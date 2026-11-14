import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/edit_profile_model.dart';
import 'package:wooberly_driver/models/payout_list_model.dart';
import 'package:wooberly_driver/models/verify_model.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

class PhoneNoVerifyController extends BaseController {

  var phoneNoController;
  bool isSMSAcknowledged = false;
  var pinvalue = "";
  late Data verifyModel;
  PayoutListModel? allPayouts;
  bool isban = false;
  String phoneCountrycode = "";

  List<Map<String, dynamic>> launguages = [];
  EditAccountController controller = Get.find();


  @override
  void onInit(){
  init();
    for (var i = 0; i < globals.langCodeJson.length; i++) {
      Map<String, dynamic> map = Map<String, dynamic>();
      map["id"] = controller.languageCode[i];
      map["value"] = controller.languageDropDown[i];
      map["discode"] = controller.languageCode[i];
      launguages.add(map);
    }
    super.onInit();
  }

  init() {
    getDeviceDetails();
    phoneNoController = TextEditingController(text: "");
    isSMSAcknowledged = false;
  }

  void changeFocusListener(
      BuildContext context,
      TextEditingController teOtpDigitOne,
      FocusNode focusNodeDigitTwo,
      FocusNode unfocusview) {
    teOtpDigitOne.addListener(() {
      if (teOtpDigitOne.text.length > 0 && focusNodeDigitTwo != null) {
        unfocusview.unfocus();
        FocusScope.of(context).requestFocus(focusNodeDigitTwo);
      }
    });
  }

  Future<String> VerifyPhone(String securityKey) async {
    String phone = phoneNoController.text.toString().replaceFirst(RegExp(r'^0+'), '');

    var variables = <String, dynamic>{
      "phoneNumber": phone,
      "phoneDialCode": globals.DialCode,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId,
      "preferredLanguage": globals.preferredLanguage.value,
      "userType": 2,
      "securityKey": securityKey
    };

    print("graphQlObject.graphQLClient: ${variables}");
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClient, "sendVerificationSecureSms", variables);

    if (_login_result != null) {
      if (_login_result["sendVerificationSecureSms"]["status"] == 200) {
        return "";
      } else {
        return _login_result["sendVerificationSecureSms"]["errorMessage"];
      }
    } else {
      return "null";
    }
  }

  Future<String?> getUpdatedVersion() async {
    if (graphQlObject.graphQLClient != null) {
      var variables = <String, dynamic>{
        "osType": globals.deviceName,
        "appType": 2,
        "version": globals.versionCode,
        "requestLang": globals.preferredLanguage.value,
      };

      try {
        Map<String, dynamic>? _updated_version =
            await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
                "getApplicationVersionInfo_query", variables);

        if (_updated_version?["getApplicationVersionInfo"]["status"] == 400) {
          if (_updated_version?["getApplicationVersionInfo"]["result"] !=
              null) {
            globals.playStoreURL =
                _updated_version?["getApplicationVersionInfo"]["result"]
                    ["playStoreURL"]["driver"];
            globals.appStoreURL = _updated_version?["getApplicationVersionInfo"]
                ["result"]["appStoreURL"]["driver"];
          }
          return _updated_version?["getApplicationVersionInfo"]["errorMessage"];
        } else {
          return "";
        }
      }  on Exception catch (e, stack) {
        debugPrint("Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
    }
  }

  Future<String?> getPaymentSettings() async {
    globals.isLoaderShow = false;
    App().getSecurityKey().then((securityKey) async {
      if (graphQlObject.graphQLClient != null) {
        var variables = <String, dynamic>{
          "securityKey": securityKey,
        };

        graphQlObject.graphQLClient.cache.store.reset();
        try {
          Map<String, dynamic>? paymentResult =
              await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
                  "getSecureSiteSettings", variables);
          if (paymentResult?["getSecureSiteSettings"]["status"] == 200) {
            Map<String,dynamic> walletoption ={};
            walletoption.addAll(globals.driverWalletOptionController.value);
            final results = paymentResult?["getSecureSiteSettings"]?["results"];
            if (results is Iterable) {
              for (final element in results) {
                final String? name = element["name"];
                final dynamic value = element["value"];
                if (name == null) continue;

                // 1. Handle simple direct assignments using a Map
                final directMappings = {
                  "stripePublishableKey": () => globals.stripePublishableKey = value,
                  "preferredDistanceType": () => globals.distanceType = value,
                  "startRideRadius": () => globals.startRideRadius = value,
                  "contactPhoneNumber": () => globals.supportPhone = value,
                  "contactEmail": () => globals.supportEmail = value,
                  "whatsApp": () => globals.supportWhatsapp = value,
                  "driverWalletOption": () => walletoption["driverWalletOption"] = value,
                  "walletFlow": () => walletoption["walletFlow"] = value,

                  "distance": () => globals.showDistance = value == "1",
                  "duration": () => globals.showDuration = value == "1",
                  "estimatedPrice": () => globals.showEstimatedFare = value == "1",
                  "pickupLocation": () => globals.showPickUpLocation = value == "1",
                  "destinationLocation": () => globals.showDropLocation = value == "1",
                  "isTripTimerToneEnable": () => globals.playTripSound = value == "1",
                  "openAppOnTrip": () => globals.isBringAppToForeGround = value == "1",
                  "enableOTPFeature": () => globals.isEnableOTP = value == '1',
                  "isVoiceAIFeature": () => globals.isVoiceChatEnable = value == 'true',
                  "isVoiceTranslatorFeature": () => globals.isVoiceTranslatorEnable = value == 'true',
                };

                if (directMappings.containsKey(name)) {
                  directMappings[name]!();
                  continue;
                }

                // 2. Handle conditional, platform-specific, or transformed logic
                switch (name) {
                  case "tripTimeTone":
                    if (value != null) {
                      final valStr = value.toString();
                      globals.tripAudioURL = valStr.contains("http")
                          ? valStr
                          : "${globals.UPLOAD_URL}/images/tripTone/$valStr";
                    }
                    break;

                  case "notificationInterval":
                    if (value != null) {
                      globals.notificationInterval = (double.parse(value.toString()) * 60).round();
                    }
                    break;

                  case "driverAppAndroidMapApiKey" when Platform.isAndroid:
                  case "driverAppiOSMapApiKey" when Platform.isIOS:
                    globals.MAP_KEY = value;
                    App().setMapKey();
                    break;

                  case "sleepDriverAndroid" when Platform.isAndroid:
                  case "sleepDriverios" when Platform.isIOS:
                    globals.screenAwake = value;
                    break;
                }
              }
            }
            globals.showLocations = globals.showPickUpLocation || globals.showDropLocation;
            globals.progressLoadTime = globals.notificationInterval;
            if(!walletoption["isDriverEligible"]  &&  walletoption["driverWalletOption"] =="1")
              globals.driverStatus = globals.driverStatus+'_NotEligible';
            globals.driverWalletOptionController.value = walletoption;
            App().getAudioPlayerCache();
            return "";
          } else {
            return "null";
          }
        }  on Exception catch (e, stack) {
          debugPrint("Error: $e");
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }
    });
  }

  Future<String> verifyOTP() async {
    graphQlObject.graphQLClient.cache.store.reset();
    globals.isEnableContinuousLoading = true;
    try {
      int otpval = int.parse(pinvalue);
      String phone = phoneNoController.text.toString().replaceFirst(RegExp(r'^0+'), '');
      var variables = <String, dynamic>{
        "phoneNumber": phone.toString(),
        "phoneDialCode": globals.DialCode.toString(),
        "deviceType": globals.deviceName.toString(),
        "verificationCode": otpval,
        "deviceId": globals.deviceId.toString(),
        "userType": int.parse('2'),
        "preferredLanguage": globals.preferredLanguage.value.toString()
      };
      Map<String, dynamic>? _login_result =
          await graphQlObject.getMutationValues(graphQlObject.graphQLClient,
              "verifyPhoneNumber_mutation", variables);

      if (_login_result != null) {
        if (_login_result["verifyPhoneNumber"]["status"] == 200) {
          log("_login_result: ${_login_result.toString()}");
          verifyModel = Data.fromJson(_login_result);

          if (verifyModel.verifyPhoneNumber?.result?.account != null) {
            globals.authToken = verifyModel.verifyPhoneNumber?.result?.auth;
            graphQlObject.getGraphQlClientWithHeader();
            if (verifyModel.verifyPhoneNumber?.result?.account?.vehicles != null) {
              globals.isVehicleDetailsReq = false;
            } else {
              globals.isVehicleDetailsReq = true;
            }

            globals.email =
                verifyModel.verifyPhoneNumber?.result?.account?.email ?? "";
            globals.userid =
                verifyModel.verifyPhoneNumber?.result?.account?.userId ?? "";
            String front = verifyModel
                    .verifyPhoneNumber?.result?.account?.licenceFrontName ??
                "";
            String back = verifyModel
                    .verifyPhoneNumber?.result?.account?.licenceBackName ??
                "";
            String rc = "", insu = "";
              rc = verifyModel.verifyPhoneNumber?.result?.account?.vehicles
                      ?.vehicleRCName ??
                  "";
              insu = verifyModel.verifyPhoneNumber?.result?.account?.vehicles
                      ?.vehicleInsuranceName ??
                  "";

              if (front != null && front.isNotEmpty) {
                String docfront = globals.UPLOAD_URL + "/" + front;
                App().appPreference.isDoc = docfront;
              }
              if (back != null && back.isNotEmpty) {
                String docback = globals.UPLOAD_URL + "/" + back;
                App().appPreference.backPath = docback;
              }
              if (rc != null && rc.isNotEmpty) {
                String docback = globals.UPLOAD_URL + "/" + rc;
                App().appPreference.rcPath = docback;
              }
              if (insu != null && insu.isNotEmpty) {
                String docback = globals.UPLOAD_URL + "/" + insu;
                App().appPreference.insuPath = docback;
              }
              debugPrint("verifyotp:doc: ${ App().appPreference.isDoc} --- ${App().appPreference.backPath} ");
          } else {
            globals.authToken = "";
            globals.userid = "";
          }

          return "";
        } else {
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
          return _login_result["verifyPhoneNumber"]["errorMessage"];
        }
      } else {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        return "null";
      }
    } on Exception {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      return "Invaild OTP";
    }
  }

  Future<String> getProfileInfo() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    EditProfileModel? editProfileModel;
    globals.isEnableContinuousLoading = true;

    Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "userAccount_query", null);

    if (_login_result?["userAccount"]["status"] == 200) {
      editProfileModel = EditProfileModel.fromJson(_login_result!);
      globals.paypalCurrencyController.text = editProfileModel.userAccount?.result?.payPalPreferredCurrency ?? "";
      globals.driverStatus = editProfileModel?.userAccount?.result?.userStatus ?? "";
      globals.loginTripStatus = editProfileModel.userAccount?.result?.tripStatus ?? "";
      globals.isActive = editProfileModel?.userAccount?.result?.isActive ?? false;
      isban = editProfileModel?.userAccount?.result?.isBan ?? false;
      if (globals.loginTripStatus.compareTo("cancelledByRider") == 0 ||
          globals.loginTripStatus.compareTo("cancelledByDriver") == 0 ||
          globals.loginTripStatus.compareTo("expired") == 0 ||
          globals.loginTripStatus == '' ||
          globals.loginTripStatus.compareTo("completed") == 0) {
        if (globals.driverStatus == "active" && globals.isActive && !isban) {
          updateDriverStatus(false);
        }
      }
      globals.firstname =
          editProfileModel?.userAccount?.result?.firstName ?? "";
      globals.lastname = editProfileModel?.userAccount?.result?.lastName ?? "";
      globals.email = editProfileModel?.userAccount?.result?.email;
      if (editProfileModel.userAccount?.result?.picture != null) {
        globals.picture = globals.UPLOAD_URL +
            "/images/avatar/" +
            (editProfileModel.userAccount?.result?.picture ?? "");
      }
      globals.gender = editProfileModel.userAccount?.result?.gender;
      globals.preferredLanguage.value =
          editProfileModel?.userAccount?.result?.preferredLanguage ??
              globals.defaultLanguageCode;
      globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
      App().appPreference.preferredLanguage = globals.preferredLanguage.value;
      globals.aiPreferredLanguage = editProfileModel.userAccount?.result?.aiPreferredLanguage ?? "";

      phoneCountrycode = globals.CountryCode =
          editProfileModel?.userAccount?.result?.phoneCountryCode ?? "";
      Map<String,dynamic> walletoptions ={};
      walletoptions.addAll(globals.driverWalletOptionController.value);
      walletoptions["walletBalance"] = editProfileModel.userAccount?.result?.driverWalletBalance;
      walletoptions["minimumWalletAmount"] = editProfileModel.userAccount?.result?.minimumWalletAmount;
      walletoptions["isDriverEligible"] = editProfileModel.userAccount?.result?.isDriverEligible;
      globals.driverWalletOptionController.value = walletoptions;
      if(!walletoptions["isDriverEligible"]  &&  walletoptions["driverWalletOption"] =="1") globals.driverStatus = globals.driverStatus+'_NotEligible';
      globals.DialCode =
          editProfileModel?.userAccount?.result?.phoneDialCode ?? "";
      globals.preferredCurrency =
          editProfileModel?.userAccount?.result?.preferredCurrency ?? "";

      NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
      globals.currencySymbol =
          _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
      globals.currencySymbol = getCurrencySybmol(globals.preferredCurrency, globals.currencySymbol);
      if (editProfileModel?.userAccount?.result?.licenceFront != null)
        globals.front = globals.UPLOAD_URL +
            "/images/license/" +
            (editProfileModel?.userAccount?.result?.licenceFront ?? "");
      if (editProfileModel?.userAccount?.result?.licenceBack != null)
        globals.back = globals.UPLOAD_URL +
            "/images/license/" +
            (editProfileModel?.userAccount?.result?.licenceBack ?? "");
      if (editProfileModel?.userAccount?.result?.vehicles?.vehicleRC != null)
        globals.RC = globals.UPLOAD_URL +
            "/images/vehicle/" +
            (editProfileModel?.userAccount?.result?.vehicles?.vehicleRC ?? "");
      if (editProfileModel?.userAccount?.result?.vehicles?.vehicleInsurance !=
          null)
        globals.Insurance = globals.UPLOAD_URL +
            "/images/vehicle/" +
            (editProfileModel
                    ?.userAccount?.result?.vehicles?.vehicleInsurance ??
                "");
      globals.vehicleType = editProfileModel?.userAccount?.result?.vehicles
              ?.vehicleCategoryDetails?.categoryName ??
          "";
      if (editProfileModel?.userAccount?.result?.vehicles
              ?.vehicleCategoryDetails?.categoryMarkerImage !=
          null)
        globals.categoryImage = await getImage(editProfileModel
                ?.userAccount
                ?.result
                ?.vehicles
                ?.vehicleCategoryDetails
                ?.categoryMarkerImage ??
            "");
      if (editProfileModel?.userAccount?.result?.vehicles
              ?.vehicleCategoryDetails?.categoryImage !=
          null)
        globals.vehicleImage = globals.UPLOAD_URL +
            "/images/category/" +
            (editProfileModel?.userAccount?.result?.vehicles
                    ?.vehicleCategoryDetails?.categoryImage ??
                "");

      globals.vehicleName =
          editProfileModel?.userAccount?.result?.vehicles?.vehicleName ?? "";
      globals.vehicleNumber =
          (editProfileModel?.userAccount?.result?.vehicles?.vehicleNumber ?? "")
              .toUpperCase();
      globals.vehicleYear =
      (editProfileModel.userAccount?.result?.vehicles?.vehicleMakeYear ??
          "");
      globals.vehiclePhoto =
      (editProfileModel.userAccount?.result?.vehicles?.vehicleImage ??
          "");
      globals.vehicleModel =
      (editProfileModel.userAccount?.result?.vehicles?.vehicleModal ??
          "");
      globals.vehicleColor =
          editProfileModel?.userAccount?.result?.vehicles?.vehicleColor ?? "";
      globals.isChildSeatAvailable =
          editProfileModel?.userAccount?.result?.vehicles?.isChildSeat ?? false;
      globals.isWheelChairAvailable =
          editProfileModel?.userAccount?.result?.vehicles?.isWheelChair ??
              false;
      globals.idVehicleToUpdate =
          editProfileModel?.userAccount?.result?.vehicles?.id ?? 0;
      globals.vehicleId = int.parse(
          editProfileModel?.userAccount?.result?.vehicles?.vehicleType ?? "0");
      globals.vehicleNumber = globals.vehicleNumber.toString().toUpperCase();
      if (editProfileModel?.userAccount?.result?.appTheme == "auto") {
        globals.theme.value = 1;
      } else if (editProfileModel?.userAccount?.result?.appTheme == "light") {
        globals.theme.value = 2;
      } else {
        globals.theme.value = 3;
      }
      getPaymentSettings();
      if(globals.paypalCurrencies.isEmpty)
        getCurrencyList();
      return "";
    } else {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      return _login_result?["userAccount"]["errorMessage"];
    }
  }

  Future<String?> getPayouts() async {
    globals.isEnableContinuousLoading = true;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    Map<String, dynamic>? _countries_result =
        await graphQlObject.getQueryValues(
            graphQlObject.graphQLClientWithHeader, "getPayouts_query", null);
    if (_countries_result !=
        null) if (_countries_result["getPayouts"]["status"] == 200) {
      allPayouts = PayoutListModel.fromJson(_countries_result);
      if ((allPayouts?.getPayouts?.results?.length ?? 0) > 0) {
        globals.payout = 1;
        for (int i = 0;
            i < (allPayouts?.getPayouts?.results?.length ?? 0);
            i++) {
          if ((allPayouts?.getPayouts?.results?[i].isVerified != null &&
                  (allPayouts?.getPayouts?.results?[i].isVerified ?? false)) ||
              (allPayouts?.getPayouts?.results?[i].defaultpayout != null &&
                  (allPayouts?.getPayouts?.results?[i].defaultpayout ??
                      false))) {
            globals.isPayout = true;
          }
        }
      } else {
        globals.payout = 0;
        globals.isPayout = false;
      }

      return "";
    } else {
      return _countries_result["getPayouts"]["errorMessage"];
    }
  }

  Future<BitmapDescriptor> getImage(String imageURL) async {
    http.Response response = await http.get(
      Uri.parse(globals.UPLOAD_URL + "/images/category/" + imageURL),
    );
    ui.Codec codec =
        await ui.instantiateImageCodec(response.bodyBytes, targetHeight: 120);
    ui.FrameInfo fi = await codec.getNextFrame();
    Uint8List markericon =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.bytes(markericon,imagePixelRatio: globals.markerImagePixelRatio);
  }




  Future<String> updateDriverStatus(bool isActive) async {
    globals.isEnableContinuousLoading = true;
    var variables = <String, dynamic>{
      "isActive": isActive,
      "lat": globals.userLat,
      "lng": globals.userLon
    };

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "updateDriverstatus_mutation",
        variables);

    if (_login_result?["updateDriverstatus"]["status"] == 200) {
      debugPrint("otpverify: rxOnlineStatus.value: ${isActive}");
      globals.isActive = isActive;

      return "";
    } else {
      return _login_result?["updateDriverstatus"]["errorMessage"];
    }
  }
}