import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/controllers/splash_controller.dart';
import 'package:app_name/widgets/app_builder.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

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

class SplashState extends State<SplashView> with SingleTickerProviderStateMixin {

  SplashController controller = Get.find();
  late List<Permission> permissionGroup;
  late AssetImage _assetImage;

  late VideoPlayerController _videoPlayerController;
  RxBool isVideoInitialize = false.obs;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    try {
      if (_videoPlayerController.value.isInitialized) {
        _videoPlayerController.pause();
      }
    } catch (_) {}
    controller.setNavigation(AppRoutes.APP_ROUTE_LOGIN);
  }

  handleTimeout() async {
    debugPrint("controller.preferences.preferredLaunguage: ${controller.preferences.preferredLaunguage}, ${controller.preferences.authToken}");
    if (controller.preferences.preferredLaunguage.isNotEmpty) {
      globals.preferredLanguage = controller.preferences.preferredLaunguage;
      globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
      Get.updateLocale(Locale(globals.preferredLanguage));
    }
    globals.downloadedLanguages =   controller.preferences.preferredLaunguage.split(",").toSet();

      globals.authToken = controller.preferences.authToken;
      if (globals.authToken == null || globals.authToken == "") {
        fetchSystemTheme();
      } else {
        Future.delayed(const Duration(milliseconds: 350), () {
          var brightness = MediaQuery.of(Get.context!).platformBrightness;
          globals.isDarkTheme = brightness == Brightness.dark;
          if (globals.isDarkTheme) {
            AppColors().changeToDark();
          } else {
            AppColors().changeToLight();
          }
          globals.themeNotifier?.isDark = globals.isDarkTheme;
        });
      }
      graphQlObject.getGraphQlClientWithHeader();
  }

  @override
  void initState() {
    super.initState();
    _assetImage = AssetImage(splashPng);
    permissionGroup = [Permission.location];
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      _navigateToLogin();
    });
    checkVideoSize();
    _videoPlayerController = VideoPlayerController.asset('assets/video.mp4');
    _videoPlayerController.setVolume(0.0);
    AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    bool isResumeState = state == AppLifecycleState.resumed || Platform.isIOS;
    if(isResumeState) {
      _videoPlayerController.addListener(_onVideoControllerUpdate);
      _videoPlayerController.initialize().then((value) {
        if (!mounted) return;
        isVideoInitialize.value = true;
        _videoPlayerController.play();
        final videoDuration = _videoPlayerController.value.duration;
        if (videoDuration > Duration.zero) {
          Future.delayed(videoDuration + const Duration(milliseconds: 300), () {
            _navigateToLogin();
          });
        } else {
          Future.delayed(const Duration(milliseconds: 2500), () {
            _navigateToLogin();
          });
        }
      }).catchError((error) {
        debugPrint("Video player initialization error: $error");
        controller.showFrozenImage.value = true;
        Future.delayed(const Duration(milliseconds: 1500), () {
          _navigateToLogin();
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 3000), () {
        _navigateToLogin();
      });
    }


    graphQlObject.loadGraphQLJson("login_graphql");
    requestPermission();
    controller.getSecureSiteSettings();
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (globals.theme == 1) {
        globals.isDarkTheme = brightness == Brightness.dark;
        if (globals.isDarkTheme) {
          AppColors().changeToDark();
          globals.themeNotifier?.isDark = globals.isDarkTheme;
        } else {
          AppColors().changeToLight();
          globals.themeNotifier?.isDark = globals.isDarkTheme;
        }
      }
    };
    AppLifecycleListener(onResume: () {
      try {
        if (!_videoPlayerController.value.isCompleted) {
          _videoPlayerController.play();
        } else {
          _videoPlayerController.seekTo(_videoPlayerController.value.position);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }, onPause: () {
      try {
        if (!_videoPlayerController.value.isCompleted) {
          _videoPlayerController.pause().then((value) {
            _videoPlayerController.seekTo(Duration.zero);
          });
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  Future<void> checkVideoSize() async {
    try {
      await rootBundle.load('assets/video.mp4');
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _navigateToLogin();
      });
    }
  }

  void _onVideoControllerUpdate() {
    final value = _videoPlayerController.value;

    if (!value.isInitialized) return;

    if (value.hasError) {
      debugPrint("Video player hasError during playback: ${value.errorDescription}");
      controller.showFrozenImage.value = true;
      _navigateToLogin();
      return;
    }

    final reachedEnd = value.isCompleted ||
        (value.duration > Duration.zero && value.position >= value.duration);

    if (reachedEnd ) {
       controller.checkConnectivity().then((value){
         if(!value){
           controller.showFrozenImage.value = true;
         } else {
           controller.showFrozenImage.value = false;
         }
       });
       _navigateToLogin();
    }
  }


  void didChangeDependencies() {
    precacheImage(_assetImage, context);
    super.didChangeDependencies();
  }

  void fetchSystemTheme() {
    Brightness brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    globals.isDarkTheme = (brightness == Brightness.dark);
    globals.theme = 1;
    if (globals.isDarkTheme) {
      AppColors().changeToDark();
    } else {
      AppColors().changeToLight();
    }
    globals.themeNotifier?.isDark = globals.isDarkTheme;
    AppBuilder.of(context)?.build(context);
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        controller.closeApp();
      },
      customAppBarContent: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: const SizedBox.shrink(),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: AppColors.PRIMARY_LIGHT_COLOR,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Image(image: AssetImage(splashPng)),
              ),
            ),
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Obx(
                  () {
                   if( controller.showFrozenImage.value)
                     return Image(image: AssetImage(splashPng));

                    return SizedBox(
                    width: _videoPlayerController.value.size.width,
                    height: _videoPlayerController.value.size.height,
                    child: isVideoInitialize.value
                        ? VideoPlayer(_videoPlayerController)
                        : Image(image: AssetImage(splashPng)),
                  );}
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 160.0),
              child: Image(
                width: 250,
                height: 250,
                image: AssetImage(riderLogoPng),
              ),
            ),
            const SizedBox(
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

  Future<void> requestPermission() async {
    try {
      Future.delayed(const Duration(milliseconds: 350), () {
        handleTimeout();
      });
      _getLoc();
    } on Exception catch (e) {
      debugPrint("Exception in request Permssio $e");
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    try {
      if (_videoPlayerController.value.isInitialized) {
        _videoPlayerController.pause();
      }
      _videoPlayerController.dispose();
    } catch (e) {
      debugPrint("Error disposing video controller: $e");
    }
    super.dispose();
  }

  Future<void> _getLoc() async {
    try {
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
        await controller.getNativeLocation();
        globals.setLocationController(true);
      }
      controller.getCurrentLocationAddress();
    } on Exception catch (e) {
      debugPrint("first.exception: _getLocation: ${e}");
    }
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