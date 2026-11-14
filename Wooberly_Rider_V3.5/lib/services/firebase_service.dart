import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/controllers/splash_controller.dart';
import 'package:app_name/main.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;

class FirebaseService {
  SplashController splashController = Get.find();

  static Future<String?> getFcmToken() async {
    try {
      Permission.notification.request();
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int count = 0;
        while (apnsToken == null && count < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          count++;
        }

        if (apnsToken == null) {
          debugPrint("APNS token is not available yet after retries.");
          return null;
        }
      }
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM token generated: $token");
      return token;
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
      return null;
    }
  }

  static Future<void> deleteFcmToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint("Error deleting FCM token: $e");
    }
  }

  configureFCM() async {
    globals.fcmConfigured = true;
    var android = new AndroidInitializationSettings('mipmap/ic_launcher_foreground');
    var ios = new DarwinInitializationSettings();
    var platform = new InitializationSettings(android: android, iOS: ios);
    flutterLocalNotificationsPlugin.initialize(settings:platform, onDidReceiveNotificationResponse: (notificationResponse) {
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        onSelectNotification(notificationResponse);
      });
    });
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("onTokenRefresh: $newToken");
      globals.deviceId = newToken;
    }).onError((error) {
      debugPrint("Token refresh error: $error");
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("onmessageReceived: ${message}");
      Map<String, dynamic> map = json.decode(message.data['content']);
      if(!(map.containsKey("unReadRiderCount") && Get.currentRoute.contains('App_Chat')) ){
        showNotification(map['title'], map['message'], map);
      }

      debugPrint("fcmtripstatus: ${map['tripStatus']} --- ${globals.tripStatus}");
      if (map['tripStatus'] != null &&
          map['tripStatus'].toString().isNotEmpty && map['tripStatus'] !=globals.tripStatus)
        globals.tripStatusChangedController("true");

    });
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(Duration(milliseconds: 100)).then((value) {
          Map<String, dynamic>? map;
          if (Platform.isAndroid) map = json.decode(message.data['content']);
          if (Platform.isIOS) map = message.data;
          NavigateToChatPage(map!,true);
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      Map<String, dynamic>? map;
       map = json.decode(message.data['content']);
      NavigateToChatPage(map!, false);
    });
  }

  void NavigateToChatPage(
      Map<String, dynamic> map, bool isTerminatedMsg) async {

    print("Data of message one --> ${map}");
    if (!Get.currentRoute.contains('App_Chat')) {
      if (map.containsKey("unReadRiderCount")) {
        if (globals.authToken != null && globals.authToken != "") {
          String? staus = await getTripStatus();
          if (staus?.isEmpty ?? false) {
            if (globals.tripStatus.compareTo("approved") == 0 ||
                globals.tripStatus.compareTo("started") == 0 || globals.tripStatus.compareTo("locationReached") == 0) {
              if (globals.openChatFromNotificationController != null) {
                debugPrint("globals.baseController.bookingId: ${splashController.bookingId}");
                if( globals.openChatFromNotificationController.value != splashController.bookingId.toString())
                  globals.openChatFromNotificationController.value = splashController.bookingId.toString();
                else
                  globals.openChatFromNotificationController.refresh();
              }
            } else {
              globals.navigateToTripsPast = true;
            }
          }
        }
      }
    }
    if(map.containsKey("tripStatus")){
        if(map["tripStatus"] != "tripComplete"){
          if(!Get.currentRoute.contains('map_main_screen')){
            if(Get.isDialogOpen ==true){
              Get.back();
            }
            if(!isTerminatedMsg) {
            Navigator.popUntil(Get.context!,
                    (r) => (r.settings.name == AppRoutes.APP_MAP_MAIN) || (r.settings.name == AppRoutes.APP_HOME));
            }
            if (globals.isDrawerOpen){
              globals.baseController.setBackNavigation();
            }
          }
        }
      }

    debugPrint("map['title']-> ${map['title']}");
    debugPrint("globals.isTripsPage-> ${Get.currentRoute.contains('trips')}");
  }

  Future<String?> getTripStatus() async {
    String value = await splashController.getTripStatus();
    if (value == "offline") {
      globals.baseController.netOffSnackbar( getTripStatus, false);
      return 'failure';
    } else if (value == "success") {
      return '';
    }
  }

  Future<dynamic>? onSelectNotification( NotificationResponse? notificationResponse) {
    debugPrint("onSelectNotificationpayload: ${notificationResponse} ---${notificationResponse?.payload}");
    if (notificationResponse?.payload != null && notificationResponse!.payload!.isNotEmpty) {
      try {
        Map<String, dynamic> map = json.decode(notificationResponse.payload!);
        debugPrint("onSelectNotificationpayload: --- ${map}");
        NavigateToChatPage(map,false);
      } catch (e) {
        debugPrint("Error decoding notification payload: $e");
      }
    }
  }

  showNotification(
      String title, String body, Map<String, dynamic> message) async
  {
    int curr = new DateTime.now().millisecondsSinceEpoch;

    int timeinterval = (curr - message['requestTime']).round();
    if (timeinterval < 20000) {
      var android = new AndroidNotificationDetails(
        'rider id',
        "rider channel",
        channelDescription: "rider description",
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        styleInformation: BigTextStyleInformation(''),
      );
      var iOS = new DarwinNotificationDetails();
      var platform = new NotificationDetails(android: android, iOS: iOS);
      await flutterLocalNotificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: platform,
        payload: json.encode(message),
      );
    }
  }

}