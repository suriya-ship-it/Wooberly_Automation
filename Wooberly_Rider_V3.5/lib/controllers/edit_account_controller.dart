import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/currency_model.dart';
import 'package:app_name/models/upload_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/closable_multi_part.dart';

import 'base_controller.dart';

class EditAccountController extends BaseController{
  String passwordHint = "12345678";
  String? profileImage;

  var firstNameController;
  var lastNameController;
  var emailController;

  var passwordController;
  var passwordEditController;
  var newpasswordEditController;
  var confirmpasswordEditController;

  var passwordFocusNode = new FocusNode();
  var firstNameFocusNode = new FocusNode();
  var lasttNameFocusNode = new FocusNode();
  var newPasswordFocusNode = new FocusNode();
  var confirmPasswordFocusNode = new FocusNode();

  UploadModel? model;




  RxBool loading = false.obs;
  RxString gender=''.obs;
  RxBool cursorControlController = false.obs;
  RxInt saveController = 0.obs;

  var currencyController, languageController;

  final List<String> currencyDropDown = [];
  List<String> languageDropDown = [];

  List<String> languageCode = [];
  int langPos = 0;
  bool? isSpaceAllow;

  @override
  void onInit() {
    currencyController = TextEditingController();
    languageController = TextEditingController();
    if (globals.preferredCurrency.isNotEmpty) {
      currencyController.text = globals.currencySymbol + " - " + globals.preferredCurrency;
    }
    _init();
    super.onInit();
  }
  void _init() {
    passwordController = TextEditingController(text: passwordHint);

    setFirstNameObserver();
    setLastNameObserver();
    setEmailObserver();
    setPasswordObserver();
  }



  void setLoadingController(bool param0) {
    loading(param0);
  }

  void setFirstNameObserver() {
    firstNameController = TextEditingController();
    firstNameController.addListener(() {
      String fname = firstNameController.text.toString();

      if (fname[0] == " ") firstNameController.text = "";
      cursorControlController(true);
    });
  }

  void setLastNameObserver() {
    lastNameController = TextEditingController();
    lastNameController.addListener(() {
      String lname = lastNameController.text.toString();

      if (lname[0] == " ") lastNameController.text = "";
      cursorControlController(true);
    });
  }

  void setEmailObserver() {
    emailController = TextEditingController(text: globals.email);
  }

  void setPasswordObserver() {
    passwordEditController = TextEditingController();

    passwordEditController.addListener(() {
      if (passwordEditController.text.toString()[0] == " ")
        passwordEditController.text = "";
    });

    newpasswordEditController = TextEditingController();
    newpasswordEditController.addListener(() {
      if (newpasswordEditController.text.toString()[0] == " ")
        newpasswordEditController.text = "";
    });

    confirmpasswordEditController = TextEditingController();
    confirmpasswordEditController.addListener(() {
      if (confirmpasswordEditController.text.toString()[0] == " ")
        confirmpasswordEditController.text = "";
    });
  }

  Future<String> getCurrencyList() async {
    int index = languageCode.indexOf(globals.preferredLanguage);
    String selectedLanguage = languageDropDown[index];
    languageDropDown.removeAt(index);
    languageCode.removeAt(index);

    languageDropDown.insert(0, selectedLanguage);
    languageCode.insert(0, globals.preferredLanguage);

    if (globals.currencyModel == null) {
      Map<String, dynamic>? _currency_result = await graphQlObject.getQueryValues(graphQlObject.graphQLClientWithHeader, "getAllCurrencies_query",
              null);
      if (_currency_result == null)
        return "null";
      globals.currencyModel = CurrencyModel.fromJson(_currency_result);
    }

    if (globals.currencyModel!.getAllCurrencies!.status!.compareTo("200") == 0) {
      List<CurrencyResults> result = globals.currencyModel!.getAllCurrencies!.results!;
      NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
      for (int i = 0; i < result.length; i++) {
        if (result[i].isEnable == true) {
          String currencySymbol =
              _numberFormat.simpleCurrencySymbol(result[i].symbol!);
          currencySymbol =
             getCurrencySybmol(result[i].symbol!, currencySymbol);
          String currencyValue = currencySymbol + " - " + result[i].symbol!;
          if (currencyValue != currencyController.text) {
            currencyDropDown.add(currencyValue);
          } else {
            currencyDropDown.insert(0, currencyValue);
          }
        }
      }
    }
   await globals.baseController.getAILanguageList();
    return "";
  }

  Future<String> updateProfileInfo(String fieldName, String fieldValue) async {
    globals.isContinuousLoading = true;

    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": Platform.isAndroid? "android":"ios",
      "deviceId": globals.deviceId
    };
    debugPrint("updateProfileInfo:-- variables ${variables}");

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
      if (_login_result != null) {
      if (_login_result["userUpdate"]["status"] == 200) {
        if (fieldName == "preferredCurrency") {
          globals.preferredCurrency =
              currencyController.text.toString().split("-")[1].trim();
          NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
          globals.currencySymbol =
              _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
          globals.currencySymbol = getCurrencySybmol(
              globals.preferredCurrency, globals.currencySymbol);
        }
        globals.setButtonIdle();
        fetchWalletAmount();
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

  Future<String> fetchWalletAmount() async {
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "fetchWallet_query", null);
    if (_login_result != null) {
      if (_login_result["userAccount"]["status"] == 200) {
        if(_login_result["userAccount"]["result"]["walletBalance"] !=null)
        globals.walletBalance.value = double.parse(_login_result["userAccount"]["result"]["walletBalance"].toString());
        return "";
      } else if (_login_result["userAccount"]["status"] == 500) {
        globals.setButtonIdle();
        return "timeout";
      } else {
        return _login_result["userAccount"]["errorMessage"];
      }
    } else
      return "offline";
  }

  Future<String> uploadMultipart(
      File imageFile, String type, String uploadURL) async {
    setLoadingController(true);

    var stream = new http.ByteStream(imageFile.openRead());
    stream.cast();
    var length = await imageFile.length();
    String ext = imageFile.path.split(".").last;

    var uri = Uri.parse(uploadURL);

    Map<String, String> headers = {"auth": globals.authToken!};

    var request = new CloseableMultipartRequest("POST", uri);
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
      if (model!.status == 200) {
        setLoadingController(false);
        profileImage = model!.files![0].filename!;

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
    String newPassword = newpasswordEditController.text.toString();
    var variables = <String, dynamic>{
      "oldPassword": !globals.isCurrentPassword ? "" : oldPassword,
      "newPassword": newPassword
    };

    Map<String, dynamic>? _updatePassword_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "update_Password",
            variables);

    if (_updatePassword_result?["updateUserPassword"]["status"] == 200) {
      globals.isCurrentPassword = true;
      return "";
    } else {
      return _updatePassword_result?["updateUserPassword"]["errorMessage"];
    }
  }


  setLanguage() {
    if (globals.preferredLanguage != null &&
        globals.preferredLanguage.isNotEmpty) {
      languageDropDown.clear();
      languageCode.clear();
      for (int i = 0; i < globals.langCodeJson.length; i++) {
        print("globals.langCodeJson--> ${globals.langCodeJson[i]}");
        languageDropDown.add(globals.mobileLanguages[globals.langCodeJson[i]]?.language ?? "");
        languageCode.add(globals.mobileLanguages[globals.langCodeJson[i]]?.languageCode ?? "");
      }
      for (int i = 0; i < languageCode.length; i++) {
        if (globals.preferredLanguage == languageCode[i]) {
          langPos = i;
        }
      }

      String selectedLanguage = languageDropDown[langPos];
      languageController.text = selectedLanguage;
      languageDropDown.removeAt(langPos);
      languageCode.removeAt(langPos);

      languageDropDown.insert(0, selectedLanguage);
      languageCode.insert(0, globals.preferredLanguage);

      return languageController;
    } else {
      langPos = 0;
      languageController.text = languageDropDown[langPos];
      return languageController;
    }
  }

  String getGender(String? value) {
    var valueTobeReturend = "";
    if (value == null || value == "null") {
      valueTobeReturend = "";
    } else if (value == "male") {
      valueTobeReturend = 'male'.tr;
    } else if (value == "female") {
      valueTobeReturend = 'female'.tr;
    } else {
      valueTobeReturend = 'other'.tr;
    }
    gender.value=valueTobeReturend;
    return valueTobeReturend;
  }
}