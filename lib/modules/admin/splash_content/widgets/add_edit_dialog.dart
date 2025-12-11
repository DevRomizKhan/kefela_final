import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_content_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class AddEditDialog extends GetView<SplashContentController> {
  const AddEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.editingContent != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      title: Text(
        isEdit ? 'Edit Content' : 'Add New Content',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            const Text(
              'Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppSizes.spaceS),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedType.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'quran', child: Text('Quran')),
                DropdownMenuItem(value: 'hadith', child: Text('Hadith')),
              ],
              onChanged: (value) {
                controller.selectedType.value = value!;
              },
            )),
            SizedBox(height: AppSizes.spaceM),

            // Arabic text field
            const Text(
              'Arabic Text',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppSizes.spaceS),
            TextField(
              controller: controller.arabicController,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'Enter Arabic text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                contentPadding: EdgeInsets.all(AppSizes.paddingM),
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Bangla text field
            const Text(
              'Bangla Translation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppSizes.spaceS),
            TextField(
              controller: controller.banglaController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter Bangla translation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                contentPadding: EdgeInsets.all(AppSizes.paddingM),
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Reference field
            const Text(
              'Reference',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppSizes.spaceS),
            TextField(
              controller: controller.referenceController,
              decoration: InputDecoration(
                hintText: 'e.g., সূরা আল-বাকারাহ, ২:৪৩',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                contentPadding: EdgeInsets.all(AppSizes.paddingM),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.saveContent,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(isEdit ? 'Update' : 'Add'),
        )),
      ],
    );
  }
}
