import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class LogoutController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final isLoggingOut = false.obs;

  Future<void> showLogoutConfirmation() async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'Confirm Logout',
      message: 'Are you sure you want to logout from your Admin account?',
      icon: Icons.logout,
      confirmColor: Colors.red,
      confirmText: 'Logout',
    );

    if (confirmed == true) {
      await logout();
    }
  }

  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      
      await _auth.signOut();
      
      Get.snackbar(
        AppStrings.success,
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate to login screen
      // Will be updated when auth flow is migrated
      Get.offAllNamed('/login');
      
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Logout failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }
}
