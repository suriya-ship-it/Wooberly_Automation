part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension SocketMapMainViewModel on MapMainController {
  void reInitSocket() async {
    globals.socket?.connect();
    socketConnect();
  }

  socketConnect() {
    globals.socket?.onConnect((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });

    globals.socket?.onConnect((data) {
      if (data is Map) {
        data = json.encode(data);
      }
      if (!netOff) {
        netOff = true;
        checkUserLogin();
      }
    });
    globals.socket?.onConnectError((data) {
      if (data is Map) {
        data = json.encode(data);
      }
      if (Platform.isAndroid) {
        if (data
            .toString()
            .contains("io.socket.engineio.client.EngineIOException")) {
          if (netOff) {
            netOff = false;
          }
        }
      }
    });

    globals.socket?.onError((data) {
      if (data is Map) {
        data = json.encode(data);
      }
      if (Platform.isIOS) {
        if (data.toString().contains("offline") ||
            data.toString().contains("Tried emitting when not connected")) {
          if (netOff) {
            netOff = false;
          }
        }
      }
    });
  }

  listenChatSocket(int bookingId) {
    globals.socket?.off("newMessage-$bookingId");
    globals.socket?.on("newMessage-$bookingId", (data) {

      if (data is Map) {
        debugPrint("listenChatSocket: ${data} -- ");
        if (data["data"]["status"] == 200) {
          if (globals.userid != data["data"]["data"]["authorId"]) {
            if(data["data"]["data"]["originalAudioLanguage"] !=null)
            driveraiPrefLang = data["data"]["data"]["originalAudioLanguage"];
            if (Get.currentRoute.contains('App_Chat')) {
              isMessageUpdate.refresh();
              readThreadCount();
            } else {
              unreadCount = data["data"]["data"]["unReadRiderCount"];
              update(['unReadCountController']);
            }
          }
        }
      }
    });
  }

  void sendTripPayment() {
    if(bookingId ==null || bookingId == 0)
      getTripStatusOnly();
    globals.setButtonLoading();
    List<String> arg = [
      '{"data" : {"auth": "${globals.authToken}",'
          '"paymentIntentId" : "${paymentIntent}","paymentCurrency": "${rideCurrency == 4 ? tripStatusResult["result"]["currency"] : globals.paypalCurrencyController.text}","paymentType" : ${rideCurrency},"riderId" : "${globals.userid}","driverId" : "${driverId}", "bookingId" : ${bookingId} }}'
    ];
    tipsAmount.clear();
    debugPrint("sendTripPayment: ${arg}");
    socketIns?.onsendMessage("tripPayment", arg);
  }

  onsendTripPayment(String eventName, Function onSendTripPayment) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        debugPrint("onsendTripPayment: ${data}");
        globals.setButtonIdle();
        if (data["data"]["status"] == 200) {
          if (globals.preferredPaymentMethod == 5) {
            payStackURL = data["data"]["data"]["url"].toString();
            payStackRef = data["data"]["data"]["reference"].toString();
          }
          if (globals.preferredPaymentMethod == 6) {
            payPalURL = data["data"]["data"]["redirectURL"].toString();
          }

          onSendTripPayment();
        }
        if (data["data"]["status"] == 400) {
          if(data["data"]["data"]["requireAdditionalAction"] == true){
            confirmPayment(int.parse((data["data"]["data"]["id"] ?? 0).toString()),data["data"]["data"]["paymentIntentSecret"] ?? "").then((value){
           debugPrint("confirmPayment: ${value}");
              if(value.isEmpty) {
                onSendTripPayment();
              }else{
                paymentStatusController(0);
                if(value != "exception" && value != "cancelled") showInSnackBar(value);
              }
            });
          }else{
            paymentStatusController(0);
            showInSnackBar(data["data"]["errorMessage"]);
          }
        }
      }
    });
  }

  onTripCompleted(String eventName) {
    globals.socket?.on(eventName, (data) {
      log("onTripCompleted -- data: ${data}");
      if (data["data"]["data"]["riderId"].toString() == globals.userid){

      if (Get.isRegistered<StopController>()) {
        Get.delete<StopController>();
        final StopController stopController = Get.put(StopController());
        stopController.clearStops();
      }
      locationData.clear();
      clearMap();
      globals.userLat = 0.0;
      globals.userLon = 0.0;
      EditDisableLocationsDataIndex = 0;
      PlacesAutocompleteState.activeStopIndex = 1;
      getCurrentLocation().then((value) {
        setCurrentLocation(LatLng(0.0, 0.0));
      });
      sosIconController?.reverse();
      setDefaultLocationIconPosition();
      updateRxValue(SOSavailController,false);
      tripSharedController?.reverse();
        if (data is Map && globals.tripStatus != "completed") {
          if (data["data"]["status"] == 200) {
            globals.tripStatus = "completed";
            couponController.text = "";
            for (int i = 0; i < locationData.length; i++) {
              locationData[i].fieldType = 'disabled';
            }


            if (data["data"]["data"]["isSpecialTrip"]) {
              finalAmount = data["data"]["data"]["specialTripTotalFare"];
              finalAmountController(finalAmount.toDouble());
            } else {
              finalAmount = data["data"]["data"]["riderTotalFare"];
              finalAmountController(finalAmount.toDouble());
            }
            dynamic unitPrice = data["data"]["data"]["baseFare"];
            dynamic riderBase = 0;
            if (data["data"]["data"]["totalRideDistance"] != 0 ||
                data["data"]["data"]["totalRideDistance"] != 0.0) {
              riderBase = data["data"]["data"]["totalFare"] /
                  data["data"]["data"]["totalRideDistance"];
              riderBase = riderBase.round();
            } else {
              riderBase = data["data"]["data"]["totalFare"];
            }
            if (unitPrice == riderBase) {
              baseFare = data["data"]["data"]["baseFare"];
            } else {
              baseFare = data["data"]["data"]["baseUnit"];
            }
            if (data["data"]["data"]["walletBalance"] != null) {
              globals.walletBalance.value = double.parse(data["data"]["data"]["walletBalance"].toString());
            }
            clearMap();
            getRideStatus().then((value) {
              Future.delayed(const Duration(milliseconds: 500), () {
                finalAmountController.refresh();
                update(['paymentTypeUpdate']);
                tripAmountController?.forward();
                finalAmountController(1.0);
              });
            });
            calledOnce = true;
          }
        }
        if(Get.isBottomSheetOpen??false) Get.back();
        if (scaffoldKey.currentState != null) {
          if (scaffoldKey.currentState?.isEndDrawerOpen ?? false)
            scaffoldKey.currentState?.closeEndDrawer();

          Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN);
        } else {
          Get.offAllNamed(AppRoutes.APP_MAP_MAIN);
        }
      Future.delayed(const Duration(milliseconds: 500), () {
        driverInfoAnimController?.reverse();
      });
    }
    });
  }

  onDriverCancelled(String eventName,[String? cancel]) {
    globals.socket?.on(eventName, (data) async {
      rideConfirmOTPController(0);
      rideConfirmOTPAnimController?.reverse();
      globals.tripStatus = cancel != null ? "cancelledByRider" : "cancelledByDriver";
      if (Get.isRegistered<StopController>()) {
        Get.delete<StopController>();
        final StopController stopController = Get.put(StopController());
        stopController.clearStops();
      }
      if(Get.currentRoute.contains('SelectLocationOnMapPage')){
        Get.until((route) => route.settings?.name == AppRoutes.APP_MAP_MAIN);
      } else if(Get.currentRoute.contains('SelectDropLocation')){
        Get.until((route) => route.settings?.name == AppRoutes.APP_MAP_MAIN);
      }
      debugPrint("get.currentroute: driver cancel ${Get.currentRoute}");
      locationData.clear();
      unreadCount=0;
      destLocAnimController?.forward();
      closeTripPlannerPage();
      tripSharedController?.reverse();
      if(driverInfoAnimController !=null) driverInfoAnimController?.reverse();
      if (cancel == null) rideCancelledAnimController?.forward();
      if (data is Map) {

        driverInfoAnimController?.reverse();
        setDestPlaceController("");
        calledOnce = true;
        clearMap();

        globals.userLat = 0.0;
        globals.userLon = 0.0;
        await getCurrentLocation();
        setCurrentLocation(LatLng(0.0, 0.0));
        sosIconController?.reverse();
        setDefaultLocationIconPosition();
        tripSharedController?.reverse();
        if(Get.isDialogOpen!)
          Get.back();

        updateRxValue(SOSavailController,false);
        tripSharedController?.reverse();
        if (closeMultipleStopSearchPageController != null)
          closeMultipleStopSearchPageController(true);

        if (closeCancelTripController != null) {
          closeCancelTripController!.value=true;
          closeCancelTripController = null;
        }
      }
    });
  }

  onTripStartMessageReceived(String eventName) {
    globals.socket?.on(eventName, (data) {
        if (isUserInTrip) {
          sosIconController?.forward();
          setLocIconPositionForConfirm();
          updateRxValue(SOSavailController,true);
          if (data is Map) {
            if (data["data"]["status"] == 200) {
              globals.tripStatus = "started";
              for(int i= 0; i<locationData.length; i++){
                if(i==0)
                locationData[i].fieldType = 'disabled';
              }
              EditDisableLocationsDataIndex = 1;
              update(['placeSelectController']);
              destLocAnimController?.reverse();

              rideConfirmOTPController(0);
              rideConfirmOTPAnimController?.reverse();


              socketIns?.disconnectListen("tripComplete-${globals.userid}");
              onTripCompleted("tripComplete-${globals.userid}");
              socketIns?.disconnectListen("tripStatus-${globals.userid}");
              listenBookingLocationSocket("tripStatus-${globals.userid}");
              markersMap.removeWhere((key , marker)=> marker.markerId.value == "pin");
              markersMap.removeWhere((key , marker)=> marker.markerId.value == "startpoint");
              if(globals.socket?.connected ?? false){
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }
              else{
                reInitSocket();
                socketIns?.disconnectListen("tripRequest-${globals.userid}");
                onTripRequestInfo("tripRequest-${globals.userid}");
              }

              rideStartedController(true);

              drawDestRoute(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!,
                  locationData.last.latLng!);

              driverAvailController(true);
              sosIconController?.forward();
              setLocIconPositionForConfirm();
              updateRxValue(SOSavailController,true);
              driverInfoAnimController?.forward();
              connectAnimController?.reverse();
              update(['unReadCountController']);


              update(['updateBookingLocationController']);
              if(Get.isBottomSheetOpen??false)
                Get.back();

            }
          }
        }

    });
  }

  onTripRequestInfo(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        debugPrint("onTripRequestInfo: map main ${data} -- ");
        globals.isCreatedTrip = false;
        if (data["data"]["status"] == 400) {
          if (data["data"]["data"] !=null && (data["data"]["data"]["isTryAgain"] == true || data["data"]["data"]["isTryAgain"] == 'true')) {
              if ( locationData.isNotEmpty) {
                    driverAvailController(false);
                    vehicleCatAnimController?.reverse();
                    connectAnimController?.reverse();
                    driverInfoAnimController?.forward();
                    setDefaultLocationIconPosition();
              } else {
                Get.offAllNamed(AppRoutes.APP_HOME);
              }
          }
          else {
            showConfirmationDialog(
                content: data["data"]["errorMessage"],
                onConfirm:  () {
                  debugPrint("oklabel cancel click");
                  Get.back();
                  if(globals.tripStatus != "approved" &&
                      globals.tripStatus != "locationReached" &&
                      globals.tripStatus != "started") {
                    Get.offAllNamed(AppRoutes.APP_HOME);
                  }
                },
                confirmButtonText: 'ok_label'.tr,
            isDisableCancel: true);
          }
        }
        else if (data["data"]["status"] == 500) {
          toast.show(
                context: Get.context!,
                message: 'session_timeout_err'.tr,
              );
          clearMap();
          setLogout();
        }
        else {
          bookingId = data["data"]["data"]["bookingId"];
          if(!Get.currentRoute.contains('App_Chat'))
          listenChatSocket(bookingId);
          AppLifecycleState? currentState = SchedulerBinding.instance.lifecycleState;
          print("Current App Lifecycle State: 4 $currentState");
          debugPrint("locationupdate123: 45 ${currentState == AppLifecycleState.resumed} --- ${isFromAppResume} --- ${data["data"]["data"]["locationUpdate"]}");
          if(currentState != AppLifecycleState.resumed && data["data"]["data"]["locationUpdate"])
            return;
          socketIns?.disconnectListen("riderCancel-${globals.userid}");
          onCancelResponse("riderCancel-${globals.userid}");
          avoidZoom = false;
          if (data["data"]["data"]["bookingLocations"]!= null &&
              data["data"]["data"]["bookingLocations"].isNotEmpty) {
            locationData.clear();

            data["data"]["data"]["bookingLocations"].forEach((element) {
              locationData.add(LocationData(
                  LatLng(element["locationLat"], element["locationLng"]),
                  element["location"],
                  element["fieldType"],
                  element["id"],
                  element["locationStatus"],
                  element["locationType"],
                  element["locationDistanceType"]));
            });
            update(['updateBookingLocationController']);
          }else {
            getRideStatus();
          }
          debugPrint("locationupdate123: ${currentState} --- ${isFromAppResume} --- ${data["data"]["data"]["locationUpdate"]}");
          if (data["data"]["data"]["driverLat"] != 0.0 ||
              data["data"]["data"]["driverLng"] != 0.0) {

            if(markersMap[driverVehicleId] !=null)
            driverOldLoc =  markersMap[driverVehicleId]?.position;
          double  driverLat = data["data"]["data"]["driverLat"];
            double  driverLng = data["data"]["data"]["driverLng"];

            setLocationDetails(selectLocationModel: SelectLocationModel(lat: driverLat,lng: driverLng,
                isValidLocation: driverLat !=0.0 && driverLng !=0.0,
                location: '',
                selectLocationEnum: SelectLocationEnum.bookingDriverLocation),
                selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
          }
          if(position.isEmpty)
            position = [getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!.latitude, getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!.longitude];


          if(data["data"]["data"]["rotation"] != null)
          bearing = double.parse(data["data"]["data"]["rotation"].toString());

          if (driverVehNum.isEmpty)
            driverVehNum = data["data"]["data"]["vehicleNumber"];
          debugPrint("locationupdate: ${currentState} --- ${isFromAppResume} --- ${data["data"]["data"]["locationUpdate"]}");
          if (data["data"]["data"]["locationUpdate"]) {

            connectAnimController?.reverse();
            vehicleCatAnimController?.reverse();
            destLocAnimController?.reverse();
            if(currentState == AppLifecycleState.resumed) {
              drawRouteToDriver(true, data["data"]["data"]["locationUpdate"]);
            }
          }
          else {
            isSpecialApplied = false;
            selectedSpecialID = 0;
            polyLines.points.clear();
            locationData.clear();
            _vehicleCatMarkerIds.clear();
            markersMap.clear();
            isInitialGetTripStatusLoading = true;
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target:  globals.userLat ==0.0 && globals.userLon ==0.0   ? getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)! : LatLng(globals.userLat, globals.userLon),
                zoom: 17,
              ),
            ));
            vehicleCatAnimController?.reverse();
            destLocAnimController?.reverse();
            connectAnimController?.reverse();
            rideStartedController(false);
            selectedComfortRideFromAPI.clear();
            update();
            if (data["data"]["data"]["comfortRide"] != null &&
                data["data"]["data"]["comfortRide"].length > 0) {
              data["data"]["data"]["comfortRide"].forEach((element) {
                selectedComfortRideFromAPI.add(int.parse("$element"));
              });
            }
            globals.tripStatus = "approved";
            driverName = toBeginningOfSentenceCase(
                data["data"]["data"]["name"].toString())!;

            driverId = data["data"]["data"]["driverId"];
            driverPhone = data["data"]["data"]["phoneNumber"];
            if (data["data"]["data"]["picture"] != null) {
              driverPhoto = globals.UPLOAD_URL +
                  "/images/avatar/" +
                  data["data"]["data"]["picture"];
            } else {
              driverPhoto = "";
            }

            if( globals.isEnableOTP) {
              rideConfirmOTPController(int.parse(data["data"]["data"]["confirmationCode"].toString()));
              rideConfirmOTPAnimController?.forward();
            }

            drawRouteToDriver(true, data["data"]["data"]["locationUpdate"]);

          }
          if (calledOnce) {
            calledOnce = false;
            socketIns?.disconnectListen("tripStart-${globals.userid}");
            onTripStartMessageReceived("tripStart-${globals.userid}");
            socketIns?.disconnectListen("tripLocationReached-${globals.userid}");
            onTripLocationReached("tripLocationReached-${globals.userid}");
            socketIns?.disconnectListen("driverCancel-${globals.userid}");
            onDriverCancelled("driverCancel-${globals.userid}");
          }
          if (data["data"]["data"].containsKey("adminId")) {
            isFromAdmin = data["data"]["data"]["adminId"] != null;
          }
        }
      }
    });
  }
}