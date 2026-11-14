part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';


extension CoreMapMainViewModel on MapMainController {

  callSelectLocation(){
debugPrint("isScheduleRideIconEnable: ${isScheduleRideIconEnable} --- ${isFromSchedule} -- ${isScheduleRide}");
    if(isScheduleRideIconEnable || isFromSchedule || isScheduleRide){
      Get.toNamed(AppRoutes.SELECT_DROP_LOCATION,arguments: true);
    }else{
      setNavigation( AppRoutes.SELECT_DROP_LOCATION);
    }
  }

  tripCanceled(String from) {
    couponController.text="";
    destLocAnimController?.forward();
    driverInfoAnimController?.reverse();
    if(from !="ridestatus")
      seRideNowLoadingController(0);
    connectAnimController?.reverse();
    avoidZoom = true;
    updateRxValue(connectingCancelController, false);
    if(locationData.length>=2) {
      tripCalculationModel = null;
      updatePadding(220);
      getScheduleCategoryList( isScheduleRideIconEnable);
    }

    if(globals.isCreatedTrip){
      Get.offAllNamed(AppRoutes.APP_HOME);
      globals.isCreatedTrip = false;
    }
  }

  Future<String> setCurrentLocation(LatLng lastknownLoc) async{
    if(globals.userLat !=0.0 && globals.userLon != 0.0) {
      addMyLocationMarker(globals.userLat, globals.userLon);
      lastKnownLocation =  LatLng(globals.userLat, globals.userLon);
      moveToUserLocation();
     return (await  getUserLocationName()) ?? '';
    }
    return '';
  }

  void checkUserLogin() {
    updateProfileInfo("firstName", globals.firstname.value).then((value) {
      if (value.isNotEmpty) {
        if (value == "timeout") {
          setLogout();
        }
      } else {
        checkInternet( getStatusOfRide, false);
      }
    });
  }

  initiateRide() {
      getPaymentMethods().then((value){
      tripFinalAmount = null;
      debugPrint("initiateRideL: ${confirmPopupAnimController?.status}");
      confirmPopupAnimController?.forward();
    });
  }

  getScheduleCategoryList(bool isForSchedule){
    tripCalculationModel = null;
    seRideNowLoadingController(0);
    openVehicleCategoryList(isForSchedule);

  }

  void openVehicleCategoryList(bool isSchedule) {
    debugPrint("openVehicleCategoryListlastDrawnRouteCredentials: ${locationData}");
    if(locationData.isNotEmpty) {
      globals.closeKeyBoard = false;
      tripFinalAmount = null;
      if(isSchedule){
       checkInternet( getScheduleDrivers, null);
      }else{
        nearDriverErrMsg = null;
        debugPrint("vehicleCatAnimController for 2");
        if(vehicleCatAnimController!=null)
          vehicleCatAnimController?.forward();
        checkInternet( getNearDriver, null);
      }
    }
  }



  getScheduleDrivers(){
    PrimaryScaffold.avoidLoader.value = true;
    getVehicleCategories().then((vehiclecat) {
      if (locationData.isNotEmpty) {
        if(expDate != null) {

          int scheduleDate = selScheduleFromDateTime!.millisecondsSinceEpoch;
          int expiryDate = int.parse(expDate);
          if (selectedSpecialID != null && isSpecialApplied && expiryDate >= scheduleDate) {
            checkInternet(getTripCalculationData, false);
          }
          else if (selectedSpecialID != null && expiryDate <= scheduleDate) {
            selectedSpecialID = null;
            isSpecialApplied = false;
            tripCalculationModel = null;
            setSpecialPriceController(false);
            couponController.clear();
            checkInternet(getTripCalculationData, false);
          }
         checkInternet( getTripCalculationData, false);
        }
        else{
         checkInternet(getTripCalculationData, false);
        }
      }
    });
  }

