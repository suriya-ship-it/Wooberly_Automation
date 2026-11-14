import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/secure_storage/storage_impl.dart';

import 'services/age_rating_service.dart';



void main() async {
  //runZonedGuarded(()async {
    WidgetsFlutterBinding.ensureInitialized();
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
    await initializeDateFormatting();
    await Firebase.initializeApp();
    await GetSecureStorage.init(password: globals.SecurityKey);
    await AgeRatingController().checkUserAge();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    graphQlObject.loadGraphQLJson("login_graphql");
    runApp(GraphQLProvider(
      child: CacheProvider(child: App()),
      client: graphQlObject.getGraphQlClient(),
    ));
  //
  // }, (error, stackTrace) {
  //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
  // });
}


const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description:  'This channel is used for important notifications.',

  importance: Importance.high,
);


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();