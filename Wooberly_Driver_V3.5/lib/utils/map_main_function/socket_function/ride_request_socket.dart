import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../app/app.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';
import '../../map_utils.dart';

class RideRequestSocket {
  late HomeViewState state;
  final MapMainController controller = Get.find();

  RideRequestSocket() {
    state = controller.homeViewState;
  }

  void onReceivedRideRequest(String eventName) async {
    controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
    globals.socket?.on(eventName, (data) async {
    debugPrint("controller.isAppResume: ${controller.isAppResume}");
    globals.tripFromSocket = false;
    if(Platform.isAndroid ||  (Platform.isIOS && controller.isAppResume))
      _handleTripRequestResponse(data);
    });
  }

  void showTripAcceptInfo() async {
    controller.isTripAcceptLoading.value = false;
    controller.tripStatus = "created";

    globals.progressLoadTime = globals.notificationInterval;
    controller.riderID = globals.tripInfo["riderId"];
    controller.riderName = globals.tripInfo["name"];
    controller.riderNumber = globals.tripInfo["phoneNumber"];
    controller.riderLoc = globals.tripInfo["riderLocation"];
    controller.pickUpLoc = globals.tripInfo["pickUpLocation"];
    controller.dropLoc = globals.tripInfo["dropOffLocation"];
    controller.bookingID = globals.tripInfo["bookingId"];
    controller.pickLat = globals.tripInfo["pickUpLat"];
    controller.pickLon = globals.tripInfo["pickUpLng"];
    controller.dropLat = globals.tripInfo["dropOffLat"];
    controller.dropLng = globals.tripInfo["dropOffLng"];
    controller.bookingType = globals.tripInfo["bookingType"];
    globals.distanceType = globals.tripInfo["distanceType"] ?? 'km';
    print('globals.tripInfo: ${globals.tripInfo}');
    controller.selectedComfortRide = [];
    controller.selectedComfortRide = globals.tripInfo["comfortRide"] ?? [];
    controller.locationData.clear();
    List<dynamic> locationdataarr =
        globals.tripInfo["bookingLocations"].toList() as List<dynamic>;
    if (locationdataarr != null && locationdataarr.isNotEmpty) {
      for (int index = 0; index < locationdataarr.length; index++) {
        Map valueMap = locationdataarr[index];
        controller.locationData.add(LocationData(
            valueMap["id"] ?? index,
            LatLng(valueMap["locationLat"], valueMap["locationLng"]),
            valueMap["location"],
            valueMap["fieldType"] ?? ((index == 0) ? "disabled" : "deletable"),
            valueMap["locationStatus"] ?? "pending",
            valueMap["locationType"] ??
                ((index == 0)
                    ? "pickup"
                    : index ==
                            globals.tripInfo["bookingLocations"]
                                    .toList()
                                    .length -
                                1
                        ? "drop"
                        : "stop")));
      }
    }
    print('globals.requestlocationdata: ${locationdataarr}');
    if (globals.tripInfo["paymentType"] != null) {
      int paymentType = globals.tripInfo["paymentType"];
      controller.change(rxVariable: controller.rxPaymentType, value: paymentType);
      controller.change(rxVariable: controller.rxTripstartedResController, value: true);
    }
    if (globals.tripInfo["picture"] == null) {
      controller.riderImage = "";
    } else {
      controller.riderImage =
          globals.UPLOAD_URL + "/images/avatar/" + globals.tripInfo["picture"];
    }
    if (globals.tripInfo != null && globals.tripInfo["overallRating"] != null) {
      controller.rating = globals.tripInfo["overallRating"];
      controller.change(rxVariable: controller.rxProfileInfoupdateController, value: true);
    } else
      controller.rating = 0.0;
    print('globals.requestfromsocket: ${globals.tripFromSocket}');
    showTripRequestInfo();
    globals.tripFromSocket = true;
  }

  void showTripRequestInfo() {
    controller.isTripAcceptLoading.value = false;
    globals.driverStatus = "active";
    if (globals.playTripSound) {
      globals.audioPlayer?.setLoopMode(LoopMode.one);

      state.rideFetchAnimController?.addListener(() {
        if (state.rideFetchAnimController?.status != AnimationStatus.forward &&
            state.rideFetchAnimController?.status !=
                AnimationStatus.completed) {
          App().stopRequestAudio();
        }
      });
      state.rideFetchAnimController?.addListener(() {
        if (state.rideFetchAnimController?.status != AnimationStatus.forward &&
            state.rideFetchAnimController?.status !=
                AnimationStatus.completed) {
          App().stopRequestAudio();
        }
      });
    //  if(!(!controller.isAppResume && Platform.isIOS) ) {
        globals.audioPlayer?.seek(Duration.zero);
        globals.audioPlayer?.play();

      state.rideCompleteAnimController?.reverse();
      state.tripAmountController?.reverse();
      state.tripCashPopupController?.reverse();
      state.rideCancelledAnimController?.reverse();
   //   }
    }

    getDuration();

    if (globals.isBringAppToForeGround && !controller.isAppResume) {
      MethodChannel bringtoforegroundChannel =
          MethodChannel('bringtoforeground');
      bringtoforegroundChannel.invokeMethod('bringtoforeground');
    }
  }

