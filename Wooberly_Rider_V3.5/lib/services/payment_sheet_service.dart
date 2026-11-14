import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/add_card_controller.dart';

class PaymentSheetService {
  PaymentSheetService._(this.context, this.isFrom)
      : _addCardController = Get.find<AddCardController>();

  static Future<bool>? _activeStart;

  final BuildContext context;
  final String isFrom;
  final AddCardController _addCardController;

  String? _currentClientSecret;
  String? _currentPaymentMethodId;
  String? _currentCardLast4;
  String? _intentErrorMessage;
  bool _completed = false;

  static Future<bool> start({
    required BuildContext context,
    required String isFrom,
  }) async {
    debugPrint(
        "PaymentSheetService: ${isFrom} -  ${globals.preferredLanguage}");
    if (_activeStart != null) return _activeStart!;

    final service = PaymentSheetService._(context, isFrom);
    _activeStart = service._start().whenComplete(() {
      _activeStart = null;
    });
    return _activeStart!;
  }

  Future<bool> _start() async {
    final completer = Completer<bool>();
    _addCardController.checkInternet(() async {
      globals.setButtonLoading();
      try {
        await _presentPaymentSheet();
        completer.complete(_completed);
      } on StripeException catch (e) {
        if (e.error.code == FailureCode.Canceled) {
          globals.setButtonIdle();
          completer.complete(false);
          return;
        }
        final message = e.error.localizedMessage ??
            e.error.message ??
            'something_went_wrong'.tr;
        debugPrint("striperror: ${message}");
        if (message.isNotEmpty) _showSnackBar(message);
        globals.setButtonIdle();
        completer.complete(false);
      } catch (e) {
        globals.setButtonIdle();
        _showSnackBar(e.toString());
        completer.complete(false);
      }
    }, true);

    return completer.future;
  }

  Future<void> _presentPaymentSheet() async {
    _resetState();
    Stripe.publishableKey = globals.stripePublishableKey;
    Stripe.urlScheme = 'stripesdk';
    await Stripe.instance.applySettings();

    debugPrint("_presentPaymentSheet apply settings");
    await Stripe.instance.resetPaymentSheetCustomer();
    await _initPaymentSheet();

    await _presentInitializedPaymentSheet();
    await _handlePostPaymentSheet();
    globals.setButtonIdle();
  }

  Future<void> _initPaymentSheet() async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: globals.GOOGLE_PAY_MERCHANT_ORGANIZATION,
        intentConfiguration: IntentConfiguration(
          mode: _buildIntentMode(),
          paymentMethodTypes: const ['card'],
          confirmHandler: _handlePaymentSheetConfirm,
        ),
        billingDetails: BillingDetails(
          email: globals.email,
          phone: globals.phoneNumber,
          address: Address(
            country: globals.CountryCode,
            city: '',
            line1: '',
            line2: '',
            postalCode: '',
            state: '',
          ),
        ),
        style: globals.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      ),
    );
  }

  Future<void> _presentInitializedPaymentSheet() async {
    StripeException? lastException;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await Stripe.instance.presentPaymentSheet();
        return;
      } on StripeException catch (e) {
        final message = e.error.localizedMessage ?? e.error.message ?? '';
        if (!message.contains('No payment sheet has been initialized')) {
          rethrow;
        }
        lastException = e;
        await Stripe.instance.resetPaymentSheetCustomer();
        await Future.delayed(const Duration(milliseconds: 150));
        await _initPaymentSheet();
      }
    }
    throw lastException!;
  }

  IntentMode _buildIntentMode() {
    if (isFrom == 'wallet') {
      final amount = _toMinorUnits(_addCardController.Amount);
      return IntentMode.paymentMode(
        amount: amount,
        currencyCode: globals.preferredCurrency,
      );
    }
    return IntentMode.setupMode(
      currencyCode: globals.preferredCurrency,
      setupFutureUsage: IntentFutureUsage.OffSession,
    );
  }

  int _toMinorUnits(dynamic amount) {
    final parsed = double.tryParse(amount.toString()) ?? 0.0;
    return (parsed * 100).round();
  }

  Future<void> _handlePaymentSheetConfirm(
      PaymentMethod paymentMethod, bool shouldSavePaymentMethod) async {
    _currentPaymentMethodId = paymentMethod.id;
    _currentCardLast4 = paymentMethod.card.last4 ?? '';

    final clientSecret = await _createIntentForPaymentSheet(paymentMethod);
    if (clientSecret == null || clientSecret.isEmpty) {
      await _failPaymentSheet(_intentErrorMessage ?? 'something_went_wrong'.tr);
      return;
    }

    _currentClientSecret = clientSecret;
    await Stripe.instance.intentCreationCallback(
      IntentCreationCallbackParams(clientSecret: clientSecret),
    );
  }

  Future<String?> _createIntentForPaymentSheet(
      PaymentMethod paymentMethod) async {
    if (_currentCardLast4 == null || _currentCardLast4!.isEmpty) {
      _intentErrorMessage = 'something_went_wrong'.tr;
      return null;
    }

    if (isFrom == 'wallet') {
      final status = await _addCardController.addWalletAmount(
        paymentMethod.id,
        _addCardController.Amount,
        globals.preferredCurrency,
        1,
      );
      if (status == 'success') return _addCardController.secret;
      _intentErrorMessage = status;
      return null;
    }

    if (isFrom == 'addCard') {
      final status = await _addCardController.addCardDetails(
        paymentMethod.id,
        _currentCardLast4!,
      );
      if (status == 'success') return _addCardController.secret;
      _intentErrorMessage = status;
      return null;
    }

    if (isFrom == 'updateCard') {
      final status = await _addCardController.updateCardDetails(
        paymentMethod.id,
        _currentCardLast4!,
      );
      if (status == 'success') return _addCardController.secret;
      _intentErrorMessage = status;
      return null;
    }

    if (isFrom == 'confirmPopup') {
      final status = await _addCardController.addCardDetails(
        paymentMethod.id,
        _currentCardLast4!,
      );
      if (status == 'success') return _addCardController.secret;
      _intentErrorMessage = status;
      return null;
    }

    _intentErrorMessage = 'something_went_wrong'.tr;
    return null;
  }

  Future<void> _failPaymentSheet(String message) async {
    await Stripe.instance.intentCreationCallback(
      IntentCreationCallbackParams(
        error: StripeException(
          error: LocalizedErrorMessage(
            code: FailureCode.Failed,
            message: message,
            localizedMessage: message,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePostPaymentSheet() async {
    if (_currentClientSecret == null || _currentClientSecret!.isEmpty) {
      _showSnackBar('something_went_wrong'.tr);
      return;
    }

    if (isFrom == 'wallet') {
      await _confirmWalletTopup();
      return;
    }

    await _confirmCardSetup();
  }

  Future<void> _confirmWalletTopup() async {
    try {
      final paymentIntent =
      await Stripe.instance.retrievePaymentIntent(_currentClientSecret!);
      final paymentMethodId =
          paymentIntent.paymentMethodId ?? _currentPaymentMethodId ?? '';
      final last4 = _currentCardLast4 ?? '';

      final status = await _addCardController.confirmPaymentIntent(
        paymentIntent.id,
        true,
        paymentMethodId,
        _addCardController.Amount,
        globals.preferredCurrency,
        last4,
      );

      if (status == 'success') {
        _addCardController.walletAmount.clear();
        if (globals.checkNavWallet == 'updatePaymentToWallet') {
          _addCardController.updatepaymentMethod(3);
        }
        _completed = true;
      } else {
        globals.setButtonIdle();
        _showSnackBar(status);
        if (globals.bookingPaymentType == true) {
          globals.changePayment_and_Backnav?.changePayment_and_Backnav();
        }
      }
    } on StripeException catch (e) {
      final message = e.error.localizedMessage ?? '';
      globals.setButtonIdle();
      if (message.isNotEmpty) _showSnackBar(message.toString());
    }
  }

  Future<void> _confirmCardSetup() async {
    try {
      final setupIntent =
      await Stripe.instance.retrieveSetupIntent(_currentClientSecret!);
      final paymentMethodId = setupIntent.paymentMethodId;
      final last4 = _currentCardLast4 ?? '';

      final status = await _addCardController.ConfirmSetupIntent(
        setupIntent.id,
        true,
        paymentMethodId,
        last4,
      );

      if (status == 'success') {
        globals.cardLastFour = int.tryParse(last4) ?? 0;
        _addCardController.setPaymentType(true);
        _addCardController.cardLastFour = globals.cardLastFour;

        if (globals.checkNavPaymentType != 'notUpdatePaymenttype') {
          _addCardController.updatepaymentMethod(2);
        }
        _completed = true;
      } else {
        globals.setButtonIdle();
        _showSnackBar(status);
        if (globals.bookingPaymentType == true) {
          globals.changePayment_and_Backnav?.changePayment_and_Backnav();
        }
      }
    } on StripeException catch (e) {
      final message = e.error.localizedMessage ?? '';
      globals.setButtonIdle();
      if (message.isNotEmpty) _showSnackBar(message.toString());
      _addCardController.selectPaymentController.add(true);
    }
  }

  void _showSnackBar(String message) {
    _addCardController.showInSnackBar(message);
  }

  void _resetState() {
    _currentClientSecret = null;
    _currentPaymentMethodId = null;
    _currentCardLast4 = null;
    _intentErrorMessage = null;
    _completed = false;
  }
}