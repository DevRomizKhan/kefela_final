import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberDonationPanel extends StatefulWidget {
  const MemberDonationPanel({super.key});

  @override
  State<MemberDonationPanel> createState() => _MemberDonationPanelState();
}

class _MemberDonationPanelState extends State<MemberDonationPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Center(
            child: const Text(
              'My Donations',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Monthly Donation'),
              Tab(text: 'Fund Raise'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MemberMonthlyDonationSection(),
            MemberFundRaiseSection(),
          ],
        ),
      ),
    );
  }
}

// ==================== MEMBER MONTHLY DONATION SECTION ====================
class MemberMonthlyDonationSection extends StatefulWidget {
  const MemberMonthlyDonationSection({super.key});

  @override
  State<MemberMonthlyDonationSection> createState() => _MemberMonthlyDonationSectionState();
}

class _MemberMonthlyDonationSectionState extends State<MemberMonthlyDonationSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  void _navigateToPayMonthlyDonation(Map<String, dynamic> monthlyDonation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayMonthlyDonationPage(
          monthlyDonation: monthlyDonation,
          onPaymentSubmitted: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment submitted successfully! Waiting for verification.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Info
          Card(
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.black),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pay your assigned monthly donation here. You can pay the exact amount or any amount you wish.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Assigned Monthly Donations
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('monthlyDonations')
                  .where('memberId', isEqualTo: _currentUserId)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_money, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No monthly donation assigned',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Contact admin for monthly donation assignment',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final monthlyDonations = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: monthlyDonations.length,
                  itemBuilder: (context, index) {
                    final donation = monthlyDonations[index].data() as Map<String, dynamic>;
                    final donationId = monthlyDonations[index].id;
                    final monthlyDonationData = {
                      ...donation,
                      'monthlyDonationId': donationId,
                    };

                    return _buildMonthlyDonationCard(monthlyDonationData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDonationCard(Map<String, dynamic> monthlyDonation) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.black, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Donation',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Assigned Amount: ৳${monthlyDonation['monthlyAmount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      // Admin Notice Display
                      if (monthlyDonation['adminNotice'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.announcement, size: 14, color: Colors.black),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Admin: ${monthlyDonation['adminNotice']}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment History for current month
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('monthlyDonationPayments')
                  .where('memberId', isEqualTo: _currentUserId)
                  .where('monthlyDonationId', isEqualTo: monthlyDonation['monthlyDonationId'])
                  .where('month', isEqualTo: DateFormat('yyyy-MM').format(DateTime.now()))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final payment = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final paidAt = (payment['paidAt'] as Timestamp).toDate();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(payment['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _getPaymentStatusColor(payment['status']),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Paid: ৳${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getVerificationMessage(payment['status']),
                                    style: TextStyle(
                                      color: _getPaymentStatusColor(payment['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Paid on: ${DateFormat('MMM dd, yyyy').format(paidAt)}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Admin Feedback Display
                        if (payment['adminFeedback'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.feedback, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Admin Feedback:',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        payment['adminFeedback'],
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
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
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navigateToPayMonthlyDonation(monthlyDonation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pay Now'),
                        ),
                      ),
                      // Show payment history for previous months
                      const SizedBox(height: 8),
                      _buildPreviousPayments(monthlyDonation['monthlyDonationId']),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousPayments(String monthlyDonationId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('monthlyDonationPayments')
          .where('memberId', isEqualTo: _currentUserId)
          .where('monthlyDonationId', isEqualTo: monthlyDonationId)
          .where('month', isNotEqualTo: DateFormat('yyyy-MM').format(DateTime.now()))
          .orderBy('paidAt', descending: true) // Fixed: Added orderBy
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final payments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous Payments:',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...payments.map((paymentDoc) {
              final payment = paymentDoc.data() as Map<String, dynamic>;
              final paidAt = (payment['paidAt'] as Timestamp).toDate();
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 12,
                      color: _getPaymentStatusColor(payment['status']),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${payment['monthName']}: ৳${payment['amount']?.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(payment['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _getVerificationShortMessage(payment['status']),
                        style: TextStyle(
                          color: _getPaymentStatusColor(payment['status']),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _getVerificationMessage(String? status) {
    switch (status) {
      case 'verified':
        return '✅ Verified - Legal Donation';
      case 'rejected':
        return '❌ Rejected - Not Valid';
      default:
        return '🕓 Pending - Awaiting Verification';
    }
  }

  String _getVerificationShortMessage(String? status) {
    switch (status) {
      case 'verified':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  } //Monthly Donations
}

// ==================== PAY MONTHLY DONATION PAGE ====================
class PayMonthlyDonationPage extends StatefulWidget {
  final Map<String, dynamic> monthlyDonation;
  final VoidCallback onPaymentSubmitted;

  const PayMonthlyDonationPage({
    super.key,
    required this.monthlyDonation,
    required this.onPaymentSubmitted,
  });

  @override
  State<PayMonthlyDonationPage> createState() => _PayMonthlyDonationPageState();
}

class _PayMonthlyDonationPageState extends State<PayMonthlyDonationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _paymentMethods = ['bKash', 'Nagad', 'Rocket', 'Upai', 'Others'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'bKash';
  String _selectedMonth = '';
  String _selectedYear = '';
  bool _isLoading = false;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.monthlyDonation['monthlyAmount'] ?? 0.0).toStringAsFixed(2);

    // Set default to current month and year
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
    _selectedYear = now.year.toString();
  }

  Future<void> _submitMonthlyPayment() async {
    if (_amountController.text.isEmpty || _transactionIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final monthKey = '${_selectedYear}-${_getMonthNumber(_selectedMonth).toString().padLeft(2, '0')}';

      // Check if already paid for selected month
      final existingPayment = await _firestore
          .collection('monthlyDonationPayments')
          .where('memberId', isEqualTo: _currentUserId)
          .where('month', isEqualTo: monthKey)
          .where('monthlyDonationId', isEqualTo: widget.monthlyDonation['monthlyDonationId'])
          .get();

      if (existingPayment.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already paid for $_selectedMonth $_selectedYear'),
            backgroundColor: Colors.black,
          ),
        );
        return;
      }

      // Submit payment with ALL required fields for admin panel
      await _firestore.collection('monthlyDonationPayments').add({
        'monthlyDonationId': widget.monthlyDonation['monthlyDonationId'],
        'memberId': _currentUserId,
        'memberName': widget.monthlyDonation['memberName'],
        'memberEmail': widget.monthlyDonation['memberEmail'],
        'amount': amount,
        'assignedAmount': widget.monthlyDonation['monthlyAmount'],
        'transactionId': _transactionIdController.text,
        'paymentMethod': _selectedPaymentMethod,
        'month': monthKey,
        'monthName': '$_selectedMonth $_selectedYear',
        'status': 'pending',
        'paidAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      widget.onPaymentSubmitted();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getMonthNumber(String monthName) {
    return _months.indexOf(monthName) + 1;
  }

  @override
  Widget build(BuildContext context) {
    // Generate years (current year and previous 2 years)
    final currentYear = DateTime.now().year;
    final years = List<String>.generate(3, (index) => (currentYear - index).toString());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pay Monthly Donation',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : const Icon(Icons.save, color: Colors.green),
            onPressed: _isLoading ? null : _submitMonthlyPayment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Monthly Amount Info
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Assigned Monthly Amount',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${widget.monthlyDonation['monthlyAmount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can pay the exact amount or any amount you wish',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Admin Notice
                    if (widget.monthlyDonation['adminNotice'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.announcement, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.monthlyDonation['adminNotice']!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Month Selection
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month *',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                    items: _months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(
                          month,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year *',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          year,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount (editable)
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (BDT) *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Enter donation amount',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(
                    method,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Transaction ID
            TextField(
              controller: _transactionIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Enter transaction ID from payment',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Selected Month Info
            Card(
              color: Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Paying for: $_selectedMonth $_selectedYear',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Verification Info
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.black, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment will be verified by admin. You will see the status update here.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitMonthlyPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Submit Payment',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MEMBER FUND RAISE SECTION ====================
class MemberFundRaiseSection extends StatefulWidget {
  const MemberFundRaiseSection({super.key});

  @override
  State<MemberFundRaiseSection> createState() => _MemberFundRaiseSectionState();
}

class _MemberFundRaiseSectionState extends State<MemberFundRaiseSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String? _currentUserName;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _debugCheckFundDonations();
  }

  void _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserName = userDoc.data()?['name'];
          _currentUserEmail = userDoc.data()?['email'];
        });
      }
    }
  }

  // Debug function to check fund donations
  void _debugCheckFundDonations() async {
    try {
      final snapshot = await _firestore
          .collection('fundDonations')
          .where('memberId', isEqualTo: _currentUserId)
          .get();

      print('=== FUND DONATIONS DEBUG ===');
      print('Current User ID: $_currentUserId');
      print('Total donations found: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Donation ID: ${doc.id}');
        print('Fund Name: ${data['fundName']}');
        print('Amount: ${data['amount']}');
        print('Status: ${data['status']}');
        print('Member ID in doc: ${data['memberId']}');
        print('Admin Feedback: ${data['adminFeedback']}');
        print('---');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  void _navigateToDonate(Map<String, dynamic> fundRaise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonateToFundRaisePage(
          fundRaise: fundRaise,
          memberName: _currentUserName ?? 'Unknown Member',
          memberEmail: _currentUserEmail ?? 'No email',
          onDonationSubmitted: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Donation submitted successfully! Waiting for verification.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Info
          const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.black),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Donate to active fund raises. Your donations will be verified by admin.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Single scrollable column for both history and fund raises
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Fund Donation History Section
                SliverToBoxAdapter(
                  child: _buildFundDonationHistory(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Active Fund Raises Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Active Fund Raises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ),

                // Fund Raises List
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('fundRaises')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.green),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No active fund raises',
                                style: TextStyle(color: Colors.black54),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Check back later for new fund raises',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final fundRaises = snapshot.data!.docs;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final fundRaise = fundRaises[index].data() as Map<String, dynamic>;
                          final fundRaiseId = fundRaises[index].id;
                          final fundRaiseData = {
                            ...fundRaise,
                            'fundRaiseId': fundRaiseId,
                          };

                          return _buildFundRaiseCard(fundRaiseData);
                        },
                        childCount: fundRaises.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundDonationHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('fundDonations')
          .where('memberId', isEqualTo: _currentUserId)
          .orderBy('donatedAt', descending: true) // Fixed: Added orderBy
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 24),
                const SizedBox(height: 8),
                Text(
                  'Error loading donation history: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, color: Colors.black, size: 32),
                SizedBox(height: 8),
                Text(
                  'No Fund Donations Yet',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your fund donations will appear here once you make donations',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final donations = snapshot.data!.docs;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'My Fund Donation History',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary Stats
              _buildDonationSummary(donations),
              const SizedBox(height: 16),

              // Donation List
              ...donations.take(3).map((donationDoc) {
                final donation = donationDoc.data() as Map<String, dynamic>;
                return _buildDonationHistoryItem(donation);
              }).toList(),

              // View All Button if more than 3
              if (donations.length > 3) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showAllDonationsHistory(donations),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    child: const Text(
                      'View All Donations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  Widget _buildDonationSummary(List<QueryDocumentSnapshot> donations) {
    final totalDonations = donations.length;
    final verifiedCount = donations.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'verified';
    }).length;
    final pendingCount = donations.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'pending';
    }).length;
    final rejectedCount = donations.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'rejected';
    }).length;
    final totalAmount = donations.fold<double>(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + (data['amount'] ?? 0.0);
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', totalDonations.toString(), Colors.black),
          _buildSummaryItem('Verified', verifiedCount.toString(), Colors.green),
          _buildSummaryItem('Pending', pendingCount.toString(), Colors.black),
          _buildSummaryItem('Rejected', rejectedCount.toString(), Colors.red),
          _buildSummaryItem('Amount', '৳${totalAmount.toStringAsFixed(0)}', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationHistoryItem(Map<String, dynamic> donation) {
    final donatedAt = (donation['donatedAt'] as Timestamp).toDate();
    final status = donation['status'] ?? 'pending';
    final verifiedAt = donation['verifiedAt'] != null
        ? (donation['verifiedAt'] as Timestamp).toDate()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['fundName'] ?? 'Fund Raise',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${donation['amount']?.toStringAsFixed(2)} • ${DateFormat('MMM dd, yyyy').format(donatedAt)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDonationStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getDonationStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status Message
          Row(
            children: [
              Icon(
                _getStatusIcon(status),
                color: _getDonationStatusColor(status),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getFundDonationVerificationMessage(status),
                  style: TextStyle(
                    color: _getDonationStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Verification Details
          if (verifiedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Verified on: ${DateFormat('MMM dd, yyyy').format(verifiedAt)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 11,
              ),
            ),
          ],

          // Admin Feedback
          if (donation['adminFeedback'] != null && donation['adminFeedback'].toString().isNotEmpty) ...[
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
                        const SizedBox(height: 2),
                        Text(
                          donation['adminFeedback'].toString(),
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

          // Payment Method
          const SizedBox(height: 6),
          Text(
            'Payment: ${donation['paymentMethod'] ?? 'Unknown'} • ${donation['transactionId'] ?? 'No ID'}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  void _showAllDonationsHistory(List<QueryDocumentSnapshot> donations) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'All Fund Donations',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index].data() as Map<String, dynamic>;
                    return _buildDonationHistoryItem(donation);
                  },
                ),
              ),
              const SizedBox(
                  height: 16
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundRaiseCard(Map<String, dynamic> fundRaise) {
    final startDate = (fundRaise['startDate'] as Timestamp).toDate();
    final endDate = (fundRaise['endDate'] as Timestamp).toDate();
    final isActive = endDate.isAfter(DateTime.now());
    final targetAmount = fundRaise['targetAmount'];
    final totalCollected = fundRaise['totalCollected'] ?? 0.0;
    final progress = targetAmount != null ? (totalCollected / targetAmount) : 0.0;
    final daysRemaining = endDate.difference(DateTime.now()).inDays;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: isActive ? Colors.green : Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fundRaise['fundName'] ?? 'Fund Raise',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Account: ${fundRaise['accountNumber'] ?? 'Not provided'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Ended',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress and Dates
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (targetAmount != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress > 1 ? 1.0 : progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1 ? Colors.green : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: progress >= 1 ? Colors.green : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collected: ৳${totalCollected.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Target: ৳${targetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'Collected: ৳${totalCollected.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
                // Days remaining or ended info
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? '$daysRemaining days remaining'
                      : 'Ended ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Donate Button
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToDonate(fundRaise),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Donate Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This fund raise has ended. Thank you for your support!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getDonationStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _getFundDonationVerificationMessage(String? status) {
    switch (status) {
      case 'verified':
        return '✅ Verified - Legal Donation';
      case 'rejected':
        return '❌ Rejected - Not Valid';
      default:
        return '🕓 Pending - Awaiting Verification';
    }
  }
}
// ==================== DONATE TO FUND RAISE PAGE ====================
class DonateToFundRaisePage extends StatefulWidget {
  final Map<String, dynamic> fundRaise;
  final String memberName;
  final String memberEmail;
  final VoidCallback onDonationSubmitted;

  const DonateToFundRaisePage({
    super.key,
    required this.fundRaise,
    required this.memberName,
    required this.memberEmail,
    required this.onDonationSubmitted,
  });

  @override
  State<DonateToFundRaisePage> createState() => _DonateToFundRaisePageState();
}

class _DonateToFundRaisePageState extends State<DonateToFundRaisePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _paymentMethods = ['bKash', 'Nagad', 'Rocket', 'Upai', 'Others'];
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'bKash';
  bool _isLoading = false;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> _submitFundDonation() async {
    if (_amountController.text.isEmpty || _transactionIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final endDate = (widget.fundRaise['endDate'] as Timestamp).toDate();
    if (endDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This fund raise has ended'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Submit donation with ALL required fields for admin panel
      await _firestore.collection('fundDonations').add({
        'fundRaiseId': widget.fundRaise['fundRaiseId'],
        'fundName': widget.fundRaise['fundName'],
        'memberId': _currentUserId,
        'memberName': widget.memberName,
        'memberEmail': widget.memberEmail,
        'amount': amount,
        'transactionId': _transactionIdController.text,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'pending',
        'donatedAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update total collected amount (this will be adjusted when admin verifies)
      final currentTotal = widget.fundRaise['totalCollected'] ?? 0.0;
      await _firestore.collection('fundRaises').doc(widget.fundRaise['fundRaiseId']).update({
        'totalCollected': currentTotal + amount,
        'updatedAt': Timestamp.now(),
      });

      widget.onDonationSubmitted();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = (widget.fundRaise['endDate'] as Timestamp).toDate();
    final isActive = endDate.isAfter(DateTime.now());
    final targetAmount = widget.fundRaise['targetAmount'];
    final totalCollected = widget.fundRaise['totalCollected'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donate to Fund Raise',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : const Icon(Icons.save, color: Colors.green),
            onPressed: _isLoading ? null : _submitFundDonation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isActive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'This fund raise has ended',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Fund Info
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.fundRaise['fundName'] ?? 'Fund Raise',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Account: ${widget.fundRaise['accountNumber'] ?? 'Not provided'}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    if (targetAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target: ৳${targetAmount.toStringAsFixed(2)} | Collected: ৳${totalCollected.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Ends: ${DateFormat('MMM dd, yyyy').format(endDate)}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Donation Amount (BDT) *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Enter donation amount',
              ),
              style: const TextStyle(color: Colors.black),
              enabled: isActive,
            ),
            const SizedBox(height: 20),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(
                    method,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: isActive ? (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              } : null,
            ),
            const SizedBox(height: 20),

            // Transaction ID
            TextField(
              controller: _transactionIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Enter transaction ID from payment',
              ),
              style: const TextStyle(color: Colors.black),
              enabled: isActive,
            ),
            const SizedBox(height: 20),

            // Verification Info
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.black, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This donation will be verified by admin. Only verified donations are considered legal.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (!isActive)
              const Text(
                'This fund raise is no longer accepting donations',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            // Donate Button
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFundDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Donation',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}