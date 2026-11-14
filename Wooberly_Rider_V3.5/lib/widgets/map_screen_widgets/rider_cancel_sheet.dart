import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/primary_button.dart';

import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';

class RiderCancelSheet extends StatefulWidget {
  late final MapMainController viewModel;

  RiderCancelSheet({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<RiderCancelSheet> createState() => RiderCancelSheetState();
}

class RiderCancelSheetState extends State<RiderCancelSheet> {
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.viewModel.rideCancelledOffset!,
      child: SafeArea(
        child: ColoredBox(
          color: Colors.black26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(24.0),
                alignment: Alignment.bottomCenter,
                color: AppColors.PRIMARY_LIGHT_COLOR,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                      SvgPicture.asset(driverCancelledSvg),
                       const SizedBox(
                          width: 20,
                        ),
                        Flexible(
                          child: Text(
                              'ride_cancelled_by_driver'.tr,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontWeight: FontWeight.w600,
                                fontSize: AppDimen.text_size_18,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),

                    PrimaryButton(
                      buttonTitle:'ok_label'.tr,
                      buttonImage: primaryBtnArrow,
                      callback: () {
                        widget.viewModel.clearMap();
                        widget.viewModel.rideCancelledAnimController?.reverse();
                        widget.viewModel.driverInfoAnimController?.reverse();
                        widget.viewModel.connectAnimController?.reverse();
                        widget.viewModel.sosIconController?.reverse();
                        widget.viewModel.destLocAnimController?.forward();
                        widget.viewModel.vehicleCatAnimController?.reverse();
                      },

                    ),
                  ],
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}