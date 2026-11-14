import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/primary_button.dart';

import '../databases/app_preferences.dart';
import '../resources/values/app_images.dart';
import '../controllers/map_main_controller/map_main_controller.dart';
import '../views/map_main_screen.dart';

class ConfirmCancelTrip extends StatefulWidget {
  bool isEdit;
  final MapMainController mapMainController=Get.find();

  final HomeViewState state;

  ConfirmCancelTrip(
      this.isEdit, this.state);

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
            body: Container(
              color: AppColors.B3_BLACK_COLOR,
              alignment: Alignment.bottomCenter,
              child: Container(
                color: AppColors.PRIMARY_LIGHT_COLOR,
                padding: const  EdgeInsetsDirectional.all(24),
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
                                'Confirm_Cancel'.tr,
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontSize: AppDimen.text_size_18,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(
                        color: AppColors.DIVIDER_COLOR,
                        height: 1,
                      ),
                      Padding(
                          padding: const EdgeInsetsDirectional.only(top: 20,bottom: 24),
                        child: Text(
                          'Confirm_Cancel_Desc'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontFamily: AppFont.font,
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w400
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: (){
                              widget.mapMainController.confirmCancelTripScreenController(false);
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width /2.5,
                              margin: const EdgeInsetsDirectional.only(end: 15),
                              height: 50,
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 30,)
,
                              decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(width: 1, color: AppColors.PRIMARY_DARK_COLOR)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('no'.tr,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_18
                                    )),
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width /2.5,
                            margin: const EdgeInsetsDirectional.only(start: 5,bottom: 5),
                            child: PrimaryButton(
                                buttonTitle: 'yes'.tr,
                                buttonImage: primaryBtnArrow,
                                callback: (){
                                  widget.mapMainController.unreadCount=0;
                                  widget.state.cancelRideByRider();
                                  Get.until((route) => route.settings?.name == AppRoutes.APP_MAP_MAIN);
                                  widget.mapMainController.confirmCancelTripScreenController(false);
                                }
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ),
            ),
        ),
    );
  }

}