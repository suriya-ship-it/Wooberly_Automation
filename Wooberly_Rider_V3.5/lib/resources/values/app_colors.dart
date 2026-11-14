import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';


class AppColors {
  BaseController controller =Get.find();
	 static const Color lightPrimaryColor = Color(0xFF131314);
	 static const Color lightsecondaryColor = Color(0xFF1654E4);
	 static const Color staticBlack = Color(0x00000000);
  static Color PRIMARY_DARK_COLOR = globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color CIRCULAR_PROGRESS_BAR_LOADING_COLOR = globals.isDarkTheme ? Color(0xFF131314) : Color(0xFFFFFFFF);
  static Color DIVIDER_COLOR =
  globals.isDarkTheme ? Color(0xFF383B4B) : Color(0xFFEAEAEA);
  static Color COMMON_BG_COLOR =
  globals.isDarkTheme ? Color(0xFF0E142F) : Color(0xFFF6F6F6);
  static Color DISABLE_COLOR =
  globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFEFEFEF);
  static Color BORDERCOLOR =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : Color(0xFFED2D2D2);
  static Color PRIMARY_LIGHT_COLOR =
  globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFFFFFFF);
  static Color PRIMARY_ICON_COLOR =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color LOCATION_ARRIVED_COLOR = globals.isDarkTheme ? Color(0xFF6D849F) : Color(0xFFAAAAAA);
  static Color PLACEHOLDER_TEXT_COLOR = Color(0xFF848484);
  static Color CHECK_BOX = Color(0XFFA8A8A8);
  static const Color SEARCH_TEXT_COLOR = Color(0xFFA5A5A5);
  static const Color VOICE_WAVEFORM_COLOR1 = Color(0xFFFF0000);
  static const Color VOICE_WAVEFORM_COLOR2 = Color(0xFF2600FF);

  static Color INDICATOR_COLOR =
      globals.isDarkTheme ? lightPrimaryColor : Color(0xFFFFFFFF);
  static Color PrecautionInstructionCancel =
      globals.isDarkTheme ? Color(0XFF0E142F) : Color(0XFFE0E0E0);

  static Color PROMOCODE_LINK_COLOR = globals.isDarkTheme ? Color(0XFF749EFF) : lightsecondaryColor;

  //Border color
  static Color PRIMARY_BORDER_COLOR =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color WHITE = globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFFFFFFF);
  static Color BLACK = globals.isDarkTheme ? Color(0xFFFFFFFF) : Color(0xFF171D37);



  // Text colour
  static Color WHITE_TEXT_COLOR = Color(0xFFFFFFFF);
  static Color BLACK_TEXT_COLOR = Color(0xFF151515);

  //Time Line and Divider color
  static const Color LOCATION_LINE_COLOR = Color(0xFFB4B4B4);
  static const Color HOME_WHERE_TO_BORDER_COLOR = Color(0xFFE8E5E0);

  // SVG colour
  static Color WHITE_SVG_COLOR =
      globals.isDarkTheme ? lightPrimaryColor : Color(0xFFFFFFFF);

//StatusColors
  static const Color VERIFY_COLOR = Color(0xFF43A047);
  static const Color EXCEPTION_COLOR = Color(0xFFE14C38);
  static const Color TRIP_CREATED = Color(0xFF3676D1);
  static const Color TRIP_DETAIL_BG_COLOR = Color(0xFFF2F7FF);
  static const Color TRIP_STARTED = Color(0XFFFF8439);
  static const Color TRIP_REACHED = Color(0XFFE0A90F);
  static const Color RATING_COLOR = Color(0xFFFF9031);
  static const Color COMPLETE_COLOR = Color(0xFF03C03C);
  static const Color RADIO_BUTTON_COLOR = Color(0XFFA8A8A8);
  static const Color GRID_COLOR = Color(0xFFDED7D6);
  static const Color APP_CHAT_COLOR = Color(0xFFDFF1FF);
  static const Color B3_BLACK_COLOR = Color(0xB3000000);

  //Light Theme
  changeToLight() {
    if(Platform.isIOS)
    controller.changeMode();
    PRIMARY_DARK_COLOR = lightPrimaryColor;
    CIRCULAR_PROGRESS_BAR_LOADING_COLOR = Color(0xFFFFFFFF);
    PRIMARY_ICON_COLOR = lightPrimaryColor;
    PRIMARY_LIGHT_COLOR = Color(0xFFFFFFFF);
    INDICATOR_COLOR = Color(0xFFFFFFFF);
    COMMON_BG_COLOR = Color(0xFFF6F6F6);
    BLACK_TEXT_COLOR = Color(0xFF151515);
    WHITE_TEXT_COLOR = Color(0xFFFFFFFF);
    WHITE = Color(0xFFFFFFFF);
    BLACK = Color(0xFF171D37);
    WHITE_SVG_COLOR = Color(0xFFFFFFFF);
    DISABLE_COLOR = Color(0XFFEFEFEF);
    PrecautionInstructionCancel = Color(0XFFE0E0E0);
    DIVIDER_COLOR = Color(0xFFEAEAEA);
    PROMOCODE_LINK_COLOR = lightsecondaryColor;
    PRIMARY_BORDER_COLOR = lightPrimaryColor;
    PLACEHOLDER_TEXT_COLOR = Color(0xFF848484);
    LOCATION_ARRIVED_COLOR = Color(0xFFAAAAAA);

    if (Platform.isAndroid)
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: PRIMARY_LIGHT_COLOR,
      ));
  }

  //Dark Theme
  changeToDark() {
    if(Platform.isIOS)
    controller.changeMode();
    PRIMARY_DARK_COLOR = Color(0xFFFFFFFF);
    CIRCULAR_PROGRESS_BAR_LOADING_COLOR = Color(0xFF131314);
    WHITE_TEXT_COLOR = Color(0xFF151515);
    PRIMARY_LIGHT_COLOR = Color(0xFF171D37);
    INDICATOR_COLOR = lightPrimaryColor;
    COMMON_BG_COLOR = Color(0xFF0E142F);
    BLACK_TEXT_COLOR = Color(0xFFC7D8EB);
    WHITE_TEXT_COLOR = Color(0xFF151515);
    WHITE = Color(0xFF171D37);
    BLACK =  Color(0xFFFFFFFF);
    PRIMARY_ICON_COLOR = Color(0xFFFFFFFF);
    WHITE_SVG_COLOR = lightPrimaryColor;
    DISABLE_COLOR = Color(0xFF171D37);
    PrecautionInstructionCancel = Color(0XFF0E142F);
    DIVIDER_COLOR = Color(0xFF383B4B);
    PROMOCODE_LINK_COLOR = Color(0XFF749EFF);
    PRIMARY_BORDER_COLOR= Color(0xFFFFFFFF);
    PLACEHOLDER_TEXT_COLOR = Color(0xFFA1BBD7);
    LOCATION_ARRIVED_COLOR = Color(0xFF6D849F);

    if (Platform.isAndroid)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            statusBarColor: PRIMARY_LIGHT_COLOR,
          ),
        );
      });
  }
}