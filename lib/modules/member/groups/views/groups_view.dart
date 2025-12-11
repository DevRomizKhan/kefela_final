import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/groups_controller.dart';
import '../../../admin/groups/models/group_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class GroupsView extends GetView<GroupsController> {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('My Groups'),
        elevation: 0,
      ),
      body: Obx(() {
        final userGroups = controller.userGroups;

        if (controller.groups.isEmpty) {
          return const EmptyState(
            message: 'No groups available',
            icon: Icons.group,
          );
        }

        if (userGroups.isEmpty) {
          return const EmptyState(
            message: 'You are not a member of any groups yet',
            icon: Icons.group_off,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSizes.paddingM),
          itemCount: userGroups.length,
          itemBuilder: (context, index) {
            final group = userGroups[index];
            return _buildGroupCard(group);
          },
        );
      }),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(
            Icons.group,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spaceXS),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.black54,
                ),
                SizedBox(width: AppSizes.spaceXS),
                Text(
                  '${group.members.length} members',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (group.memberNames.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: AppSizes.spaceXS),
                child: Text(
                  group.memberNames.take(3).join(', ') +
                      (group.memberNames.length > 3 ? '...' : ''),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.info_outline, color: AppColors.primary),
              onPressed: () => controller.showGroupDetails(group),
            ),
            IconButton(
              icon: Icon(Icons.chat, color: AppColors.primary),
              onPressed: () => controller.navigateToGroupChat(
                group.id,
                group.name,
              ),
            ),
          ],
        ),
        onTap: () => controller.navigateToGroupChat(
          group.id,
          group.name,
        ),
      ),
    );
  }
}
