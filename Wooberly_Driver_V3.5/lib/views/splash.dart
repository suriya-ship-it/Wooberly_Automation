import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:video_player/video_player.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/splash_controller.dart';
import 'package:wooberly_driver/controller/base_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import '../resources/values/app_images.dart';

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SplashView();
  }
}

class SplashView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SplashState();
}

class SplashState extends State<SplashView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SplashController _controller = Get.find();

  final rxIsVideoInitialize = ReactiveVariable("rxIsVideoInitialize", false);
  VideoPlayerController? _videoPlayerController;
  late AssetImage _assetImage;
  static const MethodChannel _splashChannel = MethodChannel('splash_screen');

  @override
  void initState() {
    super.initState();
    _notifyAndroidSplashReady();
    checkVideoSize();
    _startVideoInBackground();

    _assetImage = AssetImage(splashPng);
    _initializeAuthToken();
    globals.preferredLanguage.value = App().appPreference.preferredLanguage;
    globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
    initSocket();
    _controller.getDeviceDetails();

    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (globals.theme.value == 1) {
        globals.isDarkTheme = brightness == Brightness.dark;
        App().appPreference.preferredTheme = globals.isDarkTheme;
        if (globals.isDarkTheme) {
          AppColors().changeToDark();
          globals.themeNotifier?.isDark = globals.isDarkTheme;
          globals.isAutoThemeUpdated.value = !globals.isAutoThemeUpdated.value;
        } else {
          AppColors().changeToLight();
          globals.themeNotifier?.isDark = globals.isDarkTheme;
          globals.isAutoThemeUpdated.value = !globals.isAutoThemeUpdated.value;
        }
        globals.isAutoThemeUpdated.refresh();
      }
    };
    AppLifecycleListener(onResume: () {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _videoPlayerController?.play();
      }
    }, onPause: () {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _videoPlayerController?.pause().then((value) {
          _videoPlayerController?.seekTo(Duration.zero);
        });
      }
    });
    _controller.getPaymentSettings();
  }

  void _startVideoInBackground() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoPlayerController = VideoPlayerController.asset('assets/video.mp4');
      AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
      bool isResumeState = state == AppLifecycleState.resumed || Platform.isIOS;
      debugPrint("_startVideoInBackground: init ${state}");
      if(isResumeState) {
        _videoPlayerController?.initialize().then((value) {
          AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
          debugPrint("_startVideoInBackground: ${state}");
          bool isResumeState = state == AppLifecycleState.resumed || Platform.isIOS;
          if (isResumeState) {
            _videoPlayerController?.play();
          }
          globals.baseController.change(
              rxVariable: rxIsVideoInitialize, value: true);

          if (_videoPlayerController?.value.duration != null) {
            Future.delayed(
                _videoPlayerController!.value.duration)
                .then((_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                App().setNavigation(AppRoutes.APP_ROUTE_LOGIN);
              });
            });
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 6500), () {
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
          App().setNavigation(AppRoutes.APP_ROUTE_LOGIN);
        });
      }
    });
  }


  void _notifyAndroidSplashReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _splashChannel.invokeMethod('ready');
      } catch (_) {}
    });
  }

  Future<void> checkVideoSize() async {
    try {
      await rootBundle.load('assets/video.mp4');
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 6500), () {
        App().setNavigation(AppRoutes.APP_ROUTE_LOGIN);
      });
    }
  }

  void didChangeDependencies() {
    precacheImage(_assetImage, context);
    super.didChangeDependencies();
  }

  void fetchSystemTheme() {
    globals.isDarkTheme = Get.isPlatformDarkMode;
    globals.theme.value = 1;
    App().appPreference.preferredTheme = globals.isDarkTheme;
    if (globals.isDarkTheme) {
      AppColors().changeToDark();
    } else {
      AppColors().changeToLight();
    }
    globals.themeNotifier?.isDark = globals.isDarkTheme;
  }

  /// Initializes the auth token from Flutter Secure Storage asynchronously
  /// This ensures the token is properly loaded before navigation decisions are made
  Future<void> _initializeAuthToken() async {
    // Initialize the cache from secure storage - this awaits the actual values

    // Now get the auth token from the initialized cache
    globals.authToken = App().appPreference.authToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globals.authToken == null || globals.authToken == "") {
        fetchSystemTheme();
      } else {
        globals.isDarkTheme = App().appPreference.preferredTheme;
        App().appPreference.preferredTheme = globals.isDarkTheme;
        if (globals.isDarkTheme) {
          AppColors().changeToDark();
        } else {
          AppColors().changeToLight();
        }
        globals.themeNotifier?.isDark = globals.isDarkTheme;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        App().closeApp();
      },
      customAppBarContent: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: const SizedBox.shrink(),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Image(
                  image: _assetImage,
                ),
              ),
            ),
            GetBuilder(
                init: globals.baseController,
                id: rxIsVideoInitialize.id,
                builder: (val) {
                  return SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoPlayerController?.value.size?.width ?? 0,
                        height: _videoPlayerController?.value.size?.height ?? 0,
                        child: rxIsVideoInitialize.value && _videoPlayerController != null
                            ? VideoPlayer(_videoPlayerController!)
                            : Image(image: _assetImage),
                      ),
                    ),
                  );
                }
            ),
            SafeAssetImage(
              assetPath: splashNamePng,
              assetWidget: Padding(
                padding: const EdgeInsets.only(bottom: 160.0),
                child: Image(
                  width: 250,
                  height: 250,
                  image: AssetImage(driverLogoPng),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),

            SafeAssetImage(
              assetPath: splashNamePng,
              assetWidget: Align(
                alignment: Alignment.bottomCenter,
                child: Image(
                  width: 150,
                  height: 150,
                  image: AssetImage(splashNamePng),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }


  initSocket() async {
    App().initSocket();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}

class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final Widget assetWidget;

  const SafeAssetImage({super.key, required this.assetPath, required this.assetWidget});

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
          return assetWidget;
        }
        return const SizedBox.shrink();
      },
    );
  }
}