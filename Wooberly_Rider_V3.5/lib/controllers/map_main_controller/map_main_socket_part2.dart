part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension MapMainSocketPart2 on MapMainController{
  onCancelResponse(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 400) {
          showInSnackBar(data["data"]["errorMessage"]);
          tripSharedController?.reverse();
          requestPermission();
          setDestPlaceController("");
          couponController.text = "";
          locationData.clear();
          closeTripPlannerPage();
        }
      }
    });
  }

  onTripCancelled(String eventName, String selectedReason) {
    List<String> arg;
    if (selectedReason != null && selectedReason.isNotEmpty) {
      arg = [
        '{"data" :{"auth" : "${globals.authToken}" , "userId" : "${globals.userid}" , "reason" : ${jsonEncode(selectedReason)} , "reasonId" : ${jsonEncode(selectedCancelReason['id'])} , '
            '"bookingId" : ${bookingId}}}'
      ];
    }
    else {
      arg = [
        '{"data" :{"auth" : "${globals.authToken}" , "userId" : "${globals.userid}",'
            '"bookingId" : ${bookingId}}}'
      ];
    }
    sosIconController?.reverse();
    setDefaultLocationIconPosition();
    globals.tripStatus = "cancelledByRider";
    rideConfirmOTPController(0);
    rideConfirmOTPAnimController?.reverse();
    tripSharedController?.reverse();
    updateRxValue(SOSavailController,false);
    tripSharedController?.reverse();
    socketIns?.onsendMessage(eventName, arg);
  }

  confirmRideSocket() {
    print("confirmRideSocket");
    if (globals.socket?.connected ?? false) {
      print("confirmRideSocket connected");
      if ((confirmPopupAnimController?.status == AnimationStatus.completed)) {
        globals.tripStatus = 'created';
        globals.closeKeyBoard = false;
        confirmPopupAnimController?.reverse();
        rideStartedController(false);
        connectAnimController?.forward();
        setLocIconPositionForConfirm();
        cancelRequestLoadingController(1);
        checkInternet(sendRideReq, false);
        avoidZoom = false;
      }
    } else {
      reInitSocket();
      confirmRide();
    }
  }

  void sendRideReq() async {
    List<String> arg;
    Map<String, dynamic> dateTimeValues = getDateTimeValue();
    bool locationStringExists = true;
    _vehiclemarkerimg = '';
    for (int i = 0; i < apiLocationData.length; i++) {
      if (apiLocationData[i]["location"] == null ||
          apiLocationData[i]["location"].isEmpty ||
          apiLocationData[i]["locationLat"] == null ||
          apiLocationData[i]["locationLat"] == "0.0" ||
          apiLocationData[i]["locationLng"] == null ||
          apiLocationData[i]["locationLng"] == "0.0") {
        locationStringExists = false;
      }
    }
    if (apiLocationData.isEmpty) {
      locationStringExists = false;
    }
    if (!locationStringExists || apiLocationData.isEmpty) {
      showNoLocationDialog();
    } else {
      List<int> selectedComfortRides = [];
      if (selectedRides != null && selectedRides.length != 0) {
        selectedComfortRides = selectedRides.map((e) {
          return e.id;
        }).toList();
      }
      if (isSpecialApplied) {
        arg = [
          '{"requestStatus" : "request","data" : {'
              '"auth" : "${globals.authToken}", "promoId": ${selectedSpecialID},"userId" : "${globals.userid}","riderLocation" : "${globals.currentLocation}","riderLocationLat" : ${globals.userLat},'
              '"riderLocationLng" :${globals.userLon},"pickUpLocation" : "${locationData.first.location}",'
              '"pickUpLat" : ${locationData.first.latLng?.latitude}, "pickUpLng" : ${locationData.first.latLng?.longitude},'
              '"dropOffLocation" : "${locationData.last.location}" , "dropOffLat" : ${locationData.last.latLng?.latitude},'
              '"dropOffLng" : ${locationData.last.latLng?.longitude},"rideDistance" : ${zeroForAPISideDistanceMatrixCalculation},"rideDuration": ${zeroForAPISideDistanceMatrixCalculation} , "category" : ${selectedVehType},"deviceId" : "${globals.deviceId}","dateValue" : "${dateTimeValues["dateValue"]}","dayValue" : "${dateTimeValues["dayValue"]}","startTimeValue" : "${dateTimeValues["startTimeValue"]}","deviceType": "${globals.deviceName}","paymentType": "${globals.preferredPaymentMethod}","allowedWaitingTime" : ${2} , "rideDetails" : ${jsonEncode(apiLocationData)},'
              '"distanceType" : "${globals.distanceType}","comfortRide": ${selectedComfortRides}}}'
        ];
      } else {
        arg = [
          '{"requestStatus" : "request","data" : {'
              '"auth" : "${globals.authToken}","userId" : "${globals.userid}","riderLocation" : "${globals.currentLocation}","riderLocationLat" : ${globals.userLat},'
              '"riderLocationLng" :${globals.userLon},"pickUpLocation" : "${locationData.first.location}",'
              '"pickUpLat" : ${locationData.first.latLng?.latitude}, "pickUpLng" : ${locationData.first.latLng?.longitude},'
              '"dropOffLocation" : "${locationData.last.location}" , "dropOffLat" : ${locationData.last.latLng?.latitude},'
              '"dropOffLng" : ${locationData.last.latLng?.longitude},"rideDistance" : ${zeroForAPISideDistanceMatrixCalculation},"rideDuration": ${zeroForAPISideDistanceMatrixCalculation} , "category" : ${selectedVehType},"dateValue" : "${dateTimeValues["dateValue"]}","dayValue" : "${dateTimeValues["dayValue"]}","startTimeValue" : "${dateTimeValues["startTimeValue"]}","deviceId" : "${globals.deviceId}","deviceType": "${globals.deviceName}","paymentType": "${globals.preferredPaymentMethod}","allowedWaitingTime" : ${2} , "rideDetails" : ${jsonEncode(apiLocationData)},'
              '"distanceType" : "${globals.distanceType}","comfortRide": ${selectedComfortRides}}}'
        ];
      }

      debugPrint("onTripRequestInfo sendridereq: ${arg}");
      calledOnce = true;
      socketIns?.disconnectListen("tripRequest-${globals.userid}");
      onTripRequestInfo("tripRequest-${globals.userid}");
      socketIns?.onsendMessage("tripRequest", arg);
      if (requestExpiredTimer != null && requestExpiredTimer?.isActive) {
        requestExpiredTimer?.cancel();
      }
      int declineMinutes = 5;
      print("onTripRequestInfo expireminutes: ${globals.notificationInterval.round()} --- ${declineMinutes}");
      if(declineMinutes < globals.notificationInterval.round())
        declineMinutes = globals.notificationInterval.round()+2;

        requestExpiredTimer = Timer(Duration(minutes: declineMinutes), () {
          debugPrint("requestExpiredTimerglobals.tripStatus: ${globals.tripStatus}");
          if(globals.tripStatus == 'created') {
            globals.tripStatus = 'expired';
            onDriverNotRespond("autoCancel");
            socketIns?.disconnectListen("autoCancel-${globals.userid}");
            onReceiveNotRespond("autoCancel-${globals.userid}");
          } else {
            requestExpiredTimer?.cancel();
          }
        });

    }
  }

  onDriverNotRespond(String eventName) {
    List<String> arg = [
      '{"data" : {"auth" : "${globals.authToken}","userId" : "${globals.userid}" }}'
    ];
    socketIns?.onsendMessage(eventName, arg);
    sosIconController?.reverse();
    setDefaultLocationIconPosition();
    tripSharedController?.reverse();
    updateRxValue(SOSavailController,false);
    tripSharedController?.reverse();
    updatePadding(0);
  }

  onReceiveNotRespond(String eventName) {
    globals.socket?.on(eventName, (data) {
      debugPrint("onReceiveNotRespond: ${data}");
          if (data is Map) {
            if (data["data"]["status"] == 200 ||
                data["data"]["status"] == 400) {
              driverAvailController(false);
              sosIconController?.forward();
              setLocIconPositionForConfirm();
              vehicleCatAnimController?.reverse();
              updateRxValue(SOSavailController,true);
              connectAnimController?.reverse();
              driverInfoAnimController?.forward();

              Future.delayed(Duration(milliseconds: 5000)).then((_) {
                globals.isLoaderShow = false;
                getTripStatusOnly().then((value) {
                  if (!isUserInTrip) {
                    checkInternet(getStatusOfRide, true);
                  }
                });
              });
            }
          }

    });
  }

  cancelTripRequest() {
    Future.delayed(Duration(milliseconds: 2000)).then((_) {
      globals.isLoaderShow = false;
      getTripStatusOnly().then((value) {
        if (value?["status"] == "created") {
          List<String> arg = [
            '{"data" : {"auth" : "${globals.authToken}","userId" : "${globals.userid}" }}'
          ];
          socketIns?.onsendMessage("cancelTripRequest", arg);
          globals.tripStatus = "cancelRequest";
          socketIns?.disconnectListen("cancelTripRequest-${globals.userid}");
          tripCanceled("");
        } else {
          checkInternet( getStatusOfRide, false);
        }
      });
    });
  }


  onUserPreferenceUpdated(){
    socketIns?.disconnectListen("userPreferenceUpdated-${globals.userid}");
    globals.socket?.on("userPreferenceUpdated-${globals.userid}", (data) {
      if (data is Map) {
        debugPrint("onUserPreferenceUpdatedMSG: ${data}");
        String? langCode = data["data"]["data"]["preferredLanguage"];
        String? currency = data["data"]["data"]["preferredCurrency"];
        if(langCode !=null) {
          globals.preferredLanguage = langCode;
          globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
          EditAccountController editAccountController = Get.find();

          int selectedPos = editAccountController.languageCode.indexOf(langCode);
          if (selectedPos != -1) {
            String targetLanguage = editAccountController.languageDropDown[selectedPos];
            String targetCode = editAccountController.languageCode[selectedPos];

            editAccountController.languageDropDown.removeAt(selectedPos);
            editAccountController.languageCode.removeAt(selectedPos);

            editAccountController.languageDropDown.insert(0, targetLanguage);
            editAccountController.languageCode.insert(0, targetCode);
          }
          debugPrint("editAccountController.languageDropDown: ${editAccountController.languageDropDown}");
          debugPrint("editAccountController.languagecode: ${editAccountController.languageCode}");

          preferences.preferredLaunguage = globals.preferredLanguage;
          editAccountController.setLanguage();
          App()
              .translations
              .readJson(
              language: langCode, isUpdate: false, isOnlyDownload: false)
              .then((value) {
          Get.forceAppUpdate();
          globals.themeNotifier?.isDark = globals.isDarkTheme;
          debugPrint("onUserPreferenceUpdatedMSG:updated");
          });
        }
      }
    });
  }

  onReceiveLoginCheck(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        debugPrint("logincheckerrorMSG: ${data}");
        if (data["data"]["status"] == 200 || data["data"]["status"] == 500) {
          String deviceId = data["data"]["data"]["deviceId"].toString();
          String userType = data["data"]["data"]["userType"].toString();
          if (deviceId != globals.deviceId) {
            {
              if ((globals.authToken?.isNotEmpty ?? false) && userType == "1") {
                locationData.clear();
                  toast.show(
                    context: Get.overlayContext ?? Get.context!,
                    message: 'session_timeout_err'.tr,
                  );
                Future.delayed(const Duration(milliseconds: 1500), () {
                  setLogout();
                  dispose();
                });
              }
            }
          }
        } else if (data["data"]["status"] == 400) {
          String errorMSG = data["data"]["errorMessage"] ?? "";
          debugPrint('errorMSGlogincheck: ${errorMSG}');

          locationData.clear();
          if (errorMSG.isNotEmpty) {
            toast.show(
              context: Get.overlayContext ?? Get.context!,
              message: errorMSG,
            );
          }
          Future.delayed(const Duration(milliseconds: 1500), () {
            setLogout();
            dispose();
          });
        }
      }
    });
  }

  updatePreferredCurrency(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if(data["data"]["status"] == 200) {
          if(data["data"]["data"]["data"]["preferredCurrency"] !=null && data["data"]["data"]["data"]["preferredCurrency"] != globals.preferredCurrency){
            globals.preferredCurrency = data["data"]["data"]["data"]["preferredCurrency"];
            globals.languageUpdateController(true);
          }
        }
      }
    });
  }

  moveToSelectDropLocation() {
    socketIns?.disconnectListen("loginCheck-${globals.userid}");
    onReceiveLoginCheck("loginCheck-${globals.userid}");
    onManualBookingCreatedByAdminCheck();
    onUserPreferenceUpdated();
    socketIns?.disconnectListen("updatePreferredCurrency-${globals.userid}");
    updatePreferredCurrency("updatePreferredCurrency-${globals.userid}");
    if (!(confirmPopupAnimController?.status == AnimationStatus.completed)) {
      callSelectLocation();
    }
  }

  sendBookingLocationToDriver() {
    List<String> arg = [
      '{"data" : {'
          '"auth":"${globals.authToken}",'
          '"userId":"${globals.userid}"}}'
    ];
    if (socketIns == null)
      socketIns = SocketConnection();
    socketIns?.disconnectListen("tripStatus-${globals.userid}");
    listenBookingLocationSocket("tripStatus-${globals.userid}");
    socketIns?.onsendMessage("tripStatus", arg);
  }

  listenBookingLocationSocket(String eventName) {
    globals.socket?.on(eventName, (data) {

      if (data is Map) {
        if (data["data"]["data"]["bookingLocations"] != null &&
            data["data"]["data"]["bookingLocations"].isNotEmpty) {
          locationData.clear();

          LatLng  endlatlng = LatLng(0.0, 0.0);


        List<dynamic> bookinglocations =  reorderDropLast( data["data"]["data"]["bookingLocations"]);

          bookinglocations.asMap().entries.forEach((entry) {
            int index = entry.key;
            var element = entry.value;
            if(element["locationStatus"] == "completed"){
              EditDisableLocationsDataIndex = index+1;
            }
            debugPrint('listenBookingLocationSocketGetTripStatus:index: ${index} --- ${EditDisableLocationsDataIndex}');
            locationData.add(LocationData(
                LatLng(element["locationLat"], element["locationLng"]),
                element["location"],
                element["fieldType"],
                element["id"],
                element["locationStatus"],
                element["locationType"],
                element["locationDistanceType"]
            ));

            if(element["fieldType"].toString == 'editable'){
              endlatlng =  LatLng(element["locationLat"], element["locationLng"]);
            }
          });

          drawDestRoute(getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation)!, endlatlng);

          update(['updateBookingLocationController']);
          update(['placeSelectController']);
        }
      }
    });
  }

  List<dynamic> reorderDropLast(List<dynamic> locations) {
    final nonDrops = locations.where((loc) => loc['locationType'] != 'drop').toList();
    final drops = locations.where((loc) => loc['locationType'] == 'drop').toList();
    return [...nonDrops, ...drops];
  }

  void onTripLocationReached(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        globals.tripStatus = "locationReached";
        update(['updateBookingLocationController']);
      }
    });
  }
}