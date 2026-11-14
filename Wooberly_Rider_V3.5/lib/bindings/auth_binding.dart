import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/translations.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/controllers/splash_controller.dart';

import '../controllers/edit_account_controller.dart';
import '../controllers/phone_no_verify_controller.dart';

class AuthBinding extends Bindings{
  @override
  void dependencies(){
    Get.lazyPut(()=>SplashController());
    Get.lazyPut(()=>PhoneNoVerifyController());
    Get.lazyPut(()=>BaseController(),fenix: true);
    Get.lazyPut(()=>EditAccountController(),fenix: true);
  }
}