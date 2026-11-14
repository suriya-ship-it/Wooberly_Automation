import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../resources/values/app_images.dart';

class DrawerNavigationItem extends StatefulWidget {
  final String? drawerIcon;
  final String? navigationName;
  final String? walletAmount;
  final Function? onTap;

  DrawerNavigationItem({
    this.drawerIcon,
    this.navigationName,
    this.walletAmount,
    this.onTap,
  });

  @override
  DrawerNavigationItemState createState() {
    return new DrawerNavigationItemState();
  }
}

class DrawerNavigationItemState extends State<DrawerNavigationItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: AppColors.PRIMARY_COLOR_WHITE,
      focusColor: AppColors.PRIMARY_COLOR_WHITE,
      onTap: () {
        if (widget.onTap != null) widget.onTap!();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.circular(70)),
              child: SvgPicture.asset(
                widget.drawerIcon!,
                width: 20,
                height: 20,
                colorFilter:
                    ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                fit: BoxFit.scaleDown,
              ),
            ),
            const SizedBox(width: 25),
            Expanded(
                child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_16,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: "${widget.navigationName}",
                  ),

                  if(widget.walletAmount !=null)
                  TextSpan(
                    text: "${globals.currencySymbol}",
                    style: TextStyle(fontFamily: "Roboto"),
                  ),

                  if(widget.walletAmount !=null)
                    TextSpan(
                      text: "${widget.walletAmount}",
                    ),
                ],
              ),
            ),
            ),
            SvgPicture.asset(
              rightArrowSvg,
              width: 12,
              height: 12,
              fit: BoxFit.fill,
              matchTextDirection: true,
              colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}