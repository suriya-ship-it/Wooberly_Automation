import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:app_name/models/ride_comfort_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/map_main_screen.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_images.dart';

class RideComfortView extends StatefulWidget {
  MapMainController _mapMainController = Get.find();
  late HomeViewState state;

  RideComfortView({required this.state});

  @override
  _RideComfortState createState() => _RideComfortState();
}

class _RideComfortState extends State<RideComfortView> {
  List<RideComfortModel> _localselectedRides = [];


  @override
  Widget build(BuildContext context) {
   return GetBuilder<MapMainController>(
        id: 'rideComfortController',
        builder: (builder) {

    if(!builder.rideComfortController.value)
      return const SizedBox.shrink();

    _localselectedRides = List.from(widget._mapMainController.selectedRides);
    debugPrint('_localselectedRides (panel opened): ${_localselectedRides}');
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.B3_BLACK_COLOR,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: AppColors.PRIMARY_LIGHT_COLOR,
          padding: const EdgeInsetsDirectional.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    widget._mapMainController.selectedRides.value =
                        widget._mapMainController.rideComfortData.where((element) {
                      return element.isSelected == true;
                    }).toList();

                    bool _needtoRefresh = false;
                    if (!widget._mapMainController.isScheduleRide) {
                      final newRides = widget._mapMainController.selectedRides;
                      if (newRides.length != _localselectedRides.length) {
                        // Count changed (including going from N → 0)
                        _needtoRefresh = true;
                      } else if (newRides.isNotEmpty) {
                        // Same count but check if the actual selections differ
                        for (RideComfortModel selected in newRides) {
                          final contains = _localselectedRides.any((element) => element.id == selected.id);
                          if (!contains) {
                            _needtoRefresh = true;
                            break;
                          }
                        }
                      }
                    }
                    debugPrint("_needtoRefresh: ${_needtoRefresh} --- ${widget._mapMainController.selectedRides.length} --- ${_localselectedRides} -- ${widget._mapMainController.isScheduleRide}");

                    if (_needtoRefresh) {
                      widget._mapMainController.getScheduleCategoryList( widget._mapMainController.isScheduleRideIconEnable);
                      widget._mapMainController.updatePadding(220);
                    }

                    widget._mapMainController
                        .updateRxValue(widget._mapMainController.rideComfortController, false);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
                    child: RotatedBox(
                      quarterTurns: globals.isRTLLang ? 2 : 0,
                      child: SvgPicture.asset(
                        primaryLeftArrow,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 20),
                  child: Text(
                    'Choose_comfort_ride'.tr,
                    style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimen.text_size_18,
                        fontFamily: AppFont.font),
                  ),
                ),
                ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widget._mapMainController.rideComfortData.length,
                    itemBuilder: (context, index) {
                      return GetBuilder<MapMainController>(
                          id: 'updateRideComfortController',
                          builder: (_) {
                            return createRideComfortOption(
                                context, index, widget._mapMainController.rideComfortData[index]);
                          });
                    })
              ],
            ),
          ),
        ),
      ),
    );
        });
  }

  Widget createRideComfortOption(BuildContext context, int index, RideComfortModel indexValue) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            widget._mapMainController.rideComfortData.removeAt(index);
            widget._mapMainController.rideComfortData.insert(
                index,
                RideComfortModel(indexValue.id, indexValue.title, indexValue.icon, !indexValue.isSelected,));
            widget._mapMainController.update(['updateRideComfortController']);
          },
          child: Container(
            margin: const EdgeInsetsDirectional.only(bottom: 16),
            constraints:const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
                color: AppColors.COMMON_BG_COLOR, borderRadius: BorderRadius.all(Radius.circular(3))),
            padding: const EdgeInsetsDirectional.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              children: [
                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                      color: indexValue.isSelected ? AppColors.PRIMARY_DARK_COLOR : Colors.transparent,
                      border: Border.all(
                        color: AppColors.CHECK_BOX,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Visibility(
                    visible: indexValue.isSelected,
                    child: SvgPicture.asset(
                      rideComfortSelectedSvg,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
                  width: 35,
                  height: 30,
                  child: SvgPicture.asset(
                    indexValue.icon,
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                ),
                Expanded(
                  child: Text(
                    indexValue.title,
                    style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }
}