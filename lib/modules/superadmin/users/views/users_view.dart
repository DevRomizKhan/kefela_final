import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/users_controller.dart';
import '../models/user_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Users Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => controller.showCreateUserDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (value) => controller.searchQuery.value = value,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceM),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: controller.selectedRole.value,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                          ),
                          items: controller.roles
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              controller.selectedRole.value = value!,
                        )),
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: Obx(() {
                if (controller.filteredUsers.isEmpty) {
                  return const EmptyState(
                    message: 'No users found',
                    icon: Icons.people,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  itemCount: controller.filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = controller.filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showCreateUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserCard(SystemUser user) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            SizedBox(height: AppSizes.spaceXS),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                user.role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', user.email),
                _buildInfoRow('Phone', user.phone ?? 'Not provided'),
                _buildInfoRow(
                  'Joined',
                  DateFormat('MMM dd, yyyy').format(user.createdAt),
                ),
                SizedBox(height: AppSizes.spaceM),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (user.role != 'Superadmin') ...[
                      TextButton.icon(
                        onPressed: () => _showRoleDialog(user),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change Role'),
                      ),
                      SizedBox(width: AppSizes.spaceS),
                      TextButton.icon(
                        onPressed: () => controller.deleteUser(user),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ] else
                      const Text(
                        'Superadmin cannot be modified',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Superadmin':
        return Colors.purple;
      case 'Admin':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  void _showRoleDialog(SystemUser user) {
    final newRole = user.role.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current role: ${user.role}'),
            SizedBox(height: AppSizes.spaceM),
            Obx(() => DropdownButtonFormField<String>(
                  value: newRole.value,
                  decoration: const InputDecoration(
                    labelText: 'New Role',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.createRoles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) => newRole.value = value!,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateRole(user, newRole.value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
