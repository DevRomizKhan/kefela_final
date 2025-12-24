// donation_report_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DonationReportTab extends StatefulWidget {
  const DonationReportTab({super.key});

  @override
  State<DonationReportTab> createState() => _DonationReportTabState();
}

class _DonationReportTabState extends State<DonationReportTab> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Eyanot Reports', // Changed from 'Donation Reports'
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Monthly Eyanot'), // Changed from 'Monthly Donations'
              Tab(text: 'Fund Raises'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MonthlyDonationReportSection(),
            FundRaiseReportSection(),
          ],
        ),
      ),
    );
  }
}

// ==================== MONTHLY EYANOT REPORT SECTION ====================
class MonthlyDonationReportSection extends StatefulWidget {
  const MonthlyDonationReportSection({super.key});

  @override
  State<MonthlyDonationReportSection> createState() => _MonthlyDonationReportSectionState();
}

class _MonthlyDonationReportSectionState extends State<MonthlyDonationReportSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'all';
  String _selectedMonth = '';
  String _selectedYear = '';

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('yyyy-MM').format(now);
    _selectedYear = now.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter Controls
          _buildFilterControls(),
          const SizedBox(height: 16),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 16),

          // Eyanot List
          Expanded(
            child: _buildDonationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    final months = _generateLast12Months();
    final years = _generateLast5Years();

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Filter
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Payments')),
                      DropdownMenuItem(value: 'verified', child: Text('Verified Only')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending Only')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected Only')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month and Year Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedMonth.isNotEmpty ? _selectedMonth : null,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: months.map<DropdownMenuItem<String>>((month) {
                      return DropdownMenuItem<String>(
                        value: month['value']?.toString() ?? '',
                        child: Text(
                          month['label']?.toString() ?? '',
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear.isNotEmpty ? _selectedYear : null,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: years.map<DropdownMenuItem<String>>((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(
                          year,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('monthlyDonationPayments')
          .where('memberId', isEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final payments = snapshot.data!.docs;
        double totalAmount = 0;
        double verifiedAmount = 0;
        double pendingAmount = 0;
        double rejectedAmount = 0;

        for (var payment in payments) {
          final data = payment.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0.0).toDouble();
          final status = data['status'] ?? 'pending';

          totalAmount += amount;
          switch (status) {
            case 'verified':
              verifiedAmount += amount;
              break;
            case 'pending':
              pendingAmount += amount;
              break;
            case 'rejected':
              rejectedAmount += amount;
              break;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Eyanot', // Changed from 'Total Paid'
                '৳${totalAmount.toStringAsFixed(2)}',
                Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Verified',
                '৳${verifiedAmount.toStringAsFixed(2)}',
                Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                '৳${pendingAmount.toStringAsFixed(2)}',
                Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationList() {
    Query query = _firestore
        .collection('monthlyDonationPayments')
        .where('memberId', isEqualTo: _currentUserId)
        .orderBy('paidAt', descending: true);

    // Apply month filter if selected
    if (_selectedMonth.isNotEmpty) {
      query = query.where('month', isEqualTo: _selectedMonth);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No eyanot records found', // Changed from 'No donation records found'
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> filteredPayments = snapshot.data!.docs;

        // Apply status filter
        if (_selectedFilter != 'all') {
          filteredPayments = filteredPayments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        if (filteredPayments.isEmpty) {
          return const Center(
            child: Text(
              'No payments match the selected filter',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredPayments.length,
          itemBuilder: (context, index) {
            final payment = filteredPayments[index].data() as Map<String, dynamic>;
            return _buildPaymentCard(payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paidAt = (payment['paidAt'] as Timestamp).toDate();
    final status = payment['status'] ?? 'pending';
    final amount = payment['amount'] ?? 0.0;
    final monthName = payment['monthName'] ?? 'Unknown Month';
    final assignedAmount = payment['assignedAmount'] ?? 0.0;

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;
    String statusText = 'Pending Verification';

    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified'; // Changed from 'Legal Donation'
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected - Not Valid';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Eyanot', // Changed from 'Monthly Donation'
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        monthName,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (assignedAmount > 0)
                      Text(
                        'Assigned: ৳${assignedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status and Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Eyanot paid on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(paidAt)}', // Changed from 'Paid on'
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (payment['paymentMethod'] != null)
                          Text(
                            'Via: ${payment['paymentMethod']} • ${payment['transactionId'] ?? 'No ID'}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Admin Feedback
            if (payment['adminFeedback'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.feedback, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Feedback:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            payment['adminFeedback'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _generateLast12Months() {
    final List<Map<String, String>> months = [];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final monthLabel = DateFormat('MMMM yyyy').format(date);
      months.add({
        'value': monthKey,
        'label': monthLabel,
      });
    }

    return months;
  }

  List<String> _generateLast5Years() {
    final List<String> years = [];
    final currentYear = DateTime.now().year;

    for (int i = 0; i < 5; i++) {
      years.add((currentYear - i).toString());
    }

    return years;
  }
}

// ==================== FUND RAISE REPORT SECTION ====================
class FundRaiseReportSection extends StatefulWidget {
  const FundRaiseReportSection({super.key});

  @override
  State<FundRaiseReportSection> createState() => _FundRaiseReportSectionState();
}

class _FundRaiseReportSectionState extends State<FundRaiseReportSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'all'; // 'all', 'verified', 'pending', 'rejected'
  String _selectedFund = 'all';

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  List<String> _fundNames = [];

  @override
  void initState() {
    super.initState();
    _loadFundNames();
  }

  Future<void> _loadFundNames() async {
    try {
      final snapshot = await _firestore.collection('fundRaises').get();
      if (mounted) {
        setState(() {
          _fundNames = snapshot.docs.map((doc) {
            final data = (doc.data() ?? {}) as Map<String, dynamic>;
            final name = data['fundName'];

            return (name is String && name.trim().isNotEmpty)
                ? name
                : 'Unknown Fund';
          }).toList();

          // Insert "all" at first position
          _fundNames.insert(0, 'all');

          // Ensure valid selected fund
          if (_selectedFund.isEmpty || !_fundNames.contains(_selectedFund)) {
            _selectedFund = 'all';
          }
        });

      }
    } catch (e) {
      print('Error loading fund names: $e');
      if (mounted) {
        setState(() {
          _fundNames = ['all']; // Fallback with just 'all' option
          _selectedFund = 'all';
        });
      }
    }
  }  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter Controls
          _buildFilterControls(),
          const SizedBox(height: 16),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 16),

          // Donation List
          Expanded(
            child: _buildDonationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Filter
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Eyanot')), // Changed from 'All Donations'
                      DropdownMenuItem(value: 'verified', child: Text('Verified Only')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending Only')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected Only')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fund Filter
            Row(
              children: [
                const Text('Fund:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFund,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _fundNames.map((fund) {
                      return DropdownMenuItem(
                        value: fund,
                        child: Text(fund == 'all' ? 'All Funds' : fund),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFund = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('fundDonations')
          .where('memberId', isEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final donations = snapshot.data!.docs;
        double totalAmount = 0;
        double verifiedAmount = 0;
        double pendingAmount = 0;
        double rejectedAmount = 0;
        int totalDonations = 0;
        int verifiedCount = 0;

        for (var donation in donations) {
          final data = donation.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0.0).toDouble();
          final status = data['status'] ?? 'pending';

          totalAmount += amount;
          totalDonations++;

          switch (status) {
            case 'verified':
              verifiedAmount += amount;
              verifiedCount++;
              break;
            case 'pending':
              pendingAmount += amount;
              break;
            case 'rejected':
              rejectedAmount += amount;
              break;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildFundSummaryCard(
                'Total Eyanot', // Changed from 'Total Donated'
                '৳${totalAmount.toStringAsFixed(2)}',
                Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFundSummaryCard(
                'Verified',
                '৳${verifiedAmount.toStringAsFixed(2)}',
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFundSummaryCard(
                'Total Eyanot', // Changed from 'Total Donations'
                totalDonations.toString(),
                Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFundSummaryCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationList() {
    Query query = _firestore
        .collection('fundDonations')
        .where('memberId', isEqualTo: _currentUserId)
        .orderBy('donatedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No fund eyanot found', // Changed from 'No fund donations found'
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> filteredDonations = snapshot.data!.docs;

        // Apply status filter
        if (_selectedFilter != 'all') {
          filteredDonations = filteredDonations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        // Apply fund filter
        if (_selectedFund != 'all') {
          filteredDonations = filteredDonations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['fundName'] == _selectedFund;
          }).toList();
        }

        if (filteredDonations.isEmpty) {
          return const Center(
            child: Text(
              'No eyanot match the selected filters', // Changed from 'No donations match'
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDonations.length,
          itemBuilder: (context, index) {
            final donation = filteredDonations[index].data() as Map<String, dynamic>;
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final donatedAt = (donation['donatedAt'] as Timestamp).toDate();
    final status = donation['status'] ?? 'pending';
    final amount = donation['amount'] ?? 0.0;
    final fundName = donation['fundName'] ?? 'Unknown Fund';
    final verifiedAt = donation['verifiedAt'] != null
        ? (donation['verifiedAt'] as Timestamp).toDate()
        : null;

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;
    String statusText = 'Pending Verification';

    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified'; // Changed from 'Legal Donation'
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected - Not Valid';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(Icons.volunteer_activism, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fundName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Fund Raise Eyanot', // Changed from 'Fund Raise Donation'
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(donatedAt),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status and Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Eyanot donated on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(donatedAt)}', // Changed from 'Donated on'
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (verifiedAt != null)
                          Text(
                            'Verified on: ${DateFormat('MMM dd, yyyy').format(verifiedAt)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        if (donation['paymentMethod'] != null)
                          Text(
                            'Via: ${donation['paymentMethod']} • ${donation['transactionId'] ?? 'No ID'}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Admin Feedback
            if (donation['adminFeedback'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.feedback, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Feedback:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            donation['adminFeedback'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}