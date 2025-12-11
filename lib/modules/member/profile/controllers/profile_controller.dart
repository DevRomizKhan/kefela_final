import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_profile_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final userProfile = Rxn<UserProfile>();
  final isLoading = false.obs;

  String get userId => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        userProfile.value = UserProfile.fromFirestore(userId, doc.data()!);
      }
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error loading profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String formatJoinDate() {
    if (userProfile.value?.createdAt == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(userProfile.value!.createdAt!);
  }

  void navigateToChangePassword() {
    Get.snackbar(
      'Coming Soon',
      'Change password feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToNotifications() {
    Get.snackbar(
      'Coming Soon',
      'Notifications feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToBugReport() {
    Get.snackbar(
      'Coming Soon',
      'Bug report feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> logout() async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'Confirm Logout',
      message: 'Are you sure you want to logout?',
      icon: Icons.logout,
      confirmColor: Colors.green,
      confirmText: 'Logout',
    );

    if (confirmed != true) return;

    try {
      await _auth.signOut();

      Get.snackbar(
        AppStrings.success,
        'Logged out successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Logout failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
