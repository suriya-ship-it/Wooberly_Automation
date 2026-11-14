import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pay_android/pay_android.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:pay_platform_interface/pay_channel.dart';
import 'package:pay_platform_interface/pay_platform_interface.dart';


const supportedProviders = {
  TargetPlatform.android: [PayProvider.google_pay],
  TargetPlatform.iOS: [PayProvider.apple_pay],
};

class Pay {
  /// The implementation of the platform interface to talk to the native ends.
  final PayPlatform _payPlatform;

  /// Map of configurations for the payment providers targeted.
  final Map<PayProvider, PaymentConfiguration> _configurations;

  /// Creates an instance with a dictionary of [_configurations] and
  /// instantiates the [_payPlatform] to communicate with the native platforms.
  Pay(this._configurations) : _payPlatform = PayMethodChannel();

  /// Determines whether a user can pay with the selected [provider].
  ///
  /// This method wraps the [userCanPay] method in the platform interface. It
  /// makes sure that the [provider] exists and is available in the platform
  /// running the logic.
  Future<bool> userCanPay(PayProvider provider) async {
    await throwIfProviderIsNotDefined(provider);
    if (supportedProviders[defaultTargetPlatform]!.contains(provider)) {
      return _payPlatform.userCanPay(_configurations[provider]!);
    }

    return Future.value(false);
  }

  /// Shows the payment selector to initiate a payment process.
  ///
  /// This method wraps the [showPaymentSelector] method in the platform
  /// interface, and opens the payment selector for the [provider] of choice,
  /// with the [paymentItems] in the price summary.
  Future<Map<String, dynamic>> showPaymentSelector(
      PayProvider provider,
      List<PaymentItem> paymentItems,
      ) async {
    await throwIfProviderIsNotDefined(provider);
    return _payPlatform.showPaymentSelector(
        _configurations[provider]!, paymentItems);
  }

  /// Verifies that the selected provider has been previously configured or
  /// throws otherwise.
  Future<void> throwIfProviderIsNotDefined(PayProvider provider) async {
    if (!_configurations.containsKey(provider)) {
      throw ProviderNotConfiguredException(
          'No configuration has been provided for the provider ($provider)');
    }
  }
}

/// Thrown to indicate that the configuration for a request provider has not
/// been provided.
class ProviderNotConfiguredException implements Exception {
  ProviderNotConfiguredException(this.message);

  /// A human-readable error message, possibly null.
  final String? message;

  @override
  String toString() => 'ProviderNotConfiguredException: $message';
}


class GooglePayButton extends PayButton {
  late final Widget _googlePayButton;

  GooglePayButton({
    super.key,
    super.buttonProvider = PayProvider.google_pay,
    required final PaymentConfiguration paymentConfiguration,
    super.onPaymentResult,
    required List<PaymentItem> paymentItems,
    int cornerRadius = RawGooglePayButton.defaultButtonHeight ~/ 2,
    GooglePayButtonTheme theme = GooglePayButtonTheme.dark,
    GooglePayButtonType type = GooglePayButtonType.buy,
    super.width = RawGooglePayButton.minimumButtonWidth,
    super.height = RawGooglePayButton.defaultButtonHeight,
    super.margin = EdgeInsets.zero,
    VoidCallback? onPressed,
    super.onError,
    super.childOnError,
    super.loadingIndicator,
  })  : assert(width >= RawGooglePayButton.minimumButtonWidth),
        assert(height >= RawGooglePayButton.defaultButtonHeight),
        super(paymentConfiguration: paymentConfiguration) {
    _googlePayButton = RawGooglePayButton(
        paymentConfiguration: paymentConfiguration,
        cornerRadius: cornerRadius,
        theme: theme,
        type: type,
        onPressed: _defaultOnPressed(onPressed, paymentItems));
  }

  @override
  final List<TargetPlatform> _supportedPlatforms = [TargetPlatform.android];

  @override
  late final Widget _payButton = _googlePayButton;

  @override
  final bool _collectPaymentResultSynchronously = false;

  @override
  State<PayButton> createState() => _GooglePayButtonState();
}

class _GooglePayButtonState extends _PayButtonState {
  static const eventChannel =
  EventChannel('plugins.flutter.io/pay/payment_result');
  StreamSubscription<Map<String, dynamic>>? _paymentResultSubscription;

  @override
  void _preparePaymentResultStream() {
    _paymentResultSubscription = eventChannel
        .receiveBroadcastStream()
        .cast<String>()
        .map(jsonDecode)
        .cast<Map<String, dynamic>>()
        .listen(widget._deliverPaymentResult, onError: widget._deliverError);
  }

  @override
  void dispose() {
    _paymentResultSubscription?.cancel();
    _paymentResultSubscription = null;
    super.dispose();
  }
}

abstract class PayButton extends StatefulWidget {
  /// A resident client to issue requests against the APIs.
  final Pay _payClient;

  /// Specifies the payment provider supported by the button
  final PayProvider buttonProvider;

  /// A function called when the payment process yields a result.
  final void Function(Map<String, dynamic> result)? onPaymentResult;

  final double width;
  final double height;
  final EdgeInsets margin;

  /// A function called when there's an error in the payment process.
  final void Function(Object? error)? onError;

  /// A replacement widget shown instead of the button when the payment process
  /// errors. This can be used to show a different checkout button or an error
  /// message.
  final Widget? childOnError;

  /// An optional widget to show while the payment provider checks whether
  /// a user can pay with it and the button loads.
  final Widget? loadingIndicator;

  /// Initializes the button and the payment client that handles the requests.
  PayButton({
    super.key,
    required this.buttonProvider,
    required final PaymentConfiguration paymentConfiguration,
    this.onPaymentResult,
    this.width = 0,
    this.height = 0,
    this.margin = const EdgeInsets.all(0),
    this.onError,
    this.childOnError,
    this.loadingIndicator,
  }) : _payClient = Pay({buttonProvider: paymentConfiguration});

  /// Determines the list of supported platforms for the button.
  List<TargetPlatform> get _supportedPlatforms;

  /// Accessor for the widget to show as the payment button.
  ///
  /// This method returns a [Widget] that is conditionally shown based on the
  /// result of the `isReadyToPay` request.
  Widget get _payButton;

  /// Defines the strategy to return payment data information to the caller.
  ///
  /// This field is defined by implementations of this class to determine if the
  /// payment result is returned right after calling [Pay.showPaymentSelector]
  /// or rather received through asynchronous means (e.g.: an event stream).
  bool get _collectPaymentResultSynchronously;

  /// Determines whether the current platform is supported by the button.
  bool get _isPlatformSupported =>
      _supportedPlatforms.contains(defaultTargetPlatform);

  @override
  State<PayButton> createState() => _PayButtonState();

  /// Callback function to respond to tap events.
  ///
  /// This is the default function for tap events. Calls the [onPressed]
  /// function if set, and initiates the payment process with the [paymentItems]
  /// specified.
  VoidCallback _defaultOnPressed(
      VoidCallback? onPressed, List<PaymentItem> paymentItems) {
    return () async {
      onPressed?.call();
      try {
        final result =
        await _payClient.showPaymentSelector(buttonProvider, paymentItems);
        if (_collectPaymentResultSynchronously) _deliverPaymentResult(result);
      } catch (error) {
        _deliverError(error);
      }
    };
  }

  void _deliverPaymentResult(Map<String, dynamic> result) {
    onPaymentResult?.call(result);
  }

  void _deliverError(error) {
    onError?.call(error);
  }
}

/// Button state that adds the widgets to the tree and holds the result of the
/// `userCanPay` request.
///
/// This state executes the logic that shows the [loadingIndicator] while the
/// button loads. If the payment provider is available for a given user, the
/// [_payButton] is added to the tree. Otherwise, if set, the replacement widget
/// in [childOnError] is shown.
class _PayButtonState extends State<PayButton> {
  late final Future<bool> _userCanPayFuture;

  /// A method to initialize payment result streams
  ///
  /// Some platforms supported by this plugin, use [EventChannel]s to relay
  /// payment results back to Flutter. This method lets platform-specific
  /// implementations, set up necessary business logic to subscribe to event
  /// channel streams and deliver results to implementers of the API.
  void _preparePaymentResultStream() {}

  Future<bool> _userCanPay() async {
    try {
      return await widget._payClient.userCanPay(widget.buttonProvider);
    } catch (error) {
      widget.onError?.call(error);
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget._isPlatformSupported) return;

    _userCanPayFuture = _userCanPay();

    if (!widget._collectPaymentResultSynchronously) {
      _preparePaymentResultStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._isPlatformSupported) {
      return const SizedBox.shrink();
    }

    // Future builder running the `userCanPayFuture` and decides what to show
    // based on the result.
    return FutureBuilder<bool>(
      future: _userCanPayFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return Container(
              margin: widget.margin,
              width: widget.width,
              height: widget.height,
              child: widget._payButton,
            );
          } else {
            return ButtonPlaceholder(
              margin: widget.margin,
              child: widget.childOnError,
            );
          }
        }

        return ButtonPlaceholder(
          margin: widget.margin,
          child: widget.loadingIndicator,
        );
      },
    );
  }
}

/// Shows the appropriate widget based on the API requests above, respecting the
/// [margin] if the [child] is set.
class ButtonPlaceholder extends StatelessWidget {
  final Widget? child;
  final EdgeInsets margin;

  const ButtonPlaceholder({
    super.key,
    this.child,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return child == null
        ? const SizedBox.shrink()
        : Container(margin: margin, child: child);
  }
}