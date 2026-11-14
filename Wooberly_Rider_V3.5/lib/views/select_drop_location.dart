import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:collection/collection.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/views/select_location_on_map_page.dart';
import 'package:app_name/views/select_map_location.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import 'package:app_name/widgets/select_drop_location/animated_visibility_bottom_text.dart';
import 'package:app_name/widgets/select_drop_location/booking_location_change_field.dart';
import 'package:app_name/widgets/select_drop_location/location_input_field.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';

part '../views/select_drop_location_part2.dart';
part  '../views/select_drop_multi_stop_functions.dart';

class SelectDropLocation extends StatelessWidget {
  bool isFromSchedule = false;

  SelectDropLocation(this.isFromSchedule);

  @override
  Widget build(BuildContext context) {
    return SelectDropLocationView(this.isFromSchedule);
  }
}

class SelectDropLocationView extends PlacesAutocompleteWidget {
  bool? isFromSchedule = false;

  SelectDropLocationView(this.isFromSchedule) : super();

  @override
  _AutoCompleteState createState() => _AutoCompleteState();
}

class _AutoCompleteState extends PlacesAutocompleteState {
  late MapMainController _mapMainController;
  bool singleselect = true;
  bool _isSearching = false;


  List<LocationData> locationData = [];
  StreamSubscription? _routeDrawSubscription;

