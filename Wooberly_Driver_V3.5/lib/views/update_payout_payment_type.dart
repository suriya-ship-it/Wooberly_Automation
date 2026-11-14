import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/app/model_theme.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/app.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';

class UpdatePayOutPaymentType extends StatefulWidget {
  const UpdatePayOutPaymentType({Key? key}) : super(key: key);

  @override
  State<UpdatePayOutPaymentType> createState() =>
      _UpdatePayOutPaymentTypeState();
}

class _UpdatePayOutPaymentTypeState extends State<UpdatePayOutPaymentType> {
  int payOutPaymentType = 0;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  final PayoutController _controller = Get.find();

  @override
  void initState() {
    if (globals.paymentMethods.contains(2) ||
        globals.paymentMethods.contains(5)) {
      payOutPaymentType = globals.paymentMethods.contains(2) ? 1 : 2;
    }
    _controller.rxUpdatePayOutPaymentType.value=1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        key: _scaffoldKey,
        disableAppbar: false,
        appBarTitle: payout_methods.tr,
        customAppBarFunction: () {
          App().setBackNavigation();
        },
        body: GetBuilder(
          init: PayoutController(),
            id: _controller.rxUpdatePayOutPaymentType.id,
            builder: (val) {
              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    decoration: BoxDecoration(
                      color: AppColors.COMMON_BG_COLOR,
                    ),
                    child: ListView(
                      children: <Widget>[
                        if (globals.paymentMethods.contains(2))
                         _getPayoutTypeSelectionWidget(type: _controller.rxUpdatePayOutPaymentType.value, matchingPayoutType: 1, paymentId : 2, paymentIcon: stripeSvg,currency: _controller.paymentMethodCurrency['Credit/Debit'],),
                        if (globals.paymentMethods.contains(5))
                          _getPayoutTypeSelectionWidget(type: _controller.rxUpdatePayOutPaymentType.value, matchingPayoutType: 2, paymentId : 5, paymentIcon: payStackSvg,currency: _controller.paymentMethodCurrency['Paystack'],),
                      if (globals.paymentMethods.contains(6))
                          _getPayoutTypeSelectionWidget(type: _controller.rxUpdatePayOutPaymentType.value, matchingPayoutType: 3, paymentId : 6, paymentIcon: payPalPaymentSVG,currency: _controller.paymentMethodCurrency['PayPal'],),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 24, end: 24, bottom: 24),
                      child: PrimaryButton(
                          buttonTitle: next.tr,
                          buttonImage: primaryBtnArrow,
                          isLoad: false,
                          callback: () {
                            updatePayoutMethod(paymentMethodId: _controller.rxUpdatePayOutPaymentType.value);
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

  void updatePayoutMethod({required int paymentMethodId}) async {
   bool isNetConnected = await _controller.checkConnectivity();
   if(!isNetConnected) {
     _controller.netOffSnackbar(() {}, true);
     return;
   }
    _controller.getPaymentMethods().then((paymentMethodValue) {
      if (paymentMethodValue!.isNotEmpty) {
        _controller.showInSnackBar( paymentMethodValue);
      } else {
        if(paymentMethodId==3){
          App().setNavigation(AppRoutes.APP_PAYPAL_PAYOUT);
        }
        else if (globals.paymentMethods.contains(paymentMethodId == 1 ? 2 : 5)) {
          _controller.accountDetailsArguments = {'paymentMethodId': paymentMethodId == 1 ? 2 : 5};
         App().setNavigation(AppRoutes.APP_PAYOUT_ACCOUNT);
        } else {
          _controller.showInSnackBar(disable_add_payout.tr);
        }
      }
    });
  }

 Widget _getPayoutTypeSelectionWidget({required int type, required int matchingPayoutType, required int paymentId, required paymentIcon,required String currency }) {
    return  Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 18.0),
      margin: const  EdgeInsetsDirectional.only(top: 20),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_COLOR_WHITE,
        borderRadius:
        BorderRadius.all(Radius.circular(3),),),
      child: InkWell(
        onTap: () {
          payOutPaymentType = matchingPayoutType;
          _controller.change(rxVariable: _controller.rxUpdatePayOutPaymentType, value: matchingPayoutType);
        },
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 7,
              child: SizedBox(
                height: 20,
                width: 20,
                child: SvgPicture.asset(
                  paymentIcon,
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 80,
              child: Text(
                '${App().getPaymentName(paymentId)} (${currency})',
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Align(
              alignment: FractionalOffset.centerRight,
              child: Center(
                  child: InkWell(
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          border: Border.all(
                            color: type == matchingPayoutType
                                ? AppColors
                                .PRIMARY_COLOR_DARK
                                : AppColors
                                .BORDERCOLOR,
                          )),
                      child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: type == matchingPayoutType
                              ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors
                                    .PRIMARY_COLOR_DARK,
                                shape: BoxShape.circle,
                              ))
                              : const SizedBox.shrink()),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}