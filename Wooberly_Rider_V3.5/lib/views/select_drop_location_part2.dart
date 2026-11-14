part of 'select_drop_location.dart';

extension SelectDropLocationPart2 on _AutoCompleteState {
  getListFooter() {
    debugPrint("locationData.length: ${locationData.length} --- ${_mapMainController.EditDisableLocationsDataIndex}");
    return

      Column(
      children: [
        AnimatedVisibilityBottomText(
          visible: locationData.length-1 > _mapMainController.EditDisableLocationsDataIndex,
          child: Container(
              margin: (PlacesAutocompleteState.response != null) &&
                      PlacesAutocompleteState.queryTextController!.text.isNotEmpty
                  ? const EdgeInsetsDirectional.only(
                      start: 24.0,
                      top: 10.0,
                      end: 24.0,
                    )
                  : const EdgeInsetsDirectional.only(
                      start: 24.0,
                      top: 35.0,
                      end: 24.0,
                    ),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _getFavoriteLocationWidget(SelectLocationEnum.homeLocation,
                      'Add_home'.tr, 'home'.tr, homeSvg),
                  Divider(
                    thickness: 1.1,
                    color: AppColors.DIVIDER_COLOR,
                  ),
                  _getFavoriteLocationWidget(SelectLocationEnum.workLocation,
                      'Add_work'.tr, 'work'.tr, workSvg),
                  Divider(
                    thickness: 1.1,
                    color: AppColors.DIVIDER_COLOR,
                  ),
                  InkWell(
                      onTap: () {
                        Get.to(
                          SelectLocationOnMapPage(
                            isFromSchedule: widget.isFromSchedule ?? false,
                            locationData: locationData,
                          ),
                          transition: Transition.rightToLeft,
                        )?.then((result){
                          if(result !=null)
                          updateLocationData(result['place'], LatLng(result['lat'], result['lng']));
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            end: 15.0, top: 10.0, bottom: 20.0, start: 15.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: AppColors.BORDERCOLOR, width: 1)),
                              child: Center(
                                child: SvgPicture.asset(
                                  locationFilledSvg,
                                  width: 40.0,
                                  height: 40.0,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.PRIMARY_ICON_COLOR,
                                      BlendMode.srcIn),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Flexible(
                              child: Text(
                                'set_location_on_map'.tr,
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                      )),
                ],
              )),
        ),
        SizedBox(
          height: 20,
        ),
        AnimatedVisibilityBottomText(
          visible: locationData.length > 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              bottomText(),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ],
      );
  }

  Widget bottomText() {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
          color: AppColors.PRIMARY_LIGHT_COLOR,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            waitingClockSvg,
            height: 45.0,
            width: 45.0,
          ),
          const SizedBox(height: 10),
          Text(
            "${'please_keep_stops_to'.tr} ${globals.multipleStopWaitingTime} ${'minutes_or_less'.tr}",
            style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
              "${'as_a_courtesy_for_your_driver'.tr} ${globals.multipleStopWaitingTime} ${'minutes_or_less_otherwise'.tr}",
              style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontWeight: FontWeight.w500,
                  fontSize: AppDimen.text_size_16)),
        ],
      ),
    );
  }


  void _moveToRouteDrawnPage(int data) {
    debugPrint('_mapMainController.nearDriverErrMsg: ${_mapMainController.nearDriverErrMsg == null} --- ${data}');
    Future.delayed(
        Duration(
            milliseconds: _mapMainController.isHomeScreen
                ? 1000
                : 10), () {
      _mapMainController.setDestPlaceController(_mapMainController.locationData.last.location ?? '');
      _mapMainController.destLocAnimController?.forward();

      if (_mapMainController.nearDriverErrMsg != null && data == 3)
        _mapMainController.seRideNowLoadingController(2);
      else {
        _mapMainController.seRideNowLoadingController(0); //issue2
      }
      if (_mapMainController.vehicleCatAnimController != null) {
        _mapMainController.vehicleCatAnimController?.forward();
      }
    });
    if (data == 3) {
      _mapMainController.seRideNowLoadingController(1);
      if (_mapMainController.vehicleCatAnimController != null) {
        _mapMainController.vehicleCatAnimController?.forward();
      }
    } else {
      _mapMainController.tripCalculationModel = null;
      _mapMainController.seRideNowLoadingController(0); //issue1
      debugPrint("destLocAnimController forward 12 a");
      if (_mapMainController.destLocAnimController != null)
        _mapMainController.destLocAnimController?.forward();
      try {
        _mapMainController.updatePadding(220);
        if (globals.currencyRates != null && globals.currencyRates.isNotEmpty) {
          _mapMainController.openVehicleCategoryList(
              _mapMainController.isScheduleRideIconEnable);
        } else {
          _mapMainController.getCurrencyRates().then((currencyRate) {
            if (currencyRate!.isEmpty) {
              _mapMainController.openVehicleCategoryList(
                  _mapMainController.isScheduleRideIconEnable);
            } else {
              _mapMainController.checkInternet(() {}, false);
            }
          });
        }
      } on Exception catch (e) {
        debugPrint("route draw error");
      }
    }
    _mapMainController.isHomeScreen = false;
  }

  _getFavoriteLocationWidget(SelectLocationEnum locationEnum, String emptyAdd,
      String locationType, String image) {
    return InkWell(
        onTap: () {
          if (_mapMainController
              .getLocationDetails(locationEnum)
              .location
              .isEmpty) {
            _mapMainController.update(['placeSelectController']);


            double keyopen = MediaQuery.of(context).viewInsets.bottom;
            if (PlacesAutocompleteState.focus || keyopen != 0.0) {
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              Future.delayed(Duration(milliseconds: 150)).then((_) {
                if (widget.isFromSchedule == true) {
                  _mapMainController.scheduleRideIconController(true);
                  _mapMainController.scheduleRideIconController.refresh();
                }
                Get.to(
                  () => SelectMapLocation(
                    selectedPlace: _mapMainController
                        .getLocationDetails(locationEnum)
                        .location,
                    isFromSchedule: widget.isFromSchedule ?? false,
                    multiStopFrom: "dropLocationpage",
                  ),
                  arguments: {'locationEnum': locationEnum}
                );
              });
            } else {
              if (widget.isFromSchedule!) {
                _mapMainController.scheduleRideIconController(true);
                _mapMainController.scheduleRideIconController.refresh();
              }

              Get.to(
                () => SelectMapLocation(
                  selectedPlace: _mapMainController
                      .getLocationDetails(locationEnum)
                      .location,
                  isFromSchedule: widget.isFromSchedule ?? false,
                  multiStopFrom: "dropLocationpage",
                ),
                  arguments: {'locationEnum': locationEnum}
              );
            }
          } else {
            if (!_isSearching) {
              SelectLocationModel locationModelData = _mapMainController.getLocationDetails(locationEnum);
              updateLocationData(locationModelData.location, LatLng(locationModelData.lat, locationModelData.lng));
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment:
              _mapMainController.getLocationDetails(locationEnum).location != ''
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(
                  end: 15.0,
                  top: _mapMainController.getLocationDetails(locationEnum).location != ''
                      ? 20.0
                      : 20,
                  start: 15.0,
                  bottom: 15.0),
              child: Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.BORDERCOLOR, width: 1)),
                child: Center(
                  child: SvgPicture.asset(
                    image,
                    width: 40.0,
                    height: 40.0,
                    colorFilter: ColorFilter.mode(
                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: _mapMainController
                                .getLocationDetails(locationEnum)
                                .location !=
                            ''
                        ? EdgeInsetsDirectional.only(top: 15.0)
                        : EdgeInsetsDirectional.only(top: 5.0),
                    child: Text(
                      _mapMainController
                                  .getLocationDetails(locationEnum)
                                  .location ==
                              ''
                          ? "${emptyAdd}"
                          : "${locationType}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16),
                    ),
                  ),
                  _mapMainController
                              .getLocationDetails(locationEnum)
                              .location !=
                          ''
                      ? Padding(
                          padding:
                              EdgeInsetsDirectional.only(end: 20.0, bottom: 10),
                          child: Directionality(
                            textDirection: globals.isRTLLang
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Text(
                              _mapMainController
                                  .getLocationDetails(locationEnum)
                                  .location
                                  .toString()
                                  .toRemoveCommaString(),
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_14,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ));
  }

  Future<Null> updateLocationData(
      String locationName,  LatLng detail) async {
    debugPrint("selectedEnum: ${PlacesAutocompleteState.activeStopIndex} --- --- ${locationName} --- ${detail}");

      PlacesAutocompleteState.queryTextController?.clear();
      if(locationData.length>=1) {

        final index = locationData.indexWhere(
              (element) {
                return element.location != null && element.location!.isNotEmpty && locationName ==element.location && element.locationStatus != "completed"; },
        );
        if(index != -1) {
          _mapMainController.toast.show(context: context, message: 'start_end_same_error'.tr);
          return;
        }


       bool isCountryCheck = await _mapMainController.getCountryCheck(
            detail, locationData.first.latLng!);
        if (!isCountryCheck) {
          _mapMainController.showInSnackBar('no_service_avaliable'.tr);
          return;
        }
      }
      PlacesAutocompleteState.focus = false;

      // No route to draw yet – reset flag so search works normally again

      final existingLocationData = locationData[PlacesAutocompleteState.activeStopIndex];
      locationData[PlacesAutocompleteState.activeStopIndex] = LocationData(
        detail,
        locationName,
        existingLocationData.fieldType,
        existingLocationData.id,
        existingLocationData.locationStatus,
        existingLocationData.locationType,
        existingLocationData.locationDistanceType,
      );
      PlacesAutocompleteState.isSelectingPrediction = false;
    _mapMainController.update(['placeSelectController']);
      Future.delayed(const Duration(milliseconds: 200), () {
        final index = locationData.indexWhere(
              (element) => element.location == null || element.location!.isEmpty,
        );
        if (index != -1) {
          PlacesAutocompleteState.activeStopIndex = index;
        }
      });
  }

}