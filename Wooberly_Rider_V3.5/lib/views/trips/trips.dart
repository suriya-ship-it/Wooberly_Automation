import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/globals.dart';
import 'package:app_name/controllers/trip_controller.dart';
import 'package:app_name/views/show_tips.dart';
import 'package:app_name/views/trips/trips_payment_icon.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import 'package:app_name/widgets/schedule_ride.dart';

import '../../app/model_theme.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../widgets/map_screen_widgets/location_data_widget.dart';
import '../../widgets/spin_kit/three_bounce.dart';
import '../../widgets/time_line_widget.dart';
import '../../widgets/trip_detail_view.dart';

class Trips extends StatelessWidget {
  bool isFromConfirmSchedule = false;

  Trips(this.isFromConfirmSchedule);

  @override
  Widget build(BuildContext context) {
    return TripsView(this.isFromConfirmSchedule);
  }
}

class TripsView extends StatefulWidget {
  bool isFromConfirmSchedule = false;

  TripsView(this.isFromConfirmSchedule);

  @override
  _TripsViewState createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView>
    with TickerProviderStateMixin
    implements refreshControllerIF, ScheduleRideControllerIF {
  late TabController controller, emptycontroller;
  final upComingScrollController = new ScrollController();
  final previousScrollController = new ScrollController();
  bool? _isTrackEnable, _isUserReviewed;
  TripController tripController = Get.find();

  Map<String, dynamic>? previoudModel, upcomingTrips;
  bool _isInitial = true;
  late BuildContext scoffoldcontext;
  bool isTrip = false, isLoading = true;
  final GlobalKey<RefreshIndicatorState> _UpcomingrefreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _PastrefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  late AnimationController cardEntranceAnimationController;
  final placeHolderWidget = Container(
    height: 55,
    width: 55,
    padding: const EdgeInsetsDirectional.all(10),
    child: Icon(Icons.directions_car, color: Colors.black12),
  );
  List<Animation>? ticketAnimations;
  DateTime? scheduledDate;
  bool isCancelAlertOpen = false;
  final List<Tab> _tripsTabs = <Tab>[
    Tab(text: 'tab_upcoming'.tr),
    Tab(text: 'tab_past'.tr),
  ];

  LocationDataWidget? _locationDataWidget;
  MapMainController mapMainController = Get.find();

  @override
  void initState() {
    super.initState();
    _locationDataWidget = LocationDataWidget();
    if (tripController.upcomingTrip != null || tripController.previousTrip != null) {
      tripController.upcomingTrip = null;
      tripController.previousTrip = null;
    }
    tripController.upcomingcurrentPage = 1;
    tripController.pastcurrentPage = 1;
    upComingScrollController.addListener(() {
      if (upComingScrollController.position.pixels <= upComingScrollController.position.maxScrollExtent &&
          upComingScrollController.position.atEdge) {
        tripController.selectedTab = 'tab_upcoming'.tr;

        if (tripController.upcomingTripCount! > tripController.upcomingTrip!.length) loadMore();
      }
    });

    previousScrollController.addListener(() {
      if (previousScrollController.position.pixels >= previousScrollController.position.maxScrollExtent &&
          previousScrollController.position.atEdge) {
        tripController.selectedTab = 'tab_past'.tr;

        if (tripController.previousTripCount! > tripController.previousTrip!.length) loadMore();
      }
    });

    Future.delayed(Duration(seconds: 2)).then((_) {
      tripController.selectedTab = 'tab_upcoming'.tr;
      tripController.checkInternet(getTripHistory, false);
    });

    controller = new TabController(vsync: this, length: 2);
    emptycontroller = new TabController(vsync: this, length: 2);
    if (globals.navigateToTripsPast) {
      controller.animateTo(1);
    }
    controller.addListener(_setActiveTabIndex);

    cardEntranceAnimationController = new AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  void _setActiveTabIndex() {
    if (!isLoading) {
      if (controller.index == 1 && (tripController.previousTrip == null)) {
        isLoading = true;
        isTrip = false;
        tripController.update(['tripLoadingController']);
        tripController.selectedTab = 'tab_past'.tr;
        tripController.pastcurrentPage = 1;
        tripController.previousTrip?.clear();
        tripController.checkInternet(getTripHistory, false);
        tripController.upcomingTrip = null;
      } else if (controller.index == 0 && (tripController.upcomingTrip == null)) {
        isLoading = true;
        isTrip = false;
        tripController.update(['tripLoadingController']);
        tripController.selectedTab = 'tab_upcoming'.tr;
        tripController.upcomingcurrentPage = 1;
        tripController.upcomingTrip?.clear();
        tripController.checkInternet(getTripHistory, false);
        tripController.previousTrip = null;
      } else if ((controller.index == 1 || controller.index == 0)) {
        isTrip = true;
        isLoading = false;
        tripController.update(['tripLoadingController']);
      }
    }
  }

  @override
  void dispose() {
    tripController.previousTripCount = null;
    globals.navigateToTripsPast = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: 'drawer_trips'.tr,
        customAppBarFunction: () {
          if (isCancelAlertOpen) {
            isCancelAlertOpen = false;
            Get.back();
          } else {
            if (widget.isFromConfirmSchedule) {
              globals.isShowMapPage = true;
              Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN);
              Future.delayed(Duration(milliseconds: 500)).then((_) {
                mapMainController.mapPaddingController.value =0;
              });
            } else {
              tripController.setBackNavigation();
            }
          }

          return Future.value(false);
        },
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
        body: Stack(children: [
          Align(
            alignment: Alignment.topCenter,
            child: GetBuilder<TripController>(
                id: 'tripLoadingController',
                builder: (_) {
                  return isTrip
                      ? Container(
                          width: 275,
                          height: 60,
                          margin: const EdgeInsetsDirectional.only(top: 20),
                          child: new TabBar(
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            indicatorColor: AppColors.WHITE_TEXT_COLOR,
                            indicatorPadding: const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                            labelStyle: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
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
                                      ? AppColors.PRIMARY_DARK_COLOR
                                      : AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    child: Text(
                                      'tab_upcoming'.tr,
                                      maxLines: 1,
                                      style: TextStyle(
                                          color: controller.index == 0
                                              ? AppColors.WHITE_TEXT_COLOR
                                              : AppColors.PRIMARY_DARK_COLOR,
                                          fontSize: AppDimen.text_size_16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.font),
                                    ),
                                  ),
                                ),
                              )),
                              Tab(
                                  child: Container(
                                    padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                decoration: BoxDecoration(
                                  color: controller.index == 1
                                      ? AppColors.PRIMARY_DARK_COLOR
                                      : AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    child: Text(
                                      'tab_past'.tr,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: controller.index == 1
                                            ? AppColors.WHITE_TEXT_COLOR
                                            : AppColors.PRIMARY_DARK_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            onTap: (index) {},
                          ),
                        )
                      : Container(
                          width: 275,
                          height: 40,
                          margin: const EdgeInsetsDirectional.only(top: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: new TabBar(
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            indicatorColor: AppColors.WHITE_TEXT_COLOR,
                            indicatorPadding: const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                            labelStyle: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_14,
                                fontWeight: FontWeight.normal),
                            controller: controller,
                            tabs: [
                              Tab(
                                  child: Container(
                                    padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                decoration: BoxDecoration(
                                  color: controller.index == 0
                                      ? AppColors.PRIMARY_DARK_COLOR
                                      : AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    child: Text(
                                      'tab_upcoming'.tr,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: controller.index == 0
                                            ? AppColors.WHITE_TEXT_COLOR
                                            : AppColors.PRIMARY_DARK_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                              Tab(
                                  child: Container(
                                    padding: const EdgeInsetsDirectional.only(start: 10,end: 10),
                                decoration: BoxDecoration(
                                  color: controller.index == 1
                                      ? AppColors.PRIMARY_DARK_COLOR
                                      : AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    child: Text(
                                      'tab_past'.tr,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: controller.index == 1
                                            ? AppColors.WHITE_TEXT_COLOR
                                            : AppColors.PRIMARY_DARK_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            onTap: (index) {},
                          ),
                        );
                }),
          ),
          GetBuilder<TripController>(
              id: 'tripLoadingController',
              builder: (_) {
                return (isTrip)
                    ? Container(
                        margin: const EdgeInsetsDirectional.only(
                          top: 90,
                        ),
                        child: new TabBarView(
                          controller: controller,
                          children: _tripsTabs.map((Tab tab) {
                            return tab.text!.compareTo('tab_upcoming'.tr) == 0
                                ? tripController.upcomingTrip == null ||
                                        tripController.upcomingTrip!.length == 0
                                    ? controller.index == 1
                                        ? tripController.getProgressIndicator()
                                        : showEmptyTrip(1)
                                    : _createListView(context, 1)
                                : tripController.previousTrip == null ||
                                        tripController.previousTrip!.length == 0
                                    ? controller.index == 0
                                        ? tripController.getProgressIndicator()
                                        : showEmptyTrip(2)
                                    : _createListView(context, 2);
                          }).toList(),
                        ),
                      )
                    : tripController.getProgressIndicator();
              }),
          Obx(
            () {
              return tripController.editRideScreenController.value == true
                  ? ScheduleRide("", "", this, scheduledDate!, true, false)
                  : const SizedBox.shrink();
            },
          ),
        ]),
      );
    });
  }

  getTripHistory() {
    tripController.getTripHistory().then((onValue) {
      if (onValue.isNotEmpty) {
        if (onValue == "offline") {
          tripController.snackBarwithAction('offline_text'.tr, getTripHistory);
        } else
          tripController.showInSnackBar(onValue);
      } else {
        if (tripController.selectedTab == 'tab_past'.tr) {
          ticketAnimations = tripController.previousTrip?.map((stop) {
            int index = tripController.previousTrip!.indexOf(stop);
            double start = index * 0.1;
            double duration = 0.6;
            double end = duration + start;
            return new Tween<double>(begin: 800.0, end: 0.0).animate(new CurvedAnimation(
                parent: cardEntranceAnimationController,
                curve: new Interval(start, end, curve: Curves.decelerate)));
          }).toList();

          isTrip = true;
          isLoading = false;
          tripController.update(['tripLoadingController']);
          cardEntranceAnimationController.forward();
        } else {
          isTrip = true;
          isLoading = false;
          tripController.update(['tripLoadingController']);
        }

        if (_isInitial && tripController.selectedTab == 'tab_upcoming'.tr && controller.index != 0) {
          _setActiveTabIndex();
          _isInitial = false;
        }
      }
    });
  }

  Widget _createListView(BuildContext context, int from) {
    if (from == 1) {
      tripController.pastcurrentPage = 1;
    } else if (from == 2) {
      tripController.upcomingcurrentPage = 1;
    }
    return from == 1
        ? Container(
            child: RefreshIndicator(
              key: _UpcomingrefreshIndicatorKey,
              color: AppColors.PRIMARY_DARK_COLOR,
              onRefresh: onRefresh,
              child: ListView.builder(
                  itemCount: tripController.upcomingTrip!.length + 1,
                  physics: const AlwaysScrollableScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  controller: upComingScrollController,
                  itemBuilder: (BuildContext ctxt, int index) {
                    if (index == tripController.upcomingTrip!.length) {
                      return GetBuilder<TripController>(
                          id: 'tripLoadingController',
                          builder: (_) {
                            if (isLoading) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.all(10.0),
                                  child: SpinKitThreeBounce(
                                    color: AppColors.PRIMARY_DARK_COLOR,
                                    size: 22.0,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          });
                    } else {
                      upcomingTrips = tripController.upcomingTrip![index];
                      Widget listitem = _createListItem(context, from);
                      return listitem;
                    }
                  }),
            ),
          )
        : Container(
            child: RefreshIndicator(
              color: AppColors.PRIMARY_DARK_COLOR,
              key: _PastrefreshIndicatorKey,
              onRefresh: onRefresh,
              child: ListView.builder(
                  itemCount: tripController.previousTrip!.length + 1,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  shrinkWrap: false,
                  controller: previousScrollController,
                  itemBuilder: (BuildContext ctxt, int index) {
                    if (index == tripController.previousTrip!.length) {
                      return GetBuilder<TripController>(
                          id: 'tripLoadingController',
                          builder: (_) {
                            if (isLoading) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.all(10.0),
                                  child: SpinKitThreeBounce(
                                    color: AppColors.PRIMARY_DARK_COLOR,
                                    size: 22.0,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          });
                    } else {
                      if (tripController.previousTrip!.length > 0)
                        previoudModel = tripController.previousTrip![index];
                      Widget listitem = _createListItem(context, from);
                      return listitem;
                    }
                  }),
            ),
          );
  }

  Future<Null> onRefresh() async {
    isTrip = false;
    tripController.update(['tripLoadingController']);

    if (tripController.selectedTab == 'tab_upcoming'.tr) {
      tripController.upcomingcurrentPage = 1;
      tripController.upcomingTrip?.clear();
      tripController.checkInternet(getTripHistory, false);
    } else {
      tripController.pastcurrentPage = 1;
      tripController.previousTrip?.clear();
      tripController.checkInternet(getTripHistory, false);
    }
  }

  checkMiniutesDifferent(DateTime currentDate, DateTime scheduledDate) {
    return scheduledDate.difference(currentDate).inMinutes > globals.scheduleRestrictionTime ? true : false;
  }

  Widget _createListItem(BuildContext context, int from) {
    Map<String, dynamic> tripmodel;
    if (from == 1) {
      tripmodel = upcomingTrips!;
    } else {
      tripmodel = previoudModel!;
    }
    if (tripmodel["bookingLocations"] == null || tripmodel["bookingLocations"].isEmpty) {
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

    List<String> dates = tripmodel["startDate"].toString().split("-");
    String date = dates[2] + "-" + dates[1] + "-" + dates[0];

    List<Widget> _listItems = _locationDataWidget!
        .frameDisplayLocationWidgets(reorderDropLast(tripmodel["bookingLocations"]), tripmodel["tripStatus"]);

    dynamic amount;
    _isTrackEnable = tripmodel['tripStatus'] == 'started' ||
        tripmodel['tripStatus'] == 'approved' ||
        tripmodel['tripStatus'] == 'locationReached' ||
        tripmodel['tripStatus'] == 'completed';
    _isUserReviewed = tripmodel['tripStatus'] == 'completed' && tripmodel['isRiderReviewed'] == false;
    bool showCancelEdit = false,showCancel = false;
    if (tripmodel["isSpecialTrip"]) {
      if (tripmodel["isTipGiven"]) {
        amount = tripController.getRate(tripmodel["currency"], tripmodel["tipsTotalFare"]);
      } else {
        amount = tripController.getRate(tripmodel["currency"], tripmodel["specialTripTotalFare"]);
      }
    } else {
      if (tripmodel["isTipGiven"]) {
        amount = tripController.getRate(tripmodel["currency"], tripmodel["tipsTotalFare"]);
      } else {
        amount = tripController.getRate(tripmodel["currency"], tripmodel["riderTotalFare"]);
      }
    }

    if (tripmodel["scheduleBookingDetails"] != null) {
      if (tripmodel["tripStatus"] == "scheduled" &&
          checkMiniutesDifferent(
              DateTime.now(),
              DateTime.parse(
                  getTime(tripmodel["scheduleBookingDetails"]["scheduleFrom"], globals.dateTimeFormat)))) {
        showCancelEdit = true;
      } else {
        if(tripmodel["tripStatus"] == "scheduled"){
          showCancel = true;
        }
        showCancelEdit = false;
      }
    } else {
      showCancelEdit = false;
    }
    debugPrint("showCancelEdittrip: ${showCancelEdit} -- ${showCancel}");
    amount = double.parse(amount).toStringAsFixed(2);
    return new Container(
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10.0,
                spreadRadius: 5.1,
              )
            ]),
        child: Column(
          children: [
            InkWell(
                onTap: () {
                  if (tripmodel['tripStatus'] != 'cancelledByRider' &&
                      tripmodel['tripStatus'] != 'cancelledByDriver' &&
                      tripmodel['tripStatus'] != 'expired') {
                    tripController.selectedTrip = tripmodel;
                    tripController.selectedComfortRide = [];
                    tripController.selectedComfortRide = tripmodel["comfortRide"];
                    tripController.setNavigation(AppRoutes.APP_TRIP_DETAIL);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.only(start: 10.0, end: 10.0, top: 20.0, bottom: 10),
                        child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 2.0),
                                child: new Container(
                                    child: FittedBox(
                                  child: new Row(children: <Widget>[
                                    new Icon(
                                      Icons.access_time,
                                      color: AppColors.PRIMARY_DARK_COLOR,
                                      size: 15,
                                    ),
                                    const SizedBox(
                                      width: 3,
                                    ),
                                    new Text(
                                      tripmodel["bookingType"] == 2
                                          ? (tripmodel["scheduleBookingDetails"] != null
                                              ? getTime(tripmodel["scheduleBookingDetails"]["scheduleFrom"],
                                                  "dd-MM-yyyy")
                                              : "                            ")
                                          : date,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: AppFont.font,
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      "/",
                                      style: TextStyle(
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    new Text(
                                      tripmodel["bookingType"] == 2
                                          ? (tripmodel["scheduleBookingDetails"] != null
                                              ? getTime(tripmodel["scheduleBookingDetails"]["scheduleFrom"],
                                                  scheduleTimeFormat)
                                              : "")
                                          : getTime(tripmodel["startTime"], scheduleTimeFormat),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: AppFont.font,
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ]),
                                )),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.topEnd,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      TripsPaymentIcon(paymentType: tripmodel['paymentType']),
                                      RichText(
                                          text: TextSpan(
                                        style: TextStyle(
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: globals.currencySymbol,
                                          ),
                                          TextSpan(
                                            text: amount.toString(),
                                            style: TextStyle(
                                              fontFamily: AppFont.font,
                                              color: AppColors.BLACK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )),
                                      tripmodel["isTipGiven"]
                                          ? SvgPicture.asset(
                                              tickSvg,
                                              width: 15.0,
                                              height: 15.0,
                                            )
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
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 5.0),
                        child: Timeline(
                          children: _listItems,
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: AppColors.DIVIDER_COLOR,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 10, end: 10, bottom: 10),
                        child:
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                          new Expanded(
                            child: new Row(children: <Widget>[
                              tripmodel["categoryDetails"] != null &&
                                      tripmodel["categoryDetails"]["categoryImage"] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(5.0),
                                      child: CachedNetworkImage(
                                        width: 55.0,
                                        fit: BoxFit.scaleDown,
                                        imageUrl: globals.UPLOAD_URL +
                                            "/images/category/" +
                                            tripmodel["categoryDetails"]["categoryImage"],
                                        placeholder: (context, url) => placeHolderWidget,
                                      ),
                                    )
                                  : placeHolderWidget,
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  tripmodel["categoryDetails"] != null
                                      ? tripmodel["categoryDetails"]["categoryName"]
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
                                color: globals.statusConfig[tripmodel["tripStatus"]]?.color,
                              ),
                              margin: const EdgeInsetsDirectional.only(start: 4),
                              padding: const EdgeInsetsDirectional.only(
                                  start: 10.0, end: 10.0, top: 2.0, bottom: 5.0),
                              child: Text(
                                getStatus(tripmodel),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: AppDimen.text_size_12,
                                    fontWeight: FontWeight.w500,

                                    color: AppColors.WHITE_TEXT_COLOR),
                                maxLines: 2,
                              ),
                            ),

                        ]),
                      )
                    ]),
                  ],
                )),
            Visibility(
              visible: _isTrackEnable != null ? false : true,
              child: Divider(
                color: AppColors.DIVIDER_COLOR,
                thickness: 1,
              ),
            ),
            Visibility(
                visible: _isTrackEnable != null ? true : false,
                child: showCancel ?
                Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        borderRadius: BorderRadius.only(bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10))),
                    child:
                InkWell(
                  onTap: () {
                    _asyncConfirmDialog(tripmodel);
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsetsDirectional.only(
                      top: 15,
                    ),
                    color: AppColors.COMMON_BG_COLOR,
                    child: Text(
                      'cancel_ride'.tr,
                      style: TextStyle(
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.PROMOCODE_LINK_COLOR),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ),
                ):
                showCancelEdit
                    ? showCancelEditOption(tripmodel, context)
                    : Container(
                        height: ((_isTrackEnable != null) && (_isTrackEnable == false) ? 0 : 50),
                        decoration: BoxDecoration(
                            color: AppColors.COMMON_BG_COLOR,
                            borderRadius: BorderRadiusDirectional.only(
                                bottomStart: Radius.circular(10), bottomEnd: Radius.circular(10))),
                        child: Row(
                          children: [
                            Visibility(
                              visible: _isUserReviewed ?? false,
                              child: Expanded(
                                child: InkWell(
                                    onTap: () {
                                      mapMainController.isFromtrips = true;
                                      mapMainController.driverId = tripmodel["driverDetails"]["userId"];
                                      mapMainController.bookingId = tripmodel["id"];
                                      if (tripmodel["driverDetails"]["picture"] != null) {
                                        mapMainController.driverPhoto = globals.UPLOAD_URL +
                                            "/images/avatar/" +
                                            tripmodel["driverDetails"]["picture"];
                                      } else {
                                        mapMainController.driverPhoto = "";
                                      }
                                      mapMainController.refreshControl = this;

                                      tripController.setNavigation(AppRoutes.APP_SHOW_REVIEW);
                                    },
                                    child: Center(
                                      child: Text(
                                        'Rate_your_trip'.tr,
                                        style: TextStyle(
                                            fontFamily: AppFont.font,
                                            fontSize: AppDimen.text_size_14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.PROMOCODE_LINK_COLOR),
                                        maxLines: 1,
                                      ),
                                    )),
                              ),
                            ),
                            Visibility(
                                visible: _isUserReviewed ?? false,
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
                                        Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN);
                                        if (isDrawerOpen) tripController.setBackNavigation();
                                      }
                                    } else {
                                      if (tripmodel['tripStatus'] != 'cancelledByRider' &&
                                          tripmodel['tripStatus'] != 'cancelledByDriver' &&
                                          tripmodel['tripStatus'] != 'expired') {
                                        tripController.selectedTrip = tripmodel;
                                        tripController.selectedComfortRide = [];
                                        tripController.selectedComfortRide = tripmodel["comfortRide"];
                                        tripController.setNavigation(AppRoutes.APP_TRIP_DETAIL);
                                      }
                                    }
                                  },
                                  child: _isTrackEnable == true
                                      ? Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                              color: AppColors.COMMON_BG_COLOR,
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft: const Radius.circular(10),
                                                  bottomRight: const Radius.circular(10))),
                                          child: Center(
                                            child: Text(
                                              controller.index == 0 ? 'track_trip'.tr : 'view_Details'.tr,
                                              style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                  fontSize: AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.PROMOCODE_LINK_COLOR),
                                              maxLines: 1,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink()),
                            ),
                          ],
                        ),
                      )
            ),
          ],
        ));
  }

  getTime(String timestamp, String convertDateFormat) {
    return new DateFormat(convertDateFormat, defaultLanguageCode)
        .format(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
  }

  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute + minToAdd);
  }

  void loadMore() async {
    if (!isLoading) {
      isLoading = true;
      tripController.update(['tripLoadingController']);
      tripController.selectedTab == 'tab_upcoming'.tr
          ? tripController.upcomingcurrentPage++
          : tripController.pastcurrentPage++;
      tripController.checkInternet(getTripHistory, false);
    }
  }

  Widget showEmptyTrip(int trip) {
    return Container(
      padding: const EdgeInsetsDirectional.all(20.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 27.0),
            child: SvgPicture.asset(
              noTripsSvg,
              width: 156.0,
              height: 156.0,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 3.0),
            child: new Text(
              'empty_trip'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.font),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10.0),
            child: new Text(
              'empty_trip_content'.trParams(
                  {'field': trip == 1 ? 'upcoming'.tr.toLowerCase() : 'trip_completed'.tr.toLowerCase()}),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_14,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFont.font),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> reorderDropLast(List<dynamic> locations) {
    final nonDrops = locations.where((loc) => loc['locationType'] != 'drop').toList();
    final drops = locations.where((loc) => loc['locationType'] == 'drop').toList();
    return [...nonDrops, ...drops];
  }

  Widget showCancelEditOption(Map<String, dynamic> tripModel, BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
          color: AppColors.COMMON_BG_COLOR,
          borderRadius: BorderRadius.only(bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 49,
            child: InkWell(
              onTap: () {
                _asyncConfirmDialog(tripModel);
              },
              child: Container(
                height: 50,
                padding: const EdgeInsetsDirectional.only(
                  top: 15,
                ),
                child: Text(
                  'cancel_ride'.tr,
                  style: TextStyle(
                      fontSize: AppDimen.text_size_14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.PROMOCODE_LINK_COLOR),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Container(
            height: 25,
            width: 1,
            color: AppColors.BORDERCOLOR,
          ),
          Expanded(
            flex: 49,
            child: InkWell(
              onTap: () {
                scheduledDate = DateTime.parse(
                    getTime(tripModel["scheduleBookingDetails"]["scheduleFrom"], globals.dateTimeFormat));
                tripController.selectedTrip = tripModel;
                tripController.editRideScreenController(true);
              },
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width / 2,
                padding: const EdgeInsetsDirectional.only(top: 15),
                child: Text(
                  'Edit_Date_and_Time'.tr,
                  style: TextStyle(
                      fontSize: AppDimen.text_size_14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.PROMOCODE_LINK_COLOR),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _asyncConfirmDialog(Map<String, dynamic> tripModel) async {
    isCancelAlertOpen = true;
    return tripController.showConfirmationDialog(
        content: 'Cancel_Schedule_ride'.tr,
        onConfirm: (){
          isCancelAlertOpen = false;
          cancelScheduleRide(tripModel, context);
        },
        onCancel: (){
          isCancelAlertOpen = false;
          Get.back();
        },
        cancelButtonText: 'cancel_label'.tr.toUpperCase(),
        confirmButtonText: 'ok_label'.tr);
  }

  void cancelScheduleRide(Map<String, dynamic> tripModel, BuildContext context) {
    Get.back();
    isTrip = false;
    tripController.update(['tripLoadingController']);
    if (tripModel["scheduleBookingDetails"] != null) {
      tripController.cancelScheduleRide(tripModel["scheduleBookingDetails"]["bookingId"]).then((value) {
        if (value.isNotEmpty) {
          tripController.showInSnackBar(value);
        } else {
          tripController.showInSnackBar('Schedule_ride_canceled'.tr);
        }

        onRefresh();
      });
    }
  }

  @override
  void scheduleRideController(String data, DateTime selectedDateTime) {
    if (data == "cancel screen") {
      tripController.editRideScreenController(false);
    } else if (data == "confirm") {
      tripController.editRideScreenController(false);

      isTrip = false;
      tripController.update(['tripLoadingController']);
      var selectedToDate = getTimeByAddMin(selectedDateTime, 10);

      tripController
          .updateScheduleRide(
              tripController.selectedTrip?["scheduleBookingDetails"]["bookingId"],
              tripController.selectedTrip?["scheduleBookingDetails"]["id"],
              (selectedDateTime.toUtc().millisecondsSinceEpoch / 1000).round(),
              selectedToDate)
          .then((value) {
        if (value.isNotEmpty) {
          tripController.showInSnackBar(value);
        } else {
          tripController.showInSnackBar('Schedule_ride_updated'.tr);
        }
        onRefresh();
      });
    }
  }

  @override
  void refreshController() {
    onRefresh();
  }

  String getStatus(tripmodel) {
    debugPrint("transkey: ${globals.statusConfig[tripmodel["tripStatus"]]?.translationKey.tr}");
    return globals.statusConfig[tripmodel["tripStatus"]]?.translationKey.tr ?? 'abc';
  }
}