import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../resources/values/app_lang.dart';
import '../../../views/map_main_screen.dart';

class DriverLoginSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  DriverLoginSocket({required this.state});

  onReceiveLoginCheck(String eventName) {
    debugPrint("LoginCheck: ${eventName}");
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      debugPrint("LoginCheck: data ${data}");
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          String deviceID = data["data"]["data"]["deviceId"].toString();
          String userType = data["data"]["data"]["userType"].toString();
          if (deviceID != globals.deviceId && userType == "2") {
            state.locationFetchOnMapMainScreen?.stopAndroidService();
            controller.setLogout(state.scaffoldContext!);
            App().toast.show(
                  context: state.scaffoldContext!,
                  message: session_timeout_err.tr,
                );
            controller.clearMap();
          }
        } else if (data["data"]["status"] == 400) {
          String errorMSG = data["data"]["errorMessage"];
          state.locationFetchOnMapMainScreen?.stopAndroidService();
          App().removeUserCache(state.scaffoldContext!);
          App().toast.show(
                context: state.scaffoldContext!,
                message: errorMSG,
              );
          controller.clearMap();
        }
      }
    });
  }

  onUserPreferenceUpdated(){
    globals.socket?.off("userPreferenceUpdated-${globals.userid}");
    globals.socket?.on("userPreferenceUpdated-${globals.userid}", (data) {
      if (data is Map) {
        debugPrint("onUserPreferenceUpdatedMSG: ${data}");
        String? langCode = data["data"]["data"]["preferredLanguage"];
        String? currency = data["data"]["data"]["preferredCurrency"];
        if(langCode !=null) {
          globals.preferredLanguage.value = langCode;
          globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
          if(  Get.isRegistered<EditAccountController>()) {
            EditAccountController editAccountController = Get.find();

            int selectedPos = editAccountController.languageCode.indexOf(
                langCode);
            if (selectedPos != -1) {
              String targetLanguage = editAccountController
                  .languageDropDown[selectedPos];
              String targetCode = editAccountController.languageCode[selectedPos];

              editAccountController.languageDropDown.removeAt(selectedPos);
              editAccountController.languageCode.removeAt(selectedPos);

              editAccountController.languageDropDown.insert(0, targetLanguage);
              editAccountController.languageCode.insert(0, targetCode);
            }
            debugPrint(
                "editAccountController.languageDropDown: ${editAccountController
                    .languageDropDown}");
            debugPrint(
                "editAccountController.languagecode: ${editAccountController
                    .languageCode}");
            editAccountController.setLanguage();
          }
          App().appPreference.preferredLanguage = globals.preferredLanguage.value;

          App()
              .localizationService
              .readJson(
              language: langCode, isUpdate: false, isDownloadOnly: false)
              .then((value) {
            Get.forceAppUpdate();
            globals.themeNotifier?.isDark = globals.isDarkTheme;
            debugPrint("onUserPreferenceUpdatedMSG:updated");
          });
        }

      }
    });
  }
}