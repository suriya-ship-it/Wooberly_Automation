import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class DriverCancelSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  DriverCancelSocket({required this.state});

  sendDriverCancelled(String eventName, String selectedReason) {
    List<String> arg;
    if (selectedReason != null && selectedReason.isNotEmpty) {
      arg = [
        '{"data" :{"auth" : "${globals.authToken}" , "userId" : "${globals.userid}" , "reason" : ${jsonEncode(selectedReason)} , "reasonId" : ${jsonEncode( controller.selectedCancelReason['id'])} , '
            '"bookingId" : ${controller.bookingID}}}'
      ];
    } else {
      arg = [
        '{"data" : {"auth" : "${globals.authToken}", "userId" : "${globals.userid}",'
            '"bookingId" : ${controller.bookingID}}}'
      ];
    }
    debugPrint("sendDriverCancelled : ${arg}");
    controller.rideConfirmOTPEntryController.clear();
    controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);

    controller.socketIns.onsendMessage(eventName, arg);
  }


  cancelRide() {
    String selectedCancelReason = "";
    if (controller.otherReasonController.text != null &&
        controller.otherReasonController.text.isNotEmpty) {
      selectedCancelReason = controller.otherCancelReason;
    } else {
      selectedCancelReason = controller.selectedCancelReason['reason'];
    }
    sendDriverCancelled("driverCancel", selectedCancelReason.trim());
    controller.clearMap();
    controller.riderinfoview = false;
    controller.rxRideDetailEnabledController.value = (false);
    state.rideDetailAnimController?.reverse();
    debugPrint("riderInfoAnimController reverse 2");
    state.riderInfoAnimController?.reverse();
    state.animController?.reverse();
    state.rideStartAnimController?.reverse();
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

    if (globals.socket?.connected == true) {
      controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
      state.rideRequestSocket
          ?.onReceivedRideRequest("tripRequest-${globals.userid}");
    } else {
      globals.socket?.connect();
      controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
      state.rideRequestSocket
          ?.onReceivedRideRequest("tripRequest-${globals.userid}");
    }
  }

  cancelReasonAnimReverse() {
    controller.selectedCancelReason = null;
    controller.change(rxVariable: controller.rxRadioListSelectController, value: false);
    controller.change(rxVariable: controller.rxOtherReasonSelectController, value: true);
    controller.otherReasonController.text = "";
  }

  receiveTripCancelled(String eventName) {
    globals.socket?.on(eventName, (data) {
      controller.tripStatus = 'cancelledByDriver';
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
      cancelReasonAnimReverse();
      controller.setStatus(true);
      controller.socketIns.disconnectListen("tripRequest-${globals.userid}");

      if (globals.socket?.connected == true) {
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