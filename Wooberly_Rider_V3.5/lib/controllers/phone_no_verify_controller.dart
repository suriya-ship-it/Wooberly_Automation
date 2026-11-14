import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'package:app_name/app/app.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/models/verify_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/controllers/edit_account_controller.dart';

class PhoneNoVerifyController extends BaseController{
  var phoneNoController;
  bool isSMSAcknowledged = false;
  RxBool loading = false.obs;
  var pinvalue = "";
  int bookingId = 0;
  late Data verifyModel;
  EditAccountController controller = Get.find();
  List<Map<String, dynamic>> launguages = [];


@override
  void onInit() {
  init();
  for (var i = 0; i < globals.langCodeJson.length; i++) {
    Map<String, dynamic> map = Map<String, dynamic>();
    map["id"] = controller.languageCode[i];
    map["value"] = controller.languageDropDown[i];
    map["discode"] = controller.languageCode[i];
    launguages.add(map);
  }
}

  init() {
    graphQlObject.getGraphQlClient();
    getDeviceDetails();
    phoneNoController = TextEditingController(text: "");
    isSMSAcknowledged = false;
  }

  Future<String> VerifyPhone(String securityKey) async {
      String phone = phoneNoController.text
          .trim()
          .replaceFirst(RegExp(r'^0+'), '');
      var variables = <String, dynamic>{
        "phoneNumber": phone,
        "phoneDialCode": globals.DialCode,
        "deviceType": globals.deviceName,
        "deviceId": globals.deviceId,
        "userType": 1,
        "securityKey": securityKey
      };
      Map<String, dynamic>? _login_result = await graphQlObject
          .getMutationValues(
          graphQlObject.graphQLClient, "sendVerificationSecureSms", variables);

      if (_login_result != null) {
        if (_login_result["sendVerificationSecureSms"]["status"] == 200) {
          globals.isContinuousLoading = true;
          return "";
        } else {
          globals.isContinuousLoading = false;
          return _login_result["sendVerificationSecureSms"]["errorMessage"];
        }
      } else {
        globals.isContinuousLoading = false;
        return "null";
      }
    }



  void setLoadingController(bool param0) {
    loading(param0);
  }

  Future<String> verifyOTP() async {
    int otpval = int.parse(pinvalue);
    String phone =phoneNoController.text
        .trim()
        .replaceFirst(RegExp(r'^0+'), '');

    var variables = <String, dynamic>{
      "phoneNumber": phone,
      "phoneDialCode": globals.DialCode,
      "deviceType": globals.deviceName,
      "verificationCode": otpval,
      "deviceId": globals.deviceId,
      "userType": 1,
      "preferredLanguage": globals.preferredLanguage
    };

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClient, "verifyPhoneNumber_mutation", variables);

