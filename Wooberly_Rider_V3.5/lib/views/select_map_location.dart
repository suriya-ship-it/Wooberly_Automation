import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:provider/provider.dart';
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/views/settings.dart';
import 'package:app_name/widgets/audio_chat/ai_lang_selection_widget.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_images.dart';
import '../utils/map_utils.dart';
import '../controllers/base_controller.dart';
import '../controllers/register_controller.dart';
import '../widgets/primary_button.dart';
import 'flutter_google_places.dart';

class SelectMapLocation extends StatelessWidget {
  final String? selectedPlace;
  final int? stopPosition;
  final String? multiStopFrom;
  final bool? isFromSchedule;
  final List<LocationData>? locationData;

  SelectMapLocation(
      {Key? key,
        this.selectedPlace,
        this.stopPosition,
        this.isFromSchedule,
        this.multiStopFrom,
        this.locationData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectMapLocationView(this.selectedPlace ?? "", this.stopPosition ?? 0, this.multiStopFrom ?? "",
        this.locationData ?? [], this.isFromSchedule);
  }
}

class SelectMapLocationView extends PlacesAutocompleteWidget {
  final String selectedPlace, multiStopFrom;
  final List<LocationData> locationData;
  final int stopPosition;
  bool? isFromSchedule;

  SelectMapLocationView(
      this.selectedPlace, this.stopPosition, this.multiStopFrom, this.locationData, this.isFromSchedule)
      : super();

  @override
  SelectMapLocationState createState() =>
      SelectMapLocationState(this.selectedPlace, this.stopPosition, this.multiStopFrom, this.locationData);
}

class SelectMapLocationState extends PlacesAutocompleteState with AutomaticKeepAliveClientMixin {
  MapMainController mapMainController = Get.find();
  RegisterController _registerController = Get.find();

  String selectedPlace, multiStopFrom;
  final List<LocationData> locationData;
  String _locId = "";
  bool isFromPrediction = false;
  final int stopPosition;
  var locationTextEditingCont = TextEditingController();
  Timer? _mapIdleSubscription;
  String _location = "";
  GoogleMapController? mapController;

  SelectMapLocationState(this.selectedPlace, this.stopPosition, this.multiStopFrom, this.locationData);

  BuildContext? _scaffoldContext;
  bool isMapControllerCreated = false;
  bool _recallLoading = true;
  Timer? _locationfetchTimer;


  @override
  void initState() {
    globals.isLocationScreen = true;
    mapMainController.onLoadMapStyle();
    debugPrint("movetoSetting: ${Get.arguments}");
    _registerController.showSelected = true;
    mapMainController.isSelectMapLocation = true;
    if (selectedPlace == "") {
      getInitialLocation();
    }
    DefaultCacheManager().emptyCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrimaryScaffold.avoidLoader.value = true;
      mapMainController.mapLoadingController(true);
      Future.delayed(const Duration(milliseconds: 600), () {
        mapMainController.mapLoadingController(false);
        debugPrint('globals.selectedFavoriteLocationEnum: select map ${Get.arguments['locationEnum']}');
      });
    });
    ever(globals.openChatFromNotificationController, (value) async {
      print("globals.openChatFromNotificationController: location on map ${value}");
      if (value != null) {
        bool internetConnect = await mapMainController.checkConnectivity();
        if (internetConnect != null && internetConnect) {
          if(globals.isVoiceTranslatorEnable && globals.aiPreferredLanguage.isEmpty){
            VoiceChatBottomSheet(NavigateFunction: () async{
              bool internetConnect = await mapMainController.checkConnectivity();
              if (internetConnect != null && internetConnect) {
                debugPrint("VoiceChatBottomSheet naivgation");
                mapMainController.setNavigation(AppRoutes.APP_CHAT);
              } else {
                mapMainController.showInSnackBar('offline_text'.tr);
              }
            });
            return;
          }
          mapMainController.setNavigation(AppRoutes.APP_CHAT);
        } else {
          mapMainController.showInSnackBar('offline_text'.tr);
        }
      }
    });


    globals.favoriteLocationEnumList.forEach((element) {
      if (element == Get.arguments['locationEnum'] && selectedPlace.isNotEmpty) {
        SelectLocationModel homeLocModel =
        mapMainController.getLocationDetails(Get.arguments['locationEnum']);
        _registerController.selectedPlace = homeLocModel.location;
        _registerController.latController = homeLocModel.lat;
        _registerController.lngController = homeLocModel.lng;
        mapMainController.lastKnownLocation =
            LatLng(_registerController.latController, _registerController.lngController);
        isFromPrediction = true;
      }
    });

