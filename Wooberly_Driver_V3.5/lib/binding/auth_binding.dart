import 'package:get/get.dart';
import 'package:wooberly_driver/controller/auth_controllers/document_controller.dart';
import '../controller/auth_controllers/phone_no_verify_controller.dart';
import '../controller/auth_controllers/register_controller.dart';
import '../controller/auth_controllers/splash_controller.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../controller/profile_controllers/edit_account_controller.dart';
import '../pref/app_preference.dart';

class AuthBinding extends Bindings {
  AuthBinding._privateConstructor();
  static final AuthBinding _instance = AuthBinding._privateConstructor();

  factory AuthBinding() {
    return _instance;
  }

  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController(), fenix: true);
    Get.lazyPut<PhoneNoVerifyController>(() => PhoneNoVerifyController(), fenix: true);
    Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true);
    Get.lazyPut<EditAccountController>(() => EditAccountController(), fenix: true);
    Get.lazyPut<DocumentController>(() => DocumentController(), fenix: true);
    Get.lazyPut<MapMainController>(() => MapMainController(), fenix: true);
  }
}