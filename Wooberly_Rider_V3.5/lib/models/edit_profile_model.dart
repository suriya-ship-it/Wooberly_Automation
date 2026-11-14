class EditProfileModel {
  UserAccount? userAccount;

  EditProfileModel({this.userAccount});

  EditProfileModel.fromJson(Map<String, dynamic> json) {
    userAccount = json['userAccount'] != null
        ? new UserAccount.fromJson(json['userAccount'])
        : null;
  }

}

class UserAccount {
  Result? result;
  int? status;
  String? errorMessage;


  UserAccount.fromJson(Map<String, dynamic> json) {
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
    status = json['status'];
    errorMessage = json['errorMessage'];
  }

}

class Result {
  String? userId;
  int? profileId;
  String? firstName;
  String? lastName;
  String? gender;
  String? email;
  String? picture;
  String? state;
  String? city;
  int? preferredPaymentMethod;
  String? zipcode;
  String? country;
  String? licenceFront;
  String? licenceBack;
  bool? isBan;
  String? distanceType;
  String? preferredCurrency;
  String? preferredLanguage;
  String? aiPreferredLanguage;
  dynamic walletBalance;
  dynamic walletUsed;
  String? phoneNumber;
  int? cardLastFour;
  String? cardToken;
  String? sourceId;
  bool? isActive;
  String? phoneDialCode;
  String? phoneCountryCode;
  String? userStatus;
  int? userType;
  String? multipleStopsWaitingTime;
  dynamic payout;
  Verification? verification;
  List<SavedLocations>? savedLocations;
   List<EmergencyContacts>? emergencyContacts;
  String? contactEmail;
  String? contactPhoneNumber;
  String? numberMasking;
  List<MaskingMethods>? maskingMethods;
  String? appTheme;
  bool? isActiveBooking;
  String? paymentStatus;
  String? tripStatus;
  String? paypalPreferredCurrency;



  Result.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    profileId = json['profileId'];
    firstName = json['firstName'];
    preferredPaymentMethod = json['preferredPaymentMethod'];
    lastName = json['lastName'];
    email = json['email'];
    gender = json['gender'];
    picture = json['picture'];
    state = json['state'];
    city = json['city'];
    zipcode = json['zipcode'];
    country = json['country'];
    licenceFront = json['licenceFront'];
    licenceBack = json['licenceBack'];
    isBan = json['isBan'];
    distanceType = json["distanceType"];
    preferredCurrency = json['preferredCurrency'];
    paypalPreferredCurrency=json['payPalPreferredCurrency'];
    preferredLanguage = json['preferredLanguage'];
    aiPreferredLanguage = json['aiPreferredLanguage'];
    walletBalance = json['walletBalance'];
    walletUsed = json['walletUsed'];
    phoneNumber = json['phoneNumber'];
    cardLastFour = json['cardLastFour'];
    cardToken = json['cardToken'];
    sourceId = json['sourceId'];
    isActive = json['isActive'];
    phoneDialCode = json['phoneDialCode'];
    phoneCountryCode = json['phoneCountryCode'];
    userStatus = json['userStatus'];
    userType = json['userType'];
    multipleStopsWaitingTime = json['multipleStopsWaitingTime'];
    payout = json['payout'];
    numberMasking = json['numberMasking'];
    verification = json['verification'] != null
        ? new Verification.fromJson(json['verification'])
        : null;

    if (json['savedLocations'] != null) {
      savedLocations = [];
      json['savedLocations'].forEach((v) {
        savedLocations?.add(new SavedLocations.fromJson(v));
      });
    }
    if (json['emergencyContacts'] != null) {
      emergencyContacts = [];
      json['emergencyContacts'].forEach((v) {
        emergencyContacts?.add(new EmergencyContacts.fromJson(v));
      });
    }
    if(json['maskingMethods']!=null){
      maskingMethods = [];
      json['maskingMethods'].forEach((v){
        maskingMethods?.add(new MaskingMethods.fromJson(v));
      });
    }
    contactEmail = json['contactEmail'];
    contactPhoneNumber = json['contactPhoneNumber'];
    appTheme = json['appTheme'];
    isActiveBooking = json['isActiveBooking'];
    paymentStatus = json['paymentStatus'];
    tripStatus = json['tripStatus'];
  }

}

class Verification {
  int? id;
  bool? isEmailConfirmed;
  bool? isLicenseFrontVerified;
  bool? isLicenseBackVerified;



  Verification.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isEmailConfirmed = json['isEmailConfirmed'];
    isLicenseFrontVerified = json['isLicenseFrontVerified'];
    isLicenseBackVerified = json['isLicenseBackVerified'];
  }


}
class SavedLocations {
  int? id;
  String? userId;
  String? location;
  double? lat;
  double? lng;
  String? locationType;
  String? locationName;



  SavedLocations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    location = json['location'];
    lat = double.parse(json['lat']!=null?json['lat'].toString():0.0.toString());
    lng = double.parse(json['lng']!=null?json['lng'].toString():0.0.toString());
    locationType = json['locationType'];
    locationName = json['locationName'];
  }


}

class EmergencyContacts {
  int? id;
  String? userId;
  String? contactName;
  String? phoneNumber;

  EmergencyContacts({this.id, this.userId, this.contactName, this.phoneNumber});

  EmergencyContacts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    contactName = json['contactName'];
    phoneNumber = json['phoneNumber'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['contactName'] = this.contactName;
    data['phoneNumber'] = this.phoneNumber;
    return data;
  }

  @override
  String toString() {
    return "{\"phoneNumber\":\"$phoneNumber\",\"contactName\":\"$contactName\"}";
  }
}

class MaskingMethods {
  int? id;
  String? name;
  String? accountId;
  String? securityId;
  String? phoneNumber;
  String? phoneDialCode;
  String? phoneCountryCode;
  bool? status;
  String? environment;


  MaskingMethods.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    accountId = json['accountId'];
    securityId = json['securityId'];
    phoneNumber = json['phoneNumber'];
    phoneDialCode = json['phoneDialCode'];
    phoneCountryCode = json['phoneCountryCode'];
    status = json['status'];
    environment = json['environment'];
  }

}