import 'dart:async' show Timer;
import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:get/get.dart';
import '../../app/app.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_lang.dart';

class SocketConnectionOnMapMainScreen {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  SocketConnectionOnMapMainScreen(
      {required this.homeViewState});

  socketConnect() async {
    App().initSocket();
    try {
      globals.socket?.onDisconnect((data) {
        App().reconnectSocket();
      });
      globals.socket?.onConnect((data) {
        if (data is Map) {
          data = json.encode(data);
        }
        if (!homeViewState.netOff) {
          checkTripStatus();
          homeViewState.netOff = true;
        }
      });
      globals.socket?.onConnectError((data) async {
        if (data is Map) {
          data = json.encode(data);
        }
        if (Platform.isAndroid) {

          if (data
              .toString()
              .contains("io.socket.engineio.client.EngineIOException")) {
            if (homeViewState.netOff) {
              checkTripStatus();
              homeViewState.netOff = false;
            }
          } else {
            globals.socket?.onReconnect((data) {
              if(controller.paymentSettingTimer ==null) {
                controller.paymentSettingTimer = new Timer(const Duration(milliseconds: 5000), () {
                  controller.getPaymentSettings();
                });
              }

            });
          }
        }
      });
      globals.socket?.onReconnectError((data) {
      });
      globals.socket?.onReconnectFailed((data) {
      });
      globals.socket?.onError((data) {
        if (data is Map) {
          data = json.encode(data);
        }
        if (Platform.isIOS) {
          if (data.toString().contains("offline") ||
              data.toString().contains("Tried emitting when not connected")) {
              if (homeViewState.netOff) {
                checkTripStatus();
                homeViewState.netOff = false;
              }

          }
        }
      });
      App().reconnectSocket();
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  void checkTripStatus() {
    controller.updateCurrentLoc(controller.mapLocation).then((value) {
      if (value.isNotEmpty) {
        if (value == "timeout") {
          controller.setLogout(homeViewState.scaffoldContext!);
        }
      } else {
        controller.checkInternet(getTripStatus, null);
      }
    });
  }

  getTripStatus() {
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_tripstatus ${point} --- ');
      controller.getTripStatus().then((onValue) {
        final context = homeViewState.scaffoldContext;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .hideCurrentSnackBar();
        }
        homeViewState.driverLoginSocket?.onReceiveLoginCheck("loginCheck-${globals.userid}");
        if (onValue.isNotEmpty) {
          if (onValue == "timeout") {
            App().toast.show(
              context: homeViewState.scaffoldContext!,
              message: session_timeout_err.tr,
            );
            controller.setLogout(Get.context!);
          }
        } else {
          debugPrint("test9_tripstatus c: ${controller.tripStatus} --- ${onValue} --- ${globals.tripFromSocket}");
         if(onValue != "isDriverViewed"){
           if (controller.tripStatus.compareTo("approved") == 0 ||
               controller.tripStatus.compareTo("locationReached") == 0) {
             controller.rideConfirmOTPEntryController.clear();
             controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);

             controller.getUnreadThreadCount().then((value) {
               debugPrint("gettripstatuscontroller.getUnreadThreadCount: ${value}");
               if (value == "") {
                 controller.listenChatSocket();
                 controller.updateShowLocationController(controller.pickUpLoc);
                 controller.setNavigationStatus(1);
                 controller.setDriverStatus(true);
                 homeViewState.riderCancelSocket?.receiveTripCancelled("riderCancel-${globals.userid}");
                 debugPrint("gettripstatuscontroller.: ${controller.tripStatus} --- ${controller.rxRideDetailEnabledController.value}");

                 if( controller.rxRideDetailEnabledController.value == true)
                   controller.rxRideDetailEnabledController.refresh();
                 else
                   controller.rxRideDetailEnabledController.value =(true);

                 controller.riderinfoview = true;
                 homeViewState.rideDetailAnimController?.forward();
                 controller.setSwipeStart(1);
                 homeViewState.rideStartAnimController?.forward();
                 homeViewState.rideFetchAnimController?.reverse();
                 if (!controller.riderinfoview) {
                   homeViewState.animController?.reverse();
                 }

                 controller.progressController?.reverse();

                 controller.drawDestRoute(
                     LatLng(globals.userLat, globals.userLon),
                     LatLng(controller.pickLat, controller.pickLon),
                     false);
               } else if (value == "Offline") {
                 controller.showInSnackBar(
                     offline_text.tr);
               } else {
                 controller.showInSnackBar( value);
               }

               controller.change(rxVariable: controller.rxTripstartedResController, value: true);
               controller.setSwipeStart(1);
               controller.change(rxVariable: controller.rxUpdateBookingLocationController, value: true);
               controller.socketIns
                   .disconnectListen("tripStatus-${globals.userid}");
               controller
                   .onGetUpdatedBookingLocation("tripStatus-${globals.userid}");
               controller.socketIns
                   .disconnectListen("tripStart-${globals.userid}");
               homeViewState.rideStartSocket
                   ?.receiveTripStart("tripStart-${globals.userid}");
             });
           }
           else if (controller.tripStatus.compareTo("started") == 0) {
             controller.getUnreadThreadCount().then((value) {
               if (value == "") {
                 controller.listenChatSocket();
                 for (int i = 0; i < controller.locationData.length; i++) {
                   if (controller.locationData[i].locationStatus == "pending") {
                     controller.updateShowLocationController(controller.locationData[i].location);
                     break;
                   }
                 }
                 controller.change(rxVariable: controller.rxTripstartedResController, value: true);
                 controller.setNavigationStatus(2);

                 controller.socketIns
                     .disconnectListen("tripComplete-${globals.userid}");
                 homeViewState.rideCompleteSocket
                     ?.receiveTripCompleted("tripComplete-${globals.userid}");
                 controller.setDriverStatus(true);
                 homeViewState.rideStartAnimController?.reverse();
                 if( controller.rxRideDetailEnabledController.value == true)
                   controller.rxRideDetailEnabledController.refresh();
                 else
                   controller.rxRideDetailEnabledController.value =(true);
                 controller.riderinfoview = true;
                 homeViewState.rideDetailAnimController?.forward();
                 controller.setSwipeStart(1);
                 homeViewState.rideStartAnimController?.forward();
                 homeViewState.rideFetchAnimController?.reverse();
                 if (!controller.riderinfoview) {
                   homeViewState.animController?.reverse();
                 }

                 controller.progressController?.reverse();
                 controller.rideStartedAt =
                     LatLng(controller.pickLat, controller.pickLon);
               } else if (value == "Offline") {
                 controller.showInSnackBar(
                     offline_text.tr);
               } else {
                 controller.showInSnackBar( value);
               }
               controller.setSwipeStart(1);
               controller.change(rxVariable: controller.rxUpdateBookingLocationController, value: true);
               controller.updateDriverPath(false, null);
               controller.socketIns
                   .disconnectListen("tripStatus-${globals.userid}");
               controller
                   .onGetUpdatedBookingLocation("tripStatus-${globals.userid}");
             });
           }
           else if (controller.tripStatus.compareTo("cancelledByRider") == 0) {

               controller.clearMap();
               controller.riderinfoview = false;
               controller.rxRideDetailEnabledController.value =(false);
               homeViewState.rideDetailAnimController?.reverse();
               homeViewState.animController?.reverse();
               homeViewState.rideStartAnimController?.reverse();
               homeViewState.rideStartAnimController?.reverse();
               homeViewState.rideCancelledAnimController?.forward();
               controller.setStatus(true);
               controller.setNavigationStatus(-1);
             if (globals.currentShowingPage == AppRoutes.APP_CHAT) {
               Get.back();
             }
             controller.locationData.clear();

             App().initSocket().then((onValue) {
               homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
               controller.socketIns
                   .disconnectListen("tripRequest-${globals.userid}");

               if (globals.socket?.connected ?? false) {
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               } else {
                 globals.socket?.connect();
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               }
             });
           }
           else if (controller.tripStatus.compareTo("cancelledByDriver") == 0) {
             controller.clearMap();
             controller.riderinfoview = false;
             controller.rxRideDetailEnabledController.value =(false);
             homeViewState.rideDetailAnimController?.reverse();
             homeViewState.animController?.reverse();
             homeViewState.rideStartAnimController?.reverse();
             controller.setStatus(true);
             controller.setNavigationStatus(-1);
             controller.locationData.clear();
             App().initSocket().then((onValue) {
               homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
               controller.socketIns
                   .disconnectListen("tripRequest-${globals.userid}");

               if (globals.socket?.connected ?? false) {
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               } else {
                 globals.socket?.connect();
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               }
             });
           }
           else if (controller.tripStatus.compareTo("created") == 0  &&( !globals.tripFromSocket)) {

             homeViewState.rideRequestCancelSocket?.requestCancelledByRider("cancelTripRequest-${globals.userid}");
             int curr = new DateTime.now().millisecondsSinceEpoch;
             int timeInterval = curr - controller.createdAt;
               if (timeInterval < globals.notificationInterval * 1000 ) {
                   globals.progressLoadTime = globals.notificationInterval - timeInterval ~/ 1000;


               homeViewState.rideRequestSocket?.showTripRequestInfo();
             } else {
               homeViewState.internetCheckOnMapMainScreen
                   ?.checkInternetTrackLoc("declinebtnclick");
             }
             controller.socketIns
                 .disconnectListen("tripStatus-${globals.userid}");
             controller
                 .onGetUpdatedBookingLocation("tripStatus-${globals.userid}");
           }
           else if (controller.tripStatus.compareTo("expired") == 0) {
             homeViewState.rideFetchAnimController?.reverse();
             if (!controller.riderinfoview) {
               homeViewState.animController?.reverse();
             }
             controller.clearMap();
             controller.riderinfoview = false;
             controller.rxRideDetailEnabledController.value =(false);
             homeViewState.rideDetailAnimController?.reverse();
             homeViewState.animController?.reverse();
             homeViewState.rideStartAnimController?.reverse();
             homeViewState.rideStartAnimController?.reverse();
             controller.setStatus(true);
             controller.locationData.clear();

             App().initSocket().then((onValue) {
               homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
               controller.socketIns
                   .disconnectListen("tripRequest-${globals.userid}");

               if (globals.socket?.connected ?? false) {
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               } else {
                 globals.socket?.connect();
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               }
             });
           } else if (controller.tripStatus.compareTo("completed") == 0) {
             App().initSocket().then((onValue) {
               homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
               controller.socketIns
                   .disconnectListen("tripRequest-${globals.userid}");

               if (globals.socket?.connected ?? false) {
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               } else {
                 globals.socket?.connect();
                 controller.socketIns
                     .disconnectListen("tripRequest-${globals.userid}");
                 homeViewState.rideRequestSocket
                     ?.onReceivedRideRequest("tripRequest-${globals.userid}");
               }
             });
           }
         }
        }
        homeViewState.netOff = true;
      });
  }
}