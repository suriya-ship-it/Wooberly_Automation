import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';

class AppStyles {
  static ThemeData lightTheme(){
    final ThemeData base = ThemeData.light(
      useMaterial3: false
    );

    return base.copyWith(
      primaryColor: AppColors.PRIMARY_DARK_COLOR,
      primaryColorLight: AppColors.PRIMARY_DARK_COLOR,
      primaryColorDark: AppColors.PRIMARY_DARK_COLOR,
      splashColor: Colors.transparent,
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
        dialHandColor: AppColors.PRIMARY_DARK_COLOR,
        dayPeriodTextColor: AppColors.PRIMARY_DARK_COLOR,
        dialBackgroundColor: AppColors.BORDERCOLOR
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.BLACK_TEXT_COLOR,
        selectionHandleColor: Colors.transparent,
      ),
      textTheme:base.textTheme.apply(
        bodyColor: AppColors.BLACK_TEXT_COLOR,
        fontFamily: AppFont.font,
      ),

      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(fontSize:AppDimen.text_size_18,
          fontFamily: AppFont.font,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_14,
            fontFamily:AppFont.font,
          )
      ),

      dialogTheme: DialogThemeData(
        contentTextStyle: TextStyle(
          fontFamily: AppFont.font,
          color: AppColors.PRIMARY_DARK_COLOR,
        ),
      ),


      inputDecorationTheme: InputDecorationTheme(


        hintStyle: TextStyle(
            color: AppColors.PLACEHOLDER_TEXT_COLOR,
            fontSize: AppDimen.text_size_22,
            fontWeight: FontWeight.w300,
            fontFamily: AppFont.font
        ),
        labelStyle: TextStyle(
            color: AppColors.PRIMARY_DARK_COLOR,
            fontWeight: FontWeight.bold,
            fontFamily: AppFont.font
        ),
        errorStyle: TextStyle(
            color: AppColors.EXCEPTION_COLOR,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_11,
            fontFamily: AppFont.font
        ),


      ),
      buttonTheme: ButtonThemeData(
      ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: AppColors.PRIMARY_DARK_COLOR),
    );
  }

  static ThemeData darkThemeNew(){
    final ThemeData base = ThemeData.dark(
        useMaterial3: false
    );

    return base.copyWith(
      primaryColor: AppColors.PRIMARY_DARK_COLOR,
      primaryColorLight: AppColors.PRIMARY_DARK_COLOR,
      primaryColorDark: AppColors.PRIMARY_DARK_COLOR,
      splashColor: Colors.transparent,
      timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
          dialHandColor: AppColors.PRIMARY_DARK_COLOR,
          dayPeriodTextColor: AppColors.PRIMARY_DARK_COLOR,
          dialBackgroundColor: AppColors.BORDERCOLOR
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.BLACK_TEXT_COLOR,
        selectionHandleColor: Colors.transparent,
      ),
      textTheme:base.textTheme.apply(
        bodyColor: AppColors.BLACK_TEXT_COLOR,
        fontFamily: AppFont.font,
      ),

      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(fontSize:AppDimen.text_size_18,
          fontFamily: AppFont.font,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_14,
            fontFamily:AppFont.font,
          )
      ),

      dialogTheme: DialogThemeData(
        contentTextStyle: TextStyle(
          fontFamily: AppFont.font,
          color: AppColors.PRIMARY_DARK_COLOR,
        ),
      ),


      inputDecorationTheme: InputDecorationTheme(

        hintStyle: TextStyle(
            color: AppColors.PLACEHOLDER_TEXT_COLOR,
            fontSize: AppDimen.text_size_22,
            fontWeight: FontWeight.w300,
            fontFamily: AppFont.font
        ),
        labelStyle: TextStyle(
            color: AppColors.PRIMARY_DARK_COLOR,
            fontWeight: FontWeight.bold,
            fontFamily: AppFont.font
        ),
        errorStyle: TextStyle(
            color: AppColors.EXCEPTION_COLOR,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_11,
            fontFamily: AppFont.font
        ),


      ),
      buttonTheme: ButtonThemeData(
      ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: AppColors.PRIMARY_DARK_COLOR),
    );
  }
}