import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/services/age_rating_service.dart';
import 'package:wooberly_driver/views/splash.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(MainApp());
  }, (error, stackTrace) {
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  });
}

class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
    _initializeDeferred();
  }

  Future<void> _initializeApp() async {
    graphQlObject.loadGraphQLJson("login_graphql");
  }

  Future<void> _initializeDeferred() async {
    await Firebase.initializeApp();
    await initializeDateFormatting();
    await AgeRatingController().checkUserAge();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;


    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false, // Prevents the heads-up notification banner
        badge: false, // Prevents badge updates while app is open
        sound: false, // Prevents the notification sound
      );
    }
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return App().getMaterialApp(
              widget: SplashView(), title: "", buildContext: context);
        }
        return GraphQLProvider(
          child: CacheProvider(
            child: App(),
          ),
          client: graphQlObject.getGraphQlClient(),
        );
      },
    );
  }
}

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  // description
  importance: Importance.high,
);

/// Initialize the [FlutterLocalNotificationsPlugin] package.
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();