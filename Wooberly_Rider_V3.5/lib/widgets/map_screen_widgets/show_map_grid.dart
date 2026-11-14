import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
class ShowMapGridIcon extends StatefulWidget {
  final MapMainController mapMainController=Get.find();

  ShowMapGridIcon({Key? key}) : super(key: key);

  @override
  State<ShowMapGridIcon> createState() => ShowMapGridIconState();
}

class ShowMapGridIconState extends State<ShowMapGridIcon> {
  @override
  Widget build(BuildContext context) {
    return Obx((){
          return widget.mapMainController.mapLoadingController.value == true
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: AppColors.GRID_COLOR,
                  child: Image.asset(
                    mapGridPng,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.fill,
                  ),
                )
              : const SizedBox.shrink();
        });
  }
}