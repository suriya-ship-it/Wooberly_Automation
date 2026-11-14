import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../app/app.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';
import '../custom_dialog_box.dart';

class DriverStatusBottomView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

   DriverStatusBottomView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<DriverStatusBottomView> createState() => _DriverStatusBottomViewState();
}

class _DriverStatusBottomViewState extends State<DriverStatusBottomView>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: MapMainController(),
        id: widget.controller.rxOnlineStatus.id,
        builder: (val) {
          debugPrint("widget.controller.rxOnlineStatus.value : ${widget.controller.rxOnlineStatus.value} ---${globals.driverStatus} -- ${globals.isActive} ");
          return (widget.controller.rxOnlineStatus.value == false &&  globals.driverStatus == "active")
              ? Obx(() {
            return widget.controller.rxMapPaddingController.value != null ? Padding(
              padding:const EdgeInsets.only(bottom: 120),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.TEXT_LINK_COLOR,
                          width: 14),
                      shape: BoxShape.circle),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.PRIMARY_COLOR_WHITE, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: RawMaterialButton(
                      onPressed: () async {

                        bool isLocationEnable = await  widget.controller.isLocationPermissionsEnabled();
                        debugPrint("isLocationDisable: ${isLocationEnable}");
                        if(!isLocationEnable) {
                         widget.homeViewState.showlocationDialog();
                       } else {
                         _getLocation();
                       }

                      },
                      splashColor: AppColors.TEXT_LINK_COLOR,
                      fillColor: AppColors.TEXT_LINK_COLOR,
                      shape: CircleBorder(),
                      child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                              go.tr,
                              style: TextStyle(
                                  color: AppColors.WHITE_TEXT_COLOR,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimen.text_size_24,
                                  fontFamily: AppFont.font),
                          ),
                      ),
                    ),
                  ),
                ),
              ),
            ) : const SizedBox.shrink();
          }) : const SizedBox.shrink();
        });
  }

  _getPaymentMethods() {
    widget.controller.getPaymentMethods().then((value) {
      if (value?.isNotEmpty ?? false) {
        widget.controller.showInSnackBar(value!);
      } else {
        if (globals.paymentMethods.contains(2) || globals.paymentMethods.contains(5))
          widget.controller.showInSnackBar(empty_payout_content.tr);
      }
    });
  }
  Future<void> _getLocation() async {
      Map<String,dynamic> walletoption = globals.driverWalletOptionController.value;
      if(!(walletoption["driverWalletOption"] == "1" && walletoption["walletFlow"] == "allPaymentMethods")){
        if (!globals.isPayout && globals.payout == 0)
          widget.controller.checkInternet(_getPaymentMethods, false);
      }
      widget.homeViewState.internetCheckOnMapMainScreen?.checkInternetTrackLoc("goonlineclick");

  }

}