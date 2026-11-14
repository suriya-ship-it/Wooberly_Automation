import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/location_info_on_trips_view.dart';

import '../../models/ride_comfort_model.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';

class TripController extends BaseController{
  int pastcurrentPage = 1;
  int upcomingcurrentPage = 1;
  List<dynamic>? upcomingTrip = [];
  List<dynamic>? previousTrip = [];
  var rxIsTripLoadingController = ReactiveVariable("rxIsTripLoadingController", false);
  List<dynamic> selectedComfortRide = [];
  List<RideComfortModel> rideComfortData = <RideComfortModel>[];
  int? previousTripCount, upcomingTripCount;
  RxBool isCashReceived = false.obs;
  RxInt paymentType = 0.obs;
  Map<String, dynamic>? selectedTrip;
  String selectedTab = "";
  TabController? tabcontroller;

  @override
  void onInit() {
   LocationInfoOnTripsView();

    selectedTab = tab_upcoming.tr;
    rideComfortData.clear();
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
    super.onInit();
  }



  Color getStatusColor(String status) {
    switch (status) {
      case 'created':
        return AppColors.TRIP_CREATED;
      case 'approved':
      case 'completed':
      case 'scheduled':
        return AppColors.TRIP_GREEN;
      case 'declined':
      case 'cancelledByRider':
      case 'cancelledByDriver':
      case 'expired':
        return AppColors.DECLINED_COLOR;
      case 'started':
        return AppColors.TRIP_STARTED;
      case 'locationReached':
        return AppColors.TRIP_REACHED;
      default:
        return AppColors.TRIP_CREATED;
    }
  }

  String getStatusValue(String status) {
    switch (status) {
      case 'created':
        return trip_created.tr;
      case 'approved':
        return trip_approved.tr;
      case 'declined':
        return trip_declined.tr;
      case 'started':
        return trip_started.tr;
      case 'cancelledByRider':
        return cancelledByRider.tr;
      case 'cancelledByDriver':
        return cancelledByDriver.tr;
      case 'completed':
        return trip_completed.tr;
      case 'expired':
        return trip_expired.tr;
      case 'locationReached':
        return trip_reached.tr;
      default:
        return '';
    }
  }


  Future<String> getTripHistory() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "currentPage": selectedTab == tab_upcoming.tr
          ? upcomingcurrentPage
          : pastcurrentPage,
      "requestType": selectedTab == tab_upcoming.tr
          ? "upcoming"
          : "previous"
    };
    globals.isLoaderShow = false;

    debugPrint("triphist: ${variables}");
    Map<String, dynamic>? trip_history = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader,
        "GetTripHistory_query",
        variables,
        true,
        FetchPolicy.networkOnly);

    debugPrint("_controller.selectedTab: histr${trip_history}");
    if (trip_history != null) {
      if (trip_history["getBookings"]["status"] == 200) {
        if (upcomingTrip == null &&
            selectedTab.compareTo(tab_upcoming.tr) == 0) upcomingTrip = [];


        if (previousTrip == null && selectedTab.compareTo(tab_past.tr) == 0)
          previousTrip = [];

        if (selectedTab.compareTo(tab_upcoming.tr) == 0) {
          if (upcomingcurrentPage == 1 && tabcontroller?.index ==0) {
            upcomingTrip?.clear();
          }
          upcomingTripCount = trip_history["getBookings"]["results"]["count"];
          upcomingTrip?.addAll(trip_history["getBookings"]["results"]["bookings"]);
        } else if (selectedTab.compareTo(tab_past.tr) == 0) {
          if (pastcurrentPage == 1 && tabcontroller?.index ==1) {
            previousTrip?.clear();
          }
          previousTripCount = trip_history["getBookings"]["results"]["count"];
          previousTrip?.addAll(trip_history["getBookings"]["results"]["bookings"]);
        }
        return "";
      } else {
        return trip_history["TripsHistory"]["errorMessage"];
      }
    } else {
      return "offline";
    }
  }
  Future<String> confirmCashPayment(int bookingID) async {
    try {
      var variables = <String, dynamic>{
        "bookingId": bookingID,
      };
      Map<String, dynamic>? status_result =
      await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader, "confirmCashPayment_mutation",
          variables);
      if (status_result != null) {
        if (status_result["confirmCashPayment"]["status"] == 200) {
          return "";
        } else if (status_result["confirmCashPayment"]["status"] == 400) {
          return status_result["confirmCashPayment"]["errorMessage"];
        } else {
          return "timeout";
        }
      } else {
        return "offline";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      return 'offline';
    }
  }
  void changePaymentDriver(int bookingID) {
    String eventName = "changePaymentDriver-" + (globals.userid).toString();
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          if(data["data"]["data"]["bookingId"] == bookingID) {
            isCashReceived.value = data["data"]["data"]["paymentType"] == 1;
            paymentType.value = data["data"]["data"]["paymentType"];
            if(Get.isBottomSheetOpen?? false){
              Get.back();
            }
          }
        }
      }
    });
  }
}