import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../views/map_main_screen.dart';



class ShowMapView extends StatelessWidget {
  final MapMainController mapMainController=Get.find();
  final String? isFrom;
  final VoidCallback? onCameraIdle;
  final CameraPositionCallback? onCameraMove;
  final HomeViewState? state;

  ShowMapView(
      {Key? key,
        this.isFrom,
        this.onCameraIdle,
        this.state,
        this.onCameraMove})
      : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ShowMapViewStateful(
      key: key,
      mapMainController: mapMainController,
      isFrom: isFrom,
      onCameraIdle: onCameraIdle,
      onCameraMove: onCameraMove,
      state: state,
    );
  }
}


class ShowMapViewStateful extends StatefulWidget {
  late final MapMainController mapMainController;
  final String? isFrom;
  final VoidCallback? onCameraIdle;
  final CameraPositionCallback? onCameraMove;
  final HomeViewState? state;

  ShowMapViewStateful(
      {Key? key,
        required this.mapMainController,
        this.isFrom,
        this.onCameraIdle,
        this.state,
        this.onCameraMove})
      : super(key: key);

  @override
  State<ShowMapViewStateful> createState() => ShowMapViewState();
}


class ShowMapViewState extends State<ShowMapViewStateful> with TickerProviderStateMixin  {
  @override
  void initState() {
    ever(globals.mapEnableController, (data){
      debugPrint("mapEnableController: ${data}");
      updateMap();
    });
    widget.mapMainController.routeController.stream.listen((_){
      updateMap();
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    widget.mapMainController.onLoadMapStyle();
    return Obx((){

      if(widget.mapMainController.isUserInTrip)
      widget.mapMainController.markersMap
          .removeWhere((key, value) => key.value.contains("source_"));
      debugPrint("widget.mapMainController.mappadding: ${widget.mapMainController.mapPaddingController.value}");
      return Stack(
        children: [
          GoogleMap(
            onMapCreated: onMapCreated,
            myLocationButtonEnabled: false,
            myLocationEnabled: widget.isFrom == AppRoutes.APP_HOME,
            compassEnabled: false,
            mapToolbarEnabled: false,
            style: globals.isDarkTheme ? widget.mapMainController.darkmapStyle : widget.mapMainController.mapStyle,
            rotateGesturesEnabled: false,
            zoomControlsEnabled: false,
            buildingsEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(3, 18),
            onCameraIdle: widget.onCameraIdle ?? () {},
            polylines: widget.isFrom != AppRoutes.APP_HOME && widget.mapMainController.polyLines != null
                ? Set<Polyline>.of([widget.mapMainController.polyLines],
            )
                : Set<Polyline>.of(Iterable<Polyline>.empty()),
            markers: getMarkers(),
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(globals.userLat, globals.userLon),
              zoom: widget.mapMainController.zoomLevel != null &&
                  widget.mapMainController.zoomLevel != 0.0
                  ? widget.mapMainController.zoomLevel
                  : 3.0,
            ),
          ),
          if (!widget.mapMainController.mapRefreshController.value)
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: AppColors.GRID_COLOR,
              child: Image.asset(
                mapGridPng,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
              ),
            ),
        ],
      );
    });
  }

  onMapCreated(GoogleMapController controller) async {
    widget.mapMainController.mapController = controller;
    debugPrint("onMapCreated id: ${controller.mapId}");
    if (widget.isFrom == AppRoutes.APP_HOME) {
      if (!await Permission.location.isGranted) {
        Permission.location.request();
        return;
      }
      if (globals.userLat != 0.0 && globals.userLon != 0.0) {
        widget.mapMainController.mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target:  globals.tripStatus == "started" ?
             widget.mapMainController.getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!
                : LatLng(globals.userLat, globals.userLon),
            zoom: 15,
          ),
        ));
      }
      else if(widget.isFrom == AppRoutes.APP_HOME && globals.userLat == 0.0 && globals.userLon == 0.0){
        widget.mapMainController.mapController
            ?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(globals.userLat, globals.userLon),
            zoom: 3,
          ),
        ));
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.mapMainController.mapLoading = false;
        widget.mapMainController.updateHomeMapController(true);
        widget.mapMainController.updateHomeMapController.refresh();
      });
    }
    else{
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.mapMainController.mapLoadingController(false);
      });
    }
    if(!widget.mapMainController.mapControllerCompleter.isCompleted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.mapMainController.mapControllerCompleter.complete(controller);
        widget.mapMainController.updateGoogleMap();
      });
    }
  }

  getMarkers() {
    if (widget.isFrom == AppRoutes.APP_HOME) {
      return widget.mapMainController.HomeMarkersMap != null
          ? Set<Marker>.of(widget.mapMainController.HomeMarkersMap.values)
          : Set<Marker>.of(Iterable<Marker>.empty());
    } else {
      for (var item in widget.mapMainController.markersMap.values) {
        if(item !=null) {
          if (item.position == null || item.markerId == null ||
              item.icon == null || item.position.latitude == null ||
              item.position.longitude == null) {
            widget.mapMainController.markersMap.clear();
            break;
          }
        }

      }
      return widget.mapMainController.markersMap != null
          ? Set<Marker>.of(widget.mapMainController.markersMap.values)
          : Set<Marker>.of(Iterable<Marker>.empty());
    }
  }

  void updateMap() {
    if(widget.mapMainController.reloadMap){
      widget.mapMainController.reloadMap=false;
      Future.delayed(Duration(milliseconds: 300),(){
          widget.mapMainController.mapRefreshController.refresh();
        widget.mapMainController.reloadMap=true;
      });

    }

  }
}