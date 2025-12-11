import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meeting_model.dart';
import '../repositories/meetings_repository.dart';

class MeetingsController extends GetxController {
  final MeetingsRepository _repository = MeetingsRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  final meetings = <Meeting>[].obs;
  final isLoading = false.obs;
  
  // Form Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final meetingLinkController = TextEditingController();
  
  final selectedDate = Rx<DateTime?>(null);
  final startTime = Rx<TimeOfDay?>(null);
  final endTime = Rx<TimeOfDay?>(null);
  final meetingType = 'General'.obs;
  final isOnline = false.obs;

  final meetingTypes = ['General', 'Board', 'Committee', 'Emergency'];

  @override
  void onInit() {
    super.onInit();
    meetings.bindStream(_repository.getMeetings());
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    meetingLinkController.dispose();
    super.onClose();
  }

  void showCreateMeetingDialog() {
    _clearForm();
    Get.dialog(
      AlertDialog(
        title: const Text('Create New Meeting'),
        content: _buildMeetingForm(),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createMeeting(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showEditMeetingDialog(Meeting meeting) {
    _populateForm(meeting);
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Meeting'),
        content: _buildMeetingForm(),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateMeeting(meeting.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Obx(() => DropdownButtonFormField<String>(
            value: meetingType.value,
            items: meetingTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (val) => meetingType.value = val!,
            decoration: const InputDecoration(labelText: 'Meeting Type'),
          )),
          const SizedBox(height: 10),
          ListTile(
            title: Text(selectedDate.value == null 
              ? 'Select Date' 
              : '${selectedDate.value!.day}/${selectedDate.value!.month}/${selectedDate.value!.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: Get.context!,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) selectedDate.value = date;
            },
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(startTime.value?.format(Get.context!) ?? 'Start Time'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: Get.context!,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) startTime.value = time;
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(endTime.value?.format(Get.context!) ?? 'End Time'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: Get.context!,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) endTime.value = time;
                  },
                ),
              ),
            ],
          ),
          Obx(() => SwitchListTile(
            title: const Text('Online Meeting'),
            value: isOnline.value,
            onChanged: (val) => isOnline.value = val,
          )),
          Obx(() => isOnline.value 
            ? TextField(
                controller: meetingLinkController,
                decoration: const InputDecoration(labelText: 'Meeting Link'),
              )
            : TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              )
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    meetingLinkController.clear();
    selectedDate.value = null;
    startTime.value = null;
    endTime.value = null;
    meetingType.value = 'General';
    isOnline.value = false;
  }

  void _populateForm(Meeting meeting) {
    titleController.text = meeting.title;
    descriptionController.text = meeting.description;
    locationController.text = meeting.location;
    meetingLinkController.text = meeting.meetingLink ?? '';
    selectedDate.value = meeting.date;
    startTime.value = meeting.startTime;
    endTime.value = meeting.endTime;
    meetingType.value = meeting.meetingType;
    isOnline.value = meeting.isOnline;
  }

  Future<void> _createMeeting() async {
    if (!_validateForm()) return;

    try {
      final meetingData = _getMeetingData();
      await _repository.createMeeting(meetingData);
      Get.back();
      Get.snackbar('Success', 'Meeting created successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create meeting: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _updateMeeting(String id) async {
    if (!_validateForm()) return;

    try {
      final meetingData = _getMeetingData();
      await _repository.updateMeeting(id, meetingData);
      Get.back();
      Get.snackbar('Success', 'Meeting updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update meeting: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteMeeting(String id) async {
    try {
      await _repository.deleteMeeting(id);
      Get.snackbar('Success', 'Meeting deleted successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete meeting: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  bool _validateForm() {
    if (titleController.text.isEmpty || 
        selectedDate.value == null || 
        startTime.value == null || 
        endTime.value == null) {
      Get.snackbar('Error', 'Please fill all required fields',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  Map<String, dynamic> _getMeetingData() {
    return {
      'title': titleController.text,
      'description': descriptionController.text,
      'type': meetingType.value,
      'date': Timestamp.fromDate(selectedDate.value!),
      'startTime': startTime.value!.format(Get.context!),
      'endTime': endTime.value!.format(Get.context!),
      'isOnline': isOnline.value,
      'location': isOnline.value ? '' : locationController.text,
      'meetingLink': isOnline.value ? meetingLinkController.text : '',
      'createdBy': _auth.currentUser?.uid ?? '',
    };
  }
}
