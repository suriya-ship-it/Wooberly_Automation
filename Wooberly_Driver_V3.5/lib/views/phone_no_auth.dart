import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/binding/home_binding.dart';
import 'package:wooberly_driver/controller/auth_controllers/phone_no_verify_controller.dart';
import 'package:wooberly_driver/controller/base_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/static_page.dart';
import 'package:wooberly_driver/widgets/country_code_picker.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/cupertino_language_picker.dart';
import '../widgets/check_box.dart';
import '../widgets/custom_rich_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';
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
  final PhoneNoVerifyController _controller = Get.find();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;
  String _isNeedtoUpdate = "";
  bool _isOtpNavigation = false;
  FocusNode phoneNoFocusNode = FocusNode();
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void initState() {
    _controller.phoneNoController.text = "";
    _controller.isSMSAcknowledged = false;
    _isOtpNavigation = false;
    App().setTripInfo_IOS("", "");

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint("phone_no_auth onTokenRefresh: $token");
      globals.deviceId = token;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (context.mounted) {
        App().appPreference.clearPreference();
        globals.authToken = null;
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      }
    });

    super.initState();
  }

  initAction() async {
    if (Platform.isAndroid) _getLocation();
    debugPrint("getUpdatedVersion: deviceid ${globals.deviceId}");
    if (globals.deviceId == null ||
        globals.deviceId == "" ||
        globals.deviceId == "GetNewFirebaseToken") {
      getUpdatedVersion(true);
    } else {
      getUpdatedVersion(false);
    }
  }

  getUpdatedVersion(bool isSetFcm) async {
    debugPrint("getUpdatedVersion: ${isSetFcm} --- ${globals.authToken}");
    if (isSetFcm) {
      await FirebaseMessaging.instance
          .requestPermission(sound: true, badge: true, alert: true)
          .then((value) async {
        debugPrint("getUpdatedVersion: requestPermission --- ${globals.authToken}");
        await _fetchAndProceedWithToken();
      });
    } else {
      _controller.getUpdatedVersion().then((value) {
        _isNeedtoUpdate = value!;
        if (value.isNotEmpty) {
          _showUpdateDialog();
        } else {
          _controller.checkInternet(verifyPhone, false);
        }
      });
    }
  }

  /// Fetches the FCM token and proceeds with version check / phone verify.
  Future<void> _fetchAndProceedWithToken() async {
    // 1. If we already have a valid deviceId, proceed directly
    if (globals.deviceId.isNotEmpty && globals.deviceId != "GetNewFirebaseToken") {
      debugPrint("getUpdatedVersion: already have deviceId --- ${globals.deviceId}");
      _proceedWithVersionCheck();
      return;
    }

    // 2. On iOS/macOS, wait briefly for APNS token before calling getToken()
    if (Platform.isIOS || Platform.isMacOS) {
      debugPrint("getUpdatedVersion: waiting for APNS token...");
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      int attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        } catch (e) {
          debugPrint("getAPNSToken error: $e");
        }
        attempts++;
      }
      debugPrint("getUpdatedVersion: APNS token result: $apnsToken (attempts: $attempts)");
    }

    // 3. Try to get token with getToken()
    try {
      debugPrint("getUpdatedVersion: calling getToken...");
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        globals.deviceId = token;
        debugPrint("getUpdatedVersion: device --- ${globals.deviceId}");
      }
    } catch (e) {
      debugPrint("getUpdatedVersion: getToken error --- ${e.toString()}");
    }

    // 4. Always proceed so the login flow is never blocked
    _proceedWithVersionCheck();
  }

  void _proceedWithVersionCheck() {
    _controller.getUpdatedVersion().then((value) {
      _isNeedtoUpdate = value!;
      debugPrint("getUpdatedVersion: _isNeedtoUpdate --- ${_isNeedtoUpdate}");
      if (value.isNotEmpty) {
        _showUpdateDialog();
      } else {
        _controller.checkInternet(verifyPhone, false);
      }
    });
  }

  /// Safely deletes the FCM token on iOS by first ensuring the APNS token
  /// is available. Call this only when you explicitly need to rotate the token.
  Future<void> safeDeleteToken() async {
    if (Platform.isIOS || Platform.isMacOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      int attempts = 0;
      while (apnsToken == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) {
        debugPrint('APNS token still not available, skipping deleteToken()');
        return;
      }
    }
    await FirebaseMessaging.instance.deleteToken();
  }

  /// Waits for the iOS APNS token for up to [maxAttempts] × 500 ms.
  /// Returns immediately with "not-needed" on Android.
  Future<String?> _waitForApnsToken({int maxAttempts = 20}) async {
    if (!(Platform.isIOS || Platform.isMacOS)) return "not-needed";
    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    int attempts = 0;
    while (apnsToken == null && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      attempts++;
    }
    if (apnsToken == null) {
      debugPrint('APNS token not available after ${maxAttempts * 500}ms.');
    }
    return apnsToken;
  }

  _showUpdateDialog() {
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
    return Get.dialog(
        barrierDismissible: false,
        PopScope(
            canPop: false,
            child: Obx(
                    () {
                  return globals.isAutoThemeUpdated.value != null ? AlertDialog(
                    backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    title: Row(
                      children: [
                        Image.asset(dialogLogoPng, width: 40, height: 40.0),
                        SizedBox(width: 15),
                        Text(
                          force_update.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              _isNeedtoUpdate,
                              style: TextStyle(fontSize: AppDimen.text_size_16),
                            ),
                          ),
                          SizedBox(height: 30),
                          InkWell(
                            onTap: () {
                              if (globals.deviceName == "android") {
                                UrlLauncher.launchUrl(Uri.parse(globals.playStoreURL),
                                    mode: UrlLauncher.LaunchMode.externalApplication);
                              } else if (globals.deviceName == "ios") {
                                UrlLauncher.launchUrl(Uri.parse(globals.appStoreURL));
                              }
                            },
                            child: Container(
                              width: Get.width,
                              height: 50,
                              padding: const EdgeInsetsDirectional.only(
                                start: 20,
                                end: 20,
                              ),
                              decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_COLOR_DARK,
                                  borderRadius: BorderRadius.circular(4)
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(update.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16
                                    )
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ) : SizedBox.shrink();
                }
            )
        )
    );
  }

  Future<void> _getLocation() async {
    try {
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
         await App().getNativeLocation();
        if (globals.userLat == 0.0 && globals.userLon == 0.0) {
          globals.rideCompletedAt = LatLng(globals.userLat, globals.userLon);
          List<Placemark> placemark = await Geocoding().placemarkFromCoordinates(globals.userLat, globals.userLon,);
          Placemark first = placemark[0];
          if ( globals.currentShowingPage != AppRoutes.APP_OTP_VERIFY) {
            if (_controller.phoneCountrycode.isEmpty)
              globals.CountryCode = first.isoCountryCode!;
            globals.addressUpdateController.value = true;
          }
        }
      }
    } on Exception catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return PrimaryScaffold(
              key: _scaffoldKey,
              disableAppbar: false,
              customAppBarFunction: () {
                if (!_isOtpNavigation) {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    App().appPreference.clearPreference();
                    globals.authToken = null;
                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
                  });
                  App().setBackNavigation();
                }
              },
              body: Container(
                color: AppColors.COMMON_BG_COLOR,
                margin: EdgeInsetsDirectional.only(start: 24.0, end: 24.0, top: 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        enter_your.trParams({"field2":phone_no.tr}),
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_22,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w600)),
                   const SizedBox(height: 10),
                    new Row(
                      children: <Widget>[
                        CountryCodePicker(
                          onChanged: (countryCode) {
                            globals.CountryCode = countryCode.code ?? 'US';
                            WidgetsFlutterBinding.ensureInitialized().performReassemble();
                          },
                          initialSelection: globals.CountryCode,
                          showDialog: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ColoredBox(
                              color: AppColors.PRIMARY_COLOR_WHITE,
                              child: Padding(
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  autofocus: false,
                                  focusNode: phoneNoFocusNode,
                                  controller: _controller.phoneNoController,
                                  onChanged: (value) {
                                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                  },
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: new InputDecoration(
                                      border: InputBorder.none,
                                      hintText: sample_phone.tr,
                                      hintStyle: TextStyle(
                                        color: AppColors.HIND_TEXT_COLOR,
                                        fontWeight: FontWeight.w400,
                                        fontSize: AppDimen.text_size_16,
                                      )),
                                  style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontWeight: FontWeight.w300,
                                    fontSize: AppDimen.text_size_18,
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
                          padding: EdgeInsetsDirectional.only(top: 20.0),
                          child: Container(
                              color: AppColors.PRIMARY_COLOR_WHITE,
                              child: CupertinoLanguagePicker(
                                focusNode: phoneNoFocusNode,
                                pickerContext: context,
                                pickerType: "launguage",
                                pickerlist: _controller.launguages,
                              ).getWidget()),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsetsDirectional.only(
                                start: 20.0, top: 20.0, end: 5),
                            child: Text(
                                Please_choose_primary_language.tr,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_14,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsetsDirectional.only(bottom: 24.0),
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: CustomCheckBox(
                                    onChanged: (value){
                                      _controller.isSMSAcknowledged = value;
                                    },
                                    initialData: _controller.isSMSAcknowledged,
                                  ),
                                ),
                               const SizedBox(width: 10,),
                                Flexible(
                                  child: CustomRichText(
                                      text: sms_acknowledge_content.trParams({"field":"${terms_and_privacy.tr}."}),
                                      onTapResult:(result){
                                        Get.to(
                                          StaticPageStateLess(
                                            staticPageContentId: 4,
                                            staticPageTitle: terms_and_privacy.tr,
                                          ),
                                          binding: HomeBinding()
                                        )!.then((v) {phoneNoFocusNode.unfocus();});
                                      }
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: 20),
                              child: GetBuilder<BaseController>(
                                  init: globals.baseController,
                                  id: globals.rxLoadingController.id,
                                  builder: (val) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (globals.rxLoadingController.value == 2)
                                        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                    });
                                    return PrimaryButton(
                                      buttonTitle: verify.tr,
                                      buttonImage: primaryBtnArrow,
                                      callback: onClickVerifyButton,
                                    );
                                  }),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onChanged: (map) {
                scoffoldcontext = map["scaffoldcontext"];
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

  onClickVerifyButton() async {
    globals.authToken = "";
    int phonenolength = _controller.phoneNoController.text.toString().replaceFirst(RegExp(r'^0+'), '').length;
    if (phonenolength > 0) {
      if (phonenolength >= 4 && phonenolength <= 15 && _controller.isSMSAcknowledged) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
        var hasInternet = await _controller.checkInternet(initAction, false);
        if (!hasInternet) {
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        }
      }else if(!_controller.isSMSAcknowledged && (phonenolength >= 4 && phonenolength <= 15)){
        _controller.showInSnackBar( sms_acknowledge_error.trParams({"field":terms_and_privacy.tr}));
      } else {
        _controller.showInSnackBar(
            valid_msg.trParams({"field":phone_no.tr}));
      }
    } else {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":phone_no.tr}));
    }
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    globals.currentShowingPage = '';
    super.dispose();
  }

  void verifyPhone() async {
    App().getSecurityKey().then((securityKey) {
      _controller.VerifyPhone(securityKey).then((value) {
        if (value.isNotEmpty) {
          if (value == "null") {
            _controller.netOffSnackbar(verifyPhone, false);
          } else {
            if (mounted) {
              _controller.showInSnackBar( value);
              _isOtpNavigation = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                _isOtpNavigation = false;
              });
            }
          }
        } else {
          globals.phnNo = _controller.phoneNoController.text.replaceFirst(RegExp(r'^0+'), '');
          App().appPreference.LoginNo = _controller.phoneNoController.text;
          App().appPreference.CountryCode = globals.DialCode;
          App().setNavigation(AppRoutes.APP_OTP_VERIFY);
        }
      });
    });
  }
}