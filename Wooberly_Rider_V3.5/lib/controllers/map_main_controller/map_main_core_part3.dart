part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';


extension MapMainCorePart3 on MapMainController{
  Future<String?> getUserLocationName() async {
    if(lastKnownLocation != null && lastKnownLocation != LatLng(0.0, 0.0)) {
      try {
        var first;
        first = await getAddress();
        if (_initialAddress.isEmpty)
          _initialAddress = first;
        return first;
      } on Exception catch (e) {
        bool internetConnect = await checkConnectivity();

        if (internetConnect != null && internetConnect) {

        } else {
          toast.show(
            context: Get.context!,
            message: 'offline_text'.tr,
            duration: new Duration(seconds: 5),
          );
        }
        return "";
      }
    }
  }

  Future<String> getAddress() async {
    if(lastKnownLocation.latitude==globals.userLat &&lastKnownLocation.longitude==globals.userLon && globals.currentLocation.value.isNotEmpty)
      return globals.currentLocation.value;
    if(lastKnownLocation.latitude !=0.0 && lastKnownLocation.longitude !=0.0) {
      List<Placemark> placemarks = await geocoding.Geocoding().placemarkFromCoordinates(lastKnownLocation.latitude, lastKnownLocation.longitude,);

      return getAddressFromPlaceMark(placemarks[0]);
    }
    return "";

  }

  Future<void> drawRouteFromDriver() async {
    AppLifecycleState? currentState = SchedulerBinding.instance.lifecycleState;
    print("Current App Lifecycle State: 3 $currentState");
    if(currentState == AppLifecycleState.resumed || isInitialGetTripStatusLoading) {
      if(mapUtils != null) mapUtils!.isPolylineResultPending = false;
    }
    if(mapUtils?.isPolylineResultPending == false) {
      markersMap.clear();

      debugPrint("pickuplocation123: ${locationData.first.latLng} --- ${locationData.last.latLng}${currentState}");
      List<LatLng> latlnglist = [
        getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!,
        globals.tripStatus == "started" ? locationData.last.latLng! : locationData.first.latLng!,];

      if (isUserInTrip) {
        coordinatecurrentIndex = null;
        debugPrint("widget.mapMainController.polyLines: 3 ${polyLines.points} --- ${locationData} --- ${currentState} -- ${isInitialGetTripStatusLoading} -- ${latlnglist}");
        if ( locationData.isNotEmpty && polyLines != Polyline(polylineId: PolylineId(''))) {
          polyLines = Polyline(polylineId: PolylineId(''));
        }
      }
      if(currentState == AppLifecycleState.resumed || isInitialGetTripStatusLoading)
        polyLines = await mapUtils?.getPolylinesWithLocation(latlnglist, bookingId, ismutistopvia: ismultistopvia, ) ?? Polyline(polylineId: PolylineId(''));
      mapLoadingController(false);
      debugPrint('polyLines after start: ${polyLines}');

      if (polyLines != Polyline(polylineId: PolylineId('')) || (latlnglist.length==2 && latlnglist.first.latitude ==latlnglist.last.latitude && latlnglist.first.longitude ==latlnglist.last.longitude)) {
        List<LatLng> latLngData = [];
        List<LocationData> data = locationData.map((item) =>
        new LocationData.clone(item)).toList();
        data.forEach((element) {
          latLngData.add(element.latLng!);
        });
        if (globals.tripStatus == "approved" || globals.tripStatus == "locationReached")
          setMarkers(latLngData);

        updateGoogleMap();
      }
    }
  }

