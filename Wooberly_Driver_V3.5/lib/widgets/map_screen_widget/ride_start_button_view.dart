import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:get/get.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';
import '../confirm_slider.dart';

class RideStartButtonView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideStartButtonView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<RideStartButtonView> createState() => _RideStartButtonViewState();
}

class _RideStartButtonViewState extends State<RideStartButtonView>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: showTripStart(),
    );
  }

  showTripStart() {
    return GetBuilder(
      init: widget.controller,
        id: widget.controller.rxSwipeStartController.id,
        builder: (val) {
          String driverIn = getButtonTripStatus();
          return SlideTransition(
            position: widget.homeViewState.rideStartOffset!,
            child: Obx(() {
              double bottompadding = widget.controller.rxMapPaddingController.value != 0.0 ?
              widget.controller.rxMapPaddingController.value :
              widget.homeViewState.bottomSheetHeight;
              return Padding(
                padding: EdgeInsetsDirectional.only(
                    top: 20.0,
                    start: 20.0,
                    end: 20.0,
                    bottom: bottompadding + 20),
                child: widget.controller.rxSwipeStartController.value != 0
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_DARK,
                          borderRadius:
                          BorderRadius.all(Radius.circular(8))),
                      width: Get.width,
                      height: 56,
                      margin: const EdgeInsetsDirectional.only(bottom: 10),
                      child: widget.controller.rxSwipeStartController.value == 1
                          ? ConfirmationSlider(
                          height: 56,
                          width: Get.width - 40,
                          text: driverIn == "stop"
                              ? confirm_stop.tr
                              : (driverIn == "pickup" &&
                              widget.controller.tripStatus != "locationReached" &&
                              widget.controller.tripStatus != "started")
                              ? btn_Location.tr
                              : driverIn == "pickup" &&
                              widget.controller.tripStatus != "started"
                              ? btn_start.tr
                              : btn_end.tr,
                          onConfirmation: () async{
                            bool isLocationEnable = await  widget.controller.isLocationPermissionsEnabled();
                            debugPrint("isLocationDisable: ${isLocationEnable} --- ${widget.homeViewState.locationSubscription}");
                            if(!isLocationEnable) {
                              widget.homeViewState.showlocationDialog();
                              return;
                            }

                              widget.controller
                                  .checkInternet(() {}, true)
                                  .then((netconnect) {
                                if (netconnect) {
                                  if (globals.socket?.connected ?? false) {
                                    if (driverIn == "stop") {
                                      widget.controller
                                          .setSwipeStart(2);
                                      widget.homeViewState
                                          .internetCheckOnMapMainScreen
                                          ?.checkInternetTrackLoc(
                                          "confirmStop");
                                    } else if (driverIn ==
                                        "pickup" &&
                                        widget.controller.tripStatus != "locationReached" &&
                                        widget.controller.tripStatus != "started") {
                                      widget.controller.setSwipeStart(2);
                                      widget.controller.mapUtils.originLoc = LatLng(0.0, 0.0);
                                      widget.controller.mapUtils.destinationLoc = LatLng(0.0, 0.0);
                                      widget.homeViewState.internetCheckOnMapMainScreen?.checkInternetTrackLoc("locationReached");
                                    } else if (driverIn == "pickup") {
                                      widget.controller.setSwipeStart(2);
                                      widget.controller.getTripStatusOnly().then((value) {
                                        if (value != 'completed' && value != "cancelledByRider") {
                                          widget.homeViewState.internetCheckOnMapMainScreen?.checkInternetTrackLoc("startrideclick");
                                          if (widget.homeViewState.singleClick)
                                            Get.back();
                                        } else if (value == "cancelledByRider") {
                                          widget.homeViewState.socketConnectionOnMapMainScreen?.getTripStatus();
                                        }
                                      });
                                    } else {
                                      if (widget.controller.tripStatus != "completed") {
                                        widget.homeViewState.internetCheckOnMapMainScreen?.checkInternetTrackLoc("endrideclick");
                                        if (widget.homeViewState.singleClick)
                                          Get.back();
                                      }
                                    }
                                  } else {
                                    widget.controller.netOffSnackbar(() {
                                      widget.homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
                                    }, false);
                                  }
                                }
                              });

                          })
                          : Center(
                            child: SizedBox(
                              height: 15.0,
                              width: 15.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                backgroundColor: AppColors
                                    .PRIMARY_COLOR_DARK,
                                valueColor:
                                new AlwaysStoppedAnimation<
                                    Color>(AppColors.PRIMARY_COLOR_WHITE),
                              ),
                            ),
                          ),
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              );
            })
          );
        });
  }

  String getButtonTripStatus() {
    String tripDriverIn = "";

    for (int i = 0; i < widget.controller.locationData.length; i++) {
      var data = widget.controller.locationData[i];
      if (i != 0 &&
          data.locationStatus == "completed" &&
          widget.controller.locationData[i - 1].locationStatus == "pending") {
        widget.controller.locationData[i - 1].locationStatus = "completed";
      }
    }

    for (int i = 0; i < widget.controller.locationData.length; i++) {
      var data = widget.controller.locationData[i];
      tripDriverIn = data.locationType;
      if (data.locationStatus == "pending") {
        break;
      }
    }
    return tripDriverIn;
  }
}