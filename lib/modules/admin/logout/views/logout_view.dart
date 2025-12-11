import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/logout_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class LogoutView extends GetView<LogoutController> {
  const LogoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Section
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: AppSizes.iconXL + 20,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSizes.spaceXL),
              
              // Welcome Text
              const Text(
                'Admin Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: AppSizes.spaceXL),
              
              // Account Info Card
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingL),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person, color: AppColors.primary),
                        title: const Text(
                          'Role',
                          style: TextStyle(color: Colors.black54),
                        ),
                        subtitle: const Text(
                          'Administrator',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceXL),
              
              // Logout Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: controller.isLoggingOut.value
                      ? SizedBox(
                          width: AppSizes.iconM,
                          height: AppSizes.iconM,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    controller.isLoggingOut.value 
                        ? 'Logging out...' 
                        : 'Logout from Admin Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: controller.isLoggingOut.value 
                      ? null 
                      : controller.showLogoutConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    elevation: 4,
                  ),
                ),
              )),
              SizedBox(height: AppSizes.paddingL),
              
              // Additional Security Info
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppColors.primary,
                        size: AppSizes.iconS,
                      ),
                      SizedBox(width: AppSizes.spaceS),
                      const Expanded(
                        child: Text(
                          'Your admin session is secure. Remember to logout when finished.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
