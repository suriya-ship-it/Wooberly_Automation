import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/widgets/time_line_widget.dart';

import '../models/ride_comfort_model.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import 'flutter_rating_bar.dart';
import 'map_screen_widgets/location_data_widget.dart';

Widget TripDetailItemView(
    {Map<String, dynamic>? selectedTrip,
    List<dynamic>? selectedComfortRide,
    JustTheController? tooltipController,
    BuildContext? context,
    bool? isToolTipShown,
    int? ridePaymentType,
    LocationDataWidget? locationDataWidget,
    Function? tipsAddClick,
    Function? tipsRemoveClick,
    String? UsedPage}) {
  dynamic riderTotal;
  dynamic totalFare;
  dynamic discountFare;
  dynamic tipAmount, tollAmount;
  bool isToll = false;
  BaseController baseController = Get.find();
  baseController.getRideComfortList();
    RxBool comfortExpandTileController = false.obs;

  if (ridePaymentType == null) ridePaymentType = selectedTrip?["paymentType"];
  if (selectedTrip?["tollFee"] == null) {
    isToll = false;
  } else if (selectedTrip!["tollFee"].toString().isEmpty) {
    isToll = false;
  } else if (selectedTrip["tollFee"] > 0) {
    isToll = true;
    tollAmount = double.parse(baseController.getRate(selectedTrip["currency"], selectedTrip["tollFee"]))
        .toStringAsFixed(2);
  }
  if (selectedTrip?["isSpecialTrip"]) {
    if (selectedTrip?["isTipGiven"]) {
      riderTotal = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["tipsTotalFare"])).toStringAsFixed(2);
      totalFare = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]))
          .toStringAsFixed(2);
      discountFare =
          double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["specialTripPrice"]))
              .toStringAsFixed(2);
      tipAmount = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["tipsAmount"]))
          .toStringAsFixed(2);
    } else {
      riderTotal = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["specialTripTotalFare"])).toStringAsFixed(2);
      totalFare = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]))
          .toStringAsFixed(2);
      discountFare =
          double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["specialTripPrice"]))
              .toStringAsFixed(2);
    }
  } else {
    if (selectedTrip?["isTipGiven"]) {
      riderTotal = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["tipsTotalFare"])).toStringAsFixed(2);
      totalFare = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]))
          .toStringAsFixed(2);
      tipAmount = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["tipsAmount"]))
          .toStringAsFixed(2);
    } else {
      riderTotal = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["riderTotalFare"])).toStringAsFixed(2);
      totalFare = double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["totalFare"]))
          .toStringAsFixed(2);
    }
  }
  dynamic riderServiceFee =
      double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["riderServiceFee"]))
          .toStringAsFixed(2);
  dynamic waitingPrice =
      double.parse(baseController.getRate(selectedTrip?["currency"], selectedTrip?["waitingPrice"]))
          .toStringAsFixed(2);
  String TripStatus = UsedPage == 'trip_summary' ? 'completed' : selectedTrip?["tripStatus"];
  return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
            padding:  EdgeInsetsDirectional.only(
                start: 24.0, end: 24.0, bottom: UsedPage == 'trip_summary' ? 250 : 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: const BorderRadius.only(
                      topRight: const Radius.circular(10),
                      topLeft: const Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: <Widget>[
                          selectedTrip?["driverDetails"] != null
                              ? Container(
                                  padding: const EdgeInsetsDirectional.all(15.0),
                                  margin: const EdgeInsetsDirectional.only(top: 5),
                                  child: selectedTrip?["driverDetails"]["picture"] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(100.0),
                                          child: CachedNetworkImage(
                                            height: 60.0,
                                            width: 60.0,
                                            fit: BoxFit.cover,
                                            imageUrl: globals.UPLOAD_URL +
                                                "/images/avatar/" +
                                                selectedTrip?["driverDetails"]["picture"],
                                            placeholder: (context, url) => SvgPicture.asset(
                                              defaultProfileSvg,
                                              height: 70,
                                              width: 70,
                                            ),
                                          ),
                                        )
                                      : SvgPicture.asset(
                                          defaultProfileSvg,
                                          height: 60,
                                          width: 60,
                                        ))
                              : TripStatus == "scheduled"
                                  ? Expanded(
                                      child: Center(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(top: 20, start: 20, end: 20),
                                              child: Text(
                                                " ${'scheduled_on'.tr}${getScheduleDisplayTime(selectedTrip?["scheduleBookingDetails"] != null ? selectedTrip!["scheduleBookingDetails"]["scheduleFrom"] : selectedTrip?["startTime"], "${globals.scheduleDateFormat}'at' ${globals.scheduleTimeFormat}")}",
                                                style: TextStyle(
                                                    fontFamily: AppFont.font,
                                                    fontSize: AppDimen.text_size_16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.BLACK_TEXT_COLOR),
                                              ),
                                          ),
                                      ),
                          )
                                  : const SizedBox.shrink(),
                          selectedTrip?["driverDetails"] != null
                              ? Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                          selectedTrip?["driverDetails"]["firstName"] +
                                              " " +
                                              selectedTrip?["driverDetails"]["lastName"],
                                          style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_16,
                                          )),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(top: 5),
                                        child: RatingBarIndicator(
                                          rating: selectedTrip?["driverDetails"]["userData"]["overallRating"]
                                              .toDouble(),
                                          direction: Axis.horizontal,
                                          itemCount: 5,
                                          itemBuilder: (context, index) => SvgPicture.asset(
                                            ratingFullSvg,
                                            colorFilter:
                                                ColorFilter.mode(AppColors.RATING_COLOR, BlendMode.srcIn),
                                            height: 20,
                                          ),
                                          itemSize: 10,
                                          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                                          unratedColor: AppColors.LOCATION_ARRIVED_COLOR,
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 10, end: 10, bottom: 10),
                        child: Row(children: <Widget>[
                          new Expanded(
                            child: new Row(children: <Widget>[
                              selectedTrip?["categoryDetails"] != null &&
                                      selectedTrip?["categoryDetails"]["categoryImage"] != null
                                  ? Container(
                                      width: 52.0,
                                      height: 52.0,
                                      decoration: new BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          image: new DecorationImage(
                                              image: NetworkImage(globals.UPLOAD_URL +
                                                  "/images/category/" +
                                                  selectedTrip?["categoryDetails"]["categoryImage"]),
                                          ),
                                      ),
                                    )
                                  : Container(
                                      height: 52,
                                      width: 52,
                                      padding: const EdgeInsetsDirectional.all(10),
                                      child: Icon(Icons.directions_car, color: Colors.black12),
                                    ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  selectedTrip?["categoryDetails"] != null
                                      ? selectedTrip!["categoryDetails"]["categoryName"]
                                      : "",
                                  overflow: TextOverflow.ellipsis, // <-- truncate instead of overflow
                                  maxLines: 3,
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ]),
                          ),

                          Container(
                            constraints: BoxConstraints(
                                maxWidth: 150
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: (UsedPage == 'trip_summary'
                                  ? getStatusColor('completed')
                                  : getStatusColor(TripStatus)),
                            ),
                            margin: const EdgeInsetsDirectional.only(start: 8),
                            padding: const EdgeInsetsDirectional.only(
                                start: 10.0, end: 10.0, top: 2.0, bottom: 5.0),
                            child: Text(
                              getStatusValue(TripStatus),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: AppDimen.text_size_12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.WHITE_TEXT_COLOR),
                              maxLines: 2,
                            ),
                          ),
                        ]),
                      ),
                      selectedTrip?["driverDetails"] != null
                          ? Divider(
                              thickness: 1,
                              color: AppColors.DIVIDER_COLOR,
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 10.0),
                        child: Timeline(
                          children: locationDataWidget!
                              .frameDisplayLocationWidgets(reorderDropLast(selectedTrip?["bookingLocations"]), TripStatus),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (selectedComfortRide != null && selectedComfortRide.isNotEmpty)
                        Divider(
                          thickness: 1,
                          color: AppColors.DIVIDER_COLOR,
                        ),
                      if (selectedComfortRide != null && selectedComfortRide.isNotEmpty)
                        Container(
                          margin: const EdgeInsetsDirectional.symmetric(vertical: 5.0, horizontal: 15),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              borderRadius: BorderRadius.all(Radius.circular(10))),
                          child: Theme(
                            data: Theme.of(context!).copyWith(dividerColor: Colors.transparent),
                            child: ListTileTheme(
                              dense: true,
                              horizontalTitleGap: 0.0,
                              minLeadingWidth: 0,
                              contentPadding: const EdgeInsetsDirectional.all(0),
                              child: ExpansionTile(
                                leading: Padding(
                                    padding: const EdgeInsetsDirectional.only(top: 4, end: 6.0),
                                    child: SvgPicture.asset(
                                      rideComfortSvg,
                                      width: 20,
                                      height: 13,
                                      colorFilter:
                                          ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                    )),
                                title: Text(
                                  'ride_comfort'.tr,
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.font),
                                ),
                                childrenPadding: const EdgeInsetsDirectional.only(start: 0, end: 15),
                                initiallyExpanded: false,
                                onExpansionChanged: (value) {
                                  comfortExpandTileController(value);
                                },
                                trailing: Obx(() {
                                  return SvgPicture.asset(
                                    comfortExpandTileController.value ? primaryUpArrowSvg : primaryDownArrow,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  );
                                }),
                                children: [
                                  for (var item in selectedComfortRide)
                                    getSelectedComfortRide(item, baseController.rideComfortData),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsetsDirectional.only(top: 10, bottom: 15),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.DIVIDER_COLOR),
                      color: globals.isDarkTheme ? AppColors.COMMON_BG_COLOR : AppColors.TRIP_DETAIL_BG_COLOR),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(TripStatus != "completed" ? 'ride_fare'.tr : 'trip_amount'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
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
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                TextSpan(
                                  text: globals.currencySymbol,
                                ),
                                TextSpan(
                                  text: riderTotal.toString(),
                                  style: TextStyle(color: AppColors.BLACK_TEXT_COLOR, fontFamily: AppFont.font),
                                ),
                              ])),
                          selectedTrip?["isTipGiven"] && UsedPage != 'trip_summary'
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(top: 3),
                                  child: SvgPicture.asset(
                                    tickWhiteSvg,
                                    width: 20.0,
                                    height: 20.0,
                                    colorFilter: ColorFilter.mode(AppColors.VERIFY_COLOR, BlendMode.srcIn),
                                  ),
                                )
                              : const SizedBox.shrink()
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: const Radius.circular(10),
                      bottomRight: const Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15, end: 15, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('trip_duration'.tr,
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                )),
                            Text("${getTotalDuration(selectedTrip!, baseController)}",
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15, end: 15, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('trip_distance'.tr,
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w400)),
                            Text(
                                selectedTrip['totalRideDistance'].toString() +
                                    ' ${selectedTrip["distanceType"] == "km" ? 'kms'.tr : 'miles'.tr}',
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Divider(
                        thickness: 1,
                        color: AppColors.DIVIDER_COLOR,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 15.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              'time_requested'.tr,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                            Text(
                              getTime(selectedTrip["createdAt"]),
                              style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              'date'.tr,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                            Text(
                              getDate(selectedTrip["createdAt"]),
                              style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
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
                        thickness: 1,
                        color: AppColors.DIVIDER_COLOR,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              'fare'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                            RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w500),
                                    children: [
                                  TextSpan(
                                    text: globals.currencySymbol,
                                  ),
                                  TextSpan(
                                    text: totalFare.toString(),
                                    style: TextStyle(fontFamily: AppFont.font),
                                  ),
                                ]))
                          ],
                        ),
                      ),
                      selectedTrip["isSpecialTrip"]
                          ? const SizedBox(
                              height: 10,
                            )
                          : const SizedBox.shrink(),
                      selectedTrip["isSpecialTrip"]
                          ? Padding(
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'discount'.tr+'(${selectedTrip['promoCode']['code']})',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                      ),
                                    ),
                                  ),
                                  RichText(
                                      text: TextSpan(
                                          style: TextStyle(
                                              color: AppColors.BLACK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_16,
                                              fontWeight: FontWeight.w500),
                                          children: [
                                        TextSpan(
                                          text: "- ${globals.currencySymbol}",
                                        ),
                                        TextSpan(
                                          text: discountFare.toString(),
                                          style: TextStyle(fontFamily: AppFont.font),
                                        ),
                                      ]))
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              'service_fee'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                            RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
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
                                ])),
                          ],
                        ),
                      ),
                      double.parse((selectedTrip["waitingPrice"]).toString()) != 0.0
                          ? const SizedBox(
                              height: 10,
                            )
                          : const SizedBox.shrink(),
                      double.parse((selectedTrip["waitingPrice"]).toString()) != 0.0
                          ? Padding(
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Row(
                                    children: [
                                      Text(
                                        'Waiting_fare'.tr,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_16,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      JustTheTooltip(
                                          backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                                          controller: tooltipController,
                                          content: Padding(
                                            padding: const EdgeInsetsDirectional.symmetric(
                                                horizontal: 20.0, vertical: 10.0),
                                            child: Text(
                                              'Waiting_fare_desc'.tr,
                                              style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontFamily: AppFont.font,
                                                  fontSize: AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              tooltipController?.showTooltip();
                                              Future.delayed(const Duration(seconds: 10), () {
                                                tooltipController?.hideTooltip();
                                              });
                                            },
                                            child: SvgPicture.asset(
                                              vehicleInfoSvg,
                                              width: 15.0,
                                              height: 15.0,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
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
                                              color: AppColors.BLACK_TEXT_COLOR,
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
                      selectedTrip["isTipGiven"] || (UsedPage == 'trip_summary' && ridePaymentType != 1)
                          ? SizedBox(
                              height: 10,
                            )
                          : const SizedBox.shrink(),
                      selectedTrip["isTipGiven"] || (UsedPage == 'trip_summary' && ridePaymentType != 1)
                          ? Padding(
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(
                                    'tip_label'.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                    ),
                                  ),
                                  selectedTrip["isTipGiven"]
                                      ? RichText(
                                          text: TextSpan(
                                              style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontSize: AppDimen.text_size_16,
                                                  fontWeight: FontWeight.w500),
                                              children: [
                                              TextSpan(
                                                text: "${globals.currencySymbol}",
                                              ),
                                              TextSpan(
                                                text: tipAmount.toString(),
                                                style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                ),
                                              ),
                                            ]))
                                      : InkWell(
                                          onTap: () {
                                            tipsAddClick!();
                                          },
                                          child: Text(
                                            'add_contact'.tr,
                                            style: TextStyle(
                                                fontFamily: AppFont.font,
                                                fontSize: AppDimen.text_size_16,
                                                color: AppColors.PROMOCODE_LINK_COLOR),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        )
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      isToll
                          ? const SizedBox(
                              height: 10,
                            )
                          : const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0, vertical: 5),
                        child: isToll
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(
                                    'toll_charges'.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                    ),
                                  ),
                                  RichText(
                                      text: TextSpan(
                                          style: TextStyle(
                                              color: AppColors.BLACK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_16,
                                              fontWeight: FontWeight.w500),
                                          children: [
                                        TextSpan(
                                          text: "${globals.currencySymbol}",
                                        ),
                                        TextSpan(
                                          text: tollAmount,
                                          style: TextStyle(
                                            fontFamily: AppFont.font,
                                          ),
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
                        thickness: 1,
                        color: AppColors.DIVIDER_COLOR,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, bottom: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              'total_bill'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      if (UsedPage != 'trip_summary')
                        Divider(
                          thickness: 1,
                          color: AppColors.DIVIDER_COLOR,
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (UsedPage != 'trip_summary')
                        Container(
                            padding: const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, bottom: 15.0),
                            child: _getPaymentDetails(selectedTrip['paymentType'])
                        ),
                    ],
                  ),
                ),
                if (selectedTrip["isTipGiven"] && UsedPage == 'trip_summary')
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.COMMON_BG_COLOR,
                    ),
                  ),
                if (selectedTrip["isTipGiven"] && UsedPage == 'trip_summary')
                  Container(
                    height: 62,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                    decoration: BoxDecoration(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      children: <Widget>[
                        SvgPicture.asset(
                          tickWhiteSvg,
                          width: 20.0,
                          height: 20.0,
                          colorFilter: ColorFilter.mode(AppColors.VERIFY_COLOR, BlendMode.srcIn),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'tips_added'.tr,
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            tipsRemoveClick!();
                          },
                          child: Text(
                            'remove'.tr,
                            style: TextStyle(
                                fontSize: AppDimen.text_size_16, color: AppColors.PROMOCODE_LINK_COLOR),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            )),
      ));
}

List<dynamic> reorderDropLast(List<dynamic> locations) {
  final nonDrops = locations.where((loc) => loc['locationType'] != 'drop').toList();
  final drops = locations.where((loc) => loc['locationType'] == 'drop').toList();
  return [...nonDrops, ...drops];
}

Widget _getPaymentDetails(int type) {
  final String tripSuffix = 'trip'.tr.toLowerCase();

  // Data Map for quick O(1) lookup
  final paymentData = {
    1: {'icon': moneySvg, 'text': "${'cash'.tr} $tripSuffix", 'size': 20.0},
    2: {'icon': creditCardSvg, 'text': "${'credit_debit'.tr} $tripSuffix", 'size': 20.0},
    3: {'icon': walletSvg, 'text': "${'wallet'.tr} $tripSuffix", 'size': 20.0},
    4: {'icon': googlePaySvg, 'text': "Google Pay $tripSuffix", 'size': 30.0},
    6: {'icon': paypalPaymentSvg, 'text': "PayPal $tripSuffix", 'size': 25.0},
  };

  final data = paymentData[type] ?? {'icon': payStackSvg, 'text': "PayStack $tripSuffix", 'size': 18.0};

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SvgPicture.asset(
          data['icon'] as String,
          width: data['size'] as double,
          height: 20.0,
          colorFilter: ( data['icon'] ==paypalPaymentSvg || data['icon'] ==googlePaySvg|| data['icon'] ==payStackSvg) ? null :
          ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn) ,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        data['text'] as String,
        style: TextStyle(
          fontFamily: AppFont.font,
          fontSize: AppDimen.text_size_16,
          color: AppColors.BLACK_TEXT_COLOR,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ],
  );
}

String getStatusValue(String status) => globals.statusConfig[status]?.translationKey.tr ?? '';

Color getStatusColor(String status) => globals.statusConfig[status]?.color ?? Colors.transparent;

getTime(String timestamp) {
  return new DateFormat(globals.scheduleTimeFormat)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

getDate(String timestamp) {
  return new DateFormat("MMM d, yyyy", globals.preferredLanguage)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

getScheduleDisplayTime(String timestamp, String convertDateFormat) {
  return new DateFormat(convertDateFormat, globals.preferredLanguage)
      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
}

Widget getSelectedComfortRide(int id, rideComfortData) {
  if(rideComfortData ==null || rideComfortData.isEmpty){
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: 7.0),
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
            colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
          ),
        ),
        Text(
          rideComfortData[id - 1].title,
          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR, fontWeight: FontWeight.w400, fontFamily: AppFont.font),
        ),
      ],
    ),
  );
}

String getTotalDuration(Map<String, dynamic> selectedTrip, BaseController baseController) {
  var valueinInt = double.parse("${selectedTrip['totalDuration']}").round();
  var minutes = Duration(minutes: valueinInt).inMinutes;

  if (minutes >= 60) {
    var hour = (minutes / 60).toInt();
    var min = minutes % 60;
    return min > 0
        ? "$hour ${baseController.getHoursCheck(hour.toString())} $min ${baseController.getMinCheck(min.toString())}"
        : "$hour ${baseController.getHoursCheck(hour.toString())}";
  } else {
    return minutes < 1 ? 'Few_seconds'.tr : "$minutes ${baseController.getMinCheck("2")}";
  }
}