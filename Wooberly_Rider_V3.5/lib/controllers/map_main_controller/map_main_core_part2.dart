part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension MapMainCorePart2 on MapMainController{
  Future<void>  moveMarker({int? delayness,bool isforceNearestPoint = false}  ) async {
    if(markersMap[driverVehicleId] == null) return;
    _polylineMoverMarker();
  }


  drawRouteToDriver(bool status, bool locationUpdate) async {
    debugPrint("onTripRequestInfo: drawRouteToDriver ${locationUpdate} -- ${status}");
    LatLng driverpos =  getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!;
    if(position.isEmpty)
      position = [driverpos.latitude, driverpos.longitude];
    if (status) {
      if (locationUpdate) {
        if (globals.tripStatus == "started") {
          if (markersMap[driverVehicleId] != null) {
            updateMarker(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!, bearing,
                locationData.last.latLng!);
          }
        }
        else {
          if (markersMap[driverVehicleId] != null) {
            updateMarker(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!, bearing,
                locationData.first.latLng!);
          }
        }
      } else {
        if(isUserInTrip ) {
          connectAnimController?.reverse();
          if(globals.tripStatus == "started") {
            debugPrint('locationDatastarted: ${locationData}');
            drawDestRoute(
                getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!,
                locationData.last.latLng!
            );
          } else {
            drawRouteFromDriver();
          }
          driverAvailController(true);
          sosIconController?.forward();
          setLocIconPositionForConfirm();
          updateRxValue(SOSavailController,true);
          driverInfoAnimController?.forward();
        }
      }
    }
  }

  addMultipleMarker(getDriversWithCategoryAndPrice result, BitmapDescriptor markerImage)  {
    selectedCatIcon = markerImage;
    MarkerId sourceId = MarkerId("source_${selectedCabIndex.toString()}_${result.id.toString()}");
    _vehicleCatMarkerIds.add(sourceId);
    Marker sourceMarker = Marker(
        markerId: sourceId,
        position: LatLng(result.lat ?? 0.0, result.lng ?? 0.0),
        flat: true,
        icon: markerImage);
    markersMap[sourceId] = sourceMarker;
    routeController.add(LatLng(globals.userLat,globals.userLon));
  }

  void setValueOnHomeMarker({required URL,required LatLng latLng,required String categoryId}) async {
    Map<String, Uint8List> icons = await appPreferences!.getUint8ListMap();
    Uint8List? markerimg;
    if(icons[URL] ==null) {
      var request = await http.get(Uri.parse(URL));
      var bytes = await request.bodyBytes;
      markerimg = await getBytesFromAsset1(bytes);
      icons[URL] = markerimg!;
      appPreferences!.saveUint8ListMap(dataMap: icons);
    }else{
      markerimg = icons[URL];
    }
    LatLng _positionPoints = latLng;
    HomeMarkersMap[MarkerId("$categoryId")] = Marker(
      icon: BitmapDescriptor.bytes(markerimg!,imagePixelRatio: globals.markerImagePixelRatio),
      markerId: MarkerId(_positionPoints.toString()),
      position: _positionPoints,
    );
    debugPrint('updateHomeMapController:  2 ${lastNearestDriverEmail} ---${categoryId}');
    if(!mapLoading && lastNearestDriverEmail == categoryId)
      updateHomeMapController(true);
    updateHomeMapController.refresh();
    mapRefreshController.refresh();
  }

  getStatusOfRide() {
    debugPrint('getStatusOfRide called');
    Get.closeCurrentSnackbar();
      getRideStatus().then((value){
        if(value != "isRiderViewed") {
          if (value.isNotEmpty) {
            if (value != "offline") {
              destLocAnimController?.forward();
            }
          } else  {
            String status = tripStatusResult["result"]["tripStatus"];
            globals.tripStatus = status;
            socketIns?.disconnectListen("loginCheck-${globals.userid}");
            onReceiveLoginCheck("loginCheck-${globals.userid}");
            onManualBookingCreatedByAdminCheck();
            onUserPreferenceUpdated();
            socketIns?.disconnectListen("updatePreferredCurrency-${globals.userid}");
            updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
            debugPrint("onfirmPopupAnimControllerstatus: ${confirmPopupAnimController?.status} --- ${globals.tripStatus}");

            if (tripStatusResult["result"]["tripStatus"] == "expired") {
              updatePadding(0);
              tripCanceled('');
            }
            else if ((tripStatusResult["result"]["tripStatus"] == "approved") || (tripStatusResult["result"]["tripStatus"] == "locationReached")) {

              if(globals.socket?.connected ?? false){
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }
              else{
                reInitSocket();
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }
              avoidZoom = false;
              driverVehNum = tripStatusResult["result"]["vehicleNumber"];
              LatLng? driverpos =  getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
              if(driverpos ==null || !(globals.socket?.connected ?? false)){

                double driverLat = tripStatusResult["result"]["driverDetails"]["userData"]["lat"];
                double  driverLng = tripStatusResult["result"]["driverDetails"]["userData"]["lng"];
                debugPrint("driverLat: ${driverLat} -- ${driverLng} --- ${locationData}");
                setLocationDetails(selectLocationModel: SelectLocationModel(lat: driverLat,lng: driverLng,
                    isValidLocation: driverLat !=0.0 && driverLng !=0.0,
                    location: '',
                    selectLocationEnum: SelectLocationEnum.bookingDriverLocation),
                    selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
                if(position.isEmpty)
                  position = [driverLat, driverLng];
              }


              bookingId = tripStatusResult["result"]["id"];
              getUnreadThreadCount().then((value){
                if(value==""){
                  listenChatSocket(bookingId);
                  _vehiclemarkerimg = tripStatusResult["result"]["categoryDetails"]["categoryMarkerImage"];
                  driverName = "${toBeginningOfSentenceCase(tripStatusResult["result"]["driverDetails"]["firstName"].toString())}";
                  driverId = tripStatusResult["result"]["driverId"];
                  String code = tripStatusResult["result"]["driverDetails"]["userData"]["phoneDialCode"];
                  driverPhone =code+  tripStatusResult["result"]
                  ["driverDetails"]["userData"]["phoneNumber"];
                  if (tripStatusResult["result"]["driverDetails"]["picture"] != null)
                    driverPhoto = globals.UPLOAD_URL + "/images/avatar/" + tripStatusResult["result"]["driverDetails"]["picture"];
                  rideStartedController(false);
                  if (calledOnce) {
                    calledOnce = false;
                    socketIns?.disconnectListen("tripStart-${globals.userid}");
                    onTripLocationReached("tripLocationReached-${globals.userid}");
                    socketIns?.disconnectListen("tripStart-${globals.userid}");
                    onTripStartMessageReceived("tripStart-${globals.userid}");
                    socketIns?.disconnectListen("driverCancel-${globals.userid}");
                    onDriverCancelled("driverCancel-${globals.userid}");
                  }
                  connectAnimController?.reverse();
                  sosIconController?.forward();
                  setLocIconPositionForConfirm();
                  updateRxValue(SOSavailController,true);
                  destLocAnimController?.reverse();

                  update(['updateBookingLocationController','unReadCountController']);


                  _getApprovedMarker().then((value) {
                    drawRouteFromDriver();
                  });


                }else if(value=="Offline"){
                  showInSnackBar('offline_text'.tr);
                }else{
                  showInSnackBar( value);
                }
              });
              log('test9${tripStatusResult}');
              print('test9${tripStatusResult["result"]["confirmationCode"]}');
              if(tripStatusResult["result"]["confirmationCode"] !=null &&
                  tripStatusResult["result"]["confirmationCode"].toString() != rideConfirmOTPController.value.toString() && globals.isEnableOTP) {
                rideConfirmOTPController(int.parse( tripStatusResult["result"]["confirmationCode"].toString()));
                rideConfirmOTPAnimController?.forward();
              }
            }
            else if (tripStatusResult["result"]["tripStatus"] == "cancelledByDriver") {

              int date = DateTime.now().millisecondsSinceEpoch;
              if ((date - int.parse(tripStatusResult["result"]["tripStart"])) <= (60 * 1000 * 3) && globals.tripStatus != "cancelledByDriver") {
                driverInfoAnimController?.reverse();
                locationData.clear();
                clearMap();
                globals.userLat = 0.0;
                globals.userLon = 0.0;
                getCurrentLocation().then((value) {
                  setCurrentLocation(LatLng(0.0, 0.0));
                });

                calledOnce = true;
                closeMultipleStopSearchPageController(true);
              } else {
                destLocAnimController?.forward();
              }

              destLocAnimController?.forward();
              connectAnimController?.reverse();
              sosIconController?.reverse();
              setDefaultLocationIconPosition();
              tripSharedController?.reverse();
              if(locationData.isNotEmpty)
              Get.back();
              if(Get.isBottomSheetOpen == true){
                Get.back();
              }

              updateRxValue(SOSavailController,false);
              setDefaultLocationIconPosition();
              tripSharedController?.reverse();
              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();

            }
            else if (tripStatusResult["result"]["tripStatus"] == "started") {
              destLocAnimController?.reverse();

              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();
              double  driverLat = tripStatusResult["result"]["driverDetails"]["userData"]["lat"];
              double  driverLng = tripStatusResult["result"]["driverDetails"]["userData"]["lng"];

              setLocationDetails(selectLocationModel: SelectLocationModel(lat: driverLat,lng: driverLng,
                  isValidLocation: driverLat !=0.0 && driverLng !=0.0,
                  location: '',
                  selectLocationEnum: SelectLocationEnum.bookingDriverLocation),
                  selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
              socketIns?.disconnectListen("tripComplete-${globals.userid}");
              onTripCompleted("tripComplete-${globals.userid}");
              socketIns?.disconnectListen("tripStatus-${globals.userid}");
              listenBookingLocationSocket("tripStatus-${globals.userid}");

              if(globals.socket?.connected ?? false){
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }
              else{
                reInitSocket();
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }

              driverVehNum = tripStatusResult["result"]["vehicleNumber"];
              bookingId = tripStatusResult["result"]["id"];
              getUnreadThreadCount().then((value){
                if(value==""){
                  listenChatSocket(bookingId);
                  driverName =
                  "${toBeginningOfSentenceCase(tripStatusResult["result"]["driverDetails"]["firstName"].toString())}";


                  driverId = tripStatusResult["result"]["driverId"];
                  String code = tripStatusResult["result"]["driverDetails"]["userData"]["phoneDialCode"];
                  driverPhone = code + tripStatusResult["result"]
                  ["driverDetails"]["userData"]["phoneNumber"];
                  if (tripStatusResult["result"]["driverDetails"]
                  ["picture"] !=
                      null)
                    driverPhoto = globals.UPLOAD_URL +
                        "/images/avatar/" +
                        tripStatusResult["result"]["driverDetails"]
                        ["picture"];

                  _vehiclemarkerimg = tripStatusResult["result"]["categoryDetails"]["categoryMarkerImage"];

                  rideStartedController(true);

                  if (calledOnce) {
                    calledOnce = false;
                    socketIns?.disconnectListen("driverCancel-${globals.userid}");
                    onDriverCancelled("driverCancel-${globals.userid}");
                  }

                  double driverLat = tripStatusResult["result"]["driverDetails"]["userData"]["lat"];
                  double  driverLng = tripStatusResult["result"]["driverDetails"]["userData"]["lng"];

                  setLocationDetails(selectLocationModel: SelectLocationModel(lat:driverLat,
                      lng:driverLng,
                      selectLocationEnum: SelectLocationEnum.bookingDriverLocation,
                      location: '',
                      isValidLocation: (driverLat !=0.0 || driverLng !=0.0)),
                    selectLocationEnum:  SelectLocationEnum.bookingDriverLocation,);
                  if(position.isEmpty)
                    position = [driverLat, driverLng];


                  String categoryMarkerImage = tripStatusResult["result"]["categoryDetails"]["categoryMarkerImage"];
                  getMarkerBitmap(categoryMarkerImage);
                  driverAvailController(true);
                  sosIconController?.forward();
                  setLocIconPositionForConfirm();
                  updateRxValue(SOSavailController,true);
                  driverInfoAnimController?.forward();
                  connectAnimController?.reverse();
                  rideStartedController(true);
                  update(['updateBookingLocationController','unReadCountController']);

                }else if(value=="Offline"){
                  showInSnackBar( 'offline_text'.tr);
                }else{
                  showInSnackBar( value);
                }
              });
            }
            else if (tripStatusResult["result"]["tripStatus"] == "completed") {

              if(tripStatusResult["result"]["paymentStatus"] != 'completed' && tripAmountController?.isCompleted == false && confirmPopupAnimController?.isCompleted == false) {
                tripAmountController?.forward();
                finalAmountController(1.0);
              }
              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();
              destLocAnimController?.forward();
            }
            else if (tripStatusResult["result"]["tripStatus"] == "created") {
              destLocAnimController?.forward();
              connectAnimController?.forward();
              vehicleCatAnimController?.reverse();
              vehicleCatDetailAnimController?.reverse();
            }
            else if (tripStatusResult["result"]["tripStatus"] == "cancelledByRider" ) {
              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();
              if(locationData.isEmpty){
                destLocAnimController?.forward();
              }
            }
            else {
              destLocAnimController?.forward();
              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();
              connectAnimController?.reverse();
              driverInfoAnimController?.reverse();

            }
          }
        }
        Future.delayed(Duration(seconds: 1)).then((value){
          isInitialGetTripStatusLoading=false;
        });
      });

  }

  clearMap() {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_clearMap ${point} --- ');
    if (polyLines != Polyline(polylineId: PolylineId(''))) {
      polyLines = Polyline(polylineId: PolylineId(''));
    }
    markersMap.clear();
    routeController.add(LatLng(globals.userLat, globals.userLon));

  }

  void setSelectedCabController(int index, getDriversWithCategoryAndPrice result) async {
    selectedCabIndex = index;
    markersMap.removeWhere((key , marker)=> marker.markerId.value == "pin");
    for (int i = 0; i < _vehicleCatMarkerIds.length; i++) {
      markersMap.removeWhere((key , marker)=> marker.markerId.value == _vehicleCatMarkerIds[i].value);
      _vehicleCatMarkerIds.remove(i);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedCabController.value = index;
    });
    getBitmapFromUrl(result.categoryMarkerImage ?? '').then((markerimg){
      addMultipleMarker(result, markerimg);
    });
  }
  getTripCalculationData() {
    getPrecautionNotification();
    if (tripCalculationModel == null) {
      getTripCalculation().then((value) {
        if (locationData.isNotEmpty) {
          if (value == "offline") {
            seRideNowLoadingController(2);
          }
          else if (value.isNotEmpty) {
            strServiceUnavailable = value;
            seRideNowLoadingController(2);
            showInSnackBar( value);
          }
          else {
            if (!isScheduleRideIconEnable) {
              if (nearestDriversCategoryList[selectedCabIndex].lat != 0.0 &&  nearestDriversCategoryList[selectedCabIndex].lat != null)
                isCabAvailable = true;
              else {
                isCabAvailable = false;
              }
            }
            seRideNowLoadingController(1);
            setLocIconPositionForCategory();
            debugPrint("vehicleCatAnimController for 3");
            vehicleCatAnimController?.forward();
            isSelectMapLocation = false;
            PrimaryScaffold.avoidLoader.value = false;
            try {
              tripAmountController?.reverse();
            } on Exception catch (e) {
              debugPrint("route draw error");
            }
          }
        }
      });
    }
  }
}