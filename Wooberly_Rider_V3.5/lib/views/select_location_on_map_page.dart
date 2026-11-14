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
import 'package:app_name/app/enums/button_state.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../bindings/home_binding.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../controllers/register_controller.dart';

/// A dedicated map page that lets the user pick a location by:
/// 1. Searching via Places API (top search field)
/// 2. Dragging the map (camera-move reverse geocoding)
///
/// After confirming, the chosen location is written to the correct
/// pickup or drop slot in [MapMainController] and the user is sent
/// back to [SelectDropLocation].
class SelectLocationOnMapPage extends StatelessWidget {
  final bool isFromSchedule;
  final List<LocationData> locationData;

  const SelectLocationOnMapPage({
    Key? key,
    required this.isFromSchedule,
    required this.locationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SelectLocationOnMapView(
      isFromSchedule: isFromSchedule,
      locationData: locationData,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widget — extends PlacesAutocompleteWidget so we get the Places
// API search machinery for free (same pattern as select_map_location.dart).
// ---------------------------------------------------------------------------

class _SelectLocationOnMapView extends PlacesAutocompleteWidget {
  final bool isFromSchedule;
  final List<LocationData> locationData;

  _SelectLocationOnMapView({
    required this.isFromSchedule,
    required this.locationData,
  }) : super();

  @override
  _SelectLocationOnMapState createState() =>
      _SelectLocationOnMapState(locationData);
}

class _SelectLocationOnMapState extends PlacesAutocompleteState
    with AutomaticKeepAliveClientMixin {
  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  final MapMainController _mapMainController = Get.find();
  final RegisterController _registerController = Get.find();

  /// Which slot we are filling (pickup or drop).
  final List<LocationData> locationData;

  GoogleMapController? _mapController;
  BuildContext? _scaffoldContext;

  bool _isMapControllerCreated = false;
  bool _isFromPrediction = false;
  bool _recallLoading = true;

  Timer? _mapIdleTimer;
  Timer? _locationFetchTimer;

  _SelectLocationOnMapState(this.locationData);

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    globals.isLocationScreen = true;

    debugPrint("PlacesAutocompleteState.activeStopIndex: ${PlacesAutocompleteState.activeStopIndex} --- ${PlacesAutocompleteState.selectLocationEnum}");
    _mapMainController.onLoadMapStyle();
    _registerController.showSelected = true;

    // Pre-fill the text field with whatever location is already saved for
    // this slot so the user sees what was previously chosen.
   String? _targetLocationName = locationData[PlacesAutocompleteState.activeStopIndex].location;
   LatLng? _targetLatLng = locationData[PlacesAutocompleteState.activeStopIndex].latLng;
    debugPrint("existingLocation:---  --- ${_targetLocationName}");
    if (_targetLocationName !=null && _targetLocationName.isNotEmpty && _targetLatLng !=null && _targetLatLng.latitude !=0.0 && _targetLatLng.longitude !=0.0) {
      _registerController.selectedPlace = _targetLocationName;
      final targetLatLng = _targetLatLng;
      _registerController.latController = targetLatLng.latitude;
      _registerController.lngController = targetLatLng.longitude;
      _mapMainController.lastKnownLocation = targetLatLng;
    } else {
      _getInitialLocation();
    }

    DefaultCacheManager().emptyCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrimaryScaffold.avoidLoader.value = true;
      _mapMainController.mapLoadingController(true);
      Future.delayed(const Duration(milliseconds: 600), () {
        _mapMainController.mapLoadingController(false);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    PrimaryScaffold.avoidLoader.value = false;
    _recallLoading = false;
    globals.setButtonIdle();
    _mapIdleTimer?.cancel();
    _locationFetchTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<void> _getInitialLocation() async {
    if (globals.userLat != 0.0 && globals.userLon != 0.0) {
      _mapMainController.lastKnownLocation = LatLng(globals.userLat, globals.userLon);
      final address = await _mapMainController.getUserLocationName() ?? '';
      _registerController.selectedPlace = address;
      _registerController.latController = globals.userLat;
      _registerController.lngController = globals.userLon;
      _mapMainController.setDestPlaceController(_registerController.selectedPlace);
      debugPrint("_registerController.selectedPlace: ${_registerController.selectedPlace}");
      _initMapStyle('isFromGetInitialLocation');
    }
  }



  void _initMapStyle(String from) {
    if (from == 'isFromThemeChange' && _mapController != null) {
      _mapMainController.onLoadMapStyle();
    } else if (!_isMapControllerCreated && _mapController != null) {
      _isMapControllerCreated = true;
      _mapMainController.onLoadMapStyle();
      _moveToUserLocation();
    } else {
      _isMapControllerCreated = false;
    }
  }

  void _moveToUserLocation() {
    if (globals.userLat != 0.0 && globals.userLon != 0.0) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_registerController.latController !=0.0 ? _registerController.latController : globals.userLat,
              _registerController.lngController !=0.0 ? _registerController.lngController : globals.userLon,),
            zoom: 15,
          ),
        ),
      );
    } else {
      _fetchAndMoveToUserLocation();
    }
  }

  Future<void> _fetchAndMoveToUserLocation() async {
    await _mapMainController.getNativeLocation();
    _registerController.selectedPlace =
        await _getAddressString(LatLng(globals.userLat, globals.userLon));
    _moveToUserLocation();
  }

  Future<String> _getAddressString(LatLng latlng) async {
    if (latlng.latitude != 0.0 && latlng.longitude != 0.0) {
      List<Placemark> placemarks = await geocoding.Geocoding().placemarkFromCoordinates(
          latlng.latitude, latlng.longitude);
      return _registerController.getAddressFromPlaceMark(placemarks[0]);
    }
    return '';
  }



  // -------------------------------------------------------------------------
  // Map callbacks
  // -------------------------------------------------------------------------

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // If we already have coordinates for this slot, animate there.
    final loc = LatLng(_registerController.latController, _registerController.lngController);
    debugPrint("_onMapCreatedloc: ${loc}");
    if (loc.latitude != 0.0 && loc.longitude != 0.0) {
      _mapController
          ?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 15)),
      )
          .then((_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          _isFromPrediction = false;
        });
      });
      _isFromPrediction = true;
    }

    _initMapStyle('isFromCreated');
  }

  void _onCameraMove(CameraPosition position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrimaryScaffold.avoidLoader.value = true;
      if (!_isFromPrediction)
      globals.setButtonLoading();
    });
    debugPrint('buttonidle :_isFromPrediction  ${_isFromPrediction}');
    if (!_isFromPrediction) {
      _locationFetchTimer?.cancel();
      _mapMainController.lastKnownLocation = position.target;
      if (_recallLoading) _recallLoading = false;

      _mapIdleTimer?.cancel();
      _mapIdleTimer = Timer(const Duration(milliseconds: 750), () {
        _registerController.latController =
            _mapMainController.lastKnownLocation.latitude;
        _registerController.lngController =
            _mapMainController.lastKnownLocation.longitude;

        _mapMainController.ideal().then((value) {
          if (_scaffoldContext != null) {
            ScaffoldMessenger.of(_scaffoldContext!).hideCurrentSnackBar();
          }
          if (value != null) {
            if (value.isEmpty) {
              _mapMainController.showInSnackBar('location_not_found'.tr);
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: LatLng(0.0, 0.0), zoom: 3),
                ),
              );
            } else {
              _registerController.selectedPlace = value;
              _mapMainController.setDestPlaceController(value);
            }

            if (!_registerController.showSelected) {
              _registerController.showSelected = true;
              globals.placeSearchingController.refresh();
            }
          }
          Future.delayed(const Duration(milliseconds: 100), () {
            debugPrint('buttonidle');
            globals.setButtonIdle();
          });
        });
      });
    } else {
      globals.setButtonIdle();
    }
  }

  // -------------------------------------------------------------------------
  // Confirm location action
  // -------------------------------------------------------------------------

  Future<void> _confirmLocation() async {
    final place = _registerController.selectedPlace;
    final lat = _registerController.latController;
    final lng = _registerController.lngController;

    if (place.isEmpty || lat == 0.0 || lng == 0.0) {
      _mapMainController.showInSnackBar('enter_location'.tr);
      return;
    }
   Get.back(result: {'place': place, 'lat': lat, 'lng': lng});
  }

  // -------------------------------------------------------------------------
  // Prediction selected from Places API list
  // -------------------------------------------------------------------------

  Future<void> displayPrediction(var p) async {
    _registerController.latController = 0.0;
    _registerController.lngController = 0.0;
    _isFromPrediction = true;

    final detail = await _mapMainController.findPlaces(p['place_id']);
    final lat = detail.latitude;
    final lng = detail.longitude;

    if (lat == 0.0 && lng == 0.0) {
      _mapMainController.showInSnackBar(
          'latLng not found for this location, please try again or try different location');
    } else {
      _registerController.showSelected = true;
      _registerController.latController = lat;
      _registerController.lngController = lng;
      globals.setButtonIdle();

      final mapLocation = LatLng(lat, lng);
      _mapMainController.lastKnownLocation = mapLocation;

      _mapController
          ?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: mapLocation, zoom: 15),
        ),
      )
          .then((_) {
        Future.delayed(const Duration(milliseconds: 1700), () {
          _isFromPrediction = false;
          globals.setButtonIdle();
        });
      });
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapMainController.selectedPlace.value = _registerController.selectedPlace;
      debugPrint("maplocationset: ${_mapMainController.selectedPlace.value}");
    });

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      if (_mapController != null) _initMapStyle('isFromThemeChange');

      return PrimaryScaffold(
        disableAppbar: true,
        customAppBarFunction: () => _navigateBack(),
        body: Stack(
          children: [
            // ── Map + pin ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 95.0),
              child: Stack(
                children: [
                  // Google Map
                  Obx(() {
                    debugPrint("_onMapCreatedloc123: ${_registerController.latController !=0.0 ? _registerController.latController : globals.userLat}");
                    return Offstage(
                      offstage: !(globals.mapEnableController.value == true &&
                          (ModalRoute.of(context)?.isCurrent ?? false)),
                      child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          style: globals.isDarkTheme
                              ? _mapMainController.darkmapStyle
                              : _mapMainController.mapStyle,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _registerController.latController !=null && _registerController.latController !=0.0 ? _registerController.latController : globals.userLat,
                              _registerController.lngController !=null && _registerController.lngController !=0.0 ? _registerController.lngController : globals.userLon,
                            ),
                            zoom: _mapMainController.zoomLevel != 0.0
                                ? _mapMainController.zoomLevel
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

                  // Center pin
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(0.0),
                      child: SizedBox(
                        width: 30,
                        height: 40,
                        child: Image.asset(
                           pickUpPinPng,
                        ),
                      ),
                    ),
                  ),

                  // My-location FAB
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                          end: 24.0, bottom: 28.0, start: 10.0),
                      child: InkWell(
                        onTap: _moveToUserLocation,
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
                            colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loading grid overlay
                  _buildGridOverlay(context),

                  // Top search bar + prediction list
                  Obx(() {
                    globals.placeSearchingController.value;
                    return Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: _buildSearchField(context),
                    );
                  }),
                ],
              ),
            ),

            // ── Confirm button ─────────────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Container(
                color: AppColors.PRIMARY_LIGHT_COLOR,
                padding: const EdgeInsetsDirectional.all(24.0),
                child: PrimaryButton(
                  buttonTitle: 'Confirm_location'.tr,
                  buttonImage: primaryBtnArrow,
                  isLoad: true,
                  callback: _confirmLocation,
                ),
              ),
            ),
          ],
        ),
        onChanged: (map) {
          _scaffoldContext = map['scaffoldcontext'];
        },
      );
    });
  }

  // ── Back navigation ────────────────────────────────────────────────────────

  void _navigateBack() {
    globals.setButtonIdle();
    PlacesAutocompleteState.focus = false;
    Get.back();
  }

  // ── Loading grid ───────────────────────────────────────────────────────────

  Widget _buildGridOverlay(BuildContext context) {
    return Obx(() {
      return _mapMainController.mapLoadingController.value == true
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
          : const SizedBox(height: 0);
    });
  }

  // ── Top search field ───────────────────────────────────────────────────────

  Widget _buildSearchField(BuildContext context) {
    debugPrint("_registerController.selectedPlace: ${_registerController.selectedPlace} ---${PlacesAutocompleteState.queryTextController?.text}");
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Back button
              InkWell(
                onTap: _navigateBack,
                child: Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    shape: BoxShape.circle,
                  ),
                  child: RotatedBox(
                    quarterTurns: globals.isRTLLang ? 2 : 0,
                    child: SvgPicture.asset(
                      primaryLeftArrow,
                      colorFilter: ColorFilter.mode(
                          AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),

              // Search field
              Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(start: 9, end: 24),
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 10),
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
                        colorFilter: ColorFilter.mode(
                            AppColors.BLACK, BlendMode.srcIn),
                      ),
                      !_registerController.showSelected
                          // ── Typing mode ────────────────────────────────
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
                                    visible: !(PlacesAutocompleteState
                                            .queryTextController
                                            ?.text
                                            .isEmpty ??
                                        true),
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                              horizontal: 4),
                                      child: GetBuilder<RegisterController>(
                                          builder: (_) {
                                        final hasText =
                                            !(PlacesAutocompleteState
                                                    .queryTextController
                                                    ?.text
                                                    .isEmpty ??
                                                true);
                                        return AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 50),
                                          opacity: hasText ? 1 : 0,
                                          child: InkWell(
                                            onTap: () {
                                              PlacesAutocompleteState
                                                  .queryTextController
                                                  ?.text = '';
                                              _registerController
                                                  .selectedPlace = '';
                                              globals.setButtonIdle();
                                              _registerController.update();
                                            },
                                            child: SvgPicture.asset(
                                              closeCircleIcon,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.PRIMARY_ICON_COLOR,
                                                  BlendMode.srcIn),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // ── Display-selected mode ───────────────────────
                          : Expanded(
                              child: InkWell(
                                onTap: () {
                                  PlacesAutocompleteState.focus = true;
                                  PlacesAutocompleteState.queryTextController?.text = _registerController.selectedPlace;
                                  _registerController.showSelected = false;
                                  globals.setButtonIdle();
                                },
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 50),
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                          horizontal: 10, vertical: 5),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Obx(() {

                                      final loc = _mapMainController.selectedPlace.value;
                                      debugPrint("locasdfg: ${loc} --- ${_registerController.selectedPlace}");
                                      if (_mapMainController
                                              .lastKnownLocation !=
                                          const LatLng(0.0, 0.0)) {
                                        _registerController.latController =
                                            _mapMainController
                                                .lastKnownLocation.latitude;
                                        _registerController.lngController =
                                            _mapMainController
                                                .lastKnownLocation.longitude;
                                      } else if (globals.userLat != 0.0) {
                                        _mapMainController.lastKnownLocation =
                                            LatLng(globals.userLat,
                                                globals.userLon);
                                        _registerController.latController =
                                            globals.userLat;
                                        _registerController.lngController =
                                            globals.userLon;
                                      }
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          loc.isEmpty
                                              ? 'search_your_location'.tr
                                              : loc,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: loc.isEmpty
                                                ? AppColors
                                                    .LOCATION_ARRIVED_COLOR
                                                : AppColors.BLACK_TEXT_COLOR,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_14,
                                            fontFamily: AppFont.font,
                                          ),
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

          // ── Predictions list ─────────────────────────────────────────────
          _registerController.showSelected
              ? const SizedBox.shrink()
              : Obx(() {
                  globals.placeSearchingController.value;
                  return Container(
                    height: MediaQuery.of(context).size.height / 1.5,
                    margin: const EdgeInsetsDirectional.only(top: 10, end: 24),
                    child: PlacesAutocompleteResult(
                      listFooter: const SizedBox.shrink(),
                      onTap: (prediction) {
                        _isFromPrediction = true;
                        PlacesAutocompleteState.queryTextController?.text = '';
                        displayPrediction(prediction);
                        _registerController.selectedPlace = prediction['description'];
                        _mapMainController.selectedPlace.value =  _registerController.selectedPlace;
                        debugPrint("maplocationset:  2${_mapMainController.selectedPlace.value}");
                        _registerController.showSelected = true;
                        globals.setButtonIdle();
                        globals.placeSearchingController.refresh();
                      },
                    ),
                  );
                }),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}