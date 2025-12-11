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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  SizedBox(height: AppSizes.spaceL),

                  // Stats Grid
                  _buildStatsGrid(),
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
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.paddingL,
          horizontal: AppSizes.paddingM,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(AppSizes.paddingS),
                  child: Icon(Icons.dashboard, color: AppColors.primary),
                ),
                SizedBox(width: AppSizes.spaceS),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceS),
            Obx(() => Text(
              controller.formattedDate,
              style: const TextStyle(fontSize: 14),
            )),
            Obx(() => Text(
              controller.formattedTime,
              style: const TextStyle(fontSize: 14),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Members',
                controller.totalMembers.value.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: _buildStatCard(
                'Total Groups',
                controller.totalGroups.value.toString(),
                Icons.group,
                Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spaceM),

        // Second Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                controller.totalTasks.value.toString(),
                Icons.assignment,
                Colors.orange,
              ),
            ),
            SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: _buildStatCard(
                'Completed Tasks',
                controller.completedTasks.value.toString(),
                Icons.check_circle,
                AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spaceM),

        // Third Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Tasks',
                controller.pendingTasks.toString(),
                Icons.pending,
                Colors.amber,
              ),
            ),
            SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: _buildStatCard(
                'Attendance Rate',
                '${controller.attendanceRate.value.toStringAsFixed(1)}%',
                Icons.analytics,
                Colors.teal,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spaceM),

        // Full Width Task Completion Card
        _buildFullWidthStatCard(
          'Task Completion Rate',
          '${controller.taskCompletionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.indigo,
        ),
      ],
    ));
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.paddingL,
          horizontal: AppSizes.paddingM,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(AppSizes.paddingM),
              child: Icon(
                icon,
                color: color,
                size: 28,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXS),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingL),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(AppSizes.paddingM),
              child: Icon(
                icon,
                color: color,
                size: 32,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXS),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