  @override
  void initState() {
    _mapMainController = Get.find();
    debugPrint("Get.arguments: ${Get.arguments} --- ${widget.isFromSchedule}");
    if (Get.arguments != null && Get.arguments is Map && Get.arguments['locationData'] != null) {
      locationData = List.from( Get.arguments['locationData']);
    } else {
      locationData = List.from(_mapMainController.locationData);
    }
    if(locationData.isEmpty && globals.currentLocation.value.isNotEmpty && globals.userLat!=0.0 && globals.userLon !=0.0)
      locationData.add(LocationData(
        LatLng(globals.userLat, globals.userLon),
        globals.currentLocation.value,
      ));

     if (locationData.length==1){
      locationData.add(LocationData(
        LatLng(0.0, 0.0),
        '',
      ));
    }



    locationData.forEach((element){
      debugPrint('_mapMainController.locationData: 2 ${element.location} --- ${element.latLng} -- ${globals.tripStatus}');
    });

    _mapMainController.locationData.forEach((element){
      debugPrint('_mapMainController.locationData: original ${element.location} --- ${element.latLng} -- ${globals.tripStatus}');
    });
    _mapMainController.ismultistopvia = false;

    debugPrint("PlacesAutocompleteState.selectLocationEnum: 2 ${PlacesAutocompleteState.selectLocationEnum} --- ${PlacesAutocompleteState.activeStopIndex}");

    if (locationData.isEmpty) {
      PlacesAutocompleteState.activeStopIndex = 0;

    } else {
      final index = locationData.indexWhere(
            (element) => element.location == null || element.location!.isEmpty,
      );
      if (index != -1) {
        PlacesAutocompleteState.activeStopIndex = index;
      }
    }

    PlacesAutocompleteState.focus = false;
    debugPrint("initstate called");

    ever(globals.placeSearchingController, (data) {
      debugPrint("globals.placeSearchingController_isSearching ${_isSearching}");
      if (_isSearching != data) {
        _isSearching = data;
        // Only update isEnteredLocationsEmpty for real Places API searches,
        // not for the direction-draw phase (isSelectingPrediction == true).
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _mapMainController.update(['placeSelectController']);
        });
      }
    });



    super.initState();
  }

  @override
  void dispose() {
    _routeDrawSubscription?.cancel();
    super.dispose();
  }

  void _handleRouteDrawnNavigation(int data) {
    Get.offNamed(AppRoutes.APP_MAP_MAIN);
    debugPrint("_handleRouteDrawnNavigation: ${data}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveToRouteDrawnPage(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    locationData.forEach((element){
      debugPrint('locationText: local234 ${element.location} --- ${element.latLng} -- ${_mapMainController.EditDisableLocationsDataIndex}');
    });

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        resizeToAvoidBottomInset: false,
        appBarTitle: (_mapMainController.isUserInTrip) ? 'change_location_title'.tr:
        'where_to_go'.tr,
        customAppBarFunction: () {
          double keyopen = MediaQuery.of(context).viewInsets.bottom;
          if(keyopen> 100) {
            SystemChannels.textInput.invokeMethod('TextInput.hide').then((_) {
              Get.back();
            });
          } else {
            Get.back();
          }
        },
        body: GestureDetector(
          onVerticalDragEnd: (TapDownDetails) {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          child: Container(
            child: Column(
              children: [
                Expanded(
                  child: GetBuilder<MapMainController>(
                      id: 'placeSelectController',
                      builder: (_) {
                        debugPrint("placeSearchingController:  --- ${_isSearching} --- ${widget.isFromSchedule}");
                        return SingleChildScrollView(
                          child: new Column(
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsetsDirectional.only(
                                    start: 20, end: 24, top: 20),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              ( _mapMainController.isUserInTrip) ?
                                              BookingLocationChangeField(
                                                isFromSchedule:
                                                widget.isFromSchedule ?? false,
                                                onDisableLocationOTap: (){
                                                  showLocationDisableSheet(context);
                                                },
                                                onLocationDataChanged: (locationData){
                                                  this.locationData = locationData;
                                                },
                                                mapMainController: _mapMainController,
                                                locationData: locationData,
                                              ) :

                                              LocationInputWidget(
                                                isFromSchedule:
                                                widget.isFromSchedule ?? false,
                                                mapMainController: _mapMainController,
                                                locationData: locationData,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ),
                              _isSearching
                                  ? SizedBox(
                                      height: 1.5,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.black12,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.PRIMARY_DARK_COLOR),
                                      ),
                                    )
                                  : (PlacesAutocompleteState.response !=
                                              null) &&
                                          PlacesAutocompleteState
                                              .queryTextController!
                                              .text
                                              .isNotEmpty &&
                                          PlacesAutocompleteState.focus
                                      ? Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  top: 14),
                                          child: SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                1.5,
                                            child: PlacesAutocompleteResult(
                                                listFooter: Padding(
                                                  padding: EdgeInsetsDirectional.only(bottom:110),
                                                child:getListFooter()),
                                                onTap: (_prediction) async{
                                                LatLng details = await  _mapMainController.findPlaces(_prediction['place_id']);
                                                updateLocationData( _prediction['description'], details);

                                                }),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                              (PlacesAutocompleteState.response != null) &&
                                      PlacesAutocompleteState
                                          .queryTextController!
                                          .text
                                          .isNotEmpty &&
                                      PlacesAutocompleteState.focus
                                  ? const SizedBox.shrink()
                                  : getListFooter()
                            ],
                          ),
                        );
                      }),
                ),
                GetBuilder<MapMainController>(
                  id: 'placeSelectController',
                  builder: (_) {
                    return bottomButton(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget bottomButton(BuildContext context) {
    Color buttonColor = AppColors.PRIMARY_DARK_COLOR;
    Color textColor = AppColors.DISABLE_COLOR;

    _mapMainController.locationData.forEach((element){
      debugPrint('locationText: contr ${element.location} --- ${element.latLng} -- ${globals.tripStatus}');
    });

    bool isValidLocation = locationData.length >= 2;

    for (var element in locationData) {
      print("isValidLocation11--> $isValidLocation <-> ${element.location}");
      if (element.location != null && element.location!.isNotEmpty) {
        isValidLocation = true;
      } else {
        isValidLocation = false;
        break;
      }
    }



    // Button is enabled only when both locations are set AND no search /
    // direction-draw is in progress (_isSearching covers both the Places API
    // search and the route-draw phase via placeSearchingController).
    print("isValidLocation--> ${isValidLocation} -- ${PlacesAutocompleteState.focus} --- ${_isSearching}");
    bool buttonEnable =
        !PlacesAutocompleteState.focus && !_isSearching && isValidLocation;

   // if(getTripStatus()) {
      List<LocationData> cleanLocationData = [];
      for (var element in locationData) {
        if (element.location != null && element.location!.isNotEmpty) {
          cleanLocationData.add(element);
        }
      }

      List<LocationData> cleanMainLocationData = [];
      for (var element in _mapMainController.locationData) {
        if (element.location != null && element.location!.isNotEmpty) {
          cleanMainLocationData.add(element);
        }
      }

      bool areEqual = cleanLocationData.length == cleanMainLocationData.length;
      if (areEqual) {
        for (int i = 0; i < cleanLocationData.length; i++) {
          areEqual = (cleanLocationData[i].location == cleanMainLocationData[i].location) &&
              (cleanLocationData[i].latLng!.latitude == cleanMainLocationData[i].latLng!.latitude) &&
              (cleanLocationData[i].latLng!.longitude == cleanMainLocationData[i].latLng!.longitude);
          debugPrint('locationText: bottombuttontest ${cleanLocationData[i].location == cleanMainLocationData[i].location} --- ${cleanLocationData[i].latLng!.latitude == cleanMainLocationData[i].latLng!.latitude} -- ${cleanLocationData[i].latLng!.longitude == cleanMainLocationData[i].latLng!.longitude} --- ${cleanLocationData[i].location}');
          if (!areEqual) break;
        }
      }
    debugPrint('locationText: areEqual ${areEqual} -- ${buttonEnable}');
      buttonEnable = buttonEnable && !areEqual;

  //  }

    buttonColor = AppColors.PRIMARY_DARK_COLOR;
    textColor = AppColors.PRIMARY_LIGHT_COLOR;
      if ((PlacesAutocompleteState.focus &&
          PlacesAutocompleteState.queryTextController!.text.isEmpty) ||
          !isValidLocation) {
        buttonColor = AppColors.DISABLE_COLOR;
        textColor = AppColors.PLACEHOLDER_TEXT_COLOR;
      }
    return Container(
        margin: const EdgeInsetsDirectional.all(20),
        width: MediaQuery.of(context).size.width,
        child: PrimaryButton(
          buttonTitle: 'done'.tr,
          buttonImage: primaryBtnArrow,
          buttonColor: buttonColor,
          textColor: textColor,
          isLoad: true,
          callback: () {
            debugPrint("buttonEnable: ${buttonEnable} --- ${_mapMainController.isUserInTrip} --- ${isValidLocation} --- ${widget.isFromSchedule} = ${_mapMainController.isScheduleRide} ---${PlacesAutocompleteState.focus}");
            if (buttonEnable) {
                if(_mapMainController.isUserInTrip) {
                  showMultiStopConfirmDialog(context);
                } else {
                  if(isValidLocation) {
                    debugPrint("123destPlaceController.value:456 ${_mapMainController.isScheduleRide} --- ${!_mapMainController.isUserInTrip}");
                    if (widget.isFromSchedule != _mapMainController.isScheduleRide && !_mapMainController.isUserInTrip) {
                      _mapMainController.isScheduleRideIconEnable = widget.isFromSchedule ?? false;
                      _mapMainController.isScheduleRide = widget.isFromSchedule ?? false;
                      _mapMainController.isFromSchedule = widget.isFromSchedule ?? false;
                      _mapMainController.scheduleRideScreenController.value = false;
                      debugPrint("123destPlaceController.value:456 ${_mapMainController.isScheduleRide}");
                      showCategories(context);
                    }
                  }
                  showCategories(context);
                }
              } else {
              if(isValidLocation) {
                if(PlacesAutocompleteState.focus){
                  return;
                }
                debugPrint("123destPlaceController.value:456 ${_mapMainController.isScheduleRide} --- ${!_mapMainController.isUserInTrip}");
                if(widget.isFromSchedule !=_mapMainController.isScheduleRide && !_mapMainController.isUserInTrip){
                  _mapMainController.isScheduleRideIconEnable = widget.isFromSchedule ?? false;
                  _mapMainController.isScheduleRide = widget.isFromSchedule ?? false;
                  _mapMainController.isFromSchedule =widget.isFromSchedule ?? false;
                  _mapMainController.scheduleRideScreenController.value = false;
                  debugPrint("123destPlaceController.value:456 78 ${_mapMainController.isScheduleRide} --- ${_mapMainController.scheduleRideScreenController.value}");
                  showCategories(context);
                } else {
                  debugPrint("12345destPlaceController.value: ${_mapMainController.locationData.last.location}");
                  Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN);
                }
              }
            }
          },
        ),
    );
  }

  showCategories(BuildContext context) async {
    var tempLocationData =
        locationData.map((source) => LocationData.clone(source)).toList();
    for (int i = 0; i < tempLocationData.length; i++) {
      if (tempLocationData[i].location!.isEmpty &&
          tempLocationData[i].latLng!.latitude == 0.0 &&
          tempLocationData[i].latLng!.longitude == 0.0) {
        tempLocationData.removeAt(i);
      }
    }
    globals.setButtonLoading();

        _mapMainController.locationData.clear();
        tempLocationData.forEach((element) {
          _mapMainController.locationData.add(element);
        });
        _mapMainController.avoidZoom = true;
        _mapMainController.setDestPlaceController(_mapMainController
            .locationData
            .elementAt(_mapMainController.locationData.length - 1)
            .location!);
        try {
          _mapMainController.isSpecialApplied = false;
          _mapMainController.setSpecialPriceController(false);
          _mapMainController.couponController.text = "";
          _mapMainController.setPromoListController(false);
          _mapMainController.update(['placeSelectController']);
          _mapMainController.updatePadding(220);
          _routeDrawSubscription?.cancel();
          _routeDrawSubscription =
              _mapMainController.RouteDrawController.stream.listen((data) {
            debugPrint("showCategories RouteDrawController: $data");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (data == 2) {
                _routeDrawSubscription?.cancel();
                globals.setButtonIdle();
                _mapMainController.showInSnackBar('route_draw_error'.trParams({
                  'field': locationData.first.location ?? '',
                  'field1':  locationData.last.location ?? ''
                }));
                if (_mapMainController.RouteDrawController.value == 0) {
                  _mapMainController.RouteDrawController.refresh();
                } else {
                  _mapMainController.RouteDrawController(0);
                }
              } else if ( data == 1 || data == 3) {
                _routeDrawSubscription?.cancel();
                _handleRouteDrawnNavigation(data);
              }
            });
          });

          _mapMainController.drawDestRoute(
              locationData.first.latLng!,
              locationData.last.latLng!);
          Future.delayed(const Duration(milliseconds: 3500), () {
            _mapMainController.moveToUserLocation();
          });

        } on Exception catch (e) {
          _routeDrawSubscription?.cancel();
          globals.setButtonIdle();
          debugPrint("route draw error");
        }

  }

  @override
  void onResponse(dynamic response) {
    super.onResponse(response);
    if (response != null && response.isNotEmpty) {}
  }
}