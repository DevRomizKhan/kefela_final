import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../repositories/tasks_repository.dart';
import '../../../../core/constants/app_strings.dart';

class TasksController extends GetxController {
  final TasksRepository _repository = TasksRepository();

  // Observables
  final tasks = <Task>[].obs;
  final selectedFilter = 'all'.obs;
  final feedbackController = TextEditingController();

  List<Task> get filteredTasks {
    switch (selectedFilter.value) {
      case 'pending':
        return tasks.where((task) => task.status == 'pending').toList();
      case 'completed':
        return tasks.where((task) => task.status == 'completed').toList();
      case 'overdue':
        return tasks.where((task) => task.isOverdue).toList();
      default:
        return tasks;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadTasks();
  }

  @override
  void onClose() {
    feedbackController.dispose();
    super.onClose();
  }

  void _loadTasks() {
    _repository.getUserTasks().listen(
      (tasksList) {
        tasks.value = tasksList;
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading tasks: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<void> toggleTaskStatus(Task task) async {
    try {
      await _repository.toggleTaskStatus(task.id, task.status);

      Get.snackbar(
        AppStrings.success,
        task.status == 'pending'
            ? 'Task marked as completed!'
            : 'Task marked as pending',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error updating task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showFeedbackDialog(Task task) {
    feedbackController.text = task.feedback;
    Get.dialog(
      AlertDialog(
        title: Text('Provide Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task: ${task.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback or comments...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _submitFeedback(task.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String taskId) async {
    if (feedbackController.text.trim().isEmpty) {
      Get.back();
      return;
    }

    try {
      await _repository.submitFeedback(taskId, feedbackController.text.trim());
      Get.back();

      Get.snackbar(
        AppStrings.success,
        'Feedback submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error submitting feedback: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
