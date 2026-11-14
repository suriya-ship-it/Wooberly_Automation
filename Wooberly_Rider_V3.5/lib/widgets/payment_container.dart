import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/paypal_currency_box.dart';

class PaymentContainer extends StatelessWidget {
  String? paymentTitle;
  String? paymentSvg;
  int? paymentValue;
  Function? callback;
  int? paymentId;
  double? svgHeight;
  double svgWidth;
  Color? bgColor;
  ColorFilter? svgColorFilter;
  bool? isVisible;

  PaymentContainer(
      {Key? key,
      this.paymentTitle,
      this.paymentSvg,
      this.paymentValue,
      this.callback,
      this.paymentId,
      this.svgHeight = 13.0,
      this.svgWidth = 20.0,
        this.svgColorFilter,
      this.bgColor,
      this.isVisible})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("paymentId: ${paymentId} --- ${paymentValue}");
    return paymentContainer(
      paymentTitle: paymentTitle,
      paymentSvg: paymentSvg,
      paymentValue: paymentValue,
      paymentId: paymentId,
      callback: callback,
      svgHeight: svgHeight,
      svgWidth: svgWidth,
      bgColor: bgColor ?? AppColors.PRIMARY_LIGHT_COLOR,
      isVisible: isVisible,
      svgColorFilter: svgColorFilter,
    );
  }

  Widget paymentContainer(
      {String? paymentTitle,
      String? paymentSvg,
      int? paymentValue,
      Function? callback,
      int? paymentId,
      svgHeight = 13.0,
      svgWidth = 20.0,
      Color? bgColor,
      bool? isVisible,
      ColorFilter? svgColorFilter}) {
    return Visibility(
      visible:  isVisible == null ? paymentId == 4 ? ((globals.paymentMethods?.contains(paymentId) ?? false) && Platform.isAndroid): globals.paymentMethods?.contains(paymentId) ?? false : isVisible,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18.0,),
            margin: const EdgeInsetsDirectional.only(top: 16),
            height: 50,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: const BorderRadius.all(Radius.circular(3))),
            child: InkWell(
              onTap: () {
                callback!();
              },
              child: Row(
                children: <Widget>[
                  Container(
                    height: paymentId == 4 ? 24 : svgHeight,
                    width:paymentId == 4 ? 24 : svgWidth,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SvgPicture.asset(
                        paymentSvg ?? "",
                        colorFilter:svgColorFilter,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  paymentId == 3
                      ? Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  "${'wallet'.tr}",
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontFamily: AppFont.font,
                                      fontSize: AppDimen.text_size_14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                             Text("-",
                                 style: TextStyle(
                                     color: AppColors.BLACK_TEXT_COLOR,
                                     fontFamily: AppFont.font,
                                     fontSize: AppDimen.text_size_14,
                                     fontWeight: FontWeight.w500)),
                              const  SizedBox(
                                width: 5,
                              ),
                              Flexible(
                                  child: Obx((){
                                        return RichText(
                                          text: TextSpan(children: [
                                            TextSpan(
                                                text: globals.currencySymbol,
                                                style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontSize: AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                            TextSpan(
                                                text: globals.walletBalance.value
                                                    .toStringAsFixed(2),
                                                style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontSize: AppDimen.text_size_14,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: AppFont.font,
                                                ))
                                          ]),
                                        );
                                      })),
                            ],
                          ),
                        )
                      : Expanded(
                          child: Text(
                            paymentTitle ?? "",
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        border: Border.all(
                          color: paymentValue == paymentId
                              ? AppColors.PRIMARY_DARK_COLOR
                              : AppColors.RADIO_BUTTON_COLOR,
                        )),
                    child: Padding(
                        padding: const EdgeInsetsDirectional.all(4.0),
                        child: paymentValue == paymentId
                            ? Container(
                                decoration: BoxDecoration(
                                color: AppColors.PRIMARY_DARK_COLOR,
                                shape: BoxShape.circle,
                              ))
                            : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          ),
          if ((paymentValue == 6 && paymentId == paymentValue) ||
              (globals.bookingPaymentType && paymentValue == 6))
            PayPalCurrencyBox(isFrom: "paymentMethods"),
        ],
      ),
    );
  }
}