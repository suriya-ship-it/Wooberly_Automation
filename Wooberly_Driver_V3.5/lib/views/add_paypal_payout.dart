import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_button.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import 'package:wooberly_driver/widgets/show_done_view.dart';

import '../app/app.dart';
import '../app/app_routes.dart';
import '../controller/trip_controllers/payout_controller.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_lang.dart';
import '../widgets/paypal_currency_box.dart';

class PayPalPayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PayPalPayoutView();
  }
}

class PayPalPayoutView extends StatefulWidget {
  @override
  State<PayPalPayoutView> createState() => _PayPalPayoutViewState();
}

class _PayPalPayoutViewState extends State<PayPalPayoutView> {
  late PayoutController _controller;

  @override
  void initState() {
    _controller = Get.find();
    _controller.payPalController.text = globals.paypalCurrencyController.text;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        App().setBackNavigation(true);
        _controller.removeAccountDetails();
      },
      disableAppbar: false,
      appBarTitle: 'PayPal',
      body: _showBodyContent(context),
      extendBodyBehindAppBar: false,
    );
  }

  _showBodyContent(BuildContext context) {
    return ColoredBox(
      color: AppColors.COMMON_BG_COLOR,
      child: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                paypal_content.trParams({
                  'field1': "PayPal",
                  'field2': globals.PLATFORM_NAME,
                  'field3': "PayPal",
                  'field4': globals.PLATFORM_NAME,
                  'field5': "PayPal"
                }),
                style: TextStyle(
                  fontSize: AppDimen.text_size_14,
                  fontFamily: AppFont.font,
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: 24.0,
              ),
              _customTextField(
                  hintText: "${email_label.tr} ${address.tr.toLowerCase()}",
                  controller: _controller.emailController),
              const SizedBox(
                height: 24.0,
              ),
              PayPalCurrencyBox(payPalController: _controller.payPalController),
            ],
          ),
        ),
        (MediaQuery.of(context).viewInsets.bottom == 0.0) ? _finishButton() : InputDoneView()
      ]),
    );
  }

  Widget _customTextField({required String hintText, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_COLOR_WHITE,
        borderRadius: BorderRadius.all(new Radius.circular(4.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.SHADOW_COLOR,
            spreadRadius: 1,
            blurRadius: 25,
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0, vertical: 2.0),
      child: new TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        decoration: new InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: AppColors.HIND_TEXT_COLOR,
            fontWeight: FontWeight.w400,
            fontFamily: AppFont.font,
            fontSize: AppDimen.text_size_16,
          ),
        ),
        style: TextStyle(
          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
          fontWeight: FontWeight.w400,
          fontFamily: AppFont.font,
          fontSize: AppDimen.text_size_16,
        ),
        cursorColor: AppColors.HIND_TEXT_COLOR,
      ),
    );
  }

  String _validateEmail() {
    String value = _controller.emailController.text.toString();
    String errorMsg = "";
    Pattern pattern = r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z]{2,6}){1,3}$';
    RegExp regex = new RegExp(pattern.toString());
    if (value.trim().length == 0) {
      errorMsg = empty_msg.trParams({'field': "${email_label.tr} ${address.tr.toLowerCase()}"});
    } else if (!regex.hasMatch(value)) {
      errorMsg = valid_msg.trParams({'field': "${email_label.tr} ${address.tr.toLowerCase()}"});
    } else {
      errorMsg = "";
    }
    if (errorMsg.isNotEmpty) _controller.showInSnackBar(errorMsg);
    return errorMsg;
  }

  Widget _finishButton() {
    return GetBuilder<PayoutController>(
        id: _controller.rxLoadingController.id,
        builder: (btnLoader) {
          return Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
              child: PrimaryButton(
                buttonTitle: finish.tr,
                buttonImage: primaryBtnArrow,
                callback: () {
                  if (btnLoader.rxLoadingController.value == false) {
                    if (_validateEmail().isEmpty) {
                      _controller.setLoadingController(true);
                      _controller.addPayout( 6).then((value) {
                        if (value.isNotEmpty) {
                          _controller.setLoadingController(false);
                          _controller.showInSnackBar(value);
                        } else {
                          Get.until((route) => route.settings.name == AppRoutes.APP_PAYOUT_DISPLAY);
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            _controller.rxPayoutStatusChangedController(true);
                          });
                        }
                      });
                    }
                  }
                },
              ),
            ),
          );
        });
  }
}