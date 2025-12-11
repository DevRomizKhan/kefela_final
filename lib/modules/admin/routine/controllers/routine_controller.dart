import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/routine_model.dart';
import '../repositories/routine_repository.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class RoutineController extends GetxController {
  final RoutineRepository _repository = RoutineRepository();

  // Observables
  final routines = <Routine>[].obs;
  final isLoading = false.obs;

  // Form controllers
  final classNameController = TextEditingController();
  final instructorController = TextEditingController();
  final roomController = TextEditingController();
  
  // Form fields
  final selectedDay = 'Monday'.obs;
  final startTime = Rx<TimeOfDay>(TimeOfDay.now());
  final endTime = Rx<TimeOfDay>(TimeOfDay.now());

  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void onInit() {
    super.onInit();
    _loadRoutines();
  }

  @override
  void onClose() {
    classNameController.dispose();
    instructorController.dispose();
    roomController.dispose();
    super.onClose();
  }

  void _loadRoutines() {
    _repository.getAllRoutines().listen(
      (routinesList) {
        routines.value = routinesList;
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading routines: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> addRoutine() async {
    if (classNameController.text.isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Class name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final routine = Routine(
        id: '',
        className: classNameController.text,
        instructor: instructorController.text,
        room: roomController.text,
        day: selectedDay.value,
        startTime: startTime.value.format(Get.context!),
        endTime: endTime.value.format(Get.context!),
        createdAt: DateTime.now(),
      );

      await _repository.addRoutine(routine);

      // Clear form
      classNameController.clear();
      instructorController.clear();
      roomController.clear();
      selectedDay.value = 'Monday';

      Get.back(); // Close dialog

      Get.snackbar(
        AppStrings.success,
        'Class added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error adding class: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteRoutine(Routine routine) async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'Delete Class',
      message: 'Are you sure you want to delete this class?',
      icon: Icons.delete,
      confirmColor: Colors.red,
      confirmText: AppStrings.delete,
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteRoutine(routine.id);

      Get.snackbar(
        AppStrings.success,
        'Class deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error deleting class: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickStartTime() async {
    final time = await showTimePicker(
      context: Get.context!,
      initialTime: startTime.value,
    );
    if (time != null) {
      startTime.value = time;
    }
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: Get.context!,
      initialTime: endTime.value,
    );
    if (time != null) {
      endTime.value = time;
    }
  }
}
