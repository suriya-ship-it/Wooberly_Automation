import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';

import '../models/mobile_language.dart';
import '../utils/globals.dart';
import 'edit_account_controller.dart';

class SplashController extends BaseController{
  RxBool getStartedEnableController = false.obs;
  EditAccountController editAccountController = Get.find();
  String paymentStatus = '';
  int bookingId = 0;
  bool isActiveBooking = false;

  bool isMatched = false;

  RxBool showFrozenImage = false.obs;


  Future<String?> getProfileInfo() async {
    if (preferences.authToken.isEmpty) {
      String? restoredToken = await preferences.checkRestoredCredential();
      if (restoredToken != null && restoredToken.isNotEmpty) {
        preferences.authToken = restoredToken;
        globals.authToken = restoredToken;
      }
    }
    late EditProfileModel editProfileModel ;
    globals.isContinuousLoading = true;
    graphQlObject.graphQLClientWithHeader!.cache.store.reset();
    try {
      Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader!, "userAccount_query", null);

      if (_login_result != null) {
        if (_login_result["userAccount"]["status"] == 200) {
          editProfileModel = EditProfileModel.fromJson(_login_result);
          globals.paypalCurrencyController.text = editProfileModel.userAccount?.result?.paypalPreferredCurrency ?? "";
          globals.firstname.value = toBeginningOfSentenceCase(editProfileModel.userAccount?.result?.firstName?? '')!;
          globals.lastname.value = toBeginningOfSentenceCase(editProfileModel.userAccount?.result?.lastName ?? '')!;
          globals.userid = editProfileModel.userAccount?.result?.userId;
          globals.email = editProfileModel.userAccount?.result?.email;
          globals.gender = editProfileModel.userAccount?.result?.gender;
          globals.aiPreferredLanguage = editProfileModel.userAccount?.result?.aiPreferredLanguage ?? '';

          if(globals.paypalCurrencies.isEmpty)
            getCurrencyListForPaypal();
          if (editProfileModel.userAccount?.result?.picture != null) {
            globals.picture.value = globals.UPLOAD_URL + "/images/avatar/medium_" + editProfileModel.userAccount!.result!.picture!;
          }
          globals.phoneNumber = editProfileModel.userAccount?.result?.phoneNumber;
          globals.isCurrentPassword = _login_result["userAccount"]["result"]["isCurrentPassword"];
          globals.preferredCurrency = editProfileModel.userAccount?.result?.preferredCurrency ?? 'USD';
          if (editProfileModel.userAccount?.result?.walletBalance != null) {
            debugPrint("walletbalance: ${editProfileModel.userAccount?.result?.walletBalance}");
            globals.walletBalance.value = double.parse(editProfileModel.userAccount!.result!.walletBalance.toString());
          }
          if (editProfileModel.userAccount?.result?.emergencyContacts != null) {
            globals.contacts = editProfileModel.userAccount!.result!.emergencyContacts!;
          }
          globals.cardLastFour = editProfileModel.userAccount?.result?.cardLastFour;
          if (editProfileModel.userAccount?.result?.phoneCountryCode!.length == 2)
            globals.CountryCode = editProfileModel.userAccount!.result!.phoneCountryCode!;
          globals.DialCode = editProfileModel.userAccount?.result?.phoneDialCode ?? "";
          globals.preferredPaymentMethod = editProfileModel.userAccount!.result!.preferredPaymentMethod!;

          NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
          globals.currencySymbol = _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
          globals.currencySymbol = getCurrencySybmol(globals.preferredCurrency, globals.currencySymbol);
          List<SavedLocations>? saved = editProfileModel.userAccount?.result?.savedLocations;
          for (int i = 0; i < saved!.length; i++) {
            if (saved[i].locationType == "home") {

              setLocationDetails(selectLocationModel: SelectLocationModel(
                lat: double.parse(saved[i].lat.toString()),
                lng:  double.parse(saved[i].lng.toString()),
                selectLocationEnum: SelectLocationEnum.homeLocation,
                location: saved[i].location!,
                id: int.parse(saved[i].id.toString()),
                isValidLocation: double.parse(saved[i].lat.toString()) !=0.0 && double.parse(saved[i].lng.toString()) !=0.0,),
                selectLocationEnum:  SelectLocationEnum.homeLocation,);

            } else if (saved[i].locationType == "work") {
              setLocationDetails(selectLocationModel: SelectLocationModel(
                lat: double.parse(saved[i].lat.toString()),
                lng:  double.parse(saved[i].lng.toString()),
                selectLocationEnum: SelectLocationEnum.workLocation,
                location: saved[i].location!,
                id: int.parse(saved[i].id.toString()),
                isValidLocation: double.parse(saved[i].lat.toString()) !=0.0 && double.parse(saved[i].lng.toString()) !=0.0,),
                selectLocationEnum:  SelectLocationEnum.workLocation,);
            }
          }
          if (editProfileModel.userAccount?.result?.appTheme == "auto") {
            globals.theme = 1;
          } else if (editProfileModel.userAccount?.result?.appTheme == "light") {
            globals.theme = 2;
          } else {
            globals.theme = 3;
          }
         await getTripStatus();
          return "";
        }
        else if (_login_result["userAccount"]["status"] == 500) {
          return _login_result["userAccount"]["errorMessage"];
        } else {
          return _login_result["userAccount"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    } on Exception catch (e) {
      debugPrint("connection exception: ${e.toString()}");
      if (e
          .toString()
          .contains("SocketException: OS Error: Network is unreachable"))
        return "offline";
    }
  }


  Future<String?> getCurrencyRates() async {
    if (graphQlObject.graphQLClient != null) {
      try {
        globals.isContinuousLoading = true;
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClient, "getCurrencyRates_query", null);

        if(_currency_rates!=null) {
          if (_currency_rates["currency"]["status"] == 200) {
            globals.currencyRates =
            _currency_rates["currency"]["result"]["rates"];
            return "";
          }
        }else{
          getCurrencyRates();
        }

      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getCurrencyRates();
        });
      }
    } else {
      return "error";
    }
  }
  Future<String?> getSecureSiteSettings() async {

      final securityKey = await getSecurityKey();

      if (graphQlObject.graphQLClient == null) {
        return null;
      }

      final variables = <String, dynamic>{
        "securityKey": securityKey,
        "appType": "rider"
      };

      graphQlObject.graphQLClient.cache.store.reset();

      globals.isLoaderShow = false;
      globals.closeKeyBoard = false;
      globals.isContinuousLoading = true;

      final Map<String, dynamic>? result =
      await graphQlObject.getQueryValues(
        graphQlObject.graphQLClient,
        "getSecureSiteSettings",
        variables,
      );

      debugPrint("securesitesettings--result: ${result}");
      if (result == null) {
        return '';
      }

      final settings = result["getSecureSiteSettings"];

      if (settings["status"] == 200) {
        globals.phoneNumberStatus = settings["phoneNumberStatus"] ?? false;
        debugPrint("securesitesettings--result: ${editAccountController.languageDropDown} --- ${editAccountController.languageCode}");
          editAccountController.languageDropDown.clear();
          editAccountController.languageCode.clear();
          langCodeJson.clear();
          mobileLanguages.clear();
          settings["multipleMobileLanguage"].forEach((value) {
            if (value["isEnable"] == true) {
            editAccountController.languageDropDown.add(value["language"]);
            editAccountController.languageCode.add(value["languageCode"]);
            debugPrint("langs: ${editAccountController.languageDropDown}");
            langCodeJson.add(value["languageCode"]);
            mobileLanguages[value["languageCode"]] = MobileLanguage(
              language: value["language"],
              languageCode: value["languageCode"],
              languageJson: value["languageJson"],
              createdAt: value["createdAt"],
              updatedAt: value["updatedAt"],
            );
          }
          });

          debugPrint("securesitesettings--mobile: ${preferences.preferredLaunguage}");

          for (var item in settings["multipleMobileLanguage"]) {
            if(preferences.preferredLaunguage.isNotEmpty)
              globals.preferredLanguage = preferences.preferredLaunguage;
            if (globals.preferredLanguage.isEmpty) {
              if (item["isDefault"] == true && item["isEnable"] == true) {
                globals.preferredLanguage = item["languageCode"];
                preferences.preferredLaunguage = item["languageCode"];
                App().translations.readJson(language: globals.preferredLanguage,isOnlyDownload: false);
                isMatched =  true;
                break;
              }
            }
            else {
              if (item["languageCode"] == globals.preferredLanguage && item["isEnable"] == true) {
                globals.preferredLanguage = item["languageCode"];
                preferences.preferredLaunguage = item["languageCode"];
                App().translations.readJson(language: globals.preferredLanguage,isOnlyDownload: false);
                isMatched =  true;
                break;
              }
            }
          }
          debugPrint("isMatched: ${isMatched} --- ${globals.preferredLanguage}");
          if(!isMatched &&  globals.preferredLanguage.isNotEmpty){
            for (var item in settings["multipleMobileLanguage"]) {
              debugPrint("isMatched: item ${item["isDefault"]} --- ${item["isEnable"]} --- ${item["languageCode"]}");
              if (item["isDefault"] == true && item["isEnable"] == true) {
                globals.preferredLanguage = item["languageCode"];
                preferences.preferredLaunguage = item["languageCode"];
                App().translations.readJson(language: globals.preferredLanguage,isOnlyDownload: false);
                isMatched =  true;
                Future.delayed(const Duration(milliseconds: 5000), () {
                  debugPrint("globals.auth: ${globals.authToken}");
                  editAccountController.updateProfileInfo(
                      "preferredLanguage", preferences.preferredLaunguage);
                });
                break;
              }
            }
          }
          
          editAccountController.setLanguage();


        for (final element in settings["results"]) {
          switch (element["name"]) {
            case "stripePublishableKey":
              globals.stripePublishableKey = element["value"];
              break;
            case "preferredDistanceType":
              globals.distanceType = element["value"];
              break;
            case "multipleStopsWaitingTime":
              globals.multipleStopWaitingTime = element["value"];
              break;
            case "contactPhoneNumber":
              globals.supportPhone = element["value"];
              break;
            case "contactEmail":
              globals.supportEmail = element["value"];
              break;
              case "driverLocationFetchInterval":
                globals.LocationFetchInterval = int.tryParse(settings["driverLocationFetchInterval"].toString()) ?? 0;
              break;
            case "notificationInterval":
              final dynamic value = element["value"];
              final String valString = value?.toString() ?? "";
              globals.notificationInterval = (double.parse(valString));
              break;
            case "whatsApp":
              globals.supportWhatsapp = element["value"];
              break;
            case "enableOTPFeature":
              globals.isEnableOTP = element["value"] == '1';
              break;
            case "riderAppAndroidMapApiKey":
              if (Platform.isAndroid) {
                globals.MAP_KEY = element["value"];
                setMapKey();
              }
              break;
            case "riderAppiOSMapApiKey":
              if (Platform.isIOS) {
                globals.MAP_KEY = element["value"];
                setMapKey();
              }
              break;
            case "isVoiceAIFeature":
              globals.isVoiceChatEnable = element["value"] == 'true';
              break;
            case "isVoiceTranslatorFeature":
              globals.isVoiceTranslatorEnable = element["value"] == 'true';
              break;
          }
        }

        if (!globals.isVoiceChatEnable) {
          globals.isVoiceTranslatorEnable = false;
        }
      }

      return "success";

  }

  Future<String> getTripStatus() async {
    globals.isLoaderShow = false;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? _tripstatusResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "tripStatus_query", null);

    debugPrint("_tripstatusResult: ${_tripstatusResult}");
    if (_tripstatusResult != null &&
        _tripstatusResult["GetTripStatus"]["status"] == 200) {
      globals.tripStatus = _tripstatusResult["GetTripStatus"]["result"]["tripStatus"];
      paymentStatus = _tripstatusResult["GetTripStatus"]["result"]["paymentStatus"];
       bookingId = _tripstatusResult["GetTripStatus"]["result"]["id"];

       debugPrint("splashController.isActiveBooking:: ${globals.tripStatus} --- ${paymentStatus}");
      isActiveBooking = (globals.tripStatus == "started" ||
          globals.tripStatus == "created" ||
          globals.tripStatus == "accepted" ||
          globals.tripStatus == "approved" ||
          (globals.tripStatus == "completed" &&
              paymentStatus != "completed") ||
          globals.tripStatus == "locationReached");

      return "success";
    } else {
      return _tripstatusResult !=null ?_tripstatusResult["GetTripStatus"]["errorMessage"] : 'offline';
    }
  }

}