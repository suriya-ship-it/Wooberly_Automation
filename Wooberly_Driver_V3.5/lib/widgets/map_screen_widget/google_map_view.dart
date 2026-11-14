import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../views/map_main_screen.dart';

class GoogleMapView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  GoogleMapView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView>
    with TickerProviderStateMixin {
  int oldMapId = -1;
  Timer? _reloadTimer;

  @override
  void initState() {
    widget.controller.rxRouteController.stream.listen((event) {
      if (globals.userLat != 0.0 &&
          globals.userLon != 0.0 &&
          widget.controller.mapLocation != null &&
          widget.controller.mapLocation.latitude == 0.0 &&
          widget.controller.mapLocation.longitude == 0.0) {
        widget.controller.mapLocation = LatLng(globals.userLat, globals.userLon);
      }
      mapRebuild(widget.controller.rxUpdatePaddingController.value);
    });

    widget.controller.rxMapPaddingController.stream.listen((event) {
      if (event != widget.controller.rxUpdatePaddingController.value) {
        mapRebuild(event);
      }
    });

    super.initState();
  }
  
  @override
  void reassemble() {
    super.reassemble();
    widget.controller.updateDriverPath(true, null);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: MapMainController(),
        id: widget.controller.rxUpdatePaddingController.id,
        builder: (val) {
          double bottompadding = globals.driverStatus != "active"
              ? 0.0
              : (widget.controller.rxUpdatePaddingController.value == 0.0)
                  ? 110
                  : widget.controller.rxUpdatePaddingController.value;
          return Stack(
            children: [
              ColoredBox(
                color: AppColors.PRIMARY_COLOR_WHITE,
                child: GoogleMap(
                    circles: Set.from([Circle(
                    circleId: CircleId('circle'),
                    visible: widget.controller.tripStatus == "approved",
                    center: LatLng(widget.controller.pickLat ,widget.controller.pickLon),
                    radius: double.parse(globals.startRideRadius.isEmpty ? "0.0" : globals.startRideRadius),
                      fillColor: AppColors.PRIMARY_COLOR_DARK.withValues(alpha:0.1),
                      strokeWidth: 1,
                      strokeColor: AppColors.PRIMARY_COLOR_DARK.withValues(alpha:0.5)
              )]),
                  style: widget.homeViewState.mapStyle,
                  onMapCreated: _onMapCreated,
                  polylines: widget.controller.polylines !=
                          Polyline(polylineId: PolylineId(''))
                      ? Set<Polyline>.of(
                          [widget.controller.polylines],
                        )
                      : Set<Polyline>.of(Iterable<Polyline>.empty()),
                  markers: Set<Marker>.of(widget.controller.markers.values),
                  myLocationEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  buildingsEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  layoutDirection: TextDirection.ltr,
                  minMaxZoomPreference: MinMaxZoomPreference(3, 18),
                  onCameraMove: widget.controller.onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: widget.controller.mapLocation,
                    zoom: widget.controller.mapLocation != null &&
                            widget.controller.mapLocation.latitude != 0.0 &&
                            widget.controller.mapLocation.longitude != 0.0
                        ? widget.controller.zoomLevel != null &&
                                widget.controller.zoomLevel != 0.0
                            ? widget.controller.zoomLevel
                            : 15.0
                        : 0.0,
                  ),
                ),
              ),
              bottompadding != 0.0
                  ? Container(
                      padding:
                          EdgeInsetsDirectional.only(bottom: bottompadding + 5),
                      alignment: AlignmentDirectional.bottomStart,
                      child: Image.asset(
                        googleLogoPng,
                        height: 25,
                      ))
                  : const SizedBox.shrink()
            ],
          );
        });
  }

  _onMapCreated(GoogleMapController controller) {
    if (oldMapId == -1)
      oldMapId = controller.mapId;
    else {
      widget.controller.mapsImplementation.init(controller.mapId);
    }
    widget.controller.mapController = controller;
    widget.controller.change(rxVariable: widget.controller.rxUpdatePaddingController, value: widget.controller.rxUpdatePaddingController.value);
    if (globals.userLat != 0.0 && globals.userLon != 0.0)
      widget.controller.setMarkerprocess();
  }

  void mapRebuild(double value) {
    if(_reloadTimer ==null || !_reloadTimer!.isActive)
    _reloadTimer = Timer(const Duration(milliseconds: 200), () {
      widget.controller.change(
        rxVariable: widget.controller.rxUpdatePaddingController,
        value: value,
      );
      _reloadTimer?.cancel();
    });
  }
}