import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/base_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import 'package:wooberly_driver/widgets/dotted_line/dotted_line.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../controller/trip_controllers/earning_controller.dart';
import '../resources/values/app_lang.dart';
import '../widgets/arrow.dart';

class Earnings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EarningsView();
  }
}

class EarningsView extends StatefulWidget {
  @override
  _EarningsViewState createState() => _EarningsViewState();
}

class _EarningsViewState extends State<EarningsView>
    with TickerProviderStateMixin {
  final EarningController _controller = Get.find();

  bool _isload = false;
  final tooltipController = JustTheController();
  final durationtooltipController = JustTheController();
  bool isTripsToolOpen = false, isDurationToolOpen = false;
  String? earningType;
  var rxTabRefreshController = ReactiveVariable("rxTabRefreshController", 0);
  @override
  void initState() {
    _isload = true;
    _controller.selectedEarnType = 0;
    Future.delayed(Duration(milliseconds: 20)).then((_) {
      _controller.checkInternet(getEarnings, false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          disableAppbar: false,
          appBarTitle: earnings.tr,
          customAppBarFunction: () {
            if (isTripsToolOpen) {
              tooltipController.hideTooltip();
            } else if (isDurationToolOpen) {
              durationtooltipController.hideTooltip();
            } else {
              App().setBackNavigation();
            }
          },
          actionWidgets: [
            InkWell(
              onTap: () {
                App().setNavigation(AppRoutes.APP_HELP_INFO);
              },
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.PRIMARY_COLOR_DARK
                ),
                child: SvgPicture.asset(
                  helpSvg,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                ),
              ),
            ),
          ],
          body: GetBuilder<EarningController>(
            init: EarningController(),
            id: rxTabRefreshController.id,
            builder: (val) {
              earningType = _controller.earningSection[rxTabRefreshController.value];
              return _isload ?
              _controller.getProgressIndicator(context, Colors.transparent) :
              Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    onTap: () {
                      _showEarningBottomSheet();
                    },
                    child: Container(
                      margin: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                      width: Get.width,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.PRIMARY_COLOR_WHITE,
                      ),
                      child: Row(
                        children: [
                          Text(
                            earningType!,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFont.font),
                          ),
                         const Spacer(),
                          Icon(Icons.keyboard_arrow_down_outlined,color: AppColors.PRIMARY_COLOR_DARK,)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Flexible(
                    child: Container(
                      margin: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                      padding: const EdgeInsetsDirectional.all(18),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          borderRadius:
                              BorderRadius.all(Radius.circular(10),
                              ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: Get.width,
                              child: Text("${_controller.earningDetails['date']}",
                                  style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontFamily: AppFont.font,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 4),
                              child: RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_34,
                                      ),
                                      children: [
                                    TextSpan(
                                        text: globals.currencySymbol,
                                        style: TextStyle(
                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_34,
                                            fontFamily: 'Roboto')),
                                    TextSpan(
                                      text: _controller.earningDetails['earning'],
                                      style: TextStyle(
                                        fontFamily: AppFont.font,
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_34,
                                      ),
                                    ),
                                  ],
                                  ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 15),
                              child: DottedLine(
                                  direction: Axis.horizontal,
                                  lineLength: double.infinity,
                                  lineThickness: 1.0,
                                  dashColor: AppColors
                                      .PRIMARY_COLOR_DARK),
                            ),
                            showSplitUpView(
                                1,
                                No_of_Trips.tr,
                                _controller.earningDetails['trips']?? 0,
                                true,
                                false),
                            showSplitUpView(
                                2,
                                Trip_duration.tr,
                                _controller.earningDetails['duration']?? 0,
                                true,
                                false),
                            showSplitUpView(
                                3,
                                Tips_rider.tr,
                                _controller.earningDetails['tips']?? 0,
                                false,
                                true),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 16),
                              child: DottedLine(
                                  direction: Axis.horizontal,
                                  lineLength: double.infinity,
                                  lineThickness: 1.0,
                                  dashColor: AppColors
                                      .PRIMARY_COLOR_DARK),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 18),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(total.tr+" "+earnings.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.font),
                                  ),
                                  Flexible(
                                      child: Padding(
                                    padding:
                                    const EdgeInsetsDirectional.only(start: 5),
                                    child: RichText(
                                        text: TextSpan(
                                            style: TextStyle(
                                              color:
                                                  AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            children: [
                                          TextSpan(
                                              text: globals.currencySymbol,
                                              style: TextStyle(
                                                  color: AppColors
                                                      .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                  fontSize:
                                                      AppDimen.text_size_16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Roboto'),
                                          ),
                                          TextSpan(
                                            text:_controller.earningDetails['earning']??0,
                                            style: TextStyle(
                                              fontFamily: AppFont.font,
                                              color:
                                                  AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        ),
                                    ),
                                  ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    );
  }

  Widget showSplitUpView(int index, String Title, String Value,
      bool showIndication, bool isCurrencyNeeded) {
    return Container(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: Title.length > 20
                    ? Get.width * 0.3
                    : null,
                child: Text(
                  Title,
                  style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              Visibility(
                visible: showIndication,
                child: JustTheTooltip(
                    controller: index == 1
                        ? tooltipController
                        : durationtooltipController,
                    backgroundColor: AppColors.COMMON_BG_COLOR,
                    content: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        index == 1
                            ? "${no_of_trips_in_week.tr}"
                            : "${trip_duration_this_week.tr}",
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_14,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (index == 1) {
                          tooltipController.showTooltip();

                          Future.delayed(const Duration(seconds: 10), () {
                            tooltipController.hideTooltip();
                          });
                        } else {
                          durationtooltipController.showTooltip();

                          Future.delayed(const Duration(seconds: 10), () {
                            durationtooltipController.hideTooltip();
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 2),
                        child: SvgPicture.asset(
                          height: 14, width: 14,
                          infoSvg,
                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK,BlendMode.srcIn),
                        ),
                      ),
                    ),
                    onDismiss: () {
                      index == 1
                          ? isTripsToolOpen = false
                          : isDurationToolOpen = false;
                    },
                    onShow: () {
                      index == 1
                          ? isTripsToolOpen = true
                          : isDurationToolOpen = true;
                    }),
              ),
            ],
          ),
         const SizedBox(
            width: 30,
          ),
          Expanded(
            child: RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_16,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: isCurrencyNeeded ? globals.currencySymbol : "",
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto'),
                  ),
                  TextSpan(
                    text: Value,
                    style: TextStyle(
                        fontFamily: AppFont.font,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  getEarnings() {
    _controller.getEarnings().then((onValue) {
      if (onValue.isNotEmpty) {
        if (onValue == "offline") {
          _controller.snackBarwithAction(offline_text.tr, getEarnings);
        } else
          _controller.showInSnackBar(onValue);
      }
      _isload = false;
      _controller.change(rxVariable: rxTabRefreshController, value: _controller.selectedEarnType);
    });
  }

  void _showEarningBottomSheet() {
    Get.bottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
          return SafeArea(
            bottom: Platform.isAndroid,
            child: Container(
              padding: const EdgeInsetsDirectional.only(start: 24,top: 10,end: 24),
              height: Get.height * 0.32,
              color: AppColors.PRIMARY_COLOR_WHITE,
              child: ListView.builder(
                itemCount: _controller.earningSection.length,
                itemBuilder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                          _controller.change(rxVariable: rxTabRefreshController, value: snapshot);
                          _controller.selectedEarnType = snapshot;
                          getEarnings();
                        },
                        child: Container(
                          padding:
                             const EdgeInsetsDirectional.symmetric(vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _controller.earningSection[snapshot],
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.font),
                              ),
                             const Spacer(),
                              checkVerified(snapshot)
                                  ? SvgPicture.asset(
                                updatedVerified,
                                width: 23.0,
                                height: 23.0,
                                colorFilter: ColorFilter.mode(
                                    AppColors.ICON_COLOUR,
                                    BlendMode.srcIn),
                              )
                                  : const SizedBox.shrink()
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: AppColors.DIVIDER_COLOR,
                      ),
                    ],
                  );
                }
              ),
            ),
          );
        }
      )
    );
  }

  bool checkVerified(int index) {
    int index1 = _controller.earningSection
        .indexWhere((element) => element == earningType);
    return index1 == index;
  }
}