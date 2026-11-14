import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart' as intl;
import 'package:just_audio/just_audio.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/binding/auth_binding.dart';
import 'package:wooberly_driver/binding/home_binding.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/resources/values/app_styles.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/views/splash.dart';
import 'package:wooberly_driver/widgets/blinking_toast.dart';

import '../app_localizations.dart';
import '../binding/trip_binding.dart';
import '../pref/app_preference.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_lang.dart';
import 'model_theme.dart';

class App extends StatelessWidget {
  Toast toast = new Toast();
  static final App _instance = App._internal();
  final GlobalKey<NavigatorState>? navigatorKey = GlobalKey<NavigatorState>();

  final AppPreference appPreference = Get.find();
  bool _isResponseReceived = true;
  static const platformWakeLockChannel = const MethodChannel("Wakelock channel");
  MethodChannel locationChannel = MethodChannel('getLocation');
  MethodChannel tokenChannel = MethodChannel('getAuthToken');
  static const locationFetcheventChannel = const EventChannel("Background Location Fetch");
  LocalizationService localizationService = LocalizationService();

  String offlineMessageContent = 'offline_text'.tr =='offline_text' ? "You are currently offline" : 'offline_text'.tr;
  String retryContent = 'retry'.tr == 'retry'? "Retry": "retry".tr;
  App._internal() {
    availableCameras().then((value) {
      cameras = value;
    });
  }

  factory App() {
    Get.lazyPut<AppPreference>(() => AppPreference(), fenix: true);
    return _instance;
  }

  var cameras;

  @override
  Widget build(BuildContext context) {
    getAppVersion();
    return getMaterialApp(widget: SplashView(), title: "", buildContext: context);
  }

  AppRoutes getAppRoutes() {
    return AppRoutes();
  }

  void changeLanguage() {
    App().localizationService.changeLocale(languageCode: App().appPreference.preferredLanguage);
  }

  Future<Null> setBgLocationInfo_IOS(token, userid, deviceid) async {
    try {
      debugPrint("setBgLocationInfo_IOSglobals.notificationInterval: ${globals.notificationInterval}");
      if (Platform.isIOS)
        await tokenChannel.invokeMethod(
            'getAuthToken', {
              "token": globals.authToken,
              "userid": userid,
              "deviceid": deviceid,
              "declineduration": globals.notificationInterval,
           //   "tripAudioURL": globals.tripAudioURL ?? ""
            });
    } on PlatformException catch (e) {}
  }

  Future<Null> setTripInfo_IOS(riderid, bookingid) async {
    if (Platform.isAndroid) setTripInfo_Android(riderid, bookingid);
    try {
      if (Platform.isIOS)
        await tokenChannel.invokeMethod(
            'setTripInfo', {"riderid": riderid, "userid": globals.userid, "bookingid": bookingid});
    } on PlatformException catch (e) {}
  }

  Future<Null> setTripInfo_Android(riderid, bookingid) async {
    try {
      await locationChannel.invokeMethod(
          'setTripInfo', {"riderid": riderid, "deviceId": globals.deviceId, "bookingid": bookingid});
    } on PlatformException catch (e) {}
  }