  void updateMarker(LatLng driverLoc, double rotation ,LatLng end) async {
    await mapControllerCompleter.future;
    if(mapController!=null) {
      mapUtils?.MarkerMovementcoordinates.clear();
      int  pathIndex =   mapUtils?.isLocationOnPath( driverLoc,  globals.polylineDrawDistance) ?? 0;
      _isNewPolylines = false;

      if ( pathIndex < 0) {
          await drawDestRoute(driverLoc, end);
      }


      if(markersMap.isEmpty) {
        List<LatLng> tempLatLng = [];
        if (globals.tripStatus == "started") {
          tempLatLng.add(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!);
          List<LocationData> data = locationData.map((item) =>
          new LocationData.clone(item)).toList();

          for (int i = 1; i < data.length; i++) {
            if (data[i].fieldType != 'disabled')
              tempLatLng.add(data[i].latLng!);
          }
        } else {
          tempLatLng.add(locationData.first.latLng!);
          tempLatLng.add(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!);
        }
        await setMarkers(tempLatLng);
      }

      markerMoveIteration =0;
      delay = 33;
      int intervalSec = globals.LocationFetchInterval;
      if (intervalSec <= 0) intervalSec = 5;
      int totalDurationMs = intervalSec * 1000;
      numDeltas = (totalDurationMs / delay).round();
      if (numDeltas < 10) numDeltas = 10;
      double  distancemarkerlocation = 0.0;

      if (mapUtils == null) mapUtils = MapUtils();
      LatLng driverpos = App().getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!;
      if (markersMap[driverVehicleId] != null) {
        LatLng driverpos = getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!;
        distancemarkerlocation= calculateDistanceByMeter(
            markersMap[driverVehicleId!]!.position.latitude,
            markersMap[driverVehicleId!]!.position.longitude,
            driverpos.latitude, driverpos.longitude);
      }
      if (distancemarkerlocation > 2.0) {
        _polylineMoverMarker();
      } else {
        toForceCurrentLocation = 0;
        oldCoordinate = LatLng(0.0, 0.0);
        if (markersMap[driverVehicleId] != null) {
          markersMap[driverVehicleId!] = markersMap[driverVehicleId!]!.copyWith(
            rotationParam: bearing,
            positionParam: driverpos,
          );
        }
        position = [driverpos.latitude, driverpos.longitude];
        routeController.add(driverpos);
      }
      

      mapController?.getZoomLevel().then((value) {
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target:driverpos,
            zoom: value,
          ),
        ));
      });

    }
  }
  _polylineMoverMarker() async {
    LatLng mapLocation = App().getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!;
    final int currentAnimId = ++markerAnimationId;
    LatLng startPos = (driverVehicleId != null ? markersMap[driverVehicleId]?.position : null) ?? mapLocation;
    LatLng targetPos = mapLocation;

    double directDistance = calculateDistanceByMeter(
      startPos.latitude, startPos.longitude,
      targetPos.latitude, targetPos.longitude,
    );

    // If jump/teleport is very large (> 400m), snap directly to target
    if (directDistance > 400.0) {
      bearingBetween(startPos.latitude, startPos.longitude, targetPos.latitude, targetPos.longitude);
      if (driverVehicleId != null && markersMap[driverVehicleId] != null) {
        markersMap[driverVehicleId!] = markersMap[driverVehicleId!]!.copyWith(
          rotationParam: bearing,
          positionParam: targetPos,
        );
      }
      position = [targetPos.latitude, targetPos.longitude];
      routeController.add(targetPos);
      return;
    }

    List<LatLng> waypoints = [];
    waypoints.add(startPos);

    final utils = mapUtils;
    bool hasPolyline = utils != null && utils.coordinates.isNotEmpty;
    int carIndex = -1;
    int targetIndex = -1;

    if (hasPolyline && utils != null) {
      // Find segment index for current car marker and target location
      for (int tol = 10; tol <= 60; tol += 10) {
        if (carIndex == -1) {
          carIndex = utils.isLocationOnPath(startPos, tol.toDouble(), utils.coordinates);
        }
        if (targetIndex == -1) {
          targetIndex = utils.isLocationOnPath(targetPos, tol.toDouble(), utils.coordinates);
        }
        if (carIndex != -1 && targetIndex != -1) break;
      }

      debugPrint("_polylineMoverMarker: carIndex=$carIndex, targetIndex=$targetIndex, totalCoords=${utils.coordinates.length}");

      if (targetIndex != -1) {
        if (carIndex != -1 && carIndex <= targetIndex) {
          // Move forward along the polyline path
          for (int i = carIndex + 1; i <= targetIndex; i++) {
            if (i < utils.coordinates.length) {
              waypoints.add(utils.coordinates[i]);
            }
          }
        } else if (carIndex != -1 && carIndex > targetIndex) {
          // Backward on polyline (if any)
          for (int i = carIndex; i > targetIndex; i--) {
            if (i < utils.coordinates.length && i >= 0) {
              waypoints.add(utils.coordinates[i]);
            }
          }
        }

        // Project target position onto the polyline
        LatLng nearestPoint = utils.findNearestPoint(targetPos);
        if (nearestPoint.latitude != 0.0 && nearestPoint.longitude != 0.0) {
          waypoints.add(nearestPoint);
        } else {
          waypoints.add(targetPos);
        }

        // Clean up passed polyline points safely without mutating in-place during iteration
        if (carIndex > 0 && carIndex < utils.coordinates.length) {
          utils.coordinates = List<LatLng>.from(utils.coordinates.sublist(carIndex));
          polyLines = utils.removeOldPointsOnPolyLine(utils.coordinates);
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
      if (driverVehicleId != null && markersMap[driverVehicleId] != null) {
        markersMap[driverVehicleId!] = markersMap[driverVehicleId!]!.copyWith(
          rotationParam: bearing,
          positionParam: targetPos,
        );
      }
      position = [targetPos.latitude, targetPos.longitude];
      routeController.add(targetPos);
      return;
    }

    // Perform smooth multi-step animation across all waypoints
    for (int step = 1; step <= numDeltas; step++) {
      // Abort immediately if a newer location update started animating or app is paused
      AppLifecycleState? currentLifecycle = SchedulerBinding.instance.lifecycleState;
      if (currentAnimId != markerAnimationId || currentLifecycle != AppLifecycleState.resumed) {
        return;
      }

      double progress = step / numDeltas.toDouble();
      double currentDist = progress * totalDistance;

      double accumulated = 0.0;
      LatLng pointAtDist = targetPos;
      double segmentBearing = bearing;

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
          segmentBearing = bearing;
          break;
        }
        accumulated += segLen;
      }

      if (driverVehicleId != null && markersMap[driverVehicleId] != null) {
        markersMap[driverVehicleId!] = markersMap[driverVehicleId!]!.copyWith(
          positionParam: pointAtDist,
          rotationParam: segmentBearing,
        );
        routeController.add(pointAtDist);
      }

      await Future.delayed(Duration(milliseconds: delay));
    }

    // Ensure final target position and bearing on completion
    if (currentAnimId == markerAnimationId && driverVehicleId != null && markersMap[driverVehicleId] != null) {
      markersMap[driverVehicleId!] = markersMap[driverVehicleId!]!.copyWith(
        positionParam: targetPos,
        rotationParam: bearing,
      );
      position = [targetPos.latitude, targetPos.longitude];

      routeController.add(targetPos);
    }
  }
}