import 'package:flutter/material.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:get/get.dart';
import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RideRequestCancelSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  RideRequestCancelSocket({required this.state});

  requestCancelledByRider(String eventName) {
    globals.socket?.on(eventName, (data) {
      globals.tripFromSocket = false;
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          cancelledByRider(4);
          App().setTripInfo_IOS("", "");
        }
      }
    });
  }

  cancelledByRider(int i) {
    controller.isTripAcceptLoading.value = false;
    controller.tripStatus = 'cancelledByRider';
    state.previousStatus = 'cancelledByRider';
    if (!globals.isShowMapPage && Get.isDialogOpen == true) {
      Get.back(result: 'dialog');
    }

    controller.rideConfirmOTPEntryController.clear();
    controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
    state.backgroundTimer?.cancel();
    controller.clearMap();
    App().stopRequestAudio();
    controller.riderinfoview = false;
    Future.delayed(const Duration(milliseconds: 150), () {
      globals.progressLoadTime = globals.notificationInterval;
      state.rideFetchAnimController?.reverse();
        globals.progressLoadTime = globals.notificationInterval;
    });

    controller.rxRideDetailEnabledController.value =(false);
    state.rideDetailAnimController?.reverse();
    state.animController?.reverse();
    state.rideStartAnimController?.reverse();
    controller.setStatus(true);
    if(globals.driverStatus.contains("_NotEligible"))
      controller.change(rxVariable: controller.rxOnlineStatus, value: false);
  }
}