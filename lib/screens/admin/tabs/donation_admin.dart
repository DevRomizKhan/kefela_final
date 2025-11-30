import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DonationTab extends StatefulWidget {
  const DonationTab({super.key});

  @override
  State<DonationTab> createState() => _DonationTabState();
}

class _DonationTabState extends State<DonationTab> {
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
            'Donation Management',
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
              Tab(text: 'General Donation'),
              Tab(text: 'Fund Raise'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralDonationSection(),
            FundRaiseSection(),
          ],
        ),
      ),
    );
  }
}

// ==================== GENERAL DONATION SECTION ====================
class GeneralDonationSection extends StatefulWidget {
  const GeneralDonationSection({super.key});

  @override
  State<GeneralDonationSection> createState() => _GeneralDonationSectionState();
}

class _GeneralDonationSectionState extends State<GeneralDonationSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .limit(100)
          .get();

      if (mounted) {
        setState(() {
          _members = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'name': data['name'] ?? 'Unknown Member',
              'email': data['email'] ?? 'No email',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  void _navigateToAssignDonation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignMonthlyDonationPage(
          members: _members,
          onDonationAssigned: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monthly donation assigned successfully!'),
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
          // Header Card
          Card(
            color: Colors.white,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Monthly Donations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: _navigateToAssignDonation,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Assigned Monthly Donations List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('monthlyDonations')
                  .orderBy('createdAt', descending: true)
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
                          'No monthly donations assigned',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to assign monthly donation',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final donations = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index].data() as Map<String, dynamic>;
                    final donationId = donations[index].id;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.black),
                        title: Text(
                          donation['memberName'] ?? 'Unknown Member',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Amount: ৳${donation['monthlyAmount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            Text(
                              'Email: ${donation['memberEmail'] ?? 'No email'}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: donation['status'] == 'active'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                donation['status'] ?? 'active',
                                style: TextStyle(
                                  color: donation['status'] == 'active' ? Colors.green : Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black, size: 20),
                              onPressed: () => _editMonthlyDonation(donation, donationId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                              onPressed: () => _viewDonationDetails(donation, donationId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteMonthlyDonation(donationId, donation['memberName'] ?? 'Member'), // ← NEW CODE
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewDonationDetails(Map<String, dynamic> donation, String donationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlyDonationDetailsPage(
          donation: donation,
          donationId: donationId,
        ),
      ),
    );
  }

  // ADD THIS METHOD: Edit Monthly Donation
  void _editMonthlyDonation(Map<String, dynamic> donation, String donationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMonthlyDonationPage(
          donation: donation,
          donationId: donationId,
          onDonationUpdated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monthly donation updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // Update the _deleteMonthlyDonation method to show member name:
  Future<void> _deleteMonthlyDonation(String donationId, String memberName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Monthly Donation', style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete monthly donation for $memberName?',
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('monthlyDonations').doc(donationId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly donation deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting donation: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== ASSIGN MONTHLY DONATION PAGE ====================
class AssignMonthlyDonationPage extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final VoidCallback onDonationAssigned;

  const AssignMonthlyDonationPage({
    super.key,
    required this.members,
    required this.onDonationAssigned,
  });

  @override
  State<AssignMonthlyDonationPage> createState() => _AssignMonthlyDonationPageState();
}

class _AssignMonthlyDonationPageState extends State<AssignMonthlyDonationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  String _selectedMember = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _selectedMember = widget.members.first['uid'];
    }
  }

  Future<void> _assignMonthlyDonation() async {
    if (_selectedMember.isEmpty || _amountController.text.isEmpty) {
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
      final member = widget.members.firstWhere((m) => m['uid'] == _selectedMember);

      await _firestore.collection('monthlyDonations').add({
        'memberId': _selectedMember,
        'memberName': member['name'],
        'memberEmail': member['email'],
        'monthlyAmount': amount,
        'status': 'active',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      widget.onDonationAssigned();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning donation: $e'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assign Monthly Donation',
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
            onPressed: _isLoading ? null : _assignMonthlyDonation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Member Selection
                DropdownButtonFormField<String>(
                  isExpanded: true, // Important for responsiveness
                  value: _selectedMember.isEmpty && widget.members.isNotEmpty
                      ? widget.members.first['uid']
                      : _selectedMember,
                  decoration: const InputDecoration(
                    labelText: 'Select Member *',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: widget.members.map<DropdownMenuItem<String>>((member) {
                    return DropdownMenuItem<String>(
                      value: member['uid'] as String,
                      child: Text(
                        '${member['name']} (${member['email']})',
                        style: const TextStyle(color: Colors.black),
                        overflow: TextOverflow.ellipsis, // Prevent text overflow
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMember = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Monthly Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Amount (BDT) *',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),

                // Info Card
                Card(
                  // color: Colors.black.withOpacity(0.1),
                  color: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.black, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Monthly Donation Information',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• This amount will be assigned as monthly donation for the selected member\n• Member can pay this amount month-wise from their panel\n• Member can pay the exact amount or any amount they wish\n• Payments require admin verification',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14, // Slightly larger for better readability
                            height: 1.4, // Better line spacing
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: 50,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _assignMonthlyDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      disabledBackgroundColor: Colors.grey,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                        : const Text('Assign Monthly Donation'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MONTHLY DONATION DETAILS PAGE ====================
class MonthlyDonationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> donation;
  final String donationId;

  const MonthlyDonationDetailsPage({
    super.key,
    required this.donation,
    required this.donationId,
  });

  @override
  State<MonthlyDonationDetailsPage> createState() => _MonthlyDonationDetailsPageState();
}

class _MonthlyDonationDetailsPageState extends State<MonthlyDonationDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _debugCheckPayments();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _debugCheckPayments() async {
    try {
      final snapshot = await _firestore
          .collection('monthlyDonationPayments')
          .where('monthlyDonationId', isEqualTo: widget.donationId)
          .get();

      if (_isMounted) {
        print('=== MONTHLY DONATION PAYMENTS DEBUG ===');
        print('Monthly Donation ID: ${widget.donationId}');
        print('Total payments found: ${snapshot.docs.length}');

        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('Payment ID: ${doc.id}');
          print('Amount: ${data['amount']}');
          print('Member Name: ${data['memberName']}');
          print('Status: ${data['status']}');
          print('Monthly Donation ID in doc: ${data['monthlyDonationId']}');
          print('---');
        }
        print('=== END DEBUG ===');
      }
    } catch (e) {
      if (_isMounted) {
        print('Debug error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donation Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donation Info Card
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Donation Information',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Member Name', widget.donation['memberName'] ?? 'Unknown'),
                    _buildDetailRow('Email', widget.donation['memberEmail'] ?? 'No email'),
                    _buildDetailRow('Monthly Amount', '৳${widget.donation['monthlyAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('Status', widget.donation['status'] ?? 'active'),
                    _buildDetailRow('Assigned Date',
                        DateFormat('MMM dd, yyyy').format(
                            (widget.donation['createdAt'] as Timestamp).toDate()
                        )
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment History
            const Text(
              'Payment History',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('monthlyDonationPayments')
                    .where('monthlyDonationId', isEqualTo: widget.donationId)
                    .orderBy('paidAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No payments yet',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Member hasn\'t made any payments yet',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  final payments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index].data() as Map<String, dynamic>;
                      final paymentId = payments[index].id;
                      final paidAt = (payment['paidAt'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.payment,
                            color: _getStatusColor(payment['status']),
                          ),
                          title: Text(
                            '৳${payment['amount']?.toStringAsFixed(2) ?? '0.00'} for ${payment['monthName'] ?? 'Unknown Month'}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${payment['paymentMethod'] ?? 'Unknown'} • ${payment['transactionId'] ?? 'No ID'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Paid on: ${DateFormat('MMM dd, yyyy').format(paidAt)}',
                                style: const TextStyle(color: Colors.black54, fontSize: 10),
                              ),
                              if (payment['adminFeedback'] != null)
                                Text(
                                  'Admin Note: ${payment['adminFeedback']}',
                                  style: TextStyle(
                                    color: _getStatusColor(payment['status']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              // Show verification status
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(payment['status']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getVerificationMessage(payment['status']),
                                  style: TextStyle(
                                    color: _getStatusColor(payment['status']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _updatePaymentStatus(paymentId, value, payment),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'verified', child: Text('Verify Payment')),
                              const PopupMenuItem(value: 'rejected', child: Text('Reject Payment')),
                              const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(payment['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment['status']?.toString().toUpperCase() ?? 'PENDING',
                                style: TextStyle(
                                  color: _getStatusColor(payment['status']),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePaymentStatus(String paymentId, String status, Map<String, dynamic> payment) async {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '${status.toUpperCase()} Payment',
          style: const TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment: ৳${payment['amount']?.toStringAsFixed(2)} for ${payment['monthName']}',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add feedback for member (optional):',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter feedback for member...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('monthlyDonationPayments').doc(paymentId).update({
                  'status': status,
                  'adminFeedback': feedbackController.text.isNotEmpty ? feedbackController.text : null,
                  'verifiedAt': status == 'verified' ? Timestamp.now() : null,
                  'verifiedBy': 'Admin',
                  'updatedAt': Timestamp.now(),
                });

                if (_isMounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment ${status} successfully!'),
                      backgroundColor: status == 'verified' ? Colors.green : Colors.black,
                    ),
                  );
                }
              } catch (e) {
                if (_isMounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'verified' ? Colors.green : Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('${status.toUpperCase()} PAYMENT'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
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
        return '⏳ Pending - Awaiting Verification';
    }
  }
}

// ==================== FUND RAISE SECTION ====================
class FundRaiseSection extends StatefulWidget {
  const FundRaiseSection({super.key});

  @override
  State<FundRaiseSection> createState() => _FundRaiseSectionState();
}

// ==================== FUND RAISE SECTION ====================
class _FundRaiseSectionState extends State<FundRaiseSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToCreateFundRaise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFundRaisePage(
          onFundRaiseCreated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fund raise created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // ADD THIS METHOD: Edit Fund Raise
  void _editFundRaise(Map<String, dynamic> fundRaise, String fundRaiseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFundRaisePage(
          fundRaise: fundRaise,
          fundRaiseId: fundRaiseId,
          onFundRaiseUpdated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fund raise updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // ADD THIS METHOD: Delete Fund Raise
  Future<void> _deleteFundRaise(String fundRaiseId, String fundName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Fund Raise', style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete "$fundName"? This action cannot be undone.',
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('fundRaises').doc(fundRaiseId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fund raise deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting fund raise: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card (same as before)
          Card(
            color: Colors.white,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Fund Raises',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: _navigateToCreateFundRaise,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fund Raises List - UPDATE THIS PART
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('fundRaises')
                  .orderBy('createdAt', descending: true)
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
                        Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No active fund raises',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to create a fund raise',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final fundRaises = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: fundRaises.length,
                  itemBuilder: (context, index) {
                    final fundRaise = fundRaises[index].data() as Map<String, dynamic>;
                    final fundRaiseId = fundRaises[index].id;

                    return FundRaiseCard(
                      fundRaise: fundRaise,
                      fundRaiseId: fundRaiseId,
                      onTap: () => _viewFundRaiseDetails(fundRaise, fundRaiseId),
                      onEdit: () => _editFundRaise(fundRaise, fundRaiseId), // ADD THIS
                      onDelete: () => _deleteFundRaise(fundRaiseId, fundRaise['fundName'] ?? 'Fund Raise'), // ADD THIS
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewFundRaiseDetails(Map<String, dynamic> fundRaise, String fundRaiseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundRaiseDetailsPage(
          fundRaise: fundRaise,
          fundRaiseId: fundRaiseId,
        ),
      ),
    );
  }
}

// ==================== FUND RAISE CARD ====================
class FundRaiseCard extends StatelessWidget {
  final Map<String, dynamic> fundRaise;
  final String fundRaiseId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FundRaiseCard({
    super.key,
    required this.fundRaise,
    required this.fundRaiseId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = (fundRaise['startDate'] as Timestamp).toDate();
    final endDate = (fundRaise['endDate'] as Timestamp).toDate();
    final isActive = endDate.isAfter(DateTime.now());
    final targetAmount = fundRaise['targetAmount'];
    final totalCollected = fundRaise['totalCollected'] ?? 0.0;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.volunteer_activism,
          color: isActive ? Colors.green : Colors.black,
        ),
        title: Text(
          fundRaise['fundName'] ?? 'Unknown Fund',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account: ${fundRaise['accountNumber'] ?? 'Not set'}',
              style: const TextStyle(color: Colors.black87),
            ),
            Text(
              'Duration: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            if (targetAmount != null)
              Text(
                'Target: ৳${targetAmount.toStringAsFixed(2)} | Collected: ৳${totalCollected.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Completed',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (targetAmount != null && targetAmount > 0)
                  Text(
                    '${((totalCollected / targetAmount) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: (totalCollected / targetAmount) >= 1
                          ? Colors.green
                          : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CREATE FUND RAISE PAGE ====================
class CreateFundRaisePage extends StatefulWidget {
  final VoidCallback onFundRaiseCreated;

  const CreateFundRaisePage({
    super.key,
    required this.onFundRaiseCreated,
  });

  @override
  State<CreateFundRaisePage> createState() => _CreateFundRaisePageState();
}

class _CreateFundRaisePageState extends State<CreateFundRaisePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _fundNameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  Future<void> _createFundRaise() async {
    if (_fundNameController.text.isEmpty || _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('fundRaises').add({
        'fundName': _fundNameController.text,
        'targetAmount': _targetAmountController.text.isNotEmpty
            ? double.parse(_targetAmountController.text)
            : null,
        'accountNumber': _accountNumberController.text,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'status': _endDate.isBefore(DateTime.now()) ? 'completed' : 'active',
        'totalCollected': 0.0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      widget.onFundRaiseCreated();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating fund raise: $e'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Fund Raise',
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
            onPressed: _isLoading ? null : _createFundRaise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fund Name
            TextField(
              controller: _fundNameController,
              decoration: const InputDecoration(
                labelText: 'Fund Name *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Target Amount
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount (BDT)',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Optional - leave empty for no target',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Account Number
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account Number *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'bKash/Nagad/Rocket/Upai account number',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Start Date
            Card(
              color: Colors.white,
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text('Start Date *', style: TextStyle(color: Colors.black54)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_startDate),
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // End Date
            Card(
              color: Colors.white,
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.green),
                title: const Text('End Date *', style: TextStyle(color: Colors.black54)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_endDate),
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Info Card
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Colors.black, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'Fund Raise Information',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• This fund raise will be visible to all members\n• Members can donate any amount until the end date\n• Provide the account number where members should send payments\n• Target amount is optional - leave empty for open-ended fund raise\n• Progress will be tracked automatically',
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

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createFundRaise,
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
                  'Create Fund Raise',
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

// ==================== FUND RAISE DETAILS PAGE ====================
class FundRaiseDetailsPage extends StatefulWidget {
  final Map<String, dynamic> fundRaise;
  final String fundRaiseId;

  const FundRaiseDetailsPage({
    super.key,
    required this.fundRaise,
    required this.fundRaiseId,
  });

  @override
  State<FundRaiseDetailsPage> createState() => _FundRaiseDetailsPageState();
}

class _FundRaiseDetailsPageState extends State<FundRaiseDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _debugCheckDonations();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _debugCheckDonations() async {
    try {
      final snapshot = await _firestore
          .collection('fundDonations')
          .where('fundRaiseId', isEqualTo: widget.fundRaiseId)
          .get();

      if (_isMounted) {
        print('=== FUND DONATIONS DEBUG ===');
        print('Fund Raise ID: ${widget.fundRaiseId}');
        print('Total donations found: ${snapshot.docs.length}');

        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('Donation ID: ${doc.id}');
          print('Amount: ${data['amount']}');
          print('Member Name: ${data['memberName']}');
          print('Status: ${data['status']}');
          print('Fund Raise ID in doc: ${data['fundRaiseId']}');
          print('---');
        }
        print('=== END DEBUG ===');
      }
    } catch (e) {
      if (_isMounted) {
        print('Debug error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = (widget.fundRaise['startDate'] as Timestamp).toDate();
    final endDate = (widget.fundRaise['endDate'] as Timestamp).toDate();
    final targetAmount = widget.fundRaise['targetAmount'];
    final totalCollected = widget.fundRaise['totalCollected'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fund Raise Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fund Raise Info Card
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fundRaise['fundName'] ?? 'Fund Raise',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Account Number', widget.fundRaise['accountNumber'] ?? 'Not set'),
                    _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(startDate)),
                    _buildDetailRow('End Date', DateFormat('MMM dd, yyyy').format(endDate)),
                    if (targetAmount != null)
                      _buildDetailRow('Target Amount', '৳${targetAmount.toStringAsFixed(2)}'),
                    _buildDetailRow('Total Collected', '৳${totalCollected.toStringAsFixed(2)}'),
                    if (targetAmount != null)
                      _buildDetailRow('Progress', '${((totalCollected / targetAmount) * 100).toStringAsFixed(1)}%'),
                    _buildDetailRow('Status', endDate.isAfter(DateTime.now()) ? 'Active' : 'Completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Donations List
            const Text(
              'Donations Received',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('fundDonations')
                    .where('fundRaiseId', isEqualTo: widget.fundRaiseId)
                    .orderBy('donatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No donations yet',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Members haven\'t donated to this fund raise yet',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  final donations = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final donation = donations[index].data() as Map<String, dynamic>;
                      final donationId = donations[index].id;
                      final donatedAt = (donation['donatedAt'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.person,
                            color: _getStatusColor(donation['status']),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '৳${donation['amount']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                donation['memberName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${donation['paymentMethod'] ?? 'Unknown'} • ${donation['transactionId'] ?? 'No ID'}',
                                style: const TextStyle(color: Colors.black54, fontSize: 10),
                              ),
                              Text(
                                'Email: ${donation['memberEmail'] ?? 'No email'}',
                                style: const TextStyle(color: Colors.black54, fontSize: 10),
                              ),
                              Text(
                                'Donated on: ${DateFormat('MMM dd, yyyy').format(donatedAt)}',
                                style: const TextStyle(color: Colors.black54, fontSize: 10),
                              ),
                              if (donation['adminFeedback'] != null)
                                Text(
                                  'Admin Note: ${donation['adminFeedback']}',
                                  style: TextStyle(
                                    color: _getStatusColor(donation['status']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              // Show verification status
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(donation['status']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getVerificationMessage(donation['status']),
                                  style: TextStyle(
                                    color: _getStatusColor(donation['status']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _updateDonationStatus(donationId, value, donation),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'verified', child: Text('Verify Donation')),
                              const PopupMenuItem(value: 'rejected', child: Text('Reject Donation')),
                              const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(donation['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                donation['status']?.toString().toUpperCase() ?? 'PENDING',
                                style: TextStyle(
                                  color: _getStatusColor(donation['status']),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDonationStatus(String donationId, String status, Map<String, dynamic> donation) async {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '${status.toUpperCase()} Donation',
          style: const TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donation: ৳${donation['amount']?.toStringAsFixed(2)} by ${donation['memberName']}',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add feedback for member (optional):',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter feedback for member...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('fundDonations').doc(donationId).update({
                  'status': status,
                  'adminFeedback': feedbackController.text.isNotEmpty ? feedbackController.text : null,
                  'verifiedAt': status == 'verified' ? Timestamp.now() : null,
                  'verifiedBy': 'Admin',
                  'updatedAt': Timestamp.now(),
                });

                // Update total collected if verified
                if (status == 'verified') {
                  final amount = donation['amount'] ?? 0.0;
                  await _firestore.collection('fundRaises').doc(widget.fundRaiseId).update({
                    'totalCollected': FieldValue.increment(amount),
                    'updatedAt': Timestamp.now(),
                  });
                }

                if (_isMounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Donation ${status} successfully!'),
                      backgroundColor: status == 'verified' ? Colors.green : Colors.black,
                    ),
                  );
                }
              } catch (e) {
                if (_isMounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating donation: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'verified' ? Colors.green : Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('${status.toUpperCase()} DONATION'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
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
        return '⏳ Pending - Awaiting Verification';
    }
  }
}

// ==================== EDIT FUND RAISE PAGE ====================
class EditFundRaisePage extends StatefulWidget {
  final Map<String, dynamic> fundRaise;
  final String fundRaiseId;
  final VoidCallback onFundRaiseUpdated;

  const EditFundRaisePage({
    super.key,
    required this.fundRaise,
    required this.fundRaiseId,
    required this.onFundRaiseUpdated,
  });

  @override
  State<EditFundRaisePage> createState() => _EditFundRaisePageState();
}

class _EditFundRaisePageState extends State<EditFundRaisePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _fundNameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing data
    _fundNameController.text = widget.fundRaise['fundName'] ?? '';
    _targetAmountController.text = widget.fundRaise['targetAmount']?.toString() ?? '';
    _accountNumberController.text = widget.fundRaise['accountNumber'] ?? '';
    _startDate = (widget.fundRaise['startDate'] as Timestamp).toDate();
    _endDate = (widget.fundRaise['endDate'] as Timestamp).toDate();
  }

  Future<void> _updateFundRaise() async {
    if (_fundNameController.text.isEmpty || _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('fundRaises').doc(widget.fundRaiseId).update({
        'fundName': _fundNameController.text,
        'targetAmount': _targetAmountController.text.isNotEmpty
            ? double.parse(_targetAmountController.text)
            : null,
        'accountNumber': _accountNumberController.text,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'status': _endDate.isBefore(DateTime.now()) ? 'completed' : 'active',
        'updatedAt': Timestamp.now(),
      });

      widget.onFundRaiseUpdated();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating fund raise: $e'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Fund Raise',
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
            onPressed: _isLoading ? null : _updateFundRaise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fund Name
            TextField(
              controller: _fundNameController,
              decoration: const InputDecoration(
                labelText: 'Fund Name *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Target Amount
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount (BDT)',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'Optional - leave empty for no target',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Account Number
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account Number *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                hintText: 'bKash/Nagad/Rocket/Upai account number',
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Start Date
            Card(
              color: Colors.white,
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text('Start Date *', style: TextStyle(color: Colors.black54)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_startDate),
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // End Date
            Card(
              color: Colors.white,
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.green),
                title: const Text('End Date *', style: TextStyle(color: Colors.black54)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_endDate),
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateFundRaise,
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
                  'Update Fund Raise',
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


// ==================== EDIT MONTHLY DONATION PAGE ====================
class EditMonthlyDonationPage extends StatefulWidget {
  final Map<String, dynamic> donation;
  final String donationId;
  final VoidCallback onDonationUpdated;

  const EditMonthlyDonationPage({
    super.key,
    required this.donation,
    required this.donationId,
    required this.onDonationUpdated,
  });

  @override
  State<EditMonthlyDonationPage> createState() => _EditMonthlyDonationPageState();
}

class _EditMonthlyDonationPageState extends State<EditMonthlyDonationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  final List<String> _statusOptions = ['active', 'paused', 'cancelled'];
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing data
    _amountController.text = widget.donation['monthlyAmount']?.toStringAsFixed(2) ?? '0.00';
    _selectedStatus = widget.donation['status'] ?? 'active';
  }

  Future<void> _updateMonthlyDonation() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the monthly amount'),
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
      await _firestore.collection('monthlyDonations').doc(widget.donationId).update({
        'monthlyAmount': amount,
        'status': _selectedStatus,
        'updatedAt': Timestamp.now(),
      });

      widget.onDonationUpdated();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating donation: $e'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Monthly Donation',
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
            onPressed: _isLoading ? null : _updateMonthlyDonation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Member Info (Read-only)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Member Information',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyRow('Name', widget.donation['memberName'] ?? 'Unknown'),
                    _buildReadOnlyRow('Email', widget.donation['memberEmail'] ?? 'No email'),
                    _buildReadOnlyRow('Member ID', widget.donation['memberId'] ?? 'Unknown'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Monthly Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Amount (BDT) *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                labelStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.toUpperCase(),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Status Info
            Card(
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Colors.black, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'Status Information',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• ACTIVE: Member can make payments normally\n• PAUSED: Temporarily pause monthly donations\n• CANCELLED: Stop monthly donations permanently',
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

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateMonthlyDonation,
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
                  'Update Monthly Donation',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}