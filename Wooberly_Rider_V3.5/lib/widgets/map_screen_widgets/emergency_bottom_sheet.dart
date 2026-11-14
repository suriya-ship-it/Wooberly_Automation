import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:app_name/resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';import 'package:app_name/widgets/primary_button.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';

class EmergencyBottomSheet extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  EmergencyBottomSheet({Key? key});

  @override
  State<EmergencyBottomSheet> createState() => EmergencyBottomSheetState();
}

class EmergencyBottomSheetState extends State<EmergencyBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
          color: AppColors.WHITE,
            child: new Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 20.0),
      child: Wrap(
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 24,top: 30,bottom: 20),
            child: Container(
              child: Text(
                'Assistance'.tr,
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_18,
                    fontFamily: AppFont.font,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          GetBuilder(
            id:'addressController',
            init: widget.mapMainController,
            builder: (_) {
              if (widget.mapMainController.addressController != null) {
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 7,)
,
                  child: new ListTile(
                      minVerticalPadding: 20.0,

                      leading: SvgPicture.asset(
                          fetchLocationSvg,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ),
                      title: new Text(
                        'Estimated_current_location'.tr,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_14,
                            fontFamily: AppFont.font,
                        fontWeight: FontWeight.w400),
                      ),
                      subtitle: new Text(
                        widget.mapMainController.addressController ?? "",
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_14,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      onTap: () => {}),
                );
              } else {
                widget.mapMainController.getAddress().then((value) {
                  widget.mapMainController.addressController = value;
                  WidgetsBinding.instance.addPostFrameCallback((_){
                    widget.mapMainController.update(['addressController']);
                  });
                });
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new ListTile(
                      leading: SvgPicture.asset(
                          fetchLocationSvg,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ),
                      title: new Text(
                        'fetching_location'.tr,

                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_14,
                            fontFamily: AppFont.font),
                      ),
                      onTap: () => {}),
                );
              }
            },
          ),
          const SizedBox(height: 2.0),
          Divider(
            color: AppColors.BORDERCOLOR,
            indent: 24,
            endIndent: 24,
          ),
          const SizedBox(
            height: 2.0,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 7,)
,
            child: new ListTile(
              leading: SvgPicture.asset(
                  vehicleInformationSvg,
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
              title: new Text(
                widget.mapMainController!.driverName + 'vehicle_information'.tr,
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_14,
                    fontFamily: AppFont.font),
              ),
              subtitle: new Text(
                  widget.mapMainController!.driverVehNum,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_14,
                      fontFamily: AppFont.font,
                  fontWeight: FontWeight.w600)),
              onTap: () => {},
            ),
          ),
          SafeArea(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 15),
                  child: PrimaryButton(
                    buttonTitle: 'Call_911'.tr,
                    buttonImage: primaryRightArrowSvg,
                    callback: (){
                        Get.back();
                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }
                      UrlLauncher.launchUrl(Uri.parse("tel://911"));
                    },
                  ),
                ),
            ),
          ),
        ],
      ),
    )));
  }
}