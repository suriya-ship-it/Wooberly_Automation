import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/models/select_location_model.dart';
import '../../app/app_routes.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../views/map_main_screen.dart';

class WillPopScopeFunction {
  final MapMainController _mapMainController=Get.find();


  BuildContext context;
  final HomeViewState state;

  late final GlobalKey<ScaffoldState> _scaffoldKey;

  WillPopScopeFunction(  this.context, this._scaffoldKey, this.state);

  popFunc() {
      if (_mapMainController.bookingInstructionController.value) {
      _mapMainController.bookingInstructionController(false);
    }
    else if ((_scaffoldKey.currentState!.isDrawerOpen) || globals.isDrawerOpen) {
        Get.back();
    }
    else if (_mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed) {
        _mapMainController.setLocIconPositionForCategory();
        _mapMainController.confirmPopupAnimController?.reverse();
        _mapMainController.destLocAnimController?.forward();
        _mapMainController.vehicleCatAnimController?.forward();
    }
    else if (_mapMainController.backCancelReason) {
        cancelReasonAnimReverse();
    }
    else if (_mapMainController.isVehicleCatDetailOpen) {
        _mapMainController.isVehicleCatDetailOpen = false;
      _mapMainController.vehicleCatDetailAnimController?.reverse();
      _mapMainController.isScheduleRide = false;
      _mapMainController.scheduleRideIconController(false);
      _mapMainController.scheduleRideIconController.refresh();
      }
    else if(globals.tripStatus == 'created'){

      }
    else if (_mapMainController.locationData.isNotEmpty) {
        _mapMainController.appliedCoupon = "";
      _mapMainController.selectedSpecialID = 0;
      _mapMainController.updatePadding(0.0);
      _mapMainController.vehicleCatAnimController?.reverse();
      _mapMainController.isScheduleRide = false;
      _mapMainController.scheduleRideIconController(false);
        _mapMainController.scheduleRideIconController.refresh();
      _mapMainController.lastKnownLocation = LatLng(0.0,0.0);
      _mapMainController.destLocAnimController?.forward();
      _mapMainController.setDestPlaceController("");
      _mapMainController.clearMap();
      _mapMainController.isScheduleRideConfirmed = false;
      _mapMainController.setCurrentLocation(LatLng(0.0,0.0));
      _mapMainController.isFromSchedule = false;
      _mapMainController.locationData.clear();
        Get.offAllNamed(AppRoutes.APP_HOME);
    }
    else  {
      _mapMainController.closeApp();
      Future.value(true);
    }
  }

  cancelReasonAnimReverse() {
    _mapMainController.backCancelReason = false;
    _mapMainController.selectedCancelReason = null;
    _mapMainController.updateRxValue(_mapMainController.radioListSelectController, false);
    _mapMainController.updateRxValue(_mapMainController.otherReasonSelectController,true);
    _mapMainController.otherReasonController.text = "";
  }
}