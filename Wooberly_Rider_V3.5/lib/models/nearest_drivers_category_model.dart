class NearestDriversCategory {
  GetNearestDriversCategory? getNearestDriversCategory;


  NearestDriversCategory.fromJson(Map<String, dynamic> json) {
    getNearestDriversCategory = json['getNearestDriversCategory'] != null
        ? new GetNearestDriversCategory.fromJson(
        json['getNearestDriversCategory'])
        : null;
  }

}

class GetNearestDriversCategory {
  String? errorMessage;
  int? status;
  List<Result>? result;

  GetNearestDriversCategory.fromJson(Map<String, dynamic> json) {
    errorMessage = json['errorMessage'];
    status = json['status'];
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
  }

}

class Result {
  int? id;
  String? categoryName;
  String? categoryImage;
  String? categoryMarkerImage;
  List<Location>? location;


  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['categoryName'];
    categoryImage = json['categoryImage'];
    categoryMarkerImage = json['categoryMarkerImage'];
    if (json['location'] != null) {
      location = <Location>[];
      json['location'].forEach((v) {
        location!.add(new Location.fromJson(v));
      });
    }
  }


}

class Location {
  String? id;
  String? email;
  bool? isPasswordUpdated;
  Null? emailConfirmed;
  Null? type;
  Null? userBanStatus;
  double? lat;
  double? lng;



  Location.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    isPasswordUpdated = json['isPasswordUpdated'];
    emailConfirmed = json['emailConfirmed'];
    type = json['type'];
    userBanStatus = json['userBanStatus'];
    lat = json['lat'];
    lng = json['lng'];
  }

}