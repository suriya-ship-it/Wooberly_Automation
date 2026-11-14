import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app_routes.dart';


import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../resources/values/app_lang.dart';
import '../../../views/map_main_screen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

class DriverCurrencySocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  DriverCurrencySocket({required this.state});

  updatePreferredCurrency(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if(data["data"]["status"] == 200) {
          if (data["data"]["data"]["data"]["preferredCurrency"] != null) {
            if (data["data"]["data"]["data"]["preferredCurrency"] != globals.preferredCurrency &&
                (globals.authToken?.isNotEmpty ?? false)) {
              globals.preferredCurrency = data["data"]["data"]["data"]["preferredCurrency"];
              state.asyncLanguageDialog(
                  dialogContent: update_preferred_currency_content.tr,
                  onTap: (){
                    globals.audioPlayer?.pause();
                    globals.tripFromSocket = false;
                    Get.offAll(App().getAppRoutes().getWidget(AppRoutes.APP_SPLASH), predicate: (Route<dynamic> route) => false);
                  });
            }
          }
        }
      }
    });
  }
}