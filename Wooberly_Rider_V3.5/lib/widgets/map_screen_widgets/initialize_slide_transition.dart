import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/globals.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
class InitializeSlideTransition {
  final MapMainController mapMainController = Get.find();
  final TickerProvider tickerProvider;

  InitializeSlideTransition( this.tickerProvider);

  initialize() {
    mapMainController.confirmPopupAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));
    mapMainController.connectAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));
    mapMainController.vehicleCatAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));
    mapMainController.tripAmountController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));
    mapMainController.vehicleCatDetailAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 500));

    mapMainController.vehicleCatOffset =
        Tween<Offset>(begin: Offset(0.0, 10.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.vehicleCatAnimController!);
    mapMainController.vehicleCatDetailOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.vehicleCatDetailAnimController!);

    mapMainController.confirmOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.confirmPopupAnimController!);

    mapMainController.connectOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.connectAnimController!);
    mapMainController.tripAmountOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.tripAmountController!);

    mapMainController.driverInfoAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 500));
    mapMainController.driverInfoOffset =
        Tween<Offset>(begin: Offset(0.0, 10.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.driverInfoAnimController!);

    mapMainController.destLocAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 500));
    mapMainController.destLocOffset =
        Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.destLocAnimController!);

    mapMainController.rideConfirmOTPAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 500));
    mapMainController.rideConfirmOTPOffset =
        Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.rideConfirmOTPAnimController!);

    mapMainController.destLocAnimController?..addStatusListener((AnimationStatus status) {
      debugPrint("destLocAnimController status: ${status}");
    });

    mapMainController.driverInfoAnimController?..addStatusListener((AnimationStatus status) {
      if(status == AnimationStatus.forward){
        mapMainController.rideConfirmOTPAnimController?.forward();
      }
      debugPrint("driverInfoAnimController status: ${tripStatus} --- ${status}");
    });


    mapMainController.rideCancelledAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));
    mapMainController.rideCancelledOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.rideCancelledAnimController!);


    mapMainController.tripSharedController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));

    mapMainController.tripSharedOffset =
        Tween<Offset>(begin: Offset(0.0, 20.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.tripSharedController!);


    mapMainController.sosIconController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 200));

    mapMainController.sosIconOffset =
        Tween<Offset>(begin: Offset(-10.0, 0.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.sosIconController!);

    mapMainController.rideTypeSelectionAnimController = AnimationController(
        vsync: tickerProvider, duration: Duration(milliseconds: 350));
    mapMainController.rideTypeSelectionOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(mapMainController.rideTypeSelectionAnimController!);
  }
}