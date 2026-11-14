import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../app/app_routes.dart';


import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';

class ConfirmCancelTrip extends StatefulWidget {
  bool isEdit;
  final MapMainController controller = Get.find();
  final TripPlannerIF tripPlannerIF;
  final HomeViewState homeViewState;

  ConfirmCancelTrip(
      this.isEdit, this.tripPlannerIF, this.homeViewState);

  @override
  State<StatefulWidget> createState() {
    return ConfirmCancelTripState();
  }
}

class ConfirmCancelTripState extends State<ConfirmCancelTrip> {


  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: ColoredBox(
              color: AppColors.PRIMARY_COLOR_DARK_TRAN,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    padding: const EdgeInsetsDirectional.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(bottom: 20),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  cancelTripSvg,
                                  fit: BoxFit.scaleDown,
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: Text(
                                    Confirm_Cancel.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Container(
                            color: AppColors.DIVIDER_COLOR,
                            height: 1,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 20, bottom: 24),
                            child: Text(
                              Confirm_Cancel_Desc.tr,
                              style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontSize: AppDimen.text_size_16,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () {
                                  widget.controller.rxConfirmCancelTripScreenController.value = false;
                                },
                                child: Container(
                                  width: Get.width /
                                      2.5,
                                  margin: const
                                      EdgeInsetsDirectional.only(end: 15),
                                  height: 50,
                                  padding: const EdgeInsetsDirectional.symmetric(
                                     horizontal: 30),
                                  decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_WHITE,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                      border: Border.all(
                                          width: 1,
                                          color: AppColors.PRIMARY_COLOR_DARK)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        no.tr,
                                        style: TextStyle(
                                            color:
                                                AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w500,
                                            fontSize:
                                                AppDimen.text_size_18)),
                                  ),
                                ),
                              ),
                              Container(
                                width:
                                Get.width / 2.5,
                                margin:const EdgeInsetsDirectional.only(
                                    start: 5, bottom: 5),
                                child: PrimaryButton(
                                  buttonTitle:
                                  yes.tr,
                                  buttonImage: primaryBtnArrow,
                                  callback: () {
                                    if (globals.socket?.connected ?? false) {
                                      widget.controller.checkInternet(() {
                                        widget.tripPlannerIF.cancelRideByDriver();
                                        widget.controller
                                            .rxConfirmCancelTripScreenController.value =
                                        false;
                                        Get.until((route) =>
                                        route.settings.name == "/MapMainScreen");
                                      }, true);
                                    } else {
                                      widget.controller.netOffSnackbar(() {
                                        widget.homeViewState.socketConnectionOnMapMainScreen?.socketConnect();
                                      }, false);
                                    }
                                  },
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )),
              ),
            ),
        ),
    );
  }

}

class TripPlannerIF {
  void cancelRideByDriver() {}

  void openCancelReasonScreen() {}
}