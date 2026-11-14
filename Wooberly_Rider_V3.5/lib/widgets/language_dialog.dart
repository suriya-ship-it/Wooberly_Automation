import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../app/app.dart';
import '../app/app_routes.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../controllers/map_main_controller/map_main_controller.dart';

Future<void> asyncLanguageDialog(BuildContext context,MapMainController controller) async {
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  controller.showConfirmationDialog(content: 'update_preferred_currency_content'.tr,
      isDisableCancel: true,
      onConfirm: (){
        Get.offAllNamed( AppRoutes.APP_SPLASH);
      },
      confirmButtonText: toBeginningOfSentenceCase('ok_label'.tr));
}