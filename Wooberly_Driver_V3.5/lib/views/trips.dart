import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../controller/trip_controllers/trip_controller.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/map_screen_widget/location_data_widget.dart';
import '../widgets/map_screen_widget/ride_final_amount_transition_view.dart';
import '../widgets/map_screen_widget/rider_review_transition_view.dart';
import '../widgets/spin_kit/three_bounce.dart';
import '../widgets/time_line_widget.dart';
import 'map_main_screen.dart';

class Trips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TripsView();
  }
}

class TripsView extends StatefulWidget {
  @override
  _TripsViewState createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView>
    with TickerProviderStateMixin
     {
  late TabController controller, emptycontroller;
  final upComingScrollController = new ScrollController();
  final previousScrollController = new ScrollController();
  final List<Tab> _tripsTabs = <Tab>[
    Tab(text: tab_upcoming.tr),
    Tab(text: tab_past.tr),
  ];

  StreamSubscription? _tripSubscription;
  final TripController _controller = Get.find();
  final MapMainController _mapmaincontroller = Get.find();
  late Map<String, dynamic> previoudModel, upcomingTrips;
  late BuildContext scoffoldcontext;
  bool isTrip = false,
      isLoading = false,
      _isTrackEnable = false,
      _isUserReviewed = false;

  final GlobalKey<RefreshIndicatorState> _UpcomingrefreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _PastrefreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  late LocationDataWidget _locationDataWidget;

  @override
  void initState() {
    super.initState();
    globals.isTripsPage = true;
    print("===>>>---auth ${globals.authToken}");
    print("===>>>---auth ${globals.userid}");
    _locationDataWidget = LocationDataWidget();
    if (_controller.upcomingTrip != null || _controller.previousTrip != null) {
      _controller.upcomingTrip = null;
      _controller.previousTrip = null;
    }
    _controller.upcomingcurrentPage = 1;
    _controller.pastcurrentPage = 1;
    upComingScrollController.addListener(() {
      if (upComingScrollController.position.pixels <=
          upComingScrollController.position.maxScrollExtent) {
        _controller.selectedTab = tab_upcoming.tr;
        if (_controller.upcomingTripCount! > _controller.upcomingTrip!.length)
          loadMore();
      }
    });

    previousScrollController.addListener(() {
      if (previousScrollController.position.pixels <=
              previousScrollController.position.maxScrollExtent &&
          previousScrollController.position.atEdge) {
        _controller.selectedTab = tab_past.tr;
        if (_controller.previousTripCount! > _controller.previousTrip!.length)
          loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selectedTab = tab_upcoming.tr;
      _controller.checkInternet(getTripHistory, false);
    });

    controller = new TabController(vsync: this, length: 2);
    if(globals.navigateToTripsPast) {
      controller.animateTo(1);
    }
    emptycontroller = new TabController(vsync: this, length: 2);
    controller.addListener(_setActiveTabIndex);
    _controller.tabcontroller = controller;

    _tripSubscription =  globals.isRefreshTripPage.stream.listen((value){
    if(value){
      onRefresh();
    }
  });
  }

  void _setActiveTabIndex() {
    if (!isLoading) {
      if (controller.index == 1 && (_controller.previousTrip == null)) {
        isLoading = true;
          isTrip = false;
          _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
        _controller.selectedTab = tab_past.tr;
        _controller.checkInternet(getTripHistory, false);
      } else if (controller.index == 0 && (_controller.upcomingTrip == null)) {
        isLoading = true;
          isTrip = false;
        _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
        _controller.selectedTab = tab_upcoming.tr;
        _controller.checkInternet(getTripHistory, false);
      } else if ((controller.index == 1 || controller.index == 0)) {
          isTrip = true;
          isLoading = false;
          _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.previousTripCount = null;
    globals.navigateToTripsPast = false;
    if(_tripSubscription !=null)
    _tripSubscription!.cancel();
    globals.isTripsPage = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
          appBarTitle: drawer_trips.tr,
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child:  GetBuilder(
                  init: TripController(),
                    id: _controller.rxIsTripLoadingController.id,
                    builder: (val) {
                    return isTrip
                        ? Container(
                            width: 275,
                            height: 40,
                            margin: const EdgeInsets.only(top: 20),
                            child: new TabBar(
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              indicatorColor: AppColors.WHITE_TEXT_COLOR,
                              indicatorPadding:
                                  const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                              labelStyle: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_14,
                                  fontWeight: FontWeight.normal),
                              controller: controller,
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                              tabs: [
                                Tab(
                                    child: Container(
                                      padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                  decoration: BoxDecoration(
                                    color: controller.index == 0
                                        ? AppColors.PRIMARY_COLOR_DARK
                                        : AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Text(
                                        tab_upcoming.tr,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: controller.index == 0
                                                ? AppColors.PRIMARY_COLOR_WHITE
                                                : AppColors.PRIMARY_COLOR_DARK,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_16),
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                                Tab(
                                    child: Container(
                                      padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                  decoration: BoxDecoration(
                                    color: controller.index == 1
                                        ? AppColors.PRIMARY_COLOR_DARK
                                        : AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Text(
                                        tab_past.tr,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: controller.index == 1
                                                ? AppColors.PRIMARY_COLOR_WHITE
                                                : AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_16),
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: 275,
                            height: 40,
                            margin: const EdgeInsets.only(top: 20),
                            child: new TabBar(
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              indicatorColor: AppColors.WHITE_TEXT_COLOR,
                              indicatorPadding:
                                  const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                              labelStyle: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_14,
                                  fontWeight: FontWeight.normal),
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                              controller: controller,
                              tabs: [
                                Tab(
                                    child: Container(
                                      padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                  decoration: BoxDecoration(
                                    color: controller.index == 0
                                        ? AppColors.PRIMARY_COLOR_DARK
                                        : AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Text(
                                        tab_upcoming.tr,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: controller.index == 0
                                                ? AppColors.PRIMARY_COLOR_WHITE
                                                : AppColors.PRIMARY_COLOR_DARK,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_16),
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                                Tab(
                                    child: Container(
                                      padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                  decoration: BoxDecoration(
                                    color: controller.index == 1
                                        ? AppColors.PRIMARY_COLOR_DARK
                                        : AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Text(
                                        tab_past.tr,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: controller.index == 1
                                                ? AppColors.PRIMARY_COLOR_WHITE
                                                : AppColors.PRIMARY_COLOR_DARK,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_16),
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ],
                            ),
                          );
                  }
                ),
              ),
              GetBuilder(
                  init: TripController(),
                  id: _controller.rxIsTripLoadingController.id,
                  builder: (val) {
                scoffoldcontext = context;
                return (isTrip)
                    ? Container(
                        margin: const EdgeInsets.only(
                          top: 90,
                        ),
                        child: TabBarView(
                          controller: controller,
                          children: _tripsTabs.map((Tab tab) {
                            return tab.text?.compareTo(tab_upcoming.tr) ==
                                    0
                                ? _controller.upcomingTrip == null ||
                                        _controller.upcomingTrip!.length == 0
                                    ? showEmptyTrip(1)
                                    : _createListView(context, 1)
                                : _controller.previousTrip == null ||
                                        _controller.previousTrip!.length == 0
                                    ? showEmptyTrip(2)
                                    : _createListView(context, 2);
                          }).toList(),
                        ),
                      )
                    : _controller.getProgressIndicator(
                        scoffoldcontext, AppColors.PRIMARY_COLOR_DARK.withValues(alpha:0.2));
              }),
            ],
          ));
    });
  }



  getTripHistory() {
    _controller.getTripHistory().then((onValue) {
      if (onValue.isNotEmpty) {
        if (onValue == "offline") {
          _controller.snackBarwithAction(you_are_offline.tr, getTripHistory);
        } else
          _controller.showInSnackBar( onValue);
      } else {
          isTrip = true;
          isLoading = false;
          _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
      }
    });
  }

  Widget _createListView(BuildContext context, int from) {
    return from == 1
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: RefreshIndicator(
              key: _UpcomingrefreshIndicatorKey,
              color: AppColors.PRIMARY_COLOR_DARK,
              onRefresh: onRefresh,
              child: ListView.builder(
                  itemCount: _controller.upcomingTrip!.length + 1,
                  physics: const AlwaysScrollableScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  controller: upComingScrollController,
                  itemBuilder: (BuildContext ctxt, int index) {
                    if (index == _controller.upcomingTrip!.length) {
                      return  GetBuilder(
                          init: TripController(),
                          id: _controller.rxIsTripLoadingController.id,
                          builder: (val) {
                            if (isLoading) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SpinKitThreeBounce(
                                    color: AppColors.PRIMARY_COLOR_DARK,
                                    size: 22.0,
                                  ),
                                ),
                              );
                            } else {
                              return  const SizedBox.shrink();
                            }
                          }
                      );
                    } else {
                      upcomingTrips = _controller.upcomingTrip![index];
                      Widget listitem = _createListItem(context, from);
                      return listitem;
                    }
                  }),
            ),
          )
        : Container(
            padding: const EdgeInsets.only(left: 24.0, right: 24),
            child: RefreshIndicator(
              color: AppColors.PRIMARY_COLOR_DARK,
              key: _PastrefreshIndicatorKey,
              onRefresh: onRefresh,
              child: ListView.builder(
                  itemCount: _controller.previousTrip!.length + 1,
                  physics: const AlwaysScrollableScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  controller: previousScrollController,
                  itemBuilder: (BuildContext ctxt, int index) {
                    if (index == _controller.previousTrip!.length) {
                        return  GetBuilder(
                            init: TripController(),
                            id: _controller.rxIsTripLoadingController.id,
                            builder: (val) {
                              if (isLoading) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SpinKitThreeBounce(
                                      color: AppColors.PRIMARY_COLOR_DARK,
                                      size: 22.0,
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }
                        );
                    } else {
                      if (_controller.previousTrip!.length > 0)
                        previoudModel = _controller.previousTrip![index];
                      Widget listitem = _createListItem(context, from);
                      return listitem;
                    }
                  }),
            ),
          );
  }

  Widget _createListItem(BuildContext context, int from) {
    Map<String, dynamic> tripmodel;
    if (from == 1) {
      tripmodel = upcomingTrips;
    } else {
      tripmodel = previoudModel;
    }

    if (tripmodel["bookingLocations"] == null ||
        tripmodel["bookingLocations"].isEmpty) {
      tripmodel["bookingLocations"].add({
        "locationLat": tripmodel["pickUpLat"],
        "locationLng": tripmodel["pickUpLng"],
        "location": tripmodel["pickUpLocation"],
        "fieldType": "disabled",
        "locationStatus": "completed",
        "locationType": "pickup"
      });
      tripmodel["bookingLocations"].add({
        "locationLat": tripmodel["dropOffLat"],
        "locationLng": tripmodel["dropOffLng"],
        "location": tripmodel["dropOffLocation"],
        "fieldType": "disabled",
        "locationStatus": "completed",
        "locationType": "drop"
      });
    }

    dynamic amount;
    if (tripmodel["isTipGiven"]) {
      amount = _controller.getRate(tripmodel["currency"], tripmodel["tipsDriverTotalFare"]);
    } else {
      amount =
          _controller.getRate(tripmodel["currency"], tripmodel["driverTotalFare"]);
    }

    List<String> dates = tripmodel["startDate"].toString().split("-");
    String date = dates[2] + "-" + dates[1] + "-" + dates[0];

    try {
      amount = double.parse(amount).toStringAsFixed(2);
      amount = amount.toString();
    } on Exception catch (e) {
      amount = tripmodel["currency"].toString() +
          " " +
          tripmodel["driverTotalFare"].toString();
    }

    log("tripmodelbookinglocation: ${tripmodel['bookingLocations']}");

    _isTrackEnable = tripmodel['tripStatus'] == 'started' ||
        tripmodel['tripStatus'] == 'approved' ||
        tripmodel['tripStatus'] == 'locationReached' ||
        tripmodel['tripStatus'] == 'completed';
    _isUserReviewed = tripmodel["paymentType"] == 1? (tripmodel["isCashPaid"] == 1 && tripmodel['tripStatus'] == 'completed' && tripmodel['isDriverReviewed'] == false): (tripmodel['tripStatus'] == 'completed' && tripmodel['isDriverReviewed'] == false );
print("_isUserReviewed: ${_isUserReviewed} -- ${tripmodel['tripStatus']} --- ${tripmodel['isDriverReviewed']} --${tripmodel['id']} --- ${tripmodel["isCashPaid"]}");
    return InkWell(
        onTap: () {
          if (tripmodel['tripStatus'] != 'cancelledByRider' &&
              tripmodel['tripStatus'] != 'cancelledByDriver') {
            _controller.selectedTrip = tripmodel;
            _controller.selectedComfortRide = [];
            _controller.selectedComfortRide = tripmodel["comfortRide"];
            _controller.isCashReceived.value = (tripmodel["paymentType"] == 1 && tripmodel["isCashPaid"] == 0 && tripmodel["tripStatus"] == "completed");
            App().setNavigation(AppRoutes.APP_TRIP_DETAIL);
          }
        },
        child: new Container(
          margin: const EdgeInsetsDirectional.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha:0.1),
                  blurRadius: 10.0,
                  spreadRadius: 5.1,
                )
              ]),
          child: new Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 5, bottom: 5),
                    child: new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FittedBox(
                            child: Container(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                  Icon(
                                    Icons.access_time,
                                    color: AppColors.ICON_COLOUR,
                                    size: 15,
                                  ),
                                  SizedBox(
                                    width: 3,
                                  ),
                                  Text(
                                    tripmodel["bookingType"] == 2
                                        ? (tripmodel[
                                                    "scheduleBookingDetails"] !=
                                                null
                                            ? getTime(
                                                tripmodel[
                                                        "scheduleBookingDetails"]
                                                    ["scheduleFrom"],
                                                "dd-MM-yyyy")
                                            : "                            ")
                                        : date,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "/",
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    tripmodel["bookingType"] == 2
                                        ? (tripmodel[
                                                    "scheduleBookingDetails"] !=
                                                null
                                            ? getTime(
                                                tripmodel[
                                                        "scheduleBookingDetails"]
                                                    ["scheduleFrom"],
                                                "hh:mm a")
                                            : "")
                                        : getTime(
                                            tripmodel["startTime"], "hh:mm a"),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ])),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsetsDirectional.only(
                                        top: 2, end: 5),
                                    child: tripmodel['paymentType'] == 1
                                        ? SvgPicture.asset(
                                            moneySvg,
                                            colorFilter: ColorFilter.mode(
                                                AppColors.PRIMARY_COLOR_DARK,
                                                BlendMode.srcIn),
                                          )
                                        : tripmodel['paymentType'] == 2
                                            ? SvgPicture.asset(
                                                creditCardSvg,
                                                colorFilter: ColorFilter.mode(
                                                    AppColors.PRIMARY_COLOR_DARK,
                                                    BlendMode.srcIn),
                                              )
                                            : tripmodel['paymentType'] == 3
                                                ? SvgPicture.asset(
                                                    walletSvg,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            AppColors.PRIMARY_COLOR_DARK,
                                                            BlendMode.srcIn),
                                                  )
                                                : tripmodel['paymentType'] == 4
                                                    ? SvgPicture.asset(
                                                        GpaySvg,
                                                        width: 30.0,
                                                        height: 30.0,
                                                      )
                                                    :tripmodel['paymentType'] == 6
                                                    ? SvgPicture.asset(
                                                        payPalPaymentSVG,
                                                        width: 22.0,
                                                        height: 22.0,
                                                      )
                                                    : SvgPicture.asset(
                                                        payStackSvg,
                                                        width: 15.0,
                                                        height: 15.0,
                                                      ),
                                  ),
                                  RichText(
                                      text: TextSpan(
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: globals.currencySymbol,
                                      ),
                                      TextSpan(
                                        text: amount.toString(),
                                        style:
                                            TextStyle(fontFamily: AppFont.font),
                                      ),
                                    ],
                                  )),
                                  tripmodel["isTipGiven"]
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 2.0),
                                          child: SvgPicture.asset(
                                            tickSvg,
                                            width: 15.0,
                                            height: 15.0,
                                          ))
                                      : const SizedBox.shrink()
                                ],
                              ),
                            ),
                            flex: 5,
                          ),
                        ]),
                  ),
                  Divider(
                    thickness: 1,
                    color: AppColors.DIVIDER_COLOR,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Timeline(
                      children: _locationDataWidget.frameDisplayLocationWidgets(
                          reorderDropLast(tripmodel["bookingLocations"]),
                          tripmodel["tripStatus"]),
                    ),
                  ),
                  Divider(
                    color: AppColors.DIVIDER_COLOR,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(children: <Widget>[
                      new Expanded(
                        child: new Row(children: <Widget>[
                          tripmodel["categoryDetails"] != null &&
                                  tripmodel["categoryDetails"]
                                          ["categoryImage"] !=
                                      null
                              ? CachedNetworkImage(
                                  height: 55.0,
                                  width: 55.0,
                                  fit: BoxFit.scaleDown,
                                  imageUrl: globals.UPLOAD_URL +
                                      "/images/category/" +
                                      tripmodel["categoryDetails"]
                                          ["categoryImage"],
                                  placeholder: (context, url) =>
                                      SvgPicture.asset(
                                    vehicleTypeSvg,
                                    height: 55.0,
                                    width: 55.0,
                                  ),
                                )
                              : SvgPicture.asset(
                                  vehicleTypeSvg,
                                  height: 55.0,
                                  width: 55.0,
                                ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.2),
                              child: Text(
                                tripmodel["categoryDetails"] != null
                                    ? tripmodel["categoryDetails"]["categoryName"]
                                    : "",
                                maxLines: 3,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_14,

                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      ClipRRect(
                        borderRadius: new BorderRadius.circular(20.0),
                        child: Container(
                          color: _controller.getStatusColor(tripmodel["tripStatus"]),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *0.4
                          ),
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 3.0, bottom: 5.0),
                          child: FittedBox(
                            child: Text(
                              _controller.getStatusValue(tripmodel["tripStatus"])!,
                              style: TextStyle(
                                  fontSize: AppDimen.text_size_12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.WHITE_TEXT_COLOR),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    height:
                        ((_isTrackEnable != null) && (_isTrackEnable == false)
                            ? 0
                            : 50),
                    decoration: BoxDecoration(
                        color: AppColors.TRIPS_BG_Color,
                        borderRadius: BorderRadiusDirectional.only(
                            bottomStart: Radius.circular(10),
                            bottomEnd: Radius.circular(10))),
                    child: Visibility(
                        visible:
                            _isTrackEnable != null ? _isTrackEnable : false,
                        child: _isTrackEnable
                            ? Row(
                                children: [
                                  Visibility(
                                    visible: (tripmodel["isCashPaid"] == 0 && tripmodel["paymentType"] == 1 && tripmodel["tripStatus"] == "completed"),
                                    child: Expanded(
                                      child: InkWell(
                                          onTap: () {
                                              _controller.selectedTrip = tripmodel;
                                              _controller.selectedComfortRide = [];
                                              _controller.selectedComfortRide = tripmodel["comfortRide"];
                                              _controller.isCashReceived.value = (tripmodel["paymentType"] == 1 && tripmodel["isCashPaid"] == 0 && tripmodel["tripStatus"] == "completed");
                                              App().setNavigation(AppRoutes.APP_TRIP_DETAIL);
                                          },
                                          child: Center(
                                            child: Text(
                                               "cash_received".tr,
                                              style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                  fontSize:
                                                      AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppColors.TEXT_LINK_COLOR),
                                              maxLines: 1,
                                            ),
                                          )),
                                    ),
                                  ),

                                  Visibility(
                                    visible: _isUserReviewed != null ? _isUserReviewed : false,
                                    child: Expanded(
                                      child: InkWell(
                                          onTap: () {
                                              _mapmaincontroller.isFromtrips = true;
                                              _mapmaincontroller.riderID = tripmodel["riderDetails"]["userId"];
                                              _mapmaincontroller.bookingID = tripmodel["id"];
                                              _mapmaincontroller.riderPhoto = tripmodel["riderDetails"]["picture"] != null
                                                  ? globals.UPLOAD_URL + "/images/avatar/" + tripmodel["riderDetails"]["picture"] : "";
                                              App().setNavigation(AppRoutes.APP_SHOW_REVIEW);
                                          },
                                          child: Center(
                                            child: Text(
                                              Rate_your_trip.tr,
                                              style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                  fontSize:
                                                      AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppColors.TEXT_LINK_COLOR),
                                              maxLines: 1,
                                            ),
                                          )),
                                    ),
                                  ),
                                  Visibility(
                                      visible: (tripmodel["isCashPaid"] == 0 && tripmodel["paymentType"] == 1 && tripmodel["tripStatus"] == "completed"),
                                      child: Container(
                                        height: 25,
                                        color: AppColors.BORDERCOLOR,
                                        width: 1,
                                      )),
                                  Visibility(
                                      visible: _isUserReviewed != null ? _isUserReviewed : false,
                                      child: Container(
                                        height: 25,
                                        color: AppColors.BORDERCOLOR,
                                        width: 1,
                                      )),
                                  Expanded(
                                    child: InkWell(
                                        onTap: () {
                                          if (controller.index == 0) {
                                            if (tripmodel['tripStatus'] == 'started' ||
                                                tripmodel['tripStatus'] == 'approved' ||
                                                tripmodel['tripStatus'] == 'locationReached') {
                                              Get.until((route) {
                                                return route.settings.name == "/MapMainScreen";
                                              });
                                              if (globals.isDrawerOpen)
                                                App().setBackNavigation();
                                            }
                                          }
                                          else {
                                            if (tripmodel['tripStatus'] != 'cancelledByRider' &&
                                                tripmodel['tripStatus'] != 'cancelledByDriver') {
                                              _controller.selectedTrip = tripmodel;
                                              _controller.selectedComfortRide = [];
                                              _controller.isCashReceived.value = (tripmodel["paymentType"] == 1 && tripmodel["isCashPaid"] == 0 && tripmodel["tripStatus"] == "completed");
                                              _controller.selectedComfortRide = tripmodel["comfortRide"];
                                              App().setNavigation(AppRoutes.APP_TRIP_DETAIL);
                                            }
                                          }
                                        },
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                              color: AppColors.TRIPS_BG_Color,
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(10),
                                                  bottomRight:
                                                      Radius.circular(10))),
                                          child: Center(
                                            child: Text(
                                              controller.index == 0
                                                  ? track_trip.tr
                                                  : view_Details.tr,
                                              style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                  fontSize:
                                                      AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppColors.TEXT_LINK_COLOR),
                                              maxLines: 1,
                                            ),
                                          ),
                                        )),
                                  )
                                ],
                              )
                            : const SizedBox.shrink()),
                  ),
                ]),
              ],
            ),
          ),
        ));
  }

  List<dynamic> reorderDropLast(List<dynamic> locations) {
    final nonDrops = locations.where((loc) => loc['locationType'] != 'drop').toList();
    final drops = locations.where((loc) => loc['locationType'] == 'drop').toList();
    return [...nonDrops, ...drops];
  }

  getTime(String timestamp, String convertDateFormat) {
    return DateFormat(convertDateFormat, App().appPreference.preferredLanguage)
        .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
  }

  void loadMore() async {
    if (!isLoading) {
        isLoading = true;
        _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
      _controller.selectedTab == tab_upcoming.tr
          ? _controller.upcomingcurrentPage++
          : _controller.pastcurrentPage++;

        _controller.checkInternet(getTripHistory, false);
    }
  }

  Future<Null> onRefresh() async {
      isTrip = false;
      if(globals.isRefreshTripPage.value != false)
        globals.isRefreshTripPage.value = false;
      else
        globals.isRefreshTripPage.refresh();
      _controller.change(rxVariable: _controller.rxIsTripLoadingController, value: true);
    await new Future.delayed(const Duration(seconds: 2));
    debugPrint("_controller.selectedTab: ${_controller.selectedTab} --- ${controller.index}");
    if (_controller.selectedTab == tab_upcoming.tr) {
      _controller.upcomingcurrentPage = 1;
      _controller.upcomingTrip?.clear();
      _controller.checkInternet(getTripHistory, false);
    } else {
      _controller.pastcurrentPage = 1;
      _controller.previousTrip?.clear();
      _controller.checkInternet(getTripHistory, false);
    }
  }

  Widget showEmptyTrip(int trip) {
    return Container(
      color: AppColors.COMMON_BG_COLOR,
      padding: const EdgeInsets.all(20.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 27.0),
            child: SvgPicture.asset(
              noTripsSvg,
              width: 156.0,
              height: 156.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text(
              empty_trip.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.font),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              empty_trip_content.trParams({"field":trip == 1 ? upcoming.tr.toLowerCase() : trip_completed.tr.toLowerCase()}),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_14,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFont.font),
            ),
          ),
        ],
      ),
    );
  }

}