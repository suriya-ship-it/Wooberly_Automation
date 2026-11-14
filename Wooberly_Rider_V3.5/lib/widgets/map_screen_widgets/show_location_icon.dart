import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';

class ShowLocationIcon extends StatefulWidget {
  final MapMainController mapMainController=Get.find();

  ShowLocationIcon();

  @override
  State<ShowLocationIcon> createState() => ShowLocationIconState();
}

class ShowLocationIconState extends State<ShowLocationIcon> {
  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Obx((){
            return Container(
              height: 42,
              width: 42,
              margin: EdgeInsetsDirectional.only(end: 24.0,
                  bottom: (widget.mapMainController.mapPaddingController.value) + 28),
              child: ValueListenableBuilder<bool>(
                  valueListenable: widget.mapMainController.locationFetchController,

                builder: (context, locationFetchSnapshot,child) {
                  return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                      padding:  EdgeInsetsDirectional.zero,

                      elevation: 25,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      ),
                    onPressed: () async {
                      debugPrint("mapvalue: } --- ${widget.mapMainController.locationData}");
                      if (await Permission.location.serviceStatus.isDisabled || await Permission.location.isPermanentlyDenied || await Permission.location.isRestricted) {
                        widget.mapMainController.showLocationPermissionAlert(
                           'Enable_the_location_service'.tr,
                            true);
                        return;
                      }
                      var locationPermissionStatus = await widget.mapMainController.listenForPermissionStatus1(Permission.location);
                      switch (locationPermissionStatus) {
                        case PermissionStatus.granted:
                          widget.mapMainController.locationFetchController.value = true;

                          debugPrint("mapvalue: ${widget.mapMainController.isUserInTrip} --- ${widget.mapMainController.locationData} --- ");
                            if (!widget.mapMainController.isUserInTrip && widget.mapMainController.locationData.isEmpty) {
                                globals.userLat = 0.0;
                                globals.userLon = 0.0;
                                await widget.mapMainController.requestPermission();
                                widget.mapMainController.lastKnownLocation = LatLng(globals.userLat, globals.userLon);
                              String? locationname =   await widget.mapMainController.getUserLocationName();
                                debugPrint("getCurrentLocation: ${globals.userLat} -- ${locationname} -- ${globals.tripStatus}");
                                widget.mapMainController.moveToUserLocation();
                                widget.mapMainController.locationFetchController.value = false;

                            } else {
                              widget.mapMainController.moveToUserLocation();
                              widget.mapMainController.locationFetchController.value = false;
                            }

                          break;
                        case PermissionStatus.denied:
                          widget.mapMainController.showLocationPermissionAlert(
                              'Enable_the_location_service'.tr,
                              false);
                          break;
                        default:
                          widget.mapMainController.showLocationPermissionAlert(
                              'Enable_the_location_service'.tr,
                              false);
                          break;
                      }
                    },
                      child: locationFetchSnapshot == true ?
                      SizedBox(
                        height: 25.0,
                        width: 25.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          backgroundColor:
                          AppColors.PRIMARY_DARK_COLOR,
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              AppColors.INDICATOR_COLOR),
                        ),
                      ):
                      SvgPicture.asset(
                        targetSvg,
                        fit: BoxFit.scaleDown,
                         colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ),
                  );
                }
              ),
            );
          }
        ));
  }
}