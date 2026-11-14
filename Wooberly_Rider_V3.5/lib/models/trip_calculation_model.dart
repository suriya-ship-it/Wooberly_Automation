import 'dart:convert';

class TripCalculationModel {
  final TripCalculation? tripCalculation;


  TripCalculationModel.fromJson(Map<String, dynamic> json)
      : tripCalculation = json['tripCalculation'] != null
      ? TripCalculation.fromJson(json['tripCalculation'])
      : null;

}

class TripCalculation {
  List<Result> result;
  final int status;
  final String errorMessage;


  TripCalculation.fromJson(Map<String, dynamic> json)
      : result = (json['result'] as List<dynamic>)
      .map((v) => Result.fromJson(v))
      .toList(),
        status = json['status'] as int,
        errorMessage = json['errorMessage'] ?? '';

}

class Result {
  final dynamic id;
  final dynamic unitPrice;
  final dynamic minutePrice;
  final dynamic waitingFare;
  final dynamic basePrice;
  final dynamic pricingId;
  final dynamic currency;
  final dynamic categoryName;
  final dynamic riderFeeType;
  final dynamic riderFeeValue;
  final dynamic driverFeeType;
  final dynamic driverFeeValue;
  final dynamic riderServiceFee;
  final dynamic driverServiceFee;
  final dynamic priceForDistance;
  final dynamic totalFare;
  final dynamic calculatedPrice;
  final dynamic convertCurrency;
  final dynamic totalFareForRider;
  final dynamic totalFareForDriver;
  final dynamic isSpecialTrip;
  final dynamic specialTripPrice;
  final dynamic specialTripTotalFare;
  final dynamic durationToReachRider;
  final dynamic distanceToReachRider;


  Result.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        unitPrice = json['unitPrice'],
        minutePrice = json['minutePrice'],
        waitingFare = json['waitingFare'],
        basePrice = json['basePrice'],
        pricingId = json['pricingId'],
        currency = json['currency'],
        categoryName = json['categoryName'],
        riderFeeType = json['riderFeeType'],
        riderFeeValue = json['riderFeeValue'],
        driverFeeType = json['driverFeeType'],
        driverFeeValue = json['driverFeeValue'],
        riderServiceFee = json['riderServiceFee'],
        driverServiceFee = json['driverServiceFee'],
        priceForDistance = json['priceForDistance'],
        totalFare = json['totalFare'],
        calculatedPrice = json['calculatedPrice'],
        convertCurrency = json['convertCurrency'],
        totalFareForRider = json['totalFareForRider'],
        totalFareForDriver = json['totalFareForDriver'],
        isSpecialTrip = json['isSpecialTrip'],
        specialTripPrice = json['specialTripPrice'],
        specialTripTotalFare = json['specialTripTotalFare'],
        durationToReachRider = json["durationToReachRider"],
        distanceToReachRider = json["distanceToReachRider"];
}