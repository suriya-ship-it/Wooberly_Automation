import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_name/utils/contact_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/manage_contact_controller.dart';
import 'package:app_name/widgets/map_screen_widgets/emergency_bottom_sheet.dart';
import '../../app/model_theme.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_images.dart';
import 'package:app_name/models/edit_profile_model.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';

class SafetyToolKitBody extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  SafetyToolKitBody({Key? key}) : super(key: key);

  @override
  State<SafetyToolKitBody> createState() => _SafetyToolKitBodyState();
}

class _SafetyToolKitBodyState extends State<SafetyToolKitBody> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return SafeArea(
        child: Container(
            color: AppColors.WHITE,
            padding: const EdgeInsetsDirectional.only(bottom: 20.0),
            child: Wrap(
              children: <Widget>[
                Padding(
                  padding: globals.isRTLLang
                      ? const EdgeInsetsDirectional.only(
                          top: 20, end: 26, bottom: 20)
                      : const EdgeInsetsDirectional.all(20.0),
                  child: Container(
                    child: Text(
                      'Safety_Toolkit'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_18,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                new ListTile(
                    leading: Padding(
                      padding: globals.isRTLLang
                          ? const EdgeInsetsDirectional.only(start: 10)
                          : EdgeInsetsDirectional.zero,
                      child: SvgPicture.asset(
                        shareTripSvg,
                        colorFilter: ColorFilter.mode(
                            AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ),
                    ),
                    title: new Text(
                      'Share_My_trip'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_14,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: new Text('Family_and_Friends'.tr,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_14,
                            fontWeight: FontWeight.w400)),
                    trailing: Container(
                      width: 40,
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: RotatedBox(
                          quarterTurns: globals.isRTLLang ? 2 : 0,
                          child: SvgPicture.asset(
                            primaryRightArrowSvg,
                            height: 12,
                            colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      if (globals.contacts.isEmpty) {
                        _pickContactAndShare();
                      } else {
                        widget.mapMainController
                            .checkInternet(shareLiveLocation, null);
                        widget.mapMainController.setBackNavigation();
                      }
                    }),
                const SizedBox(height: 5.0),
                Divider(
                  color: AppColors.DIVIDER_COLOR,
                  indent: globals.isRTLLang ? 25 : 20,
                  endIndent: 20,
                ),
                const SizedBox(
                  height: 5.0,
                ),
                SafeArea(
                  child: new ListTile(
                    dense: true,
                    onTap: () => {_bottomSheet911()},
                    leading: Padding(
                      padding: globals.isRTLLang
                          ? const EdgeInsetsDirectional.only(start: 10)
                          : const EdgeInsetsDirectional.only(),
                      child: SvgPicture.asset(
                        assistSOSSvg,
                        colorFilter: ColorFilter.mode(
                            AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ),
                    ),
                    title: new Text(
                      'Assistance'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_14,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: new Text('Share_your_Location'.tr,
                        style: TextStyle(
                          fontFamily: AppFont.font,
                          fontSize: AppDimen.text_size_14,
                          color: AppColors.BLACK_TEXT_COLOR,
                        )),
                    trailing: Container(
                      width: 40,
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      alignment: AlignmentDirectional.centerEnd,
                      child: RotatedBox(
                        quarterTurns: globals.isRTLLang ? 2 : 0,
                        child: SvgPicture.asset(
                          primaryRightArrowSvg,
                          height: 12,
                          colorFilter: ColorFilter.mode(
                              AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
      );
    });
  }

  /// Opens the system Contact Picker (Android 17 / API 37 compliant).
  /// Uses a native Method Channel (ACTION_PICK on Phone.CONTENT_URI);
  /// no READ_CONTACTS permission required.
  Future<void> _pickContactAndShare() async {
    Get.back(); // close the bottom sheet
    try {
      // Only one contact slot needed here; cap the picker accordingly.
      final EmergencyContacts? picked = await pickContact(maxCount: 1);
      if (picked == null) return; // cancelled or no phone

      final String name = picked.contactName ?? 'name';
      final String phone = picked.phoneNumber ?? 'number';

      if (phone.isEmpty) {
        widget.mapMainController.showInSnackBar('no_phone_found'.tr);
        return;
      }

      final ManageContactController manageContactController = Get.find();
      final String result = await manageContactController.addContact([
        EmergencyContacts(contactName: name, phoneNumber: phone)
      ]);

      if (result == '') {
        // offline — surface retry snackbar
        widget.mapMainController.showInSnackBar('offline_text'.tr);
        return;
      } else if (result != 'SUCCESS') {
        widget.mapMainController.showInSnackBar(result);
        return;
      }

      // Contact saved — now share live location
      widget.mapMainController.checkInternet(shareLiveLocation, null);
    } catch (e) {
      debugPrint('Contact picker error: $e');
    }
  }

  void _bottomSheet911() {
    Future<void> future = Get.bottomSheet(
      Builder(
        builder: (BuildContext bc) {
          return SafeArea(bottom: Platform.isAndroid, child: EmergencyBottomSheet());
        },
      ),
      isDismissible: true,
      enableDrag: true,
    );

  }

  shareLiveLocation() async {
    widget.mapMainController
        .updateRxValue(widget.mapMainController.SOSLoadingController, true);
    String status = await widget.mapMainController.shareLiveLocation(
        widget.mapMainController.driverName,
        widget.mapMainController.driverVehNum,
        await widget.mapMainController.getAddress());
    if (status == "success") {
      widget.mapMainController.tripSharedController?.forward();
      Future.delayed(Duration(seconds: 5), () {
        widget.mapMainController.tripSharedController?.reverse();
      });
      widget.mapMainController
          .updateRxValue(widget.mapMainController.SOSLoadingController, false);
    } else if (status == "offline") {
      widget.mapMainController.showInSnackBar('offline_text'.tr);
      widget.mapMainController.tripSharedController?.forward();
      Future.delayed(Duration(seconds: 5), () {
        widget.mapMainController.tripSharedController?.reverse();
      });
      widget.mapMainController
          .updateRxValue(widget.mapMainController.SOSLoadingController, false);
    } else {
      widget.mapMainController.showInSnackBar(status);
      widget.mapMainController.tripSharedController?.forward();
      Future.delayed(Duration(seconds: 5), () {
        widget.mapMainController.tripSharedController?.reverse();
      });
      widget.mapMainController
          .updateRxValue(widget.mapMainController.SOSLoadingController, false);
    }
  }
}