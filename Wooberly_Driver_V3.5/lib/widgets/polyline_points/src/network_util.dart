import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;

import '../../../app/app.dart';
import '../../../resources/values/app_dimen.dart';
import '../../../utils/globals.dart' as globals;

class NetworkUtil {
  Future< Map<int, List<LatLng>>> getRouteBetweenCoordinates({
    required List<LatLng> wayPoints,required LatLng originLocation,required LatLng destinationLocation, required String googleMapKey  }) async{
    var locations = [];
    Map<String, String>? header;
    String secureKey = await App().getSecurityKey();
    var body;
    var origin = {
      "lat": originLocation.latitude,
      "lng": originLocation.longitude,
    };

    var destination = {
      "lat": destinationLocation.latitude,
      "lng": destinationLocation.longitude,
    };

    locations.insert(0, origin);
    for (var point in wayPoints) {
      var wayPointMap = {
        "lat": point.latitude,
        "lng": point.longitude,
      };
      locations.add(wayPointMap);
    }
    if(locations.length > 1){
      locations.insert(locations.length, destination);
    }
    else{
      locations.insert(1, destination);
    }

    header = {
      "Content-type": "application/json",
      "auth": globals.authToken ?? ""
    };
    body = {
      "locations" : locations,
      "platformSecretKey": secureKey,
      "bookingId" : globals.bookingId == 0 ? null : globals.bookingId
    };
    final response = await http.post(
      Uri.parse(globals.directionsUrl),
      headers: header,
      body: jsonEncode(body),
    );
    Map<int, List<LatLng>>? polylinePoints = {};
    final Map<String, dynamic> jsonRes = jsonDecode(response.body);
    if(jsonRes["response"] != null && jsonRes["response"]["routes"]!=null && jsonRes["response"]["routes"].isNotEmpty) {
      var legsArray = jsonRes["response"]["routes"][0]["legs"];
      for (int b = 0; b < legsArray.length; b++) {
        List<LatLng> poly = [];
        var stepsArray = jsonRes["response"]["routes"][0]["legs"][b]["steps"];
        for (int c = 0; c < stepsArray.length; c++) {
          poly.addAll(decodeEncodedPolyline(
              jsonRes["response"]["routes"][0]["legs"][b]["steps"][c]["polyline"]["encodedPolyline"]));
        }
        polylinePoints.addAll({b: poly});


      }
      return polylinePoints;
    }else if(jsonRes["errorMessage"]['error'] !=null && jsonRes["errorMessage"]['error']['message'] !=null &&  jsonRes["errorMessage"]['error']['message'].toString().isNotEmpty){

      Get.closeCurrentSnackbar();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      Get.showSnackbar(
          GetSnackBar(
            margin: EdgeInsets.symmetric(vertical: Get.height * 0.02, horizontal: Get.width * 0.04),
            animationDuration: Duration(milliseconds: 0),
            borderRadius: 4,
            backgroundColor: Colors.black,
            messageText: Text(jsonRes['errorMessage']['error']['message'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: AppDimen.text_size_14,
              ),
            ),
            duration: const Duration(seconds: 5),
          )
      );

    }
    else if(jsonRes["errorMessage"] != null && jsonRes["errorMessage"].toString().isNotEmpty){
      globals.baseController.showInSnackBar( jsonRes["errorMessage"]);
    }
    return polylinePoints;
    return {0: [LatLng(9.92051, 78.14874), LatLng(9.91989, 78.14872), LatLng(9.91989, 78.14872), LatLng(9.91989, 78.14864), LatLng(9.92061, 78.14864), LatLng(9.92136, 78.14867), LatLng(9.92136, 78.14867), LatLng(9.92136, 78.14823), LatLng(9.92136, 78.14794), LatLng(9.92137, 78.14702), LatLng(9.92134, 78.14649), LatLng(9.92124, 78.14577), LatLng(9.9212, 78.1454), LatLng(9.92109, 78.14469), LatLng(9.92109, 78.14469), LatLng(9.92117, 78.1446), LatLng(9.92122, 78.14446), LatLng(9.92137, 78.14382), LatLng(9.92147, 78.14343), LatLng(9.92153, 78.14314), LatLng(9.92153, 78.14314), LatLng(9.92207, 78.14324), LatLng(9.92207, 78.14324), LatLng(9.9221, 78.14308)]};


  }

  List<LatLng> decodeEncodedPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p =
      new LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }
}