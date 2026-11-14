class Data {
  GetCategories? getCategories;

  Data({this.getCategories});

  Data.fromJson(Map<String, dynamic> json) {
    getCategories = json['getCategories'] != null
        ? new GetCategories.fromJson(json['getCategories'])
        : null;
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
        result?.add(new Result.fromJson(v));
      });
    }
    status = json['status'];
    errorMessage = json['errorMessage'];
  }
}

class Result {
  int? id;
  String? categoryName;
  String? categoryImage;
  String? categoryMarkerImage;
  dynamic unitPrice;
  dynamic minutePrice;
  dynamic basePrice;
  bool? isActive;
  String? currency;

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['categoryName'];
    categoryImage = json['categoryImage'];
    categoryMarkerImage = json['categoryMarkerImage'];
    unitPrice = json['unitPrice'];
    minutePrice = json['minutePrice'];
    basePrice = json['basePrice'];
    isActive = json['isActive'];
    currency = json['currency'];
  }

}