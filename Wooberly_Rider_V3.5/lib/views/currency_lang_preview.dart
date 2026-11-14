import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/controllers/edit_account_controller.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/lang_select.dart';
import 'package:app_name/widgets/audio_chat/ai_lang_selection_widget.dart';
import 'package:app_name/widgets/tooltip_info_widget.dart';

import '../app/model_theme.dart';
import '../controllers/base_controller.dart';
import '../resources/values/app_images.dart';
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
  EditAccountController editAccountController = Get.find();
  String selectedOpt = "";
  int selectedPos = 0;
  @override
  void initState() {
    debugPrint("globals.mobileLanguages: ${globals.mobileLanguages}");
    editAccountController.currencyDropDown.clear();
    if (globals.preferredCurrency.isNotEmpty) {
      editAccountController.currencyController.text =
          globals.currencySymbol + " - " + globals.preferredCurrency;
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      Future.wait([
      editAccountController.checkInternet(editAccountController.getCurrencyList, false),
        if(globals.isVoiceTranslatorEnable)
      editAccountController.checkInternet( globals.baseController.getAILanguageList, false),
        if(globals.isVoiceTranslatorEnable)
      editAccountController.checkInternet( globals.baseController.getUserAILanguage, false),

      ]);
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
          debugPrint("titlecurr: ${'currency_languages'.tr}");
          return PrimaryScaffold(
            appBarTitle: 'currency_languages'.tr,
            onChanged: (map) {

            },
            body: Container(
              height: MediaQuery.of(context).size.height,
              margin: const EdgeInsetsDirectional.only(top: 30.0, end: 25, start: 25.0),
              child: Column(
                children: <Widget>[
                  _currencyBox(),
                  const SizedBox(height: 30.0),
                  _languageBox(title: 'label_app_text_lang'.tr,tooltipContent: 'label_tooltip_app_text_lang'.tr),
                  const SizedBox(height: 30.0),
                  if(globals.isVoiceTranslatorEnable)
                  AILangSelectionWidget(title: 'label_user_preferred_lang'.tr,tooltipcontent: 'label_tooltip_user_preferred_lang'.tr,isShowIcon: false),
                ],
              ),
            ));
      }
    );
  }

  Widget _currencyBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
            'preferred_'.trParams({'field2':
           'currency_hint'.tr.toLowerCase()}),
            style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontWeight: FontWeight.w600,
              fontSize: AppDimen.text_size_16,
            )),
        SizedBox(
          height: 15.0,
        ),
        InkWell(
          onTap: () {
            Get.closeCurrentSnackbar();
            if (editAccountController.currencyDropDown.isNotEmpty)
              _settingModalBottomSheet(
                  context,
                  'currency_hint'.tr,
                  MediaQuery.of(context).size.height * 0.65);
          },
          child: Container(
            padding: const EdgeInsetsDirectional.only(
                start: 20, end: 20, top: 13, bottom: 13),
            color: AppColors.PRIMARY_LIGHT_COLOR,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: globals.isRTLLang
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: editAccountController.currencyController.text
                                    .toString()
                                    .split("-")[1]
                                    .trim(),
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_18,
                                    fontFamily: AppFont.font)),
                            TextSpan(
                                text:
                                    " (${editAccountController.currencyController.text.toString().split("-")[0].trim()})",
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_18,
                                    fontFamily: "Roboto"))
                          ]),
                        ),
                      )),
                  flex: 95,
                ),
                SvgPicture.asset(
                  primaryDownArrow,
                  width: 7.0,
                  height: 8.0,
                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _languageBox({required String title, required String tooltipContent}) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
      Consumer<ModelTheme>(
      builder: (context, ModelTheme themeNotifier, child) {
        return TooltipInfoWidget(title: title,
            tooltipcontent: tooltipContent,
        );
      }),
          const SizedBox(height: 15.0),
          InkWell(
            onTap: () {
              Get.closeCurrentSnackbar();
              _settingModalBottomSheet(
                  context,
                  'lang_hint'.tr,
                  MediaQuery.of(context).size.height * 0.45);
            },
            child: Container(
              color: AppColors.PRIMARY_LIGHT_COLOR,
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
                            color: AppColors.PLACEHOLDER_TEXT_COLOR,
                            fontWeight: FontWeight.w300,
                            fontSize: AppDimen.text_size_18,
                          ),
                          hoverColor: AppColors.BLACK_TEXT_COLOR),
                      controller: getLangController(),
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
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
                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _settingModalBottomSheet(mcontext, String option, double value) {
    if(option == 'lang_hint'.tr) {
      Get.to(LangSelect(isFrom: 'lang_preview',), transition: Transition.downToUp);
    } else {
      App().showBottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return Container(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              height: value,
              padding: const EdgeInsetsDirectional.only(top: 10.0),
              child: ListView.builder(
                itemCount: option == 'lang_hint'.tr
                    ? editAccountController.languageDropDown.length
                    : editAccountController.currencyDropDown.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return Container(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      child: new Wrap(children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                if (option == 'lang_hint'.tr) {
                                  selectedOpt = "preferredLanguage";
                                  selectedPos = index;
                                  editAccountController.checkInternet(updateLangCurrency, false);
                                } else {
                                  selectedOpt = "preferredCurrency";
                                  selectedPos = index;
                                  editAccountController.currencyController.text = editAccountController.currencyDropDown[selectedPos];
                                  editAccountController.checkInternet(updateLangCurrency, false);
                                }
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          alignment: AlignmentDirectional.centerStart,
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional.symmetric(
                vertical: 15.0,
                horizontal: 24.0,
              ),
                                            child: option ==
                                                'lang_hint'.tr
                                                ? Text(
                                                editAccountController
                                                    .languageDropDown[index],
                                                style: TextStyle(
                                                  color:
                                                  AppColors.BLACK_TEXT_COLOR,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: AppDimen.text_size_18,
                                                ))
                                                : Align(
                                              alignment: AlignmentDirectional
                                                  .centerStart,
                                              child: CustomPaint(
                                                size: Size(60, 30),
                                                painter: CurrencyListPainter(
                                                    editAccountController.currencyDropDown[
                                                    index]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // globals.downloadedLanguages.contains(editAccountController.languageCode[index]) ? Icon(Icons.abc) : const SizedBox.shrink()
                                      ],
                                    ),
                                  ),
                                  checkVerified(option, index)
                                      ? SvgPicture.asset(
                                    updatedVerified,
                                    width: 23.0,
                                    height: 23.0,
                                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  )
                                      : const SizedBox.shrink(),
                                  checkVerified(option, index)
                                      ? SizedBox(width: 24)
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
                      ]));
                },
              ),
            );
          }
        ));
    }
  }

  updateLangCurrency() {
    if (selectedOpt.compareTo("preferredLanguage") == 0) {
      editAccountController.updateProfileInfo(selectedOpt, editAccountController.languageCode[selectedPos]).then((value) {
        if (value == "timeout") {
         editAccountController.toast.show(
                context: context,
                message: 'session_timeout_err'.tr,
              );
         editAccountController.setLogout();
        }
        else if (value == "offline") {
          editAccountController.netOffSnackbar( updateLangCurrency, false);
        }
        else if (value.isNotEmpty){
         editAccountController.showInSnackBar( value);
        }
        else {
          String selectedLangCode = editAccountController.languageCode[selectedPos];
          globals.preferredLanguage = selectedLangCode;
          globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
          int targetIndex = editAccountController.languageCode.indexOf(selectedLangCode);
          if (targetIndex != -1) {
            String targetLang = editAccountController.languageDropDown[targetIndex];
            editAccountController.languageController.text = targetLang;
            editAccountController.languageDropDown.removeAt(targetIndex);
            editAccountController.languageCode.removeAt(targetIndex);
            editAccountController.languageDropDown.insert(0, targetLang);
            editAccountController.languageCode.insert(0, selectedLangCode);
          }
          editAccountController.preferences.preferredLaunguage= globals.preferredLanguage;
          App().translations.readJson(language: globals.preferredLanguage, isUpdate: false,isOnlyDownload: false);
          globals.setButtonIdle();
        }
      });
    } else {
      editAccountController
          .updateProfileInfo(selectedOpt,
              editAccountController.currencyDropDown[selectedPos].split("-")[1].trim())
          .then((value) {
        if (value == "timeout") {
         editAccountController.toast.show(
                context: context,
                message: 'session_timeout_err'.tr,
              );
         editAccountController.setLogout();
        } else if (value == "offline") {
          editAccountController.netOffSnackbar( updateLangCurrency, false);
        }else if (value.isNotEmpty){
         editAccountController.showInSnackBar( value);
        }  else {
          Get.back();
          Get.forceAppUpdate();
        }
      });
    }
  }

  getLangController() {
    if (editAccountController.languageController.text.toString().isNotEmpty) {
      return editAccountController.languageController;
    } else if (editAccountController.languageController == null ||
        editAccountController.languageController.text == null ||
        editAccountController.languageController.text.toString().isEmpty) {
      if (editAccountController.languageController == null)
        editAccountController.languageController = TextEditingController();

      return editAccountController.setLanguage();
    }
  }

  bool checkVerified(String option, int index) {
    if (option == 'lang_hint'.tr) {
      int index1 = editAccountController.languageCode
          .indexWhere((element) => element == globals.preferredLanguage);

      return index1 == index;
    } else {
      int index1 = editAccountController.currencyDropDown.indexWhere((element) {
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
          color: AppColors.BLACK_TEXT_COLOR,
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
          color: AppColors.BLACK_TEXT_COLOR,
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
            globals.isRTLLang
                ? -(textPainter.width + textPainter2.width) + 60
                : 5,
            0));
    textPainter2.paint(
        canvas,
        Offset(
            globals.isRTLLang
                ? -(textPainter2.width) + 60
                : textPainter.width + 5,
            3));
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}