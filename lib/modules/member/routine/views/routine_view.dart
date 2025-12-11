import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/routine_controller.dart';
import '../../../admin/routine/models/routine_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class RoutineView extends GetView<RoutineController> {
  const RoutineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Class Routine'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Day Filter Chips
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              itemCount: controller.days.length,
              itemBuilder: (context, index) {
                final day = controller.days[index];
                final isSelected = controller.selectedDay.value == day;

                return Padding(
                  padding: EdgeInsets.only(right: AppSizes.spaceS),
                  child: FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => controller.changeDay(day),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[200],
                  ),
                );
              },
            )),
          ),

          // Routines List
          Expanded(
            child: Obx(() {
              final filteredRoutines = controller.filteredRoutines;

              if (controller.routines.isEmpty) {
                return const EmptyState(
                  message: 'No class schedule available',
                  icon: Icons.schedule,
                );
              }

              if (filteredRoutines.isEmpty) {
                return EmptyState(
                  message: 'No classes on ${controller.selectedDay.value}',
                  icon: Icons.event_busy,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(AppSizes.paddingM),
                itemCount: filteredRoutines.length,
                itemBuilder: (context, index) {
                  final routine = filteredRoutines[index];
                  return _buildRoutineCard(routine);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Name & Day
            Row(
              children: [
                Icon(
                  Icons.class_,
                  color: AppColors.primary,
                  size: AppSizes.iconM,
                ),
                SizedBox(width: AppSizes.spaceS),
                Expanded(
                  child: Text(
                    routine.className,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Text(
                    routine.day,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),

            // Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: AppSizes.iconS,
                  color: Colors.black54,
                ),
                SizedBox(width: AppSizes.spaceS),
                Text(
                  '${routine.startTime} - ${routine.endTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceS),

            // Instructor
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: AppSizes.iconS,
                  color: Colors.black54,
                ),
                SizedBox(width: AppSizes.spaceS),
                Text(
                  routine.instructor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceS),

            // Room
            Row(
              children: [
                Icon(
                  Icons.room,
                  size: AppSizes.iconS,
                  color: Colors.black54,
                ),
                SizedBox(width: AppSizes.spaceS),
                Text(
                  routine.room,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
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
