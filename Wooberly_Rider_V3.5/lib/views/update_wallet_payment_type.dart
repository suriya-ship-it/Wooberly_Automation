import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/payment_container.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../controllers/add_card_controller.dart';
import '../widgets/primary_button.dart';
import 'package:app_name/services/payment_sheet_service.dart';

class UpdateWalletPaymentType extends StatefulWidget {
  const UpdateWalletPaymentType({Key? key}) : super(key: key);

  @override
  State<UpdateWalletPaymentType> createState() => _UpdateWalletPaymentTypeState();
}

class _UpdateWalletPaymentTypeState extends State<UpdateWalletPaymentType> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  AddCardController _addCardController = Get.find();

  @override
  Widget build(BuildContext context) {
    _addCardController.updateWalletPaymentType.value = (globals.paymentMethods?.contains(2) ?? false)
        ? 1
        : (globals.paymentMethods?.contains(5) ?? false)
            ? 2
            : 0;
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        key: _scaffoldKey,
        disableAppbar: false,
        appBarTitle: 'payment_method'.tr,
        customAppBarFunction: () {
          _addCardController.setBackNavigation();
        },
        body: Obx(() {
          return Stack(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: AppColors.COMMON_BG_COLOR,
                ),
                child: ListView(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    PaymentContainer(
                      isVisible: globals.paymentMethods?.contains(2),
                      paymentTitle: "Stripe",
                      paymentSvg: stripeSvg,
                      paymentId: _addCardController.updateWalletPaymentType.value,
                      paymentValue: 1,
                      callback: () {
                        _addCardController.updateWalletPaymentType.value = 1;
                      },
                    ),
                    PaymentContainer(
                      isVisible: globals.paymentMethods?.contains(5),
                      paymentTitle: "PayStack",
                      paymentSvg: payStackSvg,
                      svgHeight: 15.0,
                      svgWidth: 15.0,
                      paymentId: _addCardController.updateWalletPaymentType.value,
                      paymentValue: 2,
                      callback: () {
                        _addCardController.updateWalletPaymentType.value = 2;
                      },
                    ),
                    PaymentContainer(
                      isVisible: globals.paymentMethods?.contains(6),
                      paymentTitle: "PayPal",
                      paymentSvg: paypalPaymentSvg,
                      svgHeight: 15.0,
                      svgWidth: 15.0,
                      paymentId: _addCardController.updateWalletPaymentType.value,
                      paymentValue: 6,
                      callback: () {
                        _addCardController.updateWalletPaymentType.value = 6;
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
                  child: PrimaryButton(
                      buttonTitle: 'Next'.tr,
                      buttonImage: primaryBtnArrow,
                      isLoad: true,
                      callback: () async {
                        _addCardController.checkInternet(() async {
                          _addCardController.getPaymentMethods().then((value) async{
                            if (value.isNotEmpty) {
                              _addCardController.showInSnackBar(value);
                              debugPrint("selected globals.paymentMethods: ${globals.paymentMethods}");
                            } else if (((globals.paymentMethods?.contains(2) ?? false) ||
                                    (globals.paymentMethods?.contains(5) ?? false)) &&
                                (globals.paymentMethods?.contains(3) ?? false)) {
                              if (_addCardController.updateWalletPaymentType.value == 2 &&
                                  (globals.paymentMethods?.contains(5) ?? false)) {
                                _addCardController
                                    .addWalletAmount(
                                        "", _addCardController.Amount, globals.preferredCurrency, 5)
                                    .then((value) {
                                  if (value == "success") {
                                    Get.toNamed(
                                      "/PayStackWebView",
                                      arguments: {
                                        'payStackURL': _addCardController.payStackURL,
                                        'payStackRef': _addCardController.payStackRef,
                                        'isFrom': 'walletPayment',
                                      },
                                    )?.then((value) {
                                      if (value.toString() != "close") {
                                        _addCardController.walletAmount.clear();
                                        globals.walletBalance.refresh();
                                        globals.setButtonIdle();
                                        Get.back();
                                      }
                                    });
                                    globals.setButtonIdle();
                                  } else {
                                    globals.setButtonIdle();
                                    _addCardController.showInSnackBar(value);
                                  }
                                });
                              } else if (_addCardController.updateWalletPaymentType.value == 1 &&
                                  (globals.paymentMethods?.contains(2) ?? false)) {
                                _addCardController.check = 1;
                                try {
                                  if (globals.stripePublishableKey != null &&
                                      globals.stripePublishableKey.isNotEmpty) {
                                    final success = await PaymentSheetService.start(
                                      context: context,
                                      isFrom: "wallet",
                                    );
                                    if (success) {
                                      _addCardController.walletAmount.clear();
                                      globals.walletBalance.refresh();
                                      globals.setButtonIdle();
                                      Get.back();
                                    }
                                  } else {
                                    _addCardController.showInSnackBar('stripe_key_empty_error'.tr);
                                  }
                                } catch (error) {}
                              } else if (globals.paymentMethods!.contains(6)) {
                                _addCardController
                                    .addWalletAmount(
                                        "", _addCardController.Amount, globals.preferredCurrency, 6)
                                    .then((value) {
                                  if (value == "success") {
                                    _addCardController.setLoadingControllerWallet(false);
                                    Get.toNamed(AppRoutes.APP_PAYPAL_DISPLAY, arguments: {
                                      'payPalURL': '${_addCardController.payPalURL}',
                                      'bookingId': '',
                                      'isFrom': 'paypal',
                                    })?.then((value) {
                                      if (value.toString() != "close") {
                                        _addCardController.walletAmount.clear();
                                        globals.walletBalance.refresh();
                                        globals.setButtonIdle();
                                        Get.back();
                                      } else {
                                        _addCardController.updateWalletPaymentType.value = 6;
                                      }
                                      _addCardController.setLoadingControllerWallet(false);
                                    });
                                  } else if (value.isNotEmpty) {
                                    _addCardController.setLoadingControllerWallet(false);
                                    _addCardController.showInSnackBar(value);
                                  }
                                });
                              } else {
                                _addCardController.showInSnackBar('payment_method_error'.tr);
                              }
                            } else {
                              _addCardController.showInSnackBar('payment_method_error'.tr);
                            }
                          });
                        }, false);
                      }),
                ),
              ),
            ],
          );
        }),
        onChanged: (map) {
          _scaffoldKey = map["scaffoldkey"];
        },
      );
    });
  }
}