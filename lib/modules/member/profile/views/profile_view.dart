import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final profile = controller.userProfile.value;
          if (profile == null) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.paddingL),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          radius: 50,
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 50,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceM),
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceXS),
                        Text(
                          profile.email,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceS),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingM,
                            vertical: AppSizes.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.role,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceL),

                // Personal Information
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceM),
                        _buildInfoItem(
                          'Member Since',
                          controller.formatJoinDate(),
                          Icons.calendar_today,
                        ),
                        _buildInfoItem(
                          'Role',
                          profile.role,
                          Icons.person,
                        ),
                        _buildInfoItem(
                          'Status',
                          'Active',
                          Icons.circle,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceL),

                // Settings & Actions
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceM),
                        _buildSettingOption(
                          'Change Password',
                          Icons.lock,
                          AppColors.primary,
                          controller.navigateToChangePassword,
                        ),
                        _buildSettingOption(
                          'Notification Settings',
                          Icons.notifications,
                          Colors.orange,
                          controller.navigateToNotifications,
                        ),
                        _buildSettingOption(
                          'Bug Reports & Suggestions',
                          Icons.bug_report,
                          Colors.teal,
                          controller.navigateToBugReport,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceL),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: controller.logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceL),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String value,
    IconData icon, {
    Color color = Colors.green,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppSizes.paddingS),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppSizes.paddingS),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap,
    );
  }
}
