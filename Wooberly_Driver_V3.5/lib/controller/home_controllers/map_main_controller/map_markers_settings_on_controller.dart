part of 'map_main_controller.dart';

extension MapMarkersSettingsOnController on MapMainController {
  setCarMarker(LatLng sourceLoc, LatLng riderLoc, bool isupdate) async {
    markers.remove(_endingMarkerId);
    markers[_endingMarkerId] = _endingMarker!.copyWith(
      positionParam: riderLoc,
    );
    rxRouteController.refresh();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<String?> getEndLoc(String loc) async {
    try {
      if (loc.compareTo("start") == 0) {
        rideStartedAt = mapLocation;
      } else if (loc.compareTo("end") == 0) {
        String locationstatus = await getUserCurrentLocName();
        if (locationstatus == "failed") {
          return locationstatus;
        } else if (rideEndedAt != null && rideEndedAt != LatLng(0.0, 0.0)) {
          globals.userLat = rideEndedAt.latitude;
          globals.userLon = rideEndedAt.longitude;
        }
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  updateDriverLocation(String locpurpose, double heading, String updateStatus) {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_getPolylinesWithLocation ${point} --- ');
    if (locpurpose.compareTo("update") == 0) {
      rideEndedAt = mapLocation;
      if (isDriverAccept() && updateStatus == "updateApiAndPath") {
        updateDriverPath(false, mapLocation);
      }
    } else {
      _removeMarker();
    }
    if (mapController != null) {
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
        globals.userLat = mapLocation.latitude;
        globals.userLon = mapLocation.longitude;
      }

      mapController?.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(mapLocation.latitude, mapLocation.longitude),
          zoom: zoomLevel != null && zoomLevel != 0.0 ? zoomLevel : 17.0,
        ),
      ));
    }
  }

  void bearingBetween(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude)
  {
    if ((startLatitude - endLatitude).abs() < 0.0000001 &&
        (startLongitude - endLongitude).abs() < 0.0000001) {
      return;
    }
    const double PI = 3.1415926535897932;
    double lat1 = startLatitude * PI / 180;
    double long1 = startLongitude * PI / 180;
    double lat2 = endLatitude * PI / 180;
    double long2 = endLongitude * PI / 180;

    double dLon = (long2 - long1);

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double brng = atan2(y, x);

    brng = degrees(brng);
    brng = ((brng + 360) % 360);

    rotationbearing = brng;
  }

  void _removeMarker() async {
    markerMoveIteration = 0;
    bool isUpdateMarker = false;

    if (position == null || (position?.isEmpty ?? true)) {
      isUpdateMarker = true;
      position = [mapLocation.latitude, mapLocation.longitude];
    }

    if (isUpdateMarker) {
      rxRouteController.value = mapLocation;
    }

    // Frame delay: 33ms (~30 FPS) for smooth animation without overloading the CPU/event loop
    delay = 33;
    int intervalSec = globals.locationFetchInterval;
    if (intervalSec <= 0) intervalSec = 5;
    int totalDurationMs = intervalSec * 1000;
    numDeltas = (totalDurationMs / delay).round();
    if (numDeltas < 10) numDeltas = 10;

    debugPrint("_removeMarker: numDeltas=$numDeltas -- interval=${globals.locationFetchInterval}s --- delay=${delay}ms");

    if (markers[carMarker] == null || markers.isEmpty) {
      carMarker = const MarkerId("marker_id_1");
      Marker locMarker = Marker(
          markerId: carMarker,
          position: mapLocation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          icon: globals.categoryImage!);
      markers[carMarker] = locMarker;
      position = [mapLocation.latitude, mapLocation.longitude];
      rxRouteController.value = mapLocation;
      return;
    }

    LatLng currentPos = markers[carMarker]!.position;
    double distancemarkerlocation = calculateDistanceByMeter(
        currentPos.latitude, currentPos.longitude, mapLocation.latitude, mapLocation.longitude);

    if (mapUtils == null) mapUtils = MapUtils();
    debugPrint("_removeMarker: distancemarkerlocation $distancemarkerlocation");

    if (distancemarkerlocation > 2.0) {
      _polylineMoverMarker();
    } else {
      toForceCurrentLocation = 0;
      oldCoordinate = LatLng(0.0, 0.0);
      if (markers[carMarker] != null) {
        markers[carMarker] = markers[carMarker]!.copyWith(
          rotationParam: rotationbearing,
          positionParam: mapLocation,
        );
      }
      position = [mapLocation.latitude, mapLocation.longitude];
      rxRouteController.value = mapLocation;
    }
  }

