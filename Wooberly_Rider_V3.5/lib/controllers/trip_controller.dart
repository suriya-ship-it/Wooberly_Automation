import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';

import '../models/ride_comfort_model.dart';
import '../resources/values/app_images.dart';

class TripController extends BaseController{
  int pastcurrentPage = 1;
  int upcomingcurrentPage = 1;
  List<dynamic>? upcomingTrip;
  List<dynamic>? previousTrip;
  RxBool editRideScreenController = false.obs;
  var onTabSeleted = StreamController<bool>.broadcast();
  Map<String, dynamic>? selectedTrip;
  String? selectedTab;

  int? previousTripCount, upcomingTripCount;

  List<dynamic> selectedComfortRide = [];

@override
  void onInit() {
  selectedTab = 'tab_upcoming'.tr;
  getRideComfortList();
    super.onInit();
  }




  Future<String> getTripHistory() async {
    graphQlObject.graphQLClientWithHeader;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "currentPage": selectedTab == 'tab_upcoming'.tr
          ? upcomingcurrentPage
          : pastcurrentPage,
      "requestType": selectedTab == 'tab_upcoming'.tr
          ? "upcoming"
          : "previous"
    };
    try {
      globals.isLoaderShow = false;

      Map<String, dynamic>? trip_history = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader,
          "GetTripHistory_query",
          variables);

      if (trip_history != null) {
        if (trip_history["getBookings"]["status"] == 200) {
          if (upcomingTrip == null && selectedTab?.compareTo('tab_upcoming'.tr) == 0)
            upcomingTrip = [];
          if (previousTrip == null && selectedTab?.compareTo('tab_past'.tr) == 0)
            previousTrip = [];
          if (selectedTab?.compareTo('tab_upcoming'.tr) == 0) {
            upcomingTripCount = trip_history["getBookings"]["results"]["count"];
            upcomingTrip?.addAll(trip_history["getBookings"]["results"]["bookings"]);
          } else if (selectedTab?.compareTo('tab_past'.tr) == 0) {
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
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> cancelScheduleRide(int bookingId) async {
    graphQlObject.graphQLClientWithHeader;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{"bookingId": bookingId};
    try {
      Map<String, dynamic>? cancelResult = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader,
          "cancelScheduleBookingMutation",
          variables);

      if (cancelResult?["cancelScheduleBooking"]["status"] == 200) {
        return "";
      } else if (cancelResult?["cancelScheduleBooking"]["status"] == 500) {
        return "something went wrong";
      } else {
        return cancelResult?["cancelScheduleBooking"]["errorMessage"];
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  Future<String> updateScheduleRide(int bookingId, int scheduleId,
      int scheduleFrom, DateTime scheduleTo) async {
    int scheduletimestamp =
        (scheduleTo.toUtc().millisecondsSinceEpoch / 1000).round();
    graphQlObject.graphQLClientWithHeader;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "bookingId": bookingId,
      "scheduleId": scheduleId,
      "scheduleFrom": scheduleFrom,
      "scheduleTo": scheduletimestamp
    };
    variables = getDateTimeValue(variables, scheduleTo);

    try {
      Map<String, dynamic>? updateResult = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader,
          "updateScheduleBookingMutation",
          variables);

      if (updateResult?["updateScheduleBooking"]["status"] == 200) {
        return "";
      } else if (updateResult?["updateScheduleBooking"]["status"] == 500) {
        return "something went wrong";
      } else {
        return updateResult?["updateScheduleBooking"]["errorMessage"];
      }
    } on Exception catch (e) {
      return "offline";
    }
  }
}