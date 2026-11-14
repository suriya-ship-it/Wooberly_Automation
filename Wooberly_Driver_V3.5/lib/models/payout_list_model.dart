class PayoutListModel {
  GetPayouts? getPayouts;


  PayoutListModel.fromJson(Map<String, dynamic> json) {
    getPayouts = json['getPayouts'] != null
        ? new GetPayouts.fromJson(json['getPayouts'])
        : null;
  }

}

class GetPayouts {
  List<Results>? results;


  GetPayouts.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = [];
      json['results'].forEach((v) {
        results?.add(new Results.fromJson(v));
      });
    }
  }
}

class Results {
  int? id;
  int? methodId;
  String? userId;
  String? payEmail;
  PaymentMethod? paymentMethod;
  String? address1;
  String? address2;
  String? firstName;
  String? lastName;

  String? city;
  bool? defaultpayout;
  String? state;
  String? country;
  String? zipcode;
  String? currency;
  String? createdAt;
  bool? isVerified;
  int? last4Digits;
  int? status;


  Results.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    methodId = json['methodId'];
    userId = json['userId'];
    payEmail = json['payEmail'];
    paymentMethod = json['paymentMethod'] != null
        ? new PaymentMethod.fromJson(json['paymentMethod'])
        : null;
    address1 = json['address1'];
    address2 = json['address2'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    city = json['city'];
    defaultpayout = json['default'];
    state = json['state'];
    country = json['country'];
    zipcode = json['zipcode'];
    currency = json['currency'];
    createdAt = json['createdAt'];
    isVerified = json['isVerified'];
    last4Digits = json['last4Digits'];
    status = json['status'];
  }

}

class PaymentMethod {
  int? id;
  String? name;


  PaymentMethod.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}