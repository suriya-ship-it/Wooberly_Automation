part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension UtilsMapMainViewModel on MapMainController {
  LatLngBounds getBounds(List<LatLng> locations) {
    double x0 = 0;
    double x1 = 0;
    double y0 = 0;
    double y1 = 0;

    for (LatLng latLng in locations) {
      if (x0 == 0) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }

    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  double calculateDistanceByMeter(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 1000*12742 * asin(sqrt(a));
  }

  double deg2rad(double deg) {
    return (deg * pi / 180.0);
  }

  double rad2deg(double rad) {
    return (rad * 180.0 / pi);
  }

  Future<Uint8List>? getBytesFromAsset(String? path, int? width) async {
    ByteData data = await rootBundle.load(path!);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
  Future<ui.Image> loadImage(dynamic img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<LatLng?> requestPermission() async {
    try {
      final Map<Permission, PermissionStatus> permissionRequestResult = await permission.request();
      PermissionStatus _permissionStatus = permissionRequestResult[permission[0]]!;
      if (_permissionStatus == PermissionStatus.granted) {
        return await _getLocation();
      } else {
        debugPrint("permission not granted from map main view model");
      }
    } on Exception catch (e) {
      if (e.toString().contains("ERROR_ALREADY_REQUESTING_PERMISSIONS")) {}
      debugPrint("Exception in request Permssio $e");
    }
  }

  Future<LatLng?> _getLocation() async {
    try {
      if (globals.userLat == 0.0) {
        await getCurrentLocation();
        await addMyLocationMarker(globals.userLat, globals.userLon);
        moveToUserLocation();

      }
      return LatLng(globals.userLat, globals.userLon);
    } on Exception {
     openLocationSettings();
    }
  }

  Future<String> getCurrentLocation() async {
    if (globals.userLat == 0.0) {
      await getCurrentLocationAddress(toFetchCurrentLatLng: true);
    }
    return "";
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

    bearing = brng;
  }

  Future<PermissionStatus> listenForPermissionStatus1(
      Permission permission) async {
    final PermissionStatus statusFuture = await permission.status;
    return statusFuture;
  }
  Future<BitmapDescriptor> getBitmapFromUrl(String url) async {
    url = globals.UPLOAD_URL + "/images/category/" + url;
    Map<String, Uint8List> iconmap = await appPreferences!.getUint8ListMap();
    Uint8List?  markericon;
    if(iconmap[url] ==null) {
    var request =   await http.get(Uri.parse(url));
    markericon = await getBytesFromAsset1(request.bodyBytes);
      if(markericon !=null) {
        iconmap[url] = markericon;
        appPreferences!.saveUint8ListMap(dataMap: iconmap);
      }
    }else{
      markericon = iconmap[url];
    }
    return BitmapDescriptor.bytes(markericon ?? Uint8List(0),imagePixelRatio: 2);
  }

  Future<bool> getCountryCheck(LatLng startLoc, LatLng destLoc) async {
    List<Placemark> placeMarks = await geocoding.Geocoding().placemarkFromCoordinates(startLoc.latitude, startLoc.longitude,);
   if(placeMarks.isEmpty) return false;
    List<Placemark> endPlaceMarks = await geocoding.Geocoding().placemarkFromCoordinates(destLoc.latitude, destLoc.longitude,);
    if(endPlaceMarks.isEmpty) return false;
    debugPrint("getCountryCheck: ${destLoc} -- ${endPlaceMarks}");
    String startCountryCode = placeMarks[0].isoCountryCode ?? "";
    String endCountryCode = endPlaceMarks[0].isoCountryCode ?? "";
    return startCountryCode == endCountryCode;
  }

  Future<bool> getLocationNullCheck(LatLng _startLoc, LatLng _destLoc) async {
    return _startLoc != LatLng(0.0,0.0) && _destLoc != LatLng(0.0,0.0);
  }


  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    debugPrint("getTimeByAddMin: milli ${dateTime.millisecondsSinceEpoch}");
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
        dateTime.minute + minToAdd);
  }

  Future _getApprovedMarker() async {
    http.Response response = await http.get(Uri.parse(globals.UPLOAD_URL + "/images/category/" + _vehiclemarkerimg!),
    );
    final Uint8List? markericon =
        await getBytesFromAsset1(response.bodyBytes);
    selectedCatIcon = BitmapDescriptor.bytes(markericon!,imagePixelRatio: globals.markerImagePixelRatio);
    drawRouteToDriver(true, false);
  }

  void getMarkerBitmap(String categoryMarkerImage) async {
    http.Response response = await http.get(
      Uri.parse(globals.UPLOAD_URL + "/images/category/" + categoryMarkerImage),
    );
    final Uint8List? markericon = await getBytesFromAsset1(response.bodyBytes);
    AppLifecycleState? currentState = SchedulerBinding.instance.lifecycleState;
    print("Current App Lifecycle State: 6 $currentState");
    selectedCatIcon = BitmapDescriptor.bytes(markericon!,imagePixelRatio: globals.markerImagePixelRatio);
   debugPrint('getMarkerBitmap: ${currentState} -- ${globals.tripStatus}');
    if (currentState == AppLifecycleState.resumed && globals.tripStatus == "started")
      drawDestRoute(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!, locationData.last.latLng!);

  }
}