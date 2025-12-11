import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/groups_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class GroupDialog extends GetView<GroupsController> {
  const GroupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.editingGroup != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      title: Text(
        isEdit ? 'Edit Group' : 'Create New Group',
        style: const TextStyle(color: Colors.black),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group Name Input
              TextField(
                controller: controller.groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              SizedBox(height: AppSizes.spaceM),

              // Members Selection Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Members:',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceS),

              // Members List
              SizedBox(
                height: 300,
                child: Obx(() {
                  if (controller.members.isEmpty) {
                    return const Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.members.length,
                    itemBuilder: (context, index) {
                      final member = controller.members[index];
                      return Obx(() {
                        final isSelected =
                            controller.selectedMembers.contains(member.uid);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            controller.toggleMemberSelection(member.uid);
                          },
                          title: Text(
                            member.name,
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            member.email,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          checkColor: Colors.white,
                          activeColor: AppColors.primary,
                        );
                      });
                    },
                  );
                }),
              ),
            ],
          ),
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
          onPressed: controller.isLoading.value ||
                  controller.selectedMembers.isEmpty
              ? null
              : controller.saveGroup,
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
              : Text(isEdit ? 'Update Group' : 'Create Group'),
        )),
      ],
    );
  }
}
