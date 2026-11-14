import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_images.dart';
import '../../views/map_main_screen.dart';

class ShowLocationIcon extends StatefulWidget {
  final MapMainController _controller = Get.find();
  final HomeViewState homeViewState;

  ShowLocationIcon(
    this.homeViewState,
  );

  @override
  State<ShowLocationIcon> createState() => ShowLocationIconState();
}

class ShowLocationIconState extends State<ShowLocationIcon> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: widget._controller,
        id: widget._controller.rxOnlineStatus.id,
        builder: (val) {
          print('test912 ${widget._controller.rxMapPaddingController.value} ---- ${widget._controller.rxOnlineStatus.value}');
          print('test912 ${widget.homeViewState.bottomSheetHeight}')
          ;
          return Visibility(
            visible: (widget._controller.rxOnlineStatus.value == true && !widget._controller.isDriverAccept()),
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: InkWell(
                  onTap: () {
                    widget._controller.getInitialLocation(8);
                  },
                  child: Card(
                    margin: EdgeInsetsDirectional.only(
                        start: 24,
                        end: 24,
                        bottom: globals.driverStatus != "active"
                            ? 24
                            : widget.homeViewState.bottomSheetHeight != 0
                            ? 110 +24
                            : (widget._controller.rxMapPaddingController
                            .value) + 24),
                    elevation: 20,
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset(
                        fetchlocationSvg,
                        width: 25,
                        height: 25,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  )
              ),
            ),
          );
        });
  }
}