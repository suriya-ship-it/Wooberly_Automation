import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels, rootBundle;
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/binding/home_binding.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/utils/map_main_function/internet_check_on_map_main.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/driver_wallet_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_accept_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_complete_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_decline_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_request_cancel_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_request_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/ride_start_socket.dart';
import 'package:wooberly_driver/utils/map_main_function/socket_function/rider_cancel_socket.dart';
import 'package:wooberly_driver/views/flutter_google_places.dart';
import 'package:wooberly_driver/widgets/confirm_cancel_popup.dart';
import 'package:wooberly_driver/widgets/flutter_rating_bar.dart';
import 'package:wooberly_driver/widgets/map_main_drawer.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/cancel_reason_transition_view.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/map_based_views.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/map_top_buttons_view.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/ride_request_transition_view.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/show_location_icon.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/show_ride_confirmation_otp.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import '../app/app.dart';
import '../app/app_routes.dart';
import '../app/model_theme.dart';

import '../graphql/graphql_config.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_lang.dart';
import '../utils/globals.dart' as globals;
import '../utils/map_main_function/graphql_fetch_on_map_main.dart';
import '../utils/map_main_function/initialize_map_main_view.dart';
import '../utils/map_main_function/location_fetch_on_map_main.dart';
import '../utils/map_main_function/map_view_socket_connection.dart';
import '../utils/map_main_function/socket_function/driver_cancel_socket.dart';
import '../utils/map_main_function/socket_function/driver_currency_socket.dart';
import '../utils/map_main_function/socket_function/driver_login_socket.dart';
import '../utils/map_main_function/socket_function/trip_payment_socket.dart';
import '../widgets/custom_dialog_box.dart';
import '../widgets/map_screen_widget/driver_bottom_info_sheet.dart';
import '../widgets/map_screen_widget/driver_status_bottom_view.dart';
import '../widgets/map_screen_widget/google_map_view.dart';
import '../widgets/map_screen_widget/map_navigate_button_view.dart';
import '../widgets/map_screen_widget/ride_cancelled_transition_view.dart';
import '../widgets/map_screen_widget/ride_complete_cash_popup_view.dart';
import '../widgets/map_screen_widget/ride_final_amount_transition_view.dart';
import '../widgets/map_screen_widget/ride_location_transition_view.dart';
import '../widgets/map_screen_widget/ride_start_button_view.dart';
import '../widgets/map_screen_widget/show_rider_sheet.dart';


class MapMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}

class HomeView extends StatefulWidget {
  HomeViewState homeViewState = HomeViewState();

  @override
  HomeViewState createState() => homeViewState;
}

class HomeViewState extends State<HomeView>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements  TripPlannerIF {
  final MapMainController _controller = Get.find();
  late AnimationController resizableController;
  VoidCallback? appLifecyclelistener;
  bool closeApp = true;
  bool netOff = true;
  late List<Permission> permissionGroup;
  StreamSubscription? locationSubscription;

  var audioBytes;
  bool  openSettings = false;
  AnimationController? animController,
      rideDetailAnimController,
      rideStartAnimController,
      rideCompleteAnimController,
      rideFetchAnimController,
      rideCancelledAnimController,
      riderInfoAnimController,
      tripAmountController,
      tripCashPopupController;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String mapStyle = "";
  Animation<Offset>? amountOffset,
      rideDetailOffset,
      rideDetailAmountOffset,
      rideStartOffset,
      riderReviewOffset,
      riderInfoOffset,
      rideFetchOffset,
      rideCancelledOffset,
      navigationButOffset,
      tripAmountOffset,
      tripCashPopupOffset;
  MapBasedViews? mapBasedViews;
  Timer? backgroundTimer;
  BuildContext? scaffoldContext,
      tripPlannerContext,
      tipsContext,
      amountWidgetContext;
  bool singleClick = false;
  String previousStatus = '';
  final rxChangeTripArrowPosition = ReactiveVariable("rxChangeTripArrowPosition", false);
  double timerHeight = 0.0,
      finalAmountHeight = 0.0,
      bottomSheetHeight = 0.0,
      riderInfoHeight = 0.0;
  MapNavigateButtonView? mapNavigateButtonView;
  MapTopButtonsView? mapTopButtonsView;
  RideRequestSocket? rideRequestSocket;
  RiderCancelSocket? riderCancelSocket;
  RideRequestCancelSocket? rideRequestCancelSocket;
  RideDeclineSocket? rideDeclineSocket;
  DriverLoginSocket? driverLoginSocket;
  DriverWalletSocket? driverWalletSocket;
  DriverCurrencySocket? driverCurrencySocket;
  TripPaymentSocket? tripPaymentSocket;
  DriverCancelSocket? driverCancelSocket;

