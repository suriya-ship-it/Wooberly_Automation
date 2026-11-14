import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/widgets/confirm_cancel_popup.dart';
import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';
import '../widgets/show_done_view.dart';
import 'map_main_screen.dart';

class CancelTrip extends StatefulWidget {
  late final HomeViewState state;

  CancelTrip({Key? key, required this.state}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CancelTripState();
  }
}

class CancelTripState extends State<CancelTrip> {
  MapMainController mapMainController = Get.find();
  FocusNode _focus = new FocusNode();
  final cancelReasonScrollController = new ScrollController();

  RxBool isLoading = true.obs;
  late BuildContext scaffoldContext;
  bool isConfirmPopupOpen = false;

  @override
  void initState() {
    mapMainController.updateRxValue(mapMainController.otherReasonSelectController,true);
 if(mapMainController.closeCancelTripController ==null)
   mapMainController.closeCancelTripController = false.obs;
    ever(mapMainController.closeCancelTripController!, (event) {
      if ((ModalRoute.of(Get.context!)?.isCurrent ?? false))
        Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN);
    });

    mapMainController.confirmCancelTripScreenController.stream.listen((event) {
      isConfirmPopupOpen = event;
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      getCancelReason();
    });
    super.initState();
  }

  getCancelReason() async {
    mapMainController.getCancelReason().then((value) {
      mapMainController.updateRxValue(mapMainController.cancelReasonListController, false);
      if (value == "timeout") {
        mapMainController.showInSnackBar("Request timeout, please try again");
      } else if (value.isNotEmpty) {
        mapMainController.showInSnackBar( value);
      } else {
        isLoading.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return Stack(
          children: [
            PrimaryScaffold(
              disableAppbar: false,
              appBarTitle: 'cancellation_reason'.tr,
              loader: '',
              customAppBarFunction: () {
                if (isConfirmPopupOpen) {
                  mapMainController.confirmCancelTripScreenController(false);
                } else {
                  mapMainController.setBackNavigation();
                }
              },
              body: Obx(() {
                    return !isLoading.value
                        ? Column(
                            children: [
                              GetBuilder<MapMainController>(
                               id:'cancelReasonListController',
                                builder: (_) {
                                  return mapMainController.cancelReasonList.isNotEmpty
                                      ? Expanded(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount:
                                                mapMainController.cancelReasonList.length +
                                                    2,
                                            controller:
                                                cancelReasonScrollController,
                                            physics:
                                                AlwaysScrollableScrollPhysics(),
                                            addAutomaticKeepAlives: true,
                                            itemBuilder:
                                                (BuildContext ctxt, int index) {
                                              if (index == 0) {
                                                return Padding(
                                                  padding:
                                                      EdgeInsetsDirectional.only(
                                                          start: 24.0,
                                                          end: 24.0,
                                                          top: 27.0,
                                                          bottom: 18),
                                                  child: Text(
                                                    'cancellation_reason_feedback'.tr,
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .BLACK_TEXT_COLOR,
                                                        fontSize:
                                                            AppDimen.text_size_14,
                                                        fontWeight: FontWeight.w400,
                                                        fontFamily: AppFont.font),
                                                  ),
                                                );
                                              } else if (index ==
                                                  mapMainController
                                                          .cancelReasonList.length +
                                                      1) {
                                                return GetBuilder<MapMainController>(
                                                    id:'otherReasonSelectController',
                                                    builder: (builder) {
                                                      debugPrint("otherReasonSelectControllervalue: ${builder.otherReasonSelectController.value}");
                                                        if (!builder.otherReasonSelectController.value) {
                                                          Future.delayed(
                                                              const Duration(milliseconds: 100),
                                                                  () {
                                                            cancelReasonScrollController.animateTo(cancelReasonScrollController.position.maxScrollExtent,
                                                              curve: Curves.easeOut,
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          100),
                                                            );
                                                          });
                                                        }
                                                        return !builder.otherReasonSelectController.value
                                                            ? Padding(
                                                                padding:  EdgeInsetsDirectional.only(
                                                                    start: 24.0,
                                                                    end: 24.0,
                                                                    bottom: MediaQuery.of(
                                                                            context)
                                                                        .viewInsets
                                                                        .bottom),
                                                                child: Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AppColors
                                                                        .PRIMARY_LIGHT_COLOR,
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                      const Radius
                                                                          .circular(
                                                                          10.0),
                                                                    ),
                                                                  ),
                                                                  child: Padding(
                                                                    padding: const EdgeInsetsDirectional
                                                                        .all(5),
                                                                    child:
                                                                        TextFormField(
                                                                      enableIMEPersonalizedLearning: false,
                                                                      controller: mapMainController.otherReasonController,
                                                                      maxLength: 200,
                                                                      maxLines: 3,
                                                                      focusNode:
                                                                          _focus,
                                                                      style: TextStyle(
                                                                          fontFamily:
                                                                              AppFont
                                                                                  .font,
                                                                          fontSize:
                                                                              AppDimen
                                                                                  .text_size_14,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .w400,
                                                                          color: AppColors
                                                                              .BLACK_TEXT_COLOR),
                                                                      decoration:
                                                                          InputDecoration(
                                                                        hintText: 'enter_your_reason'.tr,
                                                                        hintStyle: TextStyle(
                                                                            fontFamily:
                                                                                AppFont
                                                                                    .font,
                                                                            fontSize:
                                                                                AppDimen
                                                                                    .text_size_14,
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .w400,
                                                                            color: AppColors.PLACEHOLDER_TEXT_COLOR),
                                                                        contentPadding:
                                                                            EdgeInsetsDirectional.all(
                                                                                8.0),
                                                                        border:
                                                                            InputBorder
                                                                                .none,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            : const SizedBox.shrink();
                                                    });
                                              } else {
                                                return GetBuilder<MapMainController>(
                                                    id:'radioListSelectController',
                                                    builder: (_) {
                                                      return Container(
                                                          margin:
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      start: 24,
                                                                      end: 24,
                                                                      bottom: 15),
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .all(13),
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  AppColors.PRIMARY_LIGHT_COLOR,
                                                              borderRadius:
                                                                  BorderRadius.all(
                                                                      Radius
                                                                          .circular(
                                                                              10))),
                                                          child: InkWell(
                                                              onTap: () {
                                                                if (mapMainController.cancelReasonList[index - 1]['id'] == "0") {
                                                                  mapMainController.otherReasonController.text = "";
                                                                  mapMainController.updateRxValue(mapMainController.otherReasonSelectController,false);
                                                                } else {
                                                                  mapMainController.otherReasonController.text = "";
                                                                  mapMainController.updateRxValue(mapMainController.otherReasonSelectController,true);
                                                                }
                                                                mapMainController.selectedCancelReason =
                                                                    mapMainController.cancelReasonList[index - 1];

                                                                mapMainController.updateRxValue(mapMainController.radioListSelectController, true);
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Align(
                                                                    alignment:
                                                                        AlignmentDirectional
                                                                            .centerStart,
                                                                    child: Center(
                                                                      child:
                                                                          Container(
                                                                        height: 20,
                                                                        width: 20,
                                                                        decoration: BoxDecoration(
                                                                            shape: BoxShape.circle,
                                                                            color: AppColors.PRIMARY_LIGHT_COLOR,
                                                                            border: Border.all(
                                                                              color: ((mapMainController.selectedCancelReason != null && mapMainController.selectedCancelReason.length > 0) && (mapMainController.selectedCancelReason['id'] == mapMainController.cancelReasonList[index - 1]['id']))
                                                                                  ? AppColors.PRIMARY_DARK_COLOR
                                                                                  : AppColors.RADIO_BUTTON_COLOR,
                                                                            )),
                                                                        child: Padding(
                                                                            padding: const EdgeInsetsDirectional.all(4.0),
                                                                            child: ((mapMainController.selectedCancelReason != null && mapMainController.selectedCancelReason.length > 0) && (mapMainController.selectedCancelReason['id'] == mapMainController.cancelReasonList[index - 1]['id']))
                                                                                ? Container(
                                                                                    decoration: BoxDecoration(
                                                                                    color: AppColors.PRIMARY_DARK_COLOR,
                                                                                    shape: BoxShape.circle,
                                                                                  ))
                                                                                : const SizedBox.shrink()),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Container(
                                                                      alignment:
                                                                          AlignmentDirectional
                                                                              .centerStart,
                                                                      padding: const EdgeInsetsDirectional
                                                                          .symmetric(horizontal: 12),
                                                                      child: Text(
                                                                        mapMainController
                                                                                .cancelReasonList[
                                                                            index -
                                                                                1]['reason'],
                                                                        textAlign:
                                                                            TextAlign
                                                                                .start,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                AppDimen
                                                                                    .text_size_14,
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .w500,
                                                                            fontFamily:
                                                                                AppFont
                                                                                    .font,
                                                                            color: AppColors
                                                                                .BLACK_TEXT_COLOR),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              )));
                                                    });
                                              }
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0,vertical: 15),
                                child: GetBuilder<MapMainController>(
                                   id:'radioListSelectController',
                                    builder: (builder) {
                                      return Opacity(
                                        opacity: (builder.radioListSelectController.value == true) ? 1 : 0.2,
                                        child: PrimaryButton(
                                          buttonTitle:
                                              'submit'.tr,
                                          buttonImage: primaryBtnArrow,
                                          callback: () {
                                            if (builder.radioListSelectController.value == true) {
                                              if (globals.tripStatus != "started") {
                                                if (mapMainController.selectedCancelReason['id'] == "0") {
                                                  if (mapMainController.otherReasonController.text.isNotEmpty) {
                                                    mapMainController.otherCancelReason = mapMainController.otherReasonController.text;
                                                    mapMainController.confirmCancelTripScreenController(true);
                                                  } else {
                                                    mapMainController.showInSnackBar('please_enter_the_reason'.tr);
                                                  }
                                                } else {
                                                  mapMainController.confirmCancelTripScreenController(true);
                                                }
                                              } else {
                                                mapMainController.updateRxValue(mapMainController.radioListSelectController, false);
                                                mapMainController.updateRxValue(mapMainController.otherReasonSelectController,true);
                                                mapMainController.selectedCancelReason = null;
                                                mapMainController.otherReasonController.text = "";
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    }),
                              )
                            ],
                          )
                        : mapMainController.getProgressIndicator();
                  }),
              onChanged: (map) {
                scaffoldContext = map["scaffoldcontext"];
              },
            ),
            Obx(() {
                return mapMainController.confirmCancelTripScreenController.value == true
                    ? ConfirmCancelTrip(
                        true, widget.state)
                    : const SizedBox.shrink();
              },
            ),
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
    );
  }

 
}