    mapMainController.socketIns?.disconnectListen("driverCancel-${globals.userid}");
    mapMainController.onDriverCancelled("driverCancel-${globals.userid}");
    super.initState();
  }

  initTheme(String isFrom) async {
    if (isFrom == "isFromThemeChange" && mapController != null) {
      mapMainController.onLoadMapStyle();
    } else if (!isMapControllerCreated && mapController != null) {
      isMapControllerCreated = true;
      mapMainController.onLoadMapStyle();
      moveToUserLocation();
    } else {
      isMapControllerCreated = false;
    }
  }

  initializeMapStyle(String isFrom) {
    switch (isFrom) {
      case "isFromCreated":
        initTheme(isFrom);
        break;
      case "isFromThemeChange":
        initTheme(isFrom);
        break;
      case "isFromGetInitialLocation":
        initTheme(isFrom);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapMainController.selectedPlace.value = _registerController.selectedPlace;
    });
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      if (mapController != null) initializeMapStyle("isFromThemeChange");
      return PrimaryScaffold(
        disableAppbar: true,
        customAppBarFunction: () {
           if (multiStopFrom == "dropLocationpage") {
           Get.back();
          } else if (multiStopFrom.contains("settingspage")) {
            Get.to(
                Settings(
                  isFromForSettings: multiStopFrom.split("###")[1].trim(),
                  movetoSetting: Get.arguments['movetoSetting'],
                ),
                duration: Duration(milliseconds: 215),
                transition: Transition.leftToRight);
          }
        },
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 95.0),
              child: Stack(
                children: [
                  Obx(() {
                    return Offstage(
                      offstage: !(globals.mapEnableController.value == true &&
                          (ModalRoute.of(context)?.isCurrent ?? false)),
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        style: globals.isDarkTheme
                            ? mapMainController.darkmapStyle
                            : mapMainController.mapStyle,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(globals.userLat, globals.userLon),
                          zoom: mapMainController.zoomLevel != null && mapMainController.zoomLevel != 0.0
                              ? mapMainController.zoomLevel
                              : 3.0,
                        ),
                        onCameraIdle: () {
                          _recallLoading = true;
                        },
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        rotateGesturesEnabled: false,
                        zoomControlsEnabled: false,
                        onCameraMove: _onCameraMove,
                        mapType: MapType.normal,
                        buildingsEnabled: false,
                        layoutDirection: TextDirection.ltr,
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(0.0),
                      child: Container(
                        width: 30,
                        height: 40,
                        child: Image.asset(pickUpPinPng),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 24.0, bottom: 28.0, start: 10.0),
                      child: InkWell(
                        onTap: () async {
                          moveToUserLocation();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.PRIMARY_LIGHT_COLOR,
                            shape: BoxShape.circle,
                          ),
                          width: 44,
                          height: 44,
                          child: SvgPicture.asset(
                            targetSvg,
                            fit: BoxFit.scaleDown,
                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _showGrid(context),

                  Obx(() {
                    globals.placeSearchingController.value;
                    return
                      Align(alignment: AlignmentDirectional.topCenter, child: showPlaceSearchField(context))
                    ;})
                  ,
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Container(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  padding: const EdgeInsetsDirectional.all(
                    24.0,
                  ),
                  child: PrimaryButton(
                    buttonTitle: 'Confirm_location'.tr,
                    buttonImage: primaryBtnArrow,
                    isLoad: true,
                    callback: () {
                      setLocation();
                    },
                  )),
            )
          ],
        ),
        onChanged: (map) {
          _scaffoldContext = map['scaffoldcontext'];
        },
      );
    });
  }

  Widget showBackButton(context) {
    return InkWell(
      onTap: () {
        globals.isLocationScreen = true;
        debugPrint("multiStopFrom: ${multiStopFrom}");
       if (multiStopFrom == "dropLocationpage") {
         Get.back();
        } else if (multiStopFrom.contains("settingspage")) {
          Get.to(
              Settings(
                isFromForSettings: multiStopFrom.split("###")[1].trim(),
                movetoSetting: Get.arguments['movetoSetting'],
              ),
              duration: Duration(milliseconds: 215),
              transition: Transition.leftToRight);
        }
      },
      child: Container(
        width: 41,
        height: 41,
        decoration: BoxDecoration(color: AppColors.PRIMARY_LIGHT_COLOR, shape: BoxShape.circle),
        child: RotatedBox(
          quarterTurns: globals.isRTLLang ? 2 : 0,
          child: SvgPicture.asset(
            primaryLeftArrow,
            colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }

  Widget showPlaceSearchField(context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showBackButton(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(start: 9, end: 24),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        rectangleSvg,
                        width: 10,
                        height: 10,
                        fit: BoxFit.scaleDown,
                        colorFilter: ColorFilter.mode(AppColors.BLACK, BlendMode.srcIn),
                      ),
                      !_registerController.showSelected
                          ? Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AppBarPlacesAutoCompleteTextField(
                                avoidUnderline: true,
                                hintText: 'search_your_location'.tr,
                              ),
                            ),
                            Visibility(
                              visible: !(PlacesAutocompleteState.queryTextController!.text.isEmpty),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 4,
                                ),
                                child: GetBuilder<RegisterController>(builder: (_) {
                                  double opacityval = 1;

                                  if (PlacesAutocompleteState.queryTextController!.text.isEmpty)
                                    opacityval = 0;
                                  else
                                    opacityval = 1;

                                  return AnimatedOpacity(
                                    duration: Duration(milliseconds: 50),
                                    opacity: opacityval,
                                    child: InkWell(
                                      onTap: () {
                                        PlacesAutocompleteState.queryTextController!.text = "";
                                        _registerController.selectedPlace = "";
                                        globals.setButtonIdle();
                                        _registerController.update();
                                      },
                                      child: SvgPicture.asset(
                                        closeCircleIcon,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      )
                          : Expanded(
                        child: InkWell(
                          onTap: () {
                            PlacesAutocompleteState.focus = true;
                            PlacesAutocompleteState.queryTextController!.text = _registerController.selectedPlace;
                            selectedPlace = _registerController.selectedPlace;
                            _registerController.showSelected = false;
                            globals.setButtonIdle();
                          },
                          child: Container(
                            constraints: BoxConstraints(minHeight: 50),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Obx(() {
                                _location = mapMainController.selectedPlace.value;
                                debugPrint(" mapMainController.selectedPlace.value: #${ mapMainController.selectedPlace.value}");
                                if (mapMainController.lastKnownLocation != null &&
                                    mapMainController.lastKnownLocation != LatLng(0.0, 0.0)) {
                                  _registerController.latController =
                                      mapMainController.lastKnownLocation.latitude;
                                  _registerController.lngController =
                                      mapMainController.lastKnownLocation.longitude;
                                } else {
                                  if (globals.userLat != 0.0 && globals.userLat != 0.0) {
                                    mapMainController.lastKnownLocation =
                                        LatLng(globals.userLat, globals.userLon);
                                    _registerController.latController = globals.userLat;
                                    _registerController.lngController = globals.userLon;
                                  }
                                }

                                return SingleChildScrollView(
                                  reverse: false,
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    _location == null || _location.isEmpty
                                        ? 'search_your_location'.tr
                                        : _location,
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: _location.isEmpty
                                            ? AppColors.LOCATION_ARRIVED_COLOR
                                            : AppColors.BLACK_TEXT_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_14,
                                        fontFamily: AppFont.font),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _registerController.showSelected
              ? const SizedBox.shrink()
              : Obx(() {
            globals.placeSearchingController.value;
            return Container(
              height: MediaQuery.of(context).size.height / 1.5,
              margin: const EdgeInsetsDirectional.only(top: 10, end: 24),
              child: PlacesAutocompleteResult(
                  listFooter: const SizedBox.shrink(),
                  onTap: (_prediction) {
                    isFromPrediction = true;
                    PlacesAutocompleteState.queryTextController!.text = "";
                    displayPrediction(_prediction);
                    _registerController.selectedPlace = _prediction['description'];
                    mapMainController.selectedPlace.value = _registerController.selectedPlace;
                    _registerController.showSelected = true;
                    globals.setButtonIdle();
                    globals.placeSearchingController.refresh();
                  }),
            );
          }),
        ],
      ),
    );
  }

  _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    globals.favoriteLocationEnumList.forEach((element) {
      if (element == Get.arguments['locationEnum'] &&
          mapMainController.getLocationDetails(element).location.isNotEmpty) {
        SelectLocationModel LocModel = mapMainController.getLocationDetails(element);
        _registerController.selectedPlace = LocModel.location;
        _registerController.latController = LocModel.lat;
        _registerController.lngController = LocModel.lng;
        _registerController.showSelected = true;
        if (LocModel.id != null) _locId = LocModel.id.toString();

        LatLng mapLocation = LatLng(_registerController.latController, _registerController.lngController);
        if (mapController != null) {
          mapController
              ?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: mapLocation,
              zoom: 15,
            ),
          ))
              .then((value) {
            Future.delayed(const Duration(milliseconds: 2500), () {
              isFromPrediction = false;
            });
          });
        }
      }
    });
    initializeMapStyle("isFromCreated");
  }

  Future<void> getLocation() async {
    await mapMainController.getNativeLocation();

    _registerController.selectedPlace = await getAddress(LatLng(globals.userLat, globals.userLon));
    moveToUserLocation();
  }

  void moveToUserLocation() {
    if (globals.userLat != 0.0 && globals.userLon != 0.0) {
      LatLng mapLocation = LatLng(globals.userLat, globals.userLon);
      if (mapController != null)
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: mapLocation,
            zoom: 15,
          ),
        ));
    } else {
      getLocation();
    }
  }

  Future<String> getAddress(LatLng latlng) async {
    if (latlng.latitude != 0.0 && latlng.longitude != 0.0) {
      List<Placemark> placemarks =
      await geocoding.Geocoding().placemarkFromCoordinates(latlng.latitude, latlng.longitude);

      return _registerController.getAddressFromPlaceMark(placemarks[0]);
    }
    return "";
  }

  getInitialLocation() async {
    if (selectedPlace == null || selectedPlace.isEmpty) {
      if (globals.userLat != null &&
          globals.userLon != null &&
          globals.userLat != 0.0 &&
          globals.userLon != 0.0) {
        mapMainController.lastKnownLocation = LatLng(globals.userLat, globals.userLon);
        String? address = await mapMainController.getUserLocationName();
        selectedPlace = address!;
        _registerController.selectedPlace = selectedPlace;

        _registerController.latController = globals.userLat;
        _registerController.lngController = globals.userLon;
        initializeMapStyle("isFromGetInitialLocation");
      }
    }
  }

  _showGrid(BuildContext context) {
    return Obx(() {
      return mapMainController.mapLoadingController.value == true
          ? Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: AppColors.GRID_COLOR,
        child: Image.asset(
          mapGridPng,
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.fill,
        ),
      )
          : const SizedBox(
        height: 0,
      );
    });
  }

  void _onCameraMove(CameraPosition position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {

      PrimaryScaffold.avoidLoader.value = true;
      globals.setButtonLoading();
    });

    debugPrint('select map location _onCameraMove ${isFromPrediction}');
    if (!isFromPrediction) {
      if (_locationfetchTimer != null) _locationfetchTimer?.cancel();
      mapMainController.lastKnownLocation = position.target;
      if (_recallLoading) {
        _recallLoading = false;
      }

      _mapIdleSubscription?.cancel();
      _mapIdleSubscription = Timer(Duration(milliseconds: 750), () {
        _registerController.latController = mapMainController.lastKnownLocation.latitude;
        _registerController.lngController = mapMainController.lastKnownLocation.longitude;
        mapMainController.ideal().then((value) {
          ScaffoldMessenger.of(_scaffoldContext!).hideCurrentSnackBar();
          if(value !=null) {

            if (value.isEmpty) {
              mapMainController.showInSnackBar('location_not_found'.tr);
              mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(0.0, 0.0),
                  zoom: 3,
                ),
              ));
            } else {
              _registerController.selectedPlace = value;
              mapMainController.setDestPlaceController(value);
            }

            if(_registerController.showSelected == false) {
              _registerController.showSelected = true;
              globals.placeSearchingController.refresh();
            }
          }

          Future.delayed(const Duration(milliseconds: 100), () {
            globals.setButtonIdle();
          });
        });
      });


    }
  }

  setLocation() async {
    if (_registerController.selectedPlace == "" ||
        _registerController.latController == null ||
        _registerController.lngController == null) {
      mapMainController.showInSnackBar('enter_location'.tr);
    } else {
      debugPrint('globals.selectedFavoriteLocationEnum: ${Get.arguments['locationEnum']}');
        globals.setButtonLoading();
        if (_locId == null || _locId == "") {
          _registerController.addFavoriteLocation(Get.arguments['locationEnum']).then((value) {
            globals.setButtonIdle();

            if (value == 'offline') {
              mapMainController.netOffSnackbar(setLocation, false);
            } else if (value.isNotEmpty) {
              mapMainController.showInSnackBar(value);
              globals.locController(true);
            } else {
              if (multiStopFrom == "dropLocationpage") {
                Get.back();
                mapMainController.update(['placeSelectController']);
              } else if (multiStopFrom.contains("settingspage")) {
                Get.to(
                    Settings(
                      isFromForSettings: multiStopFrom.split("###")[1].trim(),
                      movetoSetting: Get.arguments['movetoSetting'],
                    ),
                    duration: Duration(milliseconds: 215),
                    transition: Transition.leftToRight);
              }
              _registerController.selectedPlace = '';
              globals.locController(true);
            }
          });
        } else {
          _registerController.updateFavoriteLocation(_locId!, Get.arguments['locationEnum']).then((value) {
            globals.setButtonIdle();
            if (value.isNotEmpty) {
              mapMainController.showInSnackBar(value);
              globals.locController(true);
            } else {
              if (multiStopFrom == "dropLocationpage") {
                Get.to(SelectDropLocation(widget.isFromSchedule ?? false));
              } else if (multiStopFrom.contains("settingspage")) {
                Get.to(
                    Settings(
                      isFromForSettings: multiStopFrom.split("###")[1].trim(),
                      movetoSetting: Get.arguments['movetoSetting'],
                    ),
                    duration: Duration(milliseconds: 215),
                    transition: Transition.leftToRight);
              }
              _registerController.selectedPlace = '';
              globals.locController(true);
            }
          });
        }

    }
  }

  void stopLocationSelected(String location, int position, double lat, double lng) {
    LatLng latLng = LatLng(lat, lng);
    if (position == locationData.length - 1) {
      if (locationData.length < 4) {
        locationData.insert(position, LocationData(latLng, location));
      } else {
        var tempData = locationData[position];
        locationData.removeAt(position);
        locationData.insert(
            position,
            LocationData(latLng, location, tempData.fieldType, tempData.id, tempData.locationStatus,
                tempData.locationType));
      }
    } else {
      var tempData = locationData[position];
      locationData.removeAt(position);
      locationData.insert(
          position,
          LocationData(latLng, location, tempData.fieldType, tempData.id, tempData.locationStatus,
              tempData.locationType));
    }

    if (multiStopFrom != "SelectDropLocation") {
      for (int i = 0; i < locationData.length; i++) {
        if (i < mapMainController.locationData.length) {
          locationData[i].fieldType = mapMainController.locationData[i].fieldType;
        } else {
          if (locationData[i].location!.isNotEmpty) {
            locationData[i].fieldType = "deletable";
          }
        }
      }
    }
  }

  @override
  void dispose() {
    PrimaryScaffold.avoidLoader.value = false;
    _recallLoading = false;
    globals.setButtonIdle();
    mapController?.dispose();
    super.dispose();
  }

  Future<Null> displayPrediction(var p) async {
    _registerController.latController = 0.0;
    _registerController.lngController = 0.0;
    isFromPrediction = true;
    PlacesAutocompleteState.focus = false;

    var detail = await await mapMainController.findPlaces(p['place_id']);
    final lat = detail.latitude;
    final lng = detail.longitude;

    if (lat == 0.0 && lng == 0.0) {
      mapMainController
          .showInSnackBar("latLng not found for this location, please try again or try different location");
    } else {
      _registerController.showSelected = true;
      _registerController.latController = lat;

      _registerController.lngController = lng;

      globals.setButtonIdle();

      LatLng mapLocation = LatLng(_registerController.latController, _registerController.lngController);
      mapMainController.lastKnownLocation = mapLocation;
      if (mapController != null)
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: mapLocation,
            zoom: 15,
          ),
        )).then((value) {
          Future.delayed(const Duration(milliseconds: 1700), () {
            isFromPrediction = false;
            globals.setButtonIdle();
          });
        });
    }
  }

  void getLatLngForMultipleStop(String value) async {
    if (_location.isEmpty && value.isNotEmpty) {
      _location = value;
      mapMainController.setDestPlaceController(_location);
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => false;
}