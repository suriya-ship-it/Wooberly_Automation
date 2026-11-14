import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';

import '../resources/values/app_images.dart';


class PayPalCurrencyBox extends StatelessWidget {
  TextEditingController payPalController = TextEditingController();
  BaseController controller=Get.find();
    PayPalCurrencyBox({required this.payPalController});

  @override
  Widget build(BuildContext context) {
    if(payPalController.text.isEmpty)
    payPalController.text=globals.payPalCurrency;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_COLOR_WHITE,
        borderRadius: BorderRadius.all(Radius.circular(3.0))
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('currency'.tr,style: TextStyle(
                  fontFamily: AppFont.font,
                  fontSize: AppDimen.text_size_14,
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontWeight: FontWeight.w500
              ),)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: () {
                Get.closeCurrentSnackbar();
                if(globals.paypalCurrencies.isNotEmpty) {
                  _paypalCurrencylistBottomSheet(context);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 1,
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR
                  ),
                  borderRadius: BorderRadius.all(
                      const Radius.circular(25.0)
                  ),
                ),
                padding: const  EdgeInsetsDirectional.symmetric(horizontal: 12.0),
                margin: const  EdgeInsetsDirectional.only(top: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GetBuilder<BaseController>(
                      id: 'currency',
                      builder: (context) {
                        return Container(
                          width: 70,
                          child: Text(
                            "${payPalController.text} (${controller.getCurrencySybmol(payPalController.text,'')})",
                            style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontWeight: FontWeight.w400,
                              fontSize: AppDimen.text_size_14,
                            ),
                          ),
                        );
                      }
                    ),
                    SvgPicture.asset(
                      primaryDownArrow,
                      width: 10,
                      height: 7,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _paypalCurrencylistBottomSheet(BuildContext context) {
    Get.bottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
             return ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                child: Container(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  child: SafeArea(
                    bottom: Platform.isAndroid,
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: globals.paypalCurrencies.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            return Container(
                                child: new Wrap(children: <Widget>[
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      InkWell(
                                        onTap: () {
                                          Get.back();
                                          payPalController.text =  globals.paypalCurrencies[index];
                                          controller.update(['currency']);
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              alignment: AlignmentDirectional.centerStart,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10.0,
                                                    bottom: 10.0,
                                                    right: 20.0,
                                                    left: 20.0),
                                                child: Text(
                                                    "${globals.paypalCurrencies[index]} (${controller.getCurrencySybmol(globals.paypalCurrencies[index],'')})",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color:AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR ,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: AppDimen.text_size_17,
                                                    )),
                                              ),
                                            ),
                                            if(payPalController.text == globals.paypalCurrencies[index])
                                              Padding(
                                                padding: const EdgeInsetsDirectional.only(end: 20),
                                                child: SvgPicture.asset(
                                                  updatedVerified,
                                                  height: 23.0,
                                                  width: 23.0,
                                                  colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if(index != globals.paypalCurrencies.length - 1)
                                        Divider( thickness: 1,
                                        color: AppColors.DIVIDER_COLOR,

                                ),
                            ],
                          )
                        ]));
                      },
                    ),
                  ),
                ),
              )));
           }
         )
    );
  }
}