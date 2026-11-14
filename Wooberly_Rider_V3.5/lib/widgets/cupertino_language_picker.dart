import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:intl/intl.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/views/lang_select.dart';

import '../resources/values/app_images.dart';

class CupertinoLanguagePicker {
  CupertinoLanguagePicker({
    this.pickerContext,
    this.pickerList,
    this.pickerType,
  });
  final BuildContext? pickerContext;
  final List<Map<String, dynamic>>? pickerList;
  final String? pickerType;
  BaseController baseController = Get.find();

  Map<String, dynamic>? _pickerItem;
  int _selectedItem = 0;

  show() {
    if (globals.preferredLanguage != null) {
      for (var i = 0; i < pickerList!.length; i++) {
        if (pickerList![i]["id"].contains(globals.preferredLanguage)) {
          _selectedItem = i;
          _pickerItem = pickerList![i];
          break;
        }
      }
    }
    App().showBottomSheet(
        SafeArea(
          child: Container(
                color: AppColors.PRIMARY_LIGHT_COLOR,
                height: 180,
                child: Column(
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Text(
                        'cancel_label'.tr,
                        style: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
                      )),
                  InkWell(
                      onTap: () {
                        if (_pickerItem != null) {
                          globals.preferredLanguage = _pickerItem?["id"];
                          globals.isRTLLang = Bidi.isRtlLanguage(globals.preferredLanguage);
                          baseController.preferences.preferredLaunguage = globals.preferredLanguage;
                          App().translations.readJson(language: globals.preferredLanguage, isUpdate: false,isOnlyDownload: false);
                        }
                          Get.back();
          
                      },
                      child: Text(
                        toBeginningOfSentenceCase('done'.tr.toLowerCase())!,
                        style: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
                      )),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              height: 100,
              child: CupertinoPicker(
                backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                scrollController:
                    FixedExtentScrollController(initialItem: _selectedItem),
                onSelectedItemChanged: (value) {
                  _pickerItem = pickerList![value];
                },
                itemExtent: 32.0,
                children: [
                  for (var i in pickerList!)
                    Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5.0),
                        child: Text(
                          i["value"].toString(),
                          style: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
                        ))
                ],
              ),
            ),
          ],
                ),
              ),
        ));
  }

  Widget getWidget() {
    String displayCode = "";
    if (globals.preferredLanguage != null) {
      for (var i = 0; i < pickerList!.length; i++) {
        if (pickerList![i]["id"].contains(globals.preferredLanguage)) {
          displayCode = pickerList![i]["discode"];
          break;
        }
      }
      if (displayCode.isEmpty) {
        displayCode = globals.defaultLanguageDisplayCode;
      }
    } else {
      displayCode = globals.defaultLanguageDisplayCode;
      globals.preferredLanguage = globals.defaultLanguageCode;
    }
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () {
            Get.to(() => LangSelect(isFrom: "phone_no"), transition: Transition.downToUp);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
            ),
            height: 50,
            width: 90,
            padding: const EdgeInsetsDirectional.only(
                start: 10, end: 5),
            margin: const EdgeInsetsDirectional.only(bottom: 5.0),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  languageIconSvg,
                  height: 18.0,
                  width: 18.0,
                  colorFilter: ColorFilter.mode(
                      AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                ),
                SizedBox(
                  width: 8,
                ),
                Builder(
                  builder: (context) {
                    for (var i = 0; i < pickerList!.length; i++) {
                      if (pickerList![i]["id"]
                          .contains(globals.preferredLanguage)) {
                        displayCode = pickerList![i]["discode"];
                        break;
                      }
                    }
                    return Container(
                      child: Text(
                        displayCode.toUpperCase(),
                        style: TextStyle(
                            fontSize: AppDimen.text_size_16,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            color: AppColors.BLACK_TEXT_COLOR),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                  child: SvgPicture.asset(
                    primaryDownArrow,
                    height: 5,
                    width: 5,
                    colorFilter: ColorFilter.mode(
                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}