import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../app/app.dart';

class AppColors {
	 static const Color lightPrimaryColor = Color(0xFF3bcca5);
	 static const Color lightsecondaryColor = Color(0xFFc630d1);
   static Color PRIMARY_COLOR = Color(0xFF171D37);
  static Color PRIMARY_COLOR_DARK =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color DISABLE_COLOR =
  globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFEFEFEF);
  static Color PRIMARY_COLOR_DARK_TEXT_COLOR =
  globals.isDarkTheme ? Color(0xFFC7D8EB) : Color(0xFF151515);
  static Color PRIMARY_LIGHT_COLOR =
  globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFFFFFFF);

   static Color BLACK =
   globals.isDarkTheme ? Color(0xFFFFFFFF) : Color(0xFF171D37);
  static Color PRIMARY_DARK_COLOR =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color BORDERCOLOR =
  globals.isDarkTheme ? Color(0xFFFFFFFF) : Color(0xFFED2D2D2);
  static Color PRIMARY_COLOR_WHITE =
  globals.isDarkTheme ? Color(0xFF171D37) : Color(0xFFFFFFFF);
  static Color COMPLETE_TEXT_COLOR =
  globals.isDarkTheme ? Color(0xFF6D849F) : Color(0xFFAAAAAA);
  static Color HIND_TEXT_COLOR =
  globals.isDarkTheme ? Color(0xFFA1BBD7) : Color(0xFF848484);
  static Color CHECK_BOX = Color(0XFFA8A8A8);
  static Color SVGCHANGECOLOR = Color(0xFF131314);

  static const Color ONLINE_STATUS = Color(0xFFFF0000);
  static const Color TRIP_DETAIL_BG_COLOR = Color(0xFFF2F7FF);
  static const Color VERIFY_COLOR = Color(0xFF43A047);
  static const Color RIDE_ELIGIBLE_COLOR = Color(0xFF00A53C);
  static const Color RIDE_NOT_ELIGIBLE_COLOR = Color(0xFFDC112D);
  static const Color SEARCH_TEXT_COLOR = Color(0xFFA5A5A5);
  static const Color DECLINED_COLOR = Color(0xFFE14C38);

  static const Color BUTTON_SLIDER_COLOR = Color(0xFF7A7A7A);
  static const Color BUTTON_SLIDER_INNER_COLOR = Color(0xFF4BE06B);
  static const Color TRIP_STARTED = Color(0XFFFF8439);
  static const Color STRIPE_PAINTER_COLOR = Color(0xFF121212);
  static const Color TRIP_CREATED = Color(0xFF3676D1);
  static const Color TRIP_REACHED = Color(0XFFE0A90F);
  static const Color TRIP_GREEN = Color(0xFF03C03C);
  static const Color GRAY = Color(0xFFa5abb5);
  static const Color GRID_COLOR = Color(0xFFDED7D6);
  static const Color APP_CHAT_COLOR = Color(0xFFDFF1FF);
  static const Color READING_COLOR = Color(0xFFFFA726);
  static const Color WARNING_COLOR = Color(0xFFDC112D);
  static const Color TripTRequest_TimerLoadColor = Color(0XFFea4239);

  static const Color BLUE_GRADIENT_COLOR = Color(0xFF2600FF);

  static Color CIRCULAR_PROGRESS_BAR_LOADING_COLOR =
      globals.isDarkTheme ? Color(0xFF131314) : Color(0xFFFFFFFF);
  static Color TRIPS_BG_Color =
      globals.isDarkTheme ? Color(0xFF0E142F) : Color(0xFFF7F7F7);

  // Background BG
  static Color COMMON_BG_COLOR =
      globals.isDarkTheme ? Color(0xFF0E142F) : Color(0xFFF6F6F6);
  static Color DIVIDER_COLOR =
      globals.isDarkTheme ? Color(0xFF383B4B) : Color(0xFFEFEFEF);

  static Color WHITE_TEXT_COLOR =
      globals.isDarkTheme ? Color(0xFF151515) : Color(0xFFFFFFFF);
  static Color PrecautionInstructionCancel =
      globals.isDarkTheme ? Color(0XFF0E142F) : Color(0XFFE0E0E0);

  // SVG colour
  static Color ICON_COLOUR =
      globals.isDarkTheme ? Color(0xFFFFFFFF) : lightPrimaryColor;
  static Color WHITE_ICON_COLOR =
      globals.isDarkTheme ? Color(0xFF131314) : Color(0xFFFFFFFF);
  static const Color PRIMARY_COLOR_DARK_TRAN = Color(0xB3000000);
  static const Color SHADOW_COLOR = Color(0XFF00000029);
  static Color TEXT_LINK_COLOR =
      globals.isDarkTheme ? Color(0XFF749EFF) : lightsecondaryColor;
  static Color OFFLINE_COLOR =
      globals.isDarkTheme ? Color(0XFF171D37) : Color(0XFFF3F3F3);
  static const Color LOCATION_LINE_COLOR = Color(0xFFB4B4B4);

  static Color WAVE_COLOR = Color(0xFF151515);

  static Color OUTLINE_COLOR = Color(0xFFF1F1F1);

  static const Color VOICE_WAVEFORM_COLOR1 = Color(0xFFFF0000);
  static const Color VOICE_WAVEFORM_COLOR2 = Color(0xFF2600FF);


  changeToLight() {
    if(Platform.isIOS)
    App().changeMode();
    BLACK = Color(0xFF171D37);
    OUTLINE_COLOR = Color(0xFFF1F1F1);
    PRIMARY_COLOR_DARK = lightPrimaryColor;
    ICON_COLOUR = lightPrimaryColor;
    PRIMARY_DARK_COLOR = lightPrimaryColor;
    PRIMARY_COLOR_WHITE = Color(0xFFFFFFFF);
    CIRCULAR_PROGRESS_BAR_LOADING_COLOR = Color(0xFFFFFFFF);
    COMMON_BG_COLOR = Color(0xFFF6F6F6);
    PRIMARY_LIGHT_COLOR = Color(0xFFFFFFFF);
    PRIMARY_COLOR_DARK_TEXT_COLOR = Color(0xFF151515);
    WHITE_TEXT_COLOR = Color(0xFFFFFFFF);
    WHITE_ICON_COLOR = Color(0xFFFFFFFF);
    DIVIDER_COLOR = Color(0xFFEFEFEF);
    DISABLE_COLOR = Color(0XFFECECEC);
    TRIPS_BG_Color = Color(0xFFF7F7F7);
    OFFLINE_COLOR = Color(0XFFF3F3F3);
    TEXT_LINK_COLOR = lightsecondaryColor;
    PrecautionInstructionCancel = Color(0XFFE0E0E0);
    BORDERCOLOR = Color(0xFFED2D2D2);
    COMPLETE_TEXT_COLOR = Color(0xFFAAAAAA);
    HIND_TEXT_COLOR = Color(0xFF848484);
    WAVE_COLOR = Color(0xFF151515);

    if (Platform.isAndroid)
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        statusBarColor: PRIMARY_COLOR_WHITE,
      ));
  }

  changeToDark() {
    if(Platform.isIOS)
    App().changeMode();
    BLACK = Color(0xFFFFFFFF);
    OUTLINE_COLOR = Color(0xFF252C4C);
    PRIMARY_COLOR_DARK = Color(0xFFFFFFFF);
    ICON_COLOUR = Color(0xFFFFFFFF);
    PRIMARY_COLOR_WHITE = Color(0xFF171D37);
    CIRCULAR_PROGRESS_BAR_LOADING_COLOR = Color(0xFF131314);
    COMMON_BG_COLOR = Color(0xFF0E142F);
    PRIMARY_LIGHT_COLOR = Color(0xFF171D37);
    PRIMARY_DARK_COLOR = Color(0xFFFFFFFF);
    PRIMARY_COLOR_DARK_TEXT_COLOR = Color(0xFFC7D8EB);
    WHITE_TEXT_COLOR = Color(0xFF151515);
    WHITE_ICON_COLOR = Color(0xFF131314);
    DIVIDER_COLOR = Color(0xFF383B4B);
    DISABLE_COLOR = Color(0xFF171D37);
    PrecautionInstructionCancel = Color(0XFF0E142F);
    TRIPS_BG_Color = Color(0xFF0E142F);
    OFFLINE_COLOR = Color(0XFF171D37);
    TEXT_LINK_COLOR = Color(0XFF749EFF);
    BORDERCOLOR = Color(0xFFFFFFFF);
    COMPLETE_TEXT_COLOR = Color(0xFF6D849F);
    HIND_TEXT_COLOR = Color(0xFFA1BBD7);
    WAVE_COLOR = Color(0xFFC7D8EB);

    if (Platform.isAndroid)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
            statusBarColor: PRIMARY_COLOR_WHITE, // status bar color
          ),
        );
      });
  }
}