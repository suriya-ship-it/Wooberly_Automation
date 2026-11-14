import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/map_main_screen.dart';


import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';
import '../primary_button.dart';

class RideCancelledTransitionView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideCancelledTransitionView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<RideCancelledTransitionView> createState() =>
      _RideCancelledTransitionViewState();
}

class _RideCancelledTransitionViewState
    extends State<RideCancelledTransitionView> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.homeViewState.rideCancelledOffset!,
      child: SafeArea(
        child: ColoredBox(
          color: Colors.black26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24.0),
                alignment: Alignment.bottomCenter,
                color: AppColors.PRIMARY_COLOR_WHITE,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SvgPicture.asset(riderCancelledSvg),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Text(
                              ride_cancelled_by_rider.tr,
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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
                      buttonTitle: toBeginningOfSentenceCase(
                          okay.tr.toLowerCase()),
                      buttonImage: primaryBtnArrow,
                      callback: () {
                        widget.homeViewState.rideCancelledAnimController
                            ?.reverse();
                        widget.controller.clearMap();
                        widget.homeViewState.rideStartAnimController?.reverse();
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