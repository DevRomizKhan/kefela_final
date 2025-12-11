import 'package:cloud_firestore/cloud_firestore.dart';

class SystemUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final DateTime createdAt;

  SystemUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  factory SystemUser.fromFirestore(String id, Map<String, dynamic> data) {
    return SystemUser(
      uid: id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Member',
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
