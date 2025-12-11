import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/routine_controller.dart';
import '../widgets/add_routine_dialog.dart';
import '../widgets/routine_card.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';
import '../../../../shared/widgets/common/loading_widget.dart';

class RoutineView extends GetView<RoutineController> {
  const RoutineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              // Header
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                        size: AppSizes.iconL,
                      ),
                      SizedBox(width: AppSizes.spaceM),
                      const Text(
                        'Class Routine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.add, color: AppColors.primary),
                        onPressed: () => _showAddRoutineDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceM),
              
              // Routine List
              Expanded(
                child: Obx(() {
                  if (controller.routines.isEmpty) {
                    return EmptyState(
                      message: 'No routines found',
                      icon: Icons.schedule,
                      action: ElevatedButton.icon(
                        onPressed: () => _showAddRoutineDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.routines.length,
                    itemBuilder: (context, index) {
                      final routine = controller.routines[index];
                      return RoutineCard(
                        routine: routine,
                        onDelete: () => controller.deleteRoutine(routine),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddRoutineDialog(),
    );
  }
}
