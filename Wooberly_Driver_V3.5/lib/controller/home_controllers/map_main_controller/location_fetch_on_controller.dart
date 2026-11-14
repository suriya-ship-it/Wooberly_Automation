part of 'map_main_controller.dart';

extension LocationFetchOnController on MapMainController {
  Future<void> getcurrentloc() async {
    if (mapController != null) {
      debugPrint("camera animate 1");
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(mapLocation.latitude, mapLocation.longitude),
          zoom: 15,
        ),
      ));
    }
    rxRouteController.value = mapLocation;
  }

  Future<void> getLocation(String loc, [String disableMapLocation = ""]) async {
    try {
      String currentLocation = loc.isEmpty
          ? await App().getNativeLocation('gps')
          : await App().getNativeLocation();
      mapLocation = LatLng(globals.userLat, globals.userLon);
      if (disableMapLocation == null)
        updateDriverLocation(loc, double.parse(currentLocation.split('///')[2]),
            "updateApiAndPath");
      else {
        position = [mapLocation.latitude, mapLocation.longitude];
        if(markers[carMarker] ==null){
          setMarkerprocess();
        }
        markers[carMarker] = markers[carMarker]!.copyWith(
          rotationParam: rotationbearing,
          positionParam: LatLng(globals.userLat, globals.userLon),
        );
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> getInitialLocation(int i) async {
    print("getInitialLocation: ${i}");

    try {
      bool isServiceEnable = await App().isLocationServiceEnable();
      PermissionStatus locationPermission = await Permission.location.status;
      if (isServiceEnable && !locationPermission.isPermanentlyDenied){
        Future.delayed(const Duration(milliseconds: 40000), () {
          if (globals.userLat == 0.0 && globals.userLon == 0.0) {
            App().toast.show(
                  context: scaffoldContext!,
                  message: location_fetch_failed,
                );
            getInitialLocation(7);
          }
        });
       await App().getNativeLocation();
        if (globals.userLat != 0.0 && globals.userLon != 0.0) {
          mapLocation = LatLng(globals.userLat, globals.userLon);
          setMarkerprocess();

          if (mapController != null) {
            debugPrint("camera animate 3");
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(globals.userLat, globals.userLon),
                zoom: 15,
              ),
            ));
          }
        }
      }
    } on Exception catch (e, stack) {
      debugPrint("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }

  }

  Future<String> updateLocalLocationStatusArray(int position) async {
    locationData[position].locationStatus = "completed";
    polylineoldLocation = LatLng(0.0, 0.0);
    updateShowLocationController(locationData[position + 1].location);
    if (position != 0)
      updateBookingLocationToRider("tripStatus-${globals.userid}");
    return "";
  }

}