import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app_lifecycle_handler.dart';
import 'package:app_name/bindings/auth_binding.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_styles.dart';
import 'package:app_name/translations.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/splash.dart';
import 'package:app_name/widgets/blinking_toast.dart';

import '../graphql/graphql_config.dart';
import '../utils/globals.dart';
import 'model_theme.dart';

class App extends StatelessWidget {
  final Toast toast = new Toast();

  AppTranslations translations = Get.find();
  BaseController baseController=Get.put(BaseController());
  var cameras;

  App._internal() {
    baseController.getAppVersion();
    availableCameras().then((value) {
      cameras = value;
    });

  }

  static final App _instance = App._internal();

  factory App() {
    Get.lazyPut(()=>AppTranslations(), fenix: true);
    Get.lazyPut(()=>AppPreferences(), fenix: true);
    return _instance;
  }

  @override
  Widget build(BuildContext context) {
    svg.cache.clear();
    return MyAppLifecycleHandler(
      child: getMaterialApp(
            widget: SplashView(), title: "", buildContext: context)
    );
  }
  ChangeNotifierProvider<ModelTheme> getMaterialApp(
      {required Widget widget, required String title, required BuildContext buildContext}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return ChangeNotifierProvider(
      create: (_) => ModelTheme(),
      child: Consumer<ModelTheme>(
          builder: (context, ModelTheme themeNotifier, child) {
        globals.themeNotifier = themeNotifier;
        return GetMaterialApp(
          initialBinding: AuthBinding(),
          translations: AppTranslations(),
          locale: globals.preferredLanguage != null &&
                  globals.preferredLanguage.isNotEmpty
              ? Locale(globals.preferredLanguage)
              : Locale(defaultLanguageCode),
          fallbackLocale: const Locale('en'),
          title: title,
          debugShowCheckedModeBanner: false,
          home: widget,
          theme: AppStyles.lightTheme(),
          darkTheme: AppStyles.darkThemeNew(),
          themeMode:
              globals.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: AppRoutes().getRoutes,
        );
      }),
    );
  }
  Future<String?> getUpdatedVersion() async {
    if (graphQlObject.graphQLClient != null) {
      var variables = <String, dynamic>{
        "osType": Platform.isIOS ? "ios": 'android' ,
        "appType": 1,
        "version": globals.versionCode,
        "requestLang": globals.preferredLanguage,
      };
      try {
        Map<String, dynamic>? _updated_version =
        await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
            "getApplicationVersionInfo_query", variables);
        if (_updated_version != null) {
          globals.appstoreLink = _updated_version["getApplicationVersionInfo"]
          ["result"]["appStoreURL"]["user"];
          globals.playStoreLink = _updated_version["getApplicationVersionInfo"]
          ["result"]["playStoreURL"]["user"];
          if (_updated_version["getApplicationVersionInfo"]["status"] == 400) {
            return _updated_version["getApplicationVersionInfo"]
            ["errorMessage"];
          } else {
            return "";
          }
        } else {
          return "null";
        }
      } on Exception catch (e) {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          getUpdatedVersion();
        });
      }
    } else {}
  }

  void setBackNavigation(BuildContext context) {
    svg.cache.clear();
    imageCache.clear();
    Navigator.pop(context);
  }


  Widget getProgressIndicator() {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
          child: Lottie.asset(
            globals.isDarkTheme
                ? 'assets/lottieloader_dark.json'
                : 'assets/lottieloader.json',
          ),
        ),
      ),
    );
  }
  Future<dynamic> showBottomSheet(Widget widget,[Color? color,bool isScrolled=false]){
    return Get.bottomSheet(isScrollControlled: isScrolled,
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return SafeArea(
              bottom: Platform.isAndroid,
              child: ColoredBox(
                color: color??AppColors.PRIMARY_LIGHT_COLOR,
                  child: widget),
            );
          }
        ),);
}

  setLocationDetails({required SelectLocationModel selectLocationModel,required SelectLocationEnum selectLocationEnum}){
    globals.favoriteLocationMap[selectLocationEnum] = selectLocationModel;
  }
  LatLng? getLatLngFromLocationModel({required SelectLocationEnum selectLocationEnum}){
    if( globals.favoriteLocationMap.containsKey(selectLocationEnum))
      return LatLng( globals.favoriteLocationMap[selectLocationEnum]!.lat, globals.favoriteLocationMap[selectLocationEnum]!.lng);
    return null;
  }
}

extension StringOperation on String {
    toRemoveCommaString() {
      if (this[0].contains(',')) {
        return this.replaceRange(0, 1, '');
      }
      return this;
  }
}