  ChangeNotifierProvider<ModelTheme> getMaterialApp(
      {required Widget widget, required String title, required BuildContext buildContext}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return ChangeNotifierProvider(
      create: (_) => ModelTheme(),
      child: Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        globals.themeNotifier = themeNotifier;
        return GetMaterialApp(
          initialBinding: AuthBinding(),
          translations: localizationService,
          locale: globals.preferredLanguage != null && globals.preferredLanguage.isNotEmpty
              ? Locale(globals.preferredLanguage.value)
              : Locale(globals.defaultLanguageCode),
          fallbackLocale: const Locale('en'),
          title: title,
          debugShowCheckedModeBanner: false,
          home: widget,
          theme: AppStyles.lightTheme(),
          darkTheme: AppStyles.darkTheme(),
          themeMode: globals.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: getAppRoutes().getRoutes,
        );
      }),
    );
  }

  void movetoInitialPage(String routeName) {
    Get.offAll(App().getAppRoutes().getWidget(routeName), predicate: (Route<dynamic> route) => false);
  }

  Future<bool> checkConnectivity() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<bool> checkInternet(BuildContext context, Function verify, bool? toastShow) async {
    bool internetConnect = await checkConnectivity();

    if (internetConnect != null && internetConnect) {
      verify();
    } else {
      if (toastShow == null) {
      } else if (toastShow) {
        toast.show(
          context: context,
          message: offlineMessageContent,
        );
      } else {
        netOffSnackbar(context, verify, toastShow);
      }
    }
    return Future.value(internetConnect);
  }

  void netOffSnackbar(BuildContext context, Function verify, bool toastShow) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
          new SnackBar(
            content: new Text(
              offlineMessageContent,
            ),
            backgroundColor: AppColors.PRIMARY_COLOR_DARK,
            action: SnackBarAction(
              label: retryContent,
              textColor: AppColors.PRIMARY_COLOR_WHITE,
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                checkInternet(context, verify, toastShow);
              },
            ),
            duration: Duration(hours: 1),
          ),
        )
        .closed
        .then((reason) {});
  }

  Future<dynamic> setNavigation(String app_route_name, {bool isEnableShowingPage = true}) {
    Bindings bindings;
    if (app_route_name == AppRoutes.APP_PAYOUT_ACCOUNT ||
        app_route_name == AppRoutes.APP_PAYOUT_DISPLAY ||
        app_route_name == AppRoutes.APP_PAYOUT_ADDRESS)
      bindings = TripBinding();
    else
      bindings = HomeBinding();
    if (isEnableShowingPage) {
      globals.currentShowingPage = app_route_name;
    }
    svg.cache.clear();
    return Future.delayed(Duration(milliseconds: 100), () async {
      await Get.to(App().getAppRoutes().getWidget(app_route_name),
          transition: Transition.rightToLeft, binding: bindings);
    });
  }

  void setBackNavigation([bool closeOverlays = false]) {
    Get.back(closeOverlays: closeOverlays);
  }

  void closeApp() {
    exit(0);
  }

  Future<String> userLogout() async {
    var variables = <String, dynamic>{"deviceType": globals.deviceName, "deviceId": globals.deviceId};
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);

    graphQlObject.getGraphQlClientWithHeader();

    Map<String, dynamic>? _logout_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader, "user_logout", variables);

    if (_logout_result != null) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      if (_logout_result["userLogout"]["status"] == 200) {
        graphQlObject.graphQLClientWithHeader.cache.store.reset();
        graphQlObject.graphQLClient.cache.store.reset();

        return "";
      } else {
        return _logout_result["userLogout"]["errorMessage"];
      }
    } else {
      return "offline";
    }
  }



  static Future<void> changeWakeLock(String lockStatus) async {
    await platformWakeLockChannel.invokeMethod("Wakelock channel", {"lockStatus": lockStatus});
  }

  Future<String> getNativeLocation([String provider = ""]) async {
    try {
      final point = StackTrace.current.toString().split('\n')[1];
      print('test9_getNativeLocation ${point} --- ');
      String location = await locationChannel.invokeMethod('getLocation', {"provider": provider});
      globals.userLat = double.parse(location.split('///')[0]);
      globals.userLon = double.parse(location.split('///')[1]);
      return location;
    } on PlatformException catch (e) {
      return "";
    }
  }

  getAppVersion() async {
    try {
      globals.versionCode = await locationChannel.invokeMethod('appversion');
    } on PlatformException catch (e) {
      return "";
    }
  }
  Future<bool> isiOSAppInBackground() async {
    try {
      return await locationChannel.invokeMethod('isiOSAppInBackground');
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<String> getDrawOverAppsPermission() async {
    try {
      await locationChannel.invokeMethod('drawoverapp');
    } on PlatformException catch (e) {}
    return "";
  }

  Future<bool> setMapKey() async {
    try {
      bool location = await locationChannel.invokeMethod('setMapKey', {"key": globals.MAP_KEY});
      return location;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnable() async {
    try {
      bool location = await locationChannel.invokeMethod('CheckLocationService');

      return location;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<bool> EnableLocationService() async {
    debugPrint("getNativeLocation called --- EnableLocationService");
    try {
      if (_isResponseReceived) {
        _isResponseReceived = false;
        bool location = await locationChannel.invokeMethod('EnableLocationService');
        _isResponseReceived = true;
        return location;
      } else
        return false;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<String> getSecurityKey() async {
    try {
      String secretKey = await locationChannel.invokeMethod('securityKey');
      return secretKey;
    } on PlatformException catch (e) {
      return "";
    }
  }

  Future<bool> changeMode() async {
    try {
      bool location = await locationChannel
          .invokeMethod('changeThemeMode', {"isDarkMode": globals.isDarkTheme.toString()});
      return location;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await locationChannel.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open location settings: ${e.message}');
    }
  }

  void removeUserCache(BuildContext context) {
    changeWakeLock("0");

    globals.authToken = "";
    globals.deviceId = "";
    appPreference.clearPreference();

    globals.phnNo = "";
    globals.payout = 0;
    globals.isPayout = false;
    globals.uploadedImage = null;
    globals.email = "";
    globals.firstname = "";
    globals.lastname = "";
    globals.picture = "";

    try {
      globals.socket?.clearListeners();
      globals.socket?.disconnect();
      globals.socket?.dispose();
    } catch (_) {}
    globals.socket = null;
    globals.tripInfo = "";
    globals.tripFromSocket = false;
    globals.userid = "";

    globals.front = "";
    globals.back = "";
    globals.RC = "";
    globals.Insurance = "";
    globals.audioPlayer = null;

    appPreference.preferredLanguage = globals.preferredLanguage.value;
    globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
    App().changeLanguage();

    try {
      movetoInitialPage(AppRoutes.APP_SPLASH);
    } on Exception catch (_) {
      setNavigation(AppRoutes.APP_SPLASH);
    }
  }

  void getAudioPlayerCache() {
    try {
      if (globals.audioPlayer == null) {
        globals.audioPlayer = AudioPlayer();
      }

      if (globals.tripAudioURL != null &&
          globals.tripAudioURL != "" &&
          !globals.tripAudioURL.contains("null")) {
        globals.audioPlayer?.setUrl(globals.tripAudioURL);
      } else {
        globals.audioPlayer?.setAsset('assets/ride_request.mp3');
      }
    } catch (e) {
      globals.audioPlayer?.setAsset('assets/ride_request.mp3');
    }
  }

  Future<void> initSocket() async {
    if (globals.socket != null && (globals.socket?.connected ?? false)) return;
    if (globals.socket != null) {
      reconnectSocket();
      return;
    }

    try {
      globals.socket = io(
        globals.SOCKET_URL,
        OptionBuilder()
            .setTransports(['websocket']) // Use websocket transport
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(double.infinity) // Reconnect indefinitely
            .setReconnectionDelay(1000) // Initial delay: 1 second
            .setReconnectionDelayMax(5000) // Maximum retry delay: 5 seconds
            .setRandomizationFactor(0.5) // Jitter to prevent server hammering
            .setTimeout(20000) // Connection timeout: 20 seconds
            .build(),
      );

      // Connection lifecycle listeners
      globals.socket?.onConnect((_) {
        debugPrint("Socket connected: ${globals.socket?.id}");
      });
      globals.socket?.onDisconnect((reason) {
        debugPrint("Socket disconnected. Reason: $reason");
      });
      globals.socket?.onConnectError((err) {
        debugPrint("Socket connect error: $err");
      });
      globals.socket?.onReconnect((attempt) {
        if (Get.isRegistered<MapMainController>()) {
          try {
            MapMainController controller = Get.find();
            String tripStatus = controller.tripStatus;
            controller.getTripStatusOnly().then((onValue) {
              debugPrint("controller.tripStatus: ${controller.tripStatus} -- ${tripStatus}");
              if (tripStatus != controller.tripStatus) {
                if (controller.homeViewState.socketConnectionOnMapMainScreen != null) {
                  controller.checkInternet(controller.homeViewState.socketConnectionOnMapMainScreen!.getTripStatus, null);
                }
              }
            });
          } catch (e) {
            debugPrint("onReconnect MapMainController error: $e");
          }
        }
        debugPrint("Socket reconnected successfully after $attempt attempts");
      });
      globals.socket?.onReconnectAttempt((attempt) {
        debugPrint("Socket reconnection attempt #$attempt");
      });
      globals.socket?.onReconnectError((err) {
        debugPrint("Socket reconnect error: $err");
      });
      globals.socket?.onReconnectFailed((_) {
        debugPrint("Socket reconnect failed");
      });
      globals.socket?.onError((err) {
        debugPrint("Socket error: $err");
      });
      globals.socket?.connect();
    } catch (e) {
      debugPrint("Socket init exception: $e");
    }
  }

  void reconnectSocket() {
    try {
      if (globals.socket == null) {
        initSocket();
      } else if (!(globals.socket?.connected ?? false)) {
        debugPrint("Forcing socket reconnect...");
        globals.socket?.disconnect();
        globals.socket?.connect();
      }
    } catch (e) {
      debugPrint("Socket reconnect error: $e");
    }
  }

  void stopRequestAudio() {
    globals.audioPlayer?.pause();
  }

  Future<LatLng> findPlaces(dynamic placeId, String sessionId) async {
    String secureKey = await getSecurityKey();
    var url = globals.placeSearchUrl;
    Map<String, String>? headers;
    var body;
    if (globals.authToken != null) {
      headers = {"Content-Type": "application/json", "auth": globals.authToken ?? ""};
      body = {"placeId": placeId, "platformSecretKey": secureKey, "sessionToken": sessionId};
    } else {
      headers = {
        "Content-Type": "application/json",
      };
      body = {"placeId": placeId, "platformSecretKey": secureKey,"sessionToken": sessionId};
    }

    final response = await http.post(Uri.parse(url), headers: headers, body: convert.jsonEncode(body));
    var json = convert.jsonDecode(response.body);
    if (json["response"]["location"] != null) {
      final lat = json["response"]["location"]["latitude"];
      final lng = json["response"]["location"]["longitude"];
      return LatLng(lat, lng);
    } else if (json['errorMessage'] != null && json['errorMessage'].isNotEmpty) {
      App().toast.show(context: Get.context!, message: json['errorMessage']);
      return LatLng(0.0, 0.0);
    } else if (json['errorMessage']['error']['message'] != null &&
        json['errorMessage']['error']['message'].isNotEmpty) {
      App().toast.show(
            message: json['errorMessage']['error']['message'],
            context: Get.context!,
          );
      return LatLng(0.0, 0.0);
    }
    return LatLng(0.0, 0.0);
  }

  String getPaymentName(int paymentId) {
    Map<int, String> paymentMethods = {
      1: "cash".tr,
      2: "stripe".tr,
      3: "wallet".tr,
      4: "googlepay".tr,
      5: "paystack".tr,
      6: "PayPal".tr
    };
    return paymentMethods[paymentId] ?? "";
  }

  Future<void> initializeCamera({int? cameraId}) async {
    globals.cameraController =
        CameraController(cameras[cameraId ?? 0], ResolutionPreset.medium, enableAudio: false);
    await globals.cameraController?.initialize();
    await globals.cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }
}