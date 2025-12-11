import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  final prayerCount = 0.obs;
  final taskCount = 0.obs;
  final meetingCount = 0.obs;
  final isLoading = false.obs;

  String get userId => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;

      // Load prayer count
      await _loadPrayerCount();

      // Load task count
      await _loadTaskCount();

      // Load meeting count
      await _loadMeetingCount();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading activity summary: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPrayerCount() async {
    final snapshot = await _firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .get();

    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Count true prayer entries
      for (var entry in data.entries) {
        if (entry.key != 'updatedAt' &&
            entry.key != 'createdAt' &&
            entry.key != 'date' &&
            entry.key != 'timestamp' &&
            entry.value == true) {
          count++;
        }
      }
    }
    prayerCount.value = count;
  }

  Future<void> _loadTaskCount() async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();

    taskCount.value = snapshot.docs.length;
  }

  Future<void> _loadMeetingCount() async {
    final meetingsSnapshot = await _firestore.collection('meetings').get();

    int count = 0;
    for (var meeting in meetingsSnapshot.docs) {
      final attendanceDoc = await _firestore
          .collection('meetings')
          .doc(meeting.id)
          .collection('attendance')
          .doc(userId)
          .get();

      if (attendanceDoc.exists) {
        count++;
      }
    }
    meetingCount.value = count;
  }

  void navigateToPrayer() {
    Get.toNamed('/member/prayer');
  }

  void navigateToTasks() {
    Get.toNamed('/member/tasks');
  }

  void navigateToDonations() {
    Get.toNamed('/member/donations');
  }
}
