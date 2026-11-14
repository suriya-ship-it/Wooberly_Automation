import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app/enums/button_state.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/controllers/phone_no_verify_controller.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/services/firebase_service.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/static_page.dart';
import 'package:app_name/widgets/country_code_picker.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../resources/values/app_images.dart';
import '../widgets/check_box.dart';
import '../widgets/cupertino_language_picker.dart';
import '../widgets/custom_rich_text.dart';
import '../widgets/show_done_view.dart';

class PhoneNoAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PhoneNoAuthView();
  }
}

class PhoneNoAuthView extends StatefulWidget {
  @override
  _PhoneNoAuthViewState createState() => _PhoneNoAuthViewState();
}

class _PhoneNoAuthViewState extends State<PhoneNoAuthView> {
  PhoneNoVerifyController _phoneNoVerifyController=Get.find();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool firstClick = true;
  bool  _isOtpNavigation = false;
  late FocusNode phonenoFocusNode;

  @override
  void initState() {
    _phoneNoVerifyController.clearApplicationDocumentsDirectory();
    phonenoFocusNode = FocusNode();
    _isOtpNavigation = false;
    _phoneNoVerifyController.phoneNoController.text = "";
    _phoneNoVerifyController.isSMSAcknowledged = false;


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globals.currencyRates == null || globals.currencyRates.isEmpty)
        _phoneNoVerifyController.checkInternet(getCurrencyRates, false);

      if (globals.stripePublishableKey.isEmpty)
        _phoneNoVerifyController.checkInternet(getSecureSiteSettings, false);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _phoneNoVerifyController.preferences.clearPreference();
      globals.authToken = null;
      globals.setButtonIdle();
    });
    super.initState();
  }

  onClickVerifyButton() {
    if (firstClick) {
      int phonenolength = _phoneNoVerifyController.phoneNoController.text
          .trim()
          .replaceFirst(RegExp(r'^0+'), '')
          .length;

      debugPrint("phonenolength: $phonenolength");
      if (phonenolength == 0) {
        _phoneNoVerifyController.showInSnackBar( 'empty_msg'.trParams({'field':'phone_no'.tr}));
      } else if (phonenolength >= 4 && phonenolength <= 15 && _phoneNoVerifyController.isSMSAcknowledged) {
        firstClick = false;
        _phoneNoVerifyController.checkInternet(verifyPhone, false);
      }else if(!_phoneNoVerifyController.isSMSAcknowledged && (phonenolength >= 4 && phonenolength <= 15)){
        _phoneNoVerifyController.showInSnackBar( 'sms_acknowledge_error'.trParams({'field':'terms_and_privacy'.tr}));
      } else {
        _phoneNoVerifyController.showInSnackBar('valid_msg'.trParams({'field':'phone_no'.tr}));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
          return Stack(
            children: [
              PrimaryScaffold(
                key: _scaffoldKey,
                disableAppbar: false,
                customAppBarFunction: () {
                  globals.setButtonDisabled();
                  if(!_isOtpNavigation) {
                    Future.delayed(const Duration(milliseconds: 250), () {
                      _phoneNoVerifyController.preferences.clearPreference();
                      globals.authToken = null;
                      globals.setButtonIdle();
                    });
                    _phoneNoVerifyController.setBackNavigation();
                  }
                },
                body: ColoredBox(
                  color: AppColors.COMMON_BG_COLOR,
                  child: Container(
                    margin:
                    const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, top: 26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            'enter_your'.trParams({'field2':'phone_no'.tr}),
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_22,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        new Row(
                          children: <Widget>[
                            CountryCodePicker(
                              onChanged: (countryCode) {
                                debugPrint("onChanged: ${countryCode.code}");
                                WidgetsFlutterBinding.ensureInitialized().performReassemble();
                              },
                              initialSelection: globals.CountryCode,
                              showDialog: true,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 0, end: 10, top: 10.0, bottom: 10.0),
                                child: Container(
                                  color: AppColors.PRIMARY_LIGHT_COLOR,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20,)
,
                                    child: TextField(
                                      enableIMEPersonalizedLearning: false,
                                      keyboardType: TextInputType.number,
                                      focusNode: phonenoFocusNode,
                                      autofocus: true,
                                      controller: _phoneNoVerifyController.phoneNoController,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: new InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'sample_phone'.tr,
                                          hintStyle: TextStyle(
                                            color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                            fontWeight: FontWeight.w400,
                                            fontSize: AppDimen.text_size_16,
                                          )),
                                      style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontWeight: FontWeight.w300,
                                        fontSize: AppDimen.text_size_18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 20.0),
                              child: Container(
                                  child: CupertinoLanguagePicker(
                                    pickerContext: context,
                                    pickerType: "launguage",
                                    pickerList: _phoneNoVerifyController.launguages,
                                  ).getWidget() ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 20.0, top: 20.0, end: 5),
                                child: Text(
                                    'Please_choose_primary_language'.tr,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_14,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w400)),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 24.0),
                          child: Align(
                            alignment: AlignmentDirectional.bottomStart,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 4),
                                      child: CustomCheckBox(
                                        onChanged: (value){
                                          _phoneNoVerifyController.isSMSAcknowledged = value;
                                        },
                                        initialData: _phoneNoVerifyController.isSMSAcknowledged,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: CustomRichText(
                                          text: 'sms_acknowledge_content'.trParams({'field':"${'terms_and_privacy'.tr}."}),
                                          onTapResult:(result){
                                            Get.to(() => StaticPageStateLess(
                                              staticPageContentId: 4,
                                              staticPageTitle: 'terms_and_privacy'.tr,
                                            ),binding: HomeBinding())?.then((v) {
                                              phonenoFocusNode.unfocus();
                                            });

                                          }
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(top: 25),
                                  child: Obx(() {
                                    globals.buttonState.value;
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (globals.buttonState.value == ButtonState.disabled)
                                        globals.setButtonIdle();
                                    });
                                    return PrimaryButton(
                                      buttonTitle: 'Verify'.tr,
                                      buttonImage: primaryBtnArrow,
                                      callback: onClickVerifyButton,
                                    );
                                  }
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  right: 0.0,
                  left: 0.0,
                  child: MediaQuery.of(context).viewInsets.bottom >= 175.0
                      ? InputDoneView()
                      : const SizedBox.shrink()),
            ],
          );
        }
          );
        }




  getCurrencyRates() {
    _phoneNoVerifyController.getCurrencyRates().then((value) {
      if (value == "null")
        _phoneNoVerifyController.netOffSnackbar( getCurrencyRates, false);
      else if (value!.isEmpty) {}
    });
  }

  getSecureSiteSettings() {
    globals.closeKeyBoard = false;
      _phoneNoVerifyController.getSecureSiteSettings().then((value) {
        if (value == "null")
          _phoneNoVerifyController.netOffSnackbar( getSecureSiteSettings, false);
      });
  }

  Future<void> verifyPhone() async {
    globals.setButtonLoading();

    try {
      if (globals.deviceId.isEmpty) {
        await FirebaseService.deleteFcmToken();
        final token = await FirebaseService.getFcmToken();
        globals.deviceId = token ?? "";
      }

      if (!globals.fcmConfigured) {
        FirebaseService().configureFCM();
      }

      final securityKey = await _phoneNoVerifyController.getSecurityKey();
      final value = await _phoneNoVerifyController.VerifyPhone(securityKey);

      firstClick = true;

      if (value != null && value.isNotEmpty) {
        globals.setButtonIdle();
        if (value != "null") {
          _phoneNoVerifyController.showInSnackBar(value);
        } else {
          _phoneNoVerifyController.netOffSnackbar(verifyPhone, false);
        }
        return;
      }

      // no error — proceed to OTP screen
      globals.isContinuousLoading = false;
      globals.phoneNumber = _phoneNoVerifyController.phoneNoController.text
          .replaceFirst(RegExp(r'^0+'), '');

      if (mounted) {
        _phoneNoVerifyController.setNavigation(AppRoutes.APP_OTP_VERIFY);
        _isOtpNavigation = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _isOtpNavigation = false;
        });
      }
    } catch (e) {
      globals.setButtonIdle();
      _phoneNoVerifyController.netOffSnackbar(verifyPhone, false);
    }
  }
}