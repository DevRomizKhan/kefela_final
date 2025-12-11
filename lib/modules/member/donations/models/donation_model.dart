import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyDonation {
  final String id;
  final String memberName;
  final String memberEmail;
  final double monthlyAmount;
  final String? adminNotice;
  final String status;

  MonthlyDonation({
    required this.id,
    required this.memberName,
    required this.memberEmail,
    required this.monthlyAmount,
    this.adminNotice,
    required this.status,
  });

  factory MonthlyDonation.fromFirestore(String id, Map<String, dynamic> data) {
    return MonthlyDonation(
      id: id,
      memberName: data['memberName'] ?? '',
      memberEmail: data['memberEmail'] ?? '',
      monthlyAmount: (data['monthlyAmount'] ?? 0).toDouble(),
      adminNotice: data['adminNotice'],
      status: data['status'] ?? 'active',
    );
  }
}

class DonationPayment {
  final String id;
  final String monthlyDonationId;
  final double amount;
  final String transactionId;
  final String paymentMethod;
  final String month;
  final String monthName;
  final String status;
  final DateTime paidAt;
  final String? adminFeedback;

  DonationPayment({
    required this.id,
    required this.monthlyDonationId,
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
    required this.month,
    required this.monthName,
    required this.status,
    required this.paidAt,
    this.adminFeedback,
  });

  factory DonationPayment.fromFirestore(String id, Map<String, dynamic> data) {
    return DonationPayment(
      id: id,
      monthlyDonationId: data['monthlyDonationId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      transactionId: data['transactionId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      month: data['month'] ?? '',
      monthName: data['monthName'] ?? '',
      status: data['status'] ?? 'pending',
      paidAt: (data['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminFeedback: data['adminFeedback'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get statusMessage {
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

// Need to import Colors
import 'package:flutter/material.dart';
