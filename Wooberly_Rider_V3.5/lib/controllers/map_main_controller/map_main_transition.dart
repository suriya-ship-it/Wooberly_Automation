part of 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

extension TransitionMapMainViewModel on MapMainController{


  ValueListenable<int> getSelectedCabController() => selectedCabController;
  void setTotalFareController(dynamic v) {
    debugPrint("setTotalFareController: ${v}");
    totalFareController(double.tryParse(v.toString()));
  }

  void setDestPlaceController(String v) {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_setDestPlaceController ${point} --- ');
    destPlaceController.value = v;
    selectedPlace.value = v;
    debugPrint("getUserLocationName: ${lastKnownLocation} --- ${v}");
   // WidgetsBinding.instance.addPostFrameCallback((_) {
      update(['destPlaceController']);
   // });
  }

  void refreshCouponCodeController() {
    update(['CouponCodeController']);
  }

  void setSpecialPriceController(bool v) {
    final stack=StackTrace.current.toString().split('\n')[1];
    rideNowLoadingController.refresh();
  }

  void setPromoListController(bool v) {
    promoListController(v);
    update(['promoListController']);
  }

  void seRideNowLoadingController(int v) {
    if (v == 0 && tripCalculationModel != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (tripCalculationModel != null) seRideNowLoadingController(1);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      rideNowLoadingController(v);
      rideNowLoadingController.refresh();
    });
  }

  setLocIconPositionForCategory(){
    if(isScheduleRideIconEnable){
      scheduleRideIconController(true);
      scheduleRideIconController.refresh();
    }else{
      scheduleRideIconController(false);
      scheduleRideIconController.refresh();
    }
  }

  setDefaultLocationIconPosition(){
    isScheduleRideIconEnable=false;
    scheduleRideIconController(false);
    scheduleRideIconController.refresh();
  }

  setLocIconPositionForConfirm(){
    if(isScheduleRideIconEnable){
      scheduleRideIconController(true);
      scheduleRideIconController.refresh();
    }else{
      scheduleRideIconController(false);
      scheduleRideIconController.refresh();
    }
    if(vehicleCatDetailAnimController!=null){
      vehicleCatDetailAnimController?.reverse();
    }
    if(vehicleCatAnimController!=null){
      vehicleCatAnimController?.reverse();
    }
    if(confirmPopupAnimController!=null){
      confirmPopupAnimController?.reverse();
    }
  }

  closeTripPlannerPage(){
    closeMultipleStopSearchPage();
  }

  closeMultipleStopSearchPage(){
    if(closeMultipleStopSearchPageController!=null){
      closeMultipleStopSearchPageController(false);
    }
  }

}