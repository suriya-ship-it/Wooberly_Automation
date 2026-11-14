import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/phone_no_verify_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/socket_connection.dart';
import 'package:wooberly_driver/widgets/pin_input_text_field.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';
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
  final PhoneNoVerifyController _controller = Get.find();
  late SocketConnection socketIns;
  late BuildContext scoffoldcontext;

  TextEditingController _pinEditingController = TextEditingController(text: '');
  bool singleClick = true, firstClick = true;

  @override
  void initState() {
    _controller.pinvalue = "";
    socketIns = SocketConnection();
    App().initSocket();
    globals.currentShowingPage = AppRoutes.APP_OTP_VERIFY;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return PrimaryScaffold(
              disableAppbar: false,
              body: Container(
                color: AppColors.COMMON_BG_COLOR,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: Text(
                        send_you_code.tr,
                        style: TextStyle(
                            fontSize: AppDimen.text_size_22,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.font,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: 24),
                      child: PinInputTextField(
                        pinLength: 4,
                        hintText: '0000',
                        controller: _pinEditingController,
                        textInputAction: TextInputAction.done,
                        enabled: true,
                        onSubmit: (pin) {},
                        onChanged: (pin) {
                          _controller.pinvalue = pin;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: 42, bottom: 10),
                      child: Text(
                        "${otp_content.tr}: ${globals.DialCode} ${_controller.phoneNoController.text}",
                        style: TextStyle(
                            fontSize: AppDimen.text_size_14,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFont.font,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          dint_receive_code.tr,
                          style: TextStyle(
                              fontSize: AppDimen.text_size_14,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFont.font,
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                        ),
                       const SizedBox(
                          width: 8,
                        ),
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              SystemChannels.textInput.invokeMethod('TextInput.hide');
                              _pinEditingController.clear();
                              _controller.pinvalue = "";
                              _controller.checkInternet(verifyPhone, false);
                            },
                            child: Text(
                              do_not_get_code.tr,
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize: AppDimen.text_size_14,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.TEXT_LINK_COLOR),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    globals.phoneNumberStatus ?
                    Align(
                      child: InkWell(
                        onTap: () {
                          _pinEditingController
                            ..text = "1234"
                            ..selection = TextSelection.collapsed(offset: 4);
                          _controller.pinvalue = "1234";
                        },
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                              color: AppColors.DISABLE_COLOR,
                              borderRadius: BorderRadius.all(Radius.circular(17))),
                          padding: EdgeInsetsDirectional.only(
                              start: 10, end: 10, top: 7),
                          child: Text(
                            "${otp_value.tr} ${demo_only.tr}",
                            style: TextStyle(
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ) : SizedBox.shrink(),
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(top: 20, bottom: 24.0),
                        child: PrimaryButton(
                          buttonTitle: Proceed.tr,
                          buttonImage: primaryBtnArrow,
                          callback: () {
                            if (firstClick) {
                              firstClick = false;
                              _checkValidate();
                            }
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              onChanged: (map) {
                scoffoldcontext = map["scaffoldcontext"];
              },
              customAppBarFunction: () {
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (globals.isShowMapPage) {
                    App().appPreference.clearPreference();
                    globals.authToken = null;
                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                  }
                });
                App().setBackNavigation();
              },
            );
          }
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

  void _checkValidate() {
    if (_controller.pinvalue.toString().isNotEmpty) {
      if (_controller.pinvalue.toString().length == 4) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
        if (globals.deviceId == null || globals.deviceId.isEmpty) {
          FirebaseMessaging.instance.getToken().then((token) {
            globals.deviceId = token ?? "";
            _controller.checkInternet(verifyOTP, false);
          }).catchError((err) {
            debugPrint("otp_verify getToken error: $err");
            _controller.checkInternet(verifyOTP, false);
          });
        } else {
          _controller.checkInternet(verifyOTP, false);
        }
      } else {
        firstClick = true;
        _controller.showInSnackBar(
            valid_msg.trParams({"field":otp_label.tr}));
      }
    } else {
      firstClick = true;
      _controller.showInSnackBar(
          empty_msg.trParams({"field":otp_label.tr}));
    }
  }

  void verifyOTP() {
    _controller.verifyOTP().then((value) {
      if (value.isNotEmpty) {
        firstClick = true;

        if (value != "null") {
          _pinEditingController.clear();
          _controller.pinvalue = "";
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          _controller.showInSnackBar( value);
        } else {
          _controller.netOffSnackbar(verifyOTP, false);
        }
      } else {
        _controller.phoneNoController.clear();
        App().appPreference.authToken = globals.authToken;
        App().appPreference.userId = globals.userid;

        if (globals.authToken!.isEmpty) {
          firstClick = true;
          App().setNavigation(AppRoutes.APP_NAME_FIELDS);
        } else {
          getProfileInfo();
        }
      }
    });
  }

  void verifyPhone() {
    App().getSecurityKey().then((securityKey) {
      _controller.VerifyPhone(securityKey).then((value) {
        if (value.isNotEmpty) {
          if (value == "null") {
            _controller.netOffSnackbar(verifyPhone, false);
          } else {
            _controller.showInSnackBar( value);
          }
        } else {
          _controller.showInSnackBar(otp_was_resent_successfully_to_your_number.tr);
        }
      });
    });
  }

  void getProfileInfo() {
    _controller.getProfileInfo().then((value) {
      if (value.isNotEmpty) {
        if (value == "timeout") {
          firstClick = true;
          App().toast.show(
                context: context,
                message: session_timeout_err.tr,
              );
          App().appPreference.clearPreference();
          App().setNavigation(AppRoutes.APP_ROUTE_LOGIN);
        } else if (value == "offline") {
          firstClick = true;
          _controller.checkInternet(getProfileInfo, false);
        } else {
          firstClick = true;
          _controller.showInSnackBar( value);
          singleClick = true;
        }
      } else {
        if (scoffoldcontext.mounted) {
          _controller.getPayouts();
          updateDriverInfo();
        } else {
          App().appPreference.clearPreference();
          globals.authToken = null;
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        }
      }
    });
  }



  sendLoginCheck() async{
    BuildContext ctx;
    if (scoffoldcontext.mounted) {
      ctx = context;

      List<String> arg = [
        '{"data" : {"auth" : "${globals.authToken}", "userId" : "${globals.userid}"  , "userType" : "2"}}'
      ];
      socketIns.onsendMessage("loginCheck", arg);

      _controller.phoneNoController = TextEditingController(text: "");
      firstClick = true;
      globals.isShowMapPage = true;
      if(Platform.isIOS) await Permission.camera.request();
      if (ctx != null) App().setNavigation(AppRoutes.APP_MAP_MAIN);
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        _controller.phoneNoController.text = "";
      });
    } else {
      App().appPreference.clearPreference();
      globals.authToken = null;
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    }
  }

  void setbytecode(String front, String s) async {
    http.Response response = await http.get(
      Uri.parse(front),
    );
    String image = base64.encode(response.bodyBytes);

    if (s == "front") {
      App().appPreference.LicenceFront = image;
    } else if (s == "back") {
      App().appPreference.LicenceBack = image;
    } else if (s == "RC") {
      App().appPreference.vehicleRC = image;
    } else if (s == "Insurance") {
      App().appPreference.vehicleInsurance = image;
    }
  }

  void updateDriverInfo() {
    if (globals.theme.value == 1) {
      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      globals.isDarkTheme = brightness == Brightness.dark;
      App().appPreference.preferredTheme = globals.isDarkTheme;
      if (globals.isDarkTheme) {
        AppColors().changeToDark();
      } else {
        AppColors().changeToLight();
      }
    } else if (globals.theme.value == 2) {
      globals.isDarkTheme = false;
      App().appPreference.preferredTheme = globals.isDarkTheme;
      AppColors().changeToLight();
    } else {
      globals.isDarkTheme = true;
      App().appPreference.preferredTheme = globals.isDarkTheme;
      AppColors().changeToDark();
    }
    _moveToDocumentMain();
  }

  void _moveToDocumentMain() {
    debugPrint("globals.isVehicleDetailsReq: ${globals.isVehicleDetailsReq}");
    if (globals.isVehicleDetailsReq) {
      App().setNavigation(AppRoutes.APP_ROUTE_DETAILS);
    } else {
      if (globals.front.isNotEmpty &&
          globals.back.isNotEmpty &&
          globals.RC.isNotEmpty &&
          globals.Insurance.isNotEmpty) {
        sendLoginCheck();
      } else {
        if (globals.front.isNotEmpty)
          setbytecode(globals.front, "front");
        if (globals.back.isNotEmpty)
          setbytecode(globals.back, "back");
        if (globals.RC.isNotEmpty)
          setbytecode(globals.RC, "RC");
        if (globals.Insurance.isNotEmpty)
          setbytecode(globals.Insurance, "Insurance");
        _controller.phoneNoController.text = "";
        App().setNavigation(AppRoutes.APP_DOCUMENT_MAIN);
      }
    }
  }
}