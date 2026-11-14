import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/time_line_widget.dart';

import '../app/app.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../models/ride_comfort_model.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import 'flutter_rating_bar.dart';
import 'map_screen_widget/location_data_widget.dart';

Widget TripDetailItemView(
    {Map<String, dynamic>? selectedTrip,
    List<dynamic>? selectedComfortRide,
    JustTheController? tooltipController,
    BuildContext? context,
    bool? isToolTipShown,
    int? ridePaymentType,
    LocationDataWidget? locationDataWidget,
    Function? backPressEvent,
    Function? tipsRemoveClick,
    String? UsedPage}) {
  dynamic discountFare;

  bool isToll = false;
  int paymentType;
  final MapMainController controller = Get.find();
  List<RideComfortModel> rideComfortData = <RideComfortModel>[];
  rideComfortData.add(RideComfortModel(
      1,
      Women_driver.tr,
      womenonlySvg,
      false,
      false,
      false));
  rideComfortData.add(RideComfortModel(
      2,
      Child_seat.tr,
      childSeatSvg,
      false,
      false,
      false));
  rideComfortData.add(RideComfortModel(
      3,
      Wheel_chair.tr,
      wheelChairSvg,
      false,
      false,
      false));
  var rxComfortExpandTileController = ReactiveVariable("rxComfortExpandTileController", false);
  paymentType = ridePaymentType ?? selectedTrip?["paymentType"];
  dynamic totalamount, tipsAmount, tollAmount;
  if (selectedTrip?["isTipGiven"]) {
    tipsAmount = double.parse(controller.getRate(selectedTrip?["currency"], selectedTrip?["tipsAmount"]))
        .toStringAsFixed(2);
    totalamount = controller.getRate(
        selectedTrip?["currency"], selectedTrip?["tipsDriverTotalFare"]);
  } else {
    totalamount = controller.getRate(selectedTrip?["currency"], selectedTrip?["driverTotalFare"]);
  }

  dynamic riderTotal = double.parse(
      controller.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]))
      .toStringAsFixed(2);
  totalamount = double.parse(totalamount).toStringAsFixed(2);

  dynamic totalFare =
  controller.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]);
  totalFare = double.parse(totalFare).toStringAsFixed(2);

  dynamic driverServiceFee = controller
      .getRate(selectedTrip?["currency"], selectedTrip?["driverServiceFee"]);
  dynamic riderServiceFee = double.parse(controller
          .getRate(selectedTrip?["currency"], selectedTrip?["riderServiceFee"]))
      .toStringAsFixed(2);
  driverServiceFee = double.parse(driverServiceFee).toStringAsFixed(2);

  dynamic waitingPrice = double.parse(controller
          .getRate(selectedTrip?["currency"], selectedTrip?["waitingPrice"]))
      .toStringAsFixed(2);
  if (selectedTrip?["tollFee"] == null) {
    isToll = false;
  } else if (selectedTrip!["tollFee"].toString().isEmpty) {
    isToll = false;
  } else if (selectedTrip["tollFee"] > 0) {
    isToll = true;
    tollAmount = double.parse(
        controller.getRate(selectedTrip["currency"], selectedTrip["tollFee"]))
        .toStringAsFixed(2);
  }

  return SingleChildScrollView(
    child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        decoration: BoxDecoration(
            color: AppColors.PRIMARY_COLOR_WHITE,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.only(top: 5),
                    child: selectedTrip?["riderDetails"]["picture"] == null
                        ? SvgPicture.asset(
                            defaultProfileSvg,
                            height: 60,
                            width: 60,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(100.0),
                            child: CachedNetworkImage(
                              height: 60.0,
                              width: 60.0,
                              fit: BoxFit.cover,
                              imageUrl: globals.UPLOAD_URL +
                                  "/images/avatar/" +
                                  selectedTrip?["riderDetails"]["picture"],
                              placeholder: (context, url) => SvgPicture.asset(
                                defaultProfileSvg,
                                height: 70,
                                width: 70,
                              ),
                            ),
                          )),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          selectedTrip?["riderDetails"]["firstName"] +
                              " " +
                              selectedTrip?["riderDetails"]["lastName"],
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontWeight: FontWeight.bold,
                            fontSize: AppDimen.text_size_18,
                          )),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: RatingBarIndicator(
                          rating: selectedTrip?["riderDetails"]["userData"]
                                  ["overallRating"]
                              .toDouble(),
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, index) => SvgPicture.asset(
                            ratingFullSvg,
                            colorFilter: ColorFilter.mode(
                                AppColors.READING_COLOR, BlendMode.srcIn),
                            height: 20,
                          ),
                          itemSize: 10,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                          unratedColor: AppColors.GRAY,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: Row(children: <Widget>[
                selectedTrip?["categoryDetails"] != null &&
                        selectedTrip?["categoryDetails"]["categoryImage"] !=
                            null
                    ? Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: new DecorationImage(
                                fit: BoxFit.contain,
                                image: NetworkImage(globals.UPLOAD_URL +
                                    "/images/category/" +
                                    selectedTrip?["categoryDetails"]
                                        ["categoryImage"]))),
                      )
                    : SizedBox(
                        height: 52,
                        width: 52,
                        child:
                            Icon(Icons.directions_car, color: AppColors.ICON_COLOUR),
                      ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    selectedTrip?["categoryDetails"] != null
                        ? selectedTrip!["categoryDetails"]["categoryName"]
                        : "",
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                ClipRRect(
                  borderRadius: new BorderRadius.circular(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    child: FittedBox(
                      child: Text(
                        getStatusValue(UsedPage == 'trip_summary'
                            ? 'completed'
                            : selectedTrip?["tripStatus"])!,
                        style: TextStyle(
                            fontSize: AppDimen.text_size_12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.WHITE_TEXT_COLOR),
                        maxLines: 1,
                      ),
                    ),
                    color: getStatusColor(UsedPage == 'trip_summary'
                        ? 'completed'
                        : selectedTrip?["tripStatus"]),
                  ),
                ),
              ]),
            ),
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 14),
              child: Timeline(
                children: locationDataWidget!.frameDisplayLocationWidgets(
                    reorderDropLast(selectedTrip?["bookingLocations"]),
                    selectedTrip?["tripStatus"]),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (selectedComfortRide != null && selectedComfortRide.isNotEmpty)
              Divider(
                height: 5,
                color: AppColors.DIVIDER_COLOR,
              ),
            if (selectedComfortRide != null && selectedComfortRide.isNotEmpty)
              Container(
                margin:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 15),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius: BorderRadius.all(const Radius.circular(10))),
                child: Theme(
                  data: Theme.of(context!)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ListTileTheme(
                    dense: true,
                    horizontalTitleGap: 0.0,
                    minLeadingWidth: 0,
                    contentPadding:  const EdgeInsets.all(0),
                    child: ExpansionTile(
                      leading: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 4, end: 6.0),
                          child: SvgPicture.asset(
                            rideComfortSvg,
                            width: 20,
                            height: 13,
                            colorFilter: ColorFilter.mode(
                                AppColors.ICON_COLOUR, BlendMode.srcIn),
                          )),
                      title: Text(
                        ride_comfort.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_16,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.font),
                      ),
                      childrenPadding:
                      const  EdgeInsetsDirectional.only(start: 0, end: 15),
                      initiallyExpanded: false,
                      onExpansionChanged: (value) {
                        controller.change(rxVariable: rxComfortExpandTileController, value: value);
                      },
                      trailing: GetBuilder(
                        init: MapMainController(),
                        id: rxComfortExpandTileController.id,
                        builder: (val) {
                          return SvgPicture.asset(
                            rxComfortExpandTileController.value == true
                                ? primaryUpArrow
                                : primaryDownArrow,
                            colorFilter: ColorFilter.mode(
                                AppColors.ICON_COLOUR, BlendMode.srcIn),
                          );
                        }),
                      children: [
                        for (var item in selectedComfortRide)
                          getSelectedComfortRide(item, rideComfortData),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              alignment: Alignment.center,
              padding:const  EdgeInsets.only(top: 10, bottom: 15),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.BORDERCOLOR),
                  color: globals.isDarkTheme
                      ? AppColors.PRIMARY_COLOR_WHITE
                      : AppColors.TRIP_DETAIL_BG_COLOR),
              child: Column(
                children: <Widget>[
                  const  SizedBox(
                    height: 5,
                  ),
                  Text(
                      selectedTrip?["tripStatus"] == "completed"
                          ? earnings.tr
                          : trip_earnings.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                          text: TextSpan(
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_20,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                            TextSpan(
                              text: globals.currencySymbol,
                            ),
                            TextSpan(
                              text: totalamount.toString(),
                              style: TextStyle(fontFamily: AppFont.font),
                            ),
                          ])),
                      selectedTrip?["isTipGiven"]
                          ? Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: SvgPicture.asset(
                                tickWhiteSvg,
                                width: 20.0,
                                height: 20.0,
                                colorFilter: ColorFilter.mode(
                                    AppColors.VERIFY_COLOR, BlendMode.srcIn),
                              ),
                            )
                          : const SizedBox.shrink()
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Padding(
              padding:const  EdgeInsets.only(left: 15, right: 15,  bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(duration.tr,
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                      )),
                  Text("${getTotalDuration(selectedTrip!)}",
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(distance.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w400)),
                  Text(
                      (selectedTrip?['totalRideDistance'].toString() ?? "") +
                          ' ${selectedTrip?["distanceType"] == "km" ? kms.tr : miles.tr}',
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ),
            const SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    time_requested.tr,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                  Text(
                    getTime(selectedTrip?["startTime"]),
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(right: 15.0, left: 15.0, top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    date.tr,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                  Text(
                    getDate(selectedTrip?["startTime"]),
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    fare.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                  RichText(
                      text: TextSpan(
                          style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w500),
                          children: [
                        TextSpan(
                          text: globals.currencySymbol,
                        ),
                        TextSpan(
                          text: riderTotal.toString(),
                          style: TextStyle(fontFamily: AppFont.font),
                        ),
                      ]))
                ],
              ),
            ),
            paymentType == 1
                ? const SizedBox(
                    height: 10,
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: paymentType == 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          booking_fee_payment.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_16,
                          ),
                        ),
                        RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500),
                                children: [
                              TextSpan(
                                text: globals.currencySymbol,
                              ),
                              TextSpan(
                                text: riderServiceFee.toString(),
                                style: TextStyle(fontFamily: AppFont.font),
                              ),
                            ]))
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            paymentType == 1
                ? const SizedBox(
                    height: 10,
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: paymentType == 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          booking_fee_deduction.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_16,
                          ),
                        ),
                        RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500),
                                children: [
                              TextSpan(
                                text: "-",
                              ),
                              TextSpan(
                                text: globals.currencySymbol,
                              ),
                              TextSpan(
                                text: riderServiceFee.toString(),
                                style: TextStyle(fontFamily: AppFont.font),
                              ),
                            ])),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    service_fee.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                  RichText(
                      text: TextSpan(
                          style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w500),
                          children: [
                        TextSpan(
                          text: "-",
                        ),
                        TextSpan(
                          text: globals.currencySymbol,
                        ),
                        TextSpan(
                          text: driverServiceFee.toString(),
                          style: TextStyle(fontFamily: AppFont.font),
                        ),
                      ])),
                ],
              ),
            ),
            double.parse((selectedTrip?["waitingPrice"]).toString()) != 0.0
                ? const SizedBox(
                    height: 10,
                  )
                : const SizedBox.shrink(),
            double.parse((selectedTrip?["waitingPrice"]).toString()) != 0.0
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Row(
                          children: [
                            Text(
                              Waiting_fare.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            JustTheTooltip(
                                controller: tooltipController,
                                backgroundColor: AppColors.COMMON_BG_COLOR,
                                content: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    Waiting_fare_desc.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    tooltipController?.showTooltip();

                                    Future.delayed(const Duration(seconds: 10),
                                        () {
                                      tooltipController?.hideTooltip();
                                    });
                                  },
                                  child: SvgPicture.asset(
                                    vehicleInfoSvg,
                                    width: 15.0,
                                    height: 15.0,
                                    colorFilter: ColorFilter.mode(
                                        AppColors.ICON_COLOUR, BlendMode.srcIn),
                                  ),
                                ),
                                onDismiss: () {
                                  isToolTipShown = false;
                                },
                                onShow: () {
                                  isToolTipShown = true;
                                }),
                          ],
                        ),
                        RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500),
                                children: [
                              TextSpan(
                                text: globals.currencySymbol,
                              ),
                              TextSpan(
                                text: waitingPrice.toString(),
                                style: TextStyle(fontFamily: AppFont.font),
                              ),
                            ])),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            selectedTrip?["isTipGiven"]
                ? const SizedBox(
                    height: 10,
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: selectedTrip?["isTipGiven"]
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          tip_label.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_16,
                          ),
                        ),
                        RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500),
                                children: [
                              TextSpan(
                                text: globals.currencySymbol,
                              ),
                              TextSpan(
                                text: tipsAmount.toString(),
                                style: TextStyle(fontFamily: AppFont.font),
                              ),
                            ]))
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            isToll
                ? const SizedBox(
                    height: 10,
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: isToll
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          toll_charges.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_16,
                          ),
                        ),
                        RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500),
                                children: [
                              TextSpan(
                                text: "${globals.currencySymbol}",
                              ),
                              TextSpan(
                                text: tollAmount,
                                style: TextStyle(fontFamily: AppFont.font),
                              ),
                            ]))
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(
              height: 10,
            ),
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding:
                  const EdgeInsets.only(right: 15.0, left: 15.0, bottom: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      trip_earnings.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RichText(
                      text: TextSpan(
                          style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w600),
                          children: [
                        TextSpan(
                          text: globals.currencySymbol,
                        ),
                        TextSpan(
                          text: totalamount.toString(),
                          style: TextStyle(fontFamily: AppFont.font),
                        ),
                      ]))
                ],
              ),
            ),
            Divider(
              height: 5,
              color: AppColors.DIVIDER_COLOR,
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
                padding: const EdgeInsets.only(
                    right: 15.0, left: 15.0, bottom: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    paymentType == 1
                        ? Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: SvgPicture.asset(
                              moneySvg,
                              width: 20.0,
                              height: 15.0,
                              colorFilter: ColorFilter.mode(
                                  AppColors.ICON_COLOUR, BlendMode.srcIn),
                              placeholderBuilder: (context) =>
                                  CircularProgressIndicator(),
                            ),
                          )
                        : paymentType == 2
                            ? Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: SvgPicture.asset(
                                  creditCardSvg,
                                  width: 20.0,
                                  height: 15.0,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.ICON_COLOUR, BlendMode.srcIn),
                                ),
                              )
                            : paymentType == 3
                                ? Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: SvgPicture.asset(
                                      walletSvg,
                                      width: 20.0,
                                      height: 15.0,
                                      colorFilter: ColorFilter.mode(
                                          AppColors.ICON_COLOUR,
                                          BlendMode.srcIn),
                                    ),
                                  )
                                : paymentType == 4
                                    ? Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: SvgPicture.asset(
                                          GpaySvg,
                                          width: 30.0,
                                          height: 30.0,
                                        ),
                                      )
                                    :paymentType == 6
                                    ? Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: SvgPicture.asset(
                                          payPalPaymentSVG,
                                          width: 25.0,
                                          height: 25.0,
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: SvgPicture.asset(
                                          payStackSvg,
                                          width: 15.0,
                                          height: 15.0,
                                        ),
                                      ),
                                 const SizedBox(
                                    width: 10.0,
                                  ),
                    Text(
                      // 1. Resolve the label first
                      "${switch (paymentType) {
                        1 => cash.tr,
                        2 => credit_debit.tr,
                        3 => wallet,
                        4 => "Google Pay",
                        6 => "PayPal",
                        _ => "Pay Stack",
                      }} ${trip.tr.toLowerCase()}",

                      // 2. Apply the style once
                      style: TextStyle(
                        fontFamily: AppFont.font,
                        fontSize: AppDimen.text_size_16,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  ],
                ))
          ],
        )),
  );
}

