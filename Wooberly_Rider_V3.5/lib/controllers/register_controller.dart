import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;

import 'base_controller.dart';

class RegisterController extends BaseController {
  var firstNameController;
  var lastNameController;
  var emailController;
  var selectedLocationController;
  var genderController;
  var passwordController;
  var confirmpasswordController;
  var cityController;
  var countryController;
  var stateController;
  var zipcodeController;
  var latController;
  var lngController;
  String selectedPlace = "";
  bool showSelected = false;
  List<Map<String, dynamic>> predictions = [];
  RxBool passwordVisibleController = true.obs;
  RxBool conPasswordVisibleController = true.obs;
  RxBool isAgeRestrictionAccepted = false.obs;
  List<String> genderList = ['male'.tr, 'female'.tr, 'other'.tr];
  @override
  void onInit() {
    firstNameController = TextEditingController(text: "");
    lastNameController = TextEditingController(text: "");
    genderController = TextEditingController(text: "");
    emailController = TextEditingController(text: "");
    passwordController = TextEditingController(text: "");
    confirmpasswordController = TextEditingController(text: "");
    selectedLocationController = TextEditingController(text: "");
    super.onInit();
  }

  Future<String> callSignUpAPI() async {
    String firstName =
        toBeginningOfSentenceCase(firstNameController.text.toString().trim())!;
    String lastName =
        toBeginningOfSentenceCase(lastNameController.text.toString().trim())!;
    String email = emailController.text.toString().trim();
    String password = passwordController.text.toString();
    String gender = getGender();
    String city = cityController;
    String country = countryController;
    String state = stateController;
    String zipcode = zipcodeController;
    var variables = <String, dynamic>{
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "password": password,
      "phoneDialCode": globals.DialCode,
      "phoneNumber": globals.phoneNumber,
      "phoneCountryCode": globals.CountryCode,
      "lat": latController,
      "lng": lngController,
      "city": city,
      "state": state,
      "zipcode": zipcode,
      "country": country,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId,
      "userType": 1,
      "preferredLanguage": globals.preferredLanguage,
    };

    if(gender.isNotEmpty) {
      variables["gender"] = gender;
    }


    Map<String, dynamic>? _signup_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClient, "signup_mutation", variables);
    if (_signup_result?["createUser"]["status"] == 200) {
      globals.authToken = _signup_result?["createUser"]["result"]["userToken"];
      graphQlObject.getGraphQlClientWithHeader();
      globals.userid = _signup_result?["createUser"]["result"]["userId"];
      return "";
    } else {
      return _signup_result?["createUser"]["errorMessage"];
    }
  }

  Future<dynamic> validateEmailAddress() async {
    String email = emailController.text.toString();
    var variables = <String, dynamic>{"email": email};
    Map<String, dynamic>? _validateEmail_result =
        await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
            "validateEmail_query", variables, FetchPolicy.networkOnly);
    if (_validateEmail_result != null) {
      if (_validateEmail_result?["validateEmailExist"]["status"] == 200) {
        return "";
      } else {
        return _validateEmail_result?["validateEmailExist"]["errorMessage"];
      }
    } else {
      validateEmailAddress();
    }
  }

  Future<String?> getProfileInfo() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    EditProfileModel editProfileModel = EditProfileModel();
    try {
      Map<String, dynamic>? _login_result = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader, "userAccount_query", null);

      if (_login_result?["userAccount"]["status"] == 200) {
        editProfileModel = EditProfileModel.fromJson(_login_result!);
        globals.paypalCurrencyController.text =
            editProfileModel.userAccount?.result?.paypalPreferredCurrency ?? "";
        globals.firstname.value = toBeginningOfSentenceCase(
            editProfileModel.userAccount!.result!.firstName)!;
        globals.lastname.value = toBeginningOfSentenceCase(
            editProfileModel.userAccount!.result!.lastName)!;
        globals.email = editProfileModel.userAccount!.result!.email;
        globals.userid = editProfileModel.userAccount?.result?.userId;
        globals.gender = editProfileModel.userAccount!.result!.gender;
        globals.preferredLanguage = editProfileModel.userAccount!.result!.preferredLanguage!;
        globals.aiPreferredLanguage =
            editProfileModel.userAccount?.result?.aiPreferredLanguage ?? '';
        preferences.preferredLaunguage= globals.preferredLanguage;
        globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
        if (editProfileModel.userAccount!.result!.picture != null) {
          globals.picture.value = globals.UPLOAD_URL + "/images/avatar/medium_" +
              editProfileModel.userAccount!.result!.picture!;
        }
        globals.phoneNumber =
            editProfileModel.userAccount!.result!.phoneNumber!;
        globals.isCurrentPassword =
            _login_result?["userAccount"]["result"]["isCurrentPassword"];
        if (globals.paypalCurrencies.isEmpty) getCurrencyListForPaypal();
        globals.CountryCode =
            editProfileModel.userAccount!.result!.phoneCountryCode!;
        globals.DialCode = editProfileModel.userAccount!.result!.phoneDialCode!;
        globals.preferredCurrency =
            editProfileModel.userAccount!.result!.preferredCurrency!;
        if (editProfileModel.userAccount!.result!.walletBalance != null) {
          globals.walletBalance.value = double.parse(
              editProfileModel.userAccount!.result!.walletBalance!.toString());
        }
        globals.cardLastFour =
            editProfileModel.userAccount?.result?.cardLastFour ?? 0;

        globals.preferredPaymentMethod =
            editProfileModel.userAccount!.result!.preferredPaymentMethod!;

        NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
        globals.currencySymbol =
            _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
        globals.currencySymbol = getCurrencySybmol(
            globals.preferredCurrency, globals.currencySymbol);

        if (editProfileModel.userAccount!.result!.appTheme == "auto") {
          globals.theme = 1;
        } else if (editProfileModel.userAccount!.result!.appTheme == "light") {
          globals.theme = 2;
        } else {
          globals.theme = 3;
        }

        return "";
      } else if (_login_result?["userAccount"]["status"] == 500) {
        return "timeout";
      } else {
        return _login_result?["userAccount"]["errorMessage"];
      }
    } on Exception catch (e) {
      debugPrint("connection exception: ${e.toString()}");
      if (e
          .toString()
          .contains("SocketException: OS Error: Network is unreachable"))
        return "offline";
    }
  }

  Future<String> addFavoriteLocation(SelectLocationEnum locationEnum) async {
    String locationtype = "";
    if (locationEnum== SelectLocationEnum.homeLocation)
      locationtype = "home";
    else
      locationtype = "work";
    var variables = <String, dynamic>{
      "location": selectedPlace,
      "lat": latController,
      "lng": lngController,
      "locationType": locationtype
    };

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "addSavedLocations_mutation",
        variables);

    if (_login_result != null) {
      if (_login_result["addSavedLocations"]["status"] == 200) {
        String _locId = _login_result["addSavedLocations"]["id"].toString();

        if (_locId != null) {
          setLocationDetails(
            selectLocationModel: SelectLocationModel(
              lat: double.parse(latController.toString()),
              lng: double.parse(lngController.toString()),
              selectLocationEnum: locationEnum,
              location: selectedPlace,
              id: int.parse(_locId.toString()),
              isValidLocation: double.parse(latController.toString()) != 0.0 &&
                  double.parse(lngController.toString()) != 0.0,
            ),
            selectLocationEnum: locationEnum,
          );
        }
        return "";
      } else {
        return _login_result["addSavedLocations"]["errorMessage"];
      }
    } else {
      return 'offline';
    }
  }

  Future<String> updateFavoriteLocation(String id, SelectLocationEnum selectedEnum) async {
    String locationtype = "";
    if (selectedEnum == SelectLocationEnum.homeLocation)
      locationtype = "home";
    else
      locationtype = "work";

    var variables = <String, dynamic>{
      "id": int.parse(id),
      "location": selectedPlace,
      "lat": latController,
      "lng": lngController,
      "locationType": locationtype
    };

    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "addSavedLocations_mutation",
        variables);

    if (_login_result?["addSavedLocations"]["status"] == 200) {
      setLocationDetails(
        selectLocationModel: SelectLocationModel(
          lat: double.parse(latController.toString()),
          lng: double.parse(lngController.toString()),
          selectLocationEnum: selectedEnum,
          location: selectedPlace,
          id: int.parse(id.toString()),
          isValidLocation: double.parse(latController.toString()) != 0.0 &&
              double.parse(lngController.toString()) != 0.0,
        ),
        selectLocationEnum: selectedEnum,
      );

      return "";
    } else {
      return _login_result?["addSavedLocations"]["errorMessage"];
    }
  }

  Future<String> removeFavoriteLocation(String id) async {
    var variables = <String, dynamic>{"id": int.parse(id)};
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "removeSavedLocations_mutation",
        variables);

    if (_login_result?["removeSavedLocations"]["status"] == 200) {
      return "";
    } else {
      return _login_result?["removeSavedLocations"]["errorMessage"];
    }
  }

  Future<String> updateProfileInfo(String fieldName, String fieldValue) async {
    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };

    globals.setButtonLoading();
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
    if (_login_result != null) {
      if (_login_result["userUpdate"]["status"] == 200) {
        globals.setButtonIdle();

        if (fieldValue == "auto") {
          globals.theme = 1;
          var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
          globals.isDarkTheme = brightness == Brightness.dark;
        } else if (fieldValue == "light") {
          globals.theme = 2;
          globals.isDarkTheme = false;
        } else {
          globals.theme = 3;
          globals.isDarkTheme = true;
        }
        globals.themeNotifier?.isDark = globals.isDarkTheme;
        return "";
      } else if (_login_result["userUpdate"]["status"] == 500) {
        globals.setButtonIdle();
        return "timeout";
      } else {
        globals.setButtonIdle();
        return _login_result["userUpdate"]["errorMessage"];
      }
    } else
      return "offline";
  }

  Future<PermissionStatus> listenForPermissionStatus1(
      Permission permission) async {
    final PermissionStatus statusFuture = await permission.status;

    return statusFuture;
  }

  String getGender() {
    if (genderController.text.toString().trim() == 'male'.tr)
      return "male";
    else if (genderController.text.toString().trim() == 'female'.tr)
      return "female";
    else if (genderController.text.toString().trim() == 'other'.tr)
      return "other";
    else
      return '';
  }
}