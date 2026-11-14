import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';

class TotalEarningOnMap extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  TotalEarningOnMap(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<TotalEarningOnMap> createState() => _TotalEarningOnMapState();
}

class _TotalEarningOnMapState extends State<TotalEarningOnMap>
    with TickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: MapMainController(),
        id: widget.controller.rxIsPrivateController.id,
        builder: (val) {
        debugPrint("widget.controller.rxIsPrivateController: ${widget.controller.rxIsPrivateController.value}");
          if (!widget.controller.totalEarings
              .toString()
              .contains("."))
            widget.controller.totalEarings = double.parse(
                widget.controller.totalEarings.toString());
    return  Obx(() {
      return widget.controller.rxRideDetailEnabledController.value != null ?
      Opacity(
        opacity: globals.driverStatus.compareTo("active") != 0 ? 0.0 : 1.0,
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: widget.controller.rxRideDetailEnabledController.value  == true
                ? widget.homeViewState.rideDetailAmountOffset!
                : widget.homeViewState.amountOffset!,
            child:
            InkWell(
              onTap: () {
                if (globals.driverStatus.compareTo("active") == 0) {
                  if (widget.controller.totalEarings != -1) {
                    amountWidget(context);
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 20.0),
                height: 45,
                width: (widget.controller.rxIsPrivateController.value == true ||
                    widget.controller.totalEarings == -1)
                    ? 45
                    : null,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.PRIMARY_COLOR_WHITE, width: 1),
                  color: AppColors.PRIMARY_COLOR_DARK,
                  borderRadius:
                  BorderRadius.all(Radius.circular(23.0)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.SHADOW_COLOR,
                        blurRadius: 6,
                        offset: Offset(3.0, 4.0))
                  ],
                ),
                child: (widget.controller.rxIsPrivateController.value == true ||
                    widget.controller.totalEarings == -1)
                    ? Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      visibilityOffSvg,
                      width: 24,
                      height: 18,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          AppColors.PRIMARY_COLOR_WHITE,
                          BlendMode.srcIn),
                    ),
                  ],
                )
                    : (widget.controller.rxIsPrivateController.value == false)
                    ? Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 65,
                      padding:
                      const EdgeInsetsDirectional
                          .only(
                          start: 24,
                          end: 24,
                          top: 7,
                          bottom: 8),
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: globals
                                    .currencySymbol,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_20,
                                    fontFamily: 'Roboto'),
                              ),
                              TextSpan(
                                text:
                                "${(widget.controller.totalEarings == null || widget.controller.totalEarings == 0.0 || widget.controller.totalEarings == 0) ? "0.0" :
                                widget.controller.totalEarings.toString().length < 4 ? widget.controller.totalEarings.toString() :
                                widget.controller.totalEarings.toString().contains('.') && widget.controller.totalEarings.toString().substring(0, widget.controller.totalEarings.toString().indexOf(".")).length < 3 ?
                                widget.controller.totalEarings.toString().substring(0, widget.controller.totalEarings.toString().indexOf(".")) + "+" :
                                widget.controller.totalEarings.toString().substring(0, 3) + "+"}",
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_20,
                                    fontFamily: AppFont.font),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    :const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ) : const SizedBox.shrink();
    });
        });
  }

  amountWidget(BuildContext ctx)  {
    widget.homeViewState.amountWidgetContext = ctx;
    Get.dialog(
      barrierDismissible: true,
      Obx(
        () {
          return globals.isAutoThemeUpdated.value != null ? Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 100.0),
                  child: Dialog(
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0.0,
                    backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                    child: dialogContent(context),
                  )
                )
              ],
            )
          ) : SizedBox.shrink();
        }
      )
    );
  }

  dialogContent(BuildContext context) {
    widget.controller.getPrivateStatus();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 22, start: 22, end: 22),
          child: Stack(children: <Widget>[
            Align(
                alignment: AlignmentDirectional.topStart,
                child: GetBuilder(
                  init: MapMainController(),
                    id: widget.controller.rxIsPrivateController.id,
                    builder: (val) {
                      return InkWell(
                        onTap: () {
                          if (widget.controller.totalEarings == null ||
                              widget.controller.totalEarings == -1) {
                            return;
                          } else {
                            (widget.controller.rxIsPrivateController.value == true)
                                ? widget.controller.setPrivateMode(false)
                                : widget.controller.setPrivateMode(true);
                            Get.back();
                          }
                        },
                        child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_DARK,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.PRIMARY_COLOR_WHITE, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.SHADOW_COLOR,
                                    blurRadius: 6,
                                    offset: Offset(3.0, 4.0))
                              ],
                            ),
                            child:
                                (widget.controller.rxIsPrivateController.value == true)
                                    ? SvgPicture.asset(
                                  visibilityOffSvg,
                                        width: 24,
                                        height: 18,
                                        fit: BoxFit.scaleDown,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_COLOR_WHITE,
                                            BlendMode.srcIn),
                                      )
                                    : SvgPicture.asset(
                                  visibilityOnSvg,
                                        width: 24,
                                        height: 18,
                                        fit: BoxFit.scaleDown,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_COLOR_WHITE,
                                            BlendMode.srcIn),
                                      )),
                      );
                    })),
            Align(
              alignment: FractionalOffset.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: 110),
                height: 45,
                padding: const EdgeInsetsDirectional.only(
                    top: 7, bottom: 8, start: 24, end: 24),
                decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_DARK,
                  border: Border.all(color: AppColors.PRIMARY_COLOR_WHITE, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(23)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.SHADOW_COLOR,
                        blurRadius: 6,
                        offset: Offset(3.0, 4.0))
                  ],
                ),
                child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: globals.currencySymbol,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_WHITE,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_20,
                                fontFamily: 'Roboto'),
                          ),
                          TextSpan(
                            text:
                                "${(widget.controller.totalEarings == null || widget.controller.totalEarings == 0.0 || widget.controller.totalEarings == 0 || widget.controller.totalEarings == -1) ? "0.0" : widget.controller.totalEarings.toString().length > 9 ? widget.controller.totalEarings.toString().substring(0, 8) + "+" : widget.controller.totalEarings.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_WHITE,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_20,
                                fontFamily: AppFont.font),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(today.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontWeight: FontWeight.w600,
                            fontSize: AppDimen.text_size_18,
                            fontFamily: AppFont.font)),
                  ),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 22, end: 22, top: 5),
          child: Text(
              "${widget.controller.totalTrips} ${(widget.controller.totalTrips > 1) ? tripPOther.tr : tripOne.tr} ${trip_completed.tr.toLowerCase()}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontWeight: FontWeight.w400,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 14),
          child: Divider(
            color: AppColors.DIVIDER_COLOR,
            thickness: 1,
          ),
        ),
        InkWell(
          onTap: () {
            App().setNavigation(AppRoutes.APP_EARNINGS).then((val) => App().setBackNavigation());
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
            child: Text(
              View_Earnings.tr,
              style: TextStyle(
                  color: AppColors.TEXT_LINK_COLOR,
                  fontFamily: AppFont.font,
                  fontSize: AppDimen.text_size_16,
                  fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }
}