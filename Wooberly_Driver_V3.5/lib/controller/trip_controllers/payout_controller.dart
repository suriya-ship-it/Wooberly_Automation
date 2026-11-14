import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/country_list_model.dart';
import 'package:wooberly_driver/models/payout_list_model.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/payout_country_list.dart';

class PayoutController extends BaseController{
  var countryController;
  var address1Controller;
  var address2Controller;
  var cityController;
  var stateController;
  var zipcodeController;
  var firstNameController;

  var accountTypeController;
  var lastNameController;
  var routingController;
  var accountNoController;
  var confirmAccNoController;
  var showError = false;
  var companyNameController;
  var accountOwnerNameController;
  var bankNameController;
  var branchNameController;
  var payPalController;
  var emailController;
  var bankCodeController;
  var selectedCountry;
  CountryListModel? allCountries;
  PayoutListModel? allPayouts;
  String? formateddate;
  Map<String, dynamic>? accountDetailsArguments;
  var rxCountryListController = ReactiveVariable("rxCountryListController", []);
  var rxPayoutListController = ReactiveVariable("rxPayoutListController", []);
  var isLoading = false.obs;
  var rxLoadingController = ReactiveVariable("rxLoadingController", false);
  var rxUpdatePayOutPaymentType = ReactiveVariable("rxUpdatePayOutPaymentType", 1);
  var rxPayoutStatusChangedController = false.obs;

   int payoutDefaultIndex = 0;

  bool isCompanyEnabled = true;
   Map<String,dynamic> paymentMethodCurrency={};

  String func = "";

  int selectedid = 0;

  @override
  void onInit() {
    _init();
    super.onInit();
  }

  void _init() {
    countryController = TextEditingController();
    address1Controller = TextEditingController();
    address2Controller = TextEditingController();
    cityController = TextEditingController();
    stateController = TextEditingController();
    zipcodeController = TextEditingController();
    accountTypeController = TextEditingController();
    firstNameController = TextEditingController();
    companyNameController = TextEditingController();
    lastNameController = TextEditingController();
    routingController = TextEditingController();
    accountNoController = TextEditingController();
    confirmAccNoController = TextEditingController();
    accountOwnerNameController = TextEditingController();
    bankNameController = TextEditingController();
    branchNameController = TextEditingController();
    bankCodeController = TextEditingController();
    payPalController = TextEditingController();
    emailController = TextEditingController();


    address1Controller.addListener(() {
      if (address1Controller.text.toString().isNotEmpty &&
          (address1Controller.text.toString()[0] == " " ||
              address1Controller.text.toString()[0] == "," ||
              address1Controller.text.toString()[0] == "." ||
              address1Controller.text.toString()[0] == "/" ||
              address1Controller.text.toString()[0] == "-"))
        address1Controller.text = "";
    });
    address2Controller.addListener(() {
      if (address2Controller.text.toString().isNotEmpty &&
          (address2Controller.text.toString()[0] == " " ||
              address2Controller.text.toString()[0] == "," ||
              address2Controller.text.toString()[0] == "." ||
              address2Controller.text.toString()[0] == "/" ||
              address2Controller.text.toString()[0] == "-"))
        address2Controller.text = "";
    });

    cityController.addListener(() {
      if (cityController.text.toString().isNotEmpty &&
          cityController.text.toString()[0] == " ") cityController.text = "";
    });
    stateController.addListener(() {
      if (stateController.text.toString().isNotEmpty &&
          stateController.text.toString()[0] == " ") stateController.text = "";
    });

    companyNameController.addListener(() {
      if (companyNameController.text.toString().isNotEmpty &&
          companyNameController.text.toString()[0] == " ")
        companyNameController.text = "";
    });
    accountTypeController.addListener(() {
      if (accountTypeController.text.toString().isNotEmpty &&
          accountTypeController.text.toString()[0] == " ")
        accountTypeController.text = "";
    });

    firstNameController.addListener(() {
      if (firstNameController.text.toString().isNotEmpty &&
          firstNameController.text.toString()[0] == " ")
        firstNameController.text = "";
    });

    lastNameController.addListener(() {
      if (lastNameController.text.toString().isNotEmpty &&
          lastNameController.text.toString()[0] == " ")
        lastNameController.text = "";
    });

    routingController.addListener(() {
      if (routingController.text.toString().isNotEmpty &&
          routingController.text.toString()[0] == " ")
        routingController.text = "";
    });

    accountOwnerNameController.addListener(() {
      if (accountOwnerNameController.text.toString().isNotEmpty &&
          accountOwnerNameController.text.toString()[0] == " ")
        accountOwnerNameController.text = "";
    });

    bankNameController.addListener(() {
      if (bankNameController.text.toString().isNotEmpty &&
          bankNameController.text.toString()[0] == " ")
        bankNameController.text = "";
    });

    branchNameController.addListener(() {
      if (branchNameController.text.toString().isNotEmpty &&
          branchNameController.text.toString()[0] == " ")
        branchNameController.text = "";
    });

    bankCodeController.addListener(() {
      if (bankCodeController.text.toString().isNotEmpty &&
          bankCodeController.text.toString()[0] == " ")
        bankCodeController.text = "";
    });

    payPalController.addListener(() {
      if(payPalController.text.toString().isNotEmpty && payPalController.text.toString()[0] ==" ")
        payPalController.text="";
    });

    emailController.addListener(() {
      if(emailController.text.toString().isNotEmpty && emailController.text.toString()[0] ==" ")
        emailController.text="";
    });

    formateddate = null;
    selectedCountry = null;
  }

  void setcountryListController(List<CountryResults> param0) {
    change(rxVariable: rxCountryListController, value: param0);
  }

  void setpayoutListController(List<Results> param0) {
    change(rxVariable: rxPayoutListController, value: param0);
  }

  Future<String> getCountryList() async {
    Map<String, dynamic>? _countries_result =
        await graphQlObject.getQueryValues(
            graphQlObject.graphQLClientWithHeader,
            "getAllCountries_query",
            null);

    if (_countries_result?["getAllCountries"]["status"] == 200) {
      allCountries = CountryListModel.fromJson(_countries_result!);
      return "";
    } else {
      return _countries_result?["getAllCountries"]["errorMessage"];
    }
  }

  Future<String> getPayouts() async {
    isLoading.value=true;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);

    Map<String, dynamic>? _countries_result =
        await graphQlObject.getQueryValues(
            graphQlObject.graphQLClientWithHeader, "getPayouts_query", null);

    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    if (_countries_result?["getPayouts"]["status"] == 200) {
      allPayouts = PayoutListModel.fromJson(_countries_result!);

      for (int i = 0; i < (allPayouts?.getPayouts?.results?.length ?? 0); i++) {
        globals.payout = 1;
        if ((allPayouts?.getPayouts?.results?[i].isVerified != null &&
                (allPayouts?.getPayouts?.results?[i].isVerified ?? false)) ||
            (allPayouts?.getPayouts?.results?[i].defaultpayout != null &&
                (allPayouts?.getPayouts?.results?[i].defaultpayout ?? false))) {
          globals.isPayout = true;
        } else {
          allPayouts?.getPayouts?.results?[i].isVerified = false;
          allPayouts?.getPayouts?.results?[i].defaultpayout = false;
        }
      }

      return "";
    } else {
      return _countries_result?["getPayouts"]["errorMessage"] ?? "";
    }
  }

  Future<String?> getPaymentMethods() async {
    if (graphQlObject.graphQLClient != null) {
      try {
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClientWithHeader,
                "getPaymentMethods_Query",
                null);
        if (_currency_rates != null &&
            _currency_rates["getPaymentMethods"]["status"] == 200) {
          globals.paymentMethods.clear();
          for (dynamic paymentItem in _currency_rates["getPaymentMethods"]
              ["results"]) {
            if (paymentItem is Map<String, dynamic>) {
              globals.paymentMethods.add(paymentItem["paymentType"]);
              if (paymentItem['name'] == "Credit/Debit" || paymentItem['name'] == "Paystack"|| paymentItem['name'] == "PayPal") {
                paymentMethodCurrency[paymentItem['name']] = paymentItem['currency'];
                if(paymentItem['name'] == "PayPal")
                globals.payPalCurrency=paymentItem['currency'];
              }
            }
          }
          return "";
        }
      } on Exception catch (e, stack) {
        print("Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack);
        return 'offline';
      }
    }
  }

  Future<String> addPayout(
     int paymentMethodId) async {
    var variables = <String, dynamic>{
      "methodId": paymentMethodId,
      "payEmail": paymentMethodId == 6 ? emailController.text : globals.email,
      "address1": address1Controller.text.toString(),
      "address2": address2Controller.text.toString(),
      "city": cityController.text.toString(),
      "state": stateController.text.toString(),
      "country": selectedCountry.toString(),
      "zipcode": zipcodeController.text.toString(),
      "currency": paymentMethodId == 6 ? payPalController.text.toString() : globals.preferredCurrency,
      "firstname": !isCompanyEnabled || paymentMethodId == 5
          ? firstNameController.text.toString()
          : companyNameController.text.toString(),
      "lastname":  lastNameController.text.toString(),
    };

    if (paymentMethodId == 5) {
      variables["accountType"] = companyNameController.text.toString();
      variables["bankCode"] = bankCodeController.text.toString();
      variables["accountNumber"] = accountNoController.text.toString();
    } else {
      // 1. Assign values common to all paths upfront
      variables["businessType"]  = isCompanyEnabled ? "company" : "individual";
      variables["accountNumber"] = accountNoController.text.trim();

// 2. Localize text data dynamically with trimming
      final routingText  = routingController.text.trim();
      final bankCodeText = bankCodeController.text.trim();

// 3. Fallthrough evaluations matching conditional country configurations
      if (routingNumberEnableCountries.contains(selectedCountry)) {
        variables["routingNumber"] = routingText;
      }
      else if (bankCodeEnableCountries.contains(selectedCountry)) {
        variables["bankCode"]   = bankCodeText;
        variables["branchCode"] = routingText;
      }
      else if (transitNumberEnableCountries.contains(selectedCountry)) {
        variables["transitNumber"]     = bankCodeText;
        variables["institutionNumber"] = routingText;
      }
      else if (sortCodeEnableCountries.contains(selectedCountry)) {
        variables["sortCode"] = routingText;
      }
      else if (bankNameEnableCountries.contains(selectedCountry)) {
        variables["bankName"]         = bankNameController.text.trim();
        variables["branchName"]       = branchNameController.text.trim();
        variables["bankCode"]         = bankCodeText;
        variables["branchCode"]       = routingText;
        variables["accountOwnerName"] = accountOwnerNameController.text.trim();
      }
// Note: 'europeCountries', 'clabeEnableCountries', and the final 'else'
// only needed 'accountNumber', which is already set at the top.

    }

    debugPrint("AddPayout--> $variables");

    Map<String, dynamic>? _addpayout_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "addPayout_mutation",
            variables);
    debugPrint("AddPayoutresult--> $_addpayout_result");
    if (_addpayout_result?["addPayout"]["status"] == 200) {
      if (paymentMethodId == 2) {
        globals.stripeConnectionUrl =
            _addpayout_result?["addPayout"]["connectUrl"] ?? "";
        globals.stripeAccountId =
            _addpayout_result?["addPayout"]["stripeAccountId"] ?? "";
      }

      return "";
    } else {
      return _addpayout_result?["addPayout"]["errorMessage"] ?? "null";
    }
  }

  Future<String> changePayoutConfig() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    var variables = <String, dynamic>{
      "id": selectedid,
      "type": func,
    };

    Map<String, dynamic>? _countries_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "setDefaultPayout_mutation",
            variables);

    if (_countries_result?["setDefaultPayout"]["status"] == 200) {
      return "";
    } else {
      return _countries_result?["setDefaultPayout"]["errorMessage"];
    }
  }

  Future<String> confirmPayout() async {
    var variables = <String, dynamic>{
      "currentAccountId": "${globals.stripeAccountId}",
      "country": selectedCountry
    };
    Map<String, dynamic>? _confirmPayoutResult =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "confirmPayout_Mutation",
            variables);
    if (_confirmPayoutResult?["confirmPayout"]["status"] == 200) {
      return "";
    } else {
      return _confirmPayoutResult?["confirmPayout"]["status"];
    }
  }

  Future<String> VerifyPayout() async {
    var variables = <String, dynamic>{
      "stripeAccount": "${globals.stripeAccountId}"
    };
    Map<String, dynamic>? verifyPayoutResult =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "verifyPayout_Mutation",
            variables);
    if (verifyPayoutResult?["verifyPayout"]["status"] == 200) {
      globals.stripeConnectionUrl =
      verifyPayoutResult?["verifyPayout"]["connectUrl"];
      globals.stripeAccountId =
          verifyPayoutResult?["verifyPayout"]["stripeAccountId"];
      return "";
    } else {
      return verifyPayoutResult?["verifyPayout"]["status"];
    }
  }

  void Reset() {
    _init();
  }

  void setLoadingController(bool param0) {
    change(rxVariable: rxLoadingController, value: param0);
  }

  Future<String?> getPaymentSettings() async {
    App().getSecurityKey().then((securityKey) async {
      if (graphQlObject.graphQLClient != null) {
        var variables = <String, dynamic>{
          "securityKey": securityKey,
          "settingsType": "configSettings"
        };

        graphQlObject.graphQLClient.cache.store.reset();
        try {
          Map<String, dynamic>? paymentResult =
              await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
                  "getSecureSiteSettings", variables);
          if (paymentResult?["getSecureSiteSettings"]["status"] == 200) {
            paymentResult?["getSecureSiteSettings"]["results"]
                .forEach((element) => {
                      if (element["name"] == "stripePublishableKey")
                        {
                          globals.stripePublishableKey = element["value"],
                        }
                      else if(element["name"] == "isVoiceAIFeature"){
                        globals.isVoiceChatEnable = element["value"] == 'true'
                      }else if(element["name"] == "isVoiceTranslatorFeature"){
                        globals.isVoiceTranslatorEnable = element["value"] == 'true'
                      }
                    });
            return "";
          } else {
            return "null";
          }
        }on Exception catch (e, stack) {
          print("Error: $e");
          FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }
    });
  }

  void removeAccountDetails() {
    firstNameController.text = "";
    lastNameController.text = "";
    routingController.text = "";
    accountNoController.text = "";
    confirmAccNoController.text = "";
    companyNameController.text = "";
    accountOwnerNameController.text = "";
    bankNameController.text = "";
    branchNameController.text = "";
    bankCodeController.text = "";
    payPalController.text = "";
    emailController.text = "";
  }
}