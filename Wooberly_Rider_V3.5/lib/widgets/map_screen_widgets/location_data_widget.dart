import 'package:flutter/material.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';

class LocationDataWidget{
  String status ="";
  List<dynamic> locationData = [];
  // bool isTripSummary = false;




  List<Widget> frameDisplayLocationWidgets(locationdata,tripStatus) {
    status  = tripStatus;
    locationData = locationdata;
    List<Widget> widgets = [];
    for (int i = 0; i < locationData.length; i++) {
      widgets.add(displayStopLocation(locationData[i], getFieldType(i)));

    }
    return widgets;
  }


  Widget displayStopLocation(locationData, String isReached) {
    return Text(
      locationData["location"],
      textAlign: TextAlign.start,
      style: TextStyle(
          color: getColor(isReached),
          fontSize: AppDimen.text_size_14,
          fontWeight: FontWeight.w500,
          fontFamily: AppFont.font),
    );
  }

  getColor(String isReached) {
    if(isReached  =="disabled" || status == 'completed' )
      return  AppColors.PLACEHOLDER_TEXT_COLOR;
     else
      return AppColors. BLACK_TEXT_COLOR;
  }

  String getFieldType(int i) {
    if(i==0 && status == "locationReached")
      return "disabled";
     if(status =="approved"|| status == "created"|| status == "scheduled" || status == "locationReached")
       return "deletable";
     else
       return locationData[i]["fieldType"];
  }
}