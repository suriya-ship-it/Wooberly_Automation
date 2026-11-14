import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RideAcceptSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();
  Timer? _tripAcceptedTimer;

  RideAcceptSocket({required this.state});


  acceptRide() {
    controller.socketIns.disconnectListen("tripAccept-${globals.userid}");
    receiveTripAccept("tripAccept-${globals.userid}");
    controller.sendTripAccepted();

    _tripAcceptedTimer = Timer(Duration(seconds: 3), () {
      controller.checkInternet(() {
        controller.getTripStatusOnly().then((onValue) {
          if(onValue != "created") {
            if (onValue == "approved" ||
                onValue == "locationReached" ||
                onValue == "started" ||
                onValue == "completed") {
              if (_tripAcceptedTimer != null) _tripAcceptedTimer?.cancel();
            } else {
              if (_tripAcceptedTimer != null) _tripAcceptedTimer?.cancel();
              state.rideRequestCancelSocket?.cancelledByRider(3);
            }
          }
        });
      }, false);
    });
  }

  receiveTripAccept(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      handleTripAccepted(data);
    });
    globals.socket?.off("tripAccept");
    globals.socket?.on("tripAccept", (data) {
      handleTripAccepted(data);
    });
  }

  void handleTripAccepted(dynamic data) {
    if (!controller.isTripAcceptLoading.value) {
      return;
    }
    controller.isTripAcceptLoading.value = false;
    controller.updateShowLocationController(controller.pickUpLoc);
    globals.tripFromSocket = false;
    ScaffoldMessenger.of(state.scaffoldContext!).hideCurrentSnackBar();
    controller.change(rxVariable: controller.rxOnlineSliderController, value: false);
    controller.tripStatus = "approved";
    controller.setDriverStatus(true);
    controller.listenChatSocket();
    controller.unreadCount = 0;
    controller.change(rxVariable: controller.rxUnReadCountController, value: controller.unreadCount);
    App().stopRequestAudio();

    state.riderCancelSocket?.receiveTripCancelled("riderCancel-${globals.userid}");

    controller.socketIns.disconnectListen("driverCancel-${controller.riderID}");
    state.driverCancelSocket
        ?.receiveTripCancelled("driverCancel-${controller.riderID}");
    controller.rxRideDetailEnabledController.value = (true);
    controller.riderinfoview = true;
    controller.change(rxVariable: controller.rxUpdateBookingLocationController, value: true);
    state.rideFetchAnimController?.reverse();
    state.rideDetailAnimController?.forward();
    controller.setSwipeStart(1);
    state.rideStartAnimController?.forward();

    state.tripAmountController?.reverse();
    state.tripCashPopupController?.reverse();
    if (!controller.riderinfoview) {
      state.animController?.reverse();
    }
    controller.progressController?.reverse();

    controller.drawDestRoute(
        null, LatLng(controller.pickLat, controller.pickLon), false);
  }

  onDriverApproved(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        debugPrint("ondriverapproved: ${data}");
        if (data["data"]["status"] == 200) {
          Map<String,dynamic> walletoptions =  {};
          walletoptions.addAll(globals.driverWalletOptionController.value);

          if (data["data"]["data"]["data"]["userStatus"] == "active"){
            if(data["data"]["data"]["data"]["walletBalance"] !=null){
              walletoptions['walletBalance'] = data["data"]["data"]["data"]["walletBalance"];
              if(walletoptions['isDriverEligible'] != data["data"]["data"]["data"]["isDriverEligible"] && data["data"]["data"]["data"]["isDriverEligible"]){
             setDriverEligible(isEligible:  data["data"]["data"]["data"]["isDriverEligible"]);
              }
              walletoptions['isDriverEligible'] = data["data"]["data"]["data"]["isDriverEligible"];

            }
            if (globals.driverStatus != "active") {
              if(globals.driverStatus.contains('_NotEligible')){
                globals.driverStatus ="active_NotEligible";
                setDriverEligible(isEligible:false);
              } else {
                globals.isActive = false;
                setDriverEligible(isEligible:true);
              }
              globals.driverWalletOptionController.value = walletoptions;

            } else {
              if (!globals.isActive) {
                globals.driverStatus = "active";
                controller.change(rxVariable: controller.rxOnlineStatus, value: globals.isActive);
                controller.updateMapPaddingController(100.0);
              }
            }
            if(double.parse(walletoptions['walletBalance'].toString())< double.parse(walletoptions['minimumWalletAmount'].toString()) && walletoptions['driverWalletOption'].toString() =='1') {
              globals.driverStatus ="active_NotEligible";
              setDriverEligible(isEligible: false);

            }

            globals.driverWalletOptionController.value = walletoptions;
          } else if (data["data"]["data"]["data"]["isBan"] == 1) {
            controller.setLogout(controller.scaffoldContext!);
          } else {
            String isEligible =  globals.driverStatus.contains("_NotEligible") ? "_NotEligible" :'';
              globals.driverStatus =data["data"]["data"]["data"]["userStatus"] +isEligible;
            if(data["data"]["data"]["data"]["walletBalance"] !=null) {
              walletoptions['walletBalance'] = data["data"]["data"]["data"]["walletBalance"];
            }
              setDriverEligible(isEligible:false);
            globals.driverWalletOptionController.value = walletoptions;
          }
          controller.checkIsDriverEligible().then((_){
            if( globals.driverStatus.contains('NotEligible')){
              globals.isActive = false;
              controller.change(rxVariable:controller.rxIsPrivateController, value:false);
              controller.change(rxVariable:controller.rxOnlineStatus, value:false);
            }
          });
          debugPrint("globals.driverStatus:socket: ${globals.driverStatus} --- ${walletoptions}");
          if(globals.driverStatus.contains('NotEligible')){
            controller.updateDriverStatus(false);
          }
        }
      }
    });
  }

  void setDriverEligible({required bool isEligible}) {
    debugPrint("setDriverEligible: ${isEligible}");
    if(isEligible){
      globals.driverStatus = "active";
      controller.change(rxVariable: controller.rxOnlineStatus, value: false);
      controller.updateMapPaddingController(100.0);
    } else {
      controller.change(rxVariable: controller.rxOnlineStatus, value: false);
      controller.updateMapPaddingController(0.0);
      controller.rxRideDetailEnabledController.value =(false);
      state.internetCheckOnMapMainScreen?.checkInternetTrackLoc("goofflineclick");
    }
  }
}