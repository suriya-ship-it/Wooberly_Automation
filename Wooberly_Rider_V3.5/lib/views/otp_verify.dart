import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/socket_connection.dart';
import 'package:app_name/controllers/phone_no_verify_controller.dart';
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/services/firebase_service.dart';
import 'package:app_name/widgets/app_builder.dart';
import 'package:app_name/widgets/pin_input_text_field.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../graphql/graphql_config.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_button.dart';
import '../widgets/show_done_view.dart';

class OtpVerify extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OtpVerifyView();
  }
}

class OtpVerifyView extends StatefulWidget {
  @override
  _OtpVerifyViewState createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  PhoneNoVerifyController _phoneNoVerifyController = Get.find();
  late SocketConnection socketIns;
  TextEditingController _pinEditingController = TextEditingController(text: '');
  bool firstClick = true, _isThemeChanged = false;
  String _phoneno = '';

  @override
  void initState() {
    globals.isShowMapPage = false;
    _phoneNoVerifyController.pinvalue = "";
    socketIns = SocketConnection();
    debugPrint("get.currentroute: ${Get.currentRoute}");
    _phoneno = _phoneNoVerifyController.phoneNoController.text;
    _isThemeChanged = false;
    socketConnect();
    _phoneNoVerifyController.initSocket();
    Future.delayed(const Duration(milliseconds: 250), () {
      globals.setButtonIdle();
    });
    super.initState();
  }

