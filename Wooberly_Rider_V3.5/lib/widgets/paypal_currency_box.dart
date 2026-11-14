import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/controllers/add_card_controller.dart';
import '../app/app.dart';
import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../controllers/base_controller.dart';

class PayPalCurrencyBox extends StatefulWidget {
  final String isFrom ;

  PayPalCurrencyBox({Key? key, required this.isFrom}) : super(key: key);

  @override
  State<PayPalCurrencyBox> createState() => _PayPalCurrencyBoxState();
}

class _PayPalCurrencyBoxState extends State<PayPalCurrencyBox> {
  final AddCardController _viewModel = Get.find();
  BaseController controller=Get.find();



  @override
  Widget build(BuildContext context) {
    debugPrint("globals.paypalCurrencyController.text: ${globals.paypalCurrencyController.text}");
    return Container(
      padding:  EdgeInsetsDirectional.all( widget.isFrom == "Tips" ? 0.0 : 18.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.0),
        color: AppColors.PRIMARY_LIGHT_COLOR,
      ),
      child: Column(
        children: [
          Align(
              alignment: widget.isFrom == "Tips"
                  ? AlignmentDirectional.center
                  : AlignmentDirectional.centerStart,
              child: Text(
                'currency_hint'.tr,
                style: TextStyle(
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_14,
                    fontWeight: FontWeight.w500,
                    color: widget.isFrom == "Tips"
                        ? AppColors.WHITE_TEXT_COLOR
                        : AppColors.BLACK_TEXT_COLOR),
              ),
          ),
          Align(
            alignment: widget.isFrom == "Tips"
                ? AlignmentDirectional.center
                : AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (globals.paypalCurrencies.isNotEmpty) {
                  _paypalCurrencylistBottomSheet(context);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: AppColors.PRIMARY_DARK_COLOR),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0,),
                margin: const EdgeInsetsDirectional.only(top: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GetBuilder<BaseController>(
                        id: 'currency',
                        builder: (context) {
                          return Container(
                            child: Text(
                              "${globals.paypalCurrencyController.text} (${controller.getCurrencySybmol(globals.paypalCurrencyController.text,'')})",
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontWeight: FontWeight.w400,
                                fontSize: AppDimen.text_size_14,
                              ),
                            ),
                          );
                        }
                    ),
                    const SizedBox(width: 5,),
                    SvgPicture.asset(
                      primaryDownArrow,
                      width: 10,
                      height: 6,
                      colorFilter: ColorFilter.mode(
                          AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
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
    App().showBottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: const Radius.circular(15), topRight: const Radius.circular(15)),
            child: ColoredBox(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 10.0),
                child: (() {
                  List<String> sortedCurrencies = List.from(globals.paypalCurrencies);
                  String selectedCurrency = globals.paypalCurrencyController.text;
                  if (sortedCurrencies.contains(selectedCurrency)) {
                    sortedCurrencies.remove(selectedCurrency);
                    sortedCurrencies.insert(0, selectedCurrency);
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedCurrencies.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Container(
                          child: new Wrap(children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                Get.back();
                                globals.paypalCurrencyController.text = sortedCurrencies[index];
                                _viewModel.checkInternet(
                                    _viewModel.updatePaypalCurrency, false);
                                controller.update(['currency']);
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    alignment:
                                    AlignmentDirectional.centerStart,
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      vertical: 10.0,
                                      horizontal: 20.0,
                                    ),
                                    child: Text(
                                        "${sortedCurrencies[index]} (${controller.getCurrencySybmol(sortedCurrencies[index],'')})",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppFont.font,
                                          color:  AppColors.BLACK_TEXT_COLOR,
                                          fontWeight: FontWeight.w500,
                                          fontSize: AppDimen.text_size_16,
                                        )
                                    ),
                                  ),
                                  if (globals.paypalCurrencyController.text == sortedCurrencies[index])
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.only(
                                              end: 20),
                                      child: SvgPicture.asset(
                                        updatedVerified,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_DARK_COLOR,
                                            BlendMode.srcIn),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (index != sortedCurrencies.length - 1)
                               Divider(thickness: 1, color: AppColors.DIVIDER_COLOR,),
                          ],
                        )
                      ]));
                    },
                  );
                }()),
                ),
              ),
            ),
          );
        }
      ),Colors.transparent
    );
  }
}