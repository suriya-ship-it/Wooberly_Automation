import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../views/map_main_screen.dart';

class ShowDriverReFetchIcon extends StatefulWidget {
  final MapMainController mapMainController=Get.find();
  final HomeViewState state;

  ShowDriverReFetchIcon(this.state);

  @override
  State<StatefulWidget> createState() {
    return ShowDriverReFetchState();
  }
}

class ShowDriverReFetchState extends State<ShowDriverReFetchIcon> with SingleTickerProviderStateMixin {



  @override
  Widget build(BuildContext context) {
    return Obx((){
      debugPrint("mappaddingdriverrefetch: ${widget.mapMainController.mapPaddingController.value} --- ${widget.mapMainController.isUserInTrip}");

          return !widget.mapMainController.isUserInTrip && widget.mapMainController.mapPaddingController.value>0.0 ?
            SafeArea(
              child: Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Container(
                        height: 42,
                        width: 42,
                        margin:  EdgeInsetsDirectional.only(
                          end:84.0,
                            bottom: (widget.mapMainController.mapPaddingController.value) + 28 ),
                        child:  ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                              padding:  EdgeInsetsDirectional.zero,
                              elevation: 25,
                              shape: RoundedRectangleBorder(
                                borderRadius:  BorderRadius.circular(20),
                              ),
                            ),

                            onPressed: () {
                              WidgetsBinding.instance.addPostFrameCallback((_){
                                widget.mapMainController.getScheduleCategoryList( widget.mapMainController.isScheduleRideIconEnable);
                                widget.mapMainController.updatePadding(220);

                              });
                            },
                            child:
                            SvgPicture.asset(
                              reFetchSvg,
                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                            )

                        ),
                      ),
                   ),
                    ) : const SizedBox.shrink();
        });
  }
}