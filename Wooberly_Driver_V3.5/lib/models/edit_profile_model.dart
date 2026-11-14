class EditProfileModel {
  UserAccount? userAccount;


  EditProfileModel.fromJson(Map<String, dynamic> json) {
    userAccount = json['userAccount'] != null
        ? new UserAccount.fromJson(json['userAccount'])
        : null;
  }

}

class UserAccount {
  Result? result;
  int? status;
  Null errorMessage;


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
  String? notificationInterval;
  String? gender;
  String? email;
  String? picture;
  String? state;
  String? city;
  String? zipcode;
  String? country;
  String? distanceType;
  String? licenceFront;
  dynamic? driverWalletBalance;
  dynamic? minimumWalletAmount;
  bool? isDriverEligible;
  String? licenceBack;
  bool? isBan;
  String? preferredCurrency;
  String? preferredLanguage;
  String? aiPreferredLanguage;
  String? phoneNumber;
  String? tripStatus;
  int? cardLastFour;
  String? cardToken;
  String? payout;
  bool? isPayout;
  int? sourceId;
  bool? isActive;
  String? phoneDialCode;
  String? phoneCountryCode;
  String? userStatus;
  int? userType;
  Verification? verification;
  Vehicles? vehicles;
  String? distance;
  String? duration;
  String? estimatedPrice;
  String? sleepDriverios;
  String? sleepDriverAndroid;
  String? startRideRadius;
  String? pickupLocation;
  String? destinationLocation;
  String? isTripTimerToneEnable;
  String? tripTimeTone;
  String? openAppOnTrip;
  String? contactEmail;
  String? contactPhoneNumber;
  String? numberMasking;
  List<MaskingMethods>? maskingMethods;
  String? appTheme;
  String? payPalPreferredCurrency;


  Result.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    profileId = json['profileId'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    gender = json['gender'];
    notificationInterval = json['notificationInterval'];
    email = json['email'];
    picture = json['picture'];
    state = json['state'];
    city = json['city'];
    zipcode = json['zipcode'];
    country = json['country'];
    driverWalletBalance = json['driverWalletBalance'];
    minimumWalletAmount = json['minimumWalletAmount'];
    isDriverEligible = json['isDriverEligible'];
    licenceFront = json['licenceFront'];
    distanceType = json['distanceType'];
    licenceBack = json['licenceBack'];
    isBan = json['isBan'];
    preferredCurrency = json['preferredCurrency'];
    payPalPreferredCurrency = json['payPalPreferredCurrency'];
    preferredLanguage = json['preferredLanguage'];
    aiPreferredLanguage = json['aiPreferredLanguage'];
    phoneNumber = json['phoneNumber'];
    tripStatus = json['tripStatus'];
    cardLastFour = json['cardLastFour'];
    cardToken = json['cardToken'];
    sourceId = json['sourceId'];
    isActive = json['isActive'];
    phoneDialCode = json['phoneDialCode'];
    phoneCountryCode = json['phoneCountryCode'];
    userStatus = json['userStatus'];
    payout = json['payout'];
    isPayout = json['isPayout'];
    userType = json['userType'];
    numberMasking = json['numberMasking'];
    verification = json['verification'] != null
        ? new Verification.fromJson(json['verification'])
        : null;
    vehicles = json['vehicles'] != null
        ? new Vehicles.fromJson(json['vehicles'])
        : null;

    if (json['maskingMethods'] != null) {
      maskingMethods = <MaskingMethods>[];
      json['maskingMethods'].forEach((v) {
        maskingMethods?.add(new MaskingMethods.fromJson(v));
      });
    }
    distance = json['distance'];
    duration = json['duration'];
    destinationLocation = json['destinationLocation'];
    contactEmail = json['contactEmail'];
    contactPhoneNumber = json['contactPhoneNumber'];
    pickupLocation = json['pickupLocation'];
    estimatedPrice = json['estimatedPrice'];
    sleepDriverAndroid = json['sleepDriverAndroid'];
    startRideRadius = json['startRideRadius'];
    sleepDriverios = json['sleepDriverios'];
    isTripTimerToneEnable = json['isTripTimerToneEnable'];
    openAppOnTrip = json['openAppOnTrip'];
    tripTimeTone = json['tripTimeTone'];
    appTheme = json['appTheme'];
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

class Vehicles {
  int? id;
  String? vehicleRC;
  String? vehicleInsurance;
  String? vehicleName;
  String? vehicleType;
  String? vehicleInsuranceName;
  String? vehicleNumber;
  String? vehicleMakeYear;
  String? vehicleModal;
  String? vehicleImage;
  String? vehicleColor;
  String? vehicleStatus;
  bool? isChildSeat;
  bool? isWheelChair;
  VehicleCategoryDetails? vehicleCategoryDetails;


  Vehicles.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vehicleRC = json['vehicleRC'];
    vehicleInsurance = json['vehicleInsurance'];
    vehicleName = json['vehicleName'];
    vehicleType = json['vehicleType'];
    vehicleInsuranceName = json['vehicleInsuranceName'];
    vehicleNumber = json['vehicleNumber'];
    vehicleColor = json['vehicleColor'];
    vehicleStatus = json['vehicleStatus'];
    isChildSeat = json['isChildSeatAvailable'];
    isWheelChair = json['isWheelChairAvailable'];
    vehicleMakeYear = json['vehicleMakeYear'];
    vehicleModal = json['vehicleModal'];
    vehicleImage = json['vehicleImage'];
    vehicleCategoryDetails = json['vehicleCategoryDetails'] != null
        ? new VehicleCategoryDetails.fromJson(json['vehicleCategoryDetails'])
        : null;
  }

}

class VehicleCategoryDetails {
  int? id;
  String? categoryName;
  String? categoryImage;
  String? categoryMarkerImage;
  dynamic unitPrice;
  dynamic basePrice;
  bool? isActive;
  String? currency;


  VehicleCategoryDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['categoryName'];
    categoryImage = json['categoryImage'];
    categoryMarkerImage = json['categoryMarkerImage'];
    unitPrice = json['unitPrice'];
    basePrice = json['basePrice'];
    isActive = json['isActive'];
    currency = json['currency'];
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