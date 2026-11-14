part of 'select_drop_location.dart';

extension SelectDropMultiStopFunctions on _AutoCompleteState {

  showMultiStopConfirmDialog(BuildContext context) {
    App()
        .showBottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                ),
                child: Container(
                  padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 40, bottom: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'making_changes_can_affect_the_price_of_your_trip'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontSize: 16,
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "${'if_you_add_a_stop_or_change_your_destination'.tr} ${globals.multipleStopWaitingTime} ${'minutes_as_a_courtesy_to_your_driver'.tr}",
                          style: TextStyle(
                              color: AppColors.PLACEHOLDER_TEXT_COLOR,
                              fontSize: AppDimen.text_size_12,
                              fontFamily: AppFont.font),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Container(
                                  padding:
                                  const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: AppColors.PrecautionInstructionCancel,
                                  ),
                                  child: Center(
                                      child: Text(
                                        'cancel_label'.tr,
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_14,
                                            fontFamily: AppFont.font),
                                      )),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Get.back();
                                    _mapMainController.checkInternet(updateStop, true);
                                  },
                                  child: Container(
                                    padding: const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 20),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: AppColors.PRIMARY_DARK_COLOR),
                                    child: Center(
                                        child: Text(
                                          'confirm_label'.tr,
                                          style: TextStyle(
                                              color: AppColors.WHITE_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_14,
                                              fontFamily: AppFont.font),
                                        )),
                                  ),
                                ))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
        Colors.transparent);
  }

  showLocationDisableSheet(BuildContext context) {
    App()
        .showBottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                ),
                child: Container(
                  padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 20, bottom: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: InkWell(
                            onTap: (){
                              Get.back();
                            },
                            child: SvgPicture.asset(
                              closeSvg,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_ICON_COLOR,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'this_destination_cannot_be_change'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontSize: 16,
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "${'this_destination_cannot_be_change_description'.tr}",
                          style: TextStyle(
                              color: AppColors.PLACEHOLDER_TEXT_COLOR,
                              fontSize: AppDimen.text_size_12,
                              fontFamily: AppFont.font),
                        ),
                        const SizedBox(
                          height: 30,
                        ),

                        PrimaryButton(
                          buttonTitle: 'got_it'.tr,
                          buttonImage: primaryBtnArrow,
                          isLoad: false,
                          callback: () {
                            Get.back();
                          },
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
        Colors.transparent);
  }

  updateStop() async {
    globals.refreshApp = true;
    _mapMainController.dispose();
    var tempLocationData = locationData.map((source) => LocationData.clone(source)).toList();
    tempLocationData.removeWhere((element) => element.location == null || element.location!.isEmpty);

    bool isLocationChanged = false;
    _mapMainController.updateRxValue(_mapMainController.screenController, true);
    List<dynamic> apiLocationData = [];
    if (_mapMainController.locationData.length != tempLocationData.length) {
      isLocationChanged = true;
    }
    for (int i = 0; i < tempLocationData.length && i < _mapMainController.locationData.length; i++) {
      if (tempLocationData[i].location != _mapMainController.locationData[i].location) {
        isLocationChanged = true;
      }
    }

    for (int i = 0; i < tempLocationData.length; i++) {
      if (i == 0) {
        var data = tempLocationData[i];
        if (data.id == 0) {
          apiLocationData.add({
            "id": data.id,
            "locationLat": data.latLng!.latitude,
            "locationLng": data.latLng!.longitude,
            "location": data.location,
            "locationDistance": _mapMainController.zeroForAPISideDistanceMatrixCalculation,
            "locationDuration": _mapMainController.zeroForAPISideDistanceMatrixCalculation
          });
        } else {
          apiLocationData.add({
            "id": data.id,
            "locationLat": data.latLng!.latitude,
            "locationLng": data.latLng!.longitude,
            "location": data.location,
            "locationDistance": _mapMainController.zeroForAPISideDistanceMatrixCalculation,
            "locationDuration": _mapMainController.zeroForAPISideDistanceMatrixCalculation
          });
        }
      } else {
        var currentData = tempLocationData[i];
        if (currentData.id == 0) {
          apiLocationData.add({
            "id": currentData.id,
            "locationLat": currentData.latLng!.latitude,
            "locationLng": currentData.latLng!.longitude,
            "location": currentData.location,
            "locationDistance": _mapMainController.zeroForAPISideDistanceMatrixCalculation,
            "locationDuration": _mapMainController.zeroForAPISideDistanceMatrixCalculation
          });
        } else {
          apiLocationData.add({
            "id": currentData.id,
            "locationLat": currentData.latLng!.latitude,
            "locationLng": currentData.latLng!.longitude,
            "location": currentData.location,
            "locationDistance": _mapMainController.zeroForAPISideDistanceMatrixCalculation,
            "locationDuration": _mapMainController.zeroForAPISideDistanceMatrixCalculation
          });
        }
      }
    }
    debugPrint("apiLocationData: ${apiLocationData}");
    _mapMainController.ismultistopvia = apiLocationData.length > 2;
    _mapMainController.updateStop(apiLocationData, isLocationChanged).then((value) {
      _mapMainController.updateRxValue(_mapMainController.screenController, false);
      if (value == "") {
        _mapMainController.locationData.clear();
        for (int i = 0; i < tempLocationData.length; i++) {
          if (tempLocationData[i].location!.isNotEmpty) {
            _mapMainController.locationData.add(tempLocationData[i]);
          }
        }
        _mapMainController.update(['updateBookingLocationController']);

        _mapMainController.sendBookingLocationToDriver();
        globals.tripStatus = "";

        _mapMainController.setNavigation(AppRoutes.APP_MAP_MAIN);
      } else {
        _mapMainController.showInSnackBar(value);
      }
    });
  }


}