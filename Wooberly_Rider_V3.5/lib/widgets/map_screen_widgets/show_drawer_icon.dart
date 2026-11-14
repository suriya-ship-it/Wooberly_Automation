import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../app/app_routes.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';

class ShowDrawerIcon extends StatefulWidget {
  final MapMainController mapMainController=Get.find();
  late final GlobalKey<ScaffoldState> scaffoldKey;

  ShowDrawerIcon({Key? key,required this.scaffoldKey}) : super(key: key);

  @override
  State<ShowDrawerIcon> createState() => ShowDrawerIconState();
}

class ShowDrawerIconState extends State<ShowDrawerIcon> {
  late MapMainController _mapMainController;
  void initState() {

    _mapMainController = widget.mapMainController;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Obx((){
   widget.mapMainController.scheduleRideIconController.value;
          return Align(
              alignment:   AlignmentDirectional.topEnd ,
              child: InkWell(
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                },
                child: Container(
                  width: 42.0,
                  height: 42.0,
                  margin: const EdgeInsetsDirectional.only(top:30.0, end:24.0,start: 24.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                  ),
                  child:
                  Container(
                    height: 10.0,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10.0,)
,
                    child:  SvgPicture.asset(
                      height: 15,
                      width: 15,
                      drawerSvg,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR,BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
          );
        }
    );
  }
}