import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  final userName = ''.obs;
  final completedTasks = 0.obs;
  final pendingTasks = 0.obs;
  final totalGroups = 0.obs;
  final isLoading = false.obs;

  String get userId => _auth.currentUser?.uid ?? '';
  String get formattedDate => DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
  String get formattedTime => DateFormat('hh:mm a').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;

      // Load user data
      await _loadUserData();

      // Load task stats
      await _loadTaskStats();

      // Load groups count
      await _loadGroupsCount();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading dashboard: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      userName.value = doc.data()?['name'] ?? 'Member';
    }
  }

  Future<void> _loadTaskStats() async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();

    int completed = 0;
    int pending = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'];
      if (status == 'completed') {
        completed++;
      } else {
        pending++;
      }
    }

    completedTasks.value = completed;
    pendingTasks.value = pending;
  }

  Future<void> _loadGroupsCount() async {
    final snapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    totalGroups.value = snapshot.docs.length;
  }

  void navigateToBooks() {
    Get.toNamed('/member/books');
  }

  void navigateToPrayer() {
    Get.toNamed('/member/prayer');
  }

  void navigateToTasks() {
    Get.toNamed('/member/tasks');
  }

  void navigateToGroups() {
    Get.toNamed('/member/groups');
  }

  void navigateToRoutine() {
    Get.toNamed('/member/routine');
  }

  void navigateToActivities() {
    Get.toNamed('/member/activities');
  }
}
