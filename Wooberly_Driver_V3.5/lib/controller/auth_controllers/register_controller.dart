import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';

import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/vehicle_type_model.dart';

import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../resources/values/app_lang.dart';

class RegisterController extends BaseController{
  var firstNameController;
  var lastNameController;
  var emailController;
  var selectedLocationController;
  var genderController;
  var passwordController;
  var confirmpasswordController;
  var vehicleNameController;
  var vehicleNoController;
  var vehicleModelNameController;
  var vehicleColorController;
  bool childController = false;
  bool wheelController = false;
  var vehicleModelController;
  var vehicleYearController;
  var cityController;
  var countryController;
  var stateController;
  var zipcodeController;
  var latController;
  var lngController;
  String selectedPlace = "";
  bool showSelected = false;
  late List<Map<String,dynamic>>? predictions;
  Data? getCategories;
  int vehicleModelId = 0;
  var rxLoadingController = ReactiveVariable("rxLoadingController", false);
  var rxChildSeatController = ReactiveVariable("rxChildSeatController", false);

  var rxWheelChairController = ReactiveVariable("rxWheelChairController", false);
  var rxPasswordVisibleController = ReactiveVariable("rxPasswordVisibleController", true);
  var rxConPasswordVisibleController = ReactiveVariable("rxConPasswordVisibleController", true);
  List<String> genderList = [
    male.tr,
    female.tr,
    other.tr
  ];

  @override
  void onInit() {
    _init();
    super.onInit();
  }
  void _init() {
    firstNameController = TextEditingController(text: "");
    lastNameController = TextEditingController(text: "");
    genderController = TextEditingController(text: "");
    emailController = TextEditingController(text: "");
    passwordController = TextEditingController(text: "");
    confirmpasswordController = TextEditingController(text: "");
    selectedLocationController = TextEditingController(text: "");
    vehicleNameController = TextEditingController(text: "");
    vehicleNoController = TextEditingController(text: "");
    vehicleModelNameController = TextEditingController(text: "");
    vehicleColorController = TextEditingController(text: "");

    vehicleModelController = TextEditingController(text: "");
    vehicleYearController = TextEditingController(text: "");
  }

  void setLoadingController(bool param0) {
    change(rxVariable: rxLoadingController, value: param0);
  }




  Future<String> callSignUpAPI() async {
    String firstName =
        toBeginningOfSentenceCase(firstNameController.text.toString().trim())!;
    String lastName =
        toBeginningOfSentenceCase(lastNameController.text.toString().trim())!;
    String email = emailController.text.toString().trim();
    String password = passwordController.text.toString();
    String vehicleName = vehicleNameController.text.toString().trim();
    String vehicleNo = vehicleNoController.text.toString();
    String vehicleColor = vehicleColorController.text.toString();
    String city = cityController;
    String gender = getGender();
    String country = countryController;
    String state = stateController;
    String zipcode = zipcodeController;
    var variables = <String, dynamic>{
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "password": password,
      "phoneDialCode": globals.DialCode,
      "phoneNumber": globals.phnNo,
      "phoneCountryCode": globals.CountryCode,
      "lat": latController,
      "lng": lngController,
      "city": city,
      "state": state,
      "zipcode": zipcode,
      "country": country,
      "gender": gender,
      "vehicleName": vehicleName,
      "vehicleType": vehicleModelId,
      "vehicleNumber": vehicleNo,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId,
      "vehicleColor": vehicleColor,
      "isChildSeatAvailable": childController,
      "isWheelChairAvailable": wheelController,
      "userType": 2,
      "preferredLanguage": globals.preferredLanguage.value,
      "vehicleMakeYear":vehicleYearController.text.toString(),
      "vehicleModal":vehicleModelNameController.text.toString(),
      "vehicleImage":globals.vehicleImagePath,
    };

    Map<String, dynamic>? _signup_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClient, "signup_mutation", variables);
    if (_signup_result?["createUser"]["status"] == 200) {
      globals.authToken = _signup_result?["createUser"]["result"]["userToken"];
      App().appPreference.authToken = globals.authToken;
      globals.userid = _signup_result?["createUser"]["result"]["userId"];
      globals.gender = _signup_result?["createUser"]["result"]["gender"];
      graphQlObject.getGraphQlClientWithHeader();
      return "";
    } else {
      return _signup_result?["createUser"]["errorMessage"];
    }
  }

  Future<String> callVehicleDetails() async {
    graphQlObject.getGraphQlClientWithHeader();
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    String vehicleName = vehicleNameController.text.toString().trim();
    String vehicleNo = vehicleNoController.text.toString();
    String vehicleColor = vehicleColorController.text.toString();
    var variables = <String, dynamic>{
      "vehicleName": vehicleName,
      "vehicleType": vehicleModelId,
      "vehicleNumber": vehicleNo,
      "vehicleColor": vehicleColor,
      "isChildSeatAvailable": childController,
      "isWheelChairAvailable": wheelController,
      "vehicleMakeYear":vehicleYearController.text.toString(),
      "vehicleModal":vehicleModelNameController.text.toString(),
      "vehicleImage":globals.vehicleImagePath,
      "id": null
    };

    Map<String, dynamic>? result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "vehiclesCreateMutation",
        variables);

    if (result != null) {
      if (result["vehiclesCreate"]["status"] == 200) {
        return "";
      } else {
        return result["vehiclesCreate"]["errorMessage"] ??
            "something_went_wrong".tr;
      }
    } else {
      return "something_went_wrong".tr;
    }
  }

  Future<String> getVehicleTypes() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    graphQlObject.graphQLClient.cache.store.reset();
    Map<String, dynamic>? _vehicleTypes_result =
        await graphQlObject.getQueryValues(
            graphQlObject.graphQLClient, "vehicle_type_query", null);
    if (_vehicleTypes_result?["getCategories"]["status"] == 200) {
      getCategories = Data.fromJson(_vehicleTypes_result!);
      return "";
    } else {
      return _vehicleTypes_result?["getCategories"]["errorMessage"];
    }
  }

  Future<String> validateEmailAddress() async {
    String email = emailController.text.toString();
    var variables = <String, dynamic>{"email": email};
    Map<String, dynamic>? _validateEmail_result =
        await graphQlObject.getQueryValues(
            graphQlObject.graphQLClient, "validateEmail_query", variables,true,FetchPolicy.networkOnly);
    if (_validateEmail_result?["validateEmailExist"]["status"] == 200) {
      return "";
    } else {
      return _validateEmail_result?["validateEmailExist"]["errorMessage"];
    }
  }

  String getGender() {
    if (genderController.text.toString().trim() ==
        male.tr)
      return "male";
    else if (genderController.text.toString().trim() ==
        female.tr)
      return "female";
    else
      return "other";
  }

  Future<String> updateProfileInfo(String fieldName, String fieldValue) async {
    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };

    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
    if (_login_result != null) {
      if (_login_result["userUpdate"]["status"] == 200) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        return "";
      } else if (_login_result["userUpdate"]["status"] == 500) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        return "timeout";
      } else {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        return _login_result["userUpdate"]["errorMessage"];
      }
    } else
      return "offline";
  }
}