import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../spin_kit/three_bounce.dart';

class ShowSOSButton extends StatefulWidget {
  final MapMainController mapMainController=Get.find();
  late Function bottomSheetSafetyToolKit;

  ShowSOSButton({Key? key,required this.bottomSheetSafetyToolKit})
      : super(key: key);

  @override
  State<ShowSOSButton> createState() => ShowSOSButtonState();
}

class ShowSOSButtonState extends State<ShowSOSButton> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child:
      GetBuilder<MapMainController>(
        id: 'SOSavailController',
        builder: (builder) {
          if (builder.SOSavailController.value == true) {
            return GetBuilder<MapMainController>(
                id:'SOSLoadingController',
                builder: (builder) {
                  return Obx(()=>
                    Container(
                      margin: EdgeInsetsDirectional.only(end: 82.0,
                          bottom: (widget.mapMainController.mapPaddingController.value) + 28.0),
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          SlideTransition(
                            position: widget.mapMainController.tripSharedOffset!,
                            child: Container(
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width - 150,
                              padding: const EdgeInsetsDirectional.only(
                                  start: 5, end: 5.0),
                              child: Text(
                                'trip_shared_with'.tr + " " +
                                    "${'trusted_contacts'.tr}.".toLowerCase(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR),),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          SlideTransition(
                            position: widget.mapMainController.sosIconOffset!,
                            child:
                            Container(
                              height: 42,
                              width: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                                  elevation: 25,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding:  EdgeInsetsDirectional.zero,
                                ),
                                onPressed: () async {
                                  widget.bottomSheetSafetyToolKit();
                                },
                                child: builder.SOSLoadingController.value== true ? SpinKitThreeBounce(
                                  color: AppColors.PRIMARY_ICON_COLOR,
                                  size: 15.0,
                                ) : SvgPicture.asset(
                                  updatedShieldSvg,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.PRIMARY_ICON_COLOR,
                                      BlendMode.srcIn),
                                  fit: BoxFit.fitHeight,

                                ),),
                            ),


                          ),
                        ],
                      ),
                    ),
                  );
                });
          }
          else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}