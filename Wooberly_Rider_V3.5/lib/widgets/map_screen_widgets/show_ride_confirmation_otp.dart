import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import '../../resources/values/app_colors.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
class ShowRideConfirmationOtp extends StatefulWidget {
  final MapMainController viewModel=Get.find();
  late final GlobalKey<ScaffoldState> scaffoldKey;

  ShowRideConfirmationOtp({Key? key,required this.scaffoldKey}) : super(key: key);

  @override
  State<ShowRideConfirmationOtp> createState() => ShowRideConfirmationOtpState();
}

class ShowRideConfirmationOtpState extends State<ShowRideConfirmationOtp> {
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.viewModel.rideConfirmOTPOffset!,
      child: Obx((){
            return widget.viewModel.rideConfirmOTPController.value != 0 ?
              Align(
                alignment:   AlignmentDirectional.topCenter,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(top:30.0, end:24.0,start: 24.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppColors.PRIMARY_DARK_COLOR,
                        borderRadius: const BorderRadius.all(Radius.circular(25),),),
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 10),
                    child: Text(
                      "OTP: ${widget.viewModel.rideConfirmOTPController.value }",
                      style: TextStyle(
                          fontFamily: AppFont.font,
                          fontSize: AppDimen.text_size_18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.PRIMARY_LIGHT_COLOR),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ): const SizedBox.shrink();
          }
      ),
    );
  }
}