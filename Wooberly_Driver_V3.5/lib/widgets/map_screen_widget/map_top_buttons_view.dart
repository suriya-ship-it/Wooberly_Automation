import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/map_screen_widget/total_earning_view_on_map.dart';


import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../views/drawer_view_on_map.dart';
import '../../views/map_main_screen.dart';
import '../../views/view_go_to_booking.dart';

class MapTopButtonsView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;
  final GlobalKey<ScaffoldState> scaffoldKey;

  MapTopButtonsView(
      {Key? key, required this.homeViewState,required this.scaffoldKey})
      : super(key: key);

  @override
  State<MapTopButtonsView> createState() => _MapTopButtonsViewState();
}

class _MapTopButtonsViewState extends State<MapTopButtonsView>
    with TickerProviderStateMixin {
double _imageSize = 35.0;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: widget.controller,
        id: widget.homeViewState.rxChangeTripArrowPosition.id,
        builder: (val) {
        return widget.homeViewState.rxChangeTripArrowPosition.value != true ?
        Stack(
          children: [
            TotalEarningOnMap(
              homeViewState: widget.homeViewState,
            ),
            globals.isRtlLang
                ? Positioned(
                top: 0,
                left: 25,
                child: DrawerOnMap(
                  scaffoldKey: widget.scaffoldKey,
                  imageSize: _imageSize,
                ))
                : Positioned(
                top: 0,
                right: 25,
                child: DrawerOnMap(
                  scaffoldKey: widget.scaffoldKey,
                  imageSize: _imageSize,
                )),
            globals.isRtlLang
                ? Positioned(
                top: 0,
                right: 25,
                child: ViewGoToBooking(
                  scaffoldKey: widget.scaffoldKey,
                  imageSize: _imageSize,
                ))
                : Positioned(
                top: 0,
                left: 25,
                child: ViewGoToBooking(
                  scaffoldKey: widget.scaffoldKey,
                  imageSize: _imageSize,
                )),
          ],
        )
        :const SizedBox.shrink();
      }
    );
  }

}