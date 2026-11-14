import 'package:flutter/material.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:get/get.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RideDeclineSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  RideDeclineSocket({required this.state});

  declineRide() {
    controller.isTripAcceptLoading.value = false;
    Future.delayed(const Duration(milliseconds: 200), () {
      globals.progressLoadTime = globals.notificationInterval;
    });
    ScaffoldMessenger.of(state.scaffoldContext!).hideCurrentSnackBar();

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

    controller.rxRideDetailEnabledController.value  = false;
    sendTripCancel();
    state.rideFetchAnimController?.reverse();
    if (!controller.riderinfoview) {
      state.animController?.reverse();
    }
  }

  void sendTripCancel() {
    controller.isTripAcceptLoading.value = false;
    controller.tripStatus = 'declined';
    List<String> arg = [
      '{"requestStatus" : "decline","data" : { "bookingId" : ${controller.bookingID},"auth" : "${globals.authToken}","userId" : "${globals.userid}","riderId" : "${controller.riderID}" } }'
    ];
    globals.tripFromSocket = false;
    controller.socketIns.onsendMessage("tripDecline", arg);

    Future.delayed(const Duration(milliseconds: 1500), () {
      controller.getTripStatusOnly().then((value) {
        if (value == "created") {
          sendTripCancel();
        }
      });
    });
    state.rideFetchAnimController?.reverse();
    state.animController?.reverse();
    if(globals.driverStatus.contains("_NotEligible"))
      controller.change(rxVariable: controller.rxOnlineStatus, value: false);
    controller.setNavigationStatus(-1);
  }

  void sendTripDecline() {
    App().stopRequestAudio();
    controller.change(rxVariable: controller.rxOnlineSliderController, value: false);
      if (!globals.isShowMapPage && Get.isDialogOpen == true) {
        Get.back(result: 'dialog');
      }
      state.internetCheckOnMapMainScreen
          ?.checkInternetTrackLoc("declinebtnclick");

  }
}