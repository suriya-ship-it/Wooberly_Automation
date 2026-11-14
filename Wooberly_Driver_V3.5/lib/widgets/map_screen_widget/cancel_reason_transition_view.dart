import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:get/get.dart';
import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';
import '../confirm_cancel_popup.dart';
import '../primary_button.dart';
import '../primary_scaffold.dart';
import '../show_done_view.dart';

class CancelReasonTransitionView extends StatefulWidget {
  final HomeViewState homeViewState;
  final TripPlannerIF tripPlannerIF;

  const CancelReasonTransitionView(
      {Key? key,
      required this.homeViewState,
      required this.tripPlannerIF})
      : super(key: key);

  @override
  State<CancelReasonTransitionView> createState() =>
      _CancelReasonTransitionViewState();
}

class _CancelReasonTransitionViewState extends State<CancelReasonTransitionView>
    with TickerProviderStateMixin {
  final _cancelReasonScrollController = new ScrollController();
  FocusNode _focus = new FocusNode();
  late BuildContext scaffoldContext;
  final MapMainController controller = Get.find();
  bool isConfirmPopupOpen = false, isLoading = true;
  var rxLoadingController = ReactiveVariable("rxLoadingController", true);

  @override
  void initState() {
    controller.rxConfirmCancelTripScreenController.stream.listen((event) {
      isConfirmPopupOpen = event;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCancelReason();
    });
    super.initState();
  }

  getCancelReason() async {
    controller.setLoadingController(true);
    controller.change(rxVariable: controller.rxCancelReasonListController, value: true);
    controller.getcancelreason().then((value) {
      controller.setLoadingController(false);
      isLoading = false;
      if (value == "offline") {
        controller.change(rxVariable: controller.rxCancelReasonListController, value: false);
        controller.checkInternet(getCancelReason, false);
      } else if (value!.isNotEmpty) {
        controller.change(rxVariable: controller.rxCancelReasonListController, value: false);
        controller.showInSnackBar(value);
      } else {
        controller.change(rxVariable: rxLoadingController, value: false);
        if (widget.homeViewState.tripPlannerContext != null)
          Get.back();
        controller.change(rxVariable: controller.rxCancelReasonListController, value: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Stack(
      children: [
        PrimaryScaffold(
          disableAppbar: false,
          appBarTitle: cancellation_reason.tr,
          customAppBarFunction: () {
            if (isConfirmPopupOpen) {
              controller.rxConfirmCancelTripScreenController.value = false;
            } else {
              App().setBackNavigation();
            }
          },
          body: GetBuilder(
              init: MapMainController(),
              id: rxLoadingController.id,
              builder: (val) {
                return !isLoading
                    ? Column(
                        children: [
                          Expanded(
                            child: GetBuilder(
                              init: MapMainController(),
                              id: controller.rxCancelReasonListController.id,
                              builder: (val) {
                                return Container(
                                    height: (Get.height * 0.76),
                                    padding: EdgeInsetsDirectional.symmetric(vertical: 9),
                                    child: controller.cancelReasonList.isNotEmpty
                                            ? ListView.builder(
                                                itemCount: controller.cancelReasonList.length + 2,
                                                controller: _cancelReasonScrollController,
                                                physics: AlwaysScrollableScrollPhysics(),
                                                addAutomaticKeepAlives: true,
                                                itemBuilder: (BuildContext ctxt,
                                                    int index) {
                                                  if (index == 0) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .only(
                                                                  start: 24.0,
                                                                  end: 24.0,
                                                                  top: 27.0,
                                                                  bottom: 18),
                                                      child: Text(
                                                        cancellation_reason_feedback.tr,
                                                        style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontWeight: FontWeight.w400,
                                                            fontFamily: AppFont.font),
                                                      ),
                                                    );
                                                  } else if (index == controller.cancelReasonList.length + 1) {
                                                    return GetBuilder(
                                                      init: MapMainController(),
                                                        id: controller.rxOtherReasonSelectController.id,
                                                        builder: (val) {
                                                          if (controller.rxOtherReasonSelectController.value == false) {
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                                () {
                                                              _cancelReasonScrollController
                                                                  .animateTo(
                                                                _cancelReasonScrollController
                                                                    .position
                                                                    .maxScrollExtent,
                                                                curve: Curves
                                                                    .easeOut,
                                                                duration: const Duration(
                                                                    milliseconds:
                                                                        100),
                                                              );
                                                            });
                                                          }
                                                          return controller.rxOtherReasonSelectController.value == false
                                                              ? Padding(
                                                                  padding: EdgeInsetsDirectional.only(
                                                                      start:
                                                                          24.0,
                                                                      end:
                                                                          24.0,
                                                                      bottom: MediaQuery.of(context)
                                                                          .viewInsets
                                                                          .bottom),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: AppColors
                                                                          .PRIMARY_COLOR_WHITE,
                                                                      borderRadius:
                                                                          const BorderRadius.all(
                                                                        const Radius
                                                                            .circular(
                                                                            10.0),
                                                                      ),
                                                                    ),
                                                                    child: Padding(
                                                                      padding: EdgeInsetsDirectional.only(
                                                                          start: 5,
                                                                          end: 5,
                                                                          top: 5,
                                                                          bottom: 5),
                                                                      child: TextFormField(
                                                                        controller: controller.otherReasonController,
                                                                        maxLength:
                                                                            200,
                                                                        maxLines:
                                                                            3,
                                                                        enableIMEPersonalizedLearning:
                                                                            false,
                                                                        focusNode:
                                                                            _focus,
                                                                        style: TextStyle(
                                                                            fontFamily: AppFont.font,
                                                                            fontSize: AppDimen.text_size_14,
                                                                            fontWeight: FontWeight.w400,
                                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                                                        decoration:
                                                                            InputDecoration(
                                                                          hintText:
                                                                              enter_your_reason.tr,
                                                                          hintStyle: TextStyle(
                                                                              fontFamily: AppFont.font,
                                                                              fontSize: AppDimen.text_size_14,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: AppColors.HIND_TEXT_COLOR),
                                                                          contentPadding:
                                                                              EdgeInsets.all(8.0),
                                                                          border:
                                                                              InputBorder.none,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              : SizedBox.shrink();
                                                        });
                                                  } else {
                                                    return Container(
                                                        margin: EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 15),
                                                        padding: EdgeInsetsDirectional.all(13),
                                                        decoration: BoxDecoration(
                                                            color: AppColors.PRIMARY_COLOR_WHITE,
                                                            borderRadius: BorderRadius.all(Radius.circular(10))),
                                                        child: InkWell(
                                                            onTap: () {
                                                                if (controller.cancelReasonList[index - 1]['id'] == "0") {
                                                                  controller.otherReasonController.text = "";
                                                                  controller.change(rxVariable: controller.rxOtherReasonSelectController, value: false);
                                                                } else {
                                                                  controller.otherReasonController.text = "";
                                                                  controller.change(rxVariable: controller.rxOtherReasonSelectController, value: true);
                                                                }
                                                                controller.selectedCancelReason = controller.cancelReasonList[index - 1];
                                                                controller.change(rxVariable: controller.rxRadioListSelectController, value: true);
                                                            },
                                                            child: GetBuilder(
                                                              init: MapMainController(),
                                                              id: controller.rxRadioListSelectController.id,
                                                              builder: (val) {
                                                                return Row(
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          AlignmentDirectional
                                                                              .centerStart,
                                                                      child: Center(
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              20,
                                                                          width: 20,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: AppColors.PRIMARY_COLOR_WHITE,
                                                                              border: Border.all(
                                                                                color: ((controller.selectedCancelReason != null && controller.selectedCancelReason.length > 0) && (controller.selectedCancelReason['id'] == controller.cancelReasonList[index - 1]['id']))
                                                                                    ? AppColors.PRIMARY_COLOR_DARK
                                                                                    : AppColors.BORDERCOLOR,
                                                                              )),
                                                                          child: Padding(
                                                                              padding: const EdgeInsets.all(4.0),
                                                                              child: ((controller.selectedCancelReason != null && controller.selectedCancelReason.length > 0) && (controller.selectedCancelReason['id'] == controller.cancelReasonList[index - 1]['id']))
                                                                                  ? Container(
                                                                                      decoration: BoxDecoration(
                                                                                      color: AppColors.PRIMARY_COLOR_DARK,
                                                                                      shape: BoxShape.circle,
                                                                                    ))
                                                                                  : SizedBox.shrink()),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Container(
                                                                        alignment:
                                                                            AlignmentDirectional
                                                                                .centerStart,
                                                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12),
                                                                        child: Text(
                                                                          controller
                                                                                  .cancelReasonList[
                                                                              index -
                                                                                  1]['reason'],
                                                                          textAlign:
                                                                              TextAlign
                                                                                  .start,
                                                                          style: TextStyle(
                                                                              fontSize: AppDimen
                                                                                  .text_size_14,
                                                                              fontWeight: FontWeight
                                                                                  .w500,
                                                                              fontFamily: AppFont
                                                                                  .font,
                                                                              color:
                                                                                  AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              }
                                                            )));
                                                  }
                                                },
                                              )
                                            : SizedBox.shrink());
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsetsDirectional.symmetric(horizontal: 24.0),
                              child: GetBuilder(
                                init: MapMainController(),
                                  id: controller.rxRadioListSelectController.id,
                                  builder: (val) {
                                    return Opacity(
                                        opacity: (controller.rxRadioListSelectController.value == true) ? 1 : 0.2,
                                        child: PrimaryButton(
                                            buttonTitle: submit.tr,
                                            buttonImage: primaryBtnArrow,
                                            callback: () {
                                              if (controller
                                                          .selectedCancelReason[
                                                      'id'] ==
                                                  "0") {
                                                if (controller
                                                            .otherReasonController
                                                            .text !=
                                                        null &&
                                                    controller
                                                        .otherReasonController
                                                        .text
                                                        .isNotEmpty) {
                                                  controller
                                                          .otherCancelReason =
                                                      controller
                                                          .otherReasonController
                                                          .text;
                                                  controller.rxConfirmCancelTripScreenController.value = true;
                                                } else {
                                                  controller.showInSnackBar(
                                                      please_enter_the_reason.tr);
                                                }
                                              } else {
                                                controller.rxConfirmCancelTripScreenController.value = true;
                                              }
                                            }));
                                  }),
                            ),
                          )
                        ],
                      )
                    : controller.getProgressIndicator(scaffoldContext, AppColors.PRIMARY_COLOR_DARK);
              }),
          onChanged: (map) {
            scaffoldContext = map["scaffoldcontext"];
          },
        ),
        Obx(() {
          return controller.rxConfirmCancelTripScreenController.value ? ConfirmCancelTrip(true, widget.tripPlannerIF,widget.homeViewState) : SizedBox.shrink();
        }),
        Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            right: 0.0,
            left: 0.0,
            child: MediaQuery.of(context).viewInsets.bottom >= 175.0
                ? InputDoneView()
                : const SizedBox.shrink()),
      ],
    );
  }

}