import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/routes/app_routes.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final userEmail = ''.obs;
  final userName = ''.obs;
  final appVersion = '1.0.0'.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? '';
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          userName.value = doc.data()?['name'] ?? 'Super Admin';
        }
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void changePassword() {
    // Implement change password logic or navigation
    Get.snackbar(
      'Notice',
      'Change password functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
