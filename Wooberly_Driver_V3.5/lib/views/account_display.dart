import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/app/model_theme.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/web_view_stripe.dart';

import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';

class AccountDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AccountDisplayView();
  }
}

class AccountDisplayView extends StatefulWidget {
  AccountDisplayView({Key? key}) : super(key: key);

  @override
  _AccountDisplayState createState() => new _AccountDisplayState();
}

class _AccountDisplayState extends State<AccountDisplayView> {
  final PayoutController controller = Get.find();
  BuildContext? scoffoldcontext;
  late int selectedindex;
  bool buttonClick = false;

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Map<String, dynamic> walletoptions = {}..addAll(globals.driverWalletOptionController.value);
    walletoptions['isDisablePage'] = 'payout';
    globals.driverWalletOptionController.value = walletoptions;
    controller.checkInternet(getPayouts, false);

    controller.rxPayoutStatusChangedController.stream.listen((data) {
      if (data) {
        controller.checkInternet(getPayouts, false);
      }
    });

    super.initState();
  }

  void getPayouts() {
    controller.getPayouts().then((value) {
      controller.isLoading.value = false;
      if (value.isNotEmpty) {
        controller.showInSnackBar(value);
      } else {
        controller.checkInternet(controller.getPaymentMethods, false);

        controller.setpayoutListController(controller.allPayouts?.getPayouts?.results ?? []);
      }
    });
  }

  changePayoutList() {
    controller.changePayoutConfig().then((value) {
      if (value.isNotEmpty) {
        controller.showInSnackBar(value);
        buttonClick = false;
      } else {
        if (controller.func == "remove") {
          if (controller.payoutDefaultIndex == selectedindex) {
            controller.payoutDefaultIndex = 1234567890;
          }
          controller.allPayouts?.getPayouts?.results?.removeWhere((item) => item.id == controller.selectedid);
        } else if (controller.func == "set") {
          controller.allPayouts?.getPayouts?.results?[selectedindex].defaultpayout = true;
          try {
            if (controller.payoutDefaultIndex != 1234567890)
              controller.allPayouts?.getPayouts?.results?[controller.payoutDefaultIndex].defaultpayout =
                  false;
          } on Exception catch (e, stack) {
            debugPrint("Error: $e");
            FirebaseCrashlytics.instance.recordError(e, stack);
          }
          controller.payoutDefaultIndex = selectedindex;
        }
        controller.setpayoutListController(controller.allPayouts?.getPayouts?.results ?? []);
        buttonClick = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (_, __, ___) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: payout.tr,
        body: SizedBox(
          width: Get.width,
          height: Get.height,
          child: GetBuilder(
              init: PayoutController(),
              id: controller.rxPayoutListController.id,
              builder: (val) {
                return Obx(() {
                  return controller.isLoading.value
                      ? controller.getProgressIndicator(context, AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR)
                      : controller.rxPayoutListController.value.length > 0
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                      start: 24, end: 24, bottom: 20),
                                  padding: const EdgeInsetsDirectional.all(10),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.DIVIDER_COLOR, width: 1),
                                      borderRadius: BorderRadius.all(Radius.circular(8))),
                                  child: InkWell(
                                    onTap: () {
                                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                                      controller.selectedCountry = "";
                                      if (globals.paymentMethods.contains(2) ||
                                          globals.paymentMethods.contains(5)) {
                                        App().setNavigation(AppRoutes.APP_SELECT_COUNTRY).then((onValue) {
                                          controller.checkInternet(getPayouts, false);
                                        });
                                      } else
                                        controller.showInSnackBar(disable_add_payout.tr);
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          addpayoutSvg,
                                          colorFilter:
                                              ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                        ),
                                        const SizedBox(
                                          width: 9,
                                        ),
                                        Flexible(
                                          child: Text(
                                            add_payout_method.tr,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontWeight: FontWeight.w500,
                                                fontSize: AppDimen.text_size_16,
                                                fontFamily: AppFont.font),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: new ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    shrinkWrap: true,
                                    itemCount: controller.rxPayoutListController.value.length ?? 0,
                                    itemBuilder: (BuildContext ctxt, int Index) {
                                      if (controller.rxPayoutListController.value[Index].isVerified == null)
                                        controller.rxPayoutListController.value[Index].isVerified = false;

                                      if (controller.rxPayoutListController.value[Index].defaultpayout ==
                                          null)
                                        controller.rxPayoutListController.value[Index].defaultpayout = false;

                                      if (controller.rxPayoutListController.value[Index].isVerified != null) {
                                        if ((controller.rxPayoutListController.value[Index].defaultpayout ??
                                                false) &&
                                            (controller.rxPayoutListController.value[Index].isVerified ??
                                                false)) controller.payoutDefaultIndex = Index;
                                      } else {
                                        controller.payoutDefaultIndex = 0;
                                      }
                                      return Container(
                                          decoration: BoxDecoration(
                                              color: AppColors.PRIMARY_COLOR_WHITE,
                                              borderRadius: BorderRadius.all(Radius.circular(8))),
                                          margin:
                                              const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
                                          child:
                                              new Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsetsDirectional.only(
                                                  start: 14, end: 14, top: 10, bottom: 8),
                                              child: Row(children: <Widget>[
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: SvgPicture.asset(
                                                          controller.rxPayoutListController.value[Index]
                                                                      .methodId ==
                                                                  6
                                                              ? payPalPaymentSVG
                                                              : controller.rxPayoutListController.value[Index]
                                                                          .methodId ==
                                                                      2
                                                                  ? stripeSvg
                                                                  : payStackSvg,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        controller.rxPayoutListController.value[Index]
                                                                    .methodId ==
                                                                6
                                                            ? App().getPaymentName(6)
                                                            : controller.rxPayoutListController.value[Index]
                                                                        .methodId ==
                                                                    2
                                                                ? App().getPaymentName(2)
                                                                : App().getPaymentName(5),
                                                        style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: AppDimen.text_size_16,
                                                            fontFamily: AppFont.font),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                controller.rxPayoutListController.value[Index]
                                                                .defaultpayout ==
                                                            false &&
                                                        (controller.rxPayoutListController.value.length ??
                                                                0) >
                                                            1
                                                    ? InkWell(
                                                        child: SvgPicture.asset(
                                                          payoutCloseSvg,
                                                          colorFilter: ColorFilter.mode(
                                                              AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                        ),
                                                        onTap: () {
                                                          globals.stripeAccountId = controller
                                                                  .rxPayoutListController
                                                                  .value[Index]
                                                                  .payEmail ??
                                                              "";

                                                          controller.func = "remove";
                                                          controller.selectedid = controller
                                                                  .rxPayoutListController.value[Index].id ??
                                                              0;
                                                          selectedindex = Index;
                                                          controller.checkInternet(changePayoutList, false);
                                                        })
                                                    : const SizedBox.shrink()
                                              ]),
                                            ),
                                            Padding(
                                              padding: const EdgeInsetsDirectional.symmetric(vertical: 5.0),
                                              child: Divider(
                                                height: 1.0,
                                                color: AppColors.DIVIDER_COLOR,
                                              ),
                                            ),
                                            Row(children: <Widget>[
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsetsDirectional.only(
                                                      top: 5, start: 14, end: 14, bottom: 10),
                                                  child: RichText(
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    text: TextSpan(
                                                      style: TextStyle(
                                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: AppDimen.text_size_14,
                                                        fontFamily: AppFont.font,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: "${details.tr}: ",
                                                          style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontFamily: AppFont.font,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: controller.rxPayoutListController.value[Index]
                                                                      .methodId ==
                                                                  2
                                                              ? "****${controller.rxPayoutListController.value[Index].last4Digits}"
                                                              : controller.rxPayoutListController.value[Index]
                                                                  .payEmail,
                                                          style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontFamily: AppFont.font,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ]),
                                            Visibility(
                                              visible:
                                                  controller.rxPayoutListController.value[Index].methodId !=
                                                      6,
                                              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsetsDirectional.only(
                                                        start: 14, end: 14, bottom: 10),
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: AppDimen.text_size_14,
                                                          fontFamily: AppFont.font,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: "${account_holder.tr}: ",
                                                            style: TextStyle(
                                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: AppDimen.text_size_14,
                                                              fontFamily: AppFont.font,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                "${toBeginningOfSentenceCase(controller.rxPayoutListController.value[Index].firstName.toString())} ${toBeginningOfSentenceCase(controller.rxPayoutListController.value[Index].lastName.toString())}",
                                                            style: TextStyle(
                                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: AppDimen.text_size_14,
                                                              fontFamily: AppFont.font,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ]),
                                            ),
                                            Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Padding(
                                                    padding: const EdgeInsetsDirectional.only(
                                                        start: 14, bottom: 10),
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: AppDimen.text_size_14,
                                                          fontFamily: AppFont.font,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: "${status.tr}: ",
                                                            style: TextStyle(
                                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: AppDimen.text_size_14,
                                                              fontFamily: AppFont.font,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                "${(controller.rxPayoutListController.value[Index].defaultpayout == true || controller.rxPayoutListController.value[Index].isVerified == true) ? ready.tr : not_ready.tr}",
                                                            style: TextStyle(
                                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: AppDimen.text_size_14,
                                                              fontFamily: AppFont.font,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional.only(start: 3, end: 14),
                                                    child: InkWell(
                                                      onTap: () {
                                                        Get.dialog(Obx(() {
                                                          return globals.isAutoThemeUpdated.value != null
                                                              ? AlertDialog(
                                                                  backgroundColor:
                                                                      AppColors.PRIMARY_COLOR_WHITE,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.all(
                                                                          Radius.circular(10.0))),
                                                                  title: Row(
                                                                    children: [
                                                                      Image.asset(dialogLogoPng,
                                                                          width: 40, height: 40.0),
                                                                      SizedBox(width: 15),
                                                                      Text(
                                                                        verification.tr,
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  content: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment.start,
                                                                    children: [
                                                                      Container(
                                                                        child: Text(
                                                                          tip_info.tr,
                                                                          style: TextStyle(
                                                                              fontSize:
                                                                                  AppDimen.text_size_16),
                                                                        ),
                                                                      ),
                                                                      SizedBox(height: 30),
                                                                      InkWell(
                                                                        onTap: () {
                                                                          Get.back();
                                                                        },
                                                                        child: Container(
                                                                          width: Get.width,
                                                                          height: 50,
                                                                          margin: const EdgeInsetsDirectional
                                                                              .only(start: 10),
                                                                          padding: const EdgeInsetsDirectional
                                                                              .symmetric(
                                                                            horizontal: 20,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                              color: AppColors
                                                                                  .PRIMARY_COLOR_DARK,
                                                                              borderRadius:
                                                                                  BorderRadius.circular(4)),
                                                                          child: FittedBox(
                                                                            fit: BoxFit.scaleDown,
                                                                            child: Text(okay.tr,
                                                                                style: TextStyle(
                                                                                    color: AppColors
                                                                                        .PRIMARY_COLOR_WHITE,
                                                                                    fontFamily: AppFont.font,
                                                                                    fontWeight:
                                                                                        FontWeight.w500,
                                                                                    fontSize: AppDimen
                                                                                        .text_size_16)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : SizedBox.shrink();
                                                        }));
                                                      },
                                                      child: (controller.rxPayoutListController.value[Index]
                                                                      .defaultpayout ==
                                                                  true ||
                                                              controller.rxPayoutListController.value[Index]
                                                                      .isVerified ==
                                                                  true)
                                                          ? const SizedBox.shrink()
                                                          : Padding(
                                                        padding: EdgeInsetsDirectional.only(bottom: 8),
                                                            child: SvgPicture.asset(
                                                                height: 15,
                                                                width: 15,
                                                                infoSvg,
                                                                colorFilter: ColorFilter.mode(
                                                                    AppColors.PRIMARY_COLOR_DARK,
                                                                    BlendMode.srcIn),
                                                              ),
                                                          ),
                                                    ),
                                                  )
                                                ]),
                                            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsetsDirectional.only(
                                                      start: 14, end: 14, bottom: 10),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: TextStyle(
                                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: AppDimen.text_size_14,
                                                        fontFamily: AppFont.font,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: "${currency.tr}: ",
                                                          style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontFamily: AppFont.font,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              "[${controller.rxPayoutListController.value[Index].currency}]",
                                                          style: TextStyle(
                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontFamily: AppFont.font,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ]),
                                            Padding(
                                              padding: const EdgeInsetsDirectional.only(
                                                  start: 14, end: 14, bottom: 14),
                                              child: InkWell(
                                                onTap: () {
                                                  if (!buttonClick) {
                                                    globals.stripeAccountId = controller
                                                            .rxPayoutListController.value[Index].payEmail ??
                                                        "";
                                                    if (controller
                                                            .rxPayoutListController.value[Index].isVerified ==
                                                        false) {
                                                      buttonClick = true;
                                                      verifyPayout();
                                                    } else {
                                                      if (controller.rxPayoutListController.value[Index]
                                                              .defaultpayout ==
                                                          false) {
                                                        buttonClick = true;
                                                        controller.func = "set";
                                                        controller.selectedid = controller
                                                                .rxPayoutListController.value[Index].id ??
                                                            0;
                                                        selectedindex = Index;
                                                        controller.checkInternet(changePayoutList, false);
                                                      }
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  height: 38.0,
                                                  decoration: BoxDecoration(
                                                    color: controller.rxPayoutListController.value[Index]
                                                                .defaultpayout ==
                                                            true
                                                        ? AppColors.PRIMARY_COLOR_WHITE
                                                        : AppColors.PRIMARY_COLOR_DARK,
                                                    border: Border.all(
                                                        color: controller.rxPayoutListController.value[Index]
                                                                    .defaultpayout ==
                                                                true
                                                            ? AppColors.PRIMARY_COLOR_DARK
                                                            : AppColors.PRIMARY_COLOR_WHITE,
                                                        width: 1.0),
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                  child: new Center(
                                                    child: new Text(
                                                      controller.rxPayoutListController.value[Index]
                                                                  .isVerified ==
                                                              false
                                                          ? controller.rxPayoutListController.value[Index]
                                                                      .defaultpayout ==
                                                                  true
                                                              ? default_string.tr
                                                              : verify.tr
                                                          : controller.rxPayoutListController.value[Index]
                                                                      .defaultpayout ==
                                                                  true
                                                              ? default_string.tr
                                                              : set_default.tr,
                                                      style: new TextStyle(
                                                          fontFamily: AppFont.font,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: AppDimen.text_size_16,
                                                          color: controller.rxPayoutListController
                                                                      .value[Index].defaultpayout ==
                                                                  true
                                                              ? AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR
                                                              : AppColors.PRIMARY_COLOR_WHITE),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]));
                                    },
                                  ),
                                )
                              ],
                            )
                          : controller.rxPayoutListController.value.length == 0
                              ? Column(
                                  children: [
                                    Container(
                                        margin: const EdgeInsetsDirectional.only(
                                            start: 24, end: 24, top: 30, bottom: 20),
                                        padding: EdgeInsetsDirectional.all(10),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.DIVIDER_COLOR, width: 1),
                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                        child: InkWell(
                                          onTap: () {
                                            SystemChannels.textInput.invokeMethod('TextInput.hide');
                                            if (globals.paymentMethods.contains(2) ||
                                                globals.paymentMethods.contains(5))
                                              App().setNavigation(AppRoutes.APP_SELECT_COUNTRY);
                                            else {
                                              controller.showInSnackBar(disable_add_payout.tr);
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                addpayoutSvg,
                                                colorFilter: ColorFilter.mode(
                                                    AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                              ),
                                              SizedBox(
                                                width: 9,
                                              ),
                                              Flexible(
                                                child: Text(
                                                  add_payout_method.tr,
                                                  style: TextStyle(
                                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: AppDimen.text_size_16,
                                                      fontFamily: AppFont.font),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 100, bottom: 20),
                                      child: SvgPicture.asset(
                                        emptyPayoutSvg,
                                        colorFilter:
                                            ColorFilter.mode(AppColors.DIVIDER_COLOR, BlendMode.srcIn),
                                      ),
                                    )
                                  ],
                                )
                              : controller.getProgressIndicator(
                                  context, AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR);
                });
              }),
        ),
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
      );
    });
  }

  void verifyPayout() {
    controller.VerifyPayout().then((value) {
      controller.setLoadingController(false);
      if (value.isNotEmpty) {
        buttonClick = false;
        controller.showInSnackBar(value);
      } else {
        buttonClick = false;
        Get.to(WebviewStripe());
      }
    });
  }

  @override
  void dispose() {
    Map<String, dynamic> walletoptions = {}..addAll(globals.driverWalletOptionController.value);
    walletoptions['isDisablePage'] = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.driverWalletOptionController.value = walletoptions;
    });

    super.dispose();
  }
}