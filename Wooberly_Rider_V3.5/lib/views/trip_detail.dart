import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/controllers/trip_controller.dart';

import '../app/model_theme.dart';
import '../widgets/map_screen_widgets/location_data_widget.dart';
import '../widgets/primary_scaffold.dart';
import '../widgets/trip_detail_view.dart';

class TripDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TripDetailView();
  }
}

class TripDetailView extends StatefulWidget {
  @override
  _TripDetailViewState createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  BuildContext? scoffoldcontext;
  TripController tripController = Get.find();
  LocationDataWidget? _locationDataWidget;
  final tooltipController = JustTheController();
  bool isToolTipShown = false;

  @override
  void initState() {
    _locationDataWidget = LocationDataWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: 'trip_details'.tr,
        backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
        customAppBarFunction: () {
          if (isToolTipShown) {
            tooltipController.hideTooltip();
          } else {
            tripController.setBackNavigation();
          }
        },
        body: Builder(
          builder: (BuildContext context) {
            scoffoldcontext = context;

            return TripDetailItemView(
              selectedTrip: tripController.selectedTrip!,
              selectedComfortRide: tripController.selectedComfortRide,
              tooltipController: tooltipController,
              isToolTipShown: isToolTipShown,
              context: context,
              locationDataWidget: _locationDataWidget!,
            );
          },
        ),
      );
    });
  }
}