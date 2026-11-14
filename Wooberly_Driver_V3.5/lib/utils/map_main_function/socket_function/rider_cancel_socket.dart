import 'package:flutter/material.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:get/get.dart';
import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RiderCancelSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  RiderCancelSocket({required this.state});

  receiveTripCancelled(String eventName) {
    debugPrint("receiveTripCancelled called: ${eventName}");
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      debugPrint("receiveTripCancelled data: ${data}");
      controller.tripStatus = 'cancelledByRider';
      controller.clearMap();
      controller.riderinfoview = false;
      controller.rxRideDetailEnabledController.value =(false);
      state.rideDetailAnimController?.reverse();
      state.animController?.reverse();
      state.rideStartAnimController?.reverse();
      if (state.singleClick) {
        state.singleClick = false;
        Get.back();
      }
      controller.rideConfirmOTPEntryController.clear();
      controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
      state.rideCancelledAnimController?.forward();
      controller.setStatus(true);
      if(globals.driverStatus.contains("_NotEligible"))
        controller.change(rxVariable: controller.rxOnlineStatus, value: false);
      else {
        controller.isLocationPermissionsEnabled().then((value){
          if(value)
          controller.change(rxVariable: controller.rxOnlineStatus, value: value);
          else
            state.internetCheckOnMapMainScreen?.checkInternetTrackLoc("goofflineclick");
        });
      }


      if (globals.socket?.connected ?? false) {
        controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
        state.rideRequestSocket
            ?.onReceivedRideRequest("tripRequest-${globals.userid}");
      } else {
        globals.socket?.connect();
        controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
        state.rideRequestSocket
            ?.onReceivedRideRequest("tripRequest-${globals.userid}");
      }

      if (globals.currentShowingPage == AppRoutes.APP_CHAT) {
        Get.back();
      }
      controller.setNavigationStatus(-1);

      App().setTripInfo_IOS("", "");
    });
  }
}