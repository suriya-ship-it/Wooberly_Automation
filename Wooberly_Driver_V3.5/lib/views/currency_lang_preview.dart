import 'dart:io';

import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/lang_select.dart';
import 'package:wooberly_driver/widgets/primary_appbar.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/ai_lang_selection_widget.dart';
import '../widgets/tooltip_info_widget.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';

class CurrencyLanguagePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CurrencyLanguagePreviewView();
  }
}

class CurrencyLanguagePreviewView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CurrencyLanguagePreviewViewState();
}

class CurrencyLanguagePreviewViewState
    extends State<CurrencyLanguagePreviewView> {
  final EditAccountController controller = Get.find();

  String selectedOpt = "";
  int selectedPos = 0;
  late BuildContext scoffoldcontext;

  @override
  void initState() {

    controller.currencyDropDown.clear();
    graphQlObject.getGraphQlClientWithHeader();
    if (globals.preferredCurrency.isNotEmpty) {
      controller.currencyController.text =
          globals.currencySymbol + " - " + globals.preferredCurrency;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      controller.checkInternet(getcurrencyList, false);
      controller.checkInternet(globals.baseController.getAILanguageList, false);
      controller.checkInternet(globals.baseController.getUserAILanguage, false);
    });

    super.initState();
  }

  void getcurrencyList() {
    controller.getCurrencyList().then((value) {
      if (value == null)
        controller.netOffSnackbar(getcurrencyList, false);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
          getPreferredController();
          return Obx(() {
            globals.preferredLanguage.value;
            debugPrint(
                "preferredLanguage:builder ${currency_languages.tr}");
            return PrimaryScaffold(
              appBarTitle: currency_languages.tr,
              onChanged: (map) {
                scoffoldcontext = map["scaffoldcontext"];
              },
              customAppBarFunction: () {
                if (controller.movetosetting) {
                  globals.isDrawerOpen = true;
                  Get.offUntil(AppRoutes().getWidget(AppRoutes.APP_MAP_MAIN), (Route<dynamic> route) => false);
                  controller.movetosetting = false;
                } else {
                  Get.until((route) => route.settings.name == "/MapMainScreen");
                }
              },
              body: GetBuilder(
                  init: EditAccountController(),
                  id: controller.rxCurrencyListController.id,
                  builder: (val) {
                    return Container(
                      height: Get.height,
                      margin: const EdgeInsets.only(top: 30.0, left: 25, right: 25.0),
                      child: Column(
                        children: <Widget>[
                          _currencyBox(),
                          const SizedBox(height: 30.0),
                          _languageBox(title: 'label_app_text_lang'.tr, tooltipContent: 'label_tooltip_app_text_lang'.tr),
                          const SizedBox(height: 30.0),
                          if (globals.isVoiceTranslatorEnable)
                            AILangSelectionWidget(title: 'label_user_preferred_lang'.tr,tooltipcontent: 'label_tooltip_user_preferred_lang'.tr,isShowIcon: false),
                        ],
                      ),
                    );
                  }),
            );
          });
        }
    );
  }

  Widget _currencyBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
        maxLines: 5,
        text: TextSpan(
          children: [
            TextSpan(text: preferred_.trParams({"field2":currency.tr.toLowerCase()}),
              style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontSize: AppDimen.text_size_16,
              ),),
        ])),
        const SizedBox(
          height: 15.0,
        ),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(scoffoldcontext).hideCurrentSnackBar();
            if (controller.currencyDropDown.isNotEmpty)
              _settingModalBottomSheet(
                  currency.tr,
                  Get.height * 0.65);
          },
          child: Container(
            padding: const EdgeInsetsDirectional.only(
                end: 20.0, start: 20.0, top: 12.0, bottom: 12),
            color: AppColors.PRIMARY_COLOR_WHITE,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: globals.isRtlLang
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: controller.currencyController.text
                                    .toString()
                                    .split("-")[1]
                                    .trim(),
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_18,
                                    fontFamily: AppFont.font),
                              ),
                              TextSpan(
                                text:
                                    " (${controller.currencyController.text.toString().split("-")[0].trim()})",
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_18,
                                    fontFamily: 'Roboto'),
                              ),
                            ],
                          ),
                        ),
                      )),
                  flex: 95,
                ),
                SvgPicture.asset(
                  primaryDownArrow,
                  width: 7.0,
                  height: 8.0,
                  colorFilter:
                      ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  var hintText = 'lang_hint'.tr.obs;

  Widget _languageBox({required String title, required String tooltipContent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TooltipInfoWidget(title: title,tooltipcontent: tooltipContent),
       const SizedBox(height: 15.0),
        InkWell(
          onTap: () {
            Get.closeCurrentSnackbar();
            _settingModalBottomSheet(
                'lang_hint'.tr,
                MediaQuery.of(context).size.height * 0.45);
          },
          child: Container(
            color: AppColors.PRIMARY_COLOR_WHITE,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    enableIMEPersonalizedLearning: false,
                    decoration: new InputDecoration(
                        border: InputBorder.none,
                        hintText: 'lang_hint'.tr,
                        hintStyle: TextStyle(
                          color: AppColors.HIND_TEXT_COLOR,
                          fontWeight: FontWeight.w300,
                          fontSize: AppDimen.text_size_18,
                        ),
                        hoverColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                    controller: getLangController(),
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_18,
                    ),
                    enabled: false,
                  ),
                  flex: 95,
                ),
                SvgPicture.asset(
                  primaryDownArrow,
                  width: 7.0,
                  height: 8.0,
                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _settingModalBottomSheet(String option, double value) {
    debugPrint("controller.languageDropDown.length: ${controller.languageDropDown}");
    if(option == lang_hint.tr) {
      Get.to(LangSelect(isFrom: "currency_page"), transition: Transition.downToUp);
    } else {
      Get.bottomSheet(
          backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
          Consumer<ModelTheme>(
              builder: (context, ModelTheme themeNotifier, child) {
                return SafeArea(
                  bottom: Platform.isAndroid,
                  child: Container(
                    height: value,
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    padding: const EdgeInsets.only(top: 10.0),
                    child: ListView.builder(
                      itemCount: option == lang_hint.tr || option == "aiPreferred"
                          ? controller.languageDropDown.length
                          : controller.currencyDropDown.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        return new Wrap(children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              InkWell(
                                onTap: () {

                                  Get.back();
                                  if (option == lang_hint.tr) {
                                    selectedOpt = "preferredLanguage";
                                    selectedPos = index;
                                    controller.checkInternet(updateLangCurrency, false);
                                  } else if (option == "aiPreferred") {
                                    selectedOpt = "AIPreferredLanguage";
                                    selectedPos = index;
                                    controller.checkInternet(updateLangCurrency, false);
                                  } else {
                                    selectedOpt = "preferredCurrency";
                                    selectedPos = index;
                                    controller.currencyController.text =
                                    controller.currencyDropDown[selectedPos];
                                    controller.checkInternet(updateLangCurrency, false);
                                  }
                                  debugPrint("updateLangCurrency: ${selectedOpt}");
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 15.0,
                                              bottom: 15.0,
                                              right: 24.0,
                                              left: 24.0),
                                          child: option == lang_hint.tr || (option == "aiPreferred")
                                              ? Text(
                                              controller.languageDropDown[index],
                                              style: TextStyle(
                                                color:
                                                AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontWeight: FontWeight.w500,
                                                fontSize: AppDimen.text_size_18,
                                              ))
                                              : Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: CustomPaint(
                                              size: Size(60, 30),
                                              painter: CurrencyListPainter(
                                                  controller.currencyDropDown[
                                                  index]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    checkVerified(option, index)
                                        ? SvgPicture.asset(
                                      updatedVerified,
                                      width: 23.0,
                                      height: 23.0,
                                      colorFilter: ColorFilter.mode(
                                          AppColors.ICON_COLOUR,
                                          BlendMode.srcIn),
                                    )
                                        : const SizedBox.shrink(),
                                    checkVerified(option, index)
                                        ? const SizedBox(width: 24)
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
                                child: new Divider(
                                  color: AppColors.DIVIDER_COLOR,
                                ),
                              ),
                            ],
                          )
                        ]);
                      },
                    ),
                  ),
                );
              }
          )
      );
    }
  }

  updateLangCurrency() {
    debugPrint("updateLangCurrency: ${selectedOpt}");
    if (selectedOpt.compareTo("preferredLanguage") == 0) {
      controller
          .updateProfileInfo(selectedOpt, controller.languageCode[selectedPos])
          .then((value) {
        if (value == "timeout") {
          App().toast.show(
            context: context,
            message: session_timeout_err.tr,
          );
          controller.setLogout(context);
        } else if (value == "offline") {
          controller.netOffSnackbar(updateLangCurrency, false);
        } else {
          controller.languageController.text =
          controller.languageDropDown[selectedPos];
          globals.preferredLanguage.value =
          controller.languageCode[selectedPos];

          print("arabic:::${ globals.preferredLanguage.value}");
          globals.isRtlLang =
              intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);

          controller.languageDropDown.removeAt(selectedPos);
          controller.languageCode.removeAt(selectedPos);
          controller.languageDropDown
              .insert(0, controller.languageController.text);
          controller.languageCode.insert(0, globals.preferredLanguage.value);
          App().appPreference.preferredLanguage = globals.preferredLanguage.value;
          App().changeLanguage();
          globals.preferredLanguage.refresh();
          globals.baseController.change(
              rxVariable: globals.rxLoadingController, value: 1);
        }
      });
    } else if (selectedOpt.compareTo("AIPreferredLanguage") == 0) {
      controller
          .updateProfileInfo(selectedOpt, controller.languageCode[selectedPos])
          .then((value) {
            if (value == "timeout") {
              App().toast.show(
              context: context,
               message: session_timeout_err.tr,);
             controller.setLogout(context);
            } else if (value == "offline") {
              controller.netOffSnackbar(updateLangCurrency, false);
            } else {
              controller.preferredController.text = controller.languageDropDown[selectedPos];
              globals.aiPreferredLanguage = controller.languageCode[selectedPos];

              controller.languageDropDown.removeAt(selectedPos);
              controller.preferredLanguageCode.removeAt(selectedPos);
              controller.languageDropDown
                  .insert(0, controller.preferredController.text);
              controller.preferredLanguageCode.insert(0, globals.aiPreferredLanguage);
          }
      });
    } else {

      Map<String,dynamic> walletoption = globals.driverWalletOptionController.value;
      if(!(walletoption["driverWalletOption"] == "1" && walletoption["walletFlow"] == "allPaymentMethods")){

      }
 debugPrint("currencychangewalletoption: ${walletoption} --- ${ controller.getRate(controller.currencyDropDown[selectedPos].split("-")[1].trim(), walletoption["walletBalance"])}");
      debugPrint("currencychange: ${controller.currencyDropDown[selectedPos].split("-")[1].trim()} --- ${globals.preferredCurrency}");
      controller
          .updateProfileInfo(selectedOpt,
              controller.currencyDropDown[selectedPos].split("-")[1].trim())
          .then((value) {
        if (value == "timeout") {
          App().toast.show(
                context: context,
                message: session_timeout_err.tr,
              );
          controller.setLogout(context);
        } else if (value == "offline") {
          controller.netOffSnackbar(updateLangCurrency, false);
        } else {
          controller.getDriverWalletBalance();
        }
      });
    }
  }

  getLangController() {
    return controller.setLanguage();
  }

  getPreferredController() {
    if (controller.preferredController.text.toString().isNotEmpty) {
      return controller.preferredController;
    } else if (controller.preferredController == null ||
        controller.preferredController.text == null ||
        controller.preferredController.text.toString().isEmpty) {
      if (controller.preferredController == null)
        controller.preferredController = TextEditingController();

      return controller.setPreferredLanguage();
    }
  }


  bool checkVerified(String option, int index) {
    if (option == lang_hint.tr) {
      int index1 = controller.languageCode
          .indexWhere((element) => element == globals.preferredLanguage.value);
      return index1 == index;
    } else if (option == "aiPreferred") {
      int index1 = controller.preferredLanguageCode
          .indexWhere((element) => element == globals.aiPreferredLanguage);
      return index1 == index;
    } else {
      int index1 = controller.currencyDropDown.indexWhere((element) {
        return (element ==
            globals.currencySymbol + " - " + globals.preferredCurrency);
      });

      return index1 == index;
    }
  }
}

class CurrencyListPainter extends CustomPainter {
  final String textValue;

  CurrencyListPainter(this.textValue);

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: textValue.split("-")[1].trim(),
      style: TextStyle(
          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
          fontWeight: FontWeight.w500,
          fontSize: AppDimen.text_size_18,
          fontFamily: AppFont.font),
    );
    final TextPainter textPainter = TextPainter()
      ..textDirection = TextDirection.ltr
      ..text = textSpan
      ..layout();

    final textSpan2 = TextSpan(
      text: " (${textValue.split("-")[0].trim()})",
      style: TextStyle(
          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
          fontWeight: FontWeight.w500,
          fontSize: AppDimen.text_size_18,
          fontFamily: 'Roboto'),
    );
    final TextPainter textPainter2 = TextPainter()
      ..textDirection = TextDirection.ltr
      ..text = textSpan2
      ..layout();

    textPainter.paint(
        canvas,
        Offset(
            globals.isRtlLang
                ? -(textPainter.width + textPainter2.width) + 60
                : 5,
            0));
    textPainter2.paint(
        canvas,
        Offset(
            globals.isRtlLang
                ? -(textPainter2.width) + 60
                : textPainter.width + 5,
            3));
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}