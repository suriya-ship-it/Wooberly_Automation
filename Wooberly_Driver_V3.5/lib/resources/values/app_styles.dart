import 'package:flutter/material.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';

class AppStyles {
  static ThemeData lightTheme() {
    final ThemeData base = ThemeData.light(
      useMaterial3: false,
    );
    return base.copyWith(
      primaryColor: AppColors.PRIMARY_COLOR_DARK,
      primaryColorLight: AppColors.PRIMARY_COLOR_DARK,
      primaryColorDark: AppColors.PRIMARY_COLOR_DARK,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: AppColors.PRIMARY_COLOR_DARK,
      ),
      splashColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
        selectionHandleColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
        fontFamily: AppFont.font,
      ),
      appBarTheme: AppBarTheme(
        color: AppColors.PRIMARY_COLOR_DARK,
        iconTheme: IconThemeData(color: AppColors.WHITE_ICON_COLOR),
        toolbarTextStyle: base.textTheme
            .copyWith(
              titleLarge: TextStyle(
                  fontSize: AppDimen.text_size_20,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w500,
                  color: AppColors.PRIMARY_COLOR_WHITE),
            )
            .bodyMedium,
        titleTextStyle: base.textTheme
            .copyWith(
              titleLarge: TextStyle(
                  fontSize: AppDimen.text_size_20,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w500,
                  color: AppColors.PRIMARY_COLOR_WHITE),
            )
            .titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(
        color: AppColors.PRIMARY_COLOR_WHITE,
        fontWeight: FontWeight.w300,
        fontSize: AppDimen.text_size_14,
        fontFamily: AppFont.font,
      )),
      dialogTheme: DialogThemeData(
        contentTextStyle: TextStyle(
          fontFamily: AppFont.font,
          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.SEARCH_TEXT_COLOR,
          fontSize: AppDimen.text_size_22,
          fontWeight: FontWeight.w300,
          fontFamily: AppFont.font,
        ),
        labelStyle: TextStyle(
            color: AppColors.PRIMARY_COLOR_DARK,
            fontWeight: FontWeight.bold,
            fontFamily: AppFont.font),
        errorStyle: TextStyle(
            color: AppColors.ONLINE_STATUS,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_12,
            fontFamily: AppFont.font),
      ),
      buttonTheme: ButtonThemeData(),
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    final ThemeData base = ThemeData.dark(
      useMaterial3: false,
    );
    return base.copyWith(
      primaryColor: AppColors.PRIMARY_COLOR_DARK,
      primaryColorLight: AppColors.PRIMARY_COLOR_DARK,
      primaryColorDark: AppColors.PRIMARY_COLOR_DARK,
      splashColor: Colors.transparent,
      timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
          dialHandColor: AppColors.PRIMARY_COLOR_DARK,
          dayPeriodTextColor: AppColors.PRIMARY_COLOR_DARK,
          dialBackgroundColor: AppColors.COMMON_BG_COLOR),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
        selectionHandleColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
        fontFamily: AppFont.font,
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: AppDimen.text_size_18,
          fontFamily: AppFont.font,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(
        color: AppColors.PRIMARY_COLOR_WHITE,
        fontWeight: FontWeight.w300,
        fontSize: AppDimen.text_size_14,
        fontFamily: AppFont.font,
      )),
      dialogTheme: DialogThemeData(
        contentTextStyle: TextStyle(
          fontFamily: AppFont.font,
          color: AppColors.PRIMARY_COLOR_DARK,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
            color: AppColors.SEARCH_TEXT_COLOR,
            fontSize: AppDimen.text_size_22,
            fontWeight: FontWeight.w300,
            fontFamily: AppFont.font),
        labelStyle: TextStyle(
            color: AppColors.PRIMARY_COLOR_DARK,
            fontWeight: FontWeight.bold,
            fontFamily: AppFont.font),
        errorStyle: TextStyle(
            color: AppColors.ONLINE_STATUS,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_11,
            fontFamily: AppFont.font),
      ),
      buttonTheme: ButtonThemeData(),
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(secondary: AppColors.PRIMARY_COLOR_DARK),
    );
  }
}