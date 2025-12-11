import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller._loadDashboardData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeader(),
                  SizedBox(height: AppSizes.spaceL),

                  // Stats Overview
                  _buildStatsOverview(),
                  SizedBox(height: AppSizes.spaceL),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            const Text(
              'Member Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Date & Time
            Container(
              padding: EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Date Section
                  Column(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
                      SizedBox(height: AppSizes.spaceS),
                      Obx(() => Text(
                        controller.formattedDate.split(',')[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )),
                      Obx(() => Text(
                        controller.formattedDate.split(',')[1].trim(),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      )),
                    ],
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.green.withOpacity(0.3),
                  ),

                  // Time Section
                  Column(
                    children: [
                      Icon(Icons.access_time, color: AppColors.primary, size: 24),
                      SizedBox(height: AppSizes.spaceS),
                      Obx(() => Text(
                        controller.formattedTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )),
                      const Text(
                        'Current Time',
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

            SizedBox(height: AppSizes.spaceM),

            // Welcome Message
            Obx(() => Text(
              'Welcome, ${controller.userName.value}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed Tasks',
                    controller.completedTasks.value.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: _buildStatCard(
                    'Pending Tasks',
                    controller.pendingTasks.value.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'My Groups',
                    controller.totalGroups.value.toString(),
                    Icons.group,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: AppSizes.spaceM),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Obx(() => Container(
      padding: EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: AppSizes.spaceS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppSizes.spaceXS),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Mark Prayer',
                    Icons.mosque,
                    controller.navigateToPrayer,
                  ),
                ),
                SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: _buildActionButton(
                    'View Tasks',
                    Icons.assignment,
                    controller.navigateToTasks,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),

            // Second Row
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'My Groups',
                    Icons.group,
                    controller.navigateToGroups,
                  ),
                ),
                SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: _buildActionButton(
                    'Routine',
                    Icons.schedule,
                    controller.navigateToRoutine,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),

            // Third Row
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Books',
                    Icons.book,
                    controller.navigateToBooks,
                  ),
                ),
                SizedBox(width: AppSizes.spaceM),
                Expanded(
                  child: _buildActionButton(
                    'Activities',
                    Icons.analytics,
                    controller.navigateToActivities,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.paddingM,
          horizontal: AppSizes.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            SizedBox(height: AppSizes.spaceS),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
