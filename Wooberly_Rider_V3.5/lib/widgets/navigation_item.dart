import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'dart:math' as math;

import '../resources/values/app_images.dart';

class NavigationItem extends StatefulWidget {
 late final String iconWidget;
 late final String navigationName;
 late final String navigationValue;
 late final bool isShowdivider;
 late final Function onTap;

  NavigationItem({
   required this.iconWidget,
    required this.navigationName,
    required this.navigationValue,
    required this.isShowdivider,
    required this.onTap,
  });

  @override
  OrderedItemState createState() {
    return new OrderedItemState();
  }
}

class OrderedItemState extends State<NavigationItem> {
  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: (){
        if(widget.onTap != null)
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: globals.isRTLLang ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius:
                       BorderRadius
                          .circular(10.0),
                    color: AppColors.PRIMARY_LIGHT_COLOR
                  ),
                  padding: const EdgeInsetsDirectional.all(16),
                  child: SvgPicture.asset(
                    widget.iconWidget,
                     colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.navigationName}",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontFamily: AppFont.font,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const  SizedBox(
                        height: 5,
                      ),
                      Text(
                       widget.navigationValue,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_14,
                            fontWeight: FontWeight.w400
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 25),
                  child: RotatedBox(
                    quarterTurns: globals.isRTLLang ? 2:0,
                    child: SvgPicture.asset(
                      primaryRightArrowSvg,
                      width: 6.0,
                      height: 11.0,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),

                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            widget.isShowdivider ?
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ):const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}