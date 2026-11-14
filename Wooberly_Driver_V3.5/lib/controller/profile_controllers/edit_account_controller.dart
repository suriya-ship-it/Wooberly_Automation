import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/currency_model.dart';
import 'package:wooberly_driver/models/edit_profile_model.dart';
import 'package:wooberly_driver/models/upload_model.dart';

import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../resources/values/app_lang.dart';

class EditAccountController extends BaseController{
  String email = "";
  String mobile = "";
  String password = "12345678";
  String? profileImage = null;

  var firstNameController;
  var lastNameController;
  var emailController;
  var passwordController;
  var passwordEditController;
  var newPasswordEditController;
  var conFirmPasswordEditController;

  var passwordFocusNode = new FocusNode();
  var firstNameFocusNode = new FocusNode();
  var lastNameFocusNode = new FocusNode();
  var newPasswordFocusNode = new FocusNode();
  var confirmPasswordFocusNode = new FocusNode();

  UploadModel? model;

  var rxLoadingController = ReactiveVariable("rxLoadingController", false);
  var rxCursorControlController = ReactiveVariable("rxCursorControlController", false);
  var rxSaveController = ReactiveVariable("rxSaveController", 0);
  var rxGetUpdatedDetailsController = ReactiveVariable("rxGetUpdatedDetailsController", true);
  var rxChildSeatController = ReactiveVariable("rxChildSeatController", globals.isChildSeatAvailable);
  var rxWheelChairController = ReactiveVariable("rxWheelChairController", globals.isWheelChairAvailable);
  var rxCurrencyListController = ReactiveVariable("rxCurrencyListController", false);
  RxList<dynamic> getMobileLanguageList = [].obs;

  var currencyController, languageController, preferredController;
  final List<String> currencyDropDown = [];
  List<String> languageDropDown = [];
  List<String> languageCode = [];
  List<String> preferredLanguageCode = ["en", "es", "fr", "id", "ja", "ru", "hr", "ar"];
  int langPos = 0;
  bool isSpaceAllow = false;
  bool movetosetting = false;

  RxInt index = 0.obs;

  @override
  void onInit() {
    currencyController = TextEditingController();
    languageController = TextEditingController();
    preferredController = TextEditingController();
    if (globals.preferredCurrency.isNotEmpty) {
      currencyController.text = globals.currencySymbol + " - " + globals.preferredCurrency;
    }
    init();
    super.onInit();
  }

  void init() {
    passwordController = TextEditingController(text: password);
    if (globals.email != null) email = globals.email ?? "";
    if (globals.phnNo != null) mobile = (globals.phnNo ?? "").replaceFirst(RegExp(r'^0+'), '');

    setFirstNameObserver();
    setLastNameObserver();
    setEmailObserver();
    setPasswordObserver();
  }

  void setLoadingController(bool param0) {
    change(rxVariable: rxLoadingController, value: param0);
  }

  void setFirstNameObserver() {
    firstNameController = TextEditingController();
    if (globals.brandName.toLowerCase() == "samsung") {
      firstNameController.addListener(() {
        String fname = firstNameController.text.toString();
        if (fname[0] == " ") firstNameController.text = "";
        if (fname[fname.length - 1] == " " &&
            firstNameFocusNode.hasFocus &&
            isSpaceAllow) {
          change(rxVariable: rxCursorControlController, value: false);
          firstNameController.text = fname.substring(0, fname.length - 1);
          Future.delayed(const Duration(milliseconds: 150), () {
            change(rxVariable: rxCursorControlController, value: true);
            firstNameController
              ..selection =
                  TextSelection.collapsed(offset: globals.firstname.length);
          });
          isSpaceAllow = false;
        }
      });
    } else {
      firstNameController.addListener(() {
        String fname = firstNameController.text.toString();

        if (fname[0] == " ") firstNameController.text = "";
        change(rxVariable: rxCursorControlController, value: true);
      });
    }
  }

  void setLastNameObserver() {
    lastNameController = TextEditingController();
    if (globals.brandName.toLowerCase() == "samsung") {
      lastNameController.addListener(() {
        String lname = lastNameController.text.toString();

        if (lname[0] == " ") lastNameController.text = "";
        if (lname[lname.length - 1] == " " &&
            lastNameFocusNode.hasFocus &&
            isSpaceAllow) {
          change(rxVariable: rxCursorControlController, value: false);
          lastNameController.text = lname.substring(0, lname.length - 1);
          Future.delayed(const Duration(milliseconds: 150), () {
            change(rxVariable: rxCursorControlController, value: true);
            lastNameController
              ..selection =
                  TextSelection.collapsed(offset: globals.lastname.length);
          });

          isSpaceAllow = false;
        }
      });
    } else {
      lastNameController.addListener(() {
        String lname = lastNameController.text.toString();

        if (lname[0] == " ") lastNameController.text = "";
        change(rxVariable: rxCursorControlController, value: true);
      });
    }
  }

  void setEmailObserver() {
    emailController = TextEditingController(text: email);
  }

  void setPasswordObserver() {
    passwordEditController = TextEditingController();

    passwordEditController.addListener(() {
      if (passwordEditController.text.toString()[0] == " ")
        passwordEditController.text = "";
    });

    newPasswordEditController = TextEditingController();
    newPasswordEditController.addListener(() {
      if (newPasswordEditController.text.toString()[0] == " ")
        newPasswordEditController.text = "";
    });

    conFirmPasswordEditController = TextEditingController();
    conFirmPasswordEditController.addListener(() {
      if (conFirmPasswordEditController.text.toString()[0] == " ")
        conFirmPasswordEditController.text = "";
    });
  }

  Future<dynamic> getCurrencyList() async {

    int index = languageCode.indexOf(globals.preferredLanguage.value);
    String selectedLanguage = languageDropDown[index];
    languageDropDown.removeAt(index);
    languageCode.removeAt(index);

    languageDropDown.insert(0, selectedLanguage);
    languageCode.insert(0, globals.preferredLanguage.value);

    preferredLanguageCode.insert(0, globals.aiPreferredLanguage);

    if (globals.currencyModel == null) {
      Map<String, dynamic>? _currency_result =
          await graphQlObject.getQueryValues(
              graphQlObject.graphQLClientWithHeader,
              "getAllCurrencies_query",
              null);
      if (_currency_result == null) return null;
      globals.currencyModel = CurrencyModel.fromJson(_currency_result);
    }

    if (globals.currencyModel?.getAllCurrencies?.status?.compareTo("200") ==
        0) {
      List<CurrencyResults> result =
          globals.currencyModel?.getAllCurrencies?.results ?? [];
      NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
      for (int i = 0; i < result.length; i++) {
        if (result[i].isEnable == true) {
          String currencySymbol =
              _numberFormat.simpleCurrencySymbol(result[i].symbol!);
          currencySymbol = getCurrencySybmol(result[i].symbol!, currencySymbol);
          String currencyValue = currencySymbol + " - " + result[i].symbol!;
          if (currencyValue != currencyController.text)
            currencyDropDown.add(currencyValue);
          else
            currencyDropDown.insert(0, currencyValue);
        }
      }

      change(rxVariable: rxCurrencyListController, value: true);
    }
    await globals.baseController.getAILanguageList();
    return "";
  }

  Future<String> updateProfileInfo(String fieldName, String fieldValue) async {
    try {
      change(rxVariable: rxCurrencyListController, value: false);
      var variables = <String, dynamic>{
        "userId": globals.userid,
        "fieldName": fieldName,
        "fieldValue": fieldValue,
        "deviceType": globals.deviceName,
        "deviceId": globals.deviceId
      };
      Map<String, dynamic>? _login_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "userUpdate_mutation",
              variables);
      if (_login_result != null) {
        if (_login_result["userUpdate"]["status"] == 200) {
          if (fieldName == "preferredCurrency") {
            globals.preferredCurrency =
                currencyController.text.toString().split("-")[1].trim();
            globals.currencyChanged.value = globals.preferredCurrency;
            NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
            globals.currencySymbol =
                _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
            globals.currencySymbol = getCurrencySybmol(
                globals.preferredCurrency, globals.currencySymbol);
          }
          return "";
        } else {
          return _login_result["userUpdate"]["errorMessage"];
        }
      } else {
        return "";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<bool?> getDriverWalletBalance() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.isLoaderShow = false;
    Map<String, dynamic>? result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getPreferredCurrency", null);
    debugPrint("checkIsDriverEligible: ${result}");
    if (result != null) {
      if (result["userAccount"]["status"] == 200) {
        Map<String, dynamic> walletoptions = {};
        walletoptions.addAll(globals.driverWalletOptionController.value);
        if (
        walletoptions["isDriverEligible"] != result["userAccount"]["result"]["isDriverEligible"] ||
            walletoptions["walletBalance"] != result["userAccount"]["result"]["driverWalletBalance"] ||
            walletoptions["minimumWalletAmount"] != result["userAccount"]["result"]["minimumWalletAmount"]
        ) {
          walletoptions["isDriverEligible"] =
          result["userAccount"]["result"]["isDriverEligible"];
          walletoptions["walletBalance"] =
          result["userAccount"]["result"]["driverWalletBalance"];
          walletoptions["minimumWalletAmount"] =
          result["userAccount"]["result"]["minimumWalletAmount"];
          globals.driverWalletOptionController.value = walletoptions;
        }
      }
    }
  }

  Future<String> uploadMultipart(
      File imageFile, String type, String uploadURL) async {
    setLoadingController(true);
    var stream  = new http.ByteStream(imageFile.openRead());
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
    request.headers.addAll(headers);
    http.Response response;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        response = await http.Response.fromStream(await request.send());
      } else {
        setLoadingController(false);
        return "Offline";
      }
      final _result = json.decode(response.body);
      model = UploadModel.fromJson(_result);
      if (model?.status == 200) {
        setLoadingController(false);
        profileImage = model?.files?[0].filename;
        return "";
      } else {
        setLoadingController(false);
        return _result["errorMessage"];
      }
    } on SocketException catch (_) {
      setLoadingController(false);
      return "Offline";
    } on Exception catch (_) {
      setLoadingController(false);
      return "Offline";
    }
  }

  Future<String> updatePassword() async {
    String oldPassword = passwordEditController.text.toString();
    String newPassword = newPasswordEditController.text.toString();
    var variables = <String, dynamic>{
      "oldPassword": oldPassword,
      "newPassword": newPassword
    };

    Map<String, dynamic>? _updatePassword_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "update_Password",
            variables);

    if (_updatePassword_result?["updateUserPassword"]["status"] == 200) {
      return "";
    } else {
      return _updatePassword_result?["updateUserPassword"]["errorMessage"];
    }
  }

  getAIPreferredLanguage() {
    if (getMobileLanguageList.isNotEmpty) {
      String selectedLanguage = getMobileLanguageList[index.value]["language"];
      preferredController.text = selectedLanguage;
      preferredLanguageCode.removeAt(langPos);
      preferredLanguageCode.insert(0, globals.aiPreferredLanguage);
      return preferredController;
    } else {
      preferredController.text = "Select";
      return preferredController;
    }
  }


  setPreferredLanguage() {
    if (globals.aiPreferredLanguage.isNotEmpty) {
      for (int i = 0; i < preferredLanguageCode.length; i++) {
        if (globals.aiPreferredLanguage == preferredLanguageCode[i]) {
          langPos = i;
        }
      }
      String selectedLanguage = languageDropDown[langPos];
      preferredController.text = selectedLanguage;
      languageDropDown.removeAt(langPos);
      preferredLanguageCode.removeAt(langPos);

      languageDropDown.insert(0, selectedLanguage);
      preferredLanguageCode.insert(0, globals.aiPreferredLanguage);
      return preferredController;
    } else {
      langPos = 0;
      preferredController.text = languageDropDown[langPos];
      return preferredController;
    }
  }

  setLanguage() {
    if (globals.preferredLanguage.value.isNotEmpty) {
      languageDropDown.clear();
      languageCode.clear();
      for (int i = 0; i < globals.langCodeJson.length; i++) {
        languageDropDown.add(globals.mobileLanguages[globals.langCodeJson[i]]?.language ?? "");
        languageCode.add(globals.mobileLanguages[globals.langCodeJson[i]]?.languageCode ?? "");
      }
      for (int i = 0; i < languageCode.length; i++) {
        if (globals.preferredLanguage.value == languageCode[i]) {
          langPos = i;
        }
      }
      String selectedLanguage = languageDropDown[langPos];
      languageController.text = selectedLanguage;
      languageDropDown.removeAt(langPos);
      languageCode.removeAt(langPos);

      languageDropDown.insert(0, selectedLanguage);
      languageCode.insert(0, globals.preferredLanguage.value);

      return languageController;
    } else {
      langPos = 0;
      languageController.text = languageDropDown[langPos];
      return languageController;
    }
  }

  String getGender(String value) {
    var valueTobeReturend = "";
    if (value == null || value == "null") {
      valueTobeReturend = "";
    } else if (value == "male") {
      valueTobeReturend = male.tr;
    } else if (value == "female") {
      valueTobeReturend = female.tr;
    } else {
      valueTobeReturend = other.tr;
    }
    return valueTobeReturend;
  }

  Future<String?> getProfileInfo() async {
    EditProfileModel? editProfileModel = null;
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
    change(rxVariable: rxGetUpdatedDetailsController, value: true);
    Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "vehicleDetails_query", null);

    if (_login_result != null) {
      debugPrint("_login_result: ${_login_result}");
      if (_login_result["userAccount"]["status"] == 200) {
        editProfileModel = EditProfileModel.fromJson(_login_result);

        if (editProfileModel.userAccount?.result?.vehicles != null) {
          globals.vehicleType = editProfileModel.userAccount?.result?.vehicles
                  ?.vehicleCategoryDetails?.categoryName ??
              "";

          globals.vehicleName =
              editProfileModel.userAccount?.result?.vehicles?.vehicleName ?? "";
          globals.vehicleNumber =
              editProfileModel.userAccount?.result?.vehicles?.vehicleNumber ??
                  "";
          globals.vehicleColor =
              editProfileModel.userAccount?.result?.vehicles?.vehicleColor ??
                  "";
          String categoryImage =
              '${globals.UPLOAD_URL}/images/category/${editProfileModel.userAccount?.result?.vehicles?.vehicleCategoryDetails?.categoryImage}';
          if (globals.vehicleImage != categoryImage &&
              globals.vehicleImage.isNotEmpty) {
            globals.categoryImage = await getImage(categoryImage);
            globals.vehicleImage = categoryImage;
          }
          globals.isChildSeatAvailable =
              editProfileModel.userAccount?.result?.vehicles?.isChildSeat ??
                  false;
          change(rxVariable: rxChildSeatController, value: globals.isChildSeatAvailable);
          globals.isWheelChairAvailable =
              editProfileModel.userAccount?.result?.vehicles?.isWheelChair ??
                  false;
          change(rxVariable: rxWheelChairController, value: globals.isWheelChairAvailable);
          globals.idVehicleToUpdate =
              editProfileModel.userAccount?.result?.vehicles?.id ?? 0;
          globals.vehicleId = int.parse(
              editProfileModel.userAccount?.result?.vehicles?.vehicleType ??
                  "0");
        }

        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        change(rxVariable: rxGetUpdatedDetailsController, value: false);
        return "";
      } else {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        change(rxVariable: rxGetUpdatedDetailsController, value: false);
        return _login_result["userAccount"]["errorMessage"];
      }
    } else {
      getProfileInfo();
    }
  }

  Future<String> callVehicleDetails(
      bool updatedChildSeat, bool updatedWheelChair) async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    var variables = <String, dynamic>{
      "vehicleName": globals.vehicleName,
      "vehicleType": globals.vehicleId,
      "vehicleNumber": globals.vehicleNumber,
      "vehicleColor": globals.vehicleColor,
      "isChildSeatAvailable": updatedChildSeat,
      "isWheelChairAvailable": updatedWheelChair,
      "id": globals.idVehicleToUpdate
    };

    Map<String, dynamic>? result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "vehiclesCreateMutation",
        variables);

    if (result != null) {
      if (result["vehiclesCreate"]["status"] == 200) {
        globals.isChildSeatAvailable = updatedChildSeat;
        globals.isWheelChairAvailable = updatedWheelChair;

        return "";
      } else {
        return result["vehiclesCreate"]["errorMessage"] ??
            "something_went_wrong".tr;
      }
    } else {
      return "something_went_wrong".tr;
    }
  }

  Future<BitmapDescriptor> getImage(String imageURL) async {
    http.Response response = await http.get(
      Uri.parse(imageURL),
    );
    ui.Codec codec =
        await ui.instantiateImageCodec(response.bodyBytes, targetHeight: 90);
    ui.FrameInfo fi = await codec.getNextFrame();
    Uint8List markerIcon =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.bytes(markerIcon,imagePixelRatio: globals.markerImagePixelRatio);
  }

  Future<String> getAllLanguage() async {
    Map<String, dynamic>? _language_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClient, "getAllMobileLanguage", null);
    if (_language_result != null) {
      if (_language_result["getAllMobileLanguage"]["status"] == 200) {
        getMobileLanguageList.value = _language_result["getAllMobileLanguage"]["results"];
        return "";
      } else
      if (_language_result["getAllMobileLanguage"]["status"] == 400) {
        return _language_result["getAllMobileLanguage"]["errorMessage"];
      } else {
        return "timeout";
      }
    } else {
      return "offline";
    }
  }
}