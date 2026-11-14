import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/widgets/audio_chat/ai_lang_selection_widget.dart';
import '../../app/app_routes.dart';
import '../../utils/socket_connection.dart';
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../views/map_main_screen.dart';
import 'initialize_slide_transition.dart';

class MapScreenInitStateFunc {
  final MapMainController _mapMainController=Get.find();

  final HomeViewState homeViewState;

  MapScreenInitStateFunc(this.homeViewState);

  initState() {

    Future.delayed(Duration.zero).then((value) {
      if (globals.isDrawerOpen) {
        _mapMainController.scaffoldKey.currentState?.openEndDrawer();

      }
    });
    if(_mapMainController.mapStyle.isEmpty) {
      rootBundle.loadString('assets/map_style.txt').then((string) {
        _mapMainController.mapStyle = string;
      });
    }
    _mapMainController.bookingInstructionIF = homeViewState;
    _mapMainController.onReceiveLoginCheck("loginCheck-${globals.userid}");
    _mapMainController.onManualBookingCreatedByAdminCheck();
    _mapMainController.onUserPreferenceUpdated();
    _mapMainController.updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
    _mapMainController.socketIns = SocketConnection();
    _mapMainController.socketConnect();
    if (globals.userLat == 0.0 || globals.userLon == 0.0) {
      _mapMainController.zoomLevel = 3.0;
    } else {
      _mapMainController.zoomLevel = 15.0;
    }
    _mapMainController.confirmScheduleRideIF = homeViewState;
    _mapMainController.bookingInstructionIF = homeViewState;
    _mapMainController.promoStreamController(false);
    _mapMainController.getDeviceDetails();
    _mapMainController.init();
    if(_mapMainController.mapController !=null)
      _mapMainController.mapController?.dispose();
      Future.delayed(Duration(milliseconds: 50)).then((_) {
        if (!_mapMainController.isHomeScreen && (_mapMainController.isUserInTrip || (globals.tripStatus == "completed" && _mapMainController.paymentStatus != "completed"))) {
          _mapMainController.checkInternet(_mapMainController.getStatusOfRide, false);
        }
      });
      _mapMainController.updateRxValue(_mapMainController.connectingCancelController, false);


    _mapMainController.promoStreamController(false);
    ever(_mapMainController.promoStreamController, (value) {
      if ( value) {
        _mapMainController.checkInternet(
            getTripCalculation, false);
      }
    });
    globals.tripStatusChangedController("false");
    ever(globals.tripStatusChangedController, (data) {
      if (data == "true") {

          if (!(globals.socket?.connected ?? false)) {
            _mapMainController.reInitSocket();
          }
          _mapMainController.checkInternet(
              _mapMainController.getStatusOfRide, false);

        String currentstatus = globals.tripStatus;
        Future.delayed(const Duration(seconds: 5), () {
          if (currentstatus == globals.tripStatus) {
              if (!_mapMainController.isUserInTrip) {
                _mapMainController.checkInternet(
                    _mapMainController.getStatusOfRide, false);
              }
          }
        });
        globals.tripStatusChangedController("false");
      }
    }, onDone: () {
      debugPrint("Task Done");
    }, onError: (error) {
      debugPrint(" Error: ${error}");
    });
    ever(_mapMainController.scheduleRideIconController,(event){
      _mapMainController.isScheduleRideIconEnable = event;
      _mapMainController.isFromSchedule = event;
    });
    _mapMainController.setSpecialPriceController(_mapMainController.isSpecialApplied);
    print("globals.openChatFromNotificationController: listen: ${globals.openChatFromNotificationController} ");
    if(globals.openChatFromNotificationController.value !=null && globals.openChatFromNotificationController.value.toString().isNotEmpty &&  globals.openChatFromNotificationController.value != "0"){
      ChatPageNavigation();
      globals.openChatFromNotificationController.value = "0";
    }
    homeViewState.notificationnavigation = globals.openChatFromNotificationController.listen((value) async {
      print("globals.openChatFromNotificationController: ${value}");
      if (value != null && value !="0") {
        ChatPageNavigation();
      }
    });
    _mapMainController.vehicleCatAnimController?..addStatusListener((AnimationStatus status) {
      debugPrint("vehicleCatAnimController status: ${status}");

        if (status == AnimationStatus.completed) {
          _mapMainController.updatePadding( _mapMainController.mapPaddingController.value);
        }
        if (status == AnimationStatus.forward) {
          _mapMainController.tripFinalAmount = null;
        }
      });
    _mapMainController.tripAmountController?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
            _mapMainController.driverInfoAnimController?.reverse();
            _mapMainController.connectAnimController?.reverse();
           _mapMainController.sosIconController?.reverse();
        }
        if (status == AnimationStatus.forward) {
          _mapMainController.driverInfoAnimController?.reverse();
          _mapMainController.connectAnimController?.reverse();
          _mapMainController.sosIconController?.reverse();
        }
      });
    _mapMainController.rideCancelledAnimController?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
            _mapMainController.driverInfoAnimController?.reverse();
            _mapMainController.connectAnimController?.reverse();
            _mapMainController.sosIconController?.reverse();

        }
        if (status == AnimationStatus.forward) {
          _mapMainController.driverInfoAnimController?.reverse();
          _mapMainController.connectAnimController?.reverse();
          _mapMainController.sosIconController?.reverse();
        }
      });

    _mapMainController.driverInfoAnimController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(Duration(milliseconds: 400), () {
            _mapMainController.updatePadding(_mapMainController.driverInfoHeight);
          });

        } else {
          _mapMainController.updatePadding(0.0);
        }
      });

    _mapMainController.confirmPopupAnimController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _mapMainController.colorChangeController(1);
        } else if (status == AnimationStatus.reverse) {
          _mapMainController.colorChangeController(0);
        }
      });

    _mapMainController.vehicleCatDetailAnimController?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _mapMainController.colorChangeController(1);
        } else if (status == AnimationStatus.reverse) {
          
        }
      });

    _mapMainController.tripAmountController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _mapMainController.updatePadding(0.0);
          _mapMainController.paymentStatusController(0);
        } else {
          _mapMainController.updatePadding(0.0);
        }
      });
    ever(globals.currentLocation, (_){
      debugPrint("listener: globals.currentLocation changes: ${globals.currentLocation.value}");
      _mapMainController.addMyLocationMarker(globals.userLat, globals.userLon);
      _mapMainController.moveToUserLocation();
      _mapMainController.setDestPlaceController("");
    });
    debugPrint("AppLifecycleListener: ${globals.tripStatus}");
    // Store the listener on the state so it can be properly disposed in dispose().
    // Using onStateChange (rather than the shorthand onResume/onPause) lets us
    // react only when the lifecycle genuinely reaches AppLifecycleState.resumed,
    // ignoring the intermediate hidden → inactive transitions that Android fires
    // just before resumed. A _isHandlingResume flag prevents double-execution on
    // the rare occasion where Flutter delivers two consecutive resumed events.
    bool _isHandlingResume = false;
    homeViewState.lifecycleListener?.dispose();
    homeViewState.lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) async {
        debugPrint("AppLifecycleListener state: $state");
        if (state == AppLifecycleState.resumed) {
          if (_isHandlingResume) return;
          _isHandlingResume = true;
          try {
            debugPrint("getcurrentrouteapppause: ${Get.currentRoute}");
            globals.mapEnableController(true);
            svg.cache.clear();
            imageCache.clear();
            if ((_mapMainController.tripAmountController?.isCompleted ?? false) &&
                _mapMainController.rideCurrency == 4) {
              _mapMainController.paymentStatusController(0);
              return;
            }
            Future.delayed(const Duration(milliseconds: 200), () {
              _mapMainController.mapLoadingController(false);
            });
            globals.isLoaderShow = false;
            _mapMainController.position.clear();
            if (_mapMainController.mapUtils == null)
              _mapMainController.mapUtils = MapUtils();
            String tripStatus = globals.tripStatus;
            _mapMainController.getTripStatusOnly().then((onValue) async {
              debugPrint(
                  "onValuetripstatus: ${onValue} --- ${globals.tripStatus}  --- ${tripStatus}");
              if (onValue?["status"] != tripStatus) {
                _mapMainController.checkInternet(
                    _mapMainController.getStatusOfRide, false);
              } else {
                LatLng driverpos = _mapMainController.getLatLngFromLocationModel(
                        selectLocationEnum: SelectLocationEnum.bookingDriverLocation) ?? LatLng(0.0, 0.0);
                if ((onValue?["status"] == "approved" ||
                        onValue?["status"] == "locationReached" ||
                        onValue?["status"] == "started") &&
                    _mapMainController.selectedCatIcon != null) {
                  if (_mapMainController.mapUtils != null &&
                      _mapMainController.mapUtils!.isPolylineResultPending) {
                    _mapMainController.isFromAppResume = true;
                    _mapMainController.checkInternet(_mapMainController.getStatusOfRide, false);
                    return;
                  }
                  if (_mapMainController
                          .markersMap[_mapMainController.driverVehicleId] !=
                      null) {
                    _mapMainController.coordinatecurrentIndex = null;
                    _mapMainController.markersMap[
                            _mapMainController.driverVehicleId!] =
                        _mapMainController
                            .markersMap[_mapMainController.driverVehicleId]!
                            .copyWith(
                      positionParam: driverpos,
                      rotationParam: _mapMainController.bearing,
                    );
                  }
                  if (_mapMainController.mapControllerCompleter.isCompleted)
                    _mapMainController.mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: driverpos,
                        zoom: 15,
                      ),
                    ));
                  _mapMainController.position = [
                    driverpos.latitude,
                    driverpos.longitude
                  ];
                  _mapMainController.updateGoogleMap();
                } else {
                  var locationPermissionStatus = await _mapMainController
                      .listenForPermissionStatus(Permission.location);
                  switch (locationPermissionStatus) {
                    case PermissionStatus.granted:
                      await _mapMainController.requestPermission();
                      break;
                    default:
                      break;
                  }
                  debugPrint(
                      "globals.tripstatusonresume: ${tripStatus} -- ${onValue?["status"]}");
                  if (tripStatus != onValue?["status"])
                    _mapMainController.checkInternet(
                        _mapMainController.getStatusOfRide, false);
                }
              }
            });
            _mapMainController.getPreferredCurrency().then((value) {
              if (value == "update") {
                globals.languageUpdateController(true);
              }
            });
            _mapMainController
                .updatePadding(_mapMainController.mapPaddingController.value);
          } finally {
            _isHandlingResume = false;
          }
        } else if (state == AppLifecycleState.paused) {
          imageCache.clear();
          _mapMainController.position.clear();
          _mapMainController.mapLoadingController(true);
        } else if (state == AppLifecycleState.inactive) {
          if (Platform.isIOS) {
            imageCache.clear();
            _mapMainController.position.clear();
            _mapMainController.mapLoadingController(true);
          }
        }
      },
    );
  }

  getTripCalculation() {
    _mapMainController.getPrecautionNotification();
    if (_mapMainController.tripCalculationModel == null) {
      _mapMainController.getTripCalculation().then((value) {
        if (_mapMainController.locationData.isNotEmpty) {
          if (value == "offline") {
            _mapMainController.seRideNowLoadingController(2);
          } else if (value.isNotEmpty) {
            _mapMainController.strServiceUnavailable = value;
            _mapMainController.seRideNowLoadingController(2);
            _mapMainController.showInSnackBar(value);
          } else {
            if (!_mapMainController.isScheduleRideIconEnable) {
              if (_mapMainController.nearestDriversCategoryList[_mapMainController
                  .selectedCabIndex].lat != 0.0 &&
                  _mapMainController.nearestDriversCategoryList[_mapMainController
                      .selectedCabIndex].lat != null)
                _mapMainController.isCabAvailable = true;
              else {
                _mapMainController.isCabAvailable = false;
              }
              _mapMainController.seRideNowLoadingController(1);
              _mapMainController.setLocIconPositionForCategory();
              debugPrint("vehicleCatAnimController open:");
              _mapMainController.vehicleCatAnimController?.forward();
                _mapMainController.tripAmountController?.reverse();

            }
          }
        }});
    }
  }

  void ChatPageNavigation() async{
    bool internetConnect = await _mapMainController.checkConnectivity();
    print("globals.aipreferlang: ${globals.aiPreferredLanguage} --- ${ globals.isVoiceTranslatorEnable}");
    if ( internetConnect) {
      if( globals.isVoiceTranslatorEnable && globals.aiPreferredLanguage.isEmpty ) {
        if(Get.isBottomSheetOpen ?? false) {
          return;
        }
        VoiceChatBottomSheet(NavigateFunction: () async{
          bool internetConnect = await _mapMainController.checkConnectivity();
          if (internetConnect != null && internetConnect) {
            debugPrint("VoiceChatBottomSheet naivgation");
            _mapMainController.setNavigation(AppRoutes.APP_CHAT);
          } else {
            _mapMainController.showInSnackBar('offline_text'.tr);
          }
        });
        return;
      };
      _mapMainController.setNavigation(AppRoutes.APP_CHAT);
    } else {
      _mapMainController.showInSnackBar('offline_text'.tr);
    }
  }
}