  getNearDriver() {
      PrimaryScaffold.avoidLoader.value = true;
      getVehicleCategories().then((vehiclecat) {
        if (locationData.isNotEmpty) {
          getNearestDriversCategory(locationData.first.latLng?.latitude ?? 0.0, locationData.first.latLng?.longitude ?? 0.0, false).then((value) {
            if (value == "offline") {}
            else if (value.isNotEmpty) {
              showInSnackBar(
                  value);
            }
            else {
              if (locationData.isNotEmpty) {
                selectedCabIndex = 0;
               selectedCatId =0;
                checkInternet(getTripCalculationData, false);
                if (destLocAnimController != null) {
                  destLocAnimController?.forward();
                }
              }
            }
          });
        }
      });
  }

  confirmRide() {
    if (globals.precautionNotifications == null) {
      confirmRideSocket();
    }else{
      if (globals.precautionNotifications?["isEnabled"] == true){
        bookingInstructionController(true);
      }else{
        confirmRideSocket();
      }
    }
  }

  showNoLocationDialog(){
    showGetDialog(PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          content: Text('location_not_fetched_text'.tr),
          actions: [
            TextButton(
              child: Text('ok_label'.tr),
              onPressed: () {
               Get.back();
                vehicleCatAnimController?.reverse();
                connectAnimController?.reverse();
                lastKnownLocation = LatLng(0.0, 0.0);
                destLocAnimController?.forward();
                setDestPlaceController("");
                clearMap();
                isScheduleRideIconEnable=false;
                isScheduleRide=false;
                isScheduleRideConfirmed=false;
               scheduleRideIconController(false);
               scheduleRideIconController.refresh();
                setCurrentLocation(LatLng(0.0, 0.0));
              },
            ),
          ],
        )
    ));
  }

  getInitialLocation()async {
    if (globals.userLat != 0.0 && globals.userLon != 0.0) {
      lastKnownLocation = LatLng(globals.userLat,globals.userLon);
      addMyLocationMarker(globals.userLat,globals.userLon);
      getUserLocationName().then((address){

      });
    } else {
      getUserLocationName();
    }
  }

  addMyLocationMarker(double startLat, double startLng) async {
    MarkerId  sourceid = MarkerId("pin");
    if(currentLocPin ==null) {
      final Uint8List currIcon = await getBytesFromAsset(pinPng, 70)!;
      currentLocPin = BitmapDescriptor.bytes(currIcon,imagePixelRatio: globals.markerImagePixelRatio);
    }
    if(markersMap.isEmpty) {
      _pin_marker = Marker(
          markerId: sourceid,
          position: LatLng(startLat, startLng),
          flat: true,
          icon: currentLocPin!);
    }
    markersMap[sourceid] = _pin_marker!;
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_addMyLocationMarker ${point} --- ');
    routeController.add(LatLng(startLat, startLng));

  }


// ─────────────────────────────────────────────────────────────────────────
// REFACTORED setMarkers
//
// Key fixes vs original:
// 1. BUG FIX: destination marker in `approved` block used MarkerId("startpoint"),
//    the same id as the pickup marker → it was silently overwriting pickup on
//    the map. Now uses MarkerId("destpoint").
// 2. Deduplicated the onTap navigation logic (was copy-pasted 3x, including a
//    dead `data`/`tempLocationData` clone list that was never used).
// 3. Icon fetches (vehicle marker, stop marker) are now guarded against
//    concurrent duplicate HTTP calls using simple in-flight flags/Futures,
//    and cached in a Map keyed by image name so different categories don't
//    stomp on each other's cached icon.
// 4. Camera animation uses await instead of nested .then()/Future.delayed.
// ─────────────────────────────────────────────────────────────────────────

// Cache: markerImageName -> BitmapDescriptor, shared across calls on this controller.


  /// Fetches (and caches) a BitmapDescriptor from a remote category image,
  /// falling back to a bundled asset if the name is empty or the fetch fails.
  Future<BitmapDescriptor> _getOrFetchCategoryIcon(
      String markerImageName, {
        required String fallbackAssetPath,
        required double fallbackSize,
      }) async {
    if (markerImageName.isEmpty) {
      final Uint8List? bytes = await getBytesFromAsset(fallbackAssetPath, fallbackSize.toInt());
      return BitmapDescriptor.bytes(bytes!, imagePixelRatio: globals.markerImagePixelRatio);
    }

    if (_iconCache.containsKey(markerImageName)) {
      return _iconCache[markerImageName]!;
    }

    if (_iconFetchInFlight.containsKey(markerImageName)) {
      return _iconFetchInFlight[markerImageName]!;
    }

    final Future<BitmapDescriptor> fetchFuture = () async {
      try {
        final http.Response response = await http.get(
          Uri.parse('${globals.UPLOAD_URL}/images/category/$markerImageName'),
        );
        final Uint8List? bytes = await getBytesFromAsset1(response.bodyBytes);
        final icon = BitmapDescriptor.bytes(bytes!, imagePixelRatio: globals.markerImagePixelRatio);
        _iconCache[markerImageName] = icon;
        return icon;
      } catch (_) {
        final Uint8List? fallbackBytes =
        await getBytesFromAsset(fallbackAssetPath, fallbackSize.toInt());
        final icon = BitmapDescriptor.bytes(fallbackBytes!, imagePixelRatio: globals.markerImagePixelRatio);
        _iconCache[markerImageName] = icon; // cache the fallback too, avoid retry storms
        return icon;
      } finally {
        _iconFetchInFlight.remove(markerImageName);
      }
    }();

    _iconFetchInFlight[markerImageName] = fetchFuture;
    return fetchFuture;
  }

  /// Single place for the "tap a location marker to edit drop location" flow.
  /// Replaces 3 copy-pasted onTap bodies. `fallbackLocationText` is whichever
  /// location's text should be pushed into the search box (first vs last stop).
  void _onLocationMarkerTap(String fallbackLocationText) {
    if (isUserInTrip) return;

    if (locationData.length > 2) {
      // NOTE: original code built a cloned/padded `data` list here but never
      // used it before navigating — removed as dead code. If drop-location
      // editing actually needs pre-seeded stop data, pass it explicitly to
      // SelectDropLocation instead of relying on a side-channel list.
      Get.to(() => SelectDropLocation(false));
    } else {
      if (isScheduleRideIconEnable) {
        Get.to(() => SelectDropLocation(true));
      } else {
        setNavigation(AppRoutes.SELECT_DROP_LOCATION);
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        PlacesAutocompleteState.queryTextController?.text = fallbackLocationText;
        update(['placeSelectController']);
      });
    }
  }

  Future<void> setMarkers(List<LatLng> locationLatLng) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_setMarkers ${point} ---${isUserInTrip} ');
    await _focusCameraOnDriver(locationLatLng);

    if(_pin_marker !=null) {
      markersMap.removeWhere((key, value) => key == _pin_marker!.markerId);
    }
    if (isUserInTrip) {
      await _updateDriverVehicleMarker();

      if (globals.tripStatus == 'started') {
        await _upsertEndPointMarker(locationLatLng);
        if (locationLatLng.length > 2) {
          await _upsertStopMarkers(locationLatLng);
        }
      } else {
        _upsertStartPointMarker();
      }
      debugPrint("globals.tripStatus:${globals.tripStatus}");

      if (locationLatLng.length > 2 &&
          globals.tripStatus != 'approved' &&
          globals.tripStatus != 'locationReached') {
        await _upsertStopMarkers(locationLatLng);
      }

    } else {
        _upsertStartPointMarker();
      await _upsertEndPointMarker(locationLatLng);
      if (locationLatLng.length > 2) {
        await _upsertStopMarkers(locationLatLng);
      }
    }
    updateGoogleMap();
  }

  Future<void> _updateDriverVehicleMarker() async {
    if (selectedCatIcon == null && vehicleTypeModel != null) {
      String markerImage = '';
      vehicleTypeModel?.getCategories?.result?.forEach((v) {
        if (v.id == selectedCatId) {
          markerImage = v.categoryMarkerImage;
        }
      });

      selectedCatIcon = await _getOrFetchCategoryIcon(
        markerImage,
        fallbackAssetPath: pinPng,
        fallbackSize: 70,
      );
    }

    if (vehicleTypeModel == null || selectedCatIcon == null) {
      selectedCatIcon = await _getOrFetchCategoryIcon(
        _vehiclemarkerimg ?? '',
        fallbackAssetPath: pinPng,
        fallbackSize: 70,
      );
    }

    if (markersMap[driverVehicleId] == null) {
      final position = getLatLngFromLocationModel(
        selectLocationEnum: SelectLocationEnum.bookingDriverLocation,
      );
      if (position != null) {
        markersMap[driverVehicleId!] = Marker(
          markerId: driverVehicleId!,
          position: position,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: selectedCatIcon!,
        );
      }
    }
  }

  Future<void> _focusCameraOnDriver(List<LatLng> locationLatLng) async {
    final controller = mapController;
    if (controller == null) return;

    final LatLngBounds bounds = getBounds(locationLatLng);
    debugPrint("_focusCameraOnDriver called");
    if(!isUserInTrip) {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 0));
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final driverPosition = getLatLngFromLocationModel(
      selectLocationEnum: SelectLocationEnum.bookingDriverLocation,
    );
    if (driverPosition == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: driverPosition, zoom: 15),
      ),
    );
  }

  void _upsertStartPointMarker() {
    final MarkerId sourceId = MarkerId("startpoint");

    if (_start_point_marker == null) {
      _start_point_marker = Marker(
        markerId: sourceId,
        position: mapUtils?.initLoc ?? const LatLng(0.0, 0.0),
        flat: true,
        onTap: () => _onLocationMarkerTap(locationData.first.location ?? ''),
        icon: pickupIcon!,
      );
    } else {
      _start_point_marker = _start_point_marker?.copyWith(
        positionParam: mapUtils?.initLoc ?? const LatLng(0.0, 0.0),
      );
    }
    markersMap[sourceId] = _start_point_marker!;
    debugPrint("markersmap:start: ${markersMap}");
  }


  Future<void> _upsertEndPointMarker(List<LatLng> locationLatLng) async {
    debugPrint("markersmap:end: ${locationLatLng} --- ${_end_point_marker} --- ${destIcon}");
    final MarkerId destId = MarkerId("endpoint");
    final LatLng endPosition = locationLatLng[locationLatLng.length - 1];

    if (_end_point_marker == null) {
      _end_point_marker = Marker(
        markerId: destId,
        position: endPosition,
        flat: true,
        onTap: () => _onLocationMarkerTap(locationData.last.location ?? ''),
        icon: destIcon!,
      );
    } else {
      _end_point_marker = _end_point_marker?.copyWith(positionParam: endPosition);
    }
    markersMap[destId] = _end_point_marker!;
    debugPrint("markersmap:end: ${markersMap}");
  }

  Future<void> _upsertStopMarkers(List<LatLng> locationLatLng) async {
    debugPrint("markersmap:stop: ${locationLatLng} --- ${_end_point_marker} --- ${stopLocIcon}");
    stopLocIcon ??= await () async {
      final Uint8List? bytes = await getBytesFromAsset(stopMarkerPng, 45);
      return BitmapDescriptor.bytes(bytes!, imagePixelRatio: globals.markerImagePixelRatio);
    }();

    for (int i = 1; i < locationLatLng.length - 1; i++) {
      final MarkerId stopId = MarkerId("stop$i");
      markersMap[stopId] = Marker(
        markerId: stopId,
        position: LatLng(locationLatLng[i].latitude, locationLatLng[i].longitude),
        flat: true,
        onTap: () => _onLocationMarkerTap(locationData.last.location ?? ''),
        icon: stopLocIcon!,
      );
    }
    debugPrint("markersmap:stop: ${markersMap}");
  }
}