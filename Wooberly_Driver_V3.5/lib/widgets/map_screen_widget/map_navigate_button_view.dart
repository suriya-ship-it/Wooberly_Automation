import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;


import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';

class MapNavigateButtonView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  MapNavigateButtonView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  getOnlineStatusView() {
    return GetBuilder(
        init: MapMainController(),
        id: controller.rxOnlineStatus.id,
        builder: (val) {
          bool isInTrip =   (controller.tripStatus == "approved" ||
              controller.tripStatus == "locationReached" ||
              controller.tripStatus == "started" ||
              controller.tripStatus == "created");
          debugPrint("globals.driverStatus: ${globals.driverStatus} -- ${controller.tripStatus}");
          return Opacity(
            opacity: globals.driverStatus.compareTo("active") != 0 && !isInTrip ? 1.0 : 0.0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all( 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.PRIMARY_COLOR_WHITE, width: 1),
                  color: AppColors.WARNING_COLOR,
                  borderRadius: BorderRadius.all(Radius.circular(23.0)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.COMMON_BG_COLOR,
                        blurRadius: 2,
                        offset: Offset(3.0, 3.0))
                  ],
                ),
                width: Get.width - 150,
                child: Text( globals.driverStatus.contains("NotEligible") && globals.driverStatus.split("_")[0] =="active" ?not_eligible_for_ride_request.tr : waiting_admin_approve.tr,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_16,
                    )),
              ),
            ),
          );
        });
  }

  @override
  State<MapNavigateButtonView> createState() => _MapNavigateButtonViewState();
}

class _MapNavigateButtonViewState extends State<MapNavigateButtonView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: showNavigationButton(),
      alignment: AlignmentDirectional.bottomEnd,
    );
  }

  showNavigationButton() {
    return GetBuilder(
      init: MapMainController(),
        id: widget.controller.rxNavigationButtonstatus.id,
        builder: (val) {
          return SlideTransition(
              position: widget.homeViewState.navigationButOffset!,
              child: Obx(() {
                debugPrint('widget.controller.rxMapPaddingController.value: ${widget.controller.rxMapPaddingController.value}');
                double bottompadding = widget.controller.rxMapPaddingController.value ;
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                      top: 20,
                      bottom: bottompadding + 80),
                  child: widget.controller.rxNavigationButtonstatus.value != -1
                      ? Container(
                      child: InkWell(
                          onTap: () {
                            int position = 0;
                            for (int i = 0;
                            i <
                                widget
                                    .controller.locationData.length;
                            i++) {
                              if (widget.controller.locationData[i]
                                  .locationStatus ==
                                  "pending") {
                                position = i;
                                break;
                              }
                            }
                            widget.controller.openMap(
                                widget.controller.mapLocation.latitude,
                                widget.controller.mapLocation.longitude,
                                widget.controller.locationData[position]
                                    .latLng.latitude,
                                widget.controller.locationData[position]
                                    .latLng.longitude);
                          },
                          child: Container(
                          margin:  const EdgeInsetsDirectional.only(
                            bottom: 20.0),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.TEXT_LINK_COLOR),
                                  borderRadius:
                                  new BorderRadius.circular(23.0),
                                  color: AppColors.TEXT_LINK_COLOR),
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 15,
                                  vertical: 6),
                              child: new Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    new SvgPicture.asset(
                                      NavigateSvg,
                                      width: 14.0,
                                      height: 14.0,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                          AppColors.PRIMARY_COLOR_WHITE,
                                          BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 7),
                                    new Text(
                                      navigate.tr,
                                      style: TextStyle(
                                          fontSize:
                                          AppDimen.text_size_16,
                                          color: AppColors
                                              .WHITE_TEXT_COLOR,
                                          fontFamily: AppFont.font,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ],),),),)
                      : const SizedBox.shrink(),
                );
              }));
        });
  }
}