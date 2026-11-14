import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app_routes.dart';

import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../resources/values/app_lang.dart';
import '../../../views/map_main_screen.dart';

class DriverWalletSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  DriverWalletSocket({required this.state});

  onDriverWalletCheck() {
    globals.socket?.off('driverWalletFeature');
    globals.socket?.on('driverWalletFeature', (data) {
      debugPrint("driverWalletFeature: ${data}");
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          Map<String,dynamic> walletoption =  {};
          walletoption.addAll(globals.driverWalletOptionController.value);
          String walletFlow = data["data"]["data"]["walletFlow"];
          String driverWalletOption = data["data"]["data"]["driverWalletOption"];
          if(walletoption["driverWalletOption"] !=  driverWalletOption || walletoption["walletFlow"] !=  walletFlow){
            if (walletoption["isDisablePage"] != null && walletoption["isDisablePage"].isNotEmpty) {
            if((driverWalletOption== "1" && walletFlow == "allPaymentMethods" && walletoption["isDisablePage"] == 'payout') || driverWalletOption =="0" && walletoption["isDisablePage"] == 'wallet') {
               if(globals.currentShowingPage == AppRoutes.APP_DRIVER_WALLET)
                state.asyncLanguageDialog(
                    dialogContent: disable_payout_wallet_menu_description_content.tr,
                    onTap: () {
                      Get.until((route) => route.settings.name == "/MapMainScreen");
                    });
              }else   if(driverWalletOption != "1" || walletFlow != "allPaymentMethods"){
              if( Get.isDialogOpen == true)
                Get.key.currentState!.canPop() ? Get.back() : null;
            }
            }

          }


          walletoption["driverWalletOption"] =  driverWalletOption;
          walletoption["walletFlow"] =  walletFlow;
          debugPrint("driverWalletFeature: walletoption ${walletoption}");

          controller.checkIsDriverEligible().then((isEligible) {
          bool isInTrip =   (controller.tripStatus == "approved" ||
              controller.tripStatus == "locationReached" ||
              controller.tripStatus == "started"||
              controller.tripStatus == "created"
          );
            if((globals.driverStatus == 'active' || globals.driverStatus == 'active_NotEligible') && isEligible !=null && !isInTrip )
              state.rideAcceptSocket?.setDriverEligible(isEligible:  isEligible);

          if( globals.driverStatus.contains('NotEligible') && !isInTrip){
            globals.isActive = false;
            controller.change(rxVariable:controller.rxIsPrivateController, value:false);
            controller.change(rxVariable:controller.rxOnlineStatus, value:false);
            controller.updateDriverStatus(false);
          }
            });


          globals.driverWalletOptionController.value = walletoption;

        } else if (data["data"]["status"] == 400) {
          String errorMSG = data["data"]["errorMessage"];
          App().toast.show(
            context: state.scaffoldContext!,
            message: errorMSG,
          );
        }
      }
    });
  }


}