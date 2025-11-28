import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Update user password
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update password in Firebase Auth
      await user.updatePassword(newPassword);

      // Update password update timestamp in Firestore
      await _updatePasswordTimestamp();

      // Reload user to ensure data is fresh
      await user.reload();

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Re-authenticate user (required for sensitive operations like password change)
  Future<void> reauthenticateUser(String password) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Create credential
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update password timestamp in Firestore
  Future<void> _updatePasswordTimestamp() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get user profile data - ALWAYS FETCH FRESH DATA
  Future<Map<String, dynamic>> getUserProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    // Always get fresh data from Firebase Auth
    await user.reload();
    final User refreshedUser = _auth.currentUser!;

    return {
      'uid': refreshedUser.uid,
      'email': refreshedUser.email,
      'displayName': refreshedUser.displayName,
      'photoURL': refreshedUser.photoURL,
      'emailVerified': refreshedUser.emailVerified,
    };
  }

  // Get fresh user data without reloading (for real-time updates)
  Map<String, dynamic> getCurrentUserData() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user logged in');
    }

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
    };
  }

  // Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Please re-authenticate to update your password';
      case 'email-already-in-use':
        return 'Email is already in use by another account';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Check password strength (basic validation)
  bool isPasswordStrong(String password) {
    if (password.length < 6) {
      return false;
    }
    return true;
  }

  // Get password requirements description
  String getPasswordRequirements() {
    return 'Password must be at least 6 characters long';
  }
}