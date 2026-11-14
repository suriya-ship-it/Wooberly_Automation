import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/services/firebase_service.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../databases/app_preferences.dart';
import '../main.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../controllers/splash_controller.dart';
import '../widgets/app_builder.dart';
import '../widgets/custom_dialog_box.dart';
import '../widgets/primary_button.dart';

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainView();
  }
}

class MainView extends StatefulWidget {
  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with WidgetsBindingObserver {
  int mainFlexSize = 60;

  bool _locationSettingCalled = false;
  late BuildContext scoffoldcontext;
  late List<Permission> permission;
  SplashController splashController = Get.find();
  late RemoteMessage foregroundMessage;
  String _appUpdateContent = "";
  late bool isCurrentPage;
  bool _isContactPermissionDialogOpen = false;
  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  Worker? _buttonStateWorker;
  @override
  void initState() {
    isCurrentPage = true;
    WidgetsBinding.instance.addObserver(this);
    permission = [Permission.location];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        (mapsImplementation as GoogleMapsFlutterAndroid).useAndroidViewSurface = false;
      }
      splashController.checkInternet(getUpdatedVersion, false);
    });
    _buttonStateWorker = ever(globals.buttonState, (event) {
      if (mounted && isCurrentPage) {
        try {
          if ((ModalRoute.of(context)?.isCurrent ?? false) && event == 1) {
            globals.setButtonDisabled();
          }
        } catch (_) {}
      }
    });
    super.initState();
  }

  Future<void> requestPermission() async {
    final Map<Permission, PermissionStatus> permissionRequestResult =
        await permission.request();
    PermissionStatus? _permissionStatus =
        permissionRequestResult[Permission.location];
    if (_permissionStatus == PermissionStatus.granted) {
      await _getNotificationPermission();
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
        await splashController.getLocation();
      } else {
        await splashController.getCurrentLocationAddress();
      }
    } else {
      _locationSettingCalled = false;
    }
  }



  _getNotificationPermission() async {
    PermissionStatus notificationPermissionStatus = await Permission.notification.status;
    if (notificationPermissionStatus != PermissionStatus.granted &&
        notificationPermissionStatus != PermissionStatus.permanentlyDenied) {
      await Permission.notification.request();
    } else {
      return notificationPermissionStatus;
    }
  }

  setSignin() {
    setFCM();
    globals.favoriteLocationEnumList.forEach((element) {
      splashController.removeLocationDetails(selectLocationEnum: element);
    });

    if (globals.authToken != null && (globals.authToken?.isNotEmpty ?? false)) {
      globals.isLoaderShow = false;

      splashController.getProfileInfo().then((value) async {
        if (value!.isNotEmpty) {
          if (value == "timeout" || value == "offline") {
            globals.authToken = "";
            splashController.getStartedEnableController(true);
            splashController.getStartedEnableController.refresh();

            splashController.toast.show(
                context: context,
                message: 'session_timeout_err'.tr,
                duration: new Duration(seconds: 5));
            splashController.preferences.clearPreference().then((value) {
              FirebaseService.deleteFcmToken().then((value) {
                FirebaseService.getFcmToken().then((token) {
                  globals.deviceId = token ?? "";

                  PrimaryScaffold.avoidLoader.value = false;
                  globals.setButtonDisabled();
                });
              });
            });
          }
          // else if (value == "offline") {
          //   splashController.netOffSnackbar(setSignin, false);
          // }
          else {
            splashController.getStartedEnableController(true);
            splashController.getStartedEnableController.refresh();

            globals.authToken = "";
            //   splashController.showInSnackBar(value);
            splashController.preferences.clearPreference().then((value) {
              FirebaseService.deleteFcmToken().then((value) {
                FirebaseService.getFcmToken().then((token) {
                  globals.deviceId = token ?? "";

                  PrimaryScaffold.avoidLoader.value = false;
                  globals.setButtonDisabled();
                });
              });
            });
          }
        } else {
          if (globals.theme == 1) {
            if(scoffoldcontext !=null && scoffoldcontext.mounted) {
              var brightness = MediaQuery.of(scoffoldcontext).platformBrightness;
              globals.isDarkTheme = brightness == Brightness.dark;
            }
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
          AppBuilder.of(context)?.build(context);
          globals.isShowMapPage = true;
          debugPrint("splashController.isActiveBooking: ${splashController.isActiveBooking}");
          if (splashController.isActiveBooking) {
            if (!_isContactPermissionDialogOpen && _appUpdateContent.isEmpty) {
              globals.isCreatedTrip = true;
              splashController.setNavigation(AppRoutes.APP_MAP_MAIN);
            }
            globals.setButtonDisabled();
          } else {
            if (!_isContactPermissionDialogOpen && _appUpdateContent.isEmpty) {
              Get.offAllNamed(AppRoutes.APP_HOME);
            }
          }
        }
      });
    }
  }

  bool ispromopageCalled = false;
  Map<String, dynamic> map = {};

  void setFCM() async {
    String authToken =  splashController.preferences.authToken;

    await FirebaseMessaging.instance
        .requestPermission(sound: true, badge: true, alert: true)
        .then((value) {
      if (authToken != null && authToken != "") {
        FirebaseService.getFcmToken().then((token) {
          globals.deviceId = token ?? "";

          if (!(globals.fcmConfigured)) {
            FirebaseService().configureFCM();
          }
        });
      } else {
        FirebaseService.deleteFcmToken().then((value) {
          FirebaseService.getFcmToken().then((token) {
            globals.deviceId = token ?? "";

            if (!(globals.fcmConfigured)) {
              FirebaseService().configureFCM();
            }
          });
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        customAppBarFunction: () {
          splashController.closeApp();
        },
        disableAppbar: true,
        body: Column(
          children: [
            _showMainImageView(),
            _showBottomView(),
          ],
        ),
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _locationSettingCalled = true;

        break;
      case AppLifecycleState.resumed:
        {
          if (_locationSettingCalled) {
            requestPermission();
            _locationSettingCalled = false;
          }

          break;
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  Widget _showMainImageView() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          alignment: AlignmentDirectional.topCenter,
          fit: BoxFit.cover,
          child: Container(
            decoration: new BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
            ),
            child: Image.asset(
              fit: BoxFit.cover,
              loginPagePng,
            ),
          ),
        ),
      ),
    );
  }

  Widget _showBottomView() {
    String getMoveContent = "get_started_with".trParams({"field":globals.APP_NAME}) == "get_started_with"?"Get started with ${globals.APP_NAME}":"get_started_with".trParams({"field":globals.APP_NAME});
    String getStartContent = "get_started".tr == "get_started"?"Drive anywhere, anytime.": "get_started".tr;
    return Container(
      color: AppColors.PRIMARY_LIGHT_COLOR,
      padding: const EdgeInsetsDirectional.only(
          top: 20, bottom: 25, end: 20, start: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getMoveContent,
            style: new TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontWeight: FontWeight.w600,
              fontSize: AppDimen.text_size_22,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            getStartContent,
            style: new TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontSize: AppDimen.text_size_18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 25),
          Obx(() {
            return IgnorePointer(
              ignoring: _getStartedButtonCondition(
                  splashController.getStartedEnableController.value == true),
              child: Container(
                width: double.infinity,
                child: PrimaryButton(
                  buttonTitle: 'get_started'.tr,
                  buttonImage: primaryBtnArrow,
                  innerPadding: 30.0,
                  disableLoadCancel: true,
                  isLoad: globals.authToken != null &&
                      (globals.authToken?.isNotEmpty ?? false),
                  callback: () async{
                    globals.setButtonLoading();
                    try {
                      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
                        await splashController.getNativeLocation();
                        globals.setLocationController(true);
                      }
                      splashController.getCurrentLocationAddress();
                    } on Exception catch (e) {
                      debugPrint("first.exception: _getLocation: ${e}");
                    }

                    if (globals.authToken == null ||
                        (globals.authToken?.isEmpty ?? true)) {
                      splashController.setNavigation(AppRoutes.APP_PHONE_AUTH)
                          .then((_) {
                        globals.setButtonIdle();
                      });
                    } else {
                      splashController.checkInternet(getUpdatedVersion, false);
                    }
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    isCurrentPage = false;
    _buttonStateWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  getUpdatedVersion() {
    globals.closeKeyBoard = false;
    globals.isLoaderShow = false;
    App().getUpdatedVersion().then((value) {
      _appUpdateContent = value ?? "";
      if (value == "null") {
        splashController.netOffSnackbar(getUpdatedVersion, false);
      } else if (value!.isNotEmpty) {
        _showUpdateDialog();
      } else {
        splashController.isLocationServiceEnable().then((value) {
          if (!value) {
            splashController.EnableLocationService().then((value) {
              if (value) {
                Permission.location.status.then((value) {
                  if (value != PermissionStatus.granted)
                    [Permission.location].request();
                });
              }
            });
          }
        });
        splashController.checkInternet(getCurrencyRates, false);
      }
    });
  }

  _showUpdateDialog() {
    splashController.showConfirmationDialog(
        title: 'force_update'.tr,
        content: _appUpdateContent,
        isDisableCancel: true,
        onConfirm: () {
          if (Platform.isAndroid) {
            launchUrl(Uri.parse(globals.playStoreLink),
                mode: LaunchMode.externalApplication);
          } else {
            launchUrl(Uri.parse(globals.appstoreLink));
          }
        },
        confirmButtonText: 'update_'.trParams({'field2': ""}));
  }

  getCurrencyRates() {
    globals.isLoaderShow = false;
    splashController.getCurrencyRates().then((value) {
      splashController.checkInternet(getSecureSiteSettings, false);
    });
  }

  getSecureSiteSettings() {
    globals.isLoaderShow = false;
    splashController.getSecureSiteSettings().then((value) {
      if (globals.authToken != null && globals.authToken!.isNotEmpty) {
        setSignin();
      }
      if (globals.authToken == null || globals.authToken!.isEmpty)
        globals.setButtonDisabled();
    });
  }

  bool _getStartedButtonCondition(bool _isSessionTimeout) {
    return globals.authToken != null &&
        globals.authToken!.isNotEmpty &&
        !_isSessionTimeout;
  }
}