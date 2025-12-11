import 'package:get/get.dart';

class AttendanceController extends GetxController {
  // Simple controller for attendance navigation
  // This module mainly navigates to meeting management
  
  @override
  void onInit() {
    super.onInit();
    // Initialize if needed
  }

  void openMeetingManagement() {
    // Navigate to meeting management
    // Will be implemented when we migrate that module
    Get.toNamed('/admin/meetings');
  }
}
