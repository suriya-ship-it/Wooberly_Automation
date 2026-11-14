import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/lang_select.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';

class CupertinoLanguagePicker {
  CupertinoLanguagePicker({
    this.pickerContext,
    this.pickerlist,
    this.pickerType,
    this.focusNode
  });

  final BuildContext? pickerContext;
  final List<Map<String, dynamic>>? pickerlist;
  final String? pickerType;
  final FocusNode? focusNode;


  Widget getWidget() {
    String displayCode = "";
    if (globals.preferredLanguage.value != null &&
        globals.preferredLanguage.value.isNotEmpty) {
      for (var i = 0; i < pickerlist!.length; i++) {
        if (pickerlist?[i]["id"].contains(globals.preferredLanguage.value)) {
          displayCode = pickerlist?[i]["discode"];
          break;
        }
      }
      if (displayCode.isEmpty) {
        displayCode = globals.defaultLanguageDisplayCode;
      }
    } else {
      displayCode = globals.defaultLanguageDisplayCode;
      globals.preferredLanguage.value = globals.defaultLanguageCode;
    }
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () {
            Get.to(LangSelect(isFrom: "phone_no"), transition: Transition.downToUp);
          },
          child: Container(
            height: 50,
            width: 90,
            padding: const EdgeInsetsDirectional.only(
                start: 10, end: 5,top: 5),
            margin: const EdgeInsets.only(bottom: 5.0),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  languageIconSvg,
                  height: 18.0,
                  width: 18.0,
                  colorFilter:
                      ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                ),
                const SizedBox(
                  width: 8,
                ),
                Builder(
                  builder: (context) {
                    for (var i = 0; i < pickerlist!.length; i++) {
                      if (pickerlist?[i]["id"].contains(globals.preferredLanguage.value)) {
                        displayCode = pickerlist?[i]["discode"];
                        break;
                      }
                    }
                    return Text(
                      displayCode.toUpperCase(),
                      style: TextStyle(
                          fontSize: AppDimen.text_size_16,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w500,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                  child: SvgPicture.asset(
                    primaryDownArrow,
                    width: 5,
                    height: 5,
                    colorFilter: ColorFilter.mode(
                        AppColors.ICON_COLOUR, BlendMode.srcIn),
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