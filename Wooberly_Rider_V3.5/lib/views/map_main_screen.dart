import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/views/booking_instructions.dart';
import 'package:app_name/views/cancel_trip.dart';
import 'package:app_name/views/confirm_schedule_ride.dart';
import 'package:app_name/views/ride_comfort.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/widgets/map_main_drawer.dart';
import 'package:app_name/widgets/map_screen_widgets/init_state_func.dart';
import 'package:app_name/widgets/map_screen_widgets/show_confirm_popup.dart';
import 'package:app_name/widgets/map_screen_widgets/show_drawer_icon.dart';
import 'package:app_name/widgets/map_screen_widgets/show_location_icon.dart';
import 'package:app_name/widgets/map_screen_widgets/show_map.dart';
import 'package:app_name/widgets/map_screen_widgets/show_ride_confirmation_otp.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import 'package:app_name/widgets/schedule_ride.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/app.dart';
import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/map_screen_widgets/driver_info_sheet.dart';
import '../widgets/map_screen_widgets/initialize_slide_transition.dart';
import '../widgets/map_screen_widgets/rider_cancel_sheet.dart';
import '../widgets/map_screen_widgets/safety_toolkit_body.dart';
import '../widgets/map_screen_widgets/show_connecting.dart';
import '../widgets/map_screen_widgets/show_dest_location_on_top.dart';
import '../widgets/map_screen_widgets/show_driver_refetch_icon.dart';
import '../widgets/map_screen_widgets/show_home_icon.dart';
import '../widgets/map_screen_widgets/show_map_grid.dart';
import '../widgets/map_screen_widgets/show_sos_button.dart';
import '../widgets/map_screen_widgets/show_vehicle_category.dart';
import '../widgets/map_screen_widgets/show_vehicle_details.dart';
import '../widgets/map_screen_widgets/show_ride_type_selection.dart';
import '../widgets/map_screen_widgets/trip_amount.dart';
import '../widgets/map_screen_widgets/will_pop_scope_function.dart';

class MapMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}

class HomeView extends StatefulWidget {
  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView>
    with TickerProviderStateMixin
    implements ScheduleRideControllerIF, ConfirmScheduleRideIF, BookingInstructionIF {
  MapMainController mapMainController = Get.find();
  String _isVehicleCategoryOpen = "";
  StreamSubscription? notificationnavigation;
  AppLifecycleListener? lifecycleListener;

  @override
  void initState() {
    debugPrint("getcurrentrouteauth: ${globals.authToken}");
    graphQlObject.getGraphQlClientWithHeader();
    if (globals.socket == null) mapMainController.initSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        mapMainController.mapLoadingController(true);
      MapScreenInitStateFunc(this).initState();
    });
    InitializeSlideTransition(this).initialize();


    ever(mapMainController.bookingInstructionController, (event) {
      if (!mapMainController.isScheduleRide) mapMainController.bookingInstructionIF = this;

    });

    mapMainController.socketIns?.disconnectListen("driverApprove-${globals.userid}");
    onDriverApproved("driverApprove-${globals.userid}");

    if (globals.paymentMethods == null) mapMainController.getPaymentMethods();


    Future.delayed(Duration(milliseconds: 200)).then((value) {
      mapMainController.vehicleCatAnimController?.addListener(() {
        if (mapMainController.vehicleCatAnimController?.status == AnimationStatus.forward ||
            mapMainController.vehicleCatAnimController?.status == AnimationStatus.completed) {
          mapMainController.tripFinalAmount = null;
          if (_isVehicleCategoryOpen != "open" || _isVehicleCategoryOpen.isEmpty)
            _isVehicleCategoryOpen = "open";
        } else {
          if (_isVehicleCategoryOpen != "close" || _isVehicleCategoryOpen.isEmpty)
            _isVehicleCategoryOpen = "close";
          mapMainController.mapPaddingController.refresh();
        }
      });
    });

    globals.isLoaderShow = false;
    mapMainController.getTripStatusOnly().then((value) {
      if (value != null) {
        String? status = value["status"];
        List<String> activeStatuses = ["created", "approved", "locationReached", "started"];
        if (activeStatuses.contains(status)) {
          mapMainController.checkInternet(mapMainController.getStatusOfRide, false);
        }
      }
    });