String getStatusValue(String status) => switch (status) {
  "created" => trip_created.tr,
  "approved" => trip_approved.tr,
  "declined" => trip_declined.tr,
  "started" => trip_started.tr,
  "cancelledByRider" => cancelledByRider.tr,
  "cancelledByDriver" => cancelledByDriver.tr,
  "completed" => trip_completed.tr,
  "expired" => trip_expired.tr,
  "locationReached" => trip_reached.tr,
  _ => "Unknown status".tr,
};

Color getStatusColor(String status) => switch (status) {
  "created" => AppColors.TRIP_CREATED,
  "approved" || "completed" || "scheduled" => AppColors.TRIP_GREEN,
  "declined" || "cancelledByRider" || "cancelledByDriver" || "expired" => AppColors.DECLINED_COLOR,
  "started" => AppColors.TRIP_STARTED,
  "locationReached" => AppColors.TRIP_REACHED,
  _ => Colors.grey,
};

List<dynamic> reorderDropLast(List<dynamic> locations) {
  final nonDrops = locations.where((loc) => loc['locationType'] != 'drop').toList();
  final drops = locations.where((loc) => loc['locationType'] == 'drop').toList();
  return [...nonDrops, ...drops];
}
getTime(String timestamp) {
  return new DateFormat(globals.timeFormatHHMMA)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

getTimeWithFormat(String timestamp, String convertDateFormat) {
  return new DateFormat(convertDateFormat, globals.defaultLanguageCode)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

getDate(String timestamp) {
  return new DateFormat(globals.dateFormatMMMDDYYYY, globals.preferredLanguage.value)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

getScheduleDisplayTime(String timestamp, String convertDateFormat) {
  return new DateFormat(convertDateFormat, globals.defaultLanguageCode)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

Widget getSelectedComfortRide(int id, rideComfortData) {
  return Padding(
    padding: EdgeInsetsDirectional.only(top: 7, bottom: 7.0),
    child: Row(
      children: [
        Container(
          height: 16,
          width: 16,
          margin: const EdgeInsetsDirectional.only(top: 3, end: 8.0),
          child: SvgPicture.asset(
            rideComfortData[id - 1].icon,
            height: 16,
            width: 16,
            colorFilter:
                ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
          ),
        ),
        Text(
          rideComfortData[id - 1].title,
          style: TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontWeight: FontWeight.w400,
              fontFamily: AppFont.font),
        ),
      ],
    ),
  );
}

String getTotalDuration(Map<String, dynamic> selectedTrip) {
  final MapMainController controller = Get.find();
  var valueinInt = double.parse("${selectedTrip['totalDuration']}").round();
  var minutes = Duration(minutes: valueinInt).inMinutes;

  if (minutes >= 60) {
    var hour = (minutes / 60).toInt();
    var min = minutes % 60;
    return min > 0
        ? "$hour ${controller.getHoursCheck(hour.toString())} $min ${controller.getMinCheck(min.toString())}"
        : "$hour ${controller.getHoursCheck(hour.toString())}";
  } else {
    return minutes < 1
        ? Few_seconds.tr
        : "$minutes ${controller.getMinCheck(minutes.toString())}";
  }
}