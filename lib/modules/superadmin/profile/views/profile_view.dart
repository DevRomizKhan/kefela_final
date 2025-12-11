import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Superadmin Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: AppSizes.paddingM),
                  Obx(() => Text(
                    controller.userName.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                  SizedBox(height: AppSizes.paddingS),
                  Obx(() => Text(
                    controller.userEmail.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  )),
                  SizedBox(height: AppSizes.paddingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Superadmin',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.paddingXL),

            // Settings Section
            _buildSectionHeader('Account Settings'),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: controller.changePassword,
            ),
            
            SizedBox(height: AppSizes.paddingL),
            _buildSectionHeader('System Info'),
            Obx(() => _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: controller.appVersion.value,
              showArrow: false,
            )),

            SizedBox(height: AppSizes.paddingL),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50], // Light red background
                  foregroundColor: Colors.red, // Red text/icon
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.paddingM),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: AppSizes.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: showArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }
}
