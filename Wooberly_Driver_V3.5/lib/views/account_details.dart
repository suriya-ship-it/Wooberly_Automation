import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/payout_country_list.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';
import '../widgets/show_done_view.dart';

class PayoutAccount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PayoutAccountView();
  }
}

class PayoutAccountView extends StatefulWidget {
  PayoutAccountView({Key? key}) : super(key: key);

  @override
  _PayoutAccountState createState() => new _PayoutAccountState();
}

class _PayoutAccountState extends State<PayoutAccountView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  final PayoutController controller = Get.find();
  var bankTypeArray = [
    company.tr,
    individual.tr
  ];
  final FocusNode fnfirstname = FocusNode();
  final FocusNode fnlastname = FocusNode();
  final FocusNode fnroutingNo = FocusNode();
  final FocusNode fnaccountNo = FocusNode();
  final FocusNode fnconfirmAccNo = FocusNode();
  final FocusNode fnCompanyName = FocusNode();
  final FocusNode fnAccountOwnerName = FocusNode();
  final FocusNode fnBankName = FocusNode();
  final FocusNode fnBranchName = FocusNode();
  final FocusNode fnBankCode = FocusNode();
  final _scrollController = ScrollController();
  Map<String, dynamic> arguments = {};

  var rxBankTypeSelected = ReactiveVariable("rxBankTypeSelected", false);

  @override
  void initState() {
    arguments =  controller.accountDetailsArguments ?? {};
    controller.accountTypeController.text = "";
    controller.removeAccountDetails();
    fnconfirmAccNo.addListener(() {
      _scrollToBottom();
    });
    fnaccountNo.addListener(() {
      _scrollToBottom();
    });
    fnroutingNo.addListener(() {
      _scrollToBottom();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        Get.back();
      },
      backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
      floatingActionButton: GetBuilder(
          init: PayoutController(),
          id: controller.rxLoadingController.id,
          builder: (val) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 10, start: 40, end: 10),
              child: PrimaryButton(
                buttonTitle: next.tr,
                buttonImage: primaryBtnArrow,
                isLoad: controller.rxLoadingController.value,
                callback: () {
                  if (controller.rxLoadingController.value == false) {
                    _validateInputs();
                  }
                },
              ),
            );
          }),
      body: Stack(
        children: [
          SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              controller: _scrollController,
              child: new Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate,
                  child: new Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, right: 24, top: 10, bottom: 24),
                    child: new Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 10.0,
                              ),
                              child: new Text(
                                what_account_payout.tr,
                                style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                          ),
                          new Column(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                if (arguments["paymentMethodId"] != 5)
                                  InkWell(
                                    onTap: () {
                                      Get.bottomSheet(
                                          backgroundColor:
                                          AppColors.PRIMARY_COLOR_WHITE,
                                          SafeArea(
                                            bottom: Platform.isAndroid,
                                            child: Consumer<ModelTheme>(
                                                builder: (context, ModelTheme themeNotifier, child) {
                                                  return Container(
                                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                                    child: Padding(
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 24),
                                                        child: Wrap(
                                                          children: <Widget>[
                                                            new InkWell(
                                                                child:
                                                                Container(
                                                                  height:
                                                                  60,
                                                                  alignment:
                                                                  AlignmentDirectional
                                                                      .centerStart,
                                                                  child:
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                    MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      new Text(
                                                                        bankTypeArray[0],
                                                                        style: TextStyle(
                                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                            fontSize: AppDimen.text_size_16,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                      controller.accountTypeController.text == bankTypeArray[0]
                                                                          ? Container(
                                                                        height: 24,
                                                                        width: 24,
                                                                        margin: const EdgeInsetsDirectional.only(start: 24),
                                                                        padding: const EdgeInsets.all(5),
                                                                        decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.all(Radius.circular(50),),
                                                                          border: Border.all(color: AppColors.PRIMARY_COLOR_DARK, width: 1.5),
                                                                        ),
                                                                        child: SvgPicture.asset(
                                                                          checkSvg,
                                                                          colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                                                                        ),
                                                                      )
                                                                          : const SizedBox.shrink(),
                                                                    ],
                                                                  ),
                                                                ),
                                                                onTap:
                                                                    () => {
                                                                  controller.showError = false,
                                                                  controller.accountTypeController.text = bankTypeArray[0],
                                                                  controller.isCompanyEnabled = true,
                                                                  controller.change(rxVariable: rxBankTypeSelected, value: false),
                                                                  controller.removeAccountDetails(),
                                                                  Get.back()
                                                                }),
                                                            Divider(
                                                              height: 2.0,
                                                              color: AppColors
                                                                  .DIVIDER_COLOR,
                                                            ),
                                                            new InkWell(
                                                                child: Container(
                                                                  height: 60,
                                                                  alignment: AlignmentDirectional.centerStart,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                    MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      new Text(
                                                                        bankTypeArray[1],
                                                                        textAlign: TextAlign.center,
                                                                        style: TextStyle(
                                                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                            fontSize: AppDimen.text_size_16,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                      controller.accountTypeController.text == bankTypeArray[1]
                                                                          ? Container(
                                                                        height: 24,
                                                                        width: 24,
                                                                        margin: const EdgeInsetsDirectional.only(start: 24),
                                                                        decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(50)), border: Border.all(color: AppColors.PRIMARY_COLOR_DARK, width: 1.5)),
                                                                        padding: const EdgeInsets.all(5),
                                                                        child: SvgPicture.asset(
                                                                          checkSvg,
                                                                          colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                                                                        ),
                                                                      )
                                                                          : const SizedBox.shrink(),
                                                                    ],
                                                                  ),
                                                                ),
                                                                onTap:
                                                                    () => {
                                                                  controller.showError = false,
                                                                  controller.accountTypeController.text = bankTypeArray[1],
                                                                  controller.isCompanyEnabled = false,
                                                                  controller.removeAccountDetails(),
                                                                  controller.change(rxVariable: rxBankTypeSelected, value: true),
                                                                  Get.back(),
                                                                }),
                                                          ],
                                                        )),
                                                  );
                                                }
                                            ),
                                          )
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 23.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(3),
                                        ),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: new TextFormField(
                                              controller: controller
                                                  .accountTypeController,
                                              readOnly: true,
                                              enabled: false,
                                              decoration: new InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: account_type.tr,
                                                  hintStyle: TextStyle(
                                                    color: AppColors
                                                        .HIND_TEXT_COLOR,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize:
                                                        AppDimen.text_size_16,
                                                  )),
                                              style: TextStyle(
                                                color:
                                                    AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontWeight: FontWeight.w500,
                                                fontSize: AppDimen.text_size_16,
                                              ),
                                            ),
                                          ),
                                          SvgPicture.asset(
                                            primaryDownArrow,
                                            width: 15,
                                            height: 9,
                                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                GetBuilder<PayoutController>(
                                    init: PayoutController(),
                                    id: rxBankTypeSelected.id,
                                    builder: (val) {
                                      return Column(children: <Widget>[
                                        _customTextField(
                                          isVisible: rxBankTypeSelected.value == true ||
                                              arguments["paymentMethodId"] ==
                                                  5,
                                          hintText: firstname_label.tr,
                                          controller:
                                              controller.firstNameController,
                                          focusNode: fnfirstname,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnlastname);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: rxBankTypeSelected.value == true ||
                                              arguments["paymentMethodId"] ==
                                                  5,
                                          hintText: lastname_label.tr,
                                          controller:
                                              controller.lastNameController,
                                          focusNode: fnlastname,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaccountNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: rxBankTypeSelected.value == false ||
                                              arguments["paymentMethodId"] ==
                                                  5,
                                          hintText:
                                              arguments["paymentMethodId"] ==
                                                      5
                                                  ? account_type.tr
                                                  : company_name.tr,
                                          controller: controller
                                              .companyNameController,
                                          focusNode: fnCompanyName,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaccountNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: bankNameEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) &&
                                              arguments["paymentMethodId"] !=
                                                  5,
                                          hintText: account_owner_name.tr,
                                          controller: controller
                                              .accountOwnerNameController,
                                          focusNode: fnAccountOwnerName,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnBankName);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: bankNameEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) &&
                                              arguments["paymentMethodId"] !=
                                                  5,
                                          hintText: bank_name.tr,
                                          controller:
                                              controller.bankNameController,
                                          focusNode: fnBankName,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnBranchName);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: bankNameEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) &&
                                              arguments["paymentMethodId"] !=
                                                  5,
                                          hintText: branch_name.tr,
                                          controller:
                                              controller.branchNameController,
                                          focusNode: fnBranchName,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaccountNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: transitNumberEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) ||
                                              bankNameEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) ||
                                              bankCodeEnableCountries
                                                  .contains(controller
                                                      .selectedCountry) ||
                                              arguments["paymentMethodId"] ==
                                                  5,
                                          hintText: arguments[
                                                      "paymentMethodId"] ==
                                                  5
                                              ? bank_code.tr
                                              : transitNumberEnableCountries
                                                      .contains(controller
                                                          .selectedCountry)
                                                  ? transit_number.tr
                                                  : bank_code.tr,
                                          controller:
                                              controller.bankCodeController,
                                          focusNode: fnBankCode,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaccountNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: !(europeCountries
                                                      .contains(controller
                                                          .selectedCountry) ||
                                                  clabeEnableCountries
                                                      .contains(controller
                                                          .selectedCountry)) &&
                                              arguments["paymentMethodId"] !=
                                                  5,
                                          hintText: sortCodeEnableCountries
                                                  .contains(
                                                      controller
                                                          .selectedCountry)
                                              ? sort_code.tr
                                              : bankCodeEnableCountries
                                                          .contains(controller
                                                              .selectedCountry) ||
                                                      bankNameEnableCountries
                                                          .contains(controller
                                                              .selectedCountry)
                                                  ? branch_code.tr
                                                  : transitNumberEnableCountries
                                                          .contains(
                                                              controller
                                                                  .selectedCountry)
                                                      ? Institution_number.tr
                                                      : routing_number.tr,
                                          controller:
                                              controller.routingController,
                                          focusNode: fnroutingNo,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnaccountNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: true,
                                          hintText: arguments[
                                                      "paymentMethodId"] ==
                                                  5
                                              ? account_number.tr
                                              : europeCountries.contains(
                                                      controller
                                                          .selectedCountry)
                                                  ? iban_number.tr
                                                  : clabeEnableCountries
                                                          .contains(controller
                                                              .selectedCountry)
                                                      ? clabe_number.tr
                                                      : account_number.tr,
                                          controller:
                                              controller.accountNoController,
                                          focusNode: fnaccountNo,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            FocusScope.of(context).requestFocus(fnconfirmAccNo);
                                          },
                                        ),
                                        _customTextField(
                                          isVisible: true,
                                          hintText: arguments[
                                                      "paymentMethodId"] ==
                                                  5
                                              ? conf_acc_num.tr
                                              : europeCountries.contains(
                                                      controller
                                                          .selectedCountry)
                                                  ? confirm_iban_number.tr
                                                  : clabeEnableCountries
                                                          .contains(controller
                                                              .selectedCountry)
                                                      ? confirm_clabe_number.tr
                                                      : conf_acc_num.tr,
                                          controller: controller
                                              .confirmAccNoController,
                                          focusNode: fnconfirmAccNo,
                                          onFieldSubmitted: (term) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                          },
                                        ),
                                      ],
                                      );
                                    }),
                              ],
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom +
                                  50),
                        ],
                    ),
                  ),
              ),
          ),
          Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              right: 0.0,
              left: 0.0,
              child: MediaQuery.of(context).viewInsets.bottom > 0.0
                  ? InputDoneView()
                  : const SizedBox.shrink()),
        ],
      ),

    );
  }

  _customTextField(
      {TextEditingController? controller,
      FocusNode? focusNode,
      ValueChanged<String>? onFieldSubmitted,
      String? hintText,
      bool? isVisible}) {
    return Visibility(
      visible: isVisible == true,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 23.0),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(
                    Radius.circular(3),
                  ),
              ),
              child: new TextFormField(
                enableIMEPersonalizedLearning: false,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                controller: controller,
                focusNode: focusNode,
                decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppColors.HIND_TEXT_COLOR,
                      fontWeight: FontWeight.w400,
                      fontSize: AppDimen.text_size_16,
                    )),
                style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontWeight: FontWeight.w400,
                  fontSize: AppDimen.text_size_16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addPayout() {
    controller
        .addPayout( arguments["paymentMethodId"])
        .then((value) {
      controller.setLoadingController(false);
      if (value == "null") {
        addPayout();
      } else if (value.isNotEmpty) {
        controller.showInSnackBar( value);
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        controller.Reset();
        controller.formateddate = null;
        if (arguments["paymentMethodId"] == 5) {
          try {
            Get.until((route) => route.settings.name == "/AccountDisplay");
          } on Exception catch (exception) {
            Get.until((route) => route.settings.name == "/AccountDisplay");
          } catch (error) {
            Get.until((route) => route.settings.name == "/AccountDisplay");
          }
          Future.delayed(const Duration(milliseconds: 200), () {
            controller.rxPayoutStatusChangedController.value = true;
          });
        } else {
          Get.off(AppRoutes().getWidget(AppRoutes.APP_WEBVIEW_DISPLAY));
        }
      }
    });
  }

  void _scrollToBottom() {
    if (fnroutingNo.hasFocus || fnaccountNo.hasFocus || fnconfirmAccNo.hasFocus) {
      Future.delayed(const Duration(milliseconds: 650), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent +MediaQuery.of(context).viewInsets.bottom +200,
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


  void _validateInputs() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    controller.showError = true;
    arguments["paymentMethodId"] == 5 ? validatePayStack() : validateStripe();
  }

  void validateStripe() {
    // 1. Localize frequently used variables for readability and speed
    final country = controller.selectedCountry;
    final isCompany = controller.isCompanyEnabled;

    final accType = controller.accountTypeController.text.trim();
    final companyName = controller.companyNameController.text.trim();
    final firstName = controller.firstNameController.text.trim();
    final lastName = controller.lastNameController.text.trim();
    final ownerName = controller.accountOwnerNameController.text.trim();
    final bankName = controller.bankNameController.text.trim();
    final branchName = controller.branchNameController.text.trim();
    final bankCode = controller.bankCodeController.text.trim();
    final routing = controller.routingController.text.trim();
    final accountNo = controller.accountNoController.text.trim();
    final confirmAccNo = controller.confirmAccNoController.text.trim();

    // 2. Localize complex country checks into clear boolean flags
    final isBankNameEnabled = bankNameEnableCountries.contains(country);
    final isTransitEnabled = transitNumberEnableCountries.contains(country);
    final isBankCodeEnabled = bankCodeEnableCountries.contains(country);
    final isEurope = europeCountries.contains(country);
    final isClabe = clabeEnableCountries.contains(country);
    final isSortCode = sortCodeEnableCountries.contains(country);

    // 3. Early exit guard clauses for validation
    if (accType.isEmpty) {
      return controller.showInSnackBar(pls_choose_acc_type.tr);
    }
    if (isCompany && companyName.isEmpty) {
      return _showRequiredError(company_name_is_required.tr);
    }
    if (!isCompany && firstName.isEmpty) {
      return _showRequiredError(firstname_required.tr);
    }
    if (!isCompany && lastName.isEmpty) {
      return _showRequiredError(lastname_required.tr);
    }
    if (isBankNameEnabled && ownerName.isEmpty) {
      return _showRequiredError(account_owner_name.tr);
    }
    if (isBankNameEnabled && bankName.isEmpty) {
      return _showRequiredError(bank_name.tr);
    }
    if (isBankNameEnabled && branchName.isEmpty) {
      return _showRequiredError(branch_name.tr);
    }

    // Bank Code Validation
    if ((isTransitEnabled || isBankNameEnabled || isBankCodeEnabled) && bankCode.isEmpty) {
      final fieldLabel = isTransitEnabled ? transit_number.tr : bank_code.tr;
      return _showRequiredError(fieldLabel);
    }

    // Routing Number Validation
    if (!(isEurope || isClabe) && routing.isEmpty) {
      final String fieldLabel;
      if (isSortCode) {
        fieldLabel = sort_code.tr;
      } else if (isBankCodeEnabled || isBankNameEnabled) {
        fieldLabel = branch_code.tr;
      } else if (isTransitEnabled) {
        fieldLabel = Institution_number.tr;
      } else {
        fieldLabel = routing_number.tr;
      }
      return _showRequiredError(fieldLabel);
    }

    // Account Number Validation
    if (accountNo.isEmpty) {
      final fieldLabel = isEurope ? iban_number.tr : (isClabe ? clabe_number.tr : account_number.tr);
      return _showRequiredError(fieldLabel);
    }

    // Confirm Account Number Validation
    if (confirmAccNo.isEmpty) {
      final fieldLabel = isEurope ? confirm_iban_number.tr : (isClabe ? confirm_clabe_number.tr : conf_acc_num.tr);
      return _showRequiredError(fieldLabel);
    }

    // Matching Confirmation Validation
    if (accountNo != confirmAccNo) {
      final fieldLabel = isEurope ? confirm_iban_number.tr : (isClabe ? confirm_clabe_number.tr : conf_acc_num.tr);
      return controller.showInSnackBar(mismatch.trParams({"field": fieldLabel.toLowerCase()}));
    }

    // 4. Fallthrough to final submission logic
    controller.setLoadingController(true);

    if (globals.stripePublishableKey?.isNotEmpty ?? false) {
      controller.checkInternet(addPayout, false);
    } else {
      getPaymentSettings();
    }
  }

  void validatePayStack() {
    // 1. Extract and trim controller texts into clear variables
    final firstName = controller.firstNameController.text.trim();
    final lastName = controller.lastNameController.text.trim();
    final companyName = controller.companyNameController.text.trim();
    final bankCode = controller.bankCodeController.text.trim();
    final accountNo = controller.accountNoController.text.trim();
    final confirmAccNo = controller.confirmAccNoController.text.trim();

    // 2. Linear guard clauses for validation
    if (firstName.isEmpty) {
      return _showRequiredError(firstname_required.tr);
    }
    if (lastName.isEmpty) {
      return _showRequiredError(lastname_required.tr);
    }
    if (companyName.isEmpty) {
      return _showRequiredError(account_type.tr);
    }
    if (bankCode.isEmpty) {
      return _showRequiredError(bank_code.tr);
    }
    if (accountNo.isEmpty) {
      return _showRequiredError(account_number.tr);
    }
    if (confirmAccNo.isEmpty) {
      return controller.showInSnackBar(conf_acc_num.tr);
    }
    if (accountNo != confirmAccNo) {
      return controller.showInSnackBar(mismatch.trParams({"field": conf_acc_num.tr}));
    }

    // 3. Success pathway
    controller.setLoadingController(true);
    addPayout();
  }

// Helper method to eliminate repetitive localization code
  void _showRequiredError(String fieldName) {
    controller.showInSnackBar(
      empty_msg.trParams({"field": fieldName.toLowerCase()}),
    );
  }


  void getPaymentSettings() {
    controller.getPaymentSettings().then((value) {
      if (value!.isEmpty) {
        _validateInputs();
      }
    });
  }
}