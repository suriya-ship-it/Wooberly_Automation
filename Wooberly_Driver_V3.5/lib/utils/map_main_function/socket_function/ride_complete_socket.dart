import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/toll_fee.dart';

import '../../../app/app.dart';
import '../../../app/app_routes.dart';
import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RideCompleteSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  RideCompleteSocket({required this.state});

  endRide() {
    controller.setSwipeStart(2);
    controller.getEndLoc("end").then((value) {
      if (value == "failed") {
        controller.netOffSnackbar(endRide, false);
        return;
      }
      controller.socketIns.socketConnect();
      controller.setSwipeStart(2);

      controller.tollFeeController.text = "";
      controller.socketIns.disconnectListen("tripComplete-${globals.userid}");
      receiveTripCompleted("tripComplete-${globals.userid}");
      globals.isShowMapPage = false;
      Get.to(() => TollFee(state.getLocationStatus),);

      Future.delayed(const Duration(milliseconds: 200), () {
        controller.setSwipeStart(1);
      });
    });
  }

  receiveTripCompleted(String eventName) {
    debugPrint("receiveTripCompleted:  soclet ${controller.tripStatus}");
    globals.socket?.on(eventName, (data) {
     completeRide(data);
    });
  }

  void completeRide(data) {
    debugPrint("ride complete receiveTripCompleted: ${data}");
    debugPrint("receiveTripCompleted: ${controller.tripStatus}");
    controller.checkInternet(state.graphQLFetchOnMapMainScreen!.getTripSummary, false);

    if (data is Map &&  controller.tripStatus != "completed") {
      if (data["data"]["status"] == 200) {
        controller.tripStatus = "completed";
        globals.bookingId = 0;
        controller.markerMoveIteration = 0;
        if (data["data"]["data"]["driverId"].toString() == globals.userid) {
          if (int.parse(data["data"]["data"]["paymentType"].toString()) ==
              1) {
            if (data["data"]["data"]["isSpecialTrip"]) {
              controller.totalTripAmount = double.parse(controller.getRate(
                  data["data"]["data"]["currency"],
                  data["data"]["data"]["specialTripTotalFare"]));
              controller.totalTripAmount =
                  double.parse(controller.totalTripAmount.toStringAsFixed(2));
            } else {
              controller.totalTripAmount = double.parse(controller.getRate(
                  data["data"]["data"]["currency"],
                  data["data"]["data"]["riderTotalFare"]));
              controller.totalTripAmount =
                  double.parse(controller.totalTripAmount.toStringAsFixed(2));
            }
          } else {
            if (data["data"]["data"]["isSpecialTrip"]) {
              controller.totalTripAmount = double.parse(controller.getRate(
                  data["data"]["data"]["currency"],
                  data["data"]["data"]["specialTripTotalFare"]));
              controller.totalTripAmount =
                  double.parse(controller.totalTripAmount.toStringAsFixed(2));
            } else {
              dynamic dTotal = double.parse(controller.getRate(
                  data["data"]["data"]["currency"],
                  data["data"]["data"]["driverTotalFare"]));
              dynamic baseTotal = double.parse(controller.getRate(
                  data["data"]["data"]["currency"],
                  data["data"]["data"]["baseFare"]));
              if (dTotal < baseTotal) {
                controller.totalTripAmount = double.parse(controller.getRate(
                    data["data"]["data"]["currency"],
                    data["data"]["data"]["totalFare"]));
              } else {
                controller.totalTripAmount = double.parse(controller.getRate(
                    data["data"]["data"]["currency"],
                    data["data"]["data"]["driverTotalFare"]));
              }
            }
            controller.totalTripAmount =
                double.parse(controller.totalTripAmount.toStringAsFixed(2));
          }
          controller.rideDistance = data["data"]["data"]["totalRideDistance"];
          controller.rideDuration =
          data["data"]["data"]["totalDuration"].toString().split('.')[0];
          controller.change(rxVariable: controller.rxFinalAmountController, value: controller.totalTripAmount);
          state.tripAmountController?.forward();
          controller.rxRideDetailEnabledController.value =(false);
          state.rideStartAnimController?.reverse();
          state.rideDetailAnimController?.reverse();
          state.animController?.reverse();
          controller.riderinfoview = false;
          controller.clearMap();
          if(globals.driverStatus.contains("_NotEligible"))
            controller.change(rxVariable: controller.rxOnlineStatus, value: false);
          controller.socketIns
              .disconnectListen("tripRequest-${globals.userid}");
          if (globals.socket?.connected ?? false) {
            controller.socketIns
                .disconnectListen("tripRequest-${globals.userid}");
            state.rideRequestSocket
                ?.onReceivedRideRequest("tripRequest-${globals.userid}");
          } else {
            globals.socket?.connect();
            controller.socketIns
                .disconnectListen("tripRequest-${globals.userid}");
            state.rideRequestSocket
                ?.onReceivedRideRequest("tripRequest-${globals.userid}");
          }
        }
      }
      else if (data["data"]["status"] == 400) {
        App().toast.show(
          context: state.context,
          message: data["data"]["errorMessage"],
        );
        state.closeApp = false;
        controller.rxRideDetailEnabledController.value  = false;
        controller.setDriverStatus(true);
        controller.clearMap();
      }

      App().setTripInfo_IOS("", "");
    }
  }
}