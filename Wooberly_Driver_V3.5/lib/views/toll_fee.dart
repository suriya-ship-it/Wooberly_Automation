import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/widgets/primary_button.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../utils/globals.dart' as globals;
import '../widgets/map_screen_widget/location_data_widget.dart';
import '../widgets/time_line_widget.dart';

class TollFee extends StatelessWidget {
  VoidCallback locationStatusFunction;
  TollFee(this.locationStatusFunction);
  @override
  Widget build(BuildContext context) {
    return TollFeeView(locationStatusFunction: locationStatusFunction);
  }
}

class TollFeeView extends StatefulWidget {
  final VoidCallback locationStatusFunction;
  const TollFeeView({Key? key, required this.locationStatusFunction}) : super(key: key);

  @override
  _TollFeeViewState createState() => _TollFeeViewState();
}

class _TollFeeViewState extends State<TollFeeView> {
  final MapMainController _controller = Get.find();

  List<Map<String, dynamic>>? _locationData;
  LocationDataWidget? _locationDataWidget;
  bool isTollCompleteEnable = true;

  @override
  void initState() {
    _locationDataWidget = LocationDataWidget();
    globals.isShowMapPage = true;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: toll_charges.tr,
        appBarImage: closeSvg,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  margin: const EdgeInsetsDirectional.only(
                    top: 36,
                    start: 24,
                    end: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 24.0,
                      ),
                      GetBuilder(
                        init: _controller,
                          id: _controller.rxUpdateBookingLocationController.id,
                          builder: (val) {
                          debugPrint("_locationData == : ${_controller.locationData ==_controller.locationData}");
                            if (_locationData != null && _controller.locationData !=_controller.locationData) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Get.until((route) => route.settings.name == "/MapMainScreen");
                              });
                            }
                            _locationData = _controller.locationData
                                .map((h) => {
                                      "id": h.id,
                                      "latLng": h.latLng,
                                      "location": h.location,
                                      "fieldType": h.fieldType,
                                      "locationStatus": h.locationStatus,
                                      "locationType": h.locationType,
                                    })
                                .toList();
                            return Padding(
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                              child: Timeline(
                                children: _locationDataWidget
                                        ?.frameDisplayLocationWidgets(
                                            _locationData,
                                            _controller.tripStatus) ??
                                    [],
                              ),
                            );
                          }),
                      SizedBox(
                        height: 12.0,
                      ),
                      Container(
                        height: 1,
                        color: AppColors.DIVIDER_COLOR,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Container(
                          margin: const EdgeInsets.only(bottom: 17.0),
                          child: Text(
                              toll_charges.tr,
                              style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_18,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.font))),
                      Container(
                        width: 200,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Row(
                              children: <Widget>[
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: globals.currencySymbol,
                                      style: TextStyle(
                                        fontSize: AppDimen.text_size_22,
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]),
                                ),
                                SizedBox(
                                  width: 5.0,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    enableIMEPersonalizedLearning: false,
                                    autofocus: false,
                                    controller: _controller.tollFeeController,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                          RegExp("[0-9.]")),
                                      LengthLimitingTextInputFormatter(8)
                                    ],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    scrollPadding:
                                    const EdgeInsets.only(bottom: 140),
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                      const EdgeInsets.only(bottom: 3.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 5),
                              child: Divider(
                                height: 2,
                                color: AppColors.BLACK,
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsetsDirectional.only(
                              top: 15, start: 24, end: 24, bottom: 24),
                          child: FittedBox(
                            child: Text(
                                "${hint_toll.tr} ",
                                maxLines: 1,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_14,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFont.font)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  margin:
                  const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
                  child: PrimaryButton(
                    height: 51,
                    buttonTitle: done.tr,
                    buttonImage: primaryBtnArrow,
                    callback: () async{
                      bool isLocationEnable = await  _controller.isLocationPermissionsEnabled();
                      debugPrint("tollfeeisLocationDisable: ${isLocationEnable}");
                      if(!isLocationEnable) {
                        widget.locationStatusFunction();
                      } else {
                        if (isTollCompleteEnable) {
                          _controller.checkInternet(sendCompleteRide, true);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

      );
    });
  }

  sendCompleteRide() {
    isTollCompleteEnable = false;
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);

    Future.delayed(const Duration(milliseconds: 250), () {
      List<String> arg;
      double tollFees;
      if (_controller.tollFeeController.text == null) {
        tollFees = 0.0;
      } else if (_controller.tollFeeController.text.isEmpty ||
          _controller.tollFeeController.text.compareTo("0") == 0) {
        tollFees = 0.0;
      } else if (_controller.tollFeeController.text.compareTo(".") == 0) {
        isTollCompleteEnable = true;
        _controller.showInSnackBar(Valid_toll_charges.tr);
        return;
      } else {
        tollFees = double.parse(_controller.tollFeeController.text);
      }
      _controller.getLocation("update").then((onValue) {
        int completeLocationIndex = _controller.locationData.length - 1;
        Map<String, dynamic> dateTimeValues = _controller.getDateTimeValue();
        arg = [
          '{"data" : {"auth" : "${globals.authToken}", "userId" : "${globals.userid}",'
              '"bookingId" : ${_controller.bookingID},'
              '"isCompleteTrip" : ${true},'
              '"dropOffLocation" : "${_controller.locationData[completeLocationIndex].location}", "dropOffLat" : ${_controller.mapLocation.latitude},'
              '"dropOffLng" : ${_controller.mapLocation.longitude},'
              '"tollFee" : ${tollFees},"dateValue" : "${dateTimeValues["dateValue"]}","dayValue" : "${dateTimeValues["dayValue"]}","endTimeValue" : "${dateTimeValues["startTimeValue"]}",'
              '"dropOffDistance":${_controller.zeroForAPISideDistanceMatrixCalculation},'
              '"dropOffDuration":${_controller.zeroForAPISideDistanceMatrixCalculation}}}'
        ];
        _controller.socketIns.socketConnect();
        receiveTripCompleted("tripComplete-${globals.userid}");
        _controller.socketIns.onsendMessage("tripComplete", arg);
        _controller.setNavigationStatus(-1);
      });
    });
  }

  receiveTripCompleted(String eventName) {
    globals.socket?.on(eventName, (data) {
      debugPrint("receiveTripCompleted:tollfee ${data}");
      isTollCompleteEnable = true;
      debugPrint("receiveTripCompleted: complete: ${_controller.homeViewState.rideCompleteSocket}");
      _controller.homeViewState.rideCompleteSocket?.completeRide(data);
      if (data["data"]["status"] == 200) {
        debugPrint("receiveTripCompleted: ${globals.userid}");
        if (data["data"]["data"]["driverId"].toString() == globals.userid) {
            globals.bookingId = 0;
            Get.until((route) => route.settings.name == "/MapMainScreen");
            globals.isShowMapPage = true;
            _controller.change(
                rxVariable: _controller.rxFinalAmountController, value: 1.0);

        }
      }
    });
  }
}