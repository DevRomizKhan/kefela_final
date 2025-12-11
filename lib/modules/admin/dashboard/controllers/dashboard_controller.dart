import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final totalMembers = 0.obs;
  final totalGroups = 0.obs;
  final totalTasks = 0.obs;
  final completedTasks = 0.obs;
  final attendanceRate = 0.0.obs;
  final isLoading = false.obs;

  String get formattedDate => DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
  String get formattedTime => DateFormat('hh:mm a').format(DateTime.now());

  int get pendingTasks => totalTasks.value - completedTasks.value;
  double get taskCompletionRate =>
      totalTasks.value > 0 ? (completedTasks.value / totalTasks.value) * 100 : 0.0;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadMembersCount(),
        _loadGroupsCount(),
        _loadTaskStats(),
        _loadAttendanceRate(),
      ]);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading dashboard data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMembersCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .get();
      totalMembers.value = snapshot.docs.length;
    } catch (e) {
      totalMembers.value = 0;
    }
  }

  Future<void> _loadGroupsCount() async {
    try {
      final snapshot = await _firestore.collection('groups').get();
      totalGroups.value = snapshot.docs.length;
    } catch (e) {
      totalGroups.value = 0;
    }
  }

  Future<void> _loadTaskStats() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      totalTasks.value = snapshot.docs.length;
      completedTasks.value = snapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;
    } catch (e) {
      totalTasks.value = 0;
      completedTasks.value = 0;
    }
  }

  Future<void> _loadAttendanceRate() async {
    try {
      final meetingsSnapshot = await _firestore.collection('meetings').get();
      
      if (meetingsSnapshot.docs.isEmpty) {
        attendanceRate.value = 0.0;
        return;
      }

      double totalRate = 0;
      int count = 0;

      for (var meetingDoc in meetingsSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection('meetings')
            .doc(meetingDoc.id)
            .collection('attendance')
            .get();

        if (attendanceSnapshot.docs.isNotEmpty) {
          double meetingSum = 0;
          int valid = 0;

          for (var doc in attendanceSnapshot.docs) {
            final data = doc.data();
            final percentage = data['attendancePercentage']?.toString();
            if (percentage != null) {
              final numValue =
                  double.tryParse(percentage.replaceAll('%', '')) ?? 0.0;
              meetingSum += numValue;
              valid++;
            }
          }

          if (valid > 0) {
            totalRate += (meetingSum / valid);
            count++;
          }
        }
      }

      attendanceRate.value = count > 0 ? totalRate / count : 0.0;
    } catch (e) {
      attendanceRate.value = 0.0;
    }
  }
}