  getDuration() {
    controller.rideEndLoc =
        controller.locationData[controller.locationData.length - 1].location;
    if (globals.tripInfo != null &&
        globals.tripInfo.isNotEmpty &&
        globals.tripInfo["totalRideDistance"] != null &&
        globals.tripInfo["totalDuration"] != null) {
      controller.distanceBwStartDest =
          double.parse("${globals.tripInfo["totalRideDistance"]}");
      controller.totalDuration =
          double.parse("${globals.tripInfo["totalDuration"]}");
      if (globals.tripInfo["riderPayableFare"] != null) {
        controller.totalTripAmount =
            double.parse("${globals.tripInfo["riderPayableFare"]}");
      }
      controller.change(rxVariable: controller.rxTotalDurationController, value: controller.totalDuration.toString());
    }
    state.backgroundTimer?.cancel();

    debugPrint("getDurationAmount: ${controller.distanceBwStartDest} --- ${controller.totalDuration}");
    state.backgroundTimer =  Timer.periodic(Duration(seconds: 1), (Timer t) {
      if(controller.tripStatus != 'created'){
        t.cancel();
      } else if (t.tick !=globals.notificationInterval) {
        if ((!controller.isAppResume || !globals.isShowMapPage) && (state.animController?.status == AnimationStatus.forward))
          globals.progressLoadTime = (globals.progressLoadTime - 1);
      } else {
        state.rideDeclineSocket?.sendTripDecline();
        t.cancel();
      }

    });


    controller.progressController?.forward(from: 0);

    if(controller.rxRideDetailEnabledController.value == false)
      controller.rxRideDetailEnabledController.refresh();
    else
    controller.rxRideDetailEnabledController.value =(false);
    controller.change(rxVariable: controller.rxLoadTimerController, value: true);
    controller.change(rxVariable: controller.rxRiderNameTextShownController, value: false);
    double tripArrowPosition = (Get.height / 2) - 20;
    state.timerHeight = tripArrowPosition + 20;

    Future.delayed(const Duration(milliseconds: 100), () {
      controller.change(rxVariable: state.rxChangeTripArrowPosition, value: false);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (controller.tripStatus == 'created') state.rideFetchAnimController?.forward();
    });

    controller.change(rxVariable: controller.rxUpdateBookingLocationController, value: true);
    state.animController?.forward();
    controller.change(rxVariable: controller.rxOnlineSliderController, value: false);
  }



  void _handleTripRequestResponse(data) {

    controller.socketIns.disconnectListen("cancelTripRequest-${globals.userid}");
    state.rideRequestCancelSocket
        ?.requestCancelledByRider("cancelTripRequest-${globals.userid}");
    if (data is Map) {
      globals.tripInfo = "";
      if (data["data"]["status"] == 200) {
        if (data["data"]["data"] != null) {
          globals.tripInfo = data["data"]["data"];
          controller.riderName = data["data"]["data"]["name"];

          controller.riderPhoto = data["data"]["data"]["picture"] != null
              ? globals.UPLOAD_URL +
                  "/images/avatar/" +
                  data["data"]["data"]["picture"]
              : "";
          controller.isFromAdmin = data["data"]["data"]["adminId"] != null;
            controller.totalDuration = "";
            controller.distanceBwStartDest = 0.0;
          print("riderdetails: ${controller.riderName} --- ${controller.riderPhoto}");
          controller.change(rxVariable: controller.rxTotalDurationController, value: "");
            showTripAcceptInfo();
          controller.socketIns.disconnectListen("tripStatus-${globals.userid}");
          controller.onGetUpdatedBookingLocation("tripStatus-${globals.userid}");
        }
      }
    } else {
      controller.showInSnackBar( data["data"]["errorMessage"]);
    }

    if (state.amountWidgetContext != null) {
      try {
        App().setBackNavigation();
        state.amountWidgetContext = null;
      }on Exception catch (e, stack) {
        print("Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
    }
    state.rideCompleteAnimController?.reverse();
    state.tripAmountController?.reverse();
    state.tripCashPopupController?.reverse();
    state.rideCancelledAnimController?.reverse();
  }
}