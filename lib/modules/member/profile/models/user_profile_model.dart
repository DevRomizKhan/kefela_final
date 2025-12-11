import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