  RideAcceptSocket? rideAcceptSocket;
  RideCompleteSocket? rideCompleteSocket;
  RideStartSocket? rideStartSocket;
  GraphQLFetchOnMapMainScreen? graphQLFetchOnMapMainScreen;
  InternetCheckOnMapMainScreen? internetCheckOnMapMainScreen;
  LocationFetchOnMapMainScreen? locationFetchOnMapMainScreen;
  SocketConnectionOnMapMainScreen? socketConnectionOnMapMainScreen;
  String? preferredCurr;

  int currentLoadTime = globals.notificationInterval;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    globals.currentShowingPage = AppRoutes.APP_MAP_MAIN;
    _controller.homeViewState = this;
    if(globals.loginTripStatus.isNotEmpty)
    _controller.tripStatus = globals.loginTripStatus;
    globals.loginTripStatus = "";
    graphQlObject.getGraphQlClientWithHeader();
    getAudioBytes();
    permissionGroup = [
      Permission.location,
      Permission.storage,
      Permission.notification
    ];
    InitializeMapMainView(this, _controller);

    Future.delayed(Duration.zero).then((value) {
      if (globals.isDrawerOpen) scaffoldKey.currentState?.openEndDrawer();
    });

  _controller.rxRideDetailEnabledControllerSubscription =   _controller.rxRideDetailEnabledController.stream.listen((event) {
      debugPrint("riderInfoAnimController reverse 1: ${event}");
      if (event) {
        _controller.change(rxVariable: _controller.rxPictureChangeController, value: true);
        riderInfoAnimController?.forward();
      } else {
        riderInfoAnimController?.reverse();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addAnimation();
      PlacesAutocompleteState.queryTextController = null;
      PlacesAutocompleteState.focus = false;
      PlacesAutocompleteWidget.isRegister = false;
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _controller.setLoadingController(false);
      globals.rxFcmWalletOptions.stream.listen((fcmwallet){
        if(fcmwallet['isintial'] !=null && fcmwallet['isintial']){
          Future.delayed(const Duration(milliseconds: 300), () {
            Map<String, dynamic> walletoptions = globals.driverWalletOptionController.value;
            if (walletoptions["driverWalletOption"] == "1" && globals.userid == fcmwallet["id"]) {
              App().setNavigation(AppRoutes.APP_DRIVER_WALLET);
            }
          });
        }
      });
    });
    super.initState();
  }


  void showlocationDialog({bool isMainPage = false}) {
    Dialog alertDialog = Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: CustomDialogBox(
          callback: () async {
            // Mark disclosure as shown, then immediately trigger OS permission
            getLocationStatus();
          },
        ));
    // barrierDismissible: false ensures users cannot bypass disclosure
    Get.dialog(
        Obx(
           () {
            return globals.isAutoThemeUpdated.value != null ? alertDialog : SizedBox.shrink();
          }
        ),
        barrierDismissible: false,
    );
    // NOTE: No .whenComplete() here – getLocationStatus is called only via
    // the 'Got it' callback above, ensuring disclosure always precedes the
    // OS permission dialog (Google Play Prominent Disclosure requirement).
  }

  Future<void> getLocationStatus() async {
    final Permission locationPermission =
    Platform.isAndroid ? Permission.location : Permission.locationWhenInUse;

    bool isServiceEnabled = await App().isLocationServiceEnable();

    if (!isServiceEnabled) {
      final bool enabledNow = await App().EnableLocationService();
      if (!enabledNow) return; // user declined to enable the service — nothing more to do

      isServiceEnabled = await App().isLocationServiceEnable();
      if (!isServiceEnabled) return;

      await _handleServiceJustEnabled(locationPermission);
    } else {
      await _handleServiceAlreadyEnabled(locationPermission);
    }
  }

  /// Path A: location service was off and we just turned it on.
  Future<void> _handleServiceJustEnabled(Permission locationPermission) async {
    PermissionStatus status = await locationPermission.status;
    debugPrint("locationpermission $status");

    if (status == PermissionStatus.granted) {
      await _checkAndroidLocationAlways();
      App().checkInternet(context, requestPermission, false);
    } else {
      await permissionGroup.request();
      status = await locationPermission.status;
      if (status == PermissionStatus.granted) {
        App().checkInternet(context, requestPermission, false);
      }
    }

    await _runAndroidBackgroundChecks();
  }

  /// Path B: location service was already on.
  Future<void> _handleServiceAlreadyEnabled(Permission locationPermission) async {
    final PermissionStatus status = await locationPermission.status;
    debugPrint("locationpermission123 $status");

    if (status == PermissionStatus.granted) {
      requestPermission();
      await _runAndroidBackgroundChecks();
      await _checkAndroidLocationAlways();

      return;
    }

    // Not granted
    if (status == PermissionStatus.granted) {
      if (!App().appPreference.isFirstTimeLocationPermission) {
        await permissionGroup.request();
        App().appPreference.isFirstTimeLocationPermission = true;

        final newStatus = await locationPermission.status;
        if (newStatus == PermissionStatus.granted) {
          App().checkInternet(context, _controller.currentLocationUpdateInstant, false);
        } else {
          requestPermission();
        }
      } else {
        openSettings = true;
        await openAppSettings();
      }
      await _runAndroidBackgroundChecks();
    } else if (status == PermissionStatus.permanentlyDenied) {
      openSettings = true;
      await openAppSettings();
    } else {
      // iOS, not granted, not permanently denied
      await permissionGroup.request();
      App().appPreference.isFirstTimeLocationPermission = true;

      final newStatus = await locationPermission.status;
      if (newStatus == PermissionStatus.granted) {
        App().checkInternet(context, _controller.currentLocationUpdateInstant, false);
      }
      // Note: original had an `if (Platform.isAndroid) requestPermission()` fallback
      // here, but it's structurally unreachable in the iOS branch — removed as dead code.
    }
  }

  /// Shared: Android-only "locationAlways" check → opens settings if not granted.
  Future<void> _checkAndroidLocationAlways() async {
    final PermissionStatus locationAlwaysPermission = await Permission.locationAlways.status;
    debugPrint("locationAlwaysPermission $locationAlwaysPermission");
    if (locationAlwaysPermission != PermissionStatus.granted) {
      openSettings = true;
      await openAppSettings();
    }
  }

  /// Shared: Android-only battery optimization + draw-over-apps prompt.
  /// (Was duplicated 5x in the original — now defined once.)
  Future<void> _runAndroidBackgroundChecks() async {
    final dynamic arguments = ModalRoute.of(context)?.settings.arguments ?? "";
    if (!Platform.isAndroid ||
        arguments == "reviewPage" ||
        arguments == "cancelPage") {
      return;
    }

    App().locationChannel.invokeMethod('batteryoptimization');
    await App().locationChannel.invokeMethod('osversion');
    final bool isAllowDrawOverApps = await App().locationChannel.invokeMethod('isAllowDrawOverApps');

    if (globals.isBringAppToForeGround && !isAllowDrawOverApps) {
      Future.delayed(const Duration(seconds: 3), () {
        _asyncConfirmDialog(
          context,
          draw_over_permission_content.tr,
          toBeginningOfSentenceCase(okay.tr.toLowerCase()),
          cancel.tr,
        );
      });
    }
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      _controller.currentLocationUpdateInstant();
    } else {
      if(await permissionGroup[0].isGranted) {
        if (globals.userLat == 0.0 && globals.userLon == 0.0) {
          await App().getNativeLocation();

        }
      }
    }
  }
  void addAnimation() {
    currentLoadTime = globals.progressLoadTime = globals.notificationInterval;
    _controller.progressController = AnimationController(
        vsync: this,
        duration: Duration(seconds: globals.progressLoadTime ?? 20));
    double begintime = globals.progressLoadTime.toDouble() - currentLoadTime.toDouble();
    double endtime = globals.progressLoadTime.toDouble();
    if (begintime < 0) {
      endtime = endtime - begintime;
      begintime = 0;
    }
    _controller.tripRequestAnimation =
        Tween<double>(begin: begintime, end: endtime)
            .animate(_controller.progressController!)
          ..addListener(() {
            if (globals.authToken?.isEmpty ?? true) {
              globals.tripStatusChangedController.value = true;

              _controller.progressController?.stop();
            }

            _controller.change(rxVariable: _controller.rxLoadTimerController, value: true);
          });
  }

  @override
  Widget build(BuildContext context) {
    _controller.scaffoldContext = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadInitial();
      if(globals.navigateToTripsPast && !globals.isTripsPage) {
        App().setNavigation(  AppRoutes.APP_TRIPS);
      }
      if(globals.navigateToPayout){
        globals.navigateToPayout = false;
        App().setNavigation(AppRoutes.APP_PAYOUT_DISPLAY);
      }
    });


    _controller.getPrivateStatus();


    mapNavigateButtonView = MapNavigateButtonView(
      homeViewState: this,
    );

    mapTopButtonsView = MapTopButtonsView(
      homeViewState: this,
      scaffoldKey: scaffoldKey,
    );
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      if (_controller.mapUtils != null &&
          _controller.mapUtils.coordinates.length > 0) {
        _controller.polylines = _controller.mapUtils.updatePolylineColor();
      }

      if (globals.isDarkTheme) {
        rootBundle.loadString('assets/map_style_dark.txt').then((string) {
          mapStyle = string;
        });
      } else {
        rootBundle.loadString('assets/map_style.txt').then((string) {
          mapStyle = string;
        });
      }

      return PrimaryScaffold(
        customAppBarFunction: () {
          if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
            App().setBackNavigation();
            return Future.value(false);
          } else if(_controller.rxRideConfirmOTPScreenStatusController.value != RideConfirmOTPScreenStatus.InActive){
            _controller.rideConfirmOTPEntryController.clear();
            _controller.change(rxVariable: _controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
          }
          else if (closeApp) {
            App().closeApp();
          } else {
            rideCompleteAnimController?.reverse();
            closeApp = true;
            _controller.setDriverStatus(true);
            _controller.clearMap();
          }
        },
        resizeToAvoidBottomInset: false,
        onChanged: (map) {
          scaffoldKey = map["scaffoldkey"];
          scaffoldContext = map["scaffoldcontext"];
        },
        customAppBarContent: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: const SizedBox.shrink(),
        ),
        body: ColoredBox(
          color: AppColors.PRIMARY_COLOR_WHITE,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        GoogleMapView(homeViewState: this),
                        mapNavigateButtonView!,
                        mapNavigateButtonView?.getOnlineStatusView(),
                        mapTopButtonsView!,
                        ShowLocationIcon(this),
                        DriverStatusBottomView(homeViewState: this),
                        RideStartButtonView(homeViewState: this),
                        mapBasedViews?.showGrid(context),
                        DriverBottomInfoSheet(
                          homeViewState: this,
                          mapBasedViews: mapBasedViews!,
                        ),

                      ],
                    ),
                  ),
                ],
              ),
              mapBasedViews?.getPrivacyModeView(context),
              ShowRiderInfoSheet(homeViewState: this),
              RideLocationTransitionView(homeViewState: this),
              RideCancelledTransitionView(homeViewState: this),
              RideFinalAmountTransitionView(homeViewState: this),
              RideFinalCashPopUpView(homeViewState: this),
              RideRequestTransitionView(homeViewState: this),
              RideConfirmationOtpView(state: this),
            ],
          ),
        ),
        endDrawer: MapMainDrawer(
          callback: setDrawerOpened,
          builderctx: scaffoldContext ?? Get.context!,
        ),
      );
    });
  }

  void setDrawerOpened(bool isOpen) {
    if (isOpen && globals.uploadedImage == null) {
      ScaffoldMessenger.of(scaffoldContext ?? Get.context!)
          .hideCurrentSnackBar();
    }
    if (_controller.privacyTimer != null) {
      _controller.privacyTimer?.cancel();
      _controller.privacyTimer = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.change(rxVariable: _controller.rxShowToolTip, value: false);
      });
    }
    globals.isDrawerOpen = isOpen;
    globals.isShowMapPage = !isOpen;
    if (globals.isActive) {
      if (isOpen) {
        _controller.isAppResume = false;
      } else {
        _controller.isAppResume = true;
        _controller.updateGoogleMap();
        _controller.getLocation("", 'disable').then((value) {
          _controller.position = [
            _controller.mapLocation.latitude,
            _controller.mapLocation.longitude
          ];
          _controller.updateGoogleMap();
        });
      }
    }
    globals.currencyChanged.stream.listen((currency) {
      globals.preferredCurrency = currency;
      debugPrint("driverWalletFeature: currencyChanged stream ${currency}");
      if (preferredCurr != globals.preferredCurrency){
        _controller.checkIsDriverEligible();
        _controller.getTripSummary();
      }
      if (preferredCurr != globals.preferredCurrency && !isOpen) {
        InitializeMapMainView(this, _controller);
        _controller.change(rxVariable: rxChangeTripArrowPosition, value: false);
      }
    });
  }

  Future<void> _asyncConfirmDialog(context, signupcontent, confirm, cancel) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signupcontent,
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_16),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsetsDirectional.only(end: 5),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_WHITE,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cancel,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_18,
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                            ),
                          ),
                        ),
                        onTap: () {
                          Get.back();
                          },
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsetsDirectional.only(start: 5),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_DARK,
                              borderRadius: BorderRadius.circular(4)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              confirm,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_18,
                                  color: AppColors.PRIMARY_COLOR_WHITE),
                            ),
                          ),
                        ),
                        onTap: () {
                          Get.back();
                          App().getDrawOverAppsPermission();
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    globals.appLifecycleController.value = state.toString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if(appLifecyclelistener !=null)
    globals.appLifecycleController.removeListener(appLifecyclelistener!);
    _controller.rxRideDetailEnabledControllerSubscription?.cancel();
    _controller.mapController = null;
    globals.audioPlayer?.pause();
    super.dispose();
  }


  setWakeLockEnableDisable(String sleepStatus) {
    App.changeWakeLock(sleepStatus);
  }

  @override
  void cancelRideByDriver() {
    _controller.checkInternet(
        getTripPlannerCancel,
        null);
  }

  @override
  void openCancelReasonScreen() {
    _controller.checkInternet(
        getCancelReason,
        true);
  }

  getCancelReason() async {
    _controller.change(rxVariable: _controller.rxCancelReasonListController, value: true);
    Get.to(
      CancelReasonTransitionView(
        homeViewState: this,
        tripPlannerIF: this,
      ),
      transition: Transition.leftToRight,
      binding: HomeBinding(),
      duration: Duration(milliseconds: 215)
    );
  }

  getTripPlannerCancel() {
    internetCheckOnMapMainScreen?.checkInternetTrackLoc("canceltripclick");
  }

  void getAudioBytes() async {
    if (globals.tripAudioURL != null &&
        globals.tripAudioURL != "" &&
        !globals.tripAudioURL.contains("null")) {
      var httpClient = new HttpClient();
      var request = await httpClient.getUrl(Uri.parse(globals.tripAudioURL));
      var response = await request.close();
      audioBytes = await consolidateHttpClientResponseBytes(response);
    }
  }

  Future<void> asyncLanguageDialog({required String dialogContent,required GestureTapCallback onTap }) async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if(Get.isDialogOpen == true) {
      Get.back();
    }
      Get.dialog(
        barrierDismissible: false,
        PopScope(
          canPop: false,
          child: Obx(
            () {
              return globals.isAutoThemeUpdated.value != null ? AlertDialog(
                backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                content: Container(
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                      ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dialogContent,
                        style: TextStyle(fontSize: AppDimen.text_size_16),
                      ),
                     const SizedBox(height: 30),
                      InkWell(
                        onTap: onTap,
                        child: Container(
                          width: Get.width,
                          height: 50,
                          padding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 20,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_DARK,
                              borderRadius: BorderRadius.circular(4)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(toBeginningOfSentenceCase(okay.tr),
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ) : const SizedBox.shrink();
            }
          )
        )
      );
  }
}