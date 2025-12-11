import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/prayer_controller.dart';
import '../models/prayer_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class PrayerView extends GetView<PrayerController> {
  const PrayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer Attendance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              today,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              // Prayer List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.prayers.length,
                    itemBuilder: (context, index) {
                      final prayer = controller.prayers[index];
                      return _buildPrayerCard(prayer, index);
                    },
                  );
                }),
              ),

              // Action Buttons
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mark All Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.markAllPrayers,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppSizes.radiusS),
                            bottomLeft: Radius.circular(AppSizes.radiusS),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.checklist, color: AppColors.primary, size: 16),
                                SizedBox(width: AppSizes.spaceS),
                                const Text('Mark All', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),

                    // Clear All Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.clearAllPrayers,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(AppSizes.radiusS),
                            bottomRight: Radius.circular(AppSizes.radiusS),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.clear_all, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Clear All', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer, int index) {
    return Obx(() => Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        side: const BorderSide(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mosque,
            color: prayer.isMarked ? AppColors.primary : Colors.black26,
            size: 24,
          ),
        ),
        title: Text(
          prayer.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => controller.togglePrayer(index),
          child: prayer.isMarked
              ? Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              : Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black54,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                ),
        ),
        onTap: () => controller.togglePrayer(index),
      ),
    ));
  }
}
