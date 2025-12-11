import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../controllers/meetings_controller.dart';
import '../models/meeting_model.dart';

class MeetingsView extends GetView<MeetingsController> {
  const MeetingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.meetings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No meetings found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.showCreateMeetingDialog(),
                  child: const Text('Create Meeting'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSizes.paddingM),
          itemCount: controller.meetings.length,
          itemBuilder: (context, index) {
            final meeting = controller.meetings[index];
            return _buildMeetingCard(meeting);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showCreateMeetingDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.paddingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            meeting.isOnline ? Icons.videocam : Icons.location_on,
            color: AppColors.primary,
          ),
        ),
        title: Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${meeting.formattedDate} | ${meeting.formattedStartTime} - ${meeting.formattedEndTime}'),
            Text(meeting.isOnline ? 'Online' : meeting.location),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                meeting.meetingType,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete')]),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              controller.showEditMeetingDialog(meeting);
            } else if (value == 'delete') {
              Get.defaultDialog(
                title: 'Delete Meeting',
                middleText: 'Are you sure you want to delete this meeting?',
                textConfirm: 'Delete',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                buttonColor: Colors.red,
                onConfirm: () {
                  Get.back();
                  controller.deleteMeeting(meeting.id);
                },
              );
            }
          },
        ),
      ),
    );
  }
}
