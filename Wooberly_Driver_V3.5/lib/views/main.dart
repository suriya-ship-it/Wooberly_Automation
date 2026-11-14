import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/splash_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:firebase_core/firebase_core.dart';

import '../app/model_theme.dart';
import '../graphql/graphql_config.dart';
import '../main.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../utils/socket_connection.dart';

import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  globals.tripInfo = json.decode(message.data['content']);
}

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
  int mainFlexSize = 70;

  final SplashController _controller = Get.find();
  late Map<String, dynamic> map;
  String _isNeedtoUpdate = "";
  int _prebookingID = 0;
  late List<Permission> permissionGroup;
  SocketConnection socketConnection = SocketConnection();
  var _notificationPlatform;
  static bool fcmConfigured = false;
  static StreamSubscription<RemoteMessage>? _onMessageSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  static StreamSubscription<String>? _onTokenRefreshSubscription;

  @override
  void initState() {
    globals.authToken = App().appPreference.authToken;
    globals.downloadedLanguages = App().appPreference.downloadedLanguages.split(",").toSet();
    var _androidnotificationsetting = new AndroidNotificationDetails(
      'driver id',
      "driver channel",
      channelDescription: "driver description",
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Colors.black,
      styleInformation: BigTextStyleInformation(''),
    );

    var _iOSnotificationsettings = new DarwinNotificationDetails();
    _notificationPlatform = new NotificationDetails(
        android: _androidnotificationsetting, iOS: _iOSnotificationsettings);

    permissionGroup = [
      Permission.location,
      Permission.storage,
      Permission.notification
    ];
    _controller.checkLocationPermission();
    PrimaryScaffold.avoidLoader = true;

    try {
      Future.delayed(const Duration(milliseconds: 5), () {
        setFCM();
      });
    } on Exception catch (e) {
      debugPrint("delete token exception-->>  $e");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
      if (globals.authToken != null && (globals.authToken?.isNotEmpty ?? false)) {
        handleTimeout();
      }
    });

    globals.navigateToTripsPast = false;
    super.initState();
  }

  void handleTimeout() async {
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    _controller.getUpdatedVersion().then((value) {
      _isNeedtoUpdate = value!;
      _controller.appVersionUpdateContoller.value = true;
      if (value == "offline") {
        _controller.netOffSnackbar(handleTimeout, false);
      }
      else if (value.isNotEmpty) {
        _showUpdateDialog();
      }
      else {
        if (globals.authToken?.isEmpty ?? true) {
          App().setNavigation(AppRoutes.APP_PHONE_AUTH);
          PrimaryScaffold.avoidLoader = false;
        } else {
          _controller.getDeviceDetails();

          Future.delayed(const Duration(milliseconds: 500), () {
            FirebaseMessaging.instance.getToken().then((token) async {
              globals.deviceId = token ?? "";
            });
            _controller.getProfileInfo().then((onValue) {
              if (onValue.isNotEmpty) {
                if (onValue == "timeout" || onValue == "offline") {
                  globals.authToken = "";
                  App().toast.show(
                    context: context,
                    message:
                    session_timeout_err.tr,
                  );
                  App().appPreference.clearPreference().then((value) {
                    globals.deviceId = "";
                    App().setBgLocationInfo_IOS("", "", "");
                    PrimaryScaffold.avoidLoader = false;
                    if (ModalRoute.of(context)?.isCurrent ?? false)
                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
                  });
                }
                else {
                  globals.authToken = "";
                  _controller.showInSnackBar(onValue);
                  App().appPreference.clearPreference().then((value) {
                    // Same as above — skip deleteToken() on iOS.
                    globals.deviceId = "";
                    App().setBgLocationInfo_IOS("", "", "");
                    PrimaryScaffold.avoidLoader = false;
                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 2);
                  });
                }
              }
              else {
                if (globals.theme.value == 1) {
                  var brightness = MediaQuery.of(Get.context!).platformBrightness;
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

                debugPrint("globals.isVehicleDetailsReq: splash ${globals.isVehicleDetailsReq}");
                if (!globals.isVehicleDetailsReq) {
                  if (globals.front != null &&
                      globals.back != null &&
                      globals.RC != null &&
                      globals.Insurance != null &&
                      globals.front.isNotEmpty &&
                      globals.back.isNotEmpty &&
                      globals.RC.isNotEmpty &&
                      globals.Insurance.isNotEmpty) {

                    if(App().appPreference.LicenceFront.isEmpty) {
                      setbytecode(globals.front, "front");
                    }

                    if(App().appPreference.LicenceBack.isEmpty) {
                      setbytecode(globals.back, "back");
                    }

                    if(App().appPreference.vehicleRC.isEmpty) {
                      setbytecode(globals.RC, "RC");
                    }

                    if(App().appPreference.vehicleInsurance.isEmpty) {
                      setbytecode(globals.Insurance, "Insurance");
                    }
                    globals.isShowMapPage = true;
                    _controller.appVersionUpdateContoller.stream.listen((data) {
                      if (_isNeedtoUpdate.isEmpty) {
                        PrimaryScaffold.avoidLoader = false;
                        App().setMapKey();

                        App().setNavigation(AppRoutes.APP_MAP_MAIN);
                      }
                    });
                    if (_isNeedtoUpdate.isEmpty) {
                      _controller.appVersionUpdateContoller.value = true;
                      _controller.appVersionUpdateContoller.refresh();
                    }
                  } else {
                    if (globals.front != null && globals.front.isNotEmpty)
                      setbytecode(globals.front, "front");
                    if (globals.back != null && globals.back.isNotEmpty)
                      setbytecode(globals.back, "back");
                    if (globals.RC != null && globals.RC.isNotEmpty)
                      setbytecode(globals.RC, "RC");
                    if (globals.Insurance != null && globals.Insurance.isNotEmpty)
                      setbytecode(globals.Insurance, "Insurance");

                    _controller.appVersionUpdateContoller.stream.listen((data) {
                      if (_isNeedtoUpdate.isEmpty) {
                        PrimaryScaffold.avoidLoader = false;
                        App().setNavigation(AppRoutes.APP_DOCUMENT_MAIN);
                      }
                    });

                    if (_isNeedtoUpdate.isEmpty ) {
                      if( _controller.appVersionUpdateContoller.value == true)
                        _controller.appVersionUpdateContoller.refresh();
                      else
                        _controller.appVersionUpdateContoller.value = true;

                    }
                  }
                }
                else {
                  PrimaryScaffold.avoidLoader = false;
                  App().setNavigation(AppRoutes.APP_ROUTE_DETAILS);
                }
              }
            });
          });
        }
      }
    });
    await Future.delayed(Duration(seconds: 1));
    globals.userid = App().appPreference.userId;
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

  void setFCM() async {
    String authToken = App().appPreference.authToken;

    if (authToken == null || authToken == "") {
      debugPrint("setFCM fcmConfigured: ${fcmConfigured}");
      if (!fcmConfigured) {
        configureFCM();
      } else {
        graphQlObject.loadGraphQLJson("login_graphql").then((value) {
          globals.closeKeyboard = false;
        });
      }
    } else {
      await FirebaseMessaging.instance
          .requestPermission(sound: true, badge: true, alert: true)
          .then((value) async {
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            globals.deviceId = token;
          }
        } catch (e) {
          debugPrint("setFCM getToken error: $e");
        }

        debugPrint("fcmConfigured: ${fcmConfigured}");
        if (!fcmConfigured) {
          configureFCM();
        } else {
          graphQlObject.loadGraphQLJson("login_graphql").then((value) {
            globals.closeKeyboard = false;
          });
        }
      });
    }
  }

  configureFCM() async {
    fcmConfigured = true;
    var android = new AndroidInitializationSettings('mipmap/ic_launcher');
    var ios = new DarwinInitializationSettings();
    var platform = new InitializationSettings(android: android, iOS: ios);

    var details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    await Firebase.initializeApp();
    if (details!.didNotificationLaunchApp) {
      onSelectNotification(details.notificationResponse!);
    }
    flutterLocalNotificationsPlugin.initialize(settings: platform, onDidReceiveNotificationResponse: (notificationResponse) {
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        onSelectNotification(notificationResponse);
      });
    });


    debugPrint("configureFCM called : ${globals.deviceId}");
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await _onTokenRefreshSubscription?.cancel();
    _onTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint("main onTokenRefresh: $token");
      globals.deviceId = token;
    });

    await _onMessageSubscription?.cancel();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (globals.authToken?.isEmpty ?? true) {
        return;
      }
      map = json.decode(message.data['content']);
      if (Platform.isIOS) {
        showIOSNotification(map, message.data);
      }
      debugPrint("_onMessageSubscription: ${map}");
      if (Platform.isAndroid) {
        if (_prebookingID != map["bookingId"] ||
            map['tripStatus'] != "created") {
          globals.requestTime = map['requestTime'];
          if (message.notification?.title != null &&
              message.notification?.title != "null") {
            if (map.containsKey("unReadDriverCount")) {
              if (globals.currentShowingPage != AppRoutes.APP_CHAT) {
                showNotification(message.notification!.title!,
                    message.notification!.body!, map);
              }
            } else {
              showNotification(message.notification!.title!,
                  message.notification!.body!, map);
            }

            if (!globals.isShowMapPage &&
                map['tripStatus'] != null &&
                map['tripStatus'].toString().isNotEmpty) {
              _showItemDialog(
                  message.notification!.title!, message.notification!.body!);
            }
          } else {

            if (map.containsKey("unReadDriverCount")) {

              if ( globals.currentShowingPage != AppRoutes.APP_CHAT) {
                showNotification(map['title'], map['message'], map);
              }
            } else {
              showNotification(map['title'], map['message'], map);
            }

            if (!globals.isShowMapPage &&
                map['tripStatus'] != null &&
                map['tripStatus'].toString().isNotEmpty) {
              _showItemDialog(map['title'], map['message']);
            }
          }
          _prebookingID = map["bookingId"] ?? 0;
        }

        if (map['tripStatus'] == "created") {
          globals.tripInfo = json.decode(message.data['content']);
          if (!globals.tripFromSocket) {
            globals.tripStatusChangedController.value = true;
          }
        } else if (map['tripStatus'] == "updateStop") {
          globals.tripInfo = json.decode(message.data['content']);
          globals.tripStatusChangedController.value = true;
        }
      }
    });
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(Duration(milliseconds: 100)).then((value){
          Map<String, dynamic> map = {};
          if (Platform.isAndroid) map = json.decode(message.data['content']);
          if (Platform.isIOS) map = json.decode(message.data['content']);
          if(map['tripStatus'].toString() =="paymentSuccess"){
            print("Im called from this message in --->");
            globals.navigateToPayout = true;
          }
          debugPrint("fcmmessage: ${map}");
          if (map.containsKey("unReadDriverCount")) {
            Future.delayed(const Duration(milliseconds: 4000), () {
              NavigateToChat();
            });
          }

           else if(map.containsKey("isDriverEligible") && map.containsKey("walletBalance")){
             Future.delayed(const Duration(milliseconds: 4000), () {
               map['isintial']= true;
               globals.rxFcmWalletOptions.value = map;
            });
          }
          else if(map['tripStatus'].toString().compareTo("cancelledByRider") == 0) {
            globals.navigateToTripsPast = true;
          }
        });
      }
    });
    await _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (globals.authToken?.isEmpty ?? true) {
        return;
      }
      Map<String, dynamic> messageContent = Map<String, dynamic>();
      messageContent = json.decode(message.data['content']);
      globals.tripInfo = messageContent;
      if ((messageContent['tripStatus'].toString()).compareTo("created") == 0) {
        if (globals.isShowMapPage) {
          if (!globals.tripFromSocket) {
            int curr = new DateTime.now().millisecondsSinceEpoch;
            int timeinterval = (curr - messageContent['requestTime']).round();
            globals.progressLoadTime = globals.notificationInterval;
            if (timeinterval < globals.notificationInterval * 1000) {
                globals.progressLoadTime = globals.progressLoadTime - (timeinterval / 1000).toInt();
            }
            globals.tripStatusChangedController.value = true;
          }
        }
      }
      if ( globals.currentShowingPage != AppRoutes.APP_CHAT) {
        if (messageContent.containsKey("unReadDriverCount")) {
          NavigateToChat();
        }else {
          if (messageContent.containsKey("isDriverEligible") && messageContent.containsKey("walletBalance")) {
            if(globals.currentShowingPage == '/login'){
                Future.delayed(const Duration(milliseconds: 3000), () {
                  messageContent['isintial']= true;
                  globals.rxFcmWalletOptions.value = messageContent;
                });
                return;
              }
              globals.rxFcmWalletOptions.value = messageContent;
              Map<String, dynamic> walletoptions = globals.driverWalletOptionController.value;
              if (globals.currentShowingPage != AppRoutes.APP_DRIVER_WALLET && walletoptions["driverWalletOption"] == "1" && globals.userid == messageContent["id"])
                App().setNavigation(AppRoutes.APP_DRIVER_WALLET);
          }
          else if(messageContent.containsKey("tripStatus")){
            if(messageContent["tripStatus"] != "tripComplete"){
              if(globals.currentShowingPage == AppRoutes.APP_CHAT){
                App().setBackNavigation();
              }
              else{
                print("fcm click currentroute: 1 : ${Get.currentRoute}");
                if(Get.currentRoute != '/Main')
                Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN || route.settings.name == "/MapMainScreen" || route.isFirst);
                if (globals.isDrawerOpen) {
                  App().setBackNavigation();
                }
              }
            }
          }
        }
      }
      if((messageContent['tripStatus'].toString()).compareTo("paymentSuccess") == 0){
        App().setNavigation(AppRoutes.APP_PAYOUT_DISPLAY);
      }
      else if(messageContent['tripStatus'] == "cancelledByRider") {
        globals.navigateToTripsPast = true;
        WidgetsFlutterBinding.ensureInitialized().performReassemble();
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    graphQlObject.loadGraphQLJson("login_graphql").then((value) {
      globals.closeKeyboard = false;
    });
  }

  Future<dynamic> onMessage(bool isLocal, Map<String, dynamic> payload) async {

    globals.requestTime = payload['data']['content']['requestTime'];
    if (!globals.isShowMapPage &&
        payload['data']['content']['tripStatus'] != null &&
        payload['data']['content']['tripStatus'].toString().isNotEmpty) {
      _showItemDialog(payload['data']['content']['title'],
          payload['data']['content']['message']);
    }
    globals.tripInfo = payload['data']['content'];
    globals.tripStatusChangedController.value = true;

    if ("${payload['data']['content']['requestType']}" == "locationUpdate") {
      getcurrentlocation();
    }
  }

  Future<String?> getcurrentlocation() async {
    _getLoc();
    if (globals.userLat != 0.0 && globals.userLon != 0.0) {
      return await updateCurrentLoc(LatLng(globals.userLat, globals.userLon));
    }
  }

  Future<String> updateCurrentLoc(LatLng curlocation) async {
    graphQlObject.graphQLClientWithHeader;

    var variables = <String, dynamic>{
      "lat": curlocation.latitude,
      "lng": curlocation.longitude
    };

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "updateDriverLocation_mutation",
        variables);
    if (_login_result?["updateDriverLocation"]["status"] == 200) {
      return "";
    } else if (_login_result?["updateDriverLocation"]["status"] == 500) {
      return "timeout";
    } else {
      return _login_result?["updateDriverLocation"]["errorMessage"];
    }
  }

  showNotification(
      String title, String body, Map<String, dynamic> message) async {
    int curr = new DateTime.now().millisecondsSinceEpoch;
    int timeInterval = 0;
    debugPrint("showIOSNotification:  noti ${message} -- ${title} --");
    if (message.containsKey('requestTime')) {
      timeInterval = (curr - message['requestTime']).round();
    }


    await flutterLocalNotificationsPlugin.show(
      id:Random().nextInt(10),
        title:title,
        body:body,
      notificationDetails: _notificationPlatform,
        payload:json.encode(message)
    );

    globals.progressLoadTime = globals.progressLoadTime - timeInterval ~/ 1000;

    globals.tripInfo = message;
  }

  void showIOSNotification(
      Map<String, dynamic> map, Map<String, dynamic> message) {
    debugPrint("showIOSNotification: ${message} -- ${map}");
    globals.requestTime = map['requestTime'];
    if (map.containsKey("unReadDriverCount")) {
      if ( globals.currentShowingPage != AppRoutes.APP_CHAT) {
        showNotification(map['title'], map['message'], map);
      }
    } else {
      showNotification(map['title'], map['message'], map);
    }
    if (!globals.isShowMapPage &&
        map['tripStatus'] != null &&
        map['tripStatus'].toString().isNotEmpty) {
      _showItemDialog(map['title'], map['message']);
    }
    if (map['tripStatus'] == "created") {
      globals.tripInfo = json.decode(message['content']);
      if (!globals.tripFromSocket) {
        globals.tripStatusChangedController.value = true;
      }
    } else if (map['tripStatus'] == "updateStop") {
      globals.tripInfo = json.decode(message['content']);
      globals.tripStatusChangedController.value = true;
    }
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
                        bottomRight: Radius.circular(4),
                    ),
                ),
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

  void NavigateToChat() async {
    print("preferencetoken: ${App().appPreference.authToken.isNotEmpty}");
    if (App().appPreference.authToken.isNotEmpty) {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();

      globals.isLoaderShow = false;
      Map<String, dynamic>? _tripResult = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClientWithHeader, "getTripStatus_query", null);
      if (_tripResult?["GetTripStatus"]["status"] == 200) {
        String tripStatus = _tripResult?["GetTripStatus"]["result"]["tripStatus"];
        int bookingId = _tripResult?["GetTripStatus"]["result"]["id"];
        globals.bookingId = _tripResult?["GetTripStatus"]["result"]["id"];
        if (tripStatus.compareTo("approved") == 0 ||
            tripStatus.compareTo("locationReached") == 0 ||
            tripStatus.compareTo("started") == 0) {
          print("currentpage: ${globals.currentShowingPage} -- ${globals.openChatFromNotificationController.value} -- ${bookingId}");
          if(globals.currentShowingPage.isNotEmpty || globals.currentShowingPage != '/login'){
            if( globals.openChatFromNotificationController.value != bookingId)
              globals.openChatFromNotificationController.value = bookingId;
            else
              globals.openChatFromNotificationController.refresh();
          }
          else {
            Future.delayed(Duration(milliseconds: 5000), (){
              if( globals.openChatFromNotificationController.value != bookingId)
                globals.openChatFromNotificationController.value = bookingId;
              else
                globals.openChatFromNotificationController.refresh();
            });
          }
        }
      }
    }
  }

  void onSelectNotification(NotificationResponse? payload) {
    var map;
    if(payload !=null && payload.payload !=null){
       map = jsonDecode(payload.payload!);
    }
    if ( globals.currentShowingPage != AppRoutes.APP_CHAT) {
      if (map.containsKey("unReadDriverCount")) {
        NavigateToChat();
      } else if((map['tripStatus'].toString()).compareTo("paymentSuccess") == 0){
        App().setNavigation(AppRoutes.APP_PAYOUT_DISPLAY);
      }
      else {
      if(payload !=null && payload.payload !=null){
        Map<String,dynamic> messageContent = json.decode(payload.payload!);
        if (messageContent.containsKey("isDriverEligible") && messageContent.containsKey("walletBalance")) {
          globals.rxFcmWalletOptions.value = messageContent;
        Map<String,dynamic> walletoptions =  globals.driverWalletOptionController.value;
        if(walletoptions.isEmpty) {
          Future.delayed(const Duration(milliseconds: 3000), () {
            map['isintial'] = true;
            globals.rxFcmWalletOptions.value = map;
          });
        } else if(globals.currentShowingPage != AppRoutes.APP_DRIVER_WALLET && walletoptions["driverWalletOption"] == "1" && globals.userid ==messageContent["id"])
          App().setNavigation(  AppRoutes.APP_DRIVER_WALLET);
        }
        if(messageContent['tripStatus'] == "cancelledByRider") {
          globals.navigateToTripsPast = true;
          App().setNavigation(  AppRoutes.APP_TRIPS);
        }
        else{
          if(messageContent.containsKey("tripStatus")){
        if(messageContent["tripStatus"] != "tripComplete"){
          if(globals.currentShowingPage == AppRoutes.APP_CHAT){
            App().setBackNavigation();
          }
          else{
            print("fcm click currentroute: 2 : ${Get.currentRoute}");
            if(Get.currentRoute != '/Main')
            Get.until((route) => route.settings.name == AppRoutes.APP_MAP_MAIN || route.settings.name == "/MapMainScreen" || route.isFirst);
            if (globals.isDrawerOpen){
              App().setBackNavigation();
            }
          }
        }
        else{
          if((messageContent['tripStatus'].toString()).compareTo("paymentSuccess") == 0){
            App().setNavigation(AppRoutes.APP_PAYOUT_DISPLAY);
          }
        }
          }
        }
      }
    }
    }
  }

  Future<void> _getLoc() async {
    try {
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
     //   await App().getNativeLocation();

      }
      if (globals.userLat != 0.0 && globals.userLon != 0.0)
        _controller.checkInternet(_getSimCountryCode, false);
    } on Exception catch (e) {
    }
  }

  void _getSimCountryCode() async {

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(globals.userLat, globals.userLon,);

      if ( globals.currentShowingPage != AppRoutes.APP_OTP_VERIFY) {
        if (_controller.phoneCountrycode.isEmpty)
          globals.CountryCode = placemarks[0].isoCountryCode!;
        globals.addressUpdateController.value = true;
      }

  }

  void _showItemDialog(String title, String body) {
    if (!globals.isShowMapPage) {
      Map<String, String> dialogMap = {"title": title, "body": body};
      globals.showDialogController.value = dialogMap;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("globals.authToken?.isEmpty: ${globals.authToken}");
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          customAppBarFunction: () {
            App().closeApp();
          },
          customAppBarContent: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: const SizedBox.shrink(),
          ),
          backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
          body: Column(
            children: [_showMainImageView(), _showBottomView()],
          ),
        );
      }
    );
  }

  Widget _showMainImageView() {
    return Expanded(
      child: Container(
        width: double.infinity,
        child: FittedBox(
          alignment: AlignmentDirectional.topCenter,
          fit: BoxFit.cover,
          child: Container(
            decoration: new BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
            ),
            child: Image.asset(
              fit: BoxFit.cover,
              mainPagePng,
            ),
          ),
        ),
      ),
    );
  }

  Widget _showBottomView() {
    String getMoveContent = get_move_with.trParams({"field":globals.APP_NAME}) == "get_move_with"?"Get started with ${globals.APP_NAME}":get_move_with.trParams({"field":globals.APP_NAME});
    String getStartContent = get_Started.tr == "get_Started"?"Drive anywhere, anytime.": get_Started.tr;
    String get_started_button = get_started_btn.tr == "get_started_btn"?"Get Started": get_started_btn.tr;
    return Container(
      color: AppColors.PRIMARY_COLOR_WHITE,
      padding: EdgeInsets.only(top: 20, bottom: 25, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text( getMoveContent,
            style: new TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontWeight: FontWeight.w600,
              fontSize: AppDimen.text_size_22,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            getStartContent,
            style: new TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontSize: AppDimen.text_size_18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            child: PrimaryButton(
              buttonTitle: get_started_button,
              buttonImage: primaryBtnArrow,
              innerPadding: 30.0,
              disableLoadCancel: true,
              callback: () {
                _controller.getCountryCode();
                handleTimeout();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }


}