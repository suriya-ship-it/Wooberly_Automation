import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:async/async.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/edit_profile_model.dart';
import 'package:wooberly_driver/models/upload_model.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/resources/values/app_lang.dart' as lang;

class DocumentController extends BaseController {
  var rxLoadingController = ReactiveVariable("rxLoadingController", false);
  var rxButtonController = ReactiveVariable("rxButtonController", false);
  var rxImageRefreshController = false.obs;
  bool documentFront = false;
  bool documentBack = false;
  bool rcBook = false;
  bool insurance = false;
  String imageFront = "", imageBack = "", imageRC = "", imageInsu = "";

  String selectedImage = "";
  String documentType = "", uploadDocumentType = "";

  late UploadModel model;

  Future<String?> uploadMultipart(File imageFile,
      [String type = "", String uploadURL = ""]) async {
    setLoadingController(true);
    if (documentType.compareTo(lang.document_front.tr) == 0) {
      type = "front";
      uploadURL = "${globals.UPLOAD_URL}/uploadLicence";
    } else if (documentType.compareTo(lang.document_back.tr) == 0) {
      type = "back";
      uploadURL = "${globals.UPLOAD_URL}/uploadLicence";
    } else if (documentType.compareTo(lang.rc_book.tr) == 0) {
      type = "vehicleRC";
      uploadURL = "${globals.UPLOAD_URL}/uploadVehicle";
    } else if (documentType.compareTo(lang.insurance.tr) == 0) {
      type = "vehicleInsurance";
      uploadURL = "${globals.UPLOAD_URL}/uploadVehicle";
    } else {
      uploadURL = "${globals.UPLOAD_URL}/uploadVehicleImage";
    }

    uploadDocumentType = documentType;
    var stream = new http.ByteStream(imageFile.openRead());
    stream.cast();
    var length = await imageFile.length();
    String ext = imageFile.path.split(".").last;

    var uri = Uri.parse(uploadURL);
    Map<String, String> headers = {"auth": globals.authToken!};

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
        contentType: new MediaType("image", ext),
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
    if (type.isNotEmpty) {
      request.headers.addAll(headers);
      request.fields['type'] = type;
    }
    http.Response response;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        response = await http.Response.fromStream(await request.send());
      } else {
        change(rxVariable: rxButtonController, value: true);
        setLoadingController(false);
        return "Offline";
      }
      if(response.statusCode==413){
        if (type.compareTo("front") == 0) {
          App().appPreference.isDoc = '';
        } else if (type.compareTo("back") == 0) {
          App().appPreference.backPath = '';
        } else if (type.compareTo("vehicleInsurance") == 0) {
          App().appPreference.insuPath = '';
        } else if (type.compareTo("vehicleRC") == 0) {
          App().appPreference.rcPath = '';
        }else{
          selectedImage="";
          globals.vehicleImagePath="";
          WidgetsFlutterBinding.ensureInitialized().performReassemble();
        }
        setLoadingController(false);
        return response.reasonPhrase;
      }
      final _result = json.decode(response.body);
      model = UploadModel.fromJson(_result);
      if (model.status == 200) {
        String uploadedImage = '';
        if (type.isNotEmpty)
          uploadedImage = globals.UPLOAD_URL + "/" + model.files![0].path!;

        if (uploadDocumentType == documentType) selectedImage = uploadedImage;

        if (type.compareTo("front") == 0) {
          App().appPreference.isDoc = uploadedImage;
        } else if (type.compareTo("back") == 0) {
          App().appPreference.backPath = uploadedImage;
        } else if (type.compareTo("vehicleInsurance") == 0) {
          App().appPreference.insuPath = uploadedImage;
        } else if (type.compareTo("vehicleRC") == 0) {
          App().appPreference.rcPath = uploadedImage;
        } else {
          selectedImage =
              globals.UPLOAD_URL + "/images/vehicle/" + model.fileName!;
          globals.vehicleImagePath = model.fileName!;
        }
        rxImageRefreshController.value = true;
        change(rxVariable: rxButtonController, value: true);
        setLoadingController(false);
        update();
        return "";
      } else if (model.status == 400) {
        setLoadingController(false);
        return _result["errorMessage"];
      }
    } on SocketException catch (_) {
      change(rxVariable: rxButtonController, value: true);
      setLoadingController(false);
      return "Offline";
    } on Exception catch (_) {
      change(rxVariable: rxButtonController, value: true);
      setLoadingController(false);
      return "Offline";
    }
  }

  Future<String> getProfileInfo() async {
    globals.isLoaderShow = true;
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isEnableContinuousLoading = true;

    Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "userAccount_query", null);

    if (_login_result?["userAccount"]["status"] == 200) {
      EditProfileModel editProfileModel =
          EditProfileModel.fromJson(_login_result!);

      globals.driverStatus =
          editProfileModel.userAccount?.result?.userStatus ?? "";
      globals.paypalCurrencyController.text = editProfileModel.userAccount?.result?.payPalPreferredCurrency ?? "";
      globals.isActive = editProfileModel.userAccount?.result?.isActive ?? false;

      globals.firstname = editProfileModel.userAccount?.result?.firstName ?? "";
      globals.lastname = editProfileModel.userAccount?.result?.lastName ?? "";
      globals.email = editProfileModel.userAccount?.result?.email;
      globals.preferredLanguage.value =
          editProfileModel.userAccount?.result?.preferredLanguage ??
              globals.defaultLanguageCode;
      globals.isRtlLang =
          intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
      App().appPreference.preferredLanguage = globals.preferredLanguage.value;

      if (editProfileModel.userAccount?.result?.picture != null) {
        globals.picture = editProfileModel.userAccount?.result?.picture ?? "";
      }
      globals.CountryCode =
          editProfileModel.userAccount?.result?.phoneCountryCode ?? "";
      Map<String, dynamic> walletoptions = {};
      walletoptions.addAll(globals.driverWalletOptionController.value);
      walletoptions["walletBalance"] =
          editProfileModel.userAccount?.result?.driverWalletBalance;
      walletoptions["minimumWalletAmount"] =
          editProfileModel.userAccount?.result?.minimumWalletAmount;
      walletoptions["isDriverEligible"] =
          editProfileModel.userAccount?.result?.isDriverEligible;
      globals.driverWalletOptionController.value = walletoptions;
      globals.gender = editProfileModel.userAccount?.result?.gender;
      globals.preferredCurrency =
          editProfileModel.userAccount?.result?.preferredCurrency ?? "";
      globals.driverStatus =
          editProfileModel.userAccount?.result?.userStatus ?? "";
      if (!walletoptions["isDriverEligible"] &&  walletoptions["driverWalletOption"] =="1")
        globals.driverStatus = globals.driverStatus + '_NotEligible';
      debugPrint("globals.driverStatus:eligible: ${globals.driverStatus} --- ${walletoptions}");
      globals.phnNo = (editProfileModel.userAccount?.result?.phoneNumber ?? '').replaceFirst(RegExp(r'^0+'), '');
      globals.isPayout = false;
      NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
      globals.currencySymbol =
          _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
      globals.currencySymbol =
          getCurrencySybmol(globals.preferredCurrency, globals.currencySymbol);
          editProfileModel.userAccount?.result?.contactPhoneNumber ?? "";
      globals.supportEmail =
          editProfileModel.userAccount?.result?.contactEmail ?? "";
      if (editProfileModel.userAccount?.result?.licenceFront != null)
        globals.front = globals.UPLOAD_URL +
            "/images/license/" +
            (editProfileModel.userAccount?.result?.licenceFront ?? "");
      if (editProfileModel.userAccount?.result?.licenceBack != null)
        globals.back = globals.UPLOAD_URL +
            "/images/license/" +
            (editProfileModel.userAccount?.result?.licenceBack ?? "");
      if (editProfileModel.userAccount?.result?.vehicles?.vehicleRC != null)
        globals.RC = globals.UPLOAD_URL +
            "/images/vehicle/" +
            (editProfileModel.userAccount?.result?.vehicles?.vehicleRC ?? "");
      if (editProfileModel.userAccount?.result?.vehicles?.vehicleInsurance !=
          null)
        globals.Insurance = globals.UPLOAD_URL +
            "/images/vehicle/" +
            (editProfileModel.userAccount?.result?.vehicles?.vehicleInsurance ??
                "");
      globals.vehicleType = editProfileModel.userAccount?.result?.vehicles
              ?.vehicleCategoryDetails?.categoryName ??
          "";
      globals.categoryImage = await getImage(editProfileModel.userAccount
              ?.result?.vehicles?.vehicleCategoryDetails?.categoryMarkerImage ??
          "");
      if (editProfileModel.userAccount?.result?.vehicles?.vehicleCategoryDetails
              ?.categoryImage !=
          null)
        globals.vehicleImage = globals.UPLOAD_URL +
            "/images/category/" +
            (editProfileModel?.userAccount?.result?.vehicles
                    ?.vehicleCategoryDetails?.categoryImage ??
                "");

      globals.vehicleName =
          editProfileModel.userAccount?.result?.vehicles?.vehicleName ?? "";
      globals.vehicleNumber =
          (editProfileModel.userAccount?.result?.vehicles?.vehicleNumber ?? "")
              .toUpperCase();
      globals.vehicleYear =
          (editProfileModel.userAccount?.result?.vehicles?.vehicleMakeYear ??
              "");
      globals.vehiclePhoto =
          (editProfileModel.userAccount?.result?.vehicles?.vehicleImage ?? "");
      globals.vehicleModel =
          (editProfileModel.userAccount?.result?.vehicles?.vehicleModal ?? "");
      globals.vehicleColor =
          editProfileModel.userAccount?.result?.vehicles?.vehicleColor ?? "";
      globals.isChildSeatAvailable =
          editProfileModel.userAccount?.result?.vehicles?.isChildSeat ?? false;
      globals.isWheelChairAvailable =
          editProfileModel.userAccount?.result?.vehicles?.isWheelChair ?? false;
      globals.idVehicleToUpdate =
          editProfileModel.userAccount?.result?.vehicles?.id ?? 0;
      globals.vehicleId = int.parse(
          editProfileModel.userAccount?.result?.vehicles?.vehicleType ?? "0");
      globals.vehicleNumber = globals.vehicleNumber.toString().toUpperCase();
      if (editProfileModel.userAccount?.result?.appTheme == "auto") {
        globals.theme.value = 1;
      } else if (editProfileModel.userAccount?.result?.appTheme == "light") {
        globals.theme.value = 2;
      } else {
        globals.theme.value = 3;
      }
      getPaymentSettings();
      if(globals.paypalCurrencies.isEmpty)
        getCurrencyList();
      return "";
    } else if (_login_result?["userAccount"]["status"] == 500) {
      return "timeout";
    } else {
      return _login_result?["userAccount"]["errorMessage"];
    }
  }


  Future<String> userLogout() async {
    var variables = <String, dynamic>{
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };

    Map<String, dynamic>? _logout_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader, "user_logout", variables);

    if (_logout_result?["userLogout"]["status"] == 200) {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      graphQlObject.graphQLClient.cache.store.reset();

      return "";
    } else {
      return _logout_result?["userLogout"]["errorMessage"];
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
          if (paymentResult?["getSecureSiteSettings"]?["status"] == 200) {
            // Use map spreading to create a clean, mutable copy
            final Map<String, dynamic> walletOption = {
              ...globals.driverWalletOptionController.value
            };

            final List? results = paymentResult?["getSecureSiteSettings"]?["results"];

            if (results != null) {
              for (final element in results) {
                final String? name = element["name"];
                final dynamic value = element["value"];
                final String valString = value?.toString() ?? "";

                switch (name) {
                  case "stripePublishableKey":
                    globals.stripePublishableKey = value;
                  case "preferredDistanceType":
                    globals.distanceType = value;
                  case "startRideRadius":
                    globals.startRideRadius = value;
                  case "contactPhoneNumber":
                    globals.supportPhone = value;
                  case "contactEmail":
                    globals.supportEmail = value;
                  case "whatsApp":
                    globals.supportWhatsapp = value;
                  case "notificationInterval":
                    globals.notificationInterval = (double.parse(valString) * 60).round();
                  case "tripTimeTone":
                    if (value != null) {
                      globals.tripAudioURL = valString.contains("http")
                          ? valString
                          : "${globals.UPLOAD_URL}/images/tripTone/$valString";
                    }
                  case "distance":
                    globals.showDistance = valString == "1";
                  case "duration":
                    globals.showDuration = valString == "1";
                  case "estimatedPrice":
                    globals.showEstimatedFare = valString == "1";
                  case "pickupLocation":
                    globals.showPickUpLocation = valString == "1";
                  case "destinationLocation":
                    globals.showDropLocation = valString == "1";
                  case "isTripTimerToneEnable":
                    globals.playTripSound = valString == "1";
                  case "openAppOnTrip":
                    globals.isBringAppToForeGround = valString == "1";
                  case "enableOTPFeature":
                    globals.isEnableOTP = valString == "1";
                  case "isVoiceAIFeature":
                    globals.isVoiceChatEnable = valString == "true";
                  case "isVoiceTranslatorFeature":
                    globals.isVoiceTranslatorEnable = valString == "true";
                  case "driverWalletOption":
                    walletOption["driverWalletOption"] = value;
                  case "walletFlow":
                    walletOption["walletFlow"] = value;
                  case "driverAppAndroidMapApiKey" when Platform.isAndroid:
                  case "driverAppiOSMapApiKey" when Platform.isIOS:
                    globals.MAP_KEY = value;
                    App().setMapKey();
                  case "sleepDriverAndroid" when Platform.isAndroid:
                  case "sleepDriverios" when Platform.isIOS:
                    globals.screenAwake = value;
                }
              }
            }

            // Update dependencies and state
            globals.showLocations = globals.showPickUpLocation || globals.showDropLocation;
            globals.driverWalletOptionController.value = walletOption;
            globals.progressLoadTime = globals.notificationInterval;
            App().getAudioPlayerCache();

            return "";
          }

          else {
            return "null";
          }
        }  on Exception catch (e, stack) {
          debugPrint("Error: $e");
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }
    });
  }

  Future<BitmapDescriptor> getImage(String imageURL) async {
    http.Response response = await http.get(
      Uri.parse(globals.UPLOAD_URL + "/images/category/" + imageURL),
    );
    ui.Codec codec =
        await ui.instantiateImageCodec(response.bodyBytes, targetHeight: 120);
    ui.FrameInfo fi = await codec.getNextFrame();
    Uint8List? markericon =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))
            ?.buffer
            .asUint8List();
    return BitmapDescriptor.bytes(markericon!,
        imagePixelRatio: globals.markerImagePixelRatio);
  }


  void setLoadingController(bool param0) {
    final point=StackTrace.current.toString().split('\n')[1];
    change(rxVariable: rxLoadingController, value: param0);
  }
}