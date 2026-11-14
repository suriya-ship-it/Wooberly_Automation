import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app.dart';

import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/circle_progress.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/ride_request_bottom_view.dart';
import 'package:wooberly_driver/widgets/size_find_widget.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_lang.dart';

class RideRequestTransitionView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideRequestTransitionView(
      {required this.homeViewState});

  @override
  State<RideRequestTransitionView> createState() =>
      _RideRequestTransitionViewState();
}

class _RideRequestTransitionViewState extends State<RideRequestTransitionView> {
  RideRequestBottomView? rideRequestBottomView;
  double? _panelHeightOpen, _panelHeightClosed, _tripArrowPosition;
  ScrollController? _scrollcontroller;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getInitialSetUp();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (rideRequestBottomView == null) _getInitialSetUp();
    return SlideTransition(
      position: widget.homeViewState.rideFetchOffset!,
      child: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: GetBuilder(
          init: widget.controller,
          id: widget.homeViewState.rxChangeTripArrowPosition.id,
          builder: (val) {

              _tripArrowPosition = widget.homeViewState.rxChangeTripArrowPosition.value == true
                  ? (_panelHeightOpen)
                  : (_panelHeightClosed);
              if (_scrollcontroller != null && _scrollcontroller!.hasClients)
                _scrollcontroller?.jumpTo(0.0);
              return AnimatedContainer(
                duration:const Duration(milliseconds: 20),
                height: widget.homeViewState.rxChangeTripArrowPosition.value == true
                    ? _panelHeightOpen
                    : _panelHeightClosed,
                color: Colors.transparent,
                child: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: [
                    Container(
                      height: widget.homeViewState.rxChangeTripArrowPosition.value == true
                          ? _panelHeightOpen
                          : _panelHeightClosed,
                      margin: const EdgeInsetsDirectional.only(top: 20),
                      padding: const EdgeInsetsDirectional.only(top: 20),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.COMMON_BG_COLOR,
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                        color: AppColors.PRIMARY_COLOR_WHITE,
                        borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight:const  Radius.circular(10)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        controller: _scrollcontroller,
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Builder(
                          builder: (context) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugPrint("requestsize: 34 ${context.size} --- ${widget.homeViewState.rxChangeTripArrowPosition.value}");
                              _panelHeightOpen = Get.height * 0.90;
                              if(context.size!.height.toDouble()+60 < _panelHeightOpen!){
                                _panelHeightOpen = context.size!.height.toDouble()+60;
                              }
                              debugPrint("requestsize: ${_panelHeightOpen}");
                            });
                            return Column(children: <Widget>[
                              Padding(
                                padding:const EdgeInsetsDirectional.only(top: 40),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: GetBuilder(
                                            init: MapMainController(),
                                            id: widget.controller.rxRiderNameTextShownController.id,
                                            builder: (val) {
                                              return Text(
                                                widget.controller.riderName,
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: AppFont.font,
                                                  fontSize: AppDimen.text_size_16,
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                        child: Center(
                                            child: _getAnimatedProgress(true))),
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color:
                                              AppColors.DIVIDER_COLOR,
                                              borderRadius:
                                              BorderRadius.circular(14)),
                                          padding: const EdgeInsetsDirectional.symmetric(
                                             horizontal: 15,vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GetBuilder(
                                                  init: MapMainController(),
                                                  id: widget.controller.rxProfileInfoupdateController.id,
                                                  builder: (val) {
                                                    return new Text(
                                                      widget.controller.rating !=
                                                          null &&
                                                          double.parse(widget
                                                              .controller
                                                              .rating
                                                              .toString()) !=
                                                              0
                                                          ? double.parse(widget
                                                          .controller.rating
                                                          .toString())
                                                          .toStringAsFixed(1)
                                                          .toString()
                                                          : "0",
                                                      style: TextStyle(
                                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize:
                                                          AppDimen.text_size_16,
                                                          fontWeight:
                                                          FontWeight.w500,
                                                          fontFamily: AppFont.font),
                                                    );
                                                  }),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              SvgPicture.asset(
                                                ratingFullSvg,
                                                width: 12,
                                                height: 12,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const
                                EdgeInsetsDirectional.only(start: 24, end: 24,bottom: 105),
                                child: Column(
                                  children: [
                                    rideRequestBottomView!.showDistanceAndDuration(),
                                    rideRequestBottomView!.showEstimatedPrice(),
                                    rideRequestBottomView!.showLocations(),
                                  ],
                                ),
                              ),
                            ]);
                          }
                        ),
                      ),
                    ),
                    _showAcceptDeclineView(),

                     Builder(
                       builder: (context) {
                         debugPrint("_panelHeightOpen: ${_panelHeightOpen} --- ${_panelHeightClosed}");
                         return (_panelHeightOpen?? 0) > (_panelHeightClosed ?? 0) ?
                           PositionedDirectional(
                          end: 24,
                          bottom: _tripArrowPosition! - 40,
                          child: InkWell(
                              onTap: () {

                                if (widget.homeViewState.rxChangeTripArrowPosition.value == false) {
                                  widget.homeViewState.timerHeight =
                                  _panelHeightOpen!;
                                  widget.controller.change(rxVariable: widget.homeViewState.rxChangeTripArrowPosition, value: true);
                                } else {
                                  widget.homeViewState.timerHeight =
                                  _panelHeightClosed!;
                                  widget.controller.change(rxVariable: widget.homeViewState.rxChangeTripArrowPosition, value: false);
                                }
                                _scrollcontroller?.jumpTo(0.0);
                              },
                              child: rideRequestBottomView
                                  ?.showArrowUpDown(widget.homeViewState.rxChangeTripArrowPosition.value == true)),
                           ) : const SizedBox.shrink();
                       }
                     )
                  ],
                ),
              );
            }),
      ),
    );
  }


  Widget _showAcceptDeclineView(){
    return Container(
      decoration:
      BoxDecoration(color: AppColors.COMMON_BG_COLOR),
      height: 105,
      padding:const  EdgeInsetsDirectional.symmetric(
          vertical: 21, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => widget.controller.isTripAcceptLoading.value !=null ?
          InkWell(
            onTap:
                () async {

              debugPrint("isTripAcceptLoading.value: ${widget.controller.isTripAcceptLoading.value} --- ${globals.socket?.connected}");


              widget.controller.checkInternet(() {
                debugPrint("isTripAcceptLoading.value: ${widget.controller.isTripAcceptLoading.value} --- ${globals.socket?.connected}");
                if (globals.socket !=null && globals.socket!.connected ) {
                  if (!widget.controller.isTripAcceptLoading.value) {
                    widget.controller.change(
                        rxVariable: widget.homeViewState
                            .rxChangeTripArrowPosition,
                        value: false);
                    App().stopRequestAudio();
                    widget.homeViewState.internetCheckOnMapMainScreen
                        ?.checkInternetTrackLoc("declinebtnclick");
                    globals.tripInfo = null;
                    globals.isShowMapPage = true;
                  }
                }
              },true);

            },
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  border: Border.all(
                      color: AppColors.PRIMARY_COLOR_DARK,
                      width: 1),
                  borderRadius:
                  BorderRadius.all(Radius.circular(3))),
              padding: const EdgeInsetsDirectional.all(12),
              width: ((Get.width / 2) -
                  34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    closeWhiteSvg,
                    width: 18,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                        AppColors.ICON_COLOUR, BlendMode.srcIn),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                      child: Text(
                        btn_decline.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_18),
                      ))
                ],
              ),
            ),
          ) : const SizedBox.shrink(),
          ),
          Obx(() => widget.controller.isTripAcceptLoading.value!=null ? InkWell(
            onTap: () async {
              widget.controller.checkInternet(() {
                debugPrint("isTripAcceptLoading.value: ${widget.controller.isTripAcceptLoading.value} --- ${globals.socket?.connected}");
                if( globals.socket !=null && globals.socket!.connected && ! widget.controller.isTripAcceptLoading.value) {
                  widget.controller.change(
                      rxVariable: widget.homeViewState.rxChangeTripArrowPosition,
                      value: false);
                  App().stopRequestAudio();
                  globals.isShowMapPage = true;
                  widget.homeViewState.internetCheckOnMapMainScreen
                      ?.checkInternetTrackLoc("acceptbtnclick");
                  widget.controller.isTripAcceptLoading.value = true;
                }
              }, true);
            },
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_DARK,
                  borderRadius:
                  BorderRadius.all(Radius.circular(3))),
              padding: EdgeInsetsDirectional.all(12),
              width: ((Get.width / 2) - 34),
                height: 105,
                margin:const  EdgeInsetsDirectional.symmetric(
                    vertical: 5),
              child:
              widget.controller.isTripAcceptLoading.value
                  ? Center(
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.PRIMARY_COLOR,
                  ),
                ),
              )
                  :

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    acceptTickSvg,
                    width: 18,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                        AppColors.WHITE_ICON_COLOR,
                        BlendMode.srcIn),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      btn_accept.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_18),
                    ),
                  )
                ],
              ),
            ),
          )  : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }



  Widget _getAnimatedProgress(bool isvalue) {
    return GetBuilder(
      init: MapMainController(),
        id: widget.controller.rxLoadTimerController.id,
        builder: (val) {
          if (val.rxLoadTimerController.value == true) {
            if (globals.progressLoadTime > globals.notificationInterval)
              globals.progressLoadTime = globals.notificationInterval;
            return Center(
              child: CustomPaint(
                foregroundPainter: CircleProgress(
                    (widget.controller.tripRequestAnimation!.value > 0)
                        ? widget.controller.tripRequestAnimation!.value
                        : 0),
                child: SizedBox(
                  width: Get.width / 3.5,
                  height: Get.width / 3.5,
                  child: GestureDetector(
                    onTap: () async {
                    },
                    child: Center(
                      child: Text(
                        (globals.progressLoadTime.toDouble() >=
                            widget.controller.tripRequestAnimation!.value)
                            ? (globals.progressLoadTime.toDouble() -
                            widget
                                .controller.tripRequestAnimation!.value)
                        .toStringAsFixed(0)
                            : '0',
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_36,
                            fontFamily: AppFont.font),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        });
  }

  void _getInitialSetUp() {
    double _halfDeviceHeight = Get.height / 2;
    _panelHeightClosed = _halfDeviceHeight + 20;
    _tripArrowPosition = (_panelHeightClosed)! - 20;
    widget.homeViewState.timerHeight = _tripArrowPosition! + 20;
    _panelHeightOpen = Get.height * 0.90;
    _scrollcontroller = ScrollController();
    rideRequestBottomView = RideRequestBottomView(
        context: context,
        homeViewState: widget.homeViewState);

  }
}