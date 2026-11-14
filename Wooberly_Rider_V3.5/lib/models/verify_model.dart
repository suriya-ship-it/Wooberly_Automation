class Data {
  VerifyPhoneNumber? verifyPhoneNumber;

  Data.fromJson(Map<String, dynamic> json) {
    verifyPhoneNumber = json['verifyPhoneNumber'] != null
        ? new VerifyPhoneNumber.fromJson(json['verifyPhoneNumber'])
        : null;
  }
}

class VerifyPhoneNumber {
  int? status;
  Null errorMessage;
  Result? result;

  VerifyPhoneNumber.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    errorMessage = json['errorMessage'];
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
  }

}

class Result {
  String? auth;
  String? phoneNumber;
  String? phoneDialCode;
  Account? account;

  Result.fromJson(Map<String, dynamic> json) {
    auth = json['auth'];
    phoneNumber = json['phoneNumber'];
    phoneDialCode = json['phoneDialCode'];
    account =
    json['account'] != null ? new Account.fromJson(json['account']) : null;
  }
}

class Account {
  Null email;
  String? userId;
  String? firstName;
  String? lastName;
  String? picture;
  double? lat;
  double? lng;
  String? state;
  String? city;
  String? country;
  String? zipcode;
  String? licenceFrontName;
  String? licenceBackName;
  String? preferredLanguage;
  String? preferredCurrency;
  bool? preferredPaymentMethod;
  Vehicles? vehicles;


  Account.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    userId = json['userId'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    picture = json['picture'];
    lat = json['lat'];
    lng = json['lng'];
    state = json['state'];
    city = json['city'];
    country = json['country'];
    zipcode = json['zipcode'];
    licenceFrontName = json['licenceFrontName'];
    licenceBackName = json['licenceBackName'];
    preferredLanguage = json['preferredLanguage'];
    preferredCurrency = json['preferredCurrency'];
    preferredPaymentMethod = json['preferredPaymentMethod'];
    vehicles = json['vehicles'] != null
        ? new Vehicles.fromJson(json['vehicles'])
        : null;
  }

}

class Vehicles {
  String? vehicleRCName;
  String? vehicleInsuranceName;

  Vehicles.fromJson(Map<String, dynamic> json) {
    vehicleRCName = json['vehicleRCName'];
    vehicleInsuranceName = json['vehicleInsuranceName'];
  }

}