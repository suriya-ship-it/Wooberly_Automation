import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_lang.dart';
import '../trip_detail_view.dart';
import 'location_data_widget.dart';

class RideFinalAmountTransitionView extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  RideFinalAmountTransitionView(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<RideFinalAmountTransitionView> createState() =>
      _RideFinalAmountTransitionViewState();
}

class _RideFinalAmountTransitionViewState
    extends State<RideFinalAmountTransitionView> with TickerProviderStateMixin {
  @override
  void initState() {
    widget.homeViewState.tripAmountController
      ?..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.forward ||
            status == AnimationStatus.completed) {
          widget.controller.getTripStatus().then((value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.controller.change(rxVariable: widget.controller.rxFinalAmountController, value: 1.0);
            });
            if (value.isEmpty) {
              widget.controller.checkInternet(
                  widget.homeViewState.tripPaymentSocket!.updateTip,
                  true);
              widget.controller.checkInternet(
                  widget.homeViewState.tripPaymentSocket!.changePayment,
                  true);
            }
          });
        }
      });
    widget.controller.checkInternet(
        widget.homeViewState.tripPaymentSocket!.changePaymentDriver,
        true);
    super.initState();
  }

  bool isToolTipShown = false;
  JustTheController tooltipController = JustTheController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
          position: widget.homeViewState.tripAmountOffset!,
          child: ColoredBox(
            color: AppColors.PRIMARY_COLOR_WHITE,
            child: GetBuilder(
                init: MapMainController(),
                id: widget.controller.rxFinalAmountController.id,
                builder: (val) {
                  return Column(
                    children: [
                      showAppbarView(
                        title: trip_details.tr,
                        image: primaryLeftArrow,
                        callback: () {
                          widget.controller.clearMap();
                          widget.homeViewState.closeApp = false;
                          widget.controller.homeViewState = widget.homeViewState;
                          widget.controller.isFromtrips = false;
                          if (widget.controller.rxPaymentType.value == 1)
                            widget.homeViewState.tripCashPopupController?.forward();
                          else {
                            widget.homeViewState.tripAmountController
                                ?.reverse();
                            App().setNavigation(AppRoutes.APP_SHOW_REVIEW);
                          }
                        },
                      ),
                      if (widget.controller.tripStatusResult != null)
                        Expanded(
                          child: GetBuilder(
                              init: MapMainController(),
                              id: widget.controller.rxPaymentType.id,
                              builder: (value){
                            return Container(
                              color: AppColors.COMMON_BG_COLOR,
                              child: TripDetailItemView(
                                selectedComfortRide: widget.controller.tripStatusResult["result"]['comfortRide'],
                                selectedTrip: widget.controller.tripStatusResult["result"],
                                tooltipController: tooltipController,
                                context: context,
                                isToolTipShown: isToolTipShown,
                                locationDataWidget: LocationDataWidget(),
                                ridePaymentType: value.rxPaymentType.value,
                                UsedPage: 'trip_summary',
                              ),
                            );
                          })
                        ),
                      GetBuilder(
                          init: MapMainController(),
                          id: widget.controller.rxPaymentType.id,
                          builder: (value){
                            return Padding(
                              padding: const EdgeInsets.all(25.0),
                              child: PrimaryButton(
                                buttonTitle: next.tr,
                                buttonImage: primaryRightArrow,
                                callback: () {
                                  widget.homeViewState.closeApp = false;
                                  widget.controller.homeViewState = widget.homeViewState;
                                  widget.controller.isFromtrips = false;
                                  if (value.rxPaymentType.value == 1) {
                                    widget.homeViewState.tripCashPopupController?.forward();
                                  }
                                  else{
                                    widget.homeViewState.tripAmountController?.reverse();
                                    App().setNavigation(AppRoutes.APP_SHOW_REVIEW);
                                  }
                                },
                              ),
                            );
                          }
                      ),
                    ],
                  );
                }),
          )),
    );
  }

  Widget showAppbarView({required String image,title,required VoidCallback callback}){
    return Container(
      width: Get.width,
      margin:  EdgeInsetsDirectional.only(top: MediaQuery.of(context).padding.top) ,
      decoration: BoxDecoration(
        color: AppColors.COMMON_BG_COLOR,
      ),
      child: Stack(
        children: [
            Container(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsetsDirectional.only(start: 24, top: 22.0),
              child: InkWell(
                onTap: () {
                  callback();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_COLOR_WHITE, shape: BoxShape.circle),
                  child: SvgPicture.asset(
                    image,
                    matchTextDirection: true,
                    colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ),
          Container(
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsetsDirectional.only(
              top: 22.0,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_18,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}