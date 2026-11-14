import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/controller/trip_controllers/trip_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/map_screen_widget/location_data_widget.dart';
import '../widgets/map_screen_widget/rider_review_transition_view.dart';
import '../widgets/primary_button.dart';
import '../widgets/trip_detail_view.dart';

class TripDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TripDetailView();
  }
}

class TripDetailView extends StatefulWidget {
  @override
  _TripDetailViewState createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {

  final TripController _controller = Get.find();
  final MapMainController _mapMainController = Get.find();
  final tooltipController = JustTheController();
  bool isToolTipShown = false;

  @override
  void initState() {
    _controller.changePaymentDriver(_controller.selectedTrip?['id']);
    _controller.paymentType.value = _controller.selectedTrip?['paymentType'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: trip_details.tr,
        customAppBarFunction: () {
          if (isToolTipShown) {
            tooltipController.hideTooltip();
          } else {
            globals.isRefreshTripPage.value = true;
            globals.isRefreshTripPage.refresh();
            App().setBackNavigation();
          }
        },
        bottomNavigationBar:Obx((){
          return _controller.isCashReceived.value ?  Padding(
            padding: const EdgeInsets.all(25.0),
            child: PrimaryButton(
              buttonTitle: "have_you_received_cash".tr,
              buttonImage: primaryRightArrow,
              callback: () {
                paymentConfirm();
              },
            ),
          ): SizedBox.shrink();
        }),
        body: Obx((){
          return Container(
            color: AppColors.COMMON_BG_COLOR,
            child: TripDetailItemView(
                selectedComfortRide: _controller.selectedTrip?['comfortRide'],
                selectedTrip: _controller.selectedTrip,
                tooltipController: tooltipController,
                context: context,
                isToolTipShown: isToolTipShown,
                locationDataWidget: LocationDataWidget(),
                ridePaymentType: _controller.paymentType.value
            ),
          );
        }),
      );
    });
  }
  void paymentConfirm( ){
    Get.bottomSheet(
        backgroundColor:
        AppColors.PRIMARY_COLOR_WHITE,
        SafeArea(
          bottom: Platform.isAndroid,
          child: Consumer<ModelTheme>(
              builder: (context, ModelTheme themeNotifier, child) {
                return Container(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: [
                          SizedBox(
                            height: 58,
                            width: 58,
                            child: SvgPicture.asset(moneywithRound,colorMapper: !globals.isDarkTheme ? ChatIconColorMapper(AppColors.ICON_COLOUR) : null,),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                              const  EdgeInsetsDirectional.only(start: 15),
                              child: Text(
                                  collect_cash.tr,
                                  style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_18,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 15, bottom: 40),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color:
                                        AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w500),
                                    children: [
                                      TextSpan(
                                        text: did_you_collect_cash.tr,
                                        style: TextStyle(
                                          fontFamily: AppFont.font,
                                          fontSize: AppDimen.text_size_16,
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " ${globals.currencySymbol}",
                                        style: TextStyle(
                                          fontSize: AppDimen.text_size_16,
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        ),
                                      ),
                                      TextSpan(
                                        text:"${"" + double.parse(_controller.selectedTrip!["riderTotalFare"].toString()).toStringAsFixed(2)}?",
                                        style: TextStyle(
                                          fontFamily: AppFont.font,
                                          fontSize: AppDimen.text_size_16,
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        ),
                                      ),
                                    ])),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Get.back();
                              },
                              child: Container(
                                width:
                                Get.width,
                                margin:
                                const  EdgeInsetsDirectional.only(end: 10),
                                height: 50,
                                padding:const  EdgeInsetsDirectional.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius:
                                    BorderRadius.circular(4),
                                    border: Border.all(
                                        width: 1,
                                        color: AppColors.PRIMARY_COLOR_DARK)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      no.tr,
                                      style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK,
                                          fontFamily: AppFont.font,
                                          fontWeight: FontWeight.w500,
                                          fontSize:
                                          AppDimen.text_size_16)),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: (){
                                _controller.confirmCashPayment(_controller.selectedTrip?['id']).then((value){
                                  if(value == ""){
                                    _mapMainController.isFromtrips = true;
                                    _mapMainController.riderID = _controller.selectedTrip?["riderDetails"]["userId"];
                                    _mapMainController.bookingID = _controller.selectedTrip?["id"];
                                    _mapMainController.riderPhoto = _controller.selectedTrip?["riderDetails"]["picture"] != null
                                        ? globals.UPLOAD_URL + "/images/avatar/" + _controller.selectedTrip!["riderDetails"]["picture"] : "";
                                    Get.back();
                                    if(_controller.selectedTrip?['tripStatus'] == 'completed' && _controller.selectedTrip?['isDriverReviewed'] == false) {
                                      Get.off(RiderReviewTransitionView());
                                    } else{
                                      globals.isRefreshTripPage.value = true;
                                      globals.isRefreshTripPage.refresh();
                                      Get.back();
                                    }
                                  } else if (value.isNotEmpty){
                                    Get.back();
                                    _controller.showInSnackBar(cash_payment_error_message.tr);
                                  }
                                });
                              },
                              child: Container(
                                width:
                                Get.width,
                                height: 50,
                                margin: const EdgeInsetsDirectional.only(
                                    start: 10),
                                padding:const EdgeInsetsDirectional.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_COLOR_DARK,
                                    borderRadius:
                                    BorderRadius.circular(4)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                          yes.tr,
                                          style: TextStyle(
                                              color: AppColors.PRIMARY_COLOR_WHITE,
                                              fontFamily: AppFont.font,
                                              fontWeight:
                                              FontWeight.w500,
                                              fontSize: AppDimen
                                                  .text_size_16)),
                                      Padding(
                                        padding:
                                        const EdgeInsetsDirectional.only(
                                            start: 6),
                                        child: SvgPicture.asset(
                                          primaryRightArrow,
                                          matchTextDirection: true,
                                          colorFilter: ColorFilter.mode(
                                              AppColors.WHITE_ICON_COLOR,
                                              BlendMode.srcIn),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              }
          ),
        )
    );
  }
}