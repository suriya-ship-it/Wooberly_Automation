part of 'map_main_controller.dart';

extension RideStatusFetchOnController on MapMainController {
  Future<String> getTripStatus([String isFrom = '']) async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    Map<String, dynamic>? _review_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getTripStatus_query", null);
    if (_review_result == null) {
      return getTripStatus();
    }
    if (_review_result["GetTripStatus"]["status"] == 200) {
      if(_review_result["GetTripStatus"]["result"]["isDriverApproved"] == true && isFrom.isEmpty){
        return "isDriverViewed";
      }
      tripStatus = _review_result["GetTripStatus"]["result"]["tripStatus"];
      globals.bookingId = _review_result["GetTripStatus"]["result"]["id"];
      updateBookingViewedStatus(_review_result["GetTripStatus"]["result"]["id"],tripStatus);
      tripStatusResult = _review_result["GetTripStatus"];
      confirmationCode = _review_result["confirmationCode"].toString();
      bookingType = _review_result["GetTripStatus"]["result"]["bookingType"];
     int paymentType = _review_result["GetTripStatus"]["result"]["paymentType"];
      change(rxVariable: rxPaymentType, value: paymentType);
      riderID = _review_result["GetTripStatus"]["result"]["riderId"];
      paymentStatus = _review_result["GetTripStatus"]["result"]["paymentStatus"];
      isCashPaid = _review_result["GetTripStatus"]["result"]["isCashPaid"];

      if (selectedComfortRide != null) {
        selectedComfortRide.clear();
      }

      selectedComfortRide =
          _review_result["GetTripStatus"]["result"]["comfortRide"];
      if (_review_result["GetTripStatus"]["result"]["riderDetails"]
              ["firstName"] !=
          null)
        riderName =
            "${_review_result["GetTripStatus"]["result"]["riderDetails"]["firstName"]}";

      riderPhoto = _review_result["GetTripStatus"]["result"]["riderDetails"]
                  ["picture"] !=
              null
          ? globals.UPLOAD_URL +
              "/images/avatar/" +
              _review_result["GetTripStatus"]["result"]["riderDetails"]
                  ["picture"]
          : "";

      String countrycode = _review_result["GetTripStatus"]["result"]
          ["riderDetails"]["userData"]["phoneDialCode"];
      riderNumber = countrycode +
          _review_result["GetTripStatus"]["result"]["riderDetails"]["userData"]
              ["phoneNumber"];

      riderLoc = _review_result["GetTripStatus"]["result"]["riderLocation"];

     double driverEstimatedFare = double.parse(getRate(
          _review_result["GetTripStatus"]["result"]["currency"],
          _review_result["GetTripStatus"]["result"]["driverTotalFare"]));

      change(rxVariable: rxEstimateAmountController, value: driverEstimatedFare);

      if (tripStatus == "approved" ||
          tripStatus == "started" ||
          tripStatus == "locationReached" ||
          tripStatus == "created") {
        change(rxVariable: rxOnlineSliderController, value: false);
        globals.distanceType =
            _review_result["GetTripStatus"]["result"]["distanceType"];

        if (!globals.tripFromSocket) {
          locationData.clear();
          if (_review_result["GetTripStatus"]["result"]["bookingLocations"] != null &&
              _review_result["GetTripStatus"]["result"]["bookingLocations"].isNotEmpty) {
            LocationData? destlocationdata;
            _review_result["GetTripStatus"]["result"]["bookingLocations"].forEach((element) {
              LocationData apilocdata = LocationData(
                  element["id"],
                  LatLng(element["locationLat"], element["locationLng"]),
                  element["location"],
                  element["fieldType"],
                  element["locationStatus"],
                  element["locationType"]);
              if( element["locationType"] == "drop")
                destlocationdata = apilocdata;
              else
                locationData.add(apilocdata);
            });
            if(destlocationdata !=null)
              locationData.add(destlocationdata!);
            for (int i = 0; i < locationData.length; i++) {
              var data = locationData[i];
              if (i != 0 &&
                  data.locationStatus == "completed" &&
                  locationData[i - 1].locationStatus == "pending") {
                locationData[i - 1].locationStatus = "completed";
              }
            }
          }

          setSwipeStart(1);
          change(rxVariable: rxUpdateBookingLocationController, value: true);
          updateGoogleMap();
        }
      }

      pickUpLoc = _review_result["GetTripStatus"]["result"]["pickUpLocation"];
      dropLoc = _review_result["GetTripStatus"]["result"]["dropOffLocation"];
      bookingID = _review_result["GetTripStatus"]["result"]["id"];

      pickLat = _review_result["GetTripStatus"]["result"]["pickUpLat"];
      pickLon = _review_result["GetTripStatus"]["result"]["pickUpLng"];
      dropLat = _review_result["GetTripStatus"]["result"]["dropOffLat"];
      paymentType = _review_result["GetTripStatus"]["result"]["paymentType"];
      change(rxVariable: rxPaymentType, value: paymentType);
      dropLng = _review_result["GetTripStatus"]["result"]["dropOffLng"];
      if (tripStatus == "approved" ||
          tripStatus == "started" ||
          tripStatus == "locationReached") {
        App().setTripInfo_IOS(riderID, bookingID.toString());
      }

      if (int.parse(_review_result["GetTripStatus"]["result"]["paymentType"]
              .toString()) ==
          1) {
        //when apply promo code
        if (_review_result["GetTripStatus"]["result"]["isSpecialTrip"]) {
          totalTripAmount = double.parse(getRate(
              _review_result["GetTripStatus"]["result"]["currency"],
              _review_result["GetTripStatus"]["result"]
                  ["specialTripTotalFare"]));
          totalTripAmount = double.parse(totalTripAmount.toStringAsFixed(2));
        } else {
          totalTripAmount = double.parse(getRate(
              _review_result["GetTripStatus"]["result"]["currency"],
              _review_result["GetTripStatus"]["result"]["riderTotalFare"]));
          totalTripAmount = double.parse(totalTripAmount.toStringAsFixed(2));
        }
      } else {
        if (_review_result["GetTripStatus"]["result"]["isSpecialTrip"]) {
          totalTripAmount = double.parse(getRate(
              _review_result["GetTripStatus"]["result"]["currency"],
              _review_result["GetTripStatus"]["result"]
                  ["specialTripTotalFare"]));
          totalTripAmount = double.parse(totalTripAmount.toStringAsFixed(2));
        } else {

          totalTripAmount = double.parse(getRate(
              _review_result["GetTripStatus"]["result"]["currency"],
              _review_result["GetTripStatus"]["result"]["driverTotalFare"]));
        }
        totalTripAmount = double.parse(totalTripAmount.toStringAsFixed(2));
      }

      distanceBwStartDest = double.parse(
          "${_review_result["GetTripStatus"]["result"]["totalRideDistance"].toString()}");
      totalDuration = double.parse(
          "${_review_result["GetTripStatus"]["result"]["totalDuration"].toString()}");
      change(rxVariable: rxTotalDurationController, value: totalDuration.toString());

      int time =
          int.parse(_review_result["GetTripStatus"]["result"]["updatedAt"]);
      createdAt = time;
      if (_review_result["GetTripStatus"]["result"]["paymentType"] != null)
        paymentType = _review_result["GetTripStatus"]["result"]["paymentType"];
      change(rxVariable: rxPaymentType, value: paymentType);
      if (_review_result["GetTripStatus"]["result"]["riderDetails"]
              ["picture"] ==
          null) {
        riderImage = "";
      } else {
        riderImage = globals.UPLOAD_URL +
            "/images/avatar/" +
            _review_result["GetTripStatus"]["result"]["riderDetails"]
                ["picture"];
      }

      if (_review_result["GetTripStatus"]["result"]["riderDetails"]["userData"]
              ["overallRating"] !=
          null) {
        rating = _review_result["GetTripStatus"]["result"]["riderDetails"]
            ["userData"]["overallRating"];
        change(rxVariable: rxProfileInfoupdateController, value: true);
      } else
        rating = 0.0;
      isDriverReviewed =
          _review_result["GetTripStatus"]["result"]["isDriverReviewed"];
      isFromAdmin = _review_result["GetTripStatus"]["result"]["adminId"] != null;
      change(rxVariable: rxPictureChangeController, value: false);

      if (mapLocation == null || mapLocation == LatLng(0.0, 0.0)) {
        double lat = double.parse(_review_result["GetTripStatus"]["result"]
                ["driverDetails"]["userData"]["lat"]
            .toString());
        double lng = double.parse(_review_result["GetTripStatus"]["result"]
                ["driverDetails"]["userData"]["lng"]
            .toString());
        mapLocation = LatLng(lat, lng);
        position = [lat, lng];
      }
      return "";
    } else {
      return "something_went_wrong".tr;
    }
  }

  Future<String> getTripStatusOnly() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isLoaderShow = false;
    Map<String, dynamic>? result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getTripStatus_query", null,false);

    if (result != null) {
      if (result["GetTripStatus"]["status"] == 200) {
        if (result["GetTripStatus"]["result"] != null) {
          bookingType = result["GetTripStatus"]["result"]["bookingType"];
          tripStatus = result["GetTripStatus"]["result"]["tripStatus"];
          globals.bookingId = result["GetTripStatus"]["result"]["id"];
          confirmationCode = result["GetTripStatus"]["result"]["confirmationCode"].toString();

         double driverEstimatedFare = double.parse(getRate(
              result["GetTripStatus"]["result"]["currency"],
              result["GetTripStatus"]["result"]["driverTotalFare"]));
          change(rxVariable: rxEstimateAmountController, value: driverEstimatedFare);
          if (tripStatus == "approved" ||
              tripStatus == "started" ||
              tripStatus == "locationReached" ||
              tripStatus == "created") {
            double driverlatpos = double.parse(result["GetTripStatus"]["result"]
                    ["driverDetails"]["userData"]["lat"]
                .toString());
            double driverlngpos = double.parse(result["GetTripStatus"]["result"]
                    ["driverDetails"]["userData"]["lng"]
                .toString());
            globals.distanceType =
            result["GetTripStatus"]["result"]["distanceType"];
            locationData.clear();
            if (result["GetTripStatus"]["result"]["bookingLocations"] != null &&
                result["GetTripStatus"]["result"]["bookingLocations"].isNotEmpty) {
              LocationData? destlocationdata;
              result["GetTripStatus"]["result"]["bookingLocations"].forEach((element) {
                LocationData apilocdata = LocationData(
                    element["id"],
                    LatLng(element["locationLat"], element["locationLng"]),
                    element["location"],
                    element["fieldType"],
                    element["locationStatus"],
                    element["locationType"]);
                if( element["locationType"] == "drop")
                  destlocationdata = apilocdata;
                else
                  locationData.add(apilocdata);
              });
              if(destlocationdata !=null)
                locationData.add(destlocationdata!);
              for (int i = 0; i < locationData.length; i++) {
                var data = locationData[i];
                if (i != 0 &&
                    data.locationStatus == "completed" &&
                    locationData[i - 1].locationStatus == "pending") {
                  locationData[i - 1].locationStatus = "completed";
                }
              }
            }
          }

          if (mapLocation == null || mapLocation == LatLng(0.0, 0.0)) {
            double lat = double.parse(result["GetTripStatus"]["result"]
                    ["driverDetails"]["userData"]["lat"]
                .toString());
            double lng = double.parse(result["GetTripStatus"]["result"]
                    ["driverDetails"]["userData"]["lng"]
                .toString());
            mapLocation = LatLng(lat, lng);
          }
        } else {
          tripStatus = "aaa";
        }
      } else if (result["GetTripStatus"]["status"] == 400) {
        tripStatus = "aaa";
      } else if (result["GetTripStatus"]["status"] == 500) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
        tripStatus = "aaa";
      } else {
        tripStatus = "aaa";
      }
      return tripStatus;
    } else {
      return "null";
    }
  }

  updateBookingViewedStatus(int? bookingId,String? tripStatus) async {
    List activeBookingList = ["created","approved","locationReached","started"];
    if(bookingId != null && tripStatus != null) {
      if (!activeBookingList.contains(tripStatus)) {
        var variables = <String, dynamic>{
          "bookingId": bookingId,
        };
        Map<String, dynamic>? _loginResult = await graphQlObject
            .getMutationValues(
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


  Future<String?> getPreferredCurrency() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isLoaderShow = false;
    Map<String, dynamic>? result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getPreferredCurrency", null);

    if (result != null) {
      if(result["userAccount"]["status"] == 200) {
        if(globals.preferredCurrency != result["userAccount"]["result"]["preferredCurrency"]){
          globals.preferredCurrency = result["userAccount"]["result"]["preferredCurrency"];
          return "update";
        }
       return "";
      }else{
        return result["userAccount"]["errorMessage"];
      }
    } else {
      return "null";
    }
  }

  Future<bool?> checkIsDriverEligible() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isLoaderShow = false;
    Map<String, dynamic>? result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getPreferredCurrency", null);
    debugPrint("checkIsDriverEligible: ${result}");
    if (result != null) {
      if(result["userAccount"]["status"] == 200) {

        Map<String,dynamic> walletoptions = {};
        walletoptions.addAll(globals.driverWalletOptionController.value);
        if(
        walletoptions["isDriverEligible"] !=  result["userAccount"]["result"]["isDriverEligible"] ||
            walletoptions["walletBalance"] !=  result["userAccount"]["result"]["driverWalletBalance"] ||
            walletoptions["minimumWalletAmount"] !=  result["userAccount"]["result"]["minimumWalletAmount"]
        ){
          walletoptions["isDriverEligible"] =  result["userAccount"]["result"]["isDriverEligible"];
          walletoptions["walletBalance"] =  result["userAccount"]["result"]["driverWalletBalance"];
          walletoptions["minimumWalletAmount"] =  result["userAccount"]["result"]["minimumWalletAmount"];
          globals.driverWalletOptionController.value = walletoptions;
        }
        debugPrint("globals.driverStatus:ridestasu: ${globals.driverStatus} --- ${walletoptions} --- ${result["userAccount"]["result"]["isDriverEligible"]}");
        if(!result["userAccount"]["result"]["isDriverEligible"] && walletoptions["driverWalletOption"] =="1"){
          if(!globals.driverStatus.contains("_NotEligible"))
          globals.driverStatus = globals.driverStatus +"_NotEligible";
          else {

            debugPrint("globalsstatus: ${globals.isActive}");
            return null;
          }
        } else {
          if(globals.driverStatus.contains("_NotEligible"))
            globals.driverStatus = globals.driverStatus.replaceAll("_NotEligible", "");
          else {
            return null;
          }
        }

        debugPrint("globalsstatus -- after result: ${globals.isActive}");
       return   walletoptions["isDriverEligible"];
      }else{
        return null;
      }
    } else {
      return null;
    }
  }
}