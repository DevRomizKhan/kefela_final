import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/tasks_controller.dart';
import '../models/task_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('My Tasks'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info
            Card(
              margin: EdgeInsets.all(AppSizes.paddingM),
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingM),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceM),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tasks',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View and manage your assigned tasks',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 50,
              child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                children: [
                  _buildFilterChip('All Tasks', 'all'),
                  _buildFilterChip('Pending', 'pending'),
                  _buildFilterChip('Completed', 'completed'),
                  _buildFilterChip('Overdue', 'overdue'),
                ],
              )),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Tasks List
            Expanded(
              child: Obx(() {
                final filteredTasks = controller.filteredTasks;

                if (controller.tasks.isEmpty) {
                  return const EmptyState(
                    message: 'No tasks assigned yet',
                    icon: Icons.assignment,
                  );
                }

                if (filteredTasks.isEmpty) {
                  return const EmptyState(
                    message: 'No tasks match the filter',
                    icon: Icons.filter_list,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return Container(
        margin: EdgeInsets.only(right: AppSizes.spaceS),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => controller.setFilter(value),
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
        ),
      );
    });
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : Colors.orange,
            size: 28,
          ),
          onPressed: () => controller.toggleTaskStatus(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: AppSizes.spaceXS),
                child: Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(height: AppSizes.spaceXS),
            Text(
              'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
              style: TextStyle(
                color: task.isOverdue ? Colors.red : Colors.black54,
                fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (task.feedback.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: AppSizes.spaceXS),
                child: Text(
                  'Your Feedback: ${task.feedback}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.feedback, color: AppColors.primary),
          onPressed: () => controller.showFeedbackDialog(task),
        ),
      ),
    );
  }
}
