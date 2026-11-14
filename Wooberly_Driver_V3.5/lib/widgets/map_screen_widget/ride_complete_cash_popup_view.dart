import 'package:wooberly_driver/widgets/map_screen_widget/location_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';

import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_lang.dart';

class RideFinalCashPopUpView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideFinalCashPopUpView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<RideFinalCashPopUpView> createState() => _RideFinalCashPopUpViewState();
}

class _RideFinalCashPopUpViewState extends State<RideFinalCashPopUpView>
    with TickerProviderStateMixin {
  bool _isButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
          position: widget.homeViewState.tripCashPopupOffset!,
          child: GetBuilder(
            init: MapMainController(),
              id: widget.controller.rxColorChangeController.id,
              builder: (val) {
                return Container(
                  alignment: Alignment.bottomCenter,
                  color: widget.controller.rxColorChangeController.value == 1
                      ? AppColors.PRIMARY_COLOR_DARK_TRAN
                      : Colors.transparent,
                  child: GetBuilder(
                    init: MapMainController(),
                      id: widget.controller.rxFinalAmountController.id,
                      builder: (val) {
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
                                    child: SvgPicture.asset(moneywithRound, colorMapper: !globals.isDarkTheme ? ChatIconColorMapper(AppColors.ICON_COLOUR) : null,),
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
                                            text: did_you_collect_cash.tr+ " ",
                                            style: TextStyle(
                                              fontFamily: AppFont.font,
                                              fontSize: AppDimen.text_size_16,
                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            ),
                                          ),
                                          TextSpan(
                                            text: globals.currencySymbol,
                                            style: TextStyle(
                                              fontSize: AppDimen.text_size_16,
                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                "${"" + double.parse(widget.controller.totalTripAmount.toString()).toStringAsFixed(2)}?",
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
                                        widget.homeViewState.tripCashPopupController?.reverse();
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
                                      onTap: () {
                                        if (!_isButtonDisabled) {
                                          _isButtonDisabled = true;
                                          widget.controller.confirmCashPayment().then((value) {
                                            if (value == '') {
                                              widget.homeViewState.closeApp = false;
                                              widget.homeViewState.tripAmountController?.reverse();
                                              widget.homeViewState.tripCashPopupController?.reverse();
                                              widget.controller.homeViewState = widget.homeViewState;
                                              widget.controller.isFromtrips = false;
                                              App().setNavigation(AppRoutes.APP_SHOW_REVIEW);
                                            } else if(value != ""){
                                              widget.controller.showInSnackBar(cash_payment_error_message.tr);
                                            }
                                            Future.delayed(
                                                const Duration(seconds: 1), () {
                                              _isButtonDisabled = false;
                                            });
                                          });
                                        }
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
                      }),
                );
              })),
    );
  }
}