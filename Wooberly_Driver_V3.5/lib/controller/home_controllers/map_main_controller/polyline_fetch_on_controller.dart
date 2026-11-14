part of 'map_main_controller.dart';

extension PolylineFetchOnController on MapMainController {
  updateDriverPath(bool strictDrawPoly, dynamic mapLoc, {bool force = false}) async {
    try {
      double nextLat = 0.0;
      double nextLng = 0.0;
      final point = StackTrace.current.toString().split('\n')[1];
    //  print('test9_setLogout ${point} --- ');
    //   for (int i = 0; i < locationData.length; i++) {
    //     debugPrint("locationname: ${locationData[i].location}");
    //   }
      for (int i = 0; i < locationData.length; i++) {
        if (locationData[i].locationStatus == "pending") {
          nextLat = locationData[i].latLng.latitude;
          nextLng = locationData[i].latLng.longitude;
          updateShowLocationController(locationData[i].location);
          break;
        }
      }
      if (!strictDrawPoly) {
        if (tripStatus.compareTo("approved") == 0 ||
            tripStatus.compareTo("locationReached") == 0) {
          setCarMarker(mapLocation, LatLng(pickLat, pickLon), true);
        } else if (tripStatus.compareTo("started") == 0) {
          setCarMarker(mapLocation, LatLng(nextLat, nextLng), true);
        }
      }


      int pathIndex = mapUtils.isLocationOnPath(mapLocation, globals.polylineDrawDistance);
      if(polylineoldLocation.latitude !=0.0 && polylineoldLocation.longitude !=0.0 && mapUtils.coordinates.isNotEmpty) {
        var distance = mapUtils.computeDistanceBetween(polylineoldLocation, mapLocation);
        if(distance < globals.polylineDrawDistance)
          pathIndex = 1;
      }

      if(tripStatus !=null && tripStatus.isNotEmpty)
      polylineoldLocation = mapLocation;

      markerMoveIteration = 0;
      _isNewPolylines = false;
      if ((pathIndex < 0) || strictDrawPoly || force) {
        if (
        tripStatus.compareTo("approved") == 0 ||
            tripStatus.compareTo("started") == 0 ||
            tripStatus.compareTo("locationReached") == 0) {
          await drawDestRoute(
              mapLoc ?? mapLocation,
              tripStatus == 'started'
                  ? LatLng(nextLat, nextLng)
                  : LatLng(pickLat, pickLon),
              false,
              "updatepath",
              force);
        }
      } else {
        mapUtils.MarkerMovementcoordinates.clear();
      }
      _removeMarker();
    } catch (e) {
    }
  }


  Future<void> drawDestRoute(dynamic mapLoc, LatLng desLoc,
      [isupdatemarker, pathupdate, bool force = false]) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_drawDestRoute ${point} --- ');

    // We allow fetching if either no request is pending OR the destination/status has changed OR it's a forced fetch.
    bool shouldFetch = !mapUtils.isPolylineResultPending || 
                       mapUtils.destinationLoc != desLoc ||
        force;

    if (shouldFetch && isAppResume) {
      if (isupdatemarker == null) isupdatemarker = true;
      if (pathupdate == null) pathupdate = '';

      for (int i = 0; i < locationData.length; i++) {
        if (locationData[i].locationStatus == "pending") {
          desLoc = locationData[i].latLng;
          updateShowLocationController(locationData[i].location);
          break;
        }
      }

      if (mapUtils == null) mapUtils = MapUtils();

      String oldtripstatus = tripStatus;

      polyinewaypoint = markers != null &&
              markers[carMarker] != null &&
              markers != <MarkerId, Marker>{} &&
              mapLoc != null
          ? mapLoc
          : LatLng(0.0, 0.0);

      // Determine the origin for polyline fetching
      LatLng origin = (markers != null && markers[carMarker] != null && 
                       markers[carMarker]!.position != LatLng(0.0, 0.0))
          ? markers[carMarker]!.position
          : (mapLocation != null && mapLocation != LatLng(0.0, 0.0))
              ? mapLocation
              : mapLoc ?? LatLng(0.0, 0.0);

      Polyline? polyline = await mapUtils.getPolylinesWithLocation(
          origin,
          desLoc,
          waypoint: polyinewaypoint,
          force: force);

      // Verify if the status is still active for drawing
      bool isStatusActive = tripStatus == "approved" ||
                            tripStatus == "locationReached" ||
                            tripStatus == "started";

      if (isStatusActive) {
        if (isAppResume) {
          _isNewPolylines = true;
          coordinatecurrentIndex = null;
          if(polyline != null) {
            polylines = polyline;
            polylineoldLocation = LatLng(0.0, 0.0);
            // Only update markers AFTER polyline is ready or if strictly requested
            if (isupdatemarker) markers.remove(_endingMarkerId);
            setCarMarker(mapLocation, desLoc, isupdatemarker);
          }


          rxRouteController.refresh();
          // Safety net: force a GetBuilder rebuild so the GoogleMap widget
          // picks up the new polylines even if the stream-based mapRebuild
          // was throttled by a prior state change.
          change(rxVariable: rxUpdatePaddingController, value: rxUpdatePaddingController.value);
        } else {
          mapUtils.originLoc = LatLng(0.0, 0.0);
          mapUtils.destinationLoc = LatLng(0.0, 0.0);
        }
      } else if (!isStatusActive) {
        // Only clear if status is no longer one that requires a polyline
        polylines = Polyline(polylineId: PolylineId(''));
        mapUtils.coordinates.clear();
        rxRouteController.value = mapLocation;
      }
    }
  }

  String distance(
      double lat1, double lon1, double lat2, double lon2, String unit) {
    double theta = lon1 - lon2;
    double dist = sin(deg2rad(lat1)) * sin(deg2rad(lat2)) +
        cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * cos(deg2rad(theta));
    dist = acos(dist);
    dist = rad2deg(dist);
    dist = dist * 60 * 1.1515;
    if (unit == 'km') {
      dist = dist * 1.609344;
    } else if (unit == 'N') {
      dist = dist * 0.8684;
    }
    return dist.toStringAsFixed(2);
  }

  double deg2rad(double deg) {
    return (deg * pi / 180.0);
  }

  double rad2deg(double rad) {
    return (rad * 180.0 / pi);
  }
}