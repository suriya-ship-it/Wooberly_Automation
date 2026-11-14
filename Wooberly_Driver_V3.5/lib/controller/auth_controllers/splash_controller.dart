import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/edit_profile_model.dart';
import 'package:wooberly_driver/models/payout_list_model.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import '../../models/mobile_language.dart';

class SplashController extends BaseController{
  var appVersionUpdateContoller = false.obs;
  EditAccountController editAccountController = Get.find();
  String phoneCountrycode = "";
  PayoutListModel? allPayouts;

  bool isMatched = false;
  bool _isLocationEnabled = true;

  Future<String> getProfileInfo() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    EditProfileModel? editProfileModel = null;
    globals.isEnableContinuousLoading = true;


    Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "userAccount_query", null);
    if (_login_result != null) {
      if (_login_result["userAccount"]["status"] == 200) {
        editProfileModel = EditProfileModel.fromJson(_login_result);
        if (editProfileModel.userAccount?.result?.vehicles != null) {
          globals.isVehicleDetailsReq = false;
          getPayouts();
          getCurrencyRates();
          globals.isActive = editProfileModel.userAccount?.result?.isActive ?? false;
          globals.firstname = editProfileModel.userAccount?.result?.firstName ?? "";
          globals.lastname = editProfileModel.userAccount?.result?.lastName ?? "";
          globals.email = editProfileModel.userAccount?.result?.email;
          globals.gender = editProfileModel.userAccount?.result?.gender;
          globals.aiPreferredLanguage = editProfileModel.userAccount?.result?.aiPreferredLanguage ?? "";
          globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
          if (editProfileModel.userAccount?.result?.picture != null) {
            globals.picture = globals.UPLOAD_URL +
                "/images/avatar/" +
                (editProfileModel.userAccount?.result?.picture ?? "");
          }
          globals.userid = editProfileModel.userAccount?.result?.userId ?? '';
          App().appPreference.userId = globals.userid;
          phoneCountrycode = globals.CountryCode =
              editProfileModel.userAccount?.result?.phoneCountryCode ?? "";
          globals.DialCode =
              editProfileModel.userAccount?.result?.phoneDialCode ?? "";
          globals.phnNo = (editProfileModel.userAccount?.result?.phoneNumber ?? "").replaceFirst(RegExp(r'^0+'), '');
          globals.preferredCurrency =
              editProfileModel.userAccount?.result?.preferredCurrency ?? "";
          globals.paypalCurrencyController.text = editProfileModel.userAccount?.result?.payPalPreferredCurrency ?? "";
          globals.driverStatus = editProfileModel.userAccount?.result?.userStatus ?? "";
          globals.loginTripStatus = editProfileModel.userAccount?.result?.tripStatus ?? "";

          debugPrint(" globals.loginTripStatus: ${ globals.loginTripStatus} --- ${_isLocationEnabled}");
          if (globals.loginTripStatus != "approved" &&
              globals.loginTripStatus != "started" &&
              globals.loginTripStatus != "locationReached" &&
              globals.loginTripStatus != "created" && globals.isActive) {
           globals.isActive = _isLocationEnabled;
          }

          NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
          globals.currencySymbol =
              _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
          globals.currencySymbol = getCurrencySybmol(globals.preferredCurrency, globals.currencySymbol);
          Map<String,dynamic> walletoptions = {};
          walletoptions.addAll(globals.driverWalletOptionController.value);
          walletoptions["walletBalance"] = editProfileModel.userAccount?.result?.driverWalletBalance;
          walletoptions["minimumWalletAmount"] = editProfileModel.userAccount?.result?.minimumWalletAmount;
          walletoptions["isDriverEligible"] = editProfileModel.userAccount?.result?.isDriverEligible;
          debugPrint("globals.driverStatus:eligible: splash:${globals.driverStatus} --- ${walletoptions}");
        if(!walletoptions["isDriverEligible"]  &&  walletoptions["driverWalletOption"] =="1") globals.driverStatus = globals.driverStatus+'_NotEligible';
        globals.driverWalletOptionController.value = walletoptions;

          if (editProfileModel.userAccount?.result?.licenceFront != null)
            globals.front = globals.UPLOAD_URL +
                "/images/license/" +
                (editProfileModel.userAccount?.result?.licenceFront ?? "");
          else
            App().appPreference.LicenceFront = '';
          if (editProfileModel.userAccount?.result?.licenceBack != null)
            globals.back = globals.UPLOAD_URL +
                "/images/license/" +
                (editProfileModel.userAccount?.result?.licenceBack ?? "");
          else
            App().appPreference.LicenceBack = '';
          if (editProfileModel.userAccount?.result?.vehicles?.vehicleRC != null)
            globals.RC = globals.UPLOAD_URL +
                "/images/vehicle/" +
                (editProfileModel.userAccount?.result?.vehicles?.vehicleRC ??
                    "");
          else
            App().appPreference.vehicleRC = '';
          if (editProfileModel
                  .userAccount?.result?.vehicles?.vehicleInsurance !=
              null)
            globals.Insurance = globals.UPLOAD_URL +
                "/images/vehicle/" +
                (editProfileModel
                        ?.userAccount?.result?.vehicles?.vehicleInsurance ??
                    "");
          else
            App().appPreference.vehicleInsurance = '';
          globals.vehicleType = editProfileModel.userAccount?.result?.vehicles
                  ?.vehicleCategoryDetails?.categoryName ??
              "";

          globals.categoryImage = await getImage(editProfileModel
                  .userAccount
                  ?.result
                  ?.vehicles
                  ?.vehicleCategoryDetails
                  ?.categoryMarkerImage ??
              "");
          globals.vehicleImage = globals.UPLOAD_URL +
              "/images/category/" +
              (editProfileModel.userAccount?.result?.vehicles
                      ?.vehicleCategoryDetails?.categoryImage ??
                  "");
          globals.vehicleName =
              (editProfileModel.userAccount?.result?.vehicles?.vehicleName ??
                  "");
          globals.vehicleNumber =
              (editProfileModel.userAccount?.result?.vehicles?.vehicleNumber ??
                  "");
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
              editProfileModel.userAccount?.result?.vehicles?.vehicleColor ??
                  "";
          globals.isChildSeatAvailable =
              editProfileModel.userAccount?.result?.vehicles?.isChildSeat ??
                  false;
          globals.isWheelChairAvailable =
              editProfileModel.userAccount?.result?.vehicles?.isWheelChair ??
                  false;
          globals.idVehicleToUpdate =
              editProfileModel?.userAccount?.result?.vehicles?.id ?? 0;
          globals.vehicleId = int.parse(
              editProfileModel?.userAccount?.result?.vehicles?.vehicleType ??
                  "0");
        }
        else {
          globals.isVehicleDetailsReq = true;
        }

        if (editProfileModel.userAccount?.result?.appTheme == "auto") {
          globals.theme.value = 1;
        } else if (editProfileModel.userAccount?.result?.appTheme == "light") {
          globals.theme.value = 2;
        } else {
          globals.theme.value = 3;
        }
        if(globals.paypalCurrencies.isEmpty)
          getCurrencyList();

        return "";
      }
      if (_login_result["userAccount"]["status"] == 500) {
        return _login_result["userAccount"]["errorMessage"];
      } else {
        return _login_result["userAccount"]["errorMessage"];
      }
    } else {
      return "offline";
    }
  }

  Future<String?> getPayouts() async {
    globals.isEnableContinuousLoading = true;
    globals.isLoaderShow =
        globals.authToken != null && (globals.authToken?.isNotEmpty ?? false);
    Map<String, dynamic>? _payout_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getPayouts_query", null);

    if (_payout_result != null) {
      if (_payout_result["getPayouts"]["status"] == 200) {
        allPayouts = PayoutListModel.fromJson(_payout_result);
        if ((allPayouts?.getPayouts?.results?.length ?? 0) > 0) {
          globals.payout = 1;
          for (int i = 0;
              i < (allPayouts?.getPayouts?.results?.length ?? 0);
              i++) {
            if ((allPayouts?.getPayouts?.results?[i].isVerified ?? false) ||
                (allPayouts?.getPayouts?.results?[i].defaultpayout ?? false)) {
              globals.isPayout = true;
            }
          }
        } else {
          globals.payout = 0;
          globals.isPayout = false;
        }
        return "";
      } else {
        return _payout_result["getPayouts"]["errorMessage"];
      }
    }
  }



  getCurrencyRates() async {
    graphQlObject.getGraphQlClientWithHeader();
    globals.isEnableContinuousLoading = true;
    globals.isLoaderShow =
        globals.authToken != null && (globals.authToken?.isNotEmpty ?? false);
    Map<String, dynamic>? _currency_rates = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getCurrencyRates_query", null);
    if (_currency_rates != null) {
      if (_currency_rates["currency"]["status"] == 200) {
        globals.currencyRates = _currency_rates["currency"]["result"]["rates"];
        globals.baseCurrency = _currency_rates["currency"]["result"]["base"];
      }
    } else {
      getCurrencyRates();
    }
  }

  getDeviceDetails() {
    try {
      if (Platform.isAndroid) {
        globals.deviceName = "android";
      } else if (Platform.isIOS) {
        globals.deviceName = "ios";
      }
      graphQlObject.getGraphQlClientWithHeader();
    }  on Exception catch (e, stack) {
      debugPrint("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
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
      debugPrint("globals.authTokengetUpdatedVersion: getUpdatedVersion ${variables}");
      try {
        globals.isLoaderShow = globals.authToken != null &&
            (globals.authToken?.isNotEmpty ?? false);

        if (globals.isLoaderShow) globals.isEnableContinuousLoading = true;
        Map<String, dynamic>? _updated_version =
            await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
                "getApplicationVersionInfo_query", variables);
        debugPrint("globals.authTokengetUpdatedVersion: _updated_version ${_updated_version}");
        if (_updated_version != null) {
          if (_updated_version["getApplicationVersionInfo"]["status"] == 400) {
            if (_updated_version["getApplicationVersionInfo"]["result"] !=
                null) {
              globals.playStoreURL =
                  _updated_version["getApplicationVersionInfo"]["result"]
                      ["playStoreURL"]["driver"];
              globals.appStoreURL =
                  _updated_version["getApplicationVersionInfo"]["result"]
                      ["appStoreURL"]["driver"];
            }
            return _updated_version["getApplicationVersionInfo"]
                ["errorMessage"];
          } else {
            return "";
          }
        } else {
          return "offline";
        }
      }  on Exception catch (e, stack) {
        debugPrint("Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
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

  Future<String?> getPaymentSettings() async {
    debugPrint("getPaymentSettings getmapkey spalsh: ${globals.MAP_KEY}");
    globals.isLoaderShow = false;
    App().getSecurityKey().then((securityKey) async {
      if (graphQlObject.graphQLClient != null) {
        var variables = <String, dynamic>{
          "securityKey": securityKey,
          "appType": "driver"
        };
        graphQlObject.graphQLClient.cache.store.reset();
        try {
          Map<String, dynamic>? paymentResult =
              await graphQlObject.getQueryValues(graphQlObject.graphQLClient, "getSecureSiteSettings", variables);
          if (paymentResult != null) {
            if (paymentResult["getSecureSiteSettings"]["status"] == 200) {
              globals.phoneNumberStatus = paymentResult["getSecureSiteSettings"]["phoneNumberStatus"] ?? false;
              globals.downloadedLanguages = App().appPreference.downloadedLanguages.split(",").toSet();
              globals.langCodeJson.clear();
              globals.mobileLanguages.clear();
              paymentResult["getSecureSiteSettings"]["multipleMobileLanguage"].forEach((value) {
                if (value["isEnable"] == true) {
                  editAccountController.languageDropDown.add(value["language"]);
                  editAccountController.languageCode.add(value["languageCode"]);
                  globals.langCodeJson.add(value["languageCode"]);
                  globals.mobileLanguages[value["languageCode"]] = MobileLanguage(
                    language: value["language"],
                    languageCode: value["languageCode"],
                    languageJson: value["languageJson"],
                    createdAt: value["createdAt"],
                    updatedAt: value["updatedAt"],
                  );
                }
              });
              for (var item in paymentResult["getSecureSiteSettings"]["multipleMobileLanguage"]) {
                if(App().appPreference.preferredLanguage.isNotEmpty)
                  globals.preferredLanguage.value = App().appPreference.preferredLanguage;
                if (globals.preferredLanguage.value.isEmpty) {
                  if (item["isDefault"] == true && item["isEnable"] == true) {
                    globals.preferredLanguage.value = item["languageCode"];
                    App().appPreference.preferredLanguage = item["languageCode"];
                    App().localizationService.readJson(language: globals.preferredLanguage.value,isDownloadOnly: false);
                    isMatched =  true;
                    break;
                  }
                }
                else {
                  if (item["languageCode"] == globals.preferredLanguage.value && item["isEnable"] == true) {
                    globals.preferredLanguage.value = item["languageCode"];
                    App().appPreference.preferredLanguage = item["languageCode"];
                    App().localizationService.readJson(language: globals.preferredLanguage.value,isDownloadOnly: false);
                    isMatched =  true;
                    break;
                  }
                }
              }
              if(!isMatched &&  globals.preferredLanguage.value.isNotEmpty){
                for (var item in paymentResult["getSecureSiteSettings"]["multipleMobileLanguage"]) {
                  if (item["isDefault"] == true && item["isEnable"] == true) {
                    globals.preferredLanguage.value = item["languageCode"];
                    App().appPreference.preferredLanguage = item["languageCode"];
                    App().localizationService.readJson(language: globals.preferredLanguage.value,isDownloadOnly: false);
                    isMatched =  true;
                    Future.delayed(const Duration(milliseconds: 5000), () {
                      debugPrint("globals.auth: ${globals.authToken}");
                      editAccountController.updateProfileInfo(
                          "preferredLanguage", App().appPreference.preferredLanguage);
                    });
                    break;
                  }
                }
              }
              editAccountController.setLanguage();
              Map<String,dynamic> walletoption = {};
              walletoption.addAll(globals.driverWalletOptionController.value);
              final results = paymentResult["getSecureSiteSettings"]?["results"];

              if (results is Iterable) {
                // 1. Convert the list of elements into a clean, searchable Map
                final settings = {
                  for (var element in results)
                    if (element is Map && element["name"] != null)
                      element["name"]: element["value"]
                };

                // 2. Extract and assign global values safely
                globals.stripePublishableKey = settings["stripePublishableKey"];
                globals.distanceType         = settings["preferredDistanceType"];
                globals.startRideRadius      = settings["startRideRadius"];
                globals.supportPhone         = settings["contactPhoneNumber"];
                globals.supportEmail         = settings["contactEmail"];
                globals.supportWhatsapp      = settings["whatsApp"];

                // Boolean Flags ('1' mappings)
                globals.showDistance       = settings["distance"] == "1";
                globals.showDuration       = settings["duration"] == "1";
                globals.showEstimatedFare  = settings["estimatedPrice"] == "1";
                globals.showPickUpLocation = settings["pickupLocation"] == "1";
                globals.showDropLocation    = settings["destinationLocation"] == "1";
                globals.playTripSound      = settings["isTripTimerToneEnable"] == "1";
                globals.isBringAppToForeGround = settings["openAppOnTrip"] == "1";
                globals.isEnableOTP        = settings["enableOTPFeature"] == "1";

                // Boolean Flags ('true' mappings)
                globals.isVoiceChatEnable       = settings["isVoiceAIFeature"] == 'true';
                globals.isVoiceTranslatorEnable = settings["isVoiceTranslatorFeature"] == 'true';

                // Wallet updates
                if (settings.containsKey("driverWalletOption")) {
                  walletoption["driverWalletOption"] = settings["driverWalletOption"];
                }
                if (settings.containsKey("walletFlow")) {
                  walletoption["walletFlow"] = settings["walletFlow"];
                }

                // Parsed Numbers
                if (settings["notificationInterval"] != null) {
                  final intervalMinutes = double.tryParse(settings["notificationInterval"].toString()) ?? 0;
                  globals.notificationInterval = (intervalMinutes * 60).round();
                }

                if (settings["driverLocationFetchInterval"] != null) {
                  globals.locationFetchInterval = int.tryParse(settings["driverLocationFetchInterval"].toString()) ?? 0;
                }

                // Complex String URLs
                final tripTone = settings["tripTimeTone"];
                if (tripTone != null) {
                  final toneStr = tripTone.toString();
                  globals.tripAudioURL = toneStr.contains("http")
                      ? toneStr
                      : "${globals.UPLOAD_URL}/images/tripTone/$toneStr";
                }

                // Platform Specific Settings (Evaluated cleanly without loops)
                if (Platform.isAndroid) {
                  globals.screenAwake = settings["sleepDriverAndroid"];
                  if (settings["driverAppAndroidMapApiKey"] != null) {
                    globals.MAP_KEY = settings["driverAppAndroidMapApiKey"];
                    App().setMapKey();
                  }
                } else if (Platform.isIOS) {
                  globals.screenAwake = settings["sleepDriverios"];
                  if (settings["driverAppiOSMapApiKey"] != null) {
                    globals.MAP_KEY = settings["driverAppiOSMapApiKey"];
                    App().setMapKey();
                  }
                }
              }


              print("selected index:::${globals.isVoiceChatEnable} ${globals.isVoiceTranslatorEnable}");
              globals.showLocations =
                  globals.showPickUpLocation || globals.showDropLocation;

               globals.progressLoadTime = globals.notificationInterval;
              debugPrint("walletoption: ${walletoption}");

              if((walletoption["isDriverEligible"] !=null && !walletoption["isDriverEligible"]  &&  walletoption["driverWalletOption"] =="1")??false)
                globals.driverStatus = globals.driverStatus+'_NotEligible';
              globals.driverWalletOptionController.value = walletoption;
              App().getAudioPlayerCache();
              return "";
            } else {
              return "null";
            }
          } else {
            getPaymentSettings();
          }
        }  on Exception catch (e, stack) {
          debugPrint("Error: $e");
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }
    });
  }

  void checkLocationPermission() {
    isLocationPermissionsEnabled().then((value){
      _isLocationEnabled = value;
    });
  }
}