  _polylineMoverMarker() async {
    final int currentAnimId = ++markerAnimationId;
    LatLng startPos = markers[carMarker]?.position ?? mapLocation;
    LatLng targetPos = mapLocation;

    double directDistance = calculateDistanceByMeter(
      startPos.latitude, startPos.longitude,
      targetPos.latitude, targetPos.longitude,
    );

    // If jump/teleport is very large (> 400m), snap directly to target
    if (directDistance > 400.0) {
      bearingBetween(startPos.latitude, startPos.longitude, targetPos.latitude, targetPos.longitude);
      if (markers[carMarker] != null) {
        markers[carMarker] = markers[carMarker]!.copyWith(
          rotationParam: rotationbearing,
          positionParam: targetPos,
        );
      }
      position = [targetPos.latitude, targetPos.longitude];
      rxRouteController.value = targetPos;
      return;
    }

    List<LatLng> waypoints = [];
    waypoints.add(startPos);

    bool hasPolyline = mapUtils.coordinates.isNotEmpty;
    int carIndex = -1;
    int targetIndex = -1;

    if (hasPolyline) {
      // Find segment index for current car marker and target location
      for (int tol = 10; tol <= 60; tol += 10) {
        if (carIndex == -1) {
          carIndex = mapUtils.isLocationOnPath(startPos, tol.toDouble(), mapUtils.coordinates);
        }
        if (targetIndex == -1) {
          targetIndex = mapUtils.isLocationOnPath(targetPos, tol.toDouble(), mapUtils.coordinates);
        }
        if (carIndex != -1 && targetIndex != -1) break;
      }

      debugPrint("_polylineMoverMarker: carIndex=$carIndex, targetIndex=$targetIndex, totalCoords=${mapUtils.coordinates.length}");

      if (targetIndex != -1) {
        if (carIndex != -1 && carIndex <= targetIndex) {
          // Move forward along the polyline path
          for (int i = carIndex + 1; i <= targetIndex; i++) {
            if (i < mapUtils.coordinates.length) {
              waypoints.add(mapUtils.coordinates[i]);
            }
          }
        } else if (carIndex != -1 && carIndex > targetIndex) {
          // Backward on polyline (if any)
          for (int i = carIndex; i > targetIndex; i--) {
            if (i < mapUtils.coordinates.length && i >= 0) {
              waypoints.add(mapUtils.coordinates[i]);
            }
          }
        }

        // Project target position onto the polyline
        LatLng nearestPoint = mapUtils.findNearestPoint(targetPos);
        if (nearestPoint.latitude != 0.0 && nearestPoint.longitude != 0.0) {
          waypoints.add(nearestPoint);
        } else {
          waypoints.add(targetPos);
        }

        // Clean up passed polyline points safely without mutating in-place during iteration
        if (carIndex > 0 && carIndex < mapUtils.coordinates.length) {
          mapUtils.coordinates = List<LatLng>.from(mapUtils.coordinates.sublist(carIndex));
          polylines = mapUtils.removeOldPointsOnPolyLine(mapUtils.coordinates);
        }
      } else {
        waypoints.add(targetPos);
      }
    } else {
      waypoints.add(targetPos);
    }

    // Filter duplicate / negligible distance waypoints
    List<LatLng> cleanWaypoints = [];
    for (var pt in waypoints) {
      if (cleanWaypoints.isEmpty) {
        cleanWaypoints.add(pt);
      } else {
        double d = calculateDistanceByMeter(
          cleanWaypoints.last.latitude, cleanWaypoints.last.longitude,
          pt.latitude, pt.longitude,
        );
        if (d > 0.5) {
          cleanWaypoints.add(pt);
        }
      }
    }

    if (cleanWaypoints.length < 2) {
      cleanWaypoints.add(targetPos);
    }

    // Calculate segment distances and total distance
    List<double> segmentDistances = [];
    double totalDistance = 0.0;
    for (int i = 0; i < cleanWaypoints.length - 1; i++) {
      double segDist = calculateDistanceByMeter(
        cleanWaypoints[i].latitude, cleanWaypoints[i].longitude,
        cleanWaypoints[i + 1].latitude, cleanWaypoints[i + 1].longitude,
      );
      segmentDistances.add(segDist);
      totalDistance += segDist;
    }

    if (totalDistance < 1.0) {
      bearingBetween(startPos.latitude, startPos.longitude, targetPos.latitude, targetPos.longitude);
      if (markers[carMarker] != null) {
        markers[carMarker] = markers[carMarker]!.copyWith(
          rotationParam: rotationbearing,
          positionParam: targetPos,
        );
      }
      position = [targetPos.latitude, targetPos.longitude];
      rxRouteController.value = targetPos;
      return;
    }

    // Perform smooth multi-step animation across all waypoints
    for (int step = 1; step <= numDeltas; step++) {
      // Abort immediately if a newer location update started animating or app is paused
      if (currentAnimId != markerAnimationId || !isAppResume) {
        return;
      }

      double progress = step / numDeltas.toDouble();
      double currentDist = progress * totalDistance;

      double accumulated = 0.0;
      LatLng pointAtDist = targetPos;
      double segmentBearing = rotationbearing;

      for (int i = 0; i < segmentDistances.length; i++) {
        double segLen = segmentDistances[i];
        if (accumulated + segLen >= currentDist || i == segmentDistances.length - 1) {
          double segProgress = segLen > 0.0001
              ? ((currentDist - accumulated) / segLen).clamp(0.0, 1.0)
              : 1.0;
          double lat = cleanWaypoints[i].latitude +
              (cleanWaypoints[i + 1].latitude - cleanWaypoints[i].latitude) * segProgress;
          double lng = cleanWaypoints[i].longitude +
              (cleanWaypoints[i + 1].longitude - cleanWaypoints[i].longitude) * segProgress;
          pointAtDist = LatLng(lat, lng);

          bearingBetween(
            cleanWaypoints[i].latitude,
            cleanWaypoints[i].longitude,
            cleanWaypoints[i + 1].latitude,
            cleanWaypoints[i + 1].longitude,
          );
          segmentBearing = rotationbearing;
          break;
        }
        accumulated += segLen;
      }

      if (markers[carMarker] != null) {
        markers[carMarker] = markers[carMarker]!.copyWith(
          positionParam: pointAtDist,
          rotationParam: segmentBearing,
        );
        rxRouteController.refresh();
      }

      await Future.delayed(Duration(milliseconds: delay));
    }

    // Ensure final target position and bearing on completion
    if (currentAnimId == markerAnimationId && markers[carMarker] != null) {
      markers[carMarker] = markers[carMarker]!.copyWith(
        positionParam: targetPos,
        rotationParam: rotationbearing,
      );
      position = [targetPos.latitude, targetPos.longitude];
      rxRouteController.value = targetPos;
    }
  }

  Future<void> moveMarker([bool isforceNearestPoint = false]) async {
    // Retained for backward compatibility
    _polylineMoverMarker();
  }

  double calculateDistanceByMeter(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 1000 * 12742 * asin(sqrt(a));
  }

  updateGoogleMap() {
    rxRouteController.refresh();
  }


  void setMarkerprocess() {
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_setMarkerprocess ${point} --- ${globals.isActive} --- ${zoomLevel}-- ${mapLocation} -- ${mapController}');
    setDriverStatus(globals.isActive);
    markers.remove(carMarker);
    carMarker = MarkerId("marker_id_1");
    Marker locMarker = Marker(
        markerId: carMarker,
        position: mapLocation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        icon: globals.categoryImage!);
    markers[carMarker] = locMarker;

    if (mapController != null) {
        if (zoomLevel == 0.0) {
          zoomLevel = 15.0;
        }
        debugPrint("camera animate 4: $zoomLevel");
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(mapLocation.latitude, mapLocation.longitude),
            zoom: zoomLevel,
          ),
        ));

    }
    rxRouteController.value = mapLocation;

    mapUtils = MapUtils();

    position = [mapLocation.latitude, mapLocation.longitude];
    graphQlObject.getGraphQlClientWithHeader();
  }

  trackLocation({bool isBelow3Meter = false}) {
    LatLng location = mapLocation;
    updateCurrentLoc(mapLocation).then((value) {
      if (value != null) {
        if (value.isNotEmpty) {
          if (value == "timeout") {
            App().toast.show(
              context: homeViewState.scaffoldContext ?? scaffoldContext?? Get.context!,
              message: session_timeout_err.tr,
            );
            setLogout(scaffoldContext!);
          } else {
            showInSnackBar(value);
          }
        } else {
          if (isDriverAccept() && !isBelow3Meter) {
            getTripStatusOnly().then((value) {
              if (isDriverAccept()) {
                sendDriverLocation(location);
              }
            });
          }
        }
      }
    });
  }

}