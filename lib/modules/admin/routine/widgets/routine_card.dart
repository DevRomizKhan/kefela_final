import 'package:flutter/material.dart';
import '../models/routine_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(
            Icons.schedule,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          routine.className,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spaceXS),
            Text(
              '${routine.day} • ${routine.startTime} - ${routine.endTime}',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              '${routine.instructor} • ${routine.room}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
