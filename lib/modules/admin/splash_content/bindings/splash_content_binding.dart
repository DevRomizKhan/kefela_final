import 'package:get/get.dart';
import '../controllers/splash_content_controller.dart';

class SplashContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashContentController>(() => SplashContentController());
  }
}
