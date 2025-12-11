import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/splash_content_model.dart';
import '../repositories/splash_content_repository.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class SplashContentController extends GetxController {
  final SplashContentRepository _repository = SplashContentRepository();

  // Observables
  final contents = <SplashContent>[].obs;
  final isLoading = false.obs;

  // Form controllers
  final arabicController = TextEditingController();
  final banglaController = TextEditingController();
  final referenceController = TextEditingController();

  // Form fields
  final selectedType = 'quran'.obs;
  final types = ['quran', 'hadith'];

  // For edit mode
  SplashContent? editingContent;

  @override
  void onInit() {
    super.onInit();
    _loadContents();
  }

  @override
  void onClose() {
    arabicController.dispose();
    banglaController.dispose();
    referenceController.dispose();
    super.onClose();
  }

  void _loadContents() {
    _repository.getAllContent().listen(
      (contentsList) {
        contents.value = contentsList;
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading content: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void showAddDialog() {
    editingContent = null;
    arabicController.clear();
    banglaController.clear();
    referenceController.clear();
    selectedType.value = 'quran';
  }

  void showEditDialog(SplashContent content) {
    editingContent = content;
    arabicController.text = content.arabic;
    banglaController.text = content.bangla;
    referenceController.text = content.reference;
    selectedType.value = content.type;
  }

  Future<void> saveContent() async {
    if (arabicController.text.isEmpty ||
        banglaController.text.isEmpty ||
        referenceController.text.isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      if (editingContent != null) {
        // Update existing
        await _repository.updateContent(editingContent!.id, {
          'arabic': arabicController.text,
          'bangla': banglaController.text,
          'reference': referenceController.text,
          'type': selectedType.value,
        });

        Get.back();
        Get.snackbar(
          AppStrings.success,
          'Content updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Add new
        final content = SplashContent(
          id: '',
          arabic: arabicController.text,
          bangla: banglaController.text,
          reference: referenceController.text,
          type: selectedType.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repository.addContent(content);

        Get.back();
        Get.snackbar(
          AppStrings.success,
          'Content added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteContent(SplashContent content) async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'Delete Content',
      message: 'Are you sure you want to delete this verse/hadith?',
      icon: Icons.delete,
      confirmColor: Colors.red,
      confirmText: AppStrings.delete,
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteContent(content.id);

      Get.snackbar(
        AppStrings.success,
        'Content deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error deleting content: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