    if (globals.isVoiceTranslatorEnable) globals.baseController.getAILanguageList(isShowLoader: false);
    globals.waveGradient = LinearGradient(
      end: globals.isRTLLang ? Alignment.centerRight : Alignment.centerRight,
      begin: globals.isRTLLang ? Alignment.centerLeft : Alignment.centerLeft,
      colors: [
        AppColors.VOICE_WAVEFORM_COLOR1,
        AppColors.VOICE_WAVEFORM_COLOR2,
      ],
    );

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapMainController.updateRxValue(mapMainController.connectingCancelController, false);
    });
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      if (mapMainController.mapUtils != null &&
          mapMainController.polyLines != Polyline(polylineId: PolylineId(''))) {
        final updatedPolyline = mapMainController.mapUtils?.updatePolylineColor();
        if (updatedPolyline != null) {
          mapMainController.polyLines = updatedPolyline;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapMainController.mapRefreshController(true);
        });
      }

      mapMainController.blackLinearGradient = LinearGradient(
        begin: globals.isRTLLang ? Alignment.centerRight : Alignment.centerRight,
        end: globals.isRTLLang ? Alignment.centerLeft : Alignment.centerLeft,
        colors: [
          AppColors.PRIMARY_DARK_COLOR,
          AppColors.PRIMARY_DARK_COLOR,
        ],
      );
      return GetBuilder<MapMainController>(builder: (ctrl) {
        return PrimaryScaffold(
          disableAppbar: true,
          customAppBarFunction: () {
            WillPopScopeFunction( context,
                    mapMainController.scaffoldKey, this)
                .popFunc();
          },
          resizeToAvoidBottomInset: false,
          onChanged: (map) {
            mapMainController.scaffoldKey = map["scaffoldkey"];
          },
          body: Container(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            child: Stack(
              children: <Widget>[
                Stack(children: <Widget>[
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: _isVehicleCategoryOpen == "open" ? 200 : 0),
                    child: ShowMapView(
                      isFrom: AppRoutes.APP_MAP_MAIN,
                    ),
                  ),
                  Obx(() {
                    return mapMainController.mapPaddingController.value != 0.0
                        ? Container(
                            padding: EdgeInsetsDirectional.only(
                                bottom: mapMainController.mapPaddingController.value),
                            alignment: AlignmentDirectional.bottomStart,
                            child: Image.asset(
                              googleLogoPng,
                              height: 25,
                            ))
                        : const SizedBox.shrink();
                  }),
                  ShowMapGridIcon(),
                  ShowDrawerIcon(
                    scaffoldKey: mapMainController.scaffoldKey,
                  ),
                  ShowRideConfirmationOtp(
                    scaffoldKey: mapMainController.scaffoldKey,
                  )
                ]),
                ShowDriverReFetchIcon(this),
                ShowLocationIcon(),
                ShowHomeIcon(),
                ShowDestLocationOnTop(state: this),
                ShowSOSButton(
                  bottomSheetSafetyToolKit: _bottomSheetSafetyToolKit,
                ),
                ShowConnecting(),
                ShowVehicleCategory(),
                ShowConfirmPopup(state: this),
                ShowVehicleDetails(),
                ShowRideTypeSelection(),
                ShowDriverInfoSheet(
                  state: this,
                ),
                TripAmount(),
                RiderCancelSheet(viewModel: mapMainController),
                RideComfortView(state: this),
                Obx(
                  () {
                    return mapMainController.scheduleRideScreenController.value == true
                        ? ScheduleRide(
                        (mapMainController.locationData.isNotEmpty ?mapMainController.locationData.first.location :
                        globals.currentLocation.value.isNotEmpty ? globals.currentLocation.value: '') ?? '',
                        (mapMainController.locationData.length>1 ?mapMainController.locationData.last.location : '') ?? '',
                            // mapMainController.locationData.first.location ?? '',
                            // mapMainController.locationData.last.location ?? '',
                            this,
                            mapMainController.isScheduleRide
                                ? mapMainController.selScheduleFromDateTime!
                                : mapMainController.getTimeByAddMin(
                                    DateTime.now(), globals.scheduleRestrictionTime + 1),
                            false,
                            mapMainController.isScheduleRide)
                        : const SizedBox.shrink();
                  },
                ),
                Obx(() {
                  return mapMainController.bookingInstructionController.value == true
                      ? BookingInstructionsViewState()
                      : const SizedBox.shrink();
                }),
              ],
            ),
          ),
          endDrawer: MapMainDrawer(
            callback: setDrawerOpened,
          ),
        );
      });
    });
  }

  String preffcurr = "", preflang = "";

  void setDrawerOpened(bool isOpen) {
    globals.isShowMapPage = !isOpen;
    globals.isDrawerOpen = isOpen;
    mapMainController.isFromForSettings = "mappage";

    if (!isOpen) {
      if ((preffcurr != globals.preferredCurrency ||preflang != globals.preferredLanguage || mapMainController.isSelectMapLocation) &&
          mapMainController.locationData.isNotEmpty &&
          !mapMainController.isUserInTrip &&
          globals.tripStatus != "created") {
        mapMainController.tripCalculationModel = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapMainController.seRideNowLoadingController(0);
          if (globals.currencyRates.isNotEmpty) {
            mapMainController.openVehicleCategoryList(mapMainController.isScheduleRideIconEnable);
          } else {
            mapMainController.getCurrencyRates().then((currencyRate) {
              if (currencyRate?.isEmpty ?? false) {
                mapMainController.openVehicleCategoryList(mapMainController.isScheduleRideIconEnable);
              } else {
                mapMainController.checkInternet(() {}, false);
              }
            });
          }
        });
      } else if ((preffcurr != globals.preferredCurrency || preflang != globals.preferredLanguage) &&
          mapMainController.locationData.isNotEmpty &&
          mapMainController.isUserInTrip) {
        mapMainController.checkInternet(mapMainController.getStatusOfRide, false);
      }

      debugPrint("mapMainController.lastDrawnRouteCredentials: ${ mapMainController.vehicleCatAnimController?.status} --- ${globals.tripStatus} --- ${globals.isDrawerOpen} ");
      if (!mapMainController.isUserInTrip &&
          globals.tripStatus != "created" &&
          mapMainController.locationData.isEmpty) {
        mapMainController.destLocAnimController?.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapMainController.setDestPlaceController("");
        });
      }

      else if (!mapMainController.isUserInTrip &&
          globals.tripStatus != "created" &&
          mapMainController.locationData.isNotEmpty && mapMainController.vehicleCatAnimController?.status != AnimationStatus.completed ) {
        mapMainController.vehicleCatAnimController?.forward();
        mapMainController.destLocAnimController?.forward();
        mapMainController.drawDestRoute(
            mapMainController.locationData.first.latLng!,
            mapMainController.locationData.last.latLng!);
      }
    } else {
      preffcurr = globals.preferredCurrency;
      preflang = globals.preferredLanguage;
    }
  }

  @override
  void dispose() {
    mapMainController.isInitialGetTripStatusLoading = false;
    if (mapMainController.mapControllerCompleter.isCompleted &&
        mapMainController.mapController != null) {
      mapMainController.mapController?.dispose();
      mapMainController.mapController = null;
      mapMainController.mapControllerCompleter = Completer<GoogleMapController>();
    }
    try {
      notificationnavigation?.cancel();
    } catch (_) {}
    lifecycleListener?.dispose();
    super.dispose();
  }

  getCancelReason() async {
    mapMainController.updateRxValue(mapMainController.cancelReasonListController, true);
    Get.to(
        CancelTrip(
          state: this,
        ),
        duration: Duration(milliseconds: 215),
        transition: Transition.rightToLeft);
  }

  void cancelRide() {
    mapMainController.driverInfoAnimController?.reverse();
    String selectedCancelReason = "";
    LatLng droppos = mapMainController.locationData.last.latLng!;

    if (droppos.latitude != 0.0 && droppos.longitude != 0.0) {
      if (mapMainController.otherReasonController.text != null &&
          mapMainController.otherReasonController.text.isNotEmpty) {
        selectedCancelReason = mapMainController.otherCancelReason;
      } else {
        selectedCancelReason = mapMainController.selectedCancelReason['reason'];
      }
      mapMainController.onTripCancelled("riderCancel", selectedCancelReason.trim());
      mapMainController.socketIns?.disconnectListen("riderCancel-${globals.userid}");

      mapMainController.onCancelResponse("riderCancel-${globals.userid}");
    }
    cancelReasonAnimReverse();
    mapMainController.clearMap();
    globals.userLat = 0.0;
    globals.userLon = 0.0;
    mapMainController.getCurrentLocation().then((value) {
      mapMainController.setCurrentLocation(LatLng(globals.userLat, globals.userLon));
    });

    mapMainController.clearMap();
    mapMainController.locationData.clear();
    mapMainController.closeTripPlannerPage();
    mapMainController.setDestPlaceController("");
    mapMainController.destLocAnimController?.forward();

    Future.delayed(Duration(milliseconds: 2000)).then((_) {
      globals.isLoaderShow = false;
      mapMainController.getTripStatusOnly().then((onValue) {
        if (onValue?["id"] == mapMainController.bookingId &&
            (mapMainController.isUserInTrip || onValue?["status"] == "completed")) {
          mapMainController.checkInternet(mapMainController.getStatusOfRide, true);
        }
      });
    });
  }

  void _bottomSheetSafetyToolKit() {
    App().showBottomSheet(SafetyToolKitBody());
  }

  cancelReasonAnimReverse() {
    mapMainController.backCancelReason = false;
    mapMainController.selectedCancelReason = null;
    mapMainController.updateRxValue(mapMainController.radioListSelectController, false);
    mapMainController.updateRxValue(mapMainController.otherReasonSelectController, true);
    mapMainController.otherReasonController.text = "";
  }

  @override
  void scheduleRideController(String data, DateTime selectedDateTime) {
    if (!((mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed))) {
      if (data == "cancel") {
        mapMainController.isFromSchedule = false;
        mapMainController.isScheduleRide = false;
        mapMainController.selScheduleFromDateTime = DateTime.now();
        mapMainController.scheduleRideIconController(false);
        mapMainController.scheduleRideIconController.refresh();

        mapMainController.scheduleRideScreenController(false);
        mapMainController.isScheduleRideIconEnable = false;

        mapMainController.updatePadding(0.0);
        mapMainController.getScheduleCategoryList(false);
      } else if (data == "select") {
        mapMainController.isFromSchedule = true;
        mapMainController.selScheduleFromDateTime = selectedDateTime;
        moveToDropLocationFromSchedule();
        globals.closeKeyBoard = false;
        mapMainController.isScheduleRide = false;
      } else if (data == "next") {
        mapMainController.selScheduleFromDateTime = selectedDateTime;
        mapMainController.isScheduleRide = true;
        mapMainController.isScheduleRideIconEnable = true;
        mapMainController.scheduleRideIconController(true);
        mapMainController.scheduleRideIconController.refresh();
        mapMainController.scheduleRideScreenController(false);

        mapMainController.updatePadding(220);
        mapMainController.getScheduleCategoryList(true);
        mapMainController.isScheduleRideTripSelected.value = true;
      } else if (data == "cancel screen") {
        if (!mapMainController.isScheduleRideIconEnable) {
          mapMainController.isFromSchedule = false;
          mapMainController.isScheduleRideTripSelected.value = false;
        } else {
          mapMainController.isFromSchedule = true;
          mapMainController.isScheduleRideTripSelected.value = true;
        }
        mapMainController.scheduleRideScreenController(false);

      }
    } else {
      mapMainController.scheduleRideScreenController(false);
    }
  }

  moveToDropLocationFromSchedule() {
    mapMainController.socketIns?.disconnectListen("loginCheck-${globals.userid}");
    mapMainController.onReceiveLoginCheck("loginCheck-${globals.userid}");
    mapMainController.onManualBookingCreatedByAdminCheck();
    mapMainController.onUserPreferenceUpdated();
    mapMainController.socketIns?.disconnectListen("updatePreferredCurrency-${globals.userid}");
    mapMainController.updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
    if (!(mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed)) {
      Get.to(() => SelectDropLocation(true));
    }
  }

  @override
  void confirmScheduleRideController() {
    mapMainController.locationData.clear();
    mapMainController.lastKnownLocation = LatLng(0.0, 0.0);
    mapMainController.destLocAnimController?.forward();
    mapMainController.setDestPlaceController("");
    mapMainController.clearMap();
    mapMainController.isScheduleRideIconEnable = false;
    mapMainController.isScheduleRide = false;
    mapMainController.isScheduleRideConfirmed = false;
    mapMainController.scheduleRideIconController(false);
    mapMainController.scheduleRideIconController.refresh();
    mapMainController.setCurrentLocation(LatLng(0.0, 0.0));
    mapMainController.vehicleCatAnimController?.reverse();
    mapMainController.vehicleCatDetailAnimController?.reverse();
  }

  @override
  void moveToLocationSelectionPage(BuildContext context) {
    if (mapMainController.isScheduleRide) {
      mapMainController.isScheduleRideConfirmed = true;
    }
    if (mapMainController.isFromSchedule) {
      Get.to(SelectDropLocation(true));
    } else {
      mapMainController.setNavigation(AppRoutes.SELECT_DROP_LOCATION);
    }
  }

  @override
  void onClickActionsInPrecautionPage(int selectedButtonType) {
    switch (selectedButtonType) {
      case 1:
        {
          mapMainController.bookingInstructionController(false);
        }
        break;
      case 2:
        {
          mapMainController.bookingInstructionController(false);
          mapMainController.confirmRideSocket();
          print("selectedButtonType--> $selectedButtonType");
        }
        break;
      default:
        {}
        break;
    }
  }

  @override
  void openCancelReasonScreen() {
    mapMainController.checkInternet(getCancelReason, true);
  }

  @override
  void cancelRideByRider() {
    mapMainController.checkInternet(cancelRide, null);
  }

  onDriverApproved(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          if (data["data"]["data"]["data"]["isBan"] == 1) {
            String errorMsg = data["data"]["errorMessage"] ?? data["data"]["data"]["message"] ?? "ban_account_content".tr;
            if (Get.context != null) {
              mapMainController.toast.show(
                context: Get.overlayContext ?? Get.context!,
                message: errorMsg,
              );
            }
            Future.delayed(const Duration(milliseconds: 1500), () {
              mapMainController.setLogout();
            });
          }
        }
      }
    });
  }
}