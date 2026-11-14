import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';

class NavigationItem extends StatefulWidget {
  final String iconWidget;
  final String navigationName;
  final String navigationValue;
  final bool isShowdivider;
  final Function onTap;

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
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return InkWell(
          onTap: () {
            if (widget.onTap != null) widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, top: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: globals.isRtlLang
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          borderRadius: new BorderRadius.circular(10.0),
                          color: AppColors.PRIMARY_COLOR_WHITE),
                      padding: EdgeInsetsDirectional.all(16),
                      child: SvgPicture.asset(
                        widget.iconWidget,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
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
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            widget.navigationValue,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_14,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 25),
                      child: SvgPicture.asset(
                        rightArrowSvg,
                        matchTextDirection: true,
                        width: 6.0,
                        height: 10.0,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
                const  SizedBox(height: 30),
                widget.isShowdivider
                    ? Divider(
                        height: 5,
                        color: AppColors.DIVIDER_COLOR,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      }
    );
  }
}