import 'package:flutter/material.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_fonts.dart';

class LocationInfoOnTripsView {
  List<Widget> frameTrackingWidgets(locationData) {
    List<Widget> widgets = [];
    for (int i = 0; i < locationData.length; i++) {
      if (i < locationData.length - 1) {
        widgets.add(showTrackingIcon(
            false,
            locationData[i]["fieldType"] != null
                ? locationData[i]["fieldType"]
                : "disabled"));
        widgets.add(const SizedBox(
          height: 3.5,
        ));
        widgets.add(showVerticalDivider());
        widgets.add(const SizedBox(
          height: 3.5,
        ));
      } else {
        widgets.add(showTrackingIcon(
            true,
            locationData[i]["fieldType"] != null
                ? locationData[i]["fieldType"]
                : "disabled"));
      }
    }
    return widgets;
  }

  Widget showVerticalDivider() {
    return SizedBox(
      height: 55,
      child: VerticalDivider(
        width: 0.8,
        color: AppColors.DIVIDER_COLOR,
      ),
    );
  }

  Widget showTrackingIcon(bool isLast, String isReached) {
    return isLast
        ? Container(
            height: 5,
            width: 5,
            color: isReached != "disabled"
                ? AppColors.HIND_TEXT_COLOR
                : AppColors.PRIMARY_COLOR_DARK,
          )
        : Container(
            height: 5,
            width: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isReached != "disabled"
                  ? AppColors.HIND_TEXT_COLOR
                  : AppColors.PRIMARY_COLOR_DARK,
            ),
          );
  }

  List<Widget> frameDisplayLocationWidgets(locationData) {
    List<Widget> widgets = [];
    for (int i = 0; i < locationData.length; i++) {
      if (i == 0) {
        widgets.add(displayStopLocation(
            locationData[i],
            locationData[i]["fieldType"] != null
                ? locationData[i]["fieldType"]
                : "disabled"));
      } else {
        if (i == locationData.length - 1) {
          // for last location
          if (locationData[i]["location"].isNotEmpty) {
            widgets.add(displayStopLocation(
                locationData[i],
                locationData[i]["fieldType"] != null
                    ? locationData[i]["fieldType"]
                    : "disabled"));
          } else {
            widgets.add(displayStopLocation(
                locationData[i],
                locationData[i]["fieldType"] != null
                    ? locationData[i]["fieldType"]
                    : "disabled"));
          }
        } else {
          widgets.add(displayStopLocation(
              locationData[i],
              locationData[i]["fieldType"] != null
                  ? locationData[i]["fieldType"]
                  : "disabled"));
        }
      }
    }
    return widgets;
  }

  Widget displayStopLocation(locationData, String isReached) {
    return SizedBox(
      height: 46,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          locationData["location"],
          textAlign: TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: isReached != "disabled"
                  ? AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR
                  : AppColors.HIND_TEXT_COLOR,
              fontSize: AppDimen.text_size_14,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.font),
        ),
      ),
    );
  }
}