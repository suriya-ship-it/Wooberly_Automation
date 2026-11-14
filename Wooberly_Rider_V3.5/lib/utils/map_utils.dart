import 'dart:core';
import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:vector_math/vector_math.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/widgets/polyline_points/network_util.dart';

class MapUtils {
  int _polylineCount = 1;
   Polyline? _polylines;

  LatLng? initLoc;
  LatLng? endLoc;
  List<LatLng> coordinates = [];
  List<LatLng> MarkerMovementcoordinates = [];
  double degrees2Radians = math.pi / 180.0;
  bool isPolylineResultPending = false;

  List<List<PatternItem>> patterns = <List<PatternItem>>[
    <PatternItem>[],
    <PatternItem>[PatternItem.dash(30.0), PatternItem.gap(20.0)],
    <PatternItem>[PatternItem.dot, PatternItem.gap(10.0)],
    <PatternItem>[
      PatternItem.dash(30.0),
      PatternItem.gap(20.0),
      PatternItem.dot,
      PatternItem.gap(20.0)
    ],
  ];

  Future<Polyline?> getPolylinesWithLocation(List<LatLng> locations, int bookingId,{bool? isOldDriverIncluded,  bool? ismutistopvia }) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_getPolylinesWithLocation ${point} --- ${locations} ');
    if (locations.isEmpty || (locations.length ==2 && locations.first.latitude == locations.last.latitude && locations.first.longitude == locations.last.longitude))
      return _polylines;

    List<LatLng> wayPoints = [];
    for (int i = 1; i < locations.length - 1; i++) {
      LatLng polylinewaypoint = LatLng(
           locations[i].latitude,locations[i].longitude);
      wayPoints.add(polylinewaypoint);
    }

    bool overQuotaLimitExceeded = false;
      isPolylineResultPending = true;

      // Check preference first before calling API
      AppPreferences prefs = AppPreferences();
      Map<int, List<LatLng>>? cachedPolylinePoints = prefs.getCachedRoute(locations);
      Map<int, List<LatLng>> polylinePoints = {};
    bool isCacheValid = false;

      debugPrint("getPolylinesWithLocation: cachedPolylinePoints: ${cachedPolylinePoints}");
      if (cachedPolylinePoints != null && cachedPolylinePoints.isNotEmpty) {
        debugPrint("getPolylinesWithLocation: Route retrieved from preference storage (${cachedPolylinePoints.length} legs)!");
        List<LatLng> cachedAllPoints = [];
        cachedPolylinePoints.forEach((key, points) {
          cachedAllPoints.addAll(points);
        });

        debugPrint("AppPreferences: cachedlenth  ${cachedAllPoints.length}");

        if (cachedAllPoints.isNotEmpty) {
          LatLng? cachedDest = prefs.getCachedRouteDestination(locations);
          bool isSameDestination = false;

          if (cachedDest != null) {
            isSameDestination = (locations.last.latitude == cachedDest.latitude &&
                locations.last.longitude == cachedDest.longitude) ||
                (locations.last.latitude.toStringAsFixed(4) == cachedDest.latitude.toStringAsFixed(4) &&
                    locations.last.longitude.toStringAsFixed(4) == cachedDest.longitude.toStringAsFixed(4));
          } else {
            LatLng lastPoint = cachedAllPoints.last;
            isSameDestination = (locations.last.latitude == lastPoint.latitude &&
                locations.last.longitude == lastPoint.longitude) ||
                (locations.last.latitude.toStringAsFixed(4) == lastPoint.latitude.toStringAsFixed(4) &&
                    locations.last.longitude.toStringAsFixed(4) == lastPoint.longitude.toStringAsFixed(4)) ||
                (computeDistanceBetween(locations.last, lastPoint) <= 50);
          }

          LatLng firstPoint = cachedAllPoints.first;
          num originDistance = computeDistanceBetween(locations.first, firstPoint);

          debugPrint("AppPreferences: Cache check - sameDest: $isSameDestination, originDistance: ${originDistance.toStringAsFixed(2)}m, drawDistLimit: ${globals.polylineDrawDistance}m --- dest: ${locations.last} vs cachedDest: $cachedDest --- origin: ${locations.first} vs firstPoint: $firstPoint");

          if (isSameDestination && originDistance <= globals.polylineDrawDistance) {
            isCacheValid = true;
            polylinePoints = cachedPolylinePoints;
            debugPrint("AppPreferences: Reusing polyline from preference without network call");
          }
        }
      }
      if(!isCacheValid) {
        debugPrint("getPolylinesWithLocation: Route not found in preference storage. Fetching from API...");
        polylinePoints = await NetworkUtil().getRouteBetweenCoordinates(
            bookingId: bookingId,
            ismutistopvia: ismutistopvia ?? false,
            wayPoints: wayPoints,
            originLocation: LatLng(locations[0].latitude, locations[0].longitude),
            destinationLocation: LatLng(locations[locations.length - 1].latitude, locations[locations.length - 1].longitude),
            googleMapKey: globals.MAP_KEY);
        debugPrint("getPolylinesWithLocation: cachedPolylinePoints: save1 ${locations}");
        if (polylinePoints.isNotEmpty) {
          prefs.saveCachedRoute(locations, polylinePoints);
        }
      }

      coordinates.clear();

      if (polylinePoints.isNotEmpty) {
        coordinates.clear();
        MarkerMovementcoordinates.clear();
        getMarkerMovePointsPolylines(locations[0], polylinePoints,isOldDriverIncluded);
        debugPrint("getMarkerMovePointsPolylines end -- coordinates: ${coordinates}");
      } else {
        overQuotaLimitExceeded = true;
      }
      isPolylineResultPending = false;


    debugPrint("polylinePoints -- coordinates: ${coordinates} --- ${overQuotaLimitExceeded}");
    if (!overQuotaLimitExceeded) {
      if (coordinates != null && coordinates.isNotEmpty) {
        initLoc = coordinates[0];
        endLoc = coordinates[coordinates.length - 1];
        _polylines = addPolyline(coordinates);
        debugPrint("polylinePoints -- _polylines: ${_polylines?.points}");
        return _polylines;
      }
    }

    return _polylines;
  }

  Polyline addPolyline(List<LatLng> coordinates) {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_addPolyline ${point} --- ${coordinates} ');
    PolylineId id = PolylineId('polyline${_polylineCount}');
    Polyline polyline = Polyline(
        polylineId: id,
        patterns: patterns[0],
        points: coordinates,
        color: AppColors.BLACK,
        width: 4,
        onTap: () {});
    return polyline;
  }
  Polyline removeOldPointsOnPolyLine(List<LatLng> coordinates){
    _polylineCount++;
    return addPolyline(coordinates);
  }

  Polyline? updatePolylineColor() {
    if (coordinates.isNotEmpty) {
      _polylineCount++;
      _polylines = addPolyline(coordinates);
      return _polylines;
    }
    return _polylines;
  }

  LatLng? pointOnPolyline;

  LatLng findNearestPoint(LatLng test) {
    double NearrestPointdistance = -1,NearrestPointdistance1;
    LatLng minimumDistancePoint = test, minimumDistancePoint1;
    List<LatLng> coords =coordinates ;



    if (test == null || coords == null) {
      return minimumDistancePoint;
    }

    for (int i = 0; i < coords.length; i++) {
      LatLng point = coords[i];

      int segmentPoint = i + 1;

      if (segmentPoint >= coords.length) {
        segmentPoint = 0;
      }

      double currentDistance = pointOnLine(test, point, coords[segmentPoint]).toDouble();
      if (NearrestPointdistance == -1 || (currentDistance < NearrestPointdistance)) {
        NearrestPointdistance = currentDistance;
        pointOnLine(test, point, coords[segmentPoint]);
        if (pointOnPolyline?.latitude != 0.0 && pointOnPolyline?.longitude != 0.0)
          minimumDistancePoint = pointOnPolyline!;
      }
    }

    coords = MarkerMovementcoordinates;
    if (test == null || coords == null) {
      return minimumDistancePoint;
    }

    minimumDistancePoint1 = minimumDistancePoint;
    NearrestPointdistance1 = NearrestPointdistance;

    for (int i = 0; i < coords.length; i++) {
      LatLng point = coords[i];

      int segmentPoint = i + 1;

      if (segmentPoint >= coords.length) {
        segmentPoint = 0;
      }

      double currentDistance = pointOnLine(test, point, coords[segmentPoint]).toDouble();
      if (NearrestPointdistance == -1 || (currentDistance < NearrestPointdistance)) {
        NearrestPointdistance = currentDistance;
        pointOnLine(test, point, coords[segmentPoint]);
        if (pointOnPolyline?.latitude != 0.0 && pointOnPolyline?.longitude != 0.0)
          minimumDistancePoint = pointOnPolyline!;
      }
    }

    if(NearrestPointdistance1 < NearrestPointdistance)
      return minimumDistancePoint1;


    return minimumDistancePoint;
  }
  void getMarkerMovePointsPolylines(
      LatLng originLocation,
      Map<int, List<LatLng>> polylinePoints,
      bool? isOldDriverIncluded,
      ) {
    isOldDriverIncluded ??= false;

    coordinates.clear();

    for (int i = 0; i < polylinePoints.length; i++) {
      final points = polylinePoints[i] ?? [];

      if (coordinates.isNotEmpty && points.isNotEmpty) {
        points.removeAt(0);
      }

      coordinates.addAll(points);
    }
    debugPrint("getMarkerMovePointsPolylines -- coordinates: ${coordinates} --- ${MarkerMovementcoordinates}");

    if (isOldDriverIncluded && polylinePoints.length > 1) {
      MarkerMovementcoordinates.clear();
      MarkerMovementcoordinates.addAll(polylinePoints[0] ?? []);
    }
  }

  double toRadians(num deg) => deg * (math.pi / 180.0);

  num pointOnLine(final LatLng p, final LatLng start, final LatLng end) {
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      pointOnPolyline = start;
      return computeDistanceBetween(end, p);
    }

    final s0lat = toRadians(p.latitude);
    final s0lng = toRadians(p.longitude);
    final s1lat = toRadians(start.latitude);
    final s1lng = toRadians(start.longitude);
    final s2lat = toRadians(end.latitude);
    final s2lng = toRadians(end.longitude);

    final s2s1lat = s2lat - s1lat;
    final s2s1lng = s2lng - s1lng;
    final u = ((s0lat - s1lat) * s2s1lat + (s0lng - s1lng) * s2s1lng) /
        (s2s1lat * s2s1lat + s2s1lng * s2s1lng);
    if (u <= 0) {
      pointOnPolyline = start;
      return computeDistanceBetween(p, start);
    }
    if (u >= 1) {
      pointOnPolyline = end;
      return computeDistanceBetween(p, end);
    }
    final su = LatLng(start.latitude + u * (end.latitude - start.latitude),
        start.longitude + u * (end.longitude - start.longitude));
    double angle = computeDistanceBetween(p, su).toDouble();

    pointOnPolyline = su;

    return angle;
  }


  num distanceRadians(num lat1, num lng1, num lat2, num lng2) =>
      arcHav(havDistance(lat1, lat2, lng1 - lng2));

  num arcHav(num x) => 2 * math.asin(math.sqrt(x));

  num havDistance(num lat1, num lat2, num dLng) => hav(lat1 - lat2) + hav(dLng) * math.cos(lat1) * math.cos(lat2);

  num hav(num x) => math.sin(x * 0.5) * math.sin(x * 0.5);

  num computeAngleBetween(LatLng from, LatLng to) => distanceRadians(
      toRadians(from.latitude),
      toRadians(from.longitude),
      toRadians(to.latitude),
      toRadians(to.longitude));

  num computeDistanceBetween(LatLng from, LatLng to) => computeAngleBetween(from, to) * 6371009.0;

  int isLocationOnPath(LatLng point, double toleranceEarth,[List<LatLng>? latLngcoordinates]) {
    int pathIndex =
    _locationIndexOnEdgeOrPath(point, latLngcoordinates?? coordinates, toleranceEarth);
    return pathIndex;
  }

  int _locationIndexOnEdgeOrPath(LatLng point, List<LatLng> poly, double toleranceEarth) {
    if (poly == null) return -1;
    int size = poly.length;
    if (poly != null && size == 0) {
      return -1;
    }

    double tolerance = toleranceEarth / 6371009;
    double havTolerance = _hav(tolerance);
    double lat3 = radians(point.latitude);
    double lng3 = radians(point.longitude);
    LatLng prev = poly[0];
    double lat1 = radians(prev.latitude);
    double lng1 = radians(prev.longitude);
    int idx = 0;

    for (var point2 in poly) {
      double lat2 = radians(point2.latitude);
      double lng2 = radians(point2.longitude);
      if (_isOnSegmentGC(lat1, lng1, lat2, lng2, lat3, lng3, havTolerance)) {
        return math.max(0, idx - 1);
      }
      lat1 = lat2;
      lng1 = lng2;
      idx++;
    }
    return -1;
  }

  bool _isOnSegmentGC(double lat1, double lng1, double lat2, double lng2, double lat3, double lng3, double havTolerance) {
    double havDist13 = _havDistance(lat1, lat3, lng1 - lng3);
    if (havDist13 <= havTolerance) {
      return true;
    }
    double havDist23 = _havDistance(lat2, lat3, lng2 - lng3);
    if (havDist23 <= havTolerance) {
      return true;
    }
    double sinBearing = _sinDeltaBearing(lat1, lng1, lat2, lng2, lat3, lng3);
    double sinDist13 = _sinFromHav(havDist13);
    double havCrossTrack = _havFromSin(sinDist13 * sinBearing);
    if (havCrossTrack > havTolerance) {
      return false;
    }
    double havDist12 = _havDistance(lat1, lat2, lng1 - lng2);
    double term = havDist12 + havCrossTrack * (1 - 2 * havDist12);
    if (havDist13 > term || havDist23 > term) {
      return false;
    }
    if (havDist12 < 0.74) {
      return true;
    }
    double cosCrossTrack = 1 - 2 * havCrossTrack;
    double havAlongTrack13 = (havDist13 - havCrossTrack) / cosCrossTrack;
    double havAlongTrack23 = (havDist23 - havCrossTrack) / cosCrossTrack;
    double sinSumAlongTrack = _sinSumFromHav(havAlongTrack13, havAlongTrack23);
    return sinSumAlongTrack > 0;
  }

  double _sinSumFromHav(double x, double y) {
    double a = math.sqrt(x * (1 - x));
    double b = math.sqrt(y * (1 - y));
    return 2 * (a + b - 2 * (a * y + b * x));
  }

  double _havFromSin(double x) {
    double x2 = x * x;
    return x2 / (1 + math.sqrt(1 - x2)) * .5;
  }

  double _sinFromHav(double h) {
    return 2 * math.sqrt(h * (1 - h));
  }

  double _sinDeltaBearing(double lat1, double lng1, double lat2, double lng2, double lat3, double lng3) {
    double sinLat1 = math.sin(lat1);
    double cosLat2 = math.cos(lat2);
    double cosLat3 = math.cos(lat3);
    double lat31 = lat3 - lat1;
    double lng31 = lng3 - lng1;
    double lat21 = lat2 - lat1;
    double lng21 = lng2 - lng1;
    double a = math.sin(lng31) * cosLat3;
    double c = math.sin(lng21) * cosLat2;
    double b = math.sin(lat31) + 2 * sinLat1 * cosLat3 * _hav(lng31);
    double d = math.sin(lat21) + 2 * sinLat1 * cosLat2 * _hav(lng21);
    double denom = (a * a + b * b) * (c * c + d * d);
    return denom <= 0 ? 1 : (a * d - b * c) / math.sqrt(denom);
  }

  double _havDistance(double lat1, double lat2, double dLng) {
    return _hav(lat1 - lat2) + _hav(dLng) * math.cos(lat1) * math.cos(lat2);
  }

  double _hav(double x) {
    double sinHalf = math.sin(x * 0.5);
    return sinHalf * sinHalf;
  }


  double radians(double degrees) => degrees * degrees2Radians;
}

class LocationData {
  int? id;
  LatLng? latLng;
  String? location;
  String fieldType;
  String locationStatus;
  String locationType;
  String locationDistanceType;

  LocationData(
      [this.latLng,
      this.location,
      this.fieldType = "",
      this.id = 0,
      this.locationStatus = "",
      this.locationType = "",
      this.locationDistanceType = "",]) {}

  LocationData.clone(LocationData source)
      : this.latLng = source.latLng,
        this.location = source.location,
        this.fieldType = source.fieldType,
        this.id = source.id,
        this.locationStatus = source.locationStatus,
        this.locationType = source.locationType,
        this.locationDistanceType = source.locationDistanceType;


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationData) return false;
    return id == other.id &&
        latLng?.latitude == other.latLng?.latitude &&
        latLng?.longitude == other.latLng?.longitude &&
        location == other.location &&
        fieldType == other.fieldType &&
        locationStatus == other.locationStatus &&
        locationType == other.locationType &&
        locationDistanceType == other.locationDistanceType;
  }

  @override
  int get hashCode => Object.hash(
    id,
    latLng?.latitude,
    latLng?.longitude,
    location,
    fieldType,
    locationStatus,
    locationType,
    locationDistanceType,
  );
}