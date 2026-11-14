import 'package:wooberly_driver/widgets/map_screen_widget/location_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/map_based_views.dart';


import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';
import '../size_find_widget.dart';

class DriverBottomInfoSheet extends StatefulWidget {

  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;
  final MapBasedViews mapBasedViews;

  DriverBottomInfoSheet(
      {Key? key,
      required this.homeViewState,
      required this.mapBasedViews})
      : super(key: key);

  @override
  State<DriverBottomInfoSheet> createState() => _DriverBottomInfoSheetState();
}

class _DriverBottomInfoSheetState extends State<DriverBottomInfoSheet>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: MapMainController(),
        id: widget.controller.rxOnlineStatus.id,
        builder: (val) {
          return globals.driverStatus.compareTo("active") != 0 ?
          const SizedBox.shrink():
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: InkWell(
              onTap: () {
                if (widget.controller.rxOnlineStatus.value && !widget.controller.isDriverAccept()) {
                  widget.controller.change(rxVariable: widget.controller.rxOnlineSliderController, value: !widget.controller.rxOnlineSliderController.value);
                }
              },

                child: GetBuilder(
                    init: MapMainController(),
                    id: widget.controller.rxOnlineSliderController.id,
                    builder: (val) {

                      return    WidgetSize(
                      onChange: (Size size) {
                      widget.homeViewState.bottomSheetHeight = size.height;
                      debugPrint(" widget.homeViewState.bottomSheetHeight: ${ widget.homeViewState.bottomSheetHeight}");
                      },
                          child:
                        Container(
                        constraints: BoxConstraints(minHeight: 80),
                        color: AppColors.PRIMARY_COLOR_WHITE,
                        child: SafeArea(
                          child: GetBuilder(
                              init: MapMainController(),
                              id: widget.controller.rxOnlineStatus.id,
                              builder: (val) {
                                return InkWell(
                                    onTap: () {
                                      if (widget.controller.rxOnlineStatus.value && !widget.controller.isDriverAccept()) {
                                        widget.controller.change(rxVariable: widget.controller.rxOnlineSliderController, value: false);
                                      }
                                    },
                                    child: (!widget.controller.rxOnlineStatus.value)
                                        ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 4,
                                          width: 60,
                                          margin:
                                          EdgeInsetsDirectional.only(
                                              top: 14),
                                          decoration: BoxDecoration(
                                              color:
                                              AppColors.COMMON_BG_COLOR,
                                              borderRadius:
                                              BorderRadius.all(
                                                  Radius.circular(5),
                                              ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                          EdgeInsetsDirectional.symmetric(vertical: 28),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                EdgeInsetsDirectional
                                                    .only(top: 5,start: 5),
                                                child:
                                                SvgPicture.asset(
                                                  globals.isDarkTheme
                                                      ? strikeoutCarWhiteSvg
                                                      : strikeoutCarDarkSvg,
                                                  width: 32,
                                                  height: 22,
                                                  fit: BoxFit
                                                      .scaleDown,
                                                ),
                                              ),
                                              Flexible(
                                                child: Padding(
                                                  padding:
                                                  EdgeInsetsDirectional
                                                      .only(start: 5,end: 5),
                                                  child: FittedBox(
                                                    child: Text(
                                                        you_offline.tr,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: AppDimen.text_size_20,
                                                            fontFamily: AppFont.font)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                        : GetBuilder(
                                      init: MapMainController(),
                                        id: widget.controller.rxOnlineSliderController.id,
                                        builder: (val) {
                                        debugPrint("controller.rxOnlineSliderController: ${widget.controller.rxOnlineSliderController.value} --- ${val.rxOnlineSliderController.value}");
                                          return SafeArea(
                                            child: AnimatedContainer(
                                              curve: Curves.fastOutSlowIn,
                                              duration:
                                              Duration(milliseconds: 300),
                                              height: val.rxOnlineSliderController.value == false
                                                  ? 110.0
                                                  : 304.0,
                                              child: Wrap(children: <Widget>[
                                                Column(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      height: 4,
                                                      width: 60,
                                                      margin:
                                                      EdgeInsetsDirectional
                                                          .only(top: 14),
                                                      decoration: BoxDecoration(
                                                          color: AppColors
                                                              .COMMON_BG_COLOR,
                                                          borderRadius: BorderRadius.all(Radius.circular(5))),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsetsDirectional.only(top: 28),
                                                      child: InkWell(
                                                        onTap: () {
                                                          if (!widget.controller.isDriverAccept()) {
                                                            widget.homeViewState.bottomSheetHeight=110;
                                                            debugPrint(" widget.homeViewState.bottomSheetHeight: 2 ${ widget.homeViewState.bottomSheetHeight}");
                                                            widget.controller.change(rxVariable: widget.controller.rxOnlineSliderController, value: val.rxOnlineSliderController.value == false);
                                                            debugPrint("widget.controller.rxOnlineSliderController.value: 23 ${widget.controller.rxOnlineSliderController.value}");
                                                          }
                                                        },
                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsetsDirectional.only(top: 5,start: 5),
                                                              child:
                                                              SvgPicture
                                                                  .asset(
                                                                globals.isDarkTheme
                                                                    ? onlineCarDarkSvg
                                                                    : onlineCarSvg,
                                                                width: 32,
                                                                height: 22,
                                                                colorMapper: !globals.isDarkTheme ? ChatIconColorMapper(AppColors.ICON_COLOUR) : null,
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                              ),
                                                            ),
                                                            Flexible(
                                                              child: Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .only(
                                                                    start:
                                                                    5,end: 5),
                                                                child: FittedBox(
                                                                  child: Text(
                                                                      you_online.tr,
                                                                      maxLines: 1,
                                                                      style: TextStyle(
                                                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                          fontWeight: FontWeight.w500,
                                                                          fontSize: AppDimen.text_size_20,
                                                                          fontFamily: AppFont.font)
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: EdgeInsetsDirectional
                                                                  .only(
                                                                  top: 5,
                                                                  start:
                                                                  5,end: 5),
                                                              child:
                                                              RotatedBox(
                                                                quarterTurns: val.rxOnlineSliderController.value == true ? 2:0,
                                                                  child: SvgPicture
                                                                  .asset(
                                                                primaryUpArrow,
                                                                width:
                                                                15,
                                                                height:
                                                                10,
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                colorFilter: ColorFilter.mode(
                                                                    AppColors.ICON_COLOUR,
                                                                    BlendMode.srcIn),
                                                              ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                      EdgeInsetsDirectional
                                                          .only(top: 28),
                                                      child: Container(
                                                        height: val.rxOnlineSliderController.value == false
                                                            ? 0
                                                            : 200,
                                                        width: Get.width,
                                                        color: val.rxOnlineSliderController.value == false
                                                            ? AppColors
                                                            .PRIMARY_COLOR_WHITE
                                                            : AppColors
                                                            .OFFLINE_COLOR,
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                                height: 98,
                                                                width: 98,
                                                                margin: EdgeInsets
                                                                    .only(
                                                                    top:
                                                                    26),
                                                                decoration: BoxDecoration(
                                                                    border: Border.all(
                                                                        color: AppColors
                                                                            .ONLINE_STATUS,
                                                                        width:
                                                                        14),
                                                                    shape: BoxShape
                                                                        .circle),
                                                                child:
                                                                Container(
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    border: Border.all(
                                                                        color:
                                                                        AppColors.PRIMARY_COLOR_WHITE,
                                                                        width: 2),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child:
                                                                  RawMaterialButton(
                                                                    onPressed:
                                                                        () {
                                                                      widget.homeViewState.internetCheckOnMapMainScreen?.checkInternetTrackLoc("goofflineclick");
                                                                    },
                                                                    splashColor:
                                                                    AppColors.ONLINE_STATUS,
                                                                    fillColor:
                                                                    AppColors.ONLINE_STATUS,
                                                                    shape:
                                                                    CircleBorder(),
                                                                    child:
                                                                    Padding(
                                                                      padding:
                                                                      EdgeInsets.all(10.0),
                                                                      child: GetBuilder(
                                                                        init: MapMainController(),
                                                                          id: widget.controller.rxLoadingController.id,
                                                                          builder: (val) {
                                                                            return widget.controller.rxLoadingController.value == false
                                                                                ? SvgPicture.asset(
                                                                              strikeoutCarWhiteSvg,
                                                                              height: 26.0,
                                                                              width: 38.0,
                                                                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                                                                            )
                                                                                : CircularProgressIndicator(
                                                                              strokeWidth: 2.0,
                                                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.PRIMARY_COLOR_WHITE),
                                                                            );
                                                                          }),
                                                                    ),
                                                                  ),
                                                                )),
                                                            Padding(
                                                              padding:
                                                              EdgeInsets
                                                                  .all(
                                                                  16.0),
                                                              child: Text(
                                                                go_offline.tr,
                                                                style: TextStyle(
                                                                    color: AppColors
                                                                        .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                    fontSize:
                                                                    AppDimen
                                                                        .text_size_20,
                                                                    fontFamily:
                                                                    AppFont.font),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ]),
                                            ),
                                          );
                                        }));
                              }),
                        ),
                      ));
                    }),

            ),
          );
        }
    );
  }
}