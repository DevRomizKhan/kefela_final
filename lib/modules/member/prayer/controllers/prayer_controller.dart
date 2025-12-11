import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';
import '../repositories/prayer_repository.dart';
import '../../../../core/constants/app_strings.dart';

class PrayerController extends GetxController {
  final PrayerRepository _repository = PrayerRepository();

  // Observables
  final prayers = <Prayer>[].obs;
  final isLoading = false.obs;
  final todayDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePrayers();
    todayDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadTodayAttendance();
  }

  void _initializePrayers() {
    prayers.value = [
      Prayer(name: 'Fajr', time: '5:30 AM'),
      Prayer(name: 'Dhuhr', time: '1:00 PM'),
      Prayer(name: 'Asr', time: '4:30 PM'),
      Prayer(name: 'Maghrib', time: '6:45 PM'),
      Prayer(name: 'Isha', time: '8:00 PM'),
    ];
  }

  Future<void> _loadTodayAttendance() async {
   try {
      isLoading.value = true;
      final attendance = await _repository.getTodayAttendance(todayDate.value);

      for (var prayer in prayers) {
        prayer.isMarked = attendance[prayer.name.toLowerCase()] ?? false;
      }
      prayers.refresh();
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error loading prayer attendance: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePrayer(int index) async {
    try {
      final prayer = prayers[index];
      final newStatus = !prayer.isMarked;

      await _repository.togglePrayer(
        todayDate.value,
        prayer.name,
        newStatus,
      );

      prayer.isMarked = newStatus;
      prayers.refresh();

      Get.snackbar(
        newStatus ? AppStrings.success : 'Removed',
        newStatus
            ? '${prayer.name} marked as prayed!'
            : '${prayer.name} prayer removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: newStatus ? Colors.green : Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error updating attendance: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> markAllPrayers() async {
    try {
      final prayerNames = prayers.map((p) => p.name).toList();
      await _repository.markAll(todayDate.value, prayerNames);

      for (var prayer in prayers) {
        prayer.isMarked = true;
      }
      prayers.refresh();

      Get.snackbar(
        AppStrings.success,
        'All prayers marked as prayed!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error marking all prayers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> clearAllPrayers() async {
    try {
      await _repository.clearAll(todayDate.value);

      for (var prayer in prayers) {
        prayer.isMarked = false;
      }
      prayers.refresh();

      Get.snackbar(
        'Cleared',
        'All prayers cleared!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error clearing prayers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
