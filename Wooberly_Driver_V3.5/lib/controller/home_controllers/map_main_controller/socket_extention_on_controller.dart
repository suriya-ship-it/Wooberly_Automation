part of 'map_main_controller.dart';

extension SocketExtensionOnController on MapMainController {

  void confirmStop() {
    late int dataPosition;
    LocationData currentData;
    for (int i = 0; i < locationData.length; i++) {
      if (locationData[i].locationStatus == "pending") {
        dataPosition = i;
        break;
      }
    }
    currentData = locationData[dataPosition];
    List<String> arg = [
      '{"data" : {'
          '"auth":"${globals.authToken}",'
          '"bookingId":${bookingID},'
          '"locationDistance":${zeroForAPISideDistanceMatrixCalculation},'
          '"locationDuration":${zeroForAPISideDistanceMatrixCalculation},'
          '"location":"${currentData.location}",'
          '"locationLat":${mapLocation.latitude},'
          '"locationLng":${mapLocation.longitude},'
          '"id":${currentData.id}'
          '}}'
    ];
    debugPrint("onsendMessage: ${arg}");
    socketIns.disconnectListen("confirmStop-${globals.userid}");
    receiveConfirmStop("confirmStop-${globals.userid}", dataPosition);
    socketIns.onsendMessage("confirmStop", arg);
  }

  receiveConfirmStop(String eventName, int changingPosition) {
    globals.socket?.on(eventName, (data) async {
      if (data is Map) {
        if (data["data"]["status"] == 200) {

          await updateLocalLocationStatusArray(changingPosition);
          updateDriverPath(true, null, force: true);
          updateGoogleMap();
          setSwipeStart(1);
        } else {
          showInSnackBar(data["data"]["errorMessage"] != null
                  ? data["data"]["errorMessage"]
                  : "Something went wrong");
        }
      }
    });
  }

  updateBookingLocationToRider(String eventName) {
    List<String> arg = [
      '{"data" : {'
          '"auth":"${globals.authToken}",'
          '"userId":"${globals.userid}"}}'
    ];
    socketIns.disconnectListen("tripStatus-${globals.userid}");
    onGetUpdatedBookingLocation("tripStatus-${globals.userid}");
    socketIns.onsendMessage("tripStatus", arg);
  }

  sendTripAccepted() {
    List<String> arg = [
      '{"data" : {"auth" : "${globals.authToken}","userId" : "${globals.userid}",'
          '"riderId" : "$riderID" , "bookingId" : $bookingID  }}'
    ];

    socketIns.onsendMessage("tripAccept", arg);

    App().setTripInfo_IOS(riderID, bookingID.toString());
    setNavigationStatus(1);
  }

  sendDriverLocation(LatLng location) {
    List<String> arg = [
      '{"data" : {"auth" : "${globals.authToken}", "userId" : "${globals.userid}",'
          '"riderId" : "$riderID", "bookingId" : $bookingID, "lat" : ${location.latitude}, "lng" : ${location.longitude},"rotation" : $rotationbearing  }}'
    ];
    socketIns.onsendMessage("driverLocation", arg);
  }

  onGetUpdatedBookingLocation(String eventName) {
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["data"]["bookingLocations"] != null &&
            data["data"]["data"]["bookingLocations"].isNotEmpty) {
          debugPrint("Get.currentRoute: ongetbookinglocation: ${Get.currentRoute}");
          if(Get.currentRoute.contains('TollFee')){
            Get.back();
          }
          locationData.clear();
          LocationData? destlocationdata;
          data["data"]["data"]["bookingLocations"].forEach((element) {
            LocationData apilocationData = LocationData(
                element["id"],
                LatLng(element["locationLat"], element["locationLng"]),
                element["location"],
                element["fieldType"],
                element["locationStatus"],
                element["locationType"]);
            if( element["locationType"] == "drop")
              destlocationdata = apilocationData;
            else
              locationData.add(apilocationData);
          });
          if(destlocationdata !=null)
            locationData.add(destlocationdata!);
          setSwipeStart(1);
          polylineoldLocation = LatLng(0.0, 0.0);
          updateDriverPath(true, null, force: true);
          change(rxVariable: rxUpdateBookingLocationController, value: true);
        }
      }
    });
  }

  listenChatSocket({Function()? fun}) {
    globals.socket?.off("newMessage-$bookingID");
    globals.socket?.on("newMessage-$bookingID", (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200 &&
            lastChatTime != data["data"]["data"]["updatedAt"]) {
          if (globals.userid != data["data"]["data"]["authorId"]) {
            print("object>>>>${data["data"]["data"]}");
            if (globals.currentShowingPage == AppRoutes.APP_CHAT) {
              lastChatTime = data["data"]["data"]["updatedAt"];
              readThreadCount();
            } else {
              unreadCount = data["data"]["data"]["unReadDriverCount"];
              change(rxVariable: rxUnReadCountController, value: unreadCount);
            }
            if (fun != null) {
              fun();
          }
        }
      }
      }
    });
  }

  locationReachedSocket() {
    List<String> arg = [
      '{"data" : {"auth" : "${globals.authToken}","lang" : "${globals.preferredLanguage.value}","userId" : "${globals.userid}","riderId" : "$riderID","bookingId" : $bookingID ,"lat" : ${mapLocation.latitude},"lng" : ${mapLocation.longitude} }}'
    ];

    socketIns.socketConnect();
    receiveLocationReached("tripLocationReached-${globals.userid}");
    socketIns.onsendMessage("tripLocationReached", arg);
    socketIns.disconnectListen("tripStart-${globals.userid}");
    rideConfirmOTPEntryController.clear();
    change(rxVariable: rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
    homeViewState.rideStartSocket?.receiveTripStart("tripStart-${globals.userid}");
    homeViewState.riderCancelSocket?.receiveTripCancelled("riderCancel-${globals.userid}");
  }

  receiveLocationReached(String eventName) {
    globals.socket?.on(eventName, (data) async {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          checkInternet(getTripStatus, false);
          updateDriverPath(true, null, force: true);
          updateGoogleMap();
        } else {
          setSwipeStart(1);
          showInSnackBar(data["data"]["errorMessage"] != null
                  ? data["data"]["errorMessage"]
                  : "Something went wrong");
        }
      }
    });
  }
}