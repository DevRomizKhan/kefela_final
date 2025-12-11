import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/groups_controller.dart';
import '../widgets/group_card.dart';
import '../widgets/group_dialog.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class GroupsView extends GetView<GroupsController> {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              // Header
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: AppColors.primary,
                        size: AppSizes.iconL,
                      ),
                      SizedBox(width: AppSizes.spaceM),
                      const Text(
                        'Group Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.add, color: AppColors.primary),
                        onPressed: () => _showCreateDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceM),

              // Groups List
              Expanded(
                child: Obx(() {
                  if (controller.groups.isEmpty) {
                    return EmptyState(
                      message: 'No groups found',
                      icon: Icons.group,
                      action: ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.groups.length,
                    itemBuilder: (context, index) {
                      final group = controller.groups[index];
                      return GroupCard(
                        group: group,
                        onChat: () => controller.navigateToGroupChat(
                          group.id,
                          group.name,
                        ),
                        onEdit: () => _showEditDialog(context, group),
                        onDelete: () => controller.deleteGroup(group),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    controller.showCreateDialog();
    showDialog(
      context: context,
      builder: (context) => const GroupDialog(),
    );
  }

  void _showEditDialog(BuildContext context, group) {
    controller.showEditDialog(group);
    showDialog(
      context: context,
      builder: (context) => const GroupDialog(),
    );
  }
}
