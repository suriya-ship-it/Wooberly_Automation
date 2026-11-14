import 'package:flutter/material.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:get/get.dart';
import '../../app/app.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';

class GraphQLFetchOnMapMainScreen {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  GraphQLFetchOnMapMainScreen({required this.state});

  getTripSummary() {
    controller.getTripSummary().then((onValue) {
      if (onValue.isNotEmpty) {
        if (onValue.compareTo("offline") == 0) {
          controller.checkInternet(getTripSummary, false);
        } else {
          controller.showInSnackBar( onValue);
        }
      }
    });
  }

  goOnline() {
    debugPrint("_getLocation: goonline: ${controller.rxOnlineStatus.value}");
    if (!controller.rxOnlineStatus.value) {
      controller.updateDriverStatus(true).then((value) {
        if (value!.isNotEmpty) {
          if (value == "timeout") {
            App().toast.show(
                  context: state.context,
                  message: session_timeout_err.tr,
                );
            controller.setLogout(state.context);
          } else if (value == "null") {
            goOnline();
          } else {
            controller.setDriverStatus(false);
            controller.showInSnackBar( value);
          }
        } else {
          App().initSocket().then((onValue) {
            state.socketConnectionOnMapMainScreen?.socketConnect();
            controller.socketIns.disconnectListen("tripRequest-${globals.userid}");

            if (globals.socket?.connected ?? false) {
              controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
              state.rideRequestSocket?.onReceivedRideRequest("tripRequest-${globals.userid}");
            } else {
              globals.socket?.connect();
              controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
              state.rideRequestSocket?.onReceivedRideRequest("tripRequest-${globals.userid}");
            }
            state.driverLoginSocket?.onReceiveLoginCheck("loginCheck-${globals.userid}");
          });
          controller.setStatus(true);
          state.locationFetchOnMapMainScreen?.allocateAndroidService();
          state.setWakeLockEnableDisable(globals.screenAwake);
        }
      });
    }
  }

  goOffline() {
    controller.getTripStatusOnly().then((value) {
      if (value != "created") {
        if (controller.rxOnlineStatus.value) {
          controller.updateDriverStatus(false).then((value) {
            if (value!.isNotEmpty && value != 'null') {
              controller.showInSnackBar( value);
            } else if (value == "null") {
              goOffline();
            } else {
              try {

                state.locationFetchOnMapMainScreen?.stopAndroidService();
                controller.riderinfoview = false;
                controller.change(rxVariable:controller.rxIsPrivateController, value:false);
                controller.change(rxVariable:controller.rxOnlineStatus, value:false);
                controller.rxRideDetailEnabledController.value =(false);
                state.rideDetailAnimController?.reverse();
                state.rideFetchAnimController?.reverse();
                controller.setStatus(false);
                state.animController?.reverse();
                state.rideCompleteAnimController?.reverse();
                state.rideStartAnimController?.reverse();
              } on Exception {
                controller.riderinfoview = false;
                controller.rxRideDetailEnabledController.value =(false);
                controller.setStatus(false);
                Get.back();
              }
              controller.change(rxVariable: controller.rxOnlineSliderController, value: controller.rxOnlineSliderController.value == false);
              state.setWakeLockEnableDisable("0");
            }
          });
        }
      }
      else {
        controller.setLoadingController(false);
        controller.showInSnackBar(
          'label_you_are_in_trip'.tr,
        );
        controller.change(rxVariable: controller.rxOnlineSliderController, value: false);
        controller.checkInternet(
            state.socketConnectionOnMapMainScreen!.getTripStatus,
            null);

      }
    });
  }
}