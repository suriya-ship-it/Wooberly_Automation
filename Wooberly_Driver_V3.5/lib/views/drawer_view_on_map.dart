import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';

import '../app/model_theme.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';

class DrawerOnMap extends StatefulWidget {
  final MapMainController controller = Get.find();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  double imageSize;

  DrawerOnMap(
      {Key? key,
      required this.scaffoldKey,
      required this.imageSize})
      : super(key: key);

  @override
  State<DrawerOnMap> createState() => _DrawerOnMapState();
}

class _DrawerOnMapState extends State<DrawerOnMap> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return InkWell(
          onTap: () {
            Scaffold.of(context).openEndDrawer();
            widget.controller.change(rxVariable: widget.controller.rxOnlineSliderController, value: false);
          },
          child: Container(
            height: 65,
            alignment: Alignment.topRight,
            margin: const EdgeInsets.only(top: 20),
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
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      drawerSvg,
                      colorFilter:
                          ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                    ),
                ),
            ),
          ),
        );
      }
    );
  }
}