import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../resources/values/app_images.dart';

class DrawerNavigationItem extends StatefulWidget {
  final String? drawerIcon;
  final String? navigationName;
  final Function? onTap;

  DrawerNavigationItem({
    this.drawerIcon,
    this.navigationName,
    this.onTap,
  });

  @override
  DrawerItemState createState() {
    return new DrawerItemState();
  }
}

class DrawerItemState extends State<DrawerNavigationItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: AppColors.PRIMARY_LIGHT_COLOR,
      focusColor: AppColors.PRIMARY_LIGHT_COLOR,
      onTap: (){
        if(widget.onTap != null)
        widget.onTap!();
      },
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  borderRadius:  BorderRadius.circular(70)),
              child: SvgPicture.asset(
                widget.drawerIcon!,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                fit: BoxFit.scaleDown,
              ),
            ),
            const  SizedBox(width: 25),
            Expanded(
                child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_16,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: "${widget.navigationName}",
                  ),
                ],
              ),
            ),
            ),
        RotatedBox(
          quarterTurns: globals.isRTLLang ? 2:0,
          child:
            SvgPicture.asset(
              primaryRightArrowSvg,
              width: 12,
              height: 12,

              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
            ),
          ],
        ),
      ),
    );
  }
}