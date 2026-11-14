import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/interfaces/change_payment_type.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/add_card_controller.dart';
import 'package:app_name/services/payment_sheet_service.dart';
import 'package:app_name/widgets/payment_container.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_scaffold.dart';

class PaymentType extends StatefulWidget {
  @override
  _PaymentTypeState createState() => new _PaymentTypeState();
}

class _PaymentTypeState extends State<PaymentType> implements changePayment_and_Backnav_Interface {
  AddCardController _addCardController = Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;
  bool isloading = false;

  @override
  void initState() {
    super.initState();
    globals.changePayment_and_Backnav = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addCardController.setLoadingControllerPayType(false);
      globals.setButtonLoading();
      globals.locController(false);
      Future.delayed(const Duration(seconds: 1), () {
        getPaymentMethods();
      });
    });

    if (globals.cardLastFour != null &&globals.cardLastFour != 0 && _addCardController.cardNumberController != null) {
      _addCardController.cardNumberController.text = globals.cardLastFour.toString();
      _addCardController.cardLastFour = globals.cardLastFour.toString();
      _addCardController.update(['paymentController']);
      _addCardController.isCardAdded = true;
    }
    _addCardController.selectPaymentController.add(false);
    _addCardController.value = globals.preferredPaymentMethod;
    globals.selectedPaymentType.value = (_addCardController.value);

    Future.delayed(const Duration(milliseconds: 5), () {
      _addCardController.checkInternet(() {}, false).then((value) {
        if (value)
          _addCardController.setLoadingControllerPayType(false);
        else
          _addCardController.setLoadingControllerPayType(true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _addCardController.isPaymentAdded();
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        key: _scaffoldKey,
        disableAppbar: false,
        appBarTitle: 'payment_method'.tr,
        customAppBarFunction: () {
          _addCardController.setBackNavigation();
          globals.locController(true);
        },
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: AppColors.COMMON_BG_COLOR,
              ),
              child: Obx(() {
                return ListView(
                  children: <Widget>[
                    ...?globals.paymentMethods?.value.map((paymentId) {
                      final _paymentItemMap = _addCardController.paymentItemMap(
                        paymentOnTap: () async {
                          if (paymentId == 1 || paymentId == 4 || paymentId == 5 || paymentId == 6) {
                            if (_addCardController.value != paymentId) {
                              _addCardController.setLoadingControllerPayType(true);
                              if (globals.bookingPaymentType == false) {
                                updatePaymentMethod(paymentId);
                              } else {
                                _addCardController.setLoadingControllerPayType(false);
                                _addCardController.setBackNavigation();
                              }
                            } else {
                              if (globals.bookingPaymentType == true) {
                                _addCardController.setBackNavigation();
                              }
                            }
                          } else if (paymentId == 2) {
                            if (_addCardController.value != 2) {
                              _addCardController.setLoadingControllerPayType(true);
                              if (globals.bookingPaymentType == false) {
                                if (globals.stripePublishableKey == null ||
                                    globals.stripePublishableKey.isEmpty) {
                                  _addCardController.setLoadingControllerPayType(false);
                                }
                              } else {
                                _addCardController.setLoadingControllerPayType(false);
                                if (_addCardController.isCardAdded) {
                                  _addCardController.setBackNavigation();
                                }
                              }
                            } else {
                              if (globals.bookingPaymentType == true) {
                                _addCardController.setLoadingControllerPayType(false);
                                if (_addCardController.isCardAdded) {
                                  _addCardController.setBackNavigation();
                                }
                              }
                            }
                            if (!_addCardController.isCardAdded) {
                              try {
                                if (globals.stripePublishableKey != null &&
                                    globals.stripePublishableKey.isNotEmpty) {
                                  _addCardController.check = 0;
                                  _addCardController.setLoadingControllerPayType(false);
                                  await PaymentSheetService.start(
                                    context: context,
                                    isFrom: "addCard",
                                  );
                                  if (_addCardController.isCardAdded) {
                                    _addCardController.value = 2;
                                    globals.selectedPaymentType.value = (2);
                                  }
                                } else {
                                  _addCardController.showInSnackBar('stripe_key_empty_error'.tr);
                                }
                              } catch (error) {}
                            } else {
                              _addCardController.setLoadingControllerPayType(true);
                              updatePaymentMethod(2);
                            }
                          } else if (paymentId == 3) {
                            if (globals.walletBalance.value < 1) {
                              _addCardController.check = 0;
                              _addCardController.setLoadingControllerPayType(false);
                              if (globals.bookingPaymentType == true) {
                                _addCardController.setBackNavigation();
                              }
                              globals.checkNavWallet = "updatePaymentToWallet";
                              _addCardController.setNavigation(AppRoutes.APP_WALLET);
                            } else {
                              if (_addCardController.value != 3) {
                                _addCardController.setLoadingControllerPayType(true);
                                if (globals.bookingPaymentType == false) {
                                  updatePaymentMethod(3);
                                } else {
                                  _addCardController.setLoadingControllerPayType(false);
                                  _addCardController.setBackNavigation();
                                }
                              } else {
                                if (globals.bookingPaymentType == true) {
                                  _addCardController.setBackNavigation();
                                }
                              }
                            }
                          }
                          Future.delayed(Duration(seconds: 1), () => globals.paymentMethods?.refresh());
                        },
                      );
                      return PaymentContainer(
                        paymentTitle: _paymentItemMap[paymentId]['paymentName'],
                        paymentValue: _addCardController.value,
                        paymentId: _paymentItemMap[paymentId]['paymentId'],
                        paymentSvg: _paymentItemMap[paymentId]['paymentSvg'],
                        callback: _paymentItemMap[paymentId]['paymentOnTap'],
                        svgColorFilter: paymentId == 1 || paymentId == 2 || paymentId == 3
                            ? ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn)
                            : null,
                      );
                    }).toList(),
                    GetBuilder<AddCardController>(
                        id: 'paymentController',
                        builder: (_) {
                          debugPrint("_addCardController.cardLastFour: ${globals.cardLastFour is  String} ---abc ${globals.cardLastFour} --- ${_addCardController.isCardAdded}");
                          return _addCardController.isCardAdded &&
                                  (globals.paymentMethods?.contains(2) ?? false) &&
                                  _addCardController.cardLastFour != null
                              ? Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 30),
                                      child: Text(
                                        'agree_payment_type'.trParams({'field': globals.APP_NAME}),
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontFamily: AppFont.font,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Card(
                                      color: AppColors.PRIMARY_LIGHT_COLOR,
                                      child: Container(
                                        height: 50,
                                        margin: const EdgeInsetsDirectional.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            SvgPicture.asset(
                                              creditCardSvg,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                            ),
                                            const SizedBox(
                                              width: 10.0,
                                            ),
                                            Expanded(
                                              child: Text(
                                                "**** **** **** ${_addCardController.cardLastFour}",
                                                style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontFamily: AppFont.font,
                                                  fontSize: AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                try {
                                                  if (globals.stripePublishableKey != null &&
                                                      globals.stripePublishableKey.isNotEmpty) {
                                                    _addCardController.check = 0;
                                                    await PaymentSheetService.start(
                                                      context: context,
                                                      isFrom: "updateCard",
                                                    );
                                                  } else {
                                                    _addCardController
                                                        .showInSnackBar('stripe_key_empty_error'.tr);
                                                  }
                                                } catch (error) {
                                                  debugPrint("card error5: " + error.toString());
                                                }
                                              },
                                              child: Container(
                                                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10.0),
                                                  alignment: AlignmentDirectional.centerEnd,
                                                  child: SvgPicture.asset(
                                                    editingSvg,
                                                    colorFilter: ColorFilter.mode(
                                                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                  )),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                _asyncConfirmDialog(context);
                                              },
                                              child: Container(
                                                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10.0,),
                                                  alignment: AlignmentDirectional.centerEnd,
                                                  child: SvgPicture.asset(
                                                    deleteSVG,
                                                    colorFilter: ColorFilter.mode(
                                                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                  )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink();
                        }),
                  ],
                );
              }),
            ),
          ],
        ),
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
          _addCardController.paymentTypeContext = scoffoldcontext;
          _scaffoldKey = map["scaffoldkey"];
        },
      );
    });
  }

  Future<void> _asyncConfirmDialog(BuildContext context) async {
    return _addCardController.showConfirmationDialog(
      title: 'delete_card'.tr,
        content: 'are_you_sure'.tr + " " + 'delete_card_content'.tr + "?",
        cancelButtonText: 'cancel_label'.tr,
        onCancel: () {
          Get.back();
          globals.cardLastFour = 0;
          _addCardController.value = 1;
          globals.selectedPaymentType.value = (1);
          _addCardController.isCardAdded = true;
          _addCardController.setPaymentType(true);
        },
        onConfirm: () {
          _addCardController.checkInternet(removeCard, false);
          Get.back();
          _addCardController.setLoadingControllerPayType(true);
        },
        confirmButtonText: 'delete'.tr);
  }

  updatePaymentMethod(int value) {
    _addCardController.checkInternet(() {
      _addCardController.updatepaymentMethod(value).then((value) {
        if (value.isNotEmpty) {
          _addCardController.showInSnackBar(value);
          _addCardController.setLoadingControllerPayType(false);
        } else {
          _addCardController.setLoadingControllerPayType(false);
          globals.preferredPaymentMethod = _addCardController.value;
        }
      });
    }, true);
  }

  removeCard() {
    _addCardController.removeCardDetails().then((value) {
      _addCardController.setLoadingControllerPayType(false);
      if (value.isNotEmpty) {
        _addCardController.showInSnackBar(value);
      } else {
        _addCardController.cardLastFour = null;
        _addCardController.isCardAdded = false;
        if (_addCardController.value == 3 ||
            _addCardController.value == 1 ||
            _addCardController.value == 4 && _addCardController.value == 5) {
          Updatepayment(_addCardController.value);
        } else if (_addCardController.value == 2) {
          int paymentType;
          if (globals.paymentMethods?[0] != 2)
            paymentType = globals.paymentMethods?[0] ?? 0;
          else if ((globals.paymentMethods?.length ?? 0) > 1)
            paymentType = globals.paymentMethods?[1] ?? 0;
          else
            paymentType = globals.paymentMethods?[0] ?? 0;
          _addCardController.value = paymentType;
          globals.selectedPaymentType.value = (paymentType);
          Updatepayment(_addCardController.value);
        }
      }
    });
  }

  getPaymentMethods() {
    _addCardController.getPaymentMethods().then((value) {
      if (value.isNotEmpty) {
        _addCardController.showInSnackBar(value);
      } else {
        if (!(globals.paymentMethods?.contains(globals.preferredPaymentMethod) ?? false) ||
            (globals.preferredPaymentMethod == 4 && Platform.isIOS)) {
          _addCardController.value = globals.paymentMethods?[0] ?? 0;
          updatePaymentMethod(_addCardController.value);
        }
        globals.selectedPaymentType.value = (globals.preferredPaymentMethod);
      }
      if (globals.paypalCurrencies.isEmpty) _addCardController.getCurrencyListForPaypal();
    });
  }

  Updatepayment(int value) {
    _addCardController.setPaymentType(false);
    _addCardController.isCardAdded = false;
    _addCardController.setLoadingControllerPayType(true);
    globals.cardLastFour = 0;
    updatePaymentMethod(value);
  }

  @override
  void changePayment_and_Backnav() {
    _addCardController.setBackNavigation();
  }
}