import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../admin/routine/models/routine_model.dart';
import '../../../admin/routine/repositories/routine_repository.dart';

class RoutineController extends GetxController {
  // REUSE admin repository!
  final RoutineRepository _repository = RoutineRepository();

  // Observables
  final routines = <Routine>[].obs;
  final selectedDay = 'All'.obs;
  
  final days = ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Filtered routines by day
  List<Routine> get filteredRoutines {
    if (selectedDay.value == 'All') return routines;
    return routines.where((r) => r.day == selectedDay.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadRoutines();
  }

  void _loadRoutines() {
    _repository.getAllRoutines().listen(
      (routinesList) {
        routines.value = routinesList;
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          'Error loading routines: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void changeDay(String day) {
    selectedDay.value = day;
  }
}
