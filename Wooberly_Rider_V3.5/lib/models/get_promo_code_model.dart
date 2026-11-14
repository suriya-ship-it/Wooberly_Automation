class GetPromoCodeModel {
  GetPromoCode? getPromoCode;

  GetPromoCodeModel.fromJson(Map<String, dynamic> json) {
    getPromoCode = json['getPromoCode'] != null
        ? new GetPromoCode.fromJson(json['getPromoCode'])
        : null;
  }

}

class GetPromoCode {
  int? status;
  String? errorMessage;
  List<ResultPromo>? result;

  GetPromoCode.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    errorMessage = json['errorMessage'];
    if (json['result'] != null) {
      result = [];
      json['result'].forEach((v) {
        result?.add(new ResultPromo.fromJson(v));
      });
    }
  }

}

class ResultPromo {
  int? id;
  String? title;
  String? description;
  String? code;
  int? type;
  dynamic promoValue;
  String? currency;
  String? expiryDate;
  bool? isEnable;
  String? image;
  String? createdAt;
  String? updatedAt;
  List? availableCategories;


  ResultPromo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    image = json['image'];
    code = json['code'];
    type = json['type'];
    promoValue = json['promoValue'];
    currency = json['currency'];
    expiryDate = json['expiryDate'];
    isEnable = json['isEnable'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    availableCategories = json['availableCategories'];
  }

}