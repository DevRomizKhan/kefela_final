import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Member Reports'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Row(
            children: [
              // Members List
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.all(AppSizes.paddingM),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search members...',
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

                    // Members List
                    Expanded(
                      child: Obx(() {
                        if (controller.filteredMembers.isEmpty) {
                          return const EmptyState(
                            message: 'No members found',
                            icon: Icons.people,
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                          itemCount: controller.filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = controller.filteredMembers[index];
                            final isSelected = controller.selectedMember.value?['uid'] == member['uid'];

                            return Card(
                              margin: EdgeInsets.only(bottom: AppSizes.spaceS),
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    member['name'].toString()[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  member['name'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(member['email']),
                                onTap: () => controller.selectMember(member),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(width: 1, color: Colors.grey[300]),

              // Report Display
              Expanded(
                flex: 3,
                child: Obx(() {
                  if (controller.reportData.value == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Select a member to view report',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildReportView();
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReportView() {
    final report = controller.reportData.value!;
    final taskStats = report['taskStats'] as Map<String, dynamic>;
    final prayerStats = report['prayerStats'] as Map<String, dynamic>;
    final donationStats = report['donationStats'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['userName'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXS),
                  const Text(
                    'Member Performance Report',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => controller.downloadReportAsPDF(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceL),

          // Task Statistics
          _buildStatSection(
            'Task Performance',
            Icons.assignment,
            Colors.orange,
            [
              _buildStatRow('Total Tasks', taskStats['total'].toString()),
              _buildStatRow('Completed', taskStats['completed'].toString()),
              _buildStatRow('Pending', taskStats['pending'].toString()),
              _buildStatRow('Completion Rate', '${taskStats['completionRate'].toStringAsFixed(1)}%'),
            ],
          ),
          SizedBox(height: AppSizes.spaceL),

          // Prayer Statistics
          _buildStatSection(
            'Prayer Attendance',
            Icons.mosque,
            AppColors.primary,
            [
              _buildStatRow('Days Tracked', prayerStats['daysTracked'].toString()),
              _buildStatRow('Total Prayers', prayerStats['totalPrayers'].toString()),
              _buildStatRow('Completed', prayerStats['completedPrayers'].toString()),
              _buildStatRow('Prayer Rate', '${prayerStats['prayerRate'].toStringAsFixed(1)}%'),
            ],
          ),
          SizedBox(height: AppSizes.spaceL),

          // Donation Statistics
          _buildStatSection(
            'Donation Summary',
            Icons.attach_money,
            Colors.teal,
            [
              _buildStatRow('Total Donations', donationStats['totalDonations'].toString()),
              _buildStatRow('Total Amount', '৳${donationStats['totalAmount'].toStringAsFixed(2)}'),
              _buildStatRow('Verified', donationStats['verifiedCount'].toString()),
              _buildStatRow('Pending', donationStats['pendingCount'].toString()),
            ],
          ),
          SizedBox(height: AppSizes.spaceL),

          // Groups
          _buildStatSection(
            'Group Membership',
            Icons.group,
            Colors.purple,
            [
              _buildStatRow('Total Groups', report['groupsCount'].toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: AppSizes.spaceS),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
