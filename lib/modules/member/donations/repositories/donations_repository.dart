import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donation_model.dart';

class DonationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Stream<List<MonthlyDonation>> getMonthlyDonations() {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('monthlyDonations')
        .where('memberId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MonthlyDonation.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<List<DonationPayment>> getPaymentsForDonation(
    String monthlyDonationId,
    String currentMonth,
  ) {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('monthlyDonationPayments')
        .where('memberId', isEqualTo: userId)
        .where('monthlyDonationId', isEqualTo: monthlyDonationId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DonationPayment.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<DonationPayment?> getCurrentMonthPayment(
    String monthlyDonationId,
    String currentMonth,
  ) async {
    if (userId.isEmpty) return null;

    final snapshot = await _firestore
        .collection('monthlyDonationPayments')
        .where('memberId', isEqualTo: userId)
        .where('monthlyDonationId', isEqualTo: monthlyDonationId)
        .where('month', isEqualTo: currentMonth)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return DonationPayment.fromFirestore(doc.id, doc.data());
  }

  Future<void> submitPayment({
    required String monthlyDonationId,
    required String memberName,
    required String memberEmail,
    required double amount,
    required double assignedAmount,
    required String transactionId,
    required String paymentMethod,
    required String month,
    required String monthName,
  }) async {
    if (userId.isEmpty) return;

    await _firestore.collection('monthlyDonationPayments').add({
      'monthlyDonationId': monthlyDonationId,
      'memberId': userId,
      'memberName': memberName,
      'memberEmail': memberEmail,
      'amount': amount,
      'assignedAmount': assignedAmount,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'month': month,
      'monthName': monthName,
      'status': 'pending',
      'paidAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
}
