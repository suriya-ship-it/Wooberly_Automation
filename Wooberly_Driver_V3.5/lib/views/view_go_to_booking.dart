import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';

import '../app/model_theme.dart';

class ViewGoToBooking extends StatefulWidget {

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  double imageSize;

  ViewGoToBooking(
      {Key? key,
      required this.scaffoldKey,
      required this.imageSize})
      : super(key: key);

  @override
  State<ViewGoToBooking> createState() => _ViewGoToBookingState();
}

class _ViewGoToBookingState extends State<ViewGoToBooking> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return InkWell(
          onTap: () {
            Get.to(App().getAppRoutes().getWidget(AppRoutes.APP_TRIPS), transition: Transition.leftToRight);
          },
          child: Container(
            height: 65,
            alignment: Alignment.topRight,
            margin: const EdgeInsets.only(top: 20),
            child: Padding(
                padding: const EdgeInsets.all(1),
                child: Card(
                  elevation: 20,
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    height: 40,
                    width: 40,
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset(
                      yourTripsSvg,
                      width: 18,
                      height: 13,
                      colorFilter:
                          ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                    ),
                  ),
                )),
          ),
        );
      }
    );
  }
}