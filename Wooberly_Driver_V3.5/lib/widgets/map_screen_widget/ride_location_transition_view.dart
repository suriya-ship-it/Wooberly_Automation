import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/views/map_main_screen.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';

class RideLocationTransitionView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideLocationTransitionView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<RideLocationTransitionView> createState() =>
      _RideLocationTransitionViewState();
}

class _RideLocationTransitionViewState extends State<RideLocationTransitionView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    if (widget.homeViewState.rideDetailOffset == null) {
      widget.homeViewState.mapBasedViews
          ?.initializeAnimationController(widget.homeViewState);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.homeViewState.rideDetailOffset!,
      child: Wrap(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(
                top: 80.0, left: 24.0, right: 24.0, bottom: 24.0),
            padding:
                const EdgeInsets.all(13.0),
            decoration: new BoxDecoration(
                color: AppColors.PRIMARY_COLOR_DARK,
                borderRadius: BorderRadius.all(Radius.circular(4.0))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: SvgPicture.asset(
                    TravelledLocatioSvg,
                    colorFilter: ColorFilter.mode(
                        AppColors.WHITE_ICON_COLOR, BlendMode.srcIn),
                  ),
                ),
                const  SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: ValueListenableBuilder<String>(
                          valueListenable: widget.controller.showLocationController,
                          builder: (BuildContext context, String value,child) {
                            return Text(value ,
                                style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_WHITE,
                                  fontSize: AppDimen.text_size_16,
                                ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}