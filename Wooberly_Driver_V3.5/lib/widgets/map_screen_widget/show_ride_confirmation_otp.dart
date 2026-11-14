import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';

import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/pin_input_text_field.dart';
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_lang.dart';




class RideConfirmationOtpView extends StatefulWidget {
  final MapMainController controller = Get.find();
  late HomeViewState state;

  RideConfirmationOtpView( {required this.state});

  @override
  _RideConfirmationOtpState createState() => _RideConfirmationOtpState();
}

class _RideConfirmationOtpState extends State<RideConfirmationOtpView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.controller,
      id: widget.controller.rxRideConfirmOTPScreenStatusController.id,
      builder: (val) {
          if(val.rxRideConfirmOTPScreenStatusController.value != RideConfirmOTPScreenStatus.InActive)
        return SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.PRIMARY_COLOR_DARK_TRAN,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: Get.width,
                color: AppColors.PRIMARY_COLOR_WHITE,
                padding: const EdgeInsetsDirectional.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        verify_otp.tr,
                        style: TextStyle(
                            fontSize: AppDimen.text_size_22,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.font,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6,),
                      Text(
                        ask_for_otp_to_start_ride.trParams({"field":widget.controller.riderName}),
                        style: TextStyle(
                            fontSize: AppDimen.text_size_16,
                            fontFamily: AppFont.font,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30,),

                      PinInputTextField (
                        pinLength: 4,
                        hintText: '0000',
                        pinBoxColor: AppColors.COMMON_BG_COLOR,
                        controller: widget.controller.rideConfirmOTPEntryController,
                        textInputAction: TextInputAction.done,
                        enabled: true,
                        onSubmit: (pin) {},
                        onChanged: (pin) {
                         widget.controller.change(rxVariable: widget.controller.rxRideConfirmOTPScreenStatusController, value: widget.controller.rxRideConfirmOTPScreenStatusController.value);
                        },
                      ),
                      const SizedBox(height: 50,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if(val.rxRideConfirmOTPScreenStatusController.value!= RideConfirmOTPScreenStatus.Loading)
                                  widget.controller.change(rxVariable: widget.controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.InActive);
                              },
                              child: Container(
                                width: Get.width,
                                margin: const EdgeInsetsDirectional.only(end: 10),
                                height: 50,
                                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                    Border.all(width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                                alignment: Alignment.center,
                                child: Text(cancel.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: PrimaryButton(
                              buttonTitle: verify.tr,
                              BtnDisableColor: widget.controller.rideConfirmOTPEntryController.text.isNotEmpty && widget.controller.rideConfirmOTPEntryController.text.length ==4 ? AppColors.PRIMARY_COLOR_DARK : AppColors.PRIMARY_COLOR_DARK.withAlpha(80),
                              buttonImage: primaryBtnArrow,
                              callback: () {
                                if(widget.controller.rideConfirmOTPEntryController.text.toString().length == 4) {
                                  widget.controller.closeMessage(context);
                                  widget.controller.checkInternet((){
                                    widget.controller.change(rxVariable: widget.controller.rxRideConfirmOTPScreenStatusController, value: RideConfirmOTPScreenStatus.Loading);
                                    globals.closeKeyboard = true;
                                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
                                    widget.state.rideStartSocket!.sendTripStarted();
                                  }, true);
                                }
                              },
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom,)
                    ],
                  ),
                ),
              ),
            ),
        );
          else
            return const SizedBox.shrink();
      }
    );
  }

}