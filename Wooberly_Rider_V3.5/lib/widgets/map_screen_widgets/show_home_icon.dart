import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../app/app.dart';
import '../../app/app_routes.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';

class ShowHomeIcon extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  ShowHomeIcon();

  @override
  State<ShowHomeIcon> createState() => ShowHomeIconState();
}

class ShowHomeIconState extends State<ShowHomeIcon> {



  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: AlignmentDirectional.bottomStart,
        child:
             Obx(() {
               debugPrint("homeiconshow: ${widget.mapMainController.isUserInTrip} --- ${widget.mapMainController.mapPaddingController.value}");
             return  !(widget.mapMainController.isUserInTrip &&
                   widget.mapMainController.mapPaddingController.value != null)
                   ?
               Container(
                 height: 42,
                 width: 42,
                 margin: EdgeInsetsDirectional.only(
                     start: 24.0,
                     bottom: (widget.mapMainController.mapPaddingController
                         .value) + 28),
                 child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor:
                       AppColors.PRIMARY_LIGHT_COLOR,
                       padding: EdgeInsetsDirectional.zero,
                       elevation: 25,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(25),
                       ),
                     ),
                     onPressed: () {
                       debugPrint("widget.mapMainController.mapControllerCompleter: ${widget.mapMainController.mapControllerCompleter.isCompleted}");
                       if (widget.mapMainController.mapControllerCompleter.isCompleted) {
                         clearPreferranceValue();
                         Get.offNamedUntil(
                             AppRoutes.APP_HOME, (route) => route.isActive);
                       }
                     },
                     child: SvgPicture.asset(
                       homeScreenSvg,
                       colorFilter: ColorFilter.mode(
                           AppColors.PRIMARY_ICON_COLOR,
                           BlendMode.srcIn),
                     )),
               )
                   : const SizedBox.shrink();
             }
        )
           );
  }

  clearPreferranceValue() {
    widget.mapMainController.updatePadding(0.0);
    widget.mapMainController.vehicleCatAnimController?.reverse();
    widget.mapMainController.isScheduleRide = false;
    widget.mapMainController.scheduleRideIconController(false);
    widget.mapMainController.scheduleRideIconController.refresh();
    widget.mapMainController.locationData.clear();
    widget.mapMainController.lastKnownLocation = LatLng(0.0, 0.0);
    widget.mapMainController.destLocAnimController?.forward();
    widget.mapMainController.setDestPlaceController("");
    widget.mapMainController.clearMap();
    widget.mapMainController.isScheduleRideConfirmed = false;
    widget.mapMainController.isFromSchedule = false;
    widget.mapMainController.locationData.clear();
    widget.mapMainController.appliedCoupon = "";
    widget.mapMainController.selectedSpecialID = 0;
    globals.refreshApp = true;
    widget.mapMainController.dispose();
  }
}