import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/routine_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/forms/custom_text_field.dart';

class AddRoutineDialog extends GetView<RoutineController> {
  const AddRoutineDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      title: const Text(
        'Add New Class',
        style: TextStyle(color: Colors.black),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: controller.classNameController,
              label: 'Class Name',
              icon: Icons.class_,
            ),
            SizedBox(height: AppSizes.spaceM),
            CustomTextField(
              controller: controller.instructorController,
              label: 'Instructor',
              icon: Icons.person,
            ),
            SizedBox(height: AppSizes.spaceM),
            CustomTextField(
              controller: controller.roomController,
              label: 'Room',
              icon: Icons.room,
            ),
            SizedBox(height: AppSizes.spaceM),
            
            // Day Dropdown
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedDay.value,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Day',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              items: controller.days.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) => controller.selectedDay.value = value!,
            )),
            SizedBox(height: AppSizes.spaceM),
            
            // Time Pickers
            Row(
              children: [
                Expanded(
                  child: Obx(() => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Start Time',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    subtitle: Text(
                      controller.startTime.value.format(context),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: controller.pickStartTime,
                  )),
                ),
                Expanded(
                  child: Obx(() => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'End Time',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    subtitle: Text(
                      controller.endTime.value.format(context),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: controller.pickEndTime,
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.addRoutine,
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
              : const Text('Add Class'),
        )),
      ],
    );
  }
}
