import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/map_utils.dart';

import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class RideStartSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  RideStartSocket({required this.state});


  sendTripStarted() {
    String? enteredcode = controller.rideConfirmOTPEntryController.text;
    if( globals.isEnableOTP &&  enteredcode== '0000'){
      if(controller.confirmationCode.toString() != "1234"){
        enteredcode = '1234';
      }else{
        enteredcode = '1235';
      }
    }
    if(!globals.isEnableOTP || controller.isFromAdmin)
      enteredcode = null;

    receiveTripStart("tripStart-${controller.riderID}");
    List<String> arg = [
      '{"data" : {"auth": "${globals.authToken}", "userId" : "${globals.userid}", "confirmationCode" : ${ globals.isEnableOTP ? enteredcode : 0},'
          '"riderId" : "${controller.riderID}", "bookingId" : ${controller.bookingID} }}'
    ];
    print(">>>>>>>>>>>>>>>><<<<<<<<<<<${arg}");
    controller.socketIns.onsendMessage("tripStart", arg);
    controller.setNavigationStatus(2);

  }

  receiveTripStart(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) async {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      if (data is Map && controller.tripStatus == 'locationReached') {
        print(">>>>>>>>>>>>>>>><<<<<<<<<<<${data["data"]}");
        if (data["data"]["status"] == 400) {
          if (data["data"]["data"] != null) {
            String status = data["data"]["data"]["tripStatus"];
            if (status.compareTo("started") == 0) {
              controller.showInSnackBar( data["data"]["errorMessage"]);
              controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.Active);
            } else if (status.compareTo("cancelledByRider") == 0) {
              controller.rideConfirmOTPEntryController.clear();
              controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
            } else if (status.compareTo("cancelledByDriver") == 0) {
              controller.rideConfirmOTPEntryController.clear();
              controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
              controller.clearMap();
              controller.riderinfoview = false;
              controller.rxRideDetailEnabledController.value =(false);
              state.rideDetailAnimController?.reverse();
              state.animController?.reverse();
              state.rideStartAnimController?.reverse();
              controller.setStatus(true);
            } else if (status.compareTo("completed") == 0) {
              state.rideFetchAnimController?.reverse();
              if (!controller.riderinfoview) {
                state.animController?.reverse();
              }
              controller.clearMap();
              controller.riderinfoview = false;
              controller.rxRideDetailEnabledController.value =(false);
              state.rideDetailAnimController?.reverse();
              state.animController?.reverse();
              state.rideStartAnimController?.reverse();
              state.rideStartAnimController?.reverse();
              controller.setStatus(true);
            }
          } else {
            controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.Active);
            controller.showInSnackBar(data["data"]["errorMessage"]);
          }
        }
        else {
          await controller.updateLocalLocationStatusArray(0);
          controller.setSwipeStart(1);
          controller.change(rxVariable: controller.rxTripstartedResController, value: true);
          controller.markerMoveIteration = 0;
          controller.rideConfirmOTPEntryController.clear();
          controller.change(rxVariable: controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);

          controller.getEndLoc("start");
          if (controller.tripStatus != "started") {
            controller.tripStatus = "started";
            controller.setSwipeStart(1);
            state.rideStartAnimController?.forward();
          } else {
            controller.change(rxVariable: controller.rxTripstartedResController, value: false);
          }
          await controller.updateDriverPath(true, null, force: true);
          controller.updateGoogleMap();
        }
      }
    });
  }
}