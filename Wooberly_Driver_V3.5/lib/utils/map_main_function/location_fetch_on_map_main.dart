import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../app/app.dart';
import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';

class LocationFetchOnMapMainScreen {
  final HomeViewState state;
  final MapMainController controller = Get.find();
  

  double _lastProcessedLat = 0.0;
  double _lastProcessedLon = 0.0;

  LocationFetchOnMapMainScreen({required this.state});

  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // returns distance in meters
  }

  _updateLocation(result) {
    debugPrint("_updateLocation: ${result}");
    try {
      if (globals.authToken!.isNotEmpty &&
          globals.firstname.isNotEmpty &&
          globals.email!.isNotEmpty) {
        var resultArr = result.toString().split('///');
        var latitude = resultArr[0];
        var longitude = resultArr[1];
        String updateStatus = "updateApiAndPath";
        var bearing = "";
        if (Platform.isAndroid) {
          bearing = resultArr[2];
          updateStatus = resultArr[3];
        }

        double newLat = double.parse(latitude);
        double newLon = double.parse(longitude);

// Filter out GPS noise/jitter (< 3 meters) to save CPU and battery
        if (_lastProcessedLat != 0.0 && _lastProcessedLon != 0.0) {
          double movedDistance = _calculateDistance(
              _lastProcessedLat, _lastProcessedLon, newLat, newLon);
          if (movedDistance < 3.0) {
            debugPrint("updateCurrentLoc: map ${controller.mapLocation}");
            controller.trackLocation(isBelow3Meter: true);
            return; // Ignore sub-3m micro-jitter
          }
        }

        _lastProcessedLat = newLat;
        _lastProcessedLon = newLon;
        globals.userLat = newLat;
        globals.userLon = newLon;

        LatLng latlng = LatLng(newLat, newLon);
        controller.mapLocation = latlng;
        globals.rideCompletedAt = latlng;
        if (controller.isDriverAccept()) {
          updateStatus = "updateApiAndPath";
          if (Platform.isIOS) {
            controller.updateDriverLocation("update", -1, updateStatus);
          } else {
            controller.updateDriverLocation(
                "update", double.parse(bearing), updateStatus);
          }
        } else {
          if (Platform.isIOS) {
            controller.updateDriverLocation("", -1, updateStatus);
          } else {
            controller.updateDriverLocation(
                "", double.parse(bearing), updateStatus);
          }
        }
        controller.trackLocation();
      } else {
        stopAndroidService();
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> allocateAndroidService() async {
// Cancel any existing subscription before creating a new one


    await stopAndroidService();
    await state.locationSubscription?.cancel();
    state.locationSubscription = null;
    bool ispermissionGranted = await Permission.location.isGranted;

    if (Platform.isAndroid) {
      if (ispermissionGranted) {
        var authToken =
            "${globals.authToken}&&${globals.userid}&&${globals
            .deviceId}&&${true}&&${globals.SOCKET_URL}&&${globals
            .GRAPHQL_DOMAIN}&&${globals.notificationInterval}&&${globals
            .locationFetchInterval}";
        state.locationSubscription = App.locationFetcheventChannel
            .receiveBroadcastStream("updateLocation")
            .listen(_updateLocation);
        var methodChannel = MethodChannel("BackGround Service Channel");
        await methodChannel
            .invokeMethod("allocateService", {"authWithUserId": authToken});
      }
    }
    if (Platform.isIOS) {
      var authToken = "${globals.authToken}///${globals.userid}";
      var methodChannel = MethodChannel("Stop iOS Service Channel");
      await methodChannel.invokeMethod("startService", {
        "authWithUserId": authToken,
        "locationFetchInterval": globals.locationFetchInterval
      });

      state.locationSubscription = App.locationFetcheventChannel
          .receiveBroadcastStream("allocateService///$authToken")
          .listen(_updateLocation);
    }
  }

  Future<void> stopAndroidService() async {
    await state.locationSubscription?.cancel();
    state.locationSubscription = null;

    if (Platform.isAndroid) {
      var authToken = "${globals.authToken}&&${globals.userid}";
      var methodChannel = MethodChannel("Stop Service Channel");
      await methodChannel
          .invokeMethod("stopService", {"authWithUserId": authToken});
    }
    if (Platform.isIOS) {
      var authToken = "${globals.authToken}///${globals.userid}";
      var methodChannel = MethodChannel("Stop iOS Service Channel");
      await methodChannel
          .invokeMethod("stopService", {"authWithUserId": authToken});
    }
  }

  listenForPermissionStatus(Permission permission, String from) {
    if (from.compareTo("initiallocation") == 0) {
      state.internetCheckOnMapMainScreen
          ?.checkInternetTrackLoc("initiallocation");
    } else if (from.compareTo("update") == 0) {
      state.internetCheckOnMapMainScreen
          ?.checkInternetTrackLoc("tracklocation");
    } else if (from.compareTo("start") == 0) {
      if(globals.isEnableOTP && !controller.isFromAdmin){
        controller.rideConfirmOTPEntryController.clear();
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        controller.setSwipeStart(1);
        controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.Active);
      } else {
        controller.checkInternet(state.rideStartSocket!.sendTripStarted, true);
      }

    } else if (from.compareTo("end") == 0) {
      controller.checkInternet(state.rideCompleteSocket!.endRide, true);
    } else if (from.compareTo("goonline") == 0) {
      controller.checkInternet(state.graphQLFetchOnMapMainScreen!.goOnline, true);
    } else if (from.compareTo("confirmStop") == 0) {
      controller.checkInternet(controller.confirmStop, true);
    } else if (from.compareTo("locationReached") == 0) {
        Future.delayed(Duration(milliseconds: 3000), (){
        controller.getTripStatusOnly().then((value) {
          if(controller.tripStatus == 'approved'){
            App().getNativeLocation().then((currentLoc) {
              controller.mapLocation = LatLng(globals.userLat, globals.userLon);
              controller.checkInternet(controller.locationReachedSocket, true);
              state.rideStartAnimController?.forward();
            });
          }
        });
        });
      App().getNativeLocation().then((currentLoc) {
        controller.mapLocation = LatLng(globals.userLat, globals.userLon);
        controller.checkInternet(controller.locationReachedSocket, true);
        state.rideStartAnimController?.forward();
      });
    }
  }
}