    if (_login_result != null) {
      if (_login_result["verifyPhoneNumber"]["status"] == 200) {
        verifyModel = Data.fromJson(_login_result);

        if (_login_result["verifyPhoneNumber"]["result"] != null) {
          if (_login_result["verifyPhoneNumber"]["result"]["auth"] != null) {
            globals.authToken = verifyModel.verifyPhoneNumber!.result!.auth;
            graphQlObject.getGraphQlClientWithHeader();
          } else
            globals.authToken = "";

          if (_login_result["verifyPhoneNumber"]["result"]["account"] != null) {
            globals.email = verifyModel.verifyPhoneNumber!.result!.account!.email;
            globals.userid = verifyModel.verifyPhoneNumber!.result!.account!.userId;
          } else {
            globals.userid = "";
          }
        } else {
          globals.authToken = "";
          globals.userid = "";
        }

        return "";
      } else {
        globals.setButtonIdle();
        return _login_result["verifyPhoneNumber"]["errorMessage"];
      }
    } else {
      globals.setButtonIdle();

      return "null";
    }
  }
  Future<String?> getProfileInfo() async {
    EditProfileModel editProfileModel = EditProfileModel();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    try {
      Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader, "userAccount_query", null);

      if (_login_result != null) {
        if (_login_result["userAccount"]["status"] == 200) {
          editProfileModel = EditProfileModel.fromJson(_login_result);
          globals.paypalCurrencyController.text = editProfileModel.userAccount?.result?.paypalPreferredCurrency ?? "";
          globals.firstname.value = toBeginningOfSentenceCase(editProfileModel.userAccount!.result!.firstName)!;
          globals.lastname.value = toBeginningOfSentenceCase(editProfileModel.userAccount!.result!.lastName)!;
          globals.email = editProfileModel.userAccount!.result!.email!;
          globals.gender = editProfileModel.userAccount!.result!.gender!;
          globals.preferredLanguage = editProfileModel.userAccount!.result!.preferredLanguage!;
          preferences.preferredLaunguage= globals.preferredLanguage;
          globals.aiPreferredLanguage = editProfileModel.userAccount?.result?.aiPreferredLanguage ?? '';
          globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
          // App().translations.readJson(language: globals.preferredLanguage, isUpdate: true,isOnlyDownload: true);
          if (editProfileModel.userAccount!.result!.picture != null) {
            globals.picture.value = globals.UPLOAD_URL + "/images/avatar/medium_" + editProfileModel.userAccount!.result!.picture!;
          }

          globals.phoneNumber = editProfileModel.userAccount!.result!.phoneNumber!;

          if (editProfileModel.userAccount!.result!.phoneCountryCode!.length! == 2)
            globals.CountryCode = editProfileModel.userAccount!.result!.phoneCountryCode!;
          globals.DialCode = editProfileModel.userAccount!.result!.phoneDialCode!;
          globals.isCurrentPassword = _login_result["userAccount"]["result"]["isCurrentPassword"];
          if(globals.paypalCurrencies.isEmpty)
            getCurrencyListForPaypal();
          globals.preferredCurrency =
              editProfileModel.userAccount!.result!.preferredCurrency!;
          if (editProfileModel.userAccount!.result!.walletBalance! != null) {
            globals.walletBalance.value =double.parse(editProfileModel.userAccount!.result!.walletBalance!.toString());
          }
          globals.contacts =
              editProfileModel.userAccount!.result!.emergencyContacts!;
          globals.cardLastFour = editProfileModel.userAccount?.result?.cardLastFour;
          globals.contacts = editProfileModel.userAccount!.result!.emergencyContacts!;
          globals.preferredPaymentMethod =
              editProfileModel.userAccount!.result!.preferredPaymentMethod!;
          NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
          globals.currencySymbol =
              _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
          globals.currencySymbol = getCurrencySybmol(
              globals.preferredCurrency, globals.currencySymbol);

          List<SavedLocations> saved =
              editProfileModel.userAccount!.result!.savedLocations!;
          for (int i = 0; i < saved.length; i++) {
            if (saved[i].locationType == "home") {

              setLocationDetails(selectLocationModel: SelectLocationModel(
                  lat: double.parse(saved[i].lat.toString()),
                  lng:  double.parse(saved[i].lng.toString()),
                  selectLocationEnum: SelectLocationEnum.homeLocation,
                  location: saved[i].location!,
                  id: int.parse(saved[i].id.toString()),
                  isValidLocation: true,),
                selectLocationEnum:  SelectLocationEnum.homeLocation,);

            } else if (saved[i].locationType == "work") {
              setLocationDetails(selectLocationModel: SelectLocationModel(
                lat: double.parse(saved[i].lat.toString()),
                lng:  double.parse(saved[i].lng.toString()),
                selectLocationEnum: SelectLocationEnum.workLocation,
                location: saved[i].location!,
                id: int.parse(saved[i].id.toString()),
                isValidLocation: true,),
                selectLocationEnum:  SelectLocationEnum.workLocation,);

            }
          }

          if (editProfileModel.userAccount!.result!.appTheme == "auto") {
            globals.theme = 1;
            var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
            globals.isDarkTheme = brightness == Brightness.dark;
          } else if (editProfileModel.userAccount!.result!.appTheme == "light") {
            globals.theme = 2;
            globals.isDarkTheme = false;
          } else {
            globals.theme = 3;
            globals.isDarkTheme = true;
          }
          globals.themeNotifier?.isDark = globals.isDarkTheme;
          return "";
        } else if (_login_result["userAccount"]["status"] == 500) {
          return _login_result["userAccount"]["errorMessage"];
        } else {
          return _login_result["userAccount"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    } on Exception catch (e) {
      if (e
          .toString()
          .contains("SocketException: OS Error: Network is unreachable"))
        return "offline";
    }
  }

  Future<String?> getCurrencyRates() async {
    if (graphQlObject.graphQLClient != null) {
      try {
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClient, "getCurrencyRates_query", null);

        if (_currency_rates != null) {
          if (_currency_rates["currency"]["status"] == 200) {
            globals.currencyRates =
                _currency_rates["currency"]["result"]["rates"];
            return "";
          }
        } else {
          return "null";
        }
      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getCurrencyRates();
        });
      }
    } else {}
  }

  Future<String?> getSecureSiteSettings() async {
    getSecurityKey().then((securityKey) async {
      if (graphQlObject.graphQLClient != null) {
        var variables = <String, dynamic>{
          "securityKey": securityKey,
          "appType": "rider"
        };
        graphQlObject.graphQLClient.cache.store.reset();
        try {
          globals.isLoaderShow = false;
          globals.closeKeyBoard = false;
          globals.isContinuousLoading = true;
          Map<String, dynamic>? paymentResult = await graphQlObject
              .getQueryValues(
              graphQlObject.graphQLClient, "getSecureSiteSettings", variables);
          if (paymentResult?["getSecureSiteSettings"]["status"] == 200) {
            paymentResult?["getSecureSiteSettings"]["results"].forEach((
                element) => {
              updatesSecureSiteSettings[element["name"]]?.call(element["value"])
            });

            if(!globals.isVoiceChatEnable)
            globals.isVoiceTranslatorEnable  = false;
            return "";
          }else{
            return "null";
          }

        } on Exception catch (e) {
          graphQlObject.loadGraphQLJson("login_graphql").then((value) {
            getSecureSiteSettings();
          });
        }
      }
    });
  }



  Future<String> getTripStatus() async {
    globals.isLoaderShow = false;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? _tripstatusResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "tripStatus_query", null);

    if (_tripstatusResult != null &&
        _tripstatusResult["GetTripStatus"]["status"] == 200) {
      globals.tripStatus = _tripstatusResult["GetTripStatus"]["result"]["tripStatus"];
      bookingId = _tripstatusResult["GetTripStatus"]["result"]["id"];
      return "success";
    } else {
      return _tripstatusResult !=null ?_tripstatusResult["GetTripStatus"]["errorMessage"] : 'offline';
    }
  }
}