import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/activity_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class ActivityView extends GetView<ActivityController> {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('My Activity'),
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

          return ListView(
            padding: EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Prayer Reports Card
              _buildActivityCard(
                title: 'Prayer Reports',
                count: controller.prayerCount.value.toString(),
                subtitle: 'Total prayers tracked',
                icon: Icons.mosque,
                color: AppColors.primary,
                onTap: controller.navigateToPrayer,
              ),
              SizedBox(height: AppSizes.spaceM),

              // Task Reports Card
              _buildActivityCard(
                title: 'Task Reports',
                count: controller.taskCount.value.toString(),
                subtitle: 'Tasks assigned to you',
                icon: Icons.assignment,
                color: Colors.orange,
                onTap: controller.navigateToTasks,
              ),
              SizedBox(height: AppSizes.spaceM),

              // Meeting Reports Card
              _buildActivityCard(
                title: 'Meeting Reports',
                count: controller.meetingCount.value.toString(),
                subtitle: 'Meetings attended',
                icon: Icons.meeting_room,
                color: Colors.blue,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Meeting details will be available soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              SizedBox(height: AppSizes.spaceM),

              // Donation Reports Card
              _buildActivityCard(
                title: 'Donation Reports',
                count: '',
                subtitle: 'Monthly & Fund Raise History',
                icon: Icons.attach_money,
                color: Colors.purple,
                onTap: controller.navigateToDonations,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingL,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXS),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (count.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXS),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
