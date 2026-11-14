import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/widgets/dotted_line/dotted_line.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/location_data_widget.dart';
import 'package:wooberly_driver/widgets/time_line_widget.dart';


import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';

class RideRequestBottomView {
  final MapMainController controller = Get.find();
  final BuildContext context;
  final HomeViewState homeViewState;

  RideRequestBottomView(
      {required this.context,
      required this.homeViewState});

  Widget showEstimatedPrice() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        globals.showEstimatedFare &&
                (globals.showDistance || globals.showDuration)
            ?const SizedBox(
                height: 22,
              )
            : const SizedBox.shrink(),
        globals.showEstimatedFare &&
                (globals.showDistance || globals.showDuration)
            ? DottedLine(
                direction: Axis.horizontal,
                lineLength: double.infinity,
                lineThickness: 1.0,
                dashColor: AppColors.PRIMARY_COLOR_DARK)
            : const SizedBox.shrink(),
        globals.showEstimatedFare &&
                (globals.showDistance || globals.showDuration)
            ? const SizedBox(
                height: 22,
              )
            : const SizedBox.shrink(),
        if (globals.showEstimatedFare) ...[
          GetBuilder(
            init: MapMainController(),
              id: controller.rxEstimateAmountController.id,
              builder: (val) {
                return RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: "${globals.currencySymbol}",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_20,
                        fontFamily: "Roboto"),
                  ),
                  TextSpan(
                    text:
                        "${double.parse(controller.totalTripAmount.toString()).toStringAsFixed(2)}",
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_20,
                        fontFamily: AppFont.font),
                  ),
                ]),
                );
              }),
          const SizedBox(
            height: 5,
          ),
          Text(
            estimated_price.tr,
            style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w400,
                fontSize: AppDimen.text_size_14,
                fontFamily: AppFont.font),
          ),
        ],
        if (globals.showLocations &&
            (globals.showDistance ||
                globals.showDuration ||
                globals.showEstimatedFare)) ...[
          const SizedBox(
            height: 22,
          ),
          DottedLine(
              direction: Axis.horizontal,
              lineLength: double.infinity,
              lineThickness: 1.0,
              dashColor: AppColors.PRIMARY_COLOR_DARK)
        ],
      ],
    );
  }

  Widget showDistanceAndDuration() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const  SizedBox(
          height: 22,
        ),
        GetBuilder(
          init: MapMainController(),
            id: controller.rxTotalDurationController.id,
            builder: (val) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (globals.showDuration)
                    Expanded(
                      child: new Text(
                        val.rxTotalDurationController.value != ""
                            ? "${controller.totalDuration.toString()} ${minutes.tr}"
                            : "",
                        textAlign: globals.showDistance
                            ? TextAlign.end
                            : TextAlign.center,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            //WHITE_TEXT_COLOR
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_20,
                            fontFamily: AppFont.font),
                      ),
                    ),
                  if (globals.showDistance && globals.showDuration)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsetsDirectional.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  if (globals.showDistance)
                    Expanded(
                      child: new Text(
                        "${controller.distanceBwStartDest.toStringAsFixed(2)} ${globals.distanceType == "km" ? kms.tr : "mi"}",
                        textAlign: globals.showDuration
                            ? TextAlign.start
                            : TextAlign.center,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_20,
                            fontFamily: AppFont.font),
                      ),
                    ),
                ],
              );
            }),
        if (globals.showDistance || globals.showDuration) ...[
          const SizedBox(
            height: 5,
          ),
          Text(
            from_pickup_location_to_drop_location.tr,
            style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w400,
                fontSize: AppDimen.text_size_14,
                fontFamily: AppFont.font),
          )
        ],
      ],
    );
  }

  Widget showLocations() {
    LocationDataWidget locationDataWidget = LocationDataWidget();
    if (globals.showLocations)
      return GetBuilder(
        init: controller,
        id: controller.rxUpdateBookingLocationController.id,
        builder: (val) {
          List<Map<String, dynamic>> _locationData = [];

          controller.locationData.forEach((element) {
            _locationData.add({
              "id": element.id,
              "latLng": element.latLng,
              "location": element.location,
              "fieldType": element.fieldType,
              "locationStatus": element.locationStatus,
              "locationType": element.locationType,
            });
          });
          debugPrint("_locationData: ${_locationData}");
          if(_locationData.isNotEmpty) {
            if (!globals.showPickUpLocation) _locationData.removeAt(0);
            if (!globals.showDropLocation) {
              _locationData.clear();
              _locationData.add({
                "id": controller.locationData[0].id,
                "latLng": controller.locationData[0].latLng,
                "location": controller.locationData[0].location,
                "fieldType": controller.locationData[0].fieldType,
                "locationStatus": controller.locationData[0].locationStatus,
                "locationType": controller.locationData[0].locationType,
              });
            }
          }
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 22.0
            ),
            child: Timeline(
              physics: NeverScrollableScrollPhysics(),
              children: locationDataWidget.frameDisplayLocationWidgets(
                  _locationData, 'created'),
            ),
          );
        },
      );
    else
      return const SizedBox.shrink();
  }

  Widget showArrowUpDown(bool isOpen) {
    return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.PRIMARY_COLOR_DARK,
                borderRadius: BorderRadius.circular(19)),
            child:
                 RotatedBox(
                   quarterTurns: isOpen ? 2 : 0,
                   child: SvgPicture.asset(primaryUpArrow,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          AppColors.WHITE_ICON_COLOR, BlendMode.srcIn),
                    ),
                 )
                );
  }
}