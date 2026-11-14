import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../../views/map_main_screen.dart';


class ShowDestLocationOnTop extends StatefulWidget {
  final MapMainController mapMainController=Get.find();
  late final HomeViewState state;

  ShowDestLocationOnTop({Key? key,required  this.state})
      : super(key: key);

  @override
  State<ShowDestLocationOnTop> createState() => ShowDestLocationOnTopState();
}

class ShowDestLocationOnTopState extends State<ShowDestLocationOnTop> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(widget.mapMainController.locationData.length>=2) {
        widget.mapMainController.destPlaceController.value = widget.mapMainController.locationData.last.location ?? '';
        debugPrint("widget.mapMainController.destPlaceController.value: ${widget
            .mapMainController.destPlaceController.value}");
      }
    });
    return SlideTransition(
        position: widget.mapMainController.destLocOffset!,
        child: GetBuilder<MapMainController>(
          builder: (builder) {
            return Obx((){
             widget.mapMainController.scheduleRideIconController.value;
                  return Container(
                    margin: EdgeInsetsDirectional.only(
                        top: 20.0,
                        start: 24.0,
                        end:   70.0),
                    height: 60,
                    child: Card(
                      elevation: 10,
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      child: Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 10,
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsetsDirectional.symmetric(vertical: 3.0,),
                            decoration: ShapeDecoration(
                              color: AppColors.BLACK_TEXT_COLOR,
                              shape: RoundedRectangleBorder(),
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          GetBuilder<MapMainController>(
                            id: 'destPlaceController',
                                  builder:(_) {
                                return Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      if (!(widget.mapMainController.confirmPopupAnimController?.status == AnimationStatus.completed)) {
                                        globals.closeKeyBoard = false;
                                        widget.mapMainController.checkInternet(widget.mapMainController.moveToSelectDropLocation, true);
                                      }
                                      else {
                                        if (widget.mapMainController.isScheduleRideIconEnable &&
                                            widget.mapMainController.locationData.last.location !=null &&
                                            widget.mapMainController.locationData.last.location!.isNotEmpty) {
                                          widget.mapMainController
                                              .setLocIconPositionForConfirm();
                                        } else {
                                          if (widget.mapMainController.isScheduleRideConfirmed) {
                                            widget.mapMainController.setLocIconPositionForConfirm();
                                          } else {
                                            widget.mapMainController.setDefaultLocationIconPosition();
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      height: 60,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: SingleChildScrollView(
                                        reverse: false,
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                           globals.currentLocation.value.isEmpty
                                              ?'enter_pickup'.tr
                                              : (widget.mapMainController.destPlaceController.value.isEmpty)
                                                  ?'where_to'.tr
                                                  :widget.mapMainController.destPlaceController.value ,
                                          style: TextStyle(
                                              color: AppColors
                                                  .BLACK_TEXT_COLOR,
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  AppDimen.text_size_14),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          const SizedBox(
                            width: 3,
                          ),
                          if ( widget.mapMainController.locationData.length < 3)
                            InkWell(
                              onTap: () {
                                widget.mapMainController.isScheduleRideTripSelected.value = widget.mapMainController.isScheduleRide;
                                widget.mapMainController.rideTypeSelectionAnimController?.forward();
                              },
                              child: Container(
                                  width: 85,
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 11, end: 11, top: 4, bottom: 5),
                                  decoration: BoxDecoration(
                                    color: !widget.mapMainController.isScheduleRide
                                        ? AppColors.COMMON_BG_COLOR
                                        : AppColors.PRIMARY_DARK_COLOR,
                                    borderRadius:
                                        new BorderRadius.circular(17.0),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(top: 2),
                                        child: SvgPicture.asset(
                                          height: 15,
                                          width: 15,
                                          WhereToNowSvg,
                                          colorFilter: ColorFilter.mode(!widget.mapMainController.isScheduleRide?AppColors.PRIMARY_ICON_COLOR:AppColors.PRIMARY_LIGHT_COLOR,BlendMode.srcIn),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Flexible(
                                        child: Container(
                                          width: 40,
                                          child: Text(
                                            !widget.mapMainController.isScheduleRide
                                                ?'now_label'.tr
                                                : "${'scheduled'.tr}.",
                                            overflow: TextOverflow.clip,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: !widget.mapMainController.isScheduleRide
                                                    ? AppColors.BLACK_TEXT_COLOR
                                                    : AppColors.PRIMARY_LIGHT_COLOR,
                                                fontSize:
                                                    AppDimen.text_size_14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(top: 4),
                                        child: SvgPicture.asset(
                                          height: 5,
                                          width: 5,
                                          primaryDownArrow,
                                          colorFilter: ColorFilter.mode(!widget.mapMainController.isScheduleRide?AppColors.PRIMARY_ICON_COLOR:AppColors.PRIMARY_LIGHT_COLOR,BlendMode.srcIn),
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                          const SizedBox(
                            width: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                });
          },
        ),
    );
  }
}