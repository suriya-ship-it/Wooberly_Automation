import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app/enums/button_state.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/widgets/language_dialog.dart';
import 'package:app_name/widgets/map_main_drawer.dart';
import 'package:app_name/widgets/map_screen_widgets/show_map.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import 'package:app_name/widgets/schedule_ride.dart';
import 'package:app_name/widgets/size_find_widget.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/app.dart';
import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../utils/socket_connection.dart';
import '../controllers/base_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_name/services/firebase_service.dart';

class HomeScreen extends StatelessWidget {
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
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements ScheduleRideControllerIF {
  MapMainController _mapMainController = Get.find();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext _scaffoldContext;
  final key = GlobalKey();

  double? _userlat, _userlon, _remainingHeight;
  bool _showLocationIcon = true;
  bool _isrefreshlocationicon = false;
  double? _mapWidth, _locationnameheight;

  @override
  void initState() {
    _mapMainController.setMapKey();
    if (globals.socket == null) {
      _mapMainController.initSocket();
    }
    _mapMainController.selectedCabIndex = 0;
    _mapMainController.EditDisableLocationsDataIndex = 0;
    _mapMainController.onReceiveLoginCheck("loginCheck-${globals.userid}");
    _mapMainController.onManualBookingCreatedByAdminCheck();
    _mapMainController.onUserPreferenceUpdated();
    _mapMainController.updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");

    if (_mapMainController.socketIns == null) {
      _mapMainController.socketIns = SocketConnection();
      _mapMainController.socketConnect();
    }
    Future.delayed(Duration(milliseconds: 250), () {
      globals.setButtonLoading();
    });
    if (globals.deviceId.isEmpty) {
      FirebaseService.getFcmToken().then((token) {
        globals.deviceId = token ?? "";
        if (!globals.fcmConfigured && globals.deviceId.isNotEmpty) {
          FirebaseService().configureFCM();
        }
      });
    }
    globals.mapEnableController(true);
    debugPrint('home page init state called: fcmtoken ${globals.deviceId} ');
    _mapMainController.locationData.clear();
    debugPrint("_mapMainController.locationData: 1 ${_mapMainController.locationData} -- ${globals.tripStatus}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.locController(false);
      _mapMainController.updateRxValue(_mapMainController.selectedBookingType, 1);
      Future.delayed(const Duration(milliseconds: 400), () {
        globals.locController(true);
      });
      if (globals.isDrawerOpen) _scaffoldKey.currentState?.openEndDrawer();
      debugPrint("getTripStatusOnly --- status: -- ${globals.tripStatus} -- ${_mapMainController.paymentStatus}");
      if (globals.tripStatus.isNotEmpty && _mapMainController.isUserInTrip) {
        globals.setButtonIdle();
        _mapMainController.isHomeScreen = false;
        _mapMainController.setNavigation(AppRoutes.APP_MAP_MAIN);
      }
      if (globals.tripStatus.isNotEmpty && !_mapMainController.isUserInTrip) {
        _mapMainController.checkInternet(_getNearestDriversCategory, false);
      }
      if (globals.tripStatus.isEmpty) {
        _mapMainController.checkInternet(getUserTripStatus, false);
      }
    });

    _userlat = globals.userLat;
    _userlon = globals.userLon;
    ever(globals.setLocationController, (data) {
      if (data && _userlat != globals.userLat && _userlon != globals.userLon) {
        _userlat = globals.userLat;
        _userlon = globals.userLon;
        _moveToCurrentLocation();
        if (globals.buttonState.value != ButtonState.loading) globals.setButtonLoading();
        _mapMainController.checkInternet(_getNearestDriversCategory, false);
        debugPrint('updateHomeMapController _mapMainController.mapLoading: ${_mapMainController.mapLoading}');
        _mapMainController.updateHomeMapController(true);
        _mapMainController.updateHomeMapController.refresh();
        globals.setButtonIdle();
      }
    });
    ever(globals.currentLocation, (_) {
      String address = globals.currentLocation.value;
      debugPrint("globals.currentLocationaddress: ${address}");
      if (!_mapMainController.mapLoading) {
        _mapMainController.updateHomeMapController(true);
        _mapMainController.updateHomeMapController.refresh();
      }
    });

    _mapMainController.socketIns?.disconnectListen("driverApprove-${globals.userid}");
    onDriverApproved("driverApprove-${globals.userid}");

    if (globals.socket?.connected ?? false) {
      _mapMainController.socketIns?.disconnectListen("tripRequest-${globals.userid}");
      onTripRequestInfo("tripRequest-${globals.userid}");
    } else {
      _mapMainController.reInitSocket();
      _mapMainController.socketIns?.disconnectListen("tripRequest-${globals.userid}");
      onTripRequestInfo("tripRequest-${globals.userid}");
    }
    _mapMainController.onLoadMapStyle();

    ever(globals.languageUpdateController, (value) {
        asyncLanguageDialog(Get.context!, _mapMainController);
    });

    Future.delayed(const Duration(milliseconds: 7500), () {
    if(!_mapMainController.updateHomeMapController.value){
      _mapMainController.updateHomeMapController(true);
    }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (globals.navigateToTripsPast && !Get.currentRoute.contains('trips')) {
      _mapMainController.setNavigation(AppRoutes.APP_TRIPS);
    }

    double _imageSize = 42.0;
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      _mapMainController.onLoadMapStyle();
      return PrimaryScaffold(
        key: key,
        disableAppbar: true,
        customAppBarFunction: () {
          if (globals.isDrawerOpen) {
            _scaffoldKey.currentState?.closeEndDrawer();
          } else {
            dispose();
            _mapMainController.closeApp;
          }
        },
        resizeToAvoidBottomInset: false,
        onChanged: (map) {
          _scaffoldContext = map["scaffoldcontext"];
          _scaffoldKey = map["scaffoldkey"];
        },
        body: Stack(
          children: [
            Container(
              color: AppColors.COMMON_BG_COLOR,
              padding: const EdgeInsetsDirectional.all(25),
              child: Column(
                children: [
                  WidgetSize(
                    onChange: (Size size) {
                      _remainingHeight = size.height;
                      debugPrint('_remainingHeight: ${_remainingHeight}');

                      globals.setButtonLoading();
                      globals.setButtonIdle();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 5.0),
                            InkWell(
                              onTap: () {
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.all(Radius.circular(23)),
                                ),
                                child: Row(
                                  children: [
                                    Obx(() {
                                      if (globals.picture.value.isNotEmpty)
                                        return ClipOval(
                                          child: CachedNetworkImage(
                                            height: _imageSize,
                                            width: _imageSize,
                                            fit: BoxFit.cover,
                                            imageUrl: globals.picture.value.replaceAll("medium_", "small_") ,
                                            placeholder: (context, url) => SvgPicture.asset(
                                              defaultProfileSvg,
                                              width: _imageSize,
                                              height: _imageSize - 1,
                                            ),
                                          ),
                                        );
                                      else
                                        return SvgPicture.asset(
                                          defaultProfileSvg,
                                          width: _imageSize,
                                          height: _imageSize - 1,
                                        );
                                    }),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 7.0, end: 8.0),
                                      child: RotatedBox(
                                        quarterTurns: 2,
                                        child: SvgPicture.asset(
                                          height: 15,
                                          width: 15,
                                          drawerSvg,
                                          colorFilter:
                                              ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Spacer(),
                            InkWell(
                                onTap: () {
                                  _mapMainController.showThemeModeBottomSheet(
                                    context,
                                    scaffoldContext: _scaffoldContext,
                                    ThemeChangeCallback: (mode) {
                                      if (mode == 2)
                                        _mapMainController.updateProfileInfo("appTheme", 'light');
                                      else if (mode == 3)
                                        _mapMainController.updateProfileInfo("appTheme", "dark");
                                      else
                                        _mapMainController.updateProfileInfo("appTheme", "auto");
                                    },
                                  );
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  padding: const EdgeInsetsDirectional.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_LIGHT_COLOR,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    globals.theme == 1
                                        ? defaultThemeSvg
                                        : globals.theme == 2
                                            ? homeLightSvg
                                            : homeDarkSvg,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  ),
                                )),
                          ],
                        ),
                        const SizedBox(height: 25.0),
                        Row(
                          children: [
                            Image.asset(
                              welcomePng,
                              width: _imageSize,
                              height: _imageSize,
                            ),
                            const SizedBox(width: 8.0),
                            Obx(() {
                              return Flexible(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(top: 3.0),
                                  child: Text('hi_label'.trParams({'field': globals.firstname.value}),
                                      style: TextStyle(
                                          fontSize: AppDimen.text_size_22,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.BLACK_TEXT_COLOR)),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'where_are_you_going'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: _getFontSize(),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GetBuilder<MapMainController>(
                            id: _mapMainController.selectedBookingType.id,
                            builder: (_) {
                              int selectedBookingType = _mapMainController.selectedBookingType.value;
                              debugPrint("_mapMainController.selectedBookingType.: ${_mapMainController.selectedBookingType.value}");
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _mapMainController.updateRxValue(
                                            _mapMainController.selectedBookingType, 1);
                                      },
                                      child: Container(
                                        margin: const EdgeInsetsDirectional.only(end: 10),
                                        padding: const EdgeInsetsDirectional.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selectedBookingType == 1
                                              ? AppColors.PRIMARY_DARK_COLOR
                                              : AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.circular(40),
                                          border: Border.all(
                                            width: 1,
                                            color: AppColors.PRIMARY_DARK_COLOR,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min, // ✅ Key fix
                                          children: [
                                            SvgPicture.asset(
                                              instantBook,
                                              colorFilter: ColorFilter.mode(
                                                  selectedBookingType == 1
                                                      ? AppColors.PRIMARY_LIGHT_COLOR
                                                      : AppColors.BLACK_TEXT_COLOR,
                                                  BlendMode.srcIn),
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                'ride_now'.tr,
                                                style: TextStyle(
                                                  color: selectedBookingType == 1
                                                      ? AppColors.PRIMARY_LIGHT_COLOR
                                                      : AppColors.BLACK_TEXT_COLOR,
                                                  fontFamily: AppFont.font,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: AppDimen.text_size_14,
                                                ),
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _mapMainController.listenLocationPermission(context, () {
                                          _mapMainController.checkInternet(
                                          locationFetchMoveToUserLocation, false);
                                          _mapMainController.updateRxValue(
                                              _mapMainController.selectedBookingType, 2);
                                          _mapMainController.isHomeScreen = true;
                                          _mapMainController.scheduleRideScreenController(true);
                                        });

                                      },
                                      child: Container(
                                        margin: const EdgeInsetsDirectional.only(start: 10),
                                        padding: const EdgeInsetsDirectional.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selectedBookingType == 2
                                              ? AppColors.PRIMARY_DARK_COLOR
                                              : AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.circular(40),
                                          border: Border.all(
                                            width: 1,
                                            color: AppColors.PRIMARY_DARK_COLOR,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min, // ✅ Key fix
                                          children: [
                                            SvgPicture.asset(
                                              scheduleBook,
                                              colorFilter: ColorFilter.mode(
                                                  selectedBookingType == 2
                                                      ? AppColors.PRIMARY_LIGHT_COLOR
                                                      : AppColors.BLACK_TEXT_COLOR,
                                                  BlendMode.srcIn),
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                'Schedule_a_Ride'.tr,
                                                style: TextStyle(
                                                  color: selectedBookingType == 2
                                                      ? AppColors.PRIMARY_LIGHT_COLOR
                                                      : AppColors.BLACK_TEXT_COLOR,
                                                  fontFamily: AppFont.font,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: AppDimen.text_size_14,
                                                ),
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            _mapMainController.listenLocationPermission(context, () async {

                              if (_mapMainController.mapControllerCompleter.isCompleted) {
                                _selectDropLocation();
                              } else {
                                _mapMainController.mapControllerCompleter
                                    .complete(Future.value(_mapMainController.mapController));
                                _mapMainController.updateHomeMapController(true);
                                _mapMainController.updateHomeMapController.refresh();
                                if (_mapMainController.mapController != null) {
                                  await _mapMainController.getNativeLocation();

                                  _moveToCurrentLocation();
                                  if (globals.currentLocation.value.isEmpty)
                                    _mapMainController.getCurrentLocation();
                                }
                                _selectDropLocation();
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.WHITE,
                              borderRadius: new BorderRadius.circular(4.0),
                                border: new Border.all(
                                  color: AppColors.HOME_WHERE_TO_BORDER_COLOR,
                                  width: 1.0,
                                ),

                            ),
                            height: 45,
                            child: Row(
                              children: [
                                SizedBox(width: 14,),
                                SvgPicture.asset(
                                  searchSvg,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.LOCATION_ARRIVED_COLOR, BlendMode.srcIn),
                                ),
                                SizedBox(width: 3,),
                                Text(
                                  'search_your_destination'.tr,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.LOCATION_ARRIVED_COLOR,
                                      fontSize: AppDimen.text_size_14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          return globals.currentLocation.value != null &&
                                  globals.currentLocation.value.isNotEmpty
                              ? WidgetSize(
                                  onChange: (Size size) {
                                    _locationnameheight = size.height;
                                    _remainingHeight = _remainingHeight ?? 0 - size.height;
                                    globals.setButtonIdle();
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        homeCurrLocSvg,
                                        colorFilter:
                                            ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: RichText(
                                          text: TextSpan(children: [
                                            TextSpan(
                                                text: 'current_location'.tr,
                                                style: TextStyle(
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: AppDimen.text_size_12,
                                                    fontFamily: AppFont.font)),
                                            TextSpan(
                                                text: ",\n",
                                                style: TextStyle(
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: AppDimen.text_size_12,
                                                    fontFamily: AppFont.font)),
                                            TextSpan(
                                                text: "${globals.currentLocation.value}",
                                                style: TextStyle(
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: AppDimen.text_size_12,
                                                    fontFamily: AppFont.font))
                                          ]),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                     globals.buttonState.value;

                    double height = MediaQuery.of(context).size.height  -  MediaQuery.of(context).viewPadding.top -  MediaQuery.of(context).viewPadding.bottom;
                    double _normalsize = MediaQuery.of(context).size.width - 60;
                    if (_remainingHeight == null) _remainingHeight = height - 60;
                    if ((_normalsize + _remainingHeight! + 50) > (height))
                      _mapWidth = height - _remainingHeight! - 50;
                    else
                      _mapWidth = _normalsize;
                    if (_locationnameheight != null) _mapWidth = _mapWidth ?? 0;

                    debugPrint('_remainingHeight: ${_remainingHeight} -- ${_mapWidth} --- ${MediaQuery.of(context).viewPadding.bottom}');
                    return Container(
                      width: _mapWidth!.isNegative ? 0.0 : _mapWidth,
                      height: _mapWidth!.isNegative ? 0.0 : _mapWidth,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: new Border.all(
                            color: AppColors.PRIMARY_LIGHT_COLOR,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 8.0,
                                spreadRadius: 2.0,
                                offset: Offset(0, 3))
                          ]),
                      child: ClipOval(
                        clipBehavior: Clip.none,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(_mapWidth!)),
                          child: Stack(
                            children: [
                              Obx(() {
                                debugPrint("globals.locController.value: ${globals.locController.value}");
                                return globals.locController.value == true
                                    ? ShowMapView(
                                        isFrom: AppRoutes.APP_HOME,
                                        onCameraIdle: () {
                                          debugPrint(
                                              'onCameraIdle: ${_showLocationIcon} --- ${_mapMainController.locationFetchController.value} ---${_isrefreshlocationicon}');
                                          if (_isrefreshlocationicon) {
                                            _showLocationIcon = true;
                                            _isrefreshlocationicon = false;
                                            _mapMainController.locationFetchController.value =
                                                !(_mapMainController.locationFetchController.value);
                                            _mapMainController.locationFetchController.value =
                                                !(_mapMainController.locationFetchController.value);
                                          }
                                        },
                                      )
                                    : const SizedBox.shrink();
                              }),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Container(
                                  height: 42,
                                  width: 42,
                                  margin: const EdgeInsetsDirectional.only(top: 80.0, end: 20.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                                      padding: const EdgeInsetsDirectional.all(0),
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (globals.buttonState.value != ButtonState.loading)
                                        globals.setButtonLoading();
                                      _mapMainController.checkInternet(_getNearestDriversCategory, false);
                                    },
                                    child: SvgPicture.asset(
                                      reFetchSvg,
                                      colorFilter:
                                          ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                  alignment: AlignmentDirectional.bottomCenter,
                                  child: Image.asset(
                                    googleLogoPng,
                                    height: 20,
                                  )),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: ValueListenableBuilder<bool>(
                                    valueListenable: _mapMainController.locationFetchController,
                                    builder: (context, value, child) {
                                      debugPrint("locationFetchController: ${value} ---${_showLocationIcon}");
                                      if (!_showLocationIcon)
                                        Future.delayed(const Duration(milliseconds: 400), () {
                                          _isrefreshlocationicon = true;
                                        });

                                      return AnimatedSlide(
                                        duration: Duration(milliseconds: 300),
                                        offset: _showLocationIcon ? Offset.zero : Offset(2, 0),
                                        child: AnimatedOpacity(
                                          duration: Duration(milliseconds: 300),
                                          opacity: _showLocationIcon ? 1 : 0,
                                          child: Card(
                                            margin: const EdgeInsetsDirectional.only(end: 20, bottom: 30.0),
                                            elevation: 5,
                                            color: AppColors.PRIMARY_LIGHT_COLOR,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(50),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                _mapMainController.listenLocationPermission(context, () {
                                                  _mapMainController.checkInternet(
                                                      locationFetchMoveToUserLocation, false);
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsetsDirectional.all(8.0),
                                                child: value == true
                                                    ? SizedBox(
                                                        height: 25.0,
                                                        width: 25.0,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.0,
                                                          backgroundColor: AppColors.PRIMARY_DARK_COLOR,
                                                          valueColor: new AlwaysStoppedAnimation<Color>(
                                                              AppColors.WHITE),
                                                        ),
                                                      )
                                                    : SvgPicture.asset(
                                                        moveToLocationSvg,
                                                        width: 25,
                                                        height: 25,
                                                        colorFilter: ColorFilter.mode(
                                                            AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                              _showGrid(context),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Obx(
              () {
                debugPrint('_mapMainController.locationData: ${_mapMainController.locationData} --- ${ _mapMainController.selScheduleFromDateTime}');
                return _mapMainController.scheduleRideScreenController.value == true
                    ? ScheduleRide(
                    (_mapMainController.locationData.isNotEmpty ?_mapMainController.locationData.first.location :
                    globals.currentLocation.value.isNotEmpty ? globals.currentLocation.value: '') ?? '',
                    (_mapMainController.locationData.length>1 ?_mapMainController.locationData.last.location : '') ?? '',
                        this,
                         null,
                        false,
                        _mapMainController.isScheduleRide)
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        endDrawer: new MapMainDrawer(
          callback: setDrawerOpened,
        ),
      );
    });
  }

  _showGrid(BuildContext context) {
    return Obx(() {
      debugPrint("_mapMainController.updateHomeMapController.value : ${_mapMainController.updateHomeMapController.value }");
      return Container(
        height: _mapMainController.updateHomeMapController.value == false ? _mapWidth : 0,
        width: _mapMainController.updateHomeMapController.value == false ? _mapWidth : 0,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: AppColors.GRID_COLOR,
          image: DecorationImage(
            image: AssetImage(mapGridPng),
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }

  onDriverApproved(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      debugPrint("onDriverApproved ${data.toString()}");
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          if (data["data"]["data"]["data"]["isBan"] == 1) {
            _mapMainController.toast.show(
              context: Get.overlayContext ?? Get.context!,
              message: "ban_account_content".tr,
            );
            _mapMainController.setLogout();
          }
        }
      }
    });
  }

  void setDrawerOpened(bool isOpen) {
    globals.isShowMapPage = !isOpen;
    globals.isDrawerOpen = isOpen;

    _mapMainController.isFromForSettings = "homepage";
  }

  getUserTripStatus() {
    globals.isContinuousLoading = true;
    _mapMainController.getTripStatusOnly().then((value) {
      if (value != null) {
        globals.tripStatus =value["status"] ?? '';
        debugPrint("getTripStatusOnly: ${value["status"]}");
          if (_mapMainController.isUserInTrip) {
            globals.setButtonIdle();
            globals.refreshApp = true;
            _mapMainController.dispose();
            _mapMainController.setNavigation(AppRoutes.APP_MAP_MAIN);
          } else {
            if (globals.buttonState.value != ButtonState.loading) globals.setButtonLoading();
            _mapMainController.checkInternet(_getNearestDriversCategory, false);
          }
      } else {
        _mapMainController.checkInternet(getUserTripStatus, false);
      }
    });
  }

  _getNearestDriversCategory() {
    _mapMainController.getNearestDriversCategory(globals.userLat, globals.userLon, true).then((value) {
      globals.setButtonIdle();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!globals.mapEnableController.value) {
          globals.mapEnableController(true);
          globals.mapEnableController.refresh();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapMainController.mapController?.dispose();
    super.dispose();
  }

  void _moveToCurrentLocation() {
    if (globals.userLat != 0.0 && globals.userLon != 0.0 && _mapMainController.mapController != null)
      _mapMainController.mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(globals.userLat, globals.userLon),
          zoom: 15,
        ),
      ));
  }

  @override
  void scheduleRideController(String data, DateTime selectedDateTime) {
    if (!(_mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed)) {
      if (data == "cancel") {
        _mapMainController.scheduleRideScreenController(false);
      } else if (data == "select") {
        _mapMainController.isFromSchedule = true;
        _mapMainController.selScheduleFromDateTime = selectedDateTime;
        moveToDropLocationFromSchedule();
        _mapMainController.scheduleRideScreenController(false);
        globals.closeKeyBoard = false;
        _mapMainController.isScheduleRide = true;
      } else if (data == "next") {
        _mapMainController.selScheduleFromDateTime = selectedDateTime;
        _mapMainController.isScheduleRide = true;
        _mapMainController.scheduleRideIconController(true);
        _mapMainController.scheduleRideIconController.refresh();
        _mapMainController.scheduleRideScreenController(false);
        _mapMainController.getScheduleCategoryList(true);
        _mapMainController.isScheduleRideTripSelected.value = true;
      } else if (data == "cancel screen") {
        _mapMainController.updateRxValue(
            _mapMainController.selectedBookingType, 1);
        if (!_mapMainController.isScheduleRideIconEnable) {
          _mapMainController.isFromSchedule = false;
          _mapMainController.isScheduleRideTripSelected.value = false;
        } else {
          _mapMainController.isFromSchedule = true;
          _mapMainController.isScheduleRideTripSelected.value = true;
        }
        _mapMainController.scheduleRideScreenController(false);
      }
    } else {
      _mapMainController.scheduleRideScreenController(false);
    }
  }

  moveToDropLocationFromSchedule() {
    _mapMainController.socketIns?.disconnectListen("loginCheck-${globals.userid}");
    _mapMainController.onReceiveLoginCheck("loginCheck-${globals.userid}");
    _mapMainController.onManualBookingCreatedByAdminCheck();
    _mapMainController.onUserPreferenceUpdated();
    _mapMainController.socketIns?.disconnectListen("updatePreferredCurrency-${globals.userid}");
    _mapMainController.updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
    _mapMainController.isScheduleRide = true;
    if (!(_mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed)) {
      Get.to(SelectDropLocation(true), transition: Transition.leftToRight);
    }
  }

  void locationFetchMoveToUserLocation() async {
    if (_showLocationIcon) {
      _mapMainController.locationFetchController.value = true;
      if (_mapMainController.mapController != null) {
        await _mapMainController.getCurrentLocationAddress(toFetchCurrentLatLng: true);
        _moveToCurrentLocation();
        globals.themeNotifier?.isDark = globals.isDarkTheme;
        Future.delayed(const Duration(milliseconds: 350), () {
          _showLocationIcon = false;
          _mapMainController.locationFetchController.value = false;
        });
      }
    }
  }

  void _selectDropLocation() {
    _mapMainController.isHomeScreen = true;
    _mapMainController.tripCalculationModel = null;
    _mapMainController.isScheduleRideTripSelected.value = false;
    _mapMainController.setNavigation(AppRoutes.SELECT_DROP_LOCATION);
  }

  onTripRequestInfo(String eventName) {
    globals.socket?.on(eventName, (data) {
      debugPrint("onTripRequestInfo: ${data}");
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          _mapMainController.isSpecialApplied = false;
          _mapMainController.selectedSpecialID = 0;
          _mapMainController.isHomeScreen = false;
          _mapMainController.setNavigation(AppRoutes.APP_MAP_MAIN);
        }
      }
    });
  }

  _getFontSize() {
    double fontsize = (AppDimen.text_size_46 * MediaQuery.of(context).size.height) / 1000;
    return fontsize;
  }
}