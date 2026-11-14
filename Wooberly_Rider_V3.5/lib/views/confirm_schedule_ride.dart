import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/trips/trips.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import 'booking_instructions.dart';
import 'payment_type.dart';

class ConfirmScheduleRide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConfirmScheduleRideState();
  }
}

class ConfirmScheduleRideState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ConfirmScheduleRideView();
}

class ConfirmScheduleRideView extends State<ConfirmScheduleRideState> implements BookingInstructionIF {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  MapMainController mapMainController = Get.find();
  late BuildContext scoffoldContext;
  RxBool scheduleConfirmLoadingController = false.obs;
  bool isBookingInstructionOpen = false;
  bool isLoader = false;

  @override
  void initState() {
    mapMainController.bookingInstructionIF = this;
    ever(mapMainController.scheduleRideBookingInstruction, (event) {
      isBookingInstructionOpen = event;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        return  PopScope(
              canPop: false,
              child: Stack(children: [
                PrimaryScaffold(
                    key: _scaffoldKey,
                    customAppBarFunction: () {
                      if (!isLoader) {
                        goBack(context);
                      }
                    },
                    body: Builder(builder: (BuildContext contexts) {
                      scoffoldContext = contexts;
                      return Stack(
                        children: [
                          Padding(
                              padding: const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 130),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 15),
                                      child: Center(child: showCarIcon()),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 15),
                                      child: Center(
                                        child: showUpcomingTitle(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 7),
                                      child: Center(
                                        child: mapMainController.selScheduleFromDateTime != null
                                            ? showTripDateTime(
                                                "${DateFormat(globals.scheduleRideDateFormat).format(mapMainController.selScheduleFromDateTime!)} at ${DateFormat(globals.scheduleRideTimeFormat).format(mapMainController.selScheduleFromDateTime!)} - ${DateFormat(globals.scheduleRideTimeFormat).format(getTimeByAddMin(mapMainController.selScheduleFromDateTime!, 10))}")
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsetsDirectional.only(top: 30),
                                      padding: const EdgeInsetsDirectional.only(top: 10),
                                      decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.all(Radius.circular(10))),
                                      child: Column(
                                        children: [
                                          IntrinsicHeight(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsetsDirectional.only(
                                                        start: 12,
                                                        top: 20,
                                                      ),
                                                      child: VerticalDivider(
                                                        width: 1,
                                                        thickness: 1.5,
                                                        color: AppColors.BLACK_TEXT_COLOR,
                                                      ),
                                                    ),
                                                    Container(
                                                      height: 6,
                                                      width: 6,
                                                      margin: const EdgeInsetsDirectional.only(
                                                        start: 10,
                                                        top: 11,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(5),
                                                        color: AppColors.BLACK_TEXT_COLOR,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                showPickUpDropLocationView(
                                                    'PickUp'.tr,
                                                    mapMainController.locationData.first.location ?? '',
                                                    true),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 8,
                                                    margin: const EdgeInsetsDirectional.only(start: 12,),
                                                    child: VerticalDivider(
                                                      width: 1,
                                                      thickness: 1.5,
                                                      color: AppColors.BLACK_TEXT_COLOR,
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 6,
                                                    width: 6,
                                                    margin: const EdgeInsetsDirectional.only(
                                                      start: 10,
                                                      top: 11,
                                                    ),
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width - 64,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(left: 10, right: 10),
                                                      child: Text(
                                                        'Drop'.tr,
                                                        style: TextStyle(
                                                          fontSize: AppDimen.text_size_16,
                                                          color: AppColors.BLACK_TEXT_COLOR,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        textAlign:  TextAlign.start,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10,),
                                                      child: Text(
                                                        mapMainController
                                                            .locationData.last
                                                            .location ?? '',
                                                        style: TextStyle(
                                                          fontSize: AppDimen.text_size_16,
                                                          color: AppColors.BLACK_TEXT_COLOR,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        textAlign: TextAlign.start,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsetsDirectional.symmetric(vertical: 20),
                                      padding:
                                          EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 12),
                                      decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.all(Radius.circular(10))),
                                      child: showCashSelectionOption(),
                                    ),
                                    (mapMainController.selectedRides != null &&
                                            mapMainController.selectedRides.toList().length > 0)
                                        ? Container(
                                            margin: const EdgeInsetsDirectional.only(bottom: 20),
                                            decoration: BoxDecoration(
                                                color: AppColors.PRIMARY_LIGHT_COLOR,
                                                borderRadius: BorderRadius.all(Radius.circular(10))),
                                            child: Theme(
                                              data: ThemeData().copyWith(dividerColor: Colors.transparent),
                                              child: ExpansionTile(
                                                title: const SizedBox(),
                                                leading: Text(
                                                  'comfort_ride'.tr,
                                                  style: TextStyle(
                                                      fontFamily: AppFont.font,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: AppDimen.text_size_16,
                                                      color: AppColors.BLACK_TEXT_COLOR),
                                                ),
                                                childrenPadding:
                                                    EdgeInsetsDirectional.symmetric(horizontal: 15),
                                                initiallyExpanded: true,
                                                onExpansionChanged: (value) {
                                                  mapMainController.comfortExpandTileController(value);
                                                },
                                                trailing: Obx(() {
                                                  return SvgPicture.asset(
                                                    mapMainController.comfortExpandTileController.value ==
                                                            true
                                                        ? primaryUpArrowSvg
                                                        : primaryDownArrow,
                                                    colorFilter: ColorFilter.mode(
                                                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                  );
                                                }),
                                                children: [
                                                  _getSeperator(
                                                    color: AppColors.GRID_COLOR,
                                                  ),
                                                  ListView.builder(
                                                      physics: NeverScrollableScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount: mapMainController.selectedRides.length,
                                                      itemBuilder: (context, index) {
                                                        return createRideComfortOption(context, index,
                                                            mapMainController.selectedRides[index]);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                          ),
                          Align(alignment: Alignment.bottomCenter, child: showBottomView(context)),
                          Obx(() {
                            if (scheduleConfirmLoadingController.value == true) {
                              return mapMainController.getProgressIndicator();
                            } else {
                              return const SizedBox.shrink();
                            }
                          })
                        ],
                      );
                    })),
                Obx(() {
                  return mapMainController.scheduleRideBookingInstruction.value == true
                      ? BookingInstructionsViewState()
                      : const SizedBox.shrink();
                }),
              ]),

        );
      }
    );
  }

  Widget showCarIcon() {
    return SvgPicture.asset(
      scheduleRideSvg,
      width: 100,
      height: 100,
    );
  }

  Widget showUpcomingTitle() {
    return Text(
      'Upcoming_ride'.tr,
      style: TextStyle(
          fontSize: AppDimen.text_size_22,
          color: AppColors.BLACK_TEXT_COLOR,
          fontFamily: AppFont.font,
          fontWeight: FontWeight.w600),
    );
  }

  Widget showTripDateTime(String selectedDate) {
    return Text(
      selectedDate,
      style: TextStyle(
          fontSize: AppDimen.text_size_16,
          color: AppColors.BLACK_TEXT_COLOR,
          fontFamily: AppFont.font,
          fontWeight: FontWeight.w400),
      textAlign: TextAlign.center,
    );
  }

  Widget showPickUpDropLocationView(String title, String selectedLocation, bool rect) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppDimen.text_size_16,
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 5, end: 10, start: 10, bottom: 10),
            child: Text(
              selectedLocation,
              style: TextStyle(
                fontSize: AppDimen.text_size_16,
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.start,
            ),
          )
        ],
      ),
    );
  }

  Widget showEstimateFareAmount(String title, String currency, String EstimatedAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: SvgPicture.asset(
                updatedVerified,
                height: 22,
                width: 22,
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.font),
            ),
          ],
        ),
        RichText(
            text: TextSpan(
                style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_18,
                  fontWeight: FontWeight.w500,
                ),
                children: [
              TextSpan(
                  text: currency,
                  style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_18,
                    fontWeight: FontWeight.w500,
                  )),
              TextSpan(
                  text: EstimatedAmount,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_18,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.font))
            ])),
      ],
    );
  }

  Widget showBottomView(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 15, bottom: 20),
      decoration: BoxDecoration(color: AppColors.PRIMARY_LIGHT_COLOR, boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10.0,
          spreadRadius: 5.1,
        )
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            child: showEstimateFareAmount('Estimated_Fare'.tr, "${globals.currencySymbol}",
                "${mapMainController.estimatedScheduleAmount}"),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 19),
            child: showDoneButton(context),
          )
        ],
      ),
    );
  }

  Widget showCashSelectionOption() {
    return GetBuilder<MapMainController>(
        id: 'paymentTypeUpdate',
        builder: (_) {
          debugPrint("globals.pref: ${globals.preferredPaymentMethod} --- ${globals.bookingPaymentType}");
          return InkWell(
              onTap: () {
                globals.bookingPaymentType = false;
                Get.to(() => PaymentType())?.then((_){
                  mapMainController.finalAmountController.refresh();
                  mapMainController.update(['paymentTypeUpdate']);
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 5),
                        child: Text(
                          '${'payment_method'.tr}:',
                          style: TextStyle(
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.w600,
                              fontSize: AppDimen.text_size_16,
                              color: AppColors.BLACK_TEXT_COLOR),
                        ),
                      ),
                      getpaymentIcon(),
                    ],
                  ),
                  RotatedBox(
                      quarterTurns: globals.isRTLLang ? 2 : 0,
                      child: SvgPicture.asset(
                        primaryRightArrowSvg,
                        height: 15,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      ))
                ],
              ));
        });
  }

  Widget getpaymentIcon(){
    final paymentOptions = {
      1: (icon: moneySvg, label: 'cash'.tr, size: 20.0),
      2: (icon: creditCardSvg, label: 'credit_debit'.tr, size: 20.0),
      3: (icon: walletSvg, label: 'wallet'.tr, size: 20.0),
      4: (icon: googlePaySvg, label: 'Google Pay', size: 30.0),
      5: (icon: payStackSvg, label: 'PayStack', size: 15.0),
      6: (icon: paypalPaymentSvg, label: 'PayPal', size: 15.0),
    };

    final selected = paymentOptions[globals.preferredPaymentMethod] ?? paymentOptions[1]!;

   return Row(
      children: [
        SvgPicture.asset(
          selected.icon,
          width: selected.size,
          colorFilter: selected.icon != googlePaySvg && selected.icon != payStackSvg && selected.icon != paypalPaymentSvg
              ? ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn)
              : null,
        ),
        const SizedBox(width: 10.0),
        Text(
          selected.label,
          style: TextStyle(
            fontFamily: AppFont.font,
            fontSize: AppDimen.text_size_14,
            color: AppColors.BLACK_TEXT_COLOR,
          ),
        ),
      ],
    );
  }

  Widget showDoneButton(BuildContext context) {
    return PrimaryButton(
      buttonTitle: 'confirm_label'.tr,
      buttonImage: primaryRightArrowSvg,
      callback: () {
        if (mapMainController.selScheduleFromDateTime != null)
          mapMainController.selScheduleToDateTime = getTimeByAddMin(mapMainController.selScheduleFromDateTime!, 10);
        if (globals.cardLastFour == 0 && globals.preferredPaymentMethod == 2) {
          mapMainController.showInSnackBar('please_enter_correct_card_details'.tr);
        } else if (globals.preferredPaymentMethod == 3 &&
            double.parse(mapMainController.estimatedScheduleAmount) > globals.walletBalance.value) {
          mapMainController.showInSnackBar('wallet_not_enough'.tr);
        } else if (globals.precautionNotifications == null) {
          mapMainController.schedulingRideController(true);
          mapMainController.vehicleCatAnimController?.reverse();
          ScheduleRideAPICall();
        } else {
          if (globals.precautionNotifications!["isEnabled"] == true) {
            mapMainController.scheduleRideBookingInstruction(true);
          } else {
            mapMainController.vehicleCatAnimController?.reverse();
            ScheduleRideAPICall();
          }
        }
      },
    );
  }

  ScheduleRideAPICall() {
    scheduleConfirmLoadingController(true);
    mapMainController.createScheduleBooking().then((value) async {
      scheduleConfirmLoadingController(false);

      if (value == "offline") {
        mapMainController.netOffSnackbar(ScheduleRideAPICall(), false);
      } else if (value.isNotEmpty) {
        mapMainController.vehicleCatAnimController?.forward();
        mapMainController.showInSnackBar(value);
      } else {
        globals.setButtonLoading();
        mapMainController.confirmScheduleRideIF?.confirmScheduleRideController();
        changeSchedulingState();
      }
    });
  }

  Future<void> changeSchedulingState() async {
    await Future.delayed(const Duration(seconds: 2), () {
      mapMainController.schedulingRideController(false);
      redirectToTrip();
    });
  }

  Future<void> redirectToTrip() async {
    mapMainController.clearMap();
    await Future.delayed(const Duration(milliseconds: 1500), () {
      globals.isShowMapPage = false;
      globals.userLat = 0.0;
      globals.userLon = 0.0;
      mapMainController.getCurrentLocation().then((value) {
        mapMainController.setCurrentLocation(LatLng(0.0, 0.0));
      });
      globals.setButtonIdle();
      Get.to(Trips(true), duration: Duration(milliseconds: 215), transition: Transition.leftToRight);
    });
  }

  void goBack(BuildContext context) {
    if (isBookingInstructionOpen) {
      mapMainController.scheduleRideBookingInstruction(false);
    } else {
      mapMainController.setBackNavigation();
    }
  }

  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute + minToAdd);
  }



  @override
  void onClickActionsInPrecautionPage(int selectedButtonType) {
    mapMainController.selScheduleToDateTime = getTimeByAddMin(mapMainController.selScheduleFromDateTime!, 10);

    if (mapMainController.isScheduleRide)
      switch (selectedButtonType) {
        case 1:
          {
            mapMainController.scheduleRideBookingInstruction(false);
          }
          break;

        case 2:
          {
            mapMainController.scheduleRideBookingInstruction(false);
            mapMainController.schedulingRideController(true);
            Get.to(SchedulingRide(),
                duration: Duration(milliseconds: 215), transition: Transition.leftToRight);
          }
          break;

        default:
          break;
      }
  }

  Widget createRideComfortOption(BuildContext context, int index, rideComfortData) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Container(
            height: 15,
            width: 15,
            margin: const EdgeInsetsDirectional.only(top: 3, end: 15.0),
            child: SvgPicture.asset(
              mapMainController.selectedRides[index].icon,
              height: 15,
              width: 15,
              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
          ),
          Text(
            mapMainController.selectedRides[index].title,
            style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR, fontWeight: FontWeight.w400, fontFamily: AppFont.font),
          ),
        ],
      ),
    );
  }

  _getSeperator({ double height = 1.5, Color color = Colors.black}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

class ConfirmScheduleRideIF {
  void confirmScheduleRideController() {}
}

class SchedulingRide extends StatelessWidget {
  SchedulingRide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SchedulingRideState();
  }
}

class SchedulingRideState extends StatefulWidget {
  SchedulingRideState({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SchedulingRideView();
}

class SchedulingRideView extends State<SchedulingRideState> {
  late MapMainController mapMainController;
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    mapMainController = MapMainController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScheduleRideAPICall();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {},
      disableAppbar: true,
      body: Obx(() {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsetsDirectional.only(top: 60),
          child: mapMainController.schedulingRideController.value == true
              ? loadData(
              'Scheduling_your_Ride'.tr,
              globals.isDarkTheme
                  ? 'assets/scheduling_loader_dark.json'
                  : 'assets/scheduling_loader.json')
              : loadData('ride_scheduled'.tr, 'assets/schedule_success.json'),
        );
      }),
      onChanged: (map) {
        scoffoldcontext = map["scaffoldcontext"];
      },
    );
  }

  Widget loadData(String title, String lottiePath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: AppDimen.text_size_22,
              color: AppColors.BLACK_TEXT_COLOR,
              fontWeight: FontWeight.w600),
        ),
        Container(
          height: 290,
          width: 290,
          margin: const EdgeInsetsDirectional.only(top: 80),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR, borderRadius: BorderRadius.all(Radius.circular(300))),
          child: Lottie.asset(lottiePath),
        ),
      ],
    );
  }

  ScheduleRideAPICall() {
    globals.isLoaderShow = false;
    mapMainController.createScheduleBooking().then((value) async {
      if (value == "offline") {
        mapMainController.netOffSnackbar(ScheduleRideAPICall(), false);
      } else if (value.isNotEmpty) {
        debugPrint("ScheduleRideAPICall: ${value}");
        Get.back();
        mapMainController.showInSnackBar(value);

     //
      } else {
        mapMainController.confirmScheduleRideIF?.confirmScheduleRideController();
        changeSchedulingState();
      }
    });
  }

  Future<void> changeSchedulingState() async {
    await Future.delayed(const Duration(seconds: 2), () {
      mapMainController.schedulingRideController(false);
      redirectToTrip();
    });
  }

  Future<void> redirectToTrip() async {
    mapMainController.bookingInstructionController(false);
    mapMainController.updatePadding(0);
    mapMainController.clearMap();
    await Future.delayed(const Duration(milliseconds: 1500), () {
      globals.isShowMapPage = false;
      globals.userLat = 0.0;
      globals.userLon = 0.0;
      mapMainController.getCurrentLocation().then((value) {
        mapMainController.setCurrentLocation(LatLng(0.0, 0.0));
      });
      Get.to(Trips(true), duration: Duration(milliseconds: 215), transition: Transition.leftToRight)
          ?.then((value) {
        Future.delayed(Duration(milliseconds: 200), () {
          mapMainController.updatePadding(0);
          mapMainController.update();
        });
      });
    });
  }
}