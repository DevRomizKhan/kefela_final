import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/splash_content_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService());
    Get.put(DatabaseService());
    Get.put(SplashContentService());
  }
}
