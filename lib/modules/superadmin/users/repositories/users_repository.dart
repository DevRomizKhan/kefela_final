import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<SystemUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SystemUser.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    // Note: In production, user creation should be done via Firebase Admin SDK
    // This is a simplified version
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
}
