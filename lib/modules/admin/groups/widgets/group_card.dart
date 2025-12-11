import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onChat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupCard({
    super.key,
    required this.group,
    required this.onChat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
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
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spaceXS),
            Text(
              '${group.members.length} members',
              style: const TextStyle(color: Colors.black54),
            ),
            if (group.memberNames.isNotEmpty)
              Text(
                'Members: ${group.memberNames.take(3).join(', ')}${group.memberNames.length > 3 ? '...' : ''}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat, color: AppColors.primary),
              onPressed: onChat,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Group'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Group'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
