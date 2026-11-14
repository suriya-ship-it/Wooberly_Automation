class VehicleTypeModel {
  GetCategories? getCategories;

  VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    if (json['getCategories'] != null) {
      getCategories = GetCategories.fromJson(json['getCategories']);
    }
  }
}

class GetCategories {
  List<Result>? result;
  int? status;
  String? errorMessage;

  GetCategories.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = [];
      json['result'].forEach((v) {
        result?.add(Result.fromJson(v));
      });
    }
    status = json['status'];
    errorMessage = json['errorMessage'];
  }
}

class Result {
  dynamic id;
  dynamic categoryName;
  dynamic categoryImage;
  dynamic categoryMarkerImage;
  dynamic unitPrice;
  dynamic capacity;
  dynamic waitingFare;
  dynamic basePrice;
  dynamic minutePrice;
  dynamic isActive;
  dynamic currency;
  dynamic markerBitmap;
  dynamic categoryImg;


  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['categoryName'];
    categoryImage = json['categoryImage'];
    categoryMarkerImage = json['categoryMarkerImage'];
    unitPrice = json['unitPrice'];
    waitingFare = json['waitingFare'];
    capacity = json['capacity'];
    basePrice = json['basePrice'];
    minutePrice = json['minutePrice'];
    isActive = json['isActive'];
    currency = json['currency'];
  }
}