import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:pay_android/pay_android.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/pay.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/trip_detail_view.dart';
import '../../app/app_routes.dart';
import '../../app/enums/button_state.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../primary_scaffold.dart';
import '../single_tap_event.dart';
import 'location_data_widget.dart';

class TripAmount extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  TripAmount({Key? key}) : super(key: key);

  @override
  State<TripAmount> createState() => TripAmountState();
}

class TripAmountState extends State<TripAmount> {
  bool isToolTipShown = false;
  JustTheController tooltipController = JustTheController();
  Map<PayProvider, PaymentConfiguration> config =
  Map<PayProvider, PaymentConfiguration>();
  late Pay _payClient;

  String defaultGooglePay = '''{
  "provider": "google_pay",
  "data": {
    "environment": "${globals.stripePublishableKey.contains("pk_test") ? "TEST" : "PRODUCTION"}",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "stripe",
            "stripe:version": "2020-08-27",
            "stripe:publishableKey": "${globals.stripePublishableKey}"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["AMEX", "DISCOVER", "INTERAC", "JCB", "MASTERCARD", "MIR", "VISA"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false,
          "assuranceDetailsRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "${globals.GOOGLE_PAY_MERCHANT_ID}",
      "merchantName": "${globals.GOOGLE_PAY_MERCHANT_ORGANIZATION}"
    },
    "transactionInfo": {
      "currencyCode": "${globals.preferredCurrency}"
    }
  }
}''';

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = globals.stripePublishableKey;
    Stripe.urlScheme = 'stripesdk';
    Stripe.merchantIdentifier = null;
    Stripe.instance.applySettings();
    print(" Stripe.publishableKey: ${Stripe.publishableKey}");
    PaymentConfiguration paymentConfig =
    PaymentConfiguration.fromJsonString(defaultGooglePay);
    config[PayProvider.google_pay] = paymentConfig;
    _payClient = Pay(config);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SlideTransition(
            position: widget.mapMainController.tripAmountOffset!,
            child: PrimaryScaffold(
              appBarTitle: 'trip_details'.tr,
              backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
              loader: '',
              appBarImage: '',
              customAppBarFunction: () {
                if (isToolTipShown) {
                  tooltipController.hideTooltip();
                } else {
                  widget.mapMainController.tripAmountController?.reverse();
                }
              },
              body: Obx(
                    () {
                  if (widget.mapMainController.tripStatusResult != null &&
                      widget.mapMainController.finalAmountController.value != 0.0) {
                    widget.mapMainController.driverName =
                    widget.mapMainController.tripStatusResult["result"]
                    ["driverDetails"]['firstName'];
                    widget.mapMainController.bookingId = widget
                        .mapMainController.tripStatusResult["result"]['id'];
                    widget.mapMainController.driverId = widget.mapMainController
                        .tripStatusResult["result"]['driverId'];
                    return Stack(alignment: Alignment.bottomCenter, children: [
                      Builder(builder: (_) {
                        if (widget.mapMainController.tripStatusResult["result"]
                        ["isTipGiven"] ||
                            globals.preferredPaymentMethod != 1)
                          widget.mapMainController.rideCurrency =
                              globals.preferredPaymentMethod;
                        else if (!widget.mapMainController
                            .tripStatusResult["result"]["isTipGiven"] &&
                            globals.preferredPaymentMethod == 1)
                          widget.mapMainController.rideCurrency =
                              globals.preferredPaymentMethod;
                        else
                          widget.mapMainController.rideCurrency = widget
                              .mapMainController
                              .tripStatusResult["result"]['paymentType'];
                        debugPrint(
                            "widget.mapMainController.tripFinalAmount:  3 ${widget.mapMainController.tripFinalAmount} -- ${widget.mapMainController.finalAmountController.value} --- ${widget
                                .mapMainController.tripStatusResult['isTipGiven']} --- ${widget.mapMainController.rideCurrency}");
                        widget.mapMainController.tripFinalAmount = double.parse(
                            double.parse(widget.mapMainController.finalAmountController.value.toString()).toStringAsFixed(2));
                        _getTotalAmount();
                        return TripDetailItemView(
                          selectedComfortRide: widget.mapMainController
                              .tripStatusResult["result"]['comfortRide'],
                          selectedTrip: widget
                              .mapMainController.tripStatusResult["result"],
                          tooltipController: tooltipController,
                          context: context,
                          isToolTipShown: isToolTipShown,
                          locationDataWidget: LocationDataWidget(),
                          UsedPage: 'trip_summary',
                          ridePaymentType:
                          widget.mapMainController.rideCurrency,
                          tipsAddClick: () {
                            if (widget.mapMainController.tripFinalAmount <= 0.0)
                              _getTotalAmount();
                            widget.mapMainController
                                .setNavigation(AppRoutes.APP_SHOW_TIP);
                          },
                          tipsRemoveClick: () {
                            widget.mapMainController.tipsAmount.text = "";
                            widget.mapMainController
                                .updateTips(
                                widget.mapMainController.rideCurrency)
                                .then((value) {
                              widget.mapMainController.getRideStatus();
                            });
                          },
                        );
                      }),
                      Positioned(
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                                color: AppColors.PRIMARY_LIGHT_COLOR,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 10.0,
                                    spreadRadius: 5.1,
                                  )
                                ]),
                            child: Obx(() {
                              return Column(
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  _getPaymentWidget(
                                      widget.mapMainController.rideCurrency,
                                      widget.mapMainController
                                          .paymentStatusController.value),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  widget.mapMainController.rideCurrency == 4 &&
                                      Platform.isAndroid
                                      ? Container(
                                    height: 60,
                                    width: MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.9,
                                    child: GooglePayButton(
                                      loadingIndicator: Center(
                                        child: CircularProgressIndicator(
                                          color:
                                          AppColors.BLACK_TEXT_COLOR,
                                        ),
                                      ),
                                      type: GooglePayButtonType.pay,
                                      onPressed: onGooglePayPressed,
                                      onPaymentResult: googlePayResult,
                                      paymentConfiguration:
                                      config[PayProvider.google_pay]!,
                                      paymentItems: [
                                        PaymentItem(
                                          label: 'total_bill'.tr,
                                          amount:
                                          '${widget.mapMainController.amountSendToPayPlugin}',
                                          status: PaymentItemStatus
                                              .final_price,
                                        )
                                      ],
                                    ),
                                  )
                                      : Padding(
                                    padding:
                                    const EdgeInsetsDirectional.only(
                                        start: 24,
                                        end: 24,
                                        bottom: 24),
                                    child: PrimaryButton(
                                      buttonTitle: 'confirm_label'.tr,
                                      buttonImage: primaryRightArrowSvg,
                                      callback: () {
                                        if ((globals.cardLastFour == 0 ||globals.cardLastFour ==null)  && widget.mapMainController.rideCurrency == 2) {
                                          widget.mapMainController.showInSnackBar('please_enter_correct_card_details'.tr);
                                          return;
                                        } else if (globals.selectedPaymentType.value == 3 && double.parse( widget.mapMainController.tripFinalAmount.toString()) > globals.walletBalance.value) {
                                          widget.mapMainController.showInSnackBar('wallet_not_enough'.tr);
                                          return;
                                        }
                                        widget.mapMainController
                                            .checkInternet(() {
                                          widget.mapMainController
                                              .getPaymentMethods()
                                              .then((value) {
                                            if ((globals.paymentMethods
                                                ?.contains(globals
                                                .preferredPaymentMethod) ??
                                                false) &&
                                                (globals.paymentMethods
                                                    ?.contains(widget
                                                    .mapMainController
                                                    .rideCurrency) ??
                                                    false)) {


                                              if (widget
                                                  .mapMainController
                                                  .paymentStatusController
                                                  .value ==
                                                  0) {
                                                widget.mapMainController
                                                    .paymentStatusController(
                                                    1);
                                                globals.buttonState
                                                    .value =
                                                    ButtonState.loading;
                                                widget.mapMainController
                                                    .sendTripPayment();
                                                widget.mapMainController
                                                    .onsendTripPayment(
                                                    'tripPayment-${globals.userid}',
                                                        () {
                                                      if (globals.preferredPaymentMethod !=
                                                          5 &&
                                                          globals.preferredPaymentMethod !=
                                                              6) {
                                                        if (globals
                                                            .preferredPaymentMethod ==
                                                            3)
                                                          globals
                                                              .walletBalance
                                                              .value = globals
                                                              .walletBalance
                                                              .value -
                                                              widget
                                                                  .mapMainController
                                                                  .tripFinalAmount;
                                                        widget
                                                            .mapMainController
                                                            .tripFinalAmount = null;
                                                        widget
                                                            .mapMainController
                                                            .tripAmountController
                                                            ?.reverse();
                                                        widget.mapMainController
                                                            .isFromtrips =
                                                        false;
                                                        widget
                                                            .mapMainController
                                                            .clearMap();
                                                        widget
                                                            .mapMainController
                                                            .setNavigation(
                                                            AppRoutes
                                                                .APP_SHOW_REVIEW);
                                                      } else {
                                                        if (globals
                                                            .preferredPaymentMethod ==
                                                            6)
                                                          Get.toNamed(
                                                              AppRoutes
                                                                  .APP_PAYPAL_DISPLAY,
                                                              arguments: {
                                                                'payPalURL':
                                                                '${widget.mapMainController.payPalURL}',
                                                                'bookingId':
                                                                '',
                                                                'isFrom':
                                                                'paypal',
                                                              })?.then(
                                                                  (value) {
                                                                if (value == "") {
                                                                  widget
                                                                      .mapMainController
                                                                      .tripFinalAmount = null;
                                                                  widget
                                                                      .mapMainController
                                                                      .tripAmountController
                                                                      ?.reverse();
                                                                  widget.mapMainController
                                                                      .isFromtrips =
                                                                  false;
                                                                  widget
                                                                      .mapMainController
                                                                      .clearMap();
                                                                  widget
                                                                      .mapMainController
                                                                      .setNavigation(
                                                                      AppRoutes
                                                                          .APP_SHOW_REVIEW);
                                                                }
                                                                widget
                                                                    .mapMainController
                                                                    .paymentStatusController(
                                                                    0);
                                                              });
                                                        if (globals
                                                            .preferredPaymentMethod ==
                                                            5)
                                                          Get.toNamed(
                                                            "/PayStackWebView",
                                                            arguments: {
                                                              'payStackURL': widget
                                                                  .mapMainController
                                                                  .payStackURL,
                                                              'payStackRef': widget
                                                                  .mapMainController
                                                                  .payStackRef,
                                                              'isFrom':
                                                              'bookingPayment',
                                                            },
                                                          )?.then((value) {
                                                            if (value ==
                                                                "close")
                                                              widget
                                                                  .mapMainController
                                                                  .paymentStatusController(
                                                                  0);
                                                          });
                                                      }
                                                    });
                                              }
                                            } else {
                                              widget.mapMainController
                                                  .showInSnackBar(
                                                  'payment_method_error'
                                                      .tr);
                                            }
                                          });
                                        }, false);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      )
                    ]);
                  } else {
                    return widget.mapMainController.finalAmountController.value !=
                        0.0
                        ? widget.mapMainController.getProgressIndicator()
                        : const SizedBox.shrink();
                  }
                },
              ),
            ),
        ),
    );
  }

  void onGooglePayPressed() async {
    globals.setButtonLoading();
    widget.mapMainController.paymentStatusController(1);
    widget.mapMainController.createPaymentIntent(true).then((value) async {
      if (value.isEmpty) {
        try {
          _payClient.showPaymentSelector(PayProvider.google_pay, [
            PaymentItem(
              label: 'total_bill'.tr,
              amount: '${widget.mapMainController.amountSendToPayPlugin}',
              status: PaymentItemStatus.final_price,
            )
          ]).then((value) async {
            final token =
            value['paymentMethodData']['tokenizationData']['token'];
            widget.mapMainController.callStripeForGooglePay(token, () {
              widget.mapMainController.tripFinalAmount = null;
              widget.mapMainController.tripAmountController?.reverse();
              widget.mapMainController.mapPaddingController.refresh();
              widget.mapMainController.setNavigation(AppRoutes.APP_SHOW_REVIEW);
            });
          });
        } on Exception catch (e) {
          widget.mapMainController.paymentStatusController(0);
          print("Final google pay Error $e");
        }
      } else {
        widget.mapMainController.paymentStatusController(0);
      }
    });
  }

  googlePayResult(value) {
    final token = value['paymentMethodData']['tokenizationData']['token'];
    widget.mapMainController.callStripeForGooglePay(token, () {
      widget.mapMainController.tripFinalAmount = null;
      widget.mapMainController.tripAmountController?.reverse();
      widget.mapMainController.setNavigation(AppRoutes.APP_SHOW_REVIEW);
    });
  }

  _getPaymentWidget(paymentitem, int click) {
    String svgimage, paymentText;
    final paymentData = {
      2: (text: 'credit_debit'.tr, svg: creditCardSvg),
      3: (text: 'wallet'.tr, svg: walletSvg),
      4: (text: 'Google Pay', svg: googlePaySvg),
      5: (text: 'PayStack', svg: payStackSvg),
      6: (text: 'PayPal', svg: paypalPaymentSvg),
    };

    final selected =
        paymentData[paymentitem] ?? (text: 'cash'.tr, svg: moneySvg);
    paymentText = selected.text;
    svgimage = selected.svg;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: paymentitem == 6
                ? SvgPicture.asset(
              paypalPaymentSvg,
              width: 25.0,
              height: 25.0,
              placeholderBuilder: (context) =>
                  CircularProgressIndicator(),
            )
                : paymentitem == 4
                ? SvgPicture.asset(
              svgimage,
              width: 40.0,
              height: 35.0,
              placeholderBuilder: (context) =>
                  CircularProgressIndicator(),
            )
                : paymentitem == 5
                ? SvgPicture.asset(
              svgimage,
              width: 15.0,
              height: 15.0,
              placeholderBuilder: (context) =>
                  CircularProgressIndicator(),
            )
                : SvgPicture.asset(
              svgimage,
              width: 20.0,
              height: 15.0,
              placeholderBuilder: (context) =>
                  CircularProgressIndicator(),
              colorFilter: ColorFilter.mode(
                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
          ),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
            child: Text(
              paymentText,
              style: TextStyle(
                  fontFamily: AppFont.font,
                  fontSize: AppDimen.text_size_16,
                  color: AppColors.BLACK_TEXT_COLOR),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SingleTapEvent(
            onTap: () {
              print("===>>>---calling_click  ${click}");
              if (click == 0) {
                globals.selectedPaymentType.value = paymentitem;
                widget.mapMainController.paymentStatusController(1);
                widget.mapMainController.getPaymentMethods().then((value) {
                  widget.mapMainController.setTotalFareController(
                      widget.mapMainController.tripFinalAmount);
                  widget.mapMainController.tripAmountController?.reverse();
                  widget.mapMainController.confirmPopupAnimController
                      ?.forward();
                });
              }
            },
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                toBeginningOfSentenceCase('change'.tr.toLowerCase())!,
                style: TextStyle(
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_16,
                    color: AppColors.PROMOCODE_LINK_COLOR),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _getTotalAmount() {
    String riderTotal = '';
    if (widget.mapMainController.tripStatusResult["result"]["isSpecialTrip"] && !widget.mapMainController.tripStatusResult["result"]
    ["isTipGiven"]) {
      riderTotal =
          double.parse(widget.mapMainController.getRate(
          widget.mapMainController.tripStatusResult["result"]["currency"],
          widget.mapMainController.tripStatusResult["result"]
          ["specialTripTotalFare"]))
          .toStringAsFixed(2);
    } else if (widget.mapMainController.tripStatusResult["result"]
    ["isTipGiven"] &&
        widget.mapMainController.tripStatusResult["result"]['paymentType'] !=
            1) {
      riderTotal =
   //   widget.mapMainController.tripStatusResult["result"]["tipsTotalFare"];
          double.parse(widget.mapMainController.getRate(
          widget.mapMainController.tripStatusResult["result"]["currency"],
          widget.mapMainController.tripStatusResult["result"]
          ["tipsTotalFare"]))
          .toStringAsFixed(2);
      debugPrint("widget.mapMainController.tripFinalAmount: abc  ${riderTotal} --- ${widget.mapMainController.vehicleCatAnimController?.status}");
    } else {
      riderTotal = double.parse(widget.mapMainController.getRate(
          widget.mapMainController.tripStatusResult["result"]["currency"],
          widget.mapMainController.tripStatusResult["result"]
          ["riderTotalFare"]))
          .toStringAsFixed(2);
    }
    debugPrint("widget.mapMainController.tripFinalAmount: 2  ${riderTotal} --- ${widget.mapMainController.vehicleCatAnimController?.status}");

    if(widget.mapMainController.tripStatusResult["result"]["paymentStatus"] != "completed")
    widget.mapMainController.tripFinalAmount = double.parse(riderTotal);
  }
}