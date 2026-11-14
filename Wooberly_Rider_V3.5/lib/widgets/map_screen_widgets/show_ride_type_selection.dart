import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/views/select_drop_location.dart';

/// Ride type: 0 = Ride Now, 1 = Schedule Ride


class ShowRideTypeSelection extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  ShowRideTypeSelection({Key? key}) : super(key: key);

  @override
  State<ShowRideTypeSelection> createState() => _ShowRideTypeSelectionState();
}

class _ShowRideTypeSelectionState extends State<ShowRideTypeSelection> {


  @override
  void initState() {
    debugPrint("_isScheduelRideSelected: ${widget.mapMainController.isScheduleRideTripSelected.value} ---${widget.mapMainController.isScheduleRide}");
    super.initState();
  }
  void _close() {
    widget.mapMainController.isScheduleRideTripSelected.value = widget.mapMainController.isScheduleRide;
    widget.mapMainController.rideTypeSelectionAnimController?.reverse();
  }

  void _onContinue() {
    widget.mapMainController.scheduleRideScreenController(widget.mapMainController.isScheduleRideTripSelected.value);
    widget.mapMainController.rideTypeSelectionAnimController?.reverse();
    if(!widget.mapMainController.isScheduleRideTripSelected.value) {
      // widget.mapMainController.isScheduleRideIconEnable = widget.mapMainController.isScheduleRideTripSelected.value;
      // widget.mapMainController.isScheduleRide = widget.mapMainController.isScheduleRideTripSelected.value;
      // widget.mapMainController.isFromSchedule = widget.mapMainController.isScheduleRideTripSelected.value;
      // widget.mapMainController.checkInternet(
      //     widget.mapMainController.moveToSelectDropLocation, true);
      debugPrint("selectdrop location:");
      Get.to(SelectDropLocation(false));
      Future.delayed(const Duration(milliseconds: 350), () {
        widget.mapMainController.update(['placeSelectController']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: widget.mapMainController.rideTypeSelectionOffset!,
        child: Container(
          color: Colors.black.withAlpha(100),
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: AppColors.PRIMARY_LIGHT_COLOR,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header Row ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'when_do_you_need_a_ride'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: SvgPicture.asset(
                            closeSvg,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_DARK_COLOR,
                                BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Ride Now Card ──
                  Obx(()=>
                     _RideTypeCard(
                      isSelected: !widget.mapMainController.isScheduleRideTripSelected.value,
                      svgAsset: instantBook,
                      title:  'ride_now'.tr,
                      subtitle: 'request_a_ride_instantly'.tr,
                      onTap: () {
                        widget.mapMainController.isScheduleRideTripSelected.value = false;
                      }
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Schedule Ride Card ──
          Obx(()=>
                  _RideTypeCard(
                    isSelected: widget.mapMainController.isScheduleRideTripSelected.value,
                    svgAsset: scheduleBook,
                    title: 'schedule_ride'.tr,
                    subtitle: 'book_a_ride_for_a_future_time'.tr,
                      onTap: () {
                        widget.mapMainController.isScheduleRideTripSelected.value = true;
                      }
                  ),
                  ),

                  const SizedBox(height: 24),

                  // ── Continue Button ──
                  GestureDetector(
                    onTap: _onContinue,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.PRIMARY_DARK_COLOR,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'continue'.tr.isEmpty ? 'Continue' : 'continue'.tr,
                            style: TextStyle(
                              color: AppColors.WHITE_TEXT_COLOR,
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 2),
                            child: RotatedBox(
                              quarterTurns: globals.isRTLLang ? 2 : 0,
                              child: SvgPicture.asset(
                                primaryBtnArrow,
                                colorFilter: ColorFilter.mode(
                                    AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Internal card widget
// ─────────────────────────────────────────────
class _RideTypeCard extends StatelessWidget {
  final bool isSelected;
  final String svgAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RideTypeCard({
    Key? key,
    required this.isSelected,
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color iconBgColor = isSelected
        ? AppColors.PRIMARY_DARK_COLOR
        : AppColors.COMMON_BG_COLOR;

    final Color iconColor = isSelected
        ? AppColors.WHITE_TEXT_COLOR
        : AppColors.PRIMARY_ICON_COLOR;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.PRIMARY_LIGHT_COLOR,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.PRIMARY_DARK_COLOR
                : AppColors.DIVIDER_COLOR,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgAsset,
                  width: 26,
                  height: 26,
                  colorFilter:
                      ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                      fontSize: AppDimen.text_size_12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.PRIMARY_DARK_COLOR
                      : AppColors.PLACEHOLDER_TEXT_COLOR,
                  width: isSelected ? 6.5 : 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}