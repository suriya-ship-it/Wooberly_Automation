part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension ApiMapMainViewModel on MapMainController {
  Future<String> getRideStatus() async {
    globals.isLoaderShow = false;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_getRideStatus ${point} --- ');

    Map<String, dynamic>? _rideResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "GetTripStatus_query", null);
    if (_rideResult != null) {

      if (_rideResult["GetTripStatus"]["status"] == 200) {
        if (_rideResult["GetTripStatus"]["result"]["isRiderApproved"] == true) {
          return "isRiderViewed";
        }

        String tripStatus =
            _rideResult["GetTripStatus"]["result"]["tripStatus"];
        updateBookingViewedStatus(
            _rideResult["GetTripStatus"]["result"]["id"],
            tripStatus,
            _rideResult["GetTripStatus"]["result"]["paymentStatus"]);
        if (tripStatus == "started" ||
            tripStatus == "approved" ||
            tripStatus == "locationReached" ||
            tripStatus == "created") {
          isSpecialApplied = false;
          selectedSpecialID = 0;
          debugPrint("locationDataridestatus: clear ${locationData}");
          locationData.clear();
          if (_rideResult["GetTripStatus"]["result"]["bookingLocations"] !=
              null) {
            if (_rideResult["GetTripStatus"]["result"]["bookingLocations"].length > 2 && tripStatus == "started") {
              ismultistopvia = true;
            }

            LocationData? destlocationdata;
            _rideResult["GetTripStatus"]["result"]["bookingLocations"].asMap().entries.forEach((entry) {
              int index = entry.key;
              var element = entry.value;
              if(element["locationStatus"] == "completed"){
                EditDisableLocationsDataIndex = index+1;
              }
              debugPrint('GetTripStatus:index: ${index} --- ${EditDisableLocationsDataIndex}');
              LocationData apilocationData = LocationData(
                  LatLng(element["locationLat"], element["locationLng"]),
                  element["location"],
                  element["fieldType"],
                  element["id"],
                  element["locationStatus"],
                  element["locationType"],
                  element["locationDistanceType"]
              );
              if( element["locationType"] == "drop")
              destlocationdata = apilocationData;
              else
              locationData.add(apilocationData);
            });
            if(destlocationdata !=null)
            locationData.add(destlocationdata!);
          }
          debugPrint("locationDataridestatus: ${locationData.first.latLng}");
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            drawRouteToDriver(true, false);
          });
        }
        tripStatusResult = _rideResult["GetTripStatus"];
        debugPrint(
            "bookingPaymentType: ${_rideResult["GetTripStatus"]["result"]["paymentType"]}");

        if (totalFare == null) {
          totalFare = double.parse(getRate(
                  _rideResult["GetTripStatus"]["result"]["currency"],
                  _rideResult["GetTripStatus"]["result"]['isSpecialTrip']
                      ? _rideResult["GetTripStatus"]["result"]
                          ["specialTripTotalFare"]
                      : _rideResult["GetTripStatus"]["result"]
                          ["riderTotalFare"]))
              .toStringAsFixed(2);
          update(['updateBookingLocationController']);
        } else {
          totalFare = double.parse(getRate(
                  _rideResult["GetTripStatus"]["result"]["currency"],
                  _rideResult["GetTripStatus"]["result"]['isSpecialTrip']
                      ? _rideResult["GetTripStatus"]["result"]
                          ["specialTripTotalFare"]
                      : _rideResult["GetTripStatus"]["result"]
                          ["riderTotalFare"]))
              .toStringAsFixed(2);
        }

        driverRating = _rideResult["GetTripStatus"]["result"]["driverDetails"]
            ["userData"]["overallRating"];
        isFromAdmin = _rideResult["GetTripStatus"]["result"]["adminId"] != null;
        socketIns?.disconnectListen(
            "riderCancel-${_rideResult["GetTripStatus"]["result"]["driverId"]}");
        onDriverCancelled(
            "riderCancel-${_rideResult["GetTripStatus"]["result"]["driverId"]}",
            "cancelledByRider");
        selectedComfortRideFromAPI.clear();
        if (_rideResult["GetTripStatus"]["result"]["comfortRide"] != null &&
            _rideResult["GetTripStatus"]["result"]["comfortRide"].length > 0) {
          _rideResult["GetTripStatus"]["result"]["comfortRide"]
              .forEach((element) {
            selectedComfortRideFromAPI.add(int.parse("$element"));
          });
        }
        paymentStatus = _rideResult["GetTripStatus"]["result"]["paymentStatus"];
        if (_updateTipsCalled &&
            tripStatus == "completed" &&
            paymentStatus == "pending") {
          finalAmountController.refresh();
          update(['paymentTypeUpdate']);
          _updateTipsCalled = false;
        }
        return "";
      }
      else if (_rideResult["GetTripStatus"]["status"] == 500) {
        return "timeout";
      } else {
        return _rideResult["GetTripStatus"]["errorMessage"];
      }
    }
    else {
      return "offline";
    }
  }

  bool get isUserInTrip => (globals.tripStatus == "approved" ||
  globals.tripStatus == "started" ||
  globals.tripStatus == "locationReached" ||(globals.tripStatus == "completed" && paymentStatus == 'pending') );

  updateBookingViewedStatus(
      int? bookingId, String? tripStatus, String? paymentStatus) async {
    List activeBookingList = [
      "created",
      "approved",
      "locationReached",
      "started"
    ];
    if (bookingId != null && tripStatus != null && paymentStatus != null) {
      if (!activeBookingList.contains(tripStatus) &&
          paymentStatus != "pending") {
        var variables = <String, dynamic>{
          "bookingId": bookingId,
        };
        Map<String, dynamic>? _loginResult =
            await graphQlObject.getMutationValues(
                graphQlObject.graphQLClientWithHeader,
                "updateBookingViewedStatus_mutation",
                variables);

        if (_loginResult?["updateBookingViewedStatus"]["status"] == 200) {
          return "";
        } else {
          return _loginResult?["updateBookingViewedStatus"]["errorMessage"];
        }
      }
    }
  }

  Future<String> userLogout() async {
    var variables = <String, dynamic>{
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };

    Map<String, dynamic>? _logout_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "user_logout", variables);
    if (_logout_result?["userLogout"]["status"] == 200) {
      graphQlObject.getGraphQlClient().dispose();
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      graphQlObject.graphQLClient.cache.store.reset();
      return "";
    } else {
      return _logout_result?["userLogout"]["errorMessage"];
    }
  }

  Future<String> getVehicleCategories(
      [bool isloadershow = false, bool isHomepage = false]) async {
    globals.isLoaderShow = (isloadershow != null);

    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? _vehicleResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "vehicle_type_query", null);

    if (_vehicleResult != null &&
        _vehicleResult["getCategories"]["status"] == 200) {
      vehicleTypeModel = vehicleModel.VehicleTypeModel.fromJson(_vehicleResult);
      getDataGetCategoriesAPi();
      return "";
    } else {
      seRideNowLoadingController(2);
      return _vehicleResult?["getCategories"]["errorMessage"];
    }
  }

  Future<String> getPromoCodeList() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    try {
      var categoryArray = <String>[];

      if (globals.isPromoForCategory) {
        if (vehicleTypeModel != null) {
          for (int i = 0;
              i < (vehicleTypeModel?.getCategories?.result?.length ?? 0);
              i++) {
            int vehicleid = vehicleTypeModel?.getCategories?.result?[i].id ?? 0;
            for (int j = 0;
                j < (tripCalculationModel?.tripCalculation?.result.length ?? 0);
                j++) {
              int tripcalculationid = tripCalculationModel?.tripCalculation?.result?[j].id ?? 0;
              if (vehicleid == tripcalculationid) {
                categoryArray.add(
                    "{\"categoryId\":${vehicleid},\"bookingFare\":${tripCalculationModel?.tripCalculation?.result?[j].totalFareForRider}}");
                break;
              }
            }
          }
        }
      }
      var scheduleFromParam;

      if (isScheduleRide && selScheduleFromDateTime != null) {
        scheduleFromParam =
            DateFormat(dateFormat).format(selScheduleFromDateTime!);
      } else {
        scheduleFromParam = null;
      }

      var variables = <String, dynamic>{
        "requestCategories": categoryArray.isEmpty ? null : "${categoryArray}",
        "currency": globals.preferredCurrency,
        "scheduledFrom": scheduleFromParam
      };
      print("===>>>---calling_variable ${json.encode(variables)}");
      Map<String, dynamic>? _promo_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getPromoCode_query",
              variables);
      if (_promo_result != null) {
        if (_promo_result["getPromoCode"]["status"] == 200) {
          promoList = GetPromoCodeModel.fromJson(_promo_result);
          if (promoList != null)
            promoResults = promoList!.getPromoCode!.result!;
          update(['filterTypeController']);
          isLoading = promoResults!.length != 0;
          debugPrint("promocode load 6");
          var tempList;
          tempList = promoList;
          for (int i = _promo_result["getPromoCode"]["result"].length - 1; i >= 0; i--) {
            if (_promo_result["getPromoCode"]["result"][i]["availableCategories"] !=null && !_promo_result["getPromoCode"]["result"][i]["availableCategories"].contains(selectedCatId)) {
              promoList?.getPromoCode?.result?.removeAt(i);
            }
            expDate = _promo_result["getPromoCode"]["result"][i]["expiryDate"];
          }
          if (promoList == null) {
            setPromoListController(false);
            return "empty promo";
          }
          setPromoListController(false);
          return "";
        } else if (_promo_result["getPromoCode"]["status"] == 400) {
          return _promo_result["getPromoCode"]["errorMessage"];
        } else {
          return "offline";
        }
      }
      return "offline";
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String?> vaildateCode() async {
    var scheduleFromDate;
    if (isScheduleRide && selScheduleFromDateTime != null) {
      scheduleFromDate =
          DateFormat(dateFormat).format(selScheduleFromDateTime!);
    } else {
      scheduleFromDate = null;
    }
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    try {
      var variables = <String, dynamic>{
        "code": couponController.text.toString().toUpperCase(),
        "scheduledFrom": scheduleFromDate
      };
      Map<String, dynamic>? _vaildateCode_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "vaildateCode_mutation",
              variables);
      if (_vaildateCode_result != null) {
        if (_vaildateCode_result["validatePromoCode"]["status"] == 200) {
          promoList = GetPromoCodeModel.fromJson(_vaildateCode_result);
          appliedCoupon = couponController.text;
          isSpecialApplied = true;
          selectedSpecialID = _vaildateCode_result["validatePromoCode"]["id"];
          seRideNowLoadingController(0);
          setSpecialPriceController(true);
          return "";
        } else if (_vaildateCode_result["validatePromoCode"]["status"] == 400) {
          return _vaildateCode_result["validatePromoCode"]["errorMessage"];
        } else {
          return "timeout";
        }
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> getTripCalculation() async {
    globals.isLoaderShow = false;
    apiLocationData.clear();
    DefaultCacheManager().emptyCache();
    for (var element in locationData) {
      apiLocationData.add({
        "locationLat": element.latLng?.latitude,
        "locationLng": element.latLng?.longitude,
        "location": element.location,
        "locationDistance": zeroForAPISideDistanceMatrixCalculation,
        "locationDuration": zeroForAPISideDistanceMatrixCalculation
      });
    }
    var selectedComfortRides = [];
    if (selectedRides != null && selectedRides.length != 0) {
      selectedComfortRides = selectedRides.map((e) {
        return e.id;
      }).toList();
    }
    var variables;
    if (isSpecialApplied) {
      variables = <String, dynamic>{
        "totalDistance": zeroForAPISideDistanceMatrixCalculation,
        'totalDuration': zeroForAPISideDistanceMatrixCalculation,
        'promoId': selectedSpecialID,
        "lat": locationData.first.latLng?.latitude ?? 0.0,
        "lng":  locationData.first.latLng?.longitude ?? 0.0,
        "dropLat":  locationData.last.latLng?.latitude ?? 0.0,
        "dropLng":  locationData.first.latLng?.longitude ?? 0.0,
        "comfortRide": selectedComfortRides,
        "rideDetails": jsonEncode(apiLocationData)
      };
    } else {
      variables = <String, dynamic>{
        "totalDistance": zeroForAPISideDistanceMatrixCalculation,
        'totalDuration': zeroForAPISideDistanceMatrixCalculation,
        "lat": locationData.first.latLng?.latitude ?? 0.0,
        "lng":  locationData.first.latLng?.longitude ?? 0.0,
        "dropLat":  locationData.last.latLng?.latitude ?? 0.0,
        "dropLng":  locationData.first.latLng?.longitude ?? 0.0,
        "comfortRide": selectedComfortRides,
        "rideDetails": jsonEncode(apiLocationData)
      };
    }

    if (!isScheduleRideIconEnable)
      variables = getDateTimeValue(variables);
    else
      variables = getDateTimeValue(variables, selScheduleFromDateTime);
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    try {
      Map<String, dynamic>? _vehicle_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "tripCalculation_mutation",
              variables);
      if (_vehicle_result != null) {
        if (_vehicle_result["tripCalculation"]["status"] == 200) {
          tripCalculationModel =
              tripCalculeModel.TripCalculationModel.fromJson(_vehicle_result);
          getDataTripCalculationAPi();
          seRideNowLoadingController(1);
          return "";
        } else {
          seRideNowLoadingController(2);
          return _vehicle_result["tripCalculation"]["errorMessage"];
        }
      } else {
        seRideNowLoadingController(2);
        return 'offline';
      }
    } on Exception catch (e) {
      seRideNowLoadingController(2);
      return "offline";
    }
  }

  Future<dynamic> getPrecautionNotification() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    try {
      Map<String, dynamic>? precautionNotification =
          await graphQlObject.getQueryValues(
              graphQlObject.graphQLClientWithHeader,
              "getPrecautionNotification",
              null);
      globals.precautionNotifications = null;
      if (precautionNotification?["getPrecautionNotification"]["status"] ==
          200) {
        globals.precautionNotifications =
            precautionNotification?["getPrecautionNotification"]["result"];

        return "";
      } else if (precautionNotification?["getPrecautionNotification"]
              ["status"] ==
          500) {
        return precautionNotification?["getPrecautionNotification"]
            ["errorMessage"];
      } else {
        return precautionNotification?["getPrecautionNotification"]
            ["errorMessage"];
      }
    } on Exception catch (e) {
      debugPrint("connection exception: ${e.toString()}");
      if (e
          .toString()
          .contains("SocketException: OS Error: Network is unreachable"))
        return "offline";
    }
  }

  Future<String> sendReview() async {
    if (bookingId == 0) await getTripStatusOnly();
    double tips = 0.0;
    if (tipsAmount.text == null) {
      tips = 0.0;
    } else if (tipsAmount.text != null && tipsAmount.text.isEmpty) {
      tips = 0.0;
    } else if (tipsAmount.text == "0" || tipsAmount.text == "0.0") {
      tips = 0.0;
    } else {
      tips = double.parse(tipsAmount.text);
    }
    var variables = <String, dynamic>{
      "userId": driverId,
      "bookingId": bookingId,
      "authorId": globals.userid,
      "ratings": userRating,
      "reviewContent": "",
      "amount": tips,
      "paymentType": globals.preferredPaymentMethod,
      "currency": globals.preferredCurrency
    };
    try {
      Map<String, dynamic>? _review_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "WriteReviews_mutation",
              variables);
      tipsAmount.text = "";
      updatePadding(0);
      if (_review_result != null) {
        if (_review_result["WriteReviews"]["status"] == 200) {
          return "";
        } else {
          return _review_result["WriteReviews"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> updateTips([rideCurrency]) async {
    double tips = 0.0;
    if (tipsAmount.text == null) {
      tips = 0.0;
    } else if (tipsAmount.text != null && tipsAmount.text.isEmpty) {
      tips = 0.0;
    } else if (tipsAmount.text == "0" || tipsAmount.text == "0.0") {
      tips = 0.0;
    } else {
      tips = double.parse(tipsAmount.text);
    }
    var variables = <String, dynamic>{
      "userId": driverId,
      "bookingId": bookingId,
      "amount": tips,
      "paymentType": rideCurrency ?? globals.preferredPaymentMethod,
      "currency": globals.preferredCurrency
    };
    try {
      Map<String, dynamic>? _review_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "updateTip_mutation",
              variables);

      if (_review_result != null) {
        if (_review_result["updateTip"]["status"] == 200) {
          _updateTipsCalled = true;
          return "";
        } else {
          return _review_result["updateTip"]["errorMessage"];
        }
      } else {
        return 'something_went_wrong'.tr;
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> shareLiveLocation(
      String driverName, String vehicleNumber, String currentLocation) async {
    var variables = <String, dynamic>{
      "driverName": driverName,
      "vecihleNumber": vehicleNumber,
      "currentLocation": currentLocation,
    };
    try {
      Map<String, dynamic>? _shareLiveLocation =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "sharelivelocation_mutation",
              variables);
      print(
          "_shareLiveLocation---> ${_shareLiveLocation?["shareLiveLocations"]["status"]}---$variables");
      if (_shareLiveLocation != null) {
        if (_shareLiveLocation["shareLiveLocations"]["status"] == "200") {
          return "success";
        } else {
          return _shareLiveLocation["shareLiveLocations"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> getCancelReason() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "userType": 1,
    };
    try {
      Map<String, dynamic>? getCancelReasonResult =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getCancelReason_query",
              variables);
      if (getCancelReasonResult != null) {
        if (getCancelReasonResult["getCancelReason"]["status"] == 200) {
          if (cancelReasonList != null) {
            cancelReasonList.clear();
          }
          getCancelReasonModel =
              GetCancelReasonModel.fromJson(getCancelReasonResult);
          for (int i = 0;
              i < getCancelReasonModel!.getCancelReason!.result!.length;
              i++) {
            if (getCancelReasonModel!.getCancelReason!.result![i].isActive!) {
              Map<String, String> temp = new HashMap();
              temp['id'] =
                  getCancelReasonModel!.getCancelReason!.result![i].id!;
              temp['reason'] =
                  getCancelReasonModel!.getCancelReason!.result![i].reason!;
              cancelReasonList.add(temp);
            }
          }
          Map<String, String> temp2 = new HashMap();
          temp2['id'] = "0";
          temp2['reason'] = 'other'.tr;
          cancelReasonList.add(temp2);
          return "";
        } else if (getCancelReasonResult["getCancelReason"]["status"] == 400) {
          return getCancelReasonResult["getCancelReason"]["errorMessage"];
        } else {
          return "timeout";
        }
      } else {
        return "timeout";
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> updateProfileInfo(String fieldName, String fieldValue) async {
    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };
    debugPrint("updateProfileInfo: ${variables}");

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
    if (_login_result?["userUpdate"]["status"] == 200) {
      if (fieldValue == "auto") {
        globals.theme = 1;
        var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        globals.isDarkTheme = brightness == Brightness.dark;
      } else if (fieldValue == "light") {
        globals.theme = 2;
        globals.isDarkTheme = false;
      } else {
        globals.theme = 3;
        globals.isDarkTheme = true;
      }
      globals.themeNotifier?.isDark = globals.isDarkTheme;
      return "";
    } else if (_login_result?["userUpdate"]["status"] == 500) {
      return "timeout";
    } else {
      return _login_result?["userUpdate"]["errorMessage"];
    }
  }

  Future<String?> getCurrencyRates() async {
    if (graphQlObject.graphQLClient != null) {
      try {
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClient, "getCurrencyRates_query", null);

        if (_currency_rates?["currency"]["status"] == 200) {
          globals.currencyRates =
          _currency_rates?["currency"]["result"]["rates"];
          return "";
        }
      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getCurrencyRates();
        });
      }
    }
  }

  Future<String> getPaymentMethods() async {
    if (graphQlObject.graphQLClient != null) {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      try {
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClientWithHeader,
                "getPaymentMethods_Query",
                null);

        if (_currency_rates != null &&
            _currency_rates["getPaymentMethods"]["status"] == 200) {
          globals.paymentMethods?.value = [];
          for (dynamic paymentItem in _currency_rates["getPaymentMethods"]
              ["results"]) {
            if (paymentItem is Map<String, dynamic>) {
              globals.paymentMethods?.add(paymentItem["paymentType"]);
            }
          }

          if (!(globals.paymentMethods
                      ?.contains(globals.preferredPaymentMethod) ??
                  true) ||
              (globals.preferredPaymentMethod == 4 && Platform.isIOS)) {
            await updatepaymentMethod(globals.paymentMethods?[0] ?? 0);
          }

          if (!(globals.paymentMethods
                  ?.contains(globals.preferredPaymentMethod) ??
              true)) {
            globals.selectedPaymentType.value = globals.paymentMethods![0];
          }

          return "";
        } else {
          return "offline";
        }
      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getPaymentMethods();
          return "offline";
        });
      }
    } else {
      return "offline";
    }
    return "offline";
  }

  Future<Map<String, dynamic>?> getTripStatusOnly() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic> map = Map<String, dynamic>();
    Map<String, dynamic>? _tripStatus = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "tripStatus_query", null);
    if (_tripStatus != null) {
      if (_tripStatus["GetTripStatus"]["status"] == 200) {
        String tripStatus = _tripStatus["GetTripStatus"]["result"]["tripStatus"];
        bookingId = _tripStatus["GetTripStatus"]["result"]["id"];
        paymentStatus = _tripStatus["GetTripStatus"]["result"]["paymentStatus"];
        globals.tripStatus =tripStatus;

        map["status"] = tripStatus;
        map["id"] = bookingId;
        return map;
      }
      return map;
    } else {
      return null;
    }
  }

  Future<String> createScheduleBooking() async {
    int scheduleFromTimeStamp =
        ((selScheduleFromDateTime?.toUtc().millisecondsSinceEpoch ?? 0) / 1000)
            .round();
    int scheduleToTimeStamp =
        ((selScheduleToDateTime?.toUtc().millisecondsSinceEpoch ?? 0) / 1000)
            .round();

    var selectedComfortRides = [];
    if (selectedRides != null && selectedRides.length != 0) {
      selectedComfortRides = selectedRides.map((e) {
        return e.id;
      }).toList();
    }

    if(globals.deviceId.isEmpty){
     String? token = await FirebaseService.getFcmToken();
        globals.deviceId = token ?? "";
    }
    var variables = <String, dynamic>{
      "riderLocation":
          globals.currentLocation.value,
      "riderLocationLat": globals.userLat,
      "riderLocationLng": globals.userLon,
      "pickUpLocation": locationData.first.location,
      "pickUpLat": locationData.first.latLng?.latitude,
      "pickUpLng": locationData.first.latLng?.longitude,
      "dropOffLocation": locationData.last.location,
      "dropOffLat":  locationData.last.latLng?.latitude,
      "dropOffLng": locationData.last.latLng?.longitude,
      "rideDistance": zeroForAPISideDistanceMatrixCalculation,
      "rideDuration": zeroForAPISideDistanceMatrixCalculation,
      "category": selectedCatId,
      "deviceId": globals.deviceId,
      "deviceType": globals.deviceName,
      "paymentType": globals.preferredPaymentMethod,
      "promoId": selectedSpecialID,
      "scheduleFrom": scheduleFromTimeStamp,
      "scheduleTo": scheduleToTimeStamp,
      "distanceType":
          globals.distanceType != null && globals.distanceType.isNotEmpty
              ? globals.distanceType
              : "mile",
      "comfortRide": selectedComfortRides
    };

    variables = getDateTimeValue(variables, selScheduleFromDateTime);
    Map<String, dynamic>? scheduleResult =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "createScheduleBookingMutation",
            variables);
    if (scheduleResult != null) {
      if (scheduleResult["createScheduleBooking"]["status"] == 200) {
        if (globals.socket?.connected ?? false) {
          socketIns?.disconnectListen("tripRequest-${globals.userid}");
          onTripRequestInfo("tripRequest-${globals.userid}");
        } else {
          reInitSocket();
          socketIns?.disconnectListen("tripRequest-${globals.userid}");
          onTripRequestInfo("tripRequest-${globals.userid}");
        }
        updatePadding(0);
        couponController.clear();
        selectedSpecialID = null;
        isSpecialApplied = false;
        return "";
      } else {
        return scheduleResult["createScheduleBooking"]["errorMessage"];
      }
    } else {
      return "offline";
    }
  }

  Future<String> sendMessage(String message) async {
    var variables = <String, dynamic>{
      "bookingId": bookingId,
      "message": message,
    };
    try {
      globals.isLoaderShow = false;
      Map<String, dynamic>? msgResult = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "createThreadMutation",
          variables);
      if (msgResult != null) {
        if (msgResult["createThread"]["status"] == 200) {
          return "";
        } else {
          return msgResult["createThread"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> getAllThreads(int pageCount) async {
    var variables = <String, dynamic>{
      "bookingId": bookingId,
      "currentPage": pageCount
    };
    try {
      Map<String, dynamic>? threadResult =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getAllThreads",
              variables);
      if (threadResult != null) {
        if (threadResult["getAllThreadItems"]["status"] == 200) {
          allThreadsResult = ALLThreads.fromJson(threadResult);
          debugPrint(
              "getallthreadresult: ${threadResult["getAllThreadItems"]["result"]}");
          debugPrint(
              "getallthreadresult:globals.authToken ${globals.authToken}");
          threadItems = allThreadsResult!.getAllThreadItems!;
          if (threadItems!.result!.threadItems != null &&
              threadItems!.result!.threadItems!.length > 0) {
            threadItems!.result!.threadItems!.forEach((element) {
              if (threadItems!.result!.userDetails!.profile!.picture != null) {
                if (globals.userid != element.authorId) {
                  if (driverPhoto !=
                      globals.UPLOAD_URL +
                          "/images/avatar/" +
                          threadItems!.result!.userDetails!.profile!.picture!) {
                    driverPhoto = globals.UPLOAD_URL +
                        "/images/avatar/" +
                        threadItems!.result!.userDetails!.profile!.picture!;
                    update(['pictureChangeController']);
                  }
                }
              } else {
                driverPhoto = "";
                update(['pictureChangeController']);
              }
            });
          }
          driveraiPrefLang = threadItems?.result?.userDetails?.profile?.aiPreferredLanguage ?? '';
          return "";
        } else {
          return "null";
        }
      } else if (threadResult?["getAllThreadItems"]["status"] == 400) {
        if (threadResult?["getAllThreadItems"]["errorMessage"] != null) {
          return threadResult?["getAllThreadItems"]["errorMessage"];
        } else {
          return 'something_went_wrong'.tr;
        }
      } else {
        return 'something_went_wrong'.tr;
      }
    } on Exception catch (e) {
      return "Offline";
    }
  }

  Future<String> getUnreadThreadCount() async {
    var variables = <String, dynamic>{"bookingId": bookingId};
    try {
      Map<String, dynamic>? result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "getUnreadThreadCount",
          variables);
      if (result != null) {
        if (result["getUnreadThreadCount"]["status"] == 200) {
          listenChatSocket(bookingId);
          unreadCount = result["getUnreadThreadCount"]["count"];
          return "";
        } else if (result["getUnreadThreadCount"]["status"] == 400) {
          unreadCount = 0;
          return "";
        } else {
          return 'something_went_wrong'.tr;
        }
      } else {
        return 'something_went_wrong'.tr;
      }
    } on Exception catch (e) {
      return "Offline";
    }
  }

  Future<String?> readThreadCount() async {
    var variables = <String, dynamic>{"bookingId": bookingId};
    try {
      globals.isLoaderShow = false;
      Map<String, dynamic>? result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "readThreadMutation",
          variables);

      if (result != null) {
        if (result["readThread"]["status"] == 200 ||
            result["readThread"]["status"] == 400) {
          unreadCount = 0;
          update(['unReadCountController']);
          return "";
        } else {
          return 'something_went_wrong'.tr;
        }
      } else {
        unreadCount = 0;
        update(['unReadCountController']);
      }
    } on Exception catch (e) {
      return "Offline";
    }
  }

  Future<String> updateStop(List<dynamic> data, bool isLocationChanged) async {
    if (bookingId == 0) await getTripStatusOnly();
    var variables = <String, dynamic>{
      "bookingId": bookingId,
      "isNotify": isLocationChanged,
      "distanceType":
          globals.distanceType != null && globals.distanceType.isNotEmpty
              ? globals.distanceType
              : "mile",
      "data": jsonEncode(data)
    };

    debugPrint("updateStop location: ${jsonEncode(data)}");
    debugPrint("updateStop location: ${variables}");
    try {
      Map<String, dynamic>? result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader, "updateStop", variables);
      if (result != null) {
        if (result["updateStop"]["status"] == 200) {
          return "";
        } else if (result["updateStop"]["status"] == 400) {
          return result["updateStop"]["errorMessage"] != null
              ? result["updateStop"]["errorMessage"]
              : 'something_went_wrong'.tr;
        } else {
          return 'something_went_wrong'.tr;
        }
      } else {
        return "";
      }
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String> confirmPayment(
      int bookingId, String paymentIntentSecret) async {
    return confirmPaymentIntent(bookingId, paymentIntentSecret);
  }

  Future<String> confirmPaymentIntent(
      int bookingId, String paymentIntentSecret) async
  {
    Stripe.publishableKey = globals.stripePublishableKey;
    Stripe.urlScheme = 'stripesdk';
    await Stripe.instance.applySettings();

    final paymentIntent =
        await Stripe.instance.retrievePaymentIntent(paymentIntentSecret);
    var variables = <String, dynamic>{
      "paymentIntentId": paymentIntent.id,
      "cardLastFour": globals.cardLastFour.toString(),
      "currency": paymentIntent.currency,
    };
    debugPrint("confirmPaymentIntent: ${variables}");
    Map<String, dynamic>? _confirmpayment_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "confirmPaymentIntent",
            variables);

    if (_confirmpayment_result?["confirmPaymentIntent"]["status"] == 200) {
      try {
        debugPrint("confirmPayment: ${paymentIntentSecret}");

        final updatedPaymentIntentSecret =
            _confirmpayment_result?["confirmPaymentIntent"]
                    ["paymentIntentSecret"] ??
                paymentIntentSecret;
        final updatedPaymentIntent = await Stripe.instance
            .retrievePaymentIntent(updatedPaymentIntentSecret);
        final paymentMethodId = updatedPaymentIntent.paymentMethodId;

        final paymentIntent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: updatedPaymentIntentSecret,
          data: paymentMethodId != null && paymentMethodId.isNotEmpty
              ? PaymentMethodParams.cardFromMethodId(
                  paymentMethodData: PaymentMethodDataCardFromMethod(
                    paymentMethodId: paymentMethodId,
                  ),
                )
              : null,
        );

        var variables = <String, dynamic>{
          "bookingId": bookingId,
          "paymentIntentId": paymentIntent.id
        };

        debugPrint("confirmPayment:variables  ${variables}");
        Map<String, dynamic>? result = await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "confirmPayment_mutation",
            variables);
        if (result == null) {
          return 'something_went_wrong'.tr;
        }
        return "";
      } on StripeException catch (e) {
        if (e.error.code == FailureCode.Canceled) {
          return "cancelled";
        }
        debugPrint(
            "stripe confirm: ${e.error.localizedMessage ?? e.error.message}");
        return "exception";
      } catch (e) {
        debugPrint("stripe confirm: ${e}");
        return "exception";
      } finally {
        try {
          await Stripe.instance.resetPaymentSheetCustomer();
        } catch (e) {
          debugPrint("stripe reset payment sheet customer: ${e}");
        }
      }
    } else {
      return _confirmpayment_result?["confirmPaymentIntent"]["errorMessage"] ??
          'something_went_wrong'.tr;
    }
  }

  Future<String?> getPreferredCurrency() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isLoaderShow = false;
    Map<String, dynamic>? result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getPreferredCurrency", null);

    if (result != null) {
      if (result["userAccount"]["status"] == 200) {
        if (globals.preferredCurrency !=
            result["userAccount"]["result"]["preferredCurrency"]) {
          globals.preferredCurrency =
              result["userAccount"]["result"]["preferredCurrency"];
          return "update";
        }
        return "";
      } else {
        return result["userAccount"]["errorMessage"];
      }
    } else {
      return "null";
    }
  }

  Future<String> getNearestDriversCategory(
      double lat, double lng, bool isHomePage) async {
    globals.isLoaderShow = isHomePage;
    PrimaryScaffold.avoidLoader.value = !isHomePage;
    var selectedComfortRides = [];

    if (!isHomePage) {
      if (selectedRides != null && selectedRides.length != 0) {
        selectedComfortRides = selectedRides.map((e) {
          return e.id;
        }).toList();
      }
      globals.setButtonIdle();
    }

    var variables = <String, dynamic>{
      "lat_val": lat,
      "lng_val": lng,
      "comfortRide": isHomePage ? [] : selectedComfortRides
    };
    try {
      Map<String, dynamic>? _nearDriversCategory =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getNearestDriversCategory_query",
              variables);
      nearDriverErrMsg = null;
      if (_nearDriversCategory != null) {
        if (_nearDriversCategory["getNearestDriversCategory"]["status"] ==
            200) {
          nearestDriversCategory = null;
          HomeMarkersMap = <MarkerId, Marker>{};
          nearestDriversCategory =
              NearestDriversCategory.fromJson(_nearDriversCategory);
          nearestDriversCategory?.getNearestDriversCategory?.result
              ?.forEach((result) {
            result.location?.forEach((location) {
              lastNearestDriverEmail = location.email;
            });
          });
          nearestDriversCategory?.getNearestDriversCategory?.result
              ?.forEach((result) {
            if (isHomePage) {
              result.location?.forEach((location) {
                debugPrint("nearlocation: ${location}");
                setValueOnHomeMarker(
                  URL: result.categoryImage != null
                      ? globals.UPLOAD_URL +
                          "/images/category/" +
                          (result.categoryMarkerImage ?? "")
                      : '',
                  latLng: LatLng(location.lat ?? 0.0, location.lng ?? 0.0),
                  categoryId: "${location.email}",
                );
              });
            } else {
              if (result.location?.isNotEmpty ?? false) {
                getDataNearestDriverApi(result);
              }
            }
          });
          return "";
        } else {
          nearDriverErrMsg =
              _nearDriversCategory["getNearestDriversCategory"]["errorMessage"];
          debugPrint(
              'nearDriverErrMsg: ${_nearDriversCategory["getNearestDriversCategory"]["errorMessage"]}');
          seRideNowLoadingController(2);
          updatePadding(220);
          return "offline";
        }
      }
      seRideNowLoadingController(2);
      return "offline";
    } on Exception catch (e) {
      seRideNowLoadingController(2);
      return "offline";
    }
  }

  getDataGetCategoriesAPi() {
    nearestDriversCategoryList.clear();
    vehicleTypeModel?.getCategories?.result?.forEach((categories) {
      int index = nearestDriversCategoryList
          .indexWhere((nearestDriverID) => nearestDriverID.id == categories.id);
      if (index != -1) {
        int index = nearestDriversCategoryList.indexWhere(
            (nearestDriverID) => nearestDriverID.id == categories.id);
        nearestDriversCategoryList[index] = nearestDriversCategoryList[index]
            .copyWith(
                id: categories.id,
                categoryName: categories.categoryName,
                capacity: categories.capacity,
                isActive: categories.isActive,
                categoryMarkerImage: categories.categoryMarkerImage,
                categoryImage: categories.categoryImage);
      } else {
        nearestDriversCategoryList.add(getDriversWithCategoryAndPrice(
            id: categories.id,
            categoryName: categories.categoryName,
            capacity: categories.capacity,
            isActive: categories.isActive,
            categoryMarkerImage: categories.categoryMarkerImage,
            categoryImage: categories.categoryImage));
      }
    });
  }

  getDataNearestDriverApi(var result) {
    int index = nearestDriversCategoryList
        .indexWhere((nearestDriverID) => nearestDriverID.id == result.id);
    if (index != -1) {
      nearestDriversCategoryList[index] = nearestDriversCategoryList[index]
          .copyWith(
              id: result.id ?? 0,
              lat: result.location[0].lat,
              lng: result.location[0].lng);
    }
  }

  getDataTripCalculationAPi() async {
    Set<int> updatedIds = {};

    tripCalculationModel?.tripCalculation?.result.forEach((tripCalculation) {
      int index = nearestDriversCategoryList.indexWhere(
          (nearestDriverID) => nearestDriverID.id == tripCalculation.id);
      if (index != -1) {
        nearestDriversCategoryList[index] =
            nearestDriversCategoryList[index].copyWith(
          id: tripCalculation.id,
          convertCurrency: tripCalculation.convertCurrency.toString(),
          totalFareForRider:
              double.parse(tripCalculation.totalFareForRider.toString()),
          basePrice: double.parse(tripCalculation.basePrice.toString()),
          minutePrice: double.parse(tripCalculation.minutePrice.toString()),
          unitPrice: double.parse(tripCalculation.unitPrice.toString()),
          waitingFare: double.parse(tripCalculation.waitingFare.toString()),
          specialTripTotalFare:
              double.parse(tripCalculation.specialTripTotalFare.toString()),
          driverReachDuration: tripCalculation.durationToReachRider,
        );
        updatedIds.add(tripCalculation.id);
      }
    });
    nearestDriversCategoryList = nearestDriversCategoryList
        .where((element) => updatedIds.contains(element.id))
        .toList();
  }
}