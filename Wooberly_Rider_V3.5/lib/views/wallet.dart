import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/add_card_controller.dart';
import 'package:app_name/views/update_wallet_payment_type.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_button.dart';

class Wallet extends StatefulWidget {
  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  AddCardController _addCardController=Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      globals.locController(false);
      _addCardController.getPaymentMethods().then((value){
        _addCardController.update(['loadingController']);
        if(globals.paypalCurrencies.isEmpty)
          _addCardController.getCurrencyListForPaypal();
      });
    });
    _addCardController.currencyController.text = globals.currencySymbol;
    _addCardController.walletAmount.clear();
    if (globals.preferredPaymentMethod == 2) _addCardController.value = 2;

    Future.delayed(
      const Duration(milliseconds: 5),
      () {
        _addCardController.checkInternet(() {}, false).then((value) {
          if (value) {
            _addCardController.setLoadingControllerWallet(false);
          } else {
            _addCardController.setLoadingControllerWallet(true);
          }
        });
      },
    );

  }


  getPaymentMethods() {
    _addCardController.getPaymentMethods().then((value) {
      if (value.isNotEmpty) {
        _addCardController.showInSnackBar( value);
      } else {
        _addCardController.setLoadingControllerWallet(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
          key: _scaffoldKey,
          disableAppbar: false,
          customAppBarFunction: () {
            globals.setButtonIdle();
            _addCardController.setBackNavigation();
            globals.locController(true);
          },
          appBarTitle: 'wallet'.tr,
          body: Stack(
            children: <Widget>[
              Container(
                margin: const EdgeInsetsDirectional.only(top: 36, start: 24, end: 24),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.all(29),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: AppColors.COMMON_BG_COLOR,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            height: 74,
                            width: 88,
                            padding: const EdgeInsetsDirectional.all(15),
                            child: SvgPicture.asset(
                              walletSvg,
                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(
                            width: 24,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'your_wallet_amount'.tr,
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.font),
                                ),
                                Obx(() {
                                    return RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_28,
                                            fontWeight: FontWeight.w600),
                                        children: [
                                          TextSpan(
                                              text: globals.currencySymbol,
                                              style: TextStyle(
                                                  color: AppColors
                                                      .BLACK_TEXT_COLOR,
                                                  fontSize:
                                                      AppDimen.text_size_28,
                                                  fontWeight: FontWeight.w600)),
                                          TextSpan(
                                            text: globals.walletBalance.value.toStringAsFixed(2),
                                            style: TextStyle(
                                                color:
                                                    AppColors.BLACK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_28,
                                                fontFamily: AppFont.font,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    GetBuilder<AddCardController>(
                        id:'loadingController',
                        builder: (_) {
                          return Visibility(
                            visible: ((globals.paymentMethods?.contains(6) ?? false) ||(globals.paymentMethods?.contains(5) ?? false) || (globals.paymentMethods?.contains(2) ?? false)) && (globals.paymentMethods?.contains(3) ?? false),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Divider(
                                 thickness: 0.8,
                                  color: AppColors.DIVIDER_COLOR,
                                ),
                                const SizedBox(height: 29),
                                Text(
                                  'add_money_to_wallet'.tr,
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.font),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(top: 0.0),
                                              child: RichText(
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                    text:
                                                        globals.currencySymbol,
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppDimen.text_size_22,
                                                      color: AppColors
                                                          .BLACK_TEXT_COLOR,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ]),
                                              )),
                                          const SizedBox(
                                            width: 5.0,
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              enableIMEPersonalizedLearning: false,
                                              autofocus: false,
                                              controller:
                                                  _addCardController.walletAmount,
                                              inputFormatters: <
                                                  TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(RegExp("[0-9.]")),
                                                new LengthLimitingTextInputFormatter(
                                                    6)
                                              ],
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true,
                                                      signed: true),
                                              style: TextStyle(
                                                  color: AppColors
                                                      .BLACK_TEXT_COLOR,
                                                  fontSize:
                                                      AppDimen.text_size_24,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: AppFont.font),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: const EdgeInsetsDirectional.only(bottom: 3.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(top: 5),
                                        child: Divider(
                                          thickness: 0.75,
                                          color: AppColors
                                              .DIVIDER_COLOR,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 29),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              ),
             GetBuilder<AddCardController>(
                 id:'loadingController',
                 builder: ( _) {
                    return Visibility(
                      visible: ((globals.paymentMethods?.contains(6) ?? false) ||(globals.paymentMethods?.contains(5) ?? false) || (globals.paymentMethods?.contains(2) ?? false)) && (globals.paymentMethods?.contains(3) ?? false),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 24, end: 24, bottom: 24),
                          child: PrimaryButton(
                            buttonTitle: 'add_amount'.tr,
                            buttonImage: primaryBtnArrow,
                            callback: () {
                              if (checkAddAmount()) {
                                _addCardController.Amount = _addCardController.walletAmount.text;
                                Get.to(UpdateWalletPaymentType(),duration: Duration(milliseconds: 215));

                              } else {
                                _addCardController.toast.show(
                                      context: scoffoldcontext,
                                      message: 'empty_msg'.trParams({'field':
                                          'valid_amount'.tr}),
                                    );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }),
            ],
          ),
          onChanged: (map) {
            scoffoldcontext = map["scaffoldcontext"];
            _addCardController.walletContext = scoffoldcontext;
            _scaffoldKey = map["scaffoldkey"];
          });
    });
  }

  bool checkAddAmount() {
    if (_addCardController.walletAmount.text != null &&
        _addCardController.walletAmount.text.isEmpty) {
      return false;
    } else if (_addCardController.walletAmount.text == "0" ||
        _addCardController.walletAmount.text == "0.0") {
      return false;
    } else if (_addCardController.walletAmount.text == ".") {
      return false;
    } else {
      var amount = double.parse(_addCardController.walletAmount.text);
      try {
        return amount >= 1;
      } catch (e) {
        debugPrint(e.toString());
        return false;
      }
    }
  }

}