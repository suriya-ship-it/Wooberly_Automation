import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/views/map_main_screen.dart';


import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';

class MapBasedViews {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  MapBasedViews({required this.homeViewState});

  getPrivacyModeView(BuildContext context) {
    return GetBuilder(
      init: MapMainController(),
        id: controller.rxShowToolTip.id,
        builder: (val) {
          return Opacity(
              opacity: (controller.rxShowToolTip.value == true)
                  ? 1.0
                  : 0.0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.SHADOW_COLOR,
                          blurRadius: 6,
                          offset: Offset(3, 3))
                    ],
                  ),
                  margin: const EdgeInsetsDirectional.only(top: 70.0),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 7, vertical: 1),
                    child: Text(privacy_mode.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_14,
                            fontFamily: AppFont.font)),
                  ),
                ),
              ));
        });
  }

  showGrid(BuildContext context) {
    return GetBuilder(
      init: MapMainController(),
        id: controller.rxMapLoadingController.id,
        builder: (val) {
          return controller.rxMapLoadingController.value == true
              ? Container(
                  height: Get.height,
                  width: Get.width,
                  color: AppColors.GRID_COLOR,
                  child: Image.asset(
                    mapGridPng,
                    height: Get.height,
                    fit: BoxFit.fill,
                  ),
                )
              : const SizedBox.shrink();
        });
  }

  initializeAnimationController(HomeViewState state) {
    state.animController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));

    state.amountOffset =
        Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, -3.0))
            .animate(state.animController!);

    state.rideDetailAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));
    state.rideDetailOffset =
        Tween<Offset>(begin: Offset(0.0, -5.0), end: Offset(0.0, 0.0))
            .animate(state.rideDetailAnimController!);
    state.rideDetailAmountOffset =
        Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, -3.0))
            .animate(state.rideDetailAnimController!);

    state.rideStartAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));

    state.rideStartOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.rideStartAnimController!);
    state.navigationButOffset =
        Tween<Offset>(begin: Offset(2.0, 0.0), end: Offset(0.0, 0.0))
            .animate(state.rideStartAnimController!);
    state.rideCancelledAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));
    state.riderInfoAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 300));
    state.rideCancelledOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.rideCancelledAnimController!);

    state.rideCompleteAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));

    state.riderReviewOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.rideCompleteAnimController!);

    state.riderInfoOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.riderInfoAnimController!);

    state.rideFetchAnimController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 600));

    state.rideFetchOffset =
        Tween<Offset>(begin: Offset(0.0, 4.0), end: Offset(0.0, 0.0))
            .animate(state.rideFetchAnimController!);

    state.tripAmountController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));

    state.tripAmountOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.tripAmountController!);

    state.tripCashPopupController = AnimationController(
        vsync: state, duration: Duration(milliseconds: 200));

    state.tripCashPopupOffset =
        Tween<Offset>(begin: Offset(0.0, 2.0), end: Offset(0.0, 0.0))
            .animate(state.tripCashPopupController!);

    state.rideCompleteAnimController!
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          controller.setStarRatingController(0);
        }
      });
    state.riderInfoAnimController!
      ..addStatusListener((AnimationStatus status) {
       debugPrint("riderInfoAnimController: ${status}");
      });

    state.resizableController = new AnimationController(
      vsync: state,
      duration: new Duration(
        milliseconds: 1000,
      ),
    );
    state.resizableController?.addStatusListener((animationStatus) {
      switch (animationStatus) {
        case AnimationStatus.completed:
          state.resizableController?.reverse();
          break;
        case AnimationStatus.dismissed:
          state.resizableController?.forward();
          break;
        case AnimationStatus.forward:
          break;
        case AnimationStatus.reverse:
          break;
      }
    });
  }
}