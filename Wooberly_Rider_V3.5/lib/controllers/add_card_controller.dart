import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/country_code.dart';

import 'base_controller.dart';

enum SingingCharacter { cash, card }

class AddCardController extends BaseController {
  var cardNumberController;
  var monthController;
  var cvvController;
  var counrtyController = StreamController<String>.broadcast();
  var zipCodeController;
  int value = 1;
  var Amount;
  bool? additional_Action;
  int check = 0;
  var cardLastFour;
  var loadingController = StreamController<bool>.broadcast();
  RxBool loadingControllerWallet = false.obs;
  RxBool loadingControllerPayType = false.obs;
  var selectPaymentController = StreamController<bool>.broadcast();
  RxInt updateWalletPaymentType = 0.obs;
  bool isCardAdded = false;
  String secret = "";

  var walletAmount = TextEditingController();
  var currencyController = TextEditingController();
  BuildContext? walletContext, paymentTypeContext;
  String payStackRef = "", payStackURL = "";
  String payPalURL = '';
  SingingCharacter character = SingingCharacter.cash;

  String previousamount = "";

  @override
  void onInit() {
    cardNumberController = TextEditingController();
    monthController = TextEditingController();
    cvvController = TextEditingController();
    zipCodeController = TextEditingController();

    if (globals.cardLastFour != 0 && globals.cardLastFour !=null) {
      cardNumberController.text = globals.cardLastFour.toString();
      cardLastFour = globals.cardLastFour.toString();
      update(['paymentController']);
      isCardAdded = true;
    }
    int cardlength = 19, explength = 5, cvvlength = 3;
    if (Platform.isIOS) {
      cardlength = cardlength + 1;
      explength = explength + 1;
      cvvlength = cvvlength + 1;
    }

    walletAmount.addListener(() {
      String fname = walletAmount.text.toString();
      if (fname.contains(".") && fname.split(".").length > 2) {
        walletAmount.text = previousamount;
        walletAmount.selection = TextSelection.collapsed(offset: previousamount.runes.length);
      } else {
        previousamount = walletAmount.text.toString();
      }
    });
    super.onInit();
  }

  isPaymentAdded() {
    if (cardNumberController != null) {
      update(['paymentController']);
    }
  }

  Future<String> getPaymentMethods() async {
    if (graphQlObject.graphQLClient != null) {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      try {
        globals.setButtonLoading();
        Map<String, dynamic>? _currency_rates = await graphQlObject.getQueryValues(
            graphQlObject.graphQLClientWithHeader, "getPaymentMethods_Query", null);
        if (_currency_rates != null && _currency_rates["getPaymentMethods"]["status"] == 200) {
          globals.paymentMethods?.value = [];
          for (dynamic paymentItem in _currency_rates["getPaymentMethods"]["results"]) {
            if (paymentItem is Map<String, dynamic>) {
              globals.paymentMethods?.add(paymentItem["paymentType"]);
            }
          }

          globals.setButtonIdle();
          return "";
        } else {
          return "null";
        }
      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getPaymentMethods();
          return "null";
        });
      }
    } else {
      return "null";
    }
    return "null";
  }

  Stream<String> getContryController() => counrtyController.stream;

  addCountry(CountryCode coun) {
    counrtyController.add(coun.toCountryStringOnly());
  }

  setPaymentType(bool type) {
    isCardAdded = type;
    update(['paymentController']);
  }

  addCardNumber(String card) {
    cardNumberController.text = card;
  }

  Stream<bool> getLoadingController() => loadingController.stream;

  void setLoadingController(bool param0) {
    loadingController.add(param0);
    param0 == true ? globals.setButtonLoading() : globals.setButtonIdle();
  }

  void setLoadingControllerWallet(bool param0) {
    loadingControllerWallet(param0);
    update(['loadingController']);
    param0 == true ? globals.setButtonLoading() : globals.setButtonIdle();
  }

  void setLoadingControllerPayType(bool param0) {
    loadingControllerPayType(param0);
    param0 == true ? globals.setButtonLoading() : globals.setButtonIdle();
  }

  Future<String> updatepaymentMethod(int selectedPayment) async {
    graphQlObject.getGraphQlClientWithHeader();

    var variables = <String, dynamic>{"paymentMethodId": selectedPayment};

    Map<String, dynamic>? _paymentMethod_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "paymentMethod_mutation", variables);

    if (_paymentMethod_result?["updatePaymentMethod"]["status"] == 200) {
      value = selectedPayment;

      globals.preferredPaymentMethod = selectedPayment;
      if (selectedPayment == 2) {
        if (cardLastFour != null) {
          isCardAdded = true;
        }
      }

      Future.delayed(const Duration(milliseconds: 350), () {
        globals.selectedPaymentType.value = selectedPayment;
        selectPaymentController.add(true);
      });

      return "";
    } else {
      return _paymentMethod_result?["updatePaymentMethod"]["errorMessage"];
    }
  }

  Future<String?> addCardDetails(String paymentMethodId, String lastfour) async {
    var variables = <String, dynamic>{
      "paymentMethod": paymentMethodId,
      "cardLastFour": lastfour,
      "actionType": "add"
    };

    Map<String, dynamic>? _addCard_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "add_Card_mutation", variables);

    if (_addCard_result != null) {
      if (_addCard_result["addCardDetails"]["status"] == 200) {
        secret = _addCard_result["addCardDetails"]["paymentIntentSecret"] ?? "";
        additional_Action = _addCard_result["addCardDetails"]["requireAdditionalAction"] ?? false;
        if (additional_Action == false) {
          globals.cardLastFour = int.parse(lastfour);
        }
        return "success";
      } else {
        additional_Action = false;
        secret = "";
        globals.cardLastFour = 0;

        return _addCard_result["addCardDetails"]["errorMessage"];
      }
    }
  }

  Future<String> addWalletAmount(
      String paymentMethodId, String amount, String currency, int paymentTypeId) async {
    var variables = <String, dynamic>{
      "paymentMethod": paymentMethodId,
      "amount": double.parse(amount),
      "currency": currency,
    };
    if (paymentTypeId == 5) variables["paymentType"] = paymentTypeId;
    if (paymentTypeId == 6) {
      variables["paymentType"] = paymentTypeId;
      variables["paymentCurrency"] = globals.paypalCurrencyController.text.toString();
    }
    try {
      Map<String, dynamic>? _addWallet_result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader, "addWallet_mutation", variables);
      setLoadingControllerWallet(true);
      if (_addWallet_result?["addWallet"]["status"] == "200") {
        if (paymentTypeId == 1) {
          secret = _addWallet_result?["addWallet"]["paymentIntentSecret"] ?? "";
          additional_Action = _addWallet_result?["addWallet"]["requireAdditionalAction"] ?? false;
          if (_addWallet_result?["addWallet"]["walletBalance"] != null)
            globals.walletBalance.value =
                double.parse(_addWallet_result!["addWallet"]["walletBalance"].toString());
          setLoadingControllerWallet(true);
        } else if (paymentTypeId == 6) {
          if (_addWallet_result?["addWallet"]["redirectURL"] != null)
            payPalURL = _addWallet_result?["addWallet"]["redirectURL"];
        } else {
          payStackRef = _addWallet_result?["addWallet"]["reference"];
          payStackURL = _addWallet_result?["addWallet"]["url"];
          payStackURL = _addWallet_result?["addWallet"]["url"];
        }
        return "success";
      } else {
        return _addWallet_result?["addWallet"]["errorMessage"];
      }
    } catch (e) {
      debugPrint("addwalletmessage: ${e}");
      return e.toString();
    }
  }

  Future<String> ConfirmSetupIntent(
      String setupIntentId, bool setupIntentStatus, String paymentMethod, String lastfour) async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "setupIntentId": setupIntentId,
      "setupIntentStatus": setupIntentStatus,
      "paymentMethod": paymentMethod,
      "cardLastFour": lastfour,
    };
    Map<String, dynamic>? _confirmpayment_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "confirmSetupIntent", variables);

    if (_confirmpayment_result?["confirmSetupIntent"]["status"] == 200) {
      secret = _confirmpayment_result?["confirmSetupIntent"]["paymentIntentSecret"];
      additional_Action = _confirmpayment_result?["confirmSetupIntent"]["requireAdditionalAction"];
      if (additional_Action == false) {
        globals.cardLastFour = int.parse(lastfour);
      }
      return "success";
    } else {
      return _confirmpayment_result?["confirmSetupIntent"]["errorMessage"];
    }
  }

  Future<String> confirmPaymentIntent(String paymentIntentId, bool paymentIntentStatus, String paymentMethod,
      String amount, String currency, String lastfour) async {
    var variables = <String, dynamic>{
      "paymentIntentId": paymentIntentId,
      "cardLastFour": lastfour,
      "amount": double.parse(amount),
      "currency": currency,
    };
    Map<String, dynamic>? _confirmpayment_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "confirmPaymentIntent", variables);

    if (_confirmpayment_result?["confirmPaymentIntent"]["status"] == 200) {
      secret = _confirmpayment_result?["confirmPaymentIntent"]["paymentIntentSecret"];
      additional_Action = _confirmpayment_result?["confirmPaymentIntent"]["requireAdditionalAction"];
      if (_confirmpayment_result?["confirmPaymentIntent"]["walletBalance"] != null)
        globals.walletBalance.value =
            double.parse(_confirmpayment_result!["confirmPaymentIntent"]["walletBalance"].toString());
      return "success";
    } else {
      if (_confirmpayment_result?["confirmPaymentIntent"]["requireAdditionalAction"] != null)
        additional_Action = _confirmpayment_result?["confirmPaymentIntent"]["requireAdditionalAction"];
      if (_confirmpayment_result?["confirmPaymentIntent"]["walletBalance"] != null)
        globals.walletBalance.value =
            double.parse(_confirmpayment_result!["confirmPaymentIntent"]["walletBalance"].toString());
      return _confirmpayment_result?["confirmPaymentIntent"]["errorMessage"];
    }
  }

  Future<String> updateCardDetails(String paymentMethodId, String lastfour) async {
    var variables = <String, dynamic>{
      "paymentMethod": paymentMethodId,
      "cardLastFour": lastfour,
      "actionType": "update"
    };
    Map<String, dynamic>? _updateCard_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "add_Card_mutation", variables);

    if (_updateCard_result?["addCardDetails"]["status"] == 200) {
      secret = _updateCard_result?["addCardDetails"]["paymentIntentSecret"];
      additional_Action = _updateCard_result?["addCardDetails"]["requireAdditionalAction"];
      if (additional_Action == false) {
        globals.cardLastFour = int.parse(lastfour);
      }
      return "success";
    } else {
      return _updateCard_result?["addCardDetails"]["errorMessage"];
    }
  }

  Future<String> removeCardDetails() async {
    graphQlObject.getGraphQlClientWithHeader();

    Map<String, dynamic>? _removePayment_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "remove_Card_mutation", null);

    if (_removePayment_result?["removeCardDetails"]["status"] == 200) {
      return "";
    } else {
      return _removePayment_result?["removeCardDetails"]["errorMessage"];
    }
  }

  Future<String> updatePaypalCurrency() async {
    graphQlObject.getGraphQlClientWithHeader();
    var variables = <String, dynamic>{"currency": globals.paypalCurrencyController.text.toString()};
    Map<String, dynamic>? _paymentMethod_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "updatePaypalCurrency_mutation", variables);
    if (_paymentMethod_result != null) {
      if (_paymentMethod_result["updateUserPayPalCurrency"]["status"] == 200) {
        return "";
      } else {
        return _paymentMethod_result["updateUserPayPalCurrency"]["errorMessage"];
      }
    } else {
      return "offline";
    }
  }

  getWalletBalance() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? walletbalancequery =
        await graphQlObject.getQueryValues(graphQlObject.graphQLClientWithHeader, "fetchWallet_query", null);
    if (walletbalancequery != null) {
      if (walletbalancequery["userAccount"]["status"] == 200) {
        if (walletbalancequery["userAccount"]['result']['walletBalance'] != null) {
          globals.walletBalance.value =
              double.parse(walletbalancequery["userAccount"]['result']['walletBalance'].toString());
        }
      }
    }
  }
}