  @override
  void dispose() {
    _phoneNoVerifyController.setLoadingController(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return Stack(
        children: [
          PrimaryScaffold(
            disableAppbar: false,
            body: Container(
              color: AppColors.COMMON_BG_COLOR,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 26.0),
                    child: Text(
                      'send_you_code'.tr,
                      style: TextStyle(
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFont.font,
                          color: AppColors.BLACK_TEXT_COLOR),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 24),
                    child: PinInputTextField(
                      pinLength: 4,
                      hintText: '0000',
                      controller: _pinEditingController,
                      keyboardType: TextInputType.number,
                      enabled: true,
                      onChanged: (pin) {
                        _phoneNoVerifyController.pinvalue = pin;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 42, bottom: 10),
                    child: Text(
                      "${'otp_content'.tr}: ${globals.DialCode} ${_phoneno}",
                      style: TextStyle(
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFont.font,
                          color: AppColors.BLACK_TEXT_COLOR),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'dint_receive_code'.tr,
                        style: TextStyle(
                            fontSize: AppDimen.text_size_14,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFont.font,
                            color: AppColors.BLACK_TEXT_COLOR),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      InkWell(
                        onTap: () {
                          if (firstClick) {
                            _phoneNoVerifyController.setLoadingController(true);
                            SystemChannels.textInput.invokeMethod('TextInput.hide');
                            _pinEditingController.clear();
                            _phoneNoVerifyController.pinvalue = "";
                            _phoneNoVerifyController.checkInternet(verifyPhone, false);
                          }
                        },
                        child: Text(
                          'dont_get_code'.tr,
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: AppDimen.text_size_14,
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.w600,
                              color: AppColors.PROMOCODE_LINK_COLOR),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),

                  if( globals.phoneNumberStatus)
                  Align(
                    child: InkWell(
                      onTap: () {
                        _pinEditingController
                          ..text = "1234"
                          ..selection = TextSelection.collapsed(offset: 4);
                        _phoneNoVerifyController.pinvalue = "1234";
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.DIVIDER_COLOR,
                            borderRadius: BorderRadius.all(Radius.circular(17),
                            ),
                        ),
                        padding: const EdgeInsetsDirectional.only(start: 19, end: 19, top: 7, bottom: 7),
                        child: Text(
                          "${'otp_value'.tr} ${'demo_only'.tr}",
                          style: TextStyle(
                              fontFamily: AppFont.font,
                              fontSize: AppDimen.text_size_14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.BLACK_TEXT_COLOR),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 20, bottom: 24.0),
                      child: PrimaryButton(
                        buttonTitle: 'Proceed'.tr,
                        buttonImage: primaryBtnArrow,
                        callback: () {
                          if (firstClick) {
                            firstClick = false;
                            _checkValidate(context);
                          }
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
            customAppBarFunction: () {
              if (!_isThemeChanged && !globals.isShowMapPage) {
                Future.delayed(const Duration(milliseconds: 250), () {
                  _phoneNoVerifyController.preferences.clearPreference();
                  globals.authToken = null;
                  globals.setButtonIdle();
                });
                _phoneNoVerifyController.setBackNavigation();
              }
            },
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
    });
  }

  void _checkValidate(BuildContext ctx) {
    if (_phoneNoVerifyController.pinvalue.toString().isNotEmpty) {
      if (_phoneNoVerifyController.pinvalue.toString().length == 4) {
        _phoneNoVerifyController.setLoadingController(true);

        if (globals.deviceId.isEmpty) {
          FirebaseService.getFcmToken().then((token) {
            globals.deviceId = token ?? "";

            _phoneNoVerifyController.checkInternet(verifyOTP, false);
          });
        } else {
          _phoneNoVerifyController.checkInternet(verifyOTP, false);
        }
      } else {
        firstClick = true;
        _phoneNoVerifyController.showInSnackBar('valid_msg'.trParams({'field': 'otp_label'.tr}));
      }
    } else {
      firstClick = true;
      _phoneNoVerifyController.showInSnackBar('empty_msg'.trParams({'field': 'otp_label'.tr}));
    }
  }

  void verifyOTP() {
    _phoneNoVerifyController.verifyOTP().then((value) async {
      _phoneNoVerifyController.setLoadingController(false);

      if (value.isNotEmpty) {
        firstClick = true;

        if (value != "null") {
          _pinEditingController.clear();
          _phoneNoVerifyController.pinvalue = "";
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          _phoneNoVerifyController.showInSnackBar(value);
        } else {
          _phoneNoVerifyController.netOffSnackbar(verifyOTP, false);
        }
      } else {
        _phoneNoVerifyController.preferences.authToken= globals.authToken!;
        print('test9 ${ _phoneNoVerifyController.preferences.authToken}');

        if (globals.authToken!.isEmpty) {
          firstClick = true;
          _phoneNoVerifyController.phoneNoController.text = "";
          globals.setButtonIdle();
          _phoneNoVerifyController.setNavigation(AppRoutes.APP_NAME_FIELDS);
        } else {
          _phoneNoVerifyController.setLoadingController(true);
          getProfileInfo();
        }
      }
    });
  }

  void verifyPhone() {
    _phoneNoVerifyController.getSecurityKey().then((securityKey) {
      _phoneNoVerifyController.VerifyPhone(securityKey).then((value) {
        globals.setButtonIdle();
        if (value.isNotEmpty) {
          if (value != "null")
            _phoneNoVerifyController.showInSnackBar(value);
          else {
            _phoneNoVerifyController.netOffSnackbar(verifyPhone, false);
          }
        } else {
          _phoneNoVerifyController.showInSnackBar('otp_was_resent_successfully_to_your_number'.tr);
        }
      });
    });
  }

  void getProfileInfo() {
    _phoneNoVerifyController.getProfileInfo().then((value) {
      _phoneNoVerifyController.setLoadingController(false);
      if (value!.isNotEmpty) {
        if (value == "timeout") {
          firstClick = true;
          _phoneNoVerifyController.toast.show(
            context: context,
            message: 'session_timeout_err'.tr,
          );
          globals.refreshApp = true;
          globals.authToken = "";
          globals.uploadedImage = null;
          globals.picture.value = "";
          globals.cardLastFour = 0;

          globals.preferredPaymentMethod = 1;
          AppBuilder.of(context)?.rebuild();
          _getSimCountryCode();
          _phoneNoVerifyController.preferences.clearPreference();
          RegisterController().dispose();

          FirebaseService.getFcmToken().then((token) {
            globals.deviceId = token ?? "";
          });

          Get.offAllNamed(AppRoutes.APP_SPLASH);
        } else if (value == "offline") {
          firstClick = true;
          _phoneNoVerifyController.netOffSnackbar(getProfileInfo, false);
        } else {
          firstClick = true;
          _phoneNoVerifyController.showInSnackBar(value);
        }
      } else {
        debugPrint("scoffoldcontext.mounted: ${mounted}");
        if (mounted) {
          sendLoginCheck();
        } else {
          _phoneNoVerifyController.preferences.clearPreference();
          globals.authToken = null;
          globals.setButtonIdle();
        }
      }
    });
  }

  socketConnect() {
    globals.socket?.onConnect((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });
    globals.socket?.onConnectError((data) {
      if (data is Map) {
        data = json.encode(data);
      }

      debugPrint("onConnectError ------> ${data}");
    });
    globals.socket?.onError((data) {
      if (data is Map) {
        data = json.encode(data);
      }

      debugPrint("onError ------> ${data}");
    });
    globals.socket?.connect();
  }

  sendLoginCheck() async {
    BuildContext ctx = context;

    List<String> arg = [
      '{"data" : {"auth" : "${globals.authToken}", "userId" : "${globals.userid}" , "userType" : "1"}}'
    ];
    socketIns.onsendMessage("loginCheck", arg);
    debugPrint("socketInsconnected: ${ globals.socket?.connected}");

    globals.isShowMapPage = true;

    globals.isContinuousLoading = true;

    Map<String, dynamic>? _tripResult =
        await graphQlObject.getQueryValues(graphQlObject.graphQLClientWithHeader, "tripStatus_query", null);
    if (_tripResult?["GetTripStatus"]["status"] == 200) {
      globals.tripStatus = _tripResult?["GetTripStatus"]["result"]["tripStatus"];

      if (mounted) {
        if (globals.theme == 1) {
          var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
          globals.isDarkTheme = brightness == Brightness.dark;
          if (globals.isDarkTheme) {
            AppColors().changeToDark();
          } else {
            AppColors().changeToLight();
          }
        } else if (globals.theme == 2) {
          globals.isDarkTheme = false;
          AppColors().changeToLight();
        } else {
          globals.isDarkTheme = true;
          AppColors().changeToDark();
        }
        ctx = context;
        _isThemeChanged = true;
      } else {
        _phoneNoVerifyController.preferences.clearPreference();
        globals.authToken = null;
        globals.setButtonIdle();
      }

      firstClick = true;
      if (globals.tripStatus == "started" ||
          globals.tripStatus == "accepted" ||
          globals.tripStatus == "created" ||
          globals.tripStatus == "approved" ||
          (globals.tripStatus == "completed" &&
              _tripResult?["GetTripStatus"]["result"]["paymentStatus"] != "completed") ||
          globals.tripStatus == "locationReached") {
        if (!mounted) {
          globals.setButtonIdle();
          return;
        }
        globals.isCreatedTrip = true;
        Get.offAllNamed(AppRoutes.APP_MAP_MAIN);
      } else {
        Future.delayed(Duration(milliseconds: 400)).then((value) {
          Get.offAllNamed(AppRoutes.APP_HOME);
        });
      }
    } else {
      Future.delayed(Duration(milliseconds: 400)).then((value) {
        Get.offAllNamed(AppRoutes.APP_HOME);
      });
    }
    Future.delayed(Duration(milliseconds: 200)).then((_) {
      AppBuilder.of(ctx)?.rebuild();
    });
  }

  Future<void> _getSimCountryCode() async {
    try {
       await _phoneNoVerifyController.getNativeLocation();
    } on Exception catch (e) {
      debugPrint("Exception in getLocation $e");
    }
  }
}