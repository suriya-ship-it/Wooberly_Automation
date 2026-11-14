import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import 'package:wooberly_driver/widgets/show_done_view.dart';

import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';

class PayoutAddress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PayoutAddressView();
  }
}

class PayoutAddressView extends StatefulWidget {
  PayoutAddressView({Key? key}) : super(key: key);

  @override
  _PayoutAddressState createState() => new _PayoutAddressState();
}

class _PayoutAddressState extends State<PayoutAddressView> {
  final PayoutController controller = Get.find();
  final FocusNode fnaddress2 = FocusNode();
  final FocusNode fncity = FocusNode();
  final FocusNode fnstate = FocusNode();
  final FocusNode fnzipcode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    controller.setLoadingController(false);
    fncity.addListener(() {
      _scrollToBottom();
    });
    fnstate.addListener(() {
      _scrollToBottom();
    });
    fnzipcode.addListener(() {
      _scrollToBottom();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
        customAppBarFunction: () {
          _goBack();
        },
        backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          color: AppColors.COMMON_BG_COLOR,
          padding: const EdgeInsetsDirectional.only(bottom: 10, start: 25, end: 25),
          child: PrimaryButton(
            buttonTitle: next.tr,
            isLoad: false,
            buttonImage: primaryBtnArrow,
            callback: () {
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              _validateInputs();
            },
          ),
        ),

        body: Stack(
          children: [
             SingleChildScrollView(
                controller: _scrollController,
                child:  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 20, right: 24),
                    child: new Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Align(
                            alignment: globals.isRtlLang
                                ? Alignment.topRight
                                : Alignment.topLeft,
                            child: new Text(
                              what_address_payout.tr,
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontWeight: FontWeight.w600,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                          ),
                          new Column(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    App().setBackNavigation();
                                  },
                                  child: new Container(
                                    margin: const EdgeInsets.only(top: 23.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(3),
                                        ),
                                    ),
                                    child: new TextFormField(
                                      readOnly: true,
                                      enabled: false,
                                      enableIMEPersonalizedLearning: false,
                                      keyboardType: TextInputType.text,
                                      controller: controller.countryController,
                                      decoration: new InputDecoration(
                                          border: InputBorder.none,
                                          hintText: country.tr,
                                          hintStyle: TextStyle(
                                            color: AppColors
                                                .HIND_TEXT_COLOR,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                          )),
                                      style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: new Container(
                                        margin: const EdgeInsets.only(top: 23.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        decoration: BoxDecoration(
                                            color: AppColors.PRIMARY_COLOR_WHITE,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(3),
                                            ),
                                        ),
                                        child: new TextFormField(
                                          keyboardType: TextInputType.text,
                                          enableIMEPersonalizedLearning: false,
                                          textInputAction: TextInputAction.next,
                                          controller:
                                          controller.address1Controller,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaddress2);
                                          },
                                          decoration: new InputDecoration(
                                              border: InputBorder.none,
                                              hintText: address_line_1.tr,
                                              hintStyle: TextStyle(
                                                color: AppColors
                                                    .HIND_TEXT_COLOR,
                                                fontWeight: FontWeight.w400,
                                                fontSize: AppDimen.text_size_16,
                                              )),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: AppDimen.text_size_16,
                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                      margin: const EdgeInsets.only(top: 23.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_COLOR_WHITE,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(3),
                                          ),
                                      ),
                                      child: new TextFormField(
                                        keyboardType: TextInputType.text,
                                        enableIMEPersonalizedLearning: false,
                                        textInputAction: TextInputAction.next,
                                        controller:
                                        controller.address2Controller,
                                        focusNode: fnaddress2,
                                        onFieldSubmitted: (term) {
                                          FocusManager.instance.primaryFocus?.unfocus();
                                          FocusScope.of(context).requestFocus(fncity);
                                        },
                                        decoration: new InputDecoration(
                                          border: InputBorder.none,
                                          hintText: address_line_2.tr,
                                          hintStyle: TextStyle(
                                            color: AppColors
                                                .HIND_TEXT_COLOR,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                          ),
                                        ),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                            color:
                                            AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                      ),
                                    ),
                               Container(
                                    margin:
                                    const EdgeInsets.only(top: 23.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(3))),
                                    child: new TextFormField(
                                      keyboardType: TextInputType.text,
                                      enableIMEPersonalizedLearning: false,
                                      textInputAction: TextInputAction.next,
                                      controller: controller.cityController,
                                      focusNode: fncity,
                                      onFieldSubmitted: (term) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        FocusScope.of(context).requestFocus(fnstate);
                                      },
                                      decoration: new InputDecoration(
                                          border: InputBorder.none,
                                          hintText: city.tr,
                                          hintStyle: TextStyle(
                                            color: AppColors
                                                .HIND_TEXT_COLOR,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                          )),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                          color:
                                          AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                    ),
                                  ),
                                Container(
                                    margin:
                                    const EdgeInsets.only(top: 23.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(3))),
                                    child: new TextFormField(
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      enableIMEPersonalizedLearning: false,
                                      controller:
                                      controller.stateController,
                                      focusNode: fnstate,
                                      onFieldSubmitted: (term) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        FocusScope.of(context).requestFocus(fnzipcode);
                                      },
                                      decoration: new InputDecoration(
                                          border: InputBorder.none,
                                          hintText: state.tr,
                                          hintStyle: TextStyle(
                                            color: AppColors
                                                .HIND_TEXT_COLOR,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                          )),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                          color:
                                          AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                    ),
                                  ),
                                Container(
                                    margin: const EdgeInsets.only(top: 23.0, bottom: 20),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_WHITE,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                    ),
                                    child: new TextFormField(
                                      keyboardType: TextInputType.text,
                                      enableIMEPersonalizedLearning: false,
                                      textInputAction: TextInputAction.done,
                                      controller: controller.zipcodeController,
                                      focusNode: fnzipcode,
                                      onFieldSubmitted: (term) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                      },
                                      decoration: new InputDecoration(
                                        border: InputBorder.none,
                                        hintText: zipcode.tr,
                                        hintStyle: TextStyle(
                                          color: AppColors
                                              .HIND_TEXT_COLOR,
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                        ),),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                          color:
                                          AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                    ),
                                  ),
                                SizedBox(
                                  height: MediaQuery.of(context).viewInsets.bottom + 50,
                                )
                              ],
                          ),
                        ],
                    ),
                ),
            ),
            Positioned(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 0.0,
                left: 0.0,
                child: MediaQuery.of(context).viewInsets.bottom > 50.0
                    ? InputDoneView()
                    : const SizedBox.shrink(),
            ),
          ],
        ));
  }

  void _scrollToBottom() {
    if (fncity.hasFocus || fnstate.hasFocus || fnzipcode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 650), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent +(Platform.isIOS ? 0.0 :(MediaQuery.of(context).viewInsets.bottom +200)),
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 100),
        );
      });
    }else{
      _scrollController.animateTo(
        0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  _goBack() {
    if (!globals.isPayout && globals.payout == 0) {
      Get.close(2);
    }
    else
      App().setBackNavigation();
  }

  void _validateInputs() {

    final fields = [
      (ctrl: controller.address1Controller, msg: address_is_required.tr),
      (ctrl: controller.countryController, msg: empty_selection.trParams({"field": country_is_required.tr.toLowerCase()})),
      (ctrl: controller.cityController, msg: empty_selection.trParams({"field": city_is_required.tr.toLowerCase()})),
      (ctrl: controller.stateController, msg: empty_selection.trParams({"field": state_is_required.tr.toLowerCase()})),
      (ctrl: controller.zipcodeController, msg: empty_selection.trParams({"field": zipcode_is_required.tr.toLowerCase()})),
    ];

    for (var field in fields) {
      if (field.ctrl.text.trim().isEmpty) {
        controller.showInSnackBar(field.msg);
        return;
      }
    }

    SystemChannels.textInput.invokeMethod('TextInput.hide');
    App().setNavigation(AppRoutes.APP_PAYOUT_UPDATE);
  }
}