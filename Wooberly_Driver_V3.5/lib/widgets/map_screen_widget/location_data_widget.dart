import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';

class LocationDataWidget {
  String status = "";
  List<dynamic> locationData = [];

  List<Widget> frameDisplayLocationWidgets(locationdata, tripStatus) {
    status = tripStatus;

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
    if (isReached == "disabled")
      return AppColors.HIND_TEXT_COLOR;
    else
      return AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR;
  }

  String getFieldType(int i) {
    if (i == 0 && status == "locationReached") return "disabled";
    if (status == "approved" ||
        status == "created" ||
        status == "scheduled" ||
        status == "locationReached")
      return "deletable";
    else
      return locationData[i]["fieldType"];
  }
}


class ChatIconColorMapper extends ColorMapper {
  final Color targetColor;

  const ChatIconColorMapper(this.targetColor);

  @override
  Color substitute(
      String? id,
      String elementName,
      String attributeName,
      Color color,
      ) {
    // Detect the dark black/grey color used in the paths (#131314)
    if (color == AppColors.SVGCHANGECOLOR) {
      return targetColor;
    }
    // Return the original color for everything else (keeps the red circle)
    return color;
  }
}