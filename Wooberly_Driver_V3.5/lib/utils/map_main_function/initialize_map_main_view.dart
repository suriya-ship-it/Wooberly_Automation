import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/map_main_function/graphql_fetch_on_map_main.dart';
import 'package:wooberly_driver/utils/map_main_function/internet_check_on_map_main.dart';
import 'package:wooberly_driver/utils/map_main_function/location_fetch_on_map_main.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/driver_cancel_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/driver_currency_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/driver_wallet_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_accept_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_complete_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_request_cancel_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_request_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_start_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/rider_cancel_socket.dart';
import 'package:wooberly_driver/views/map_main_screen.dart';

import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_lang.dart';
import '../../widgets/ai_lang_selection_widget.dart';
import '../../widgets/map_screen_widget/map_based_views.dart';
import '../../widgets/map_screen_widget/map_navigate_button_view.dart';
import '../../widgets/primary_scaffold.dart';
import '../socket_connection.dart';
import 'map_view_socket_connection.dart';
import 'socket_function/driver_login_socket.dart';
import 'socket_function/ride_decline_socket.dart';
import 'socket_function/trip_payment_socket.dart';

class InitializeMapMainView {
  InitializeMapMainView(HomeViewState state, MapMainController controller) {
    debugPrint("InitializeMapMainViewglobals.isActive: ${globals.isActive}");
    controller.rxOnlineStatus = ReactiveVariable("rxOnlineStatus", globals.isActive);
    state = controller.homeViewState;
    globals.progressLoadTime = globals.notificationInterval;
    state.preferredCurr = globals.preferredCurrency;
    state.mapBasedViews = MapBasedViews(homeViewState: state);
    state.mapBasedViews?.initializeAnimationController(state);
    PrimaryScaffold.avoidLoader = true;

    state.graphQLFetchOnMapMainScreen =
        GraphQLFetchOnMapMainScreen(state: state);
    state.internetCheckOnMapMainScreen =
        InternetCheckOnMapMainScreen(state: state);
    state.locationFetchOnMapMainScreen =
        LocationFetchOnMapMainScreen(state: state);
    state.socketConnectionOnMapMainScreen = SocketConnectionOnMapMainScreen(homeViewState: state);

    if (globals.isDarkTheme) {
      rootBundle.loadString('assets/map_style_dark.txt').then((string) {
        state.mapStyle = string;
      });
    } else {
      rootBundle.loadString('assets/map_style.txt').then((string) {
        state.mapStyle = string;
      });
    }
    globals.isShowMapPage = true;
    print("noficaid: ${globals.openChatFromNotificationController.value}");
    if(globals.openChatFromNotificationController.value !=0){
      ChatPageNavigation(controller,globals.openChatFromNotificationController.value,state);
      globals.openChatFromNotificationController.value = 0;
    }
    globals.openChatFromNotificationController.stream.listen((value) async {
      if (value != 0) {
        ChatPageNavigation(controller,value,state);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init();
    });
    controller.socketIns = SocketConnection();
    controller.totalEarings = -1;
    controller.socketIns.disconnectListen("loginCheck-${globals.userid}");
    controller.socketIns.disconnectListen("updatePreferredCurrency-${globals.userid}");

    state.mapNavigateButtonView = MapNavigateButtonView(
      homeViewState: state,
    );
    state.rideRequestSocket = RideRequestSocket();
    state.rideDeclineSocket =
        RideDeclineSocket(state: state);
    state.riderCancelSocket =
        RiderCancelSocket(state: state);
    state.rideRequestCancelSocket =
        RideRequestCancelSocket(state: state);
    state.driverLoginSocket =
        DriverLoginSocket(state: state);
    state.driverWalletSocket =
        DriverWalletSocket(state: state);
    state.driverCurrencySocket =
        DriverCurrencySocket(state: state);
    state.tripPaymentSocket =
        TripPaymentSocket(state: state);
    state.driverCancelSocket =
        DriverCancelSocket(state: state);
    state.rideAcceptSocket =
        RideAcceptSocket(state: state);
    state.rideCompleteSocket =
        RideCompleteSocket(state: state);
    state.rideStartSocket =
        RideStartSocket(state: state);
    state.driverLoginSocket?.onReceiveLoginCheck("loginCheck-${globals.userid}");
    state.driverLoginSocket
        ?.onUserPreferenceUpdated();
    state.driverWalletSocket
        ?.onDriverWalletCheck();
    state.driverCurrencySocket?.updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
    controller.socketIns.disconnectListen("driverApprove-${globals.userid}");
    state.rideAcceptSocket?.onDriverApproved("driverApprove-${globals.userid}");

    state.socketConnectionOnMapMainScreen?.socketConnect();
    if (globals.isActive) {
      controller.setDriverStatus(globals.isActive);
      controller.isLocationPermissionsEnabled().then((isenabled){
        if(isenabled){
          controller.getInitialLocation(4);
        }
      });
      App().setBgLocationInfo_IOS(
          globals.authToken, globals.userid, globals.deviceId);
      state.socketConnectionOnMapMainScreen?.socketConnect();

      if (globals.socket?.connected ?? false) {
        controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
        state.rideRequestSocket?.onReceivedRideRequest("tripRequest-${globals.userid}");
      } else {
        globals.socket?.connect();
        controller.socketIns.disconnectListen("tripRequest-${globals.userid}");
        state.rideRequestSocket
            ?.onReceivedRideRequest("tripRequest-${globals.userid}");
      }

    } else {
      locationGrantedCheck(state, controller);
    }
    controller.setLoadingController(true);

    Future.delayed(Duration(milliseconds: 50)).then((_) {
      if (globals.tripInfo != null &&
          globals.tripInfo.isNotEmpty &&
          globals.tripInfo['tripStatus']
                  .toString()
                  .compareTo("cancelTripRequest") ==
              0) {
        state.rideRequestCancelSocket?.cancelledByRider(1);
      } else {
        bool isInTrip =   (controller.tripStatus == "approved" ||
            controller.tripStatus == "locationReached" ||
            controller.tripStatus == "started"||
            controller.tripStatus == "created"
        );
        state.driverLoginSocket?.onReceiveLoginCheck("loginCheck-${globals.userid}");
        debugPrint("controller.tripstatus: ${controller.tripStatus} --- ${isInTrip}");
        if (globals.isActive && isInTrip) {
          controller.checkInternet(state.socketConnectionOnMapMainScreen!.getTripStatus, null);
        } else {
          controller.getTripStatusOnly().then((onValue) {
            bool isInTrip =   (controller.tripStatus == "approved" ||
                controller.tripStatus == "locationReached" ||
                controller.tripStatus == "started"||
                controller.tripStatus == "created"
            );
            if(isInTrip)
            controller.checkInternet(state.socketConnectionOnMapMainScreen!.getTripStatus, null);
          });
        }
        controller.checkInternet(state.graphQLFetchOnMapMainScreen!.getTripSummary, false);
      }
    });
    globals.tripStatusChangedController.value = false;
    globals.tripStatusChangedController.stream.listen((data) {
      if (data) {
        if (globals.tripInfo != null &&
            globals.tripInfo.isNotEmpty &&
            globals.tripInfo is Map &&
            globals.tripInfo['tripStatus']
                    .toString()
                    .compareTo("tripRequest") ==
                0) {
          Future.delayed(const Duration(milliseconds: 5000), () {
            int curr = new DateTime.now().millisecondsSinceEpoch;

            int timeInterval = (curr.round()) -
                (int.parse(globals.tripInfo['requestTime'].toString()).round());
            controller.getTripStatusOnly().then((onValue) {
              if (onValue == "created" &&
                  !globals.tripFromSocket &&
                  !controller.isDriverAccept()) {
                if (timeInterval < globals.notificationInterval * 1000) {
                  state.rideRequestSocket?.showTripAcceptInfo();
                } else {
                  controller.bookingID = globals.tripInfo["bookingId"];
                  controller.riderID = globals.tripInfo["riderId"];
                  state.rideDeclineSocket?.sendTripCancel();
                }
              }
            });
          });
        } else if (globals.tripInfo != null &&
            globals.tripInfo.isNotEmpty &&
            globals.tripInfo is Map &&
            globals.tripInfo['tripStatus']
                    .toString()
                    .compareTo("tipsReceived") ==
                0) {
          controller.checkInternet(state.graphQLFetchOnMapMainScreen!.getTripSummary,
              false);
        } else if (globals.authToken?.isEmpty ?? true) {
          state.rideRequestCancelSocket?.cancelledByRider(2);
          globals.tripInfo = "";
        } else if (globals.tripInfo != null &&
            globals.tripInfo.isNotEmpty &&
            globals.tripInfo is Map &&
            globals.tripInfo['tripStatus'].toString().compareTo("updateStop") ==
                0) {
          controller.checkInternet(
              state.socketConnectionOnMapMainScreen!.getTripStatus,
              null);
        } else {
          Future.delayed(Duration(seconds: 5)).then((_) {
            if (globals.tripInfo['tripStatus'].toString() !=
                controller.tripStatus)
              controller.checkInternet(
                  state.socketConnectionOnMapMainScreen!.getTripStatus,
                  null);
          });
        }
        globals.tripStatusChangedController.value = false;
      }
    });
    controller.getcurrentloc();
    if (globals.isActive) {
      state.locationFetchOnMapMainScreen?.allocateAndroidService();
      state.setWakeLockEnableDisable(globals.screenAwake);
    } else {
      state.setWakeLockEnableDisable(globals.screenAwake);
    }
    globals.showDialogController.stream.listen((value) {
      if (value.isNotEmpty) {
        Get.dialog(
          barrierDismissible: false,
          Obx(
            () {
              return globals.isAutoThemeUpdated.value != null ? AlertDialog(
                backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                title: Text(
                  value["title"],
                ),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        globals.isShowMapPage = true;
                        int curr = new DateTime.now().millisecondsSinceEpoch;
                        int timeinterval = curr - globals.requestTime;
                        globals.progressLoadTime = globals.notificationInterval;
                        if (timeinterval < globals.notificationInterval * 1000) {
                          if (state.mounted) {
                              globals.progressLoadTime = globals.progressLoadTime - (timeinterval / 1000).toInt();
                          }
                        }
                        Get.back(result: 'dialog');
                        globals.tripStatusChangedController.value = true;
                        if (globals.vehicleId != 0) {
                          globals.isShowMapPage = true;
                          try {
                            if (Get.isDialogOpen == true)
                            Get.back(result: 'dialog');
                            Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN || route.settings.name == "/MapMainScreen" || route.isFirst);
                          } on Exception catch (e, stack) {
                            print("Error: $e");
                            FirebaseCrashlytics.instance.recordError(e, stack);
                          }
                        } else {
                          globals.isShowMapPage = true;
                          Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN || route.settings.name == "/MapMainScreen" || route.isFirst);
                        }
                      },
                      child: Text(
                        okay.tr,
                      ))
                ],
                content: Text(
                  value["body"],
                ),
              ) : SizedBox.shrink();
            }
          )
        );
      }
    });

    state.rideFetchAnimController
      ?..addStatusListener((AnimationStatus status) async {
        if (status == AnimationStatus.completed) {
          controller.updateMapPaddingController(state.timerHeight);
        } else {
          if (controller.isDriverAccept()) {
            controller.rxMapPaddingController.refresh();
          } else {
            controller.updateMapPaddingController(state.bottomSheetHeight);
          }
        }
      });

    state.riderInfoAnimController
      ?..addStatusListener((AnimationStatus status) async {
        if (status == AnimationStatus.completed) {
          controller.updateMapPaddingController(state.riderInfoHeight);
        } else {
          if (controller.isDriverAccept()) {
            controller.rxMapPaddingController.refresh();
          } else {
            controller.updateMapPaddingController(state.bottomSheetHeight);
          }
        }
      });

    state.tripAmountController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          controller.updateMapPaddingController(state.finalAmountHeight);
        } else {
          controller.updateMapPaddingController(state.bottomSheetHeight);
        }
      });
    state.tripCashPopupController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          PrimaryScaffold.updatedLoader = 'assets/lottieloader_dark.json';
          controller.change(rxVariable: controller.rxColorChangeController, value: 1);
        } else {
          PrimaryScaffold.updatedLoader = null;
          controller.change(rxVariable: controller.rxColorChangeController, value: 0);
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.change(rxVariable: controller.rxMapLoadingController, value: true);
      Future.delayed(const Duration(milliseconds: 600), () {
        controller.change(rxVariable: controller.rxMapLoadingController, value: false);
      });
    });


    controller.checkInternet(
        state.tripPaymentSocket!.TripPayment,
        true);
    state.appLifecyclelistener = () async {
      String   msg = globals.appLifecycleController.value;
      debugPrint("appLifecyclelistenermsg: ${msg}");
      if (msg == "AppLifecycleState.resumed") {
        controller.isAppResume = true;
        if (globals.socket == null) {
          App().initSocket();
        } else if (!globals.socket!.connected) {
          globals.socket!.connect();
        }
        controller.getTripStatusOnly().then((onValue) {
          if (state.previousStatus != controller.tripStatus) {
            if (globals.isActive) {
              if (globals.socket?.connected ?? false) {
                controller.checkInternet(
                    state.socketConnectionOnMapMainScreen!.getTripStatus,
                    null);
              } else {
                globals.socket?.connect();
                controller.checkInternet(
                    state.socketConnectionOnMapMainScreen!.getTripStatus,
                    null);
              }
            }
            state.previousStatus = controller.tripStatus;
          }
          controller.checkInternet(
              controller.getPaymentSettings,
              null);

          controller.getPreferredCurrency().then((value){
            if(value == "update"){
              state.asyncLanguageDialog(
                  dialogContent: update_preferred_currency_content.tr,
                  onTap: (){
                globals.audioPlayer?.pause();
                globals.tripFromSocket = false;
                Get.offAll(App().getAppRoutes().getWidget(AppRoutes.APP_SPLASH), predicate: (Route<dynamic> route) => false);
              });
            }
          });
          controller.polylineoldLocation = LatLng(0.0, 0.0);
          controller.updateDriverPath(true, null);
        });
      }

      if (msg == "AppLifecycleState.resumed" && state.openSettings) {
        controller.setDriverStatus(globals.isActive);
      } else if (msg == "AppLifecycleState.resumed" && await App().isLocationServiceEnable()) {
        controller.position = [];
        controller.markerMoveIteration = 0;
        if(await Permission.location.isGranted){

          await controller.getLocation("", 'disable');
          debugPrint("resumemapLocation: ${controller.mapLocation} --- ${state.locationSubscription} --- ${controller.mapController} --- ${globals.isActive}");
          if(state.locationSubscription == null && globals.isActive){
            state.locationFetchOnMapMainScreen?.allocateAndroidService();
          }
          if (controller.mapController != null) {
            debugPrint("camera animate 5");
            controller.mapController
                ?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(globals.userLat, globals.userLon),
                zoom: 15,
              ),
            ));
          }
        }


        controller.getUserAILanguage(isShowLoader: false);
        controller.trackLocation();
        controller.coordinatecurrentIndex = null;

        await controller.updateDriverPath(false, null);
      } else if (msg == "AppLifecycleState.resumed") {
        // Location service is disabled — poll briefly then request permission
        Future.delayed(Duration(milliseconds: 5550)).then((_) {
          App().isLocationServiceEnable().then((value) {
            if (value) {
              Permission.location.request().then((permissionvalue) {
                if (permissionvalue == PermissionStatus.granted) {
                  controller.getInitialLocation(4);
                }
              });
            }
          });
        });
      } else if (msg == "AppLifecycleState.paused") {
        state.previousStatus = controller.tripStatus;
        controller.isAppResume = false;
      }else if (msg == "AppLifecycleState.inactive") {
        state.previousStatus = controller.tripStatus;
        controller.isAppResume = false;
      }
    };
    if(state.appLifecyclelistener !=null)
    globals.appLifecycleController.addListener(state.appLifecyclelistener!);
    controller.getPaymentSettings();

  }


  locationGrantedCheck(HomeViewState state, MapMainController controller) {
    if (globals.driverStatus == "active") {
      controller.getTripStatusOnly().then((value) async{
        var tripStatus = value;
        StreamSubscription<bool>? streamsub;

        if ((tripStatus == "approved" ||
            tripStatus == "started" ||
            tripStatus == "locationReached")) {
          if (!globals.isActive) {
            state.graphQLFetchOnMapMainScreen?.goOnline();
            streamsub = controller.rxOnlineStatusController.stream.listen((event) {
              if (event) {
                controller.checkInternet(
                    state.socketConnectionOnMapMainScreen!.getTripStatus,
                    null);
                streamsub?.cancel();
              }
            });
          }
        }
        if (globals.isActive) {
            if ((tripStatus == "approved" ||
                tripStatus == "started" ||
                tripStatus == "locationReached")) {
              controller.setDriverStatus(globals.isActive);
            } else {
              bool isLocationPermissionEnable = await  controller.isLocationPermissionsEnabled();
              debugPrint("globals.isActive: ${globals.isActive} --- ${isLocationPermissionEnable}");
              if(!globals.isActive || !isLocationPermissionEnable) {
                globals.isActive = false;
                controller.change(rxVariable: controller.rxOnlineStatus, value: false);
                state.graphQLFetchOnMapMainScreen?.goOffline();
              }
            }

        } else {
           // controller.change(rxVariable: controller.rxOnlineSliderController, value: true);
            debugPrint("appresumen  granted");
            state.graphQLFetchOnMapMainScreen?.goOffline();

        }
      });
    }
  }

  ChatPageNavigation(MapMainController controller, bookid,HomeViewState state)async {
    bool internetConnect = await controller.checkConnectivity();
    if (internetConnect != null && internetConnect) {
      controller.bookingID = bookid;
      debugPrint("openchat: ${globals.isVoiceTranslatorEnable} -- ${globals.aiPreferredLanguage} --- ${controller.isVoiceChatLangSelectOpen}");
      if(controller.isVoiceChatLangSelectOpen) return;
      if( globals.isVoiceTranslatorEnable && globals.aiPreferredLanguage.isEmpty) {
        VoiceChatBottomSheet(NavigateFunction: () async{
          bool internetConnect = await controller.checkConnectivity();
          if (internetConnect != null && internetConnect) {
            App().setNavigation(AppRoutes.APP_CHAT);
          } else {
            controller.showInSnackBar('offline_text'.tr);
          }
        });
        return;
      }
      App().setNavigation(AppRoutes.APP_CHAT);
    } else {
      App().toast.show(
        context: state.context,
        message: offline_text.tr,
      );
    }
  }


}