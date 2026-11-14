import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uuid/uuid.dart';
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/services/firebase_service.dart';
import 'package:app_name/models/ride_comfort_model.dart';
import 'package:app_name/utils/geo_locator.dart';
import 'package:app_name/utils/google_map.dart';

import '../app/app.dart';
import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../databases/app_preferences.dart';
import '../graphql/graphql_config.dart';
import '../models/currency_model.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;
import '../utils/globals.dart';
import '../widgets/app_builder.dart';
import '../widgets/blinking_toast.dart';

part '../controllers/base_controller_part2.dart';

class BaseController extends GetxController {
  final Toast toast = new Toast();
  MethodChannel locationChannel = MethodChannel('getLocation');
  late Directory appDocumentsDir;
  String _currentroutename = "";
  AppPreferences preferences = Get.find();
  int AILangListCurrentPage = 1, AILanglistCount = 0;
  List<RideComfortModel> rideComfortData = <RideComfortModel>[];
  RxList<Map<String, String>> AILanglist = <Map<String, String>>[].obs;


  String offlineMessageContent = 'offline_text'.tr =='offline_text' ? "You are currently offline" : 'offline_text'.tr;
  String retryContent = 'retry'.tr == 'retry'? "Retry": "retry".tr;

  var uuid = Uuid();
  var sessionId = "";

  getDeviceDetails() {
    try {
      if (Platform.isAndroid) {
        globals.deviceName = "android";
      } else if (Platform.isIOS) {
        globals.deviceName = "ios";
      }
    } on Exception {
      debugPrint('Failed to get platform version');
    }
  }

  getRideComfortList(){
    rideComfortData.clear();
    rideComfortData.add(RideComfortModel(
      1,
      'Women_driver'.tr,
      womenonlySvg,
      false,));
    rideComfortData.add(RideComfortModel(
        2,
        'Child_seat'.tr,
        childSeatSvg,
        false));
    rideComfortData.add(RideComfortModel(
        3,
        'Wheel_chair'.tr,
        wheelChairSvg,
        false));
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
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> checkInternet(Function verify, bool? toastShow) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('checkInternet ${point} --- ${globals.tripStatus}');
    try {
      debugPrint("checkinternet:");
    } on Exception catch (e) {
      debugPrint("checkInternet Exception: ${e}");
      return false;
    } catch (error) {
      if (Get.currentRoute.trim() == "/")
        globals.setButtonDisabled();
      else
        globals.setButtonIdle();
      return false;
    }

    closeMessage();
    bool internetConnect = await checkConnectivity();
    if (internetConnect != null && internetConnect) {
      verify();
    } else {
      if (toastShow == null) {
      } else if (toastShow) {
        toast.show(
          context: Get.context!,
          message: offlineMessageContent,
        );
      } else {
        netOffSnackbar(verify, toastShow);
      }
    }
    return Future.value(internetConnect);
  }

  late final updatesSecureSiteSettings = {
    "stripePublishableKey": (val) => globals.stripePublishableKey = val,
    "preferredDistanceType": (val) => globals.distanceType = val,
    "multipleStopsWaitingTime": (val) => globals.multipleStopWaitingTime = val,
    "contactPhoneNumber": (val) => globals.supportPhone = val,
    "contactEmail": (val) => globals.supportEmail = val,
    "whatsApp": (val) => globals.supportWhatsapp = val,
    "enableOTPFeature": (val) => globals.isEnableOTP = val == '1',
    "isVoiceAIFeature": (val) => globals.isVoiceChatEnable = val == 'true',
    "isVoiceTranslatorFeature": (val) => globals.isVoiceTranslatorEnable = val == 'true',
    "riderAppAndroidMapApiKey": (val) {
      if (Platform.isAndroid) { globals.MAP_KEY = val; setMapKey(); }
    },
    "riderAppiOSMapApiKey": (val) {
      if (Platform.isIOS) { globals.MAP_KEY = val; setMapKey(); }
    },
  };

  closeMessage() {
    if (globals.closeKeyBoard) {
      Get.closeCurrentSnackbar();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      globals.closeKeyBoard = true;
    }
  }
  void updateObx<T>(RxObjectMixin<T> reactVar, T state) {
    if (reactVar.value == state) {
      reactVar.refresh();
    } else {
      reactVar.value = state;
    }
  }

  void netOffSnackbar(Function verify, bool toastShow) {
    Get.showSnackbar(GetSnackBar(
      backgroundColor: Colors.black,
      messageText: Text(offlineMessageContent,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_14,
            fontFamily: AppFont.font,
          )),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          checkInternet(verify, toastShow);
        },
        child: Text(
          retryContent,
          style: TextStyle(color: AppColors.PRIMARY_LIGHT_COLOR),
        ),
      ),
      snackbarStatus: (reason) {
        if (reason == SnackBarClosedReason.swipe) netOffSnackbar(verify, toastShow);
      },
      duration: Duration(hours: 1),
    ));
  }

  Future<void> setMapKey() async {
    try {
      await locationChannel.invokeMethod('setMapKey', {'key': globals.MAP_KEY});
    } on PlatformException catch (e) {
      print("Failed to get a key: '${e.message}'.");
    }
  }

   Future<void> openLocationSettings() async {
    try {

      await locationChannel.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open location settings: ${e.message}');
    }
  }


  void clearNotification() {
    locationChannel.invokeMethod('clearNotify');
  }

  Future<bool> checkUserLogin() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    Map<String, dynamic>? walletbalancequery =
        await graphQlObject.getQueryValues(graphQlObject.graphQLClientWithHeader, "fetchWallet_query", null);
    if (walletbalancequery != null) {
      if (walletbalancequery["userAccount"]["status"] == 200) {
        return true;
      } else {
        toast.show(
            context: Get.overlayContext ?? Get.context!,
            message: 'session_timeout_err'.tr,
            duration: Duration(seconds: 1)
        );
        return false;
      }
    }
    return true;
  }

  initSocket() async {
    globals.socket = io(globals.SOCKET_URL,
        OptionBuilder().setTransports(['websocket']).enableAutoConnect().enableReconnection().build());

    globals.socket?.onConnect((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });

    globals.socket?.connect();
    debugPrint("initSocket: socketconnection ${globals.socket?.connected}");
  }

  Future<void> setNavigation(String app_route_name, [Map<String, dynamic>? arguments]) async {
    checkInternet(() async {
      svg.cache.clear();
      imageCache.clear();
      _currentroutename = app_route_name;
      await Get.toNamed(app_route_name, arguments: arguments);
    }, false);
  }

  setLocationDetails(
      {required SelectLocationModel selectLocationModel, required SelectLocationEnum selectLocationEnum}) {
    globals.favoriteLocationMap[selectLocationEnum] = selectLocationModel;
  }

  void closeApp() {
    if (Platform.isAndroid) {
      locationChannel.invokeMethod('closeApp');
      SystemNavigator.pop();
    } else
      exit(0);
  }

  void showThemeModeBottomSheet(BuildContext mcontext,
      {BuildContext? scaffoldContext, Function? ThemeChangeCallback}) {
    App().showBottomSheet(Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return Container(
        height: 240,
        color: AppColors.PRIMARY_LIGHT_COLOR,
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (BuildContext ctxt, int index) {
            return Padding(
                padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 24),
                child: Wrap(children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          if (index == 0) {
                            globals.setButtonLoading();
                            var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
                            globals.isDarkTheme = brightness == Brightness.dark;
                            globals.theme = 1;
                            if (globals.isDarkTheme) {
                              AppColors().changeToDark();
                            } else {
                              AppColors().changeToLight();
                            }
                            Get.back();
                            //globals.setButtonIdle();
                            globals.setButtonIdle();
                            globals.themeNotifier?.isDark = globals.isDarkTheme;
                            AppBuilder.of(mcontext)?.build(mcontext);
                          } else if (index == 1) {
                            //globals.setButtonLoading();
                            globals.setButtonLoading();
                            globals.isDarkTheme = false;
                            globals.theme = 2;
                            AppColors().changeToLight();
                            Get.back();
                            //globals.setButtonIdle();
                            globals.setButtonIdle();
                            globals.themeNotifier?.isDark = false;
                            AppBuilder.of(mcontext)?.build(mcontext);
                          } else {
                            //globals.setButtonLoading();
                            globals.setButtonLoading();
                            globals.isDarkTheme = true;
                            globals.theme = 3;
                            AppColors().changeToDark();
                            Get.back();
                            //globals.setButtonIdle();
                            globals.setButtonIdle();
                            globals.themeNotifier?.isDark = true;
                            AppBuilder.of(mcontext)?.build(mcontext);
                          }

                          ThemeChangeCallback!(globals.theme);
                        },
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 13),
                              child: SvgPicture.asset(
                                index == 0
                                    ? defaultThemeSvg
                                    : index == 1
                                        ? homeLightSvg
                                        : homeDarkSvg,
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                index == 0
                                    ? 'Auto'.tr
                                    : index == 1
                                        ? 'Light'.tr
                                        : 'Dark'.tr,
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16),
                              ),
                            ),
                            (globals.theme == (index + 1))
                                ? SvgPicture.asset(
                                    updatedVerified,
                                    width: 23.0,
                                    height: 23.0,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 10),
                        child: Divider(
                          color: AppColors.DIVIDER_COLOR,
                        ),
                      ),
                    ],
                  )
                ]));
          },
        ),
      );
    }), AppColors.PRIMARY_LIGHT_COLOR);
  }

  listenLocationPermission(BuildContext context, Function callBack) async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(Platform.isAndroid) {
        showPermissionDialog(permissionType: 'systemLocationService');
      } else {
        EnableLocationService();
      }
      return;
    };
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint("locationpermission: ${permission}");
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint("permission: 2 ${permission}");
      if (permission == LocationPermission.deniedForever) {
        showPermissionDialog(permissionType:'appService');
        return;
      }
    }
    callBack();
  }

  Future<void> showPermissionDialog({String? title ,required String permissionType }) async{
    return showGetDialog(PopScope(
        canPop: false,
        child: Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
              return AlertDialog(
                  backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                  shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                  content: Text(title ?? 'Enable_the_location_service'.tr,style: TextStyle(color: AppColors.BLACK_TEXT_COLOR)),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text('cancel_label'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        if(permissionType == 'appService') {
                          openAppSettings();
                        }else{
                          openLocationSettings();
                        }
                        Get.back();
                      },
                      child: Text('Go_to_settings'.tr),
                    )
                  ]);
            }
        )
    ));
  }

  void snackBarwithAction(String value, Function() listenForPermissionStatus) {
    Get.showSnackbar(GetSnackBar(
      backgroundColor: Colors.black,
      messageText: Text(value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_14,
            fontFamily: AppFont.font,
          )),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          listenForPermissionStatus();
        },
        child: Text(
          offlineMessageContent,
          style: TextStyle(color: AppColors.PRIMARY_LIGHT_COLOR),
        ),
      ),
      snackbarStatus: (reason) {
        if (reason == SnackBarClosedReason.swipe) snackBarwithAction(value, listenForPermissionStatus);
      },
      duration: Duration(hours: 1),
    ));
  }

  Future<bool> listenForPermissionStatus(Permission permission) async {
    return permission.isGranted;
  }

  Future<String> getNativeLocation() async {
    try {

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) throw Exception('Location services disabled');

      if(Platform.isAndroid) {
        const MethodChannel _channel = MethodChannel('contact_picker');
        final int sdkVersion = await getAndroidSDKVersion();

        if (sdkVersion >= 37) {
          final result = await _channel.invokeMethod('triggerLocationButton');
          globals.userLat = result['lat'];
          globals.userLon = result['lng'];
          return '';
        }
      }

      // Android 16 and below → geolocator works normally
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint("serviceEnabled: getNativeLocation called: ${permission}");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      debugPrint("getNativeLocation: $permission");

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      globals.userLat = position.latitude;
      globals.userLon = position.longitude;
      debugPrint("getCurrentLocation: ${globals.userLat}---- ${globals.userLon}");
      return '';

    } on PlatformException catch (e) {
      debugPrint("Failed to get location: '${e.message}'.");
      return "";
    }
  }

  Future<int> getAndroidSDKVersion() async{
    const MethodChannel _channel = MethodChannel('contact_picker');
 return await _channel.invokeMethod<int>('getSdkVersion') ?? 0;
  }

  getCurrentLocationAddress({bool toFetchCurrentLatLng = false}) async {
    try {
      if(toFetchCurrentLatLng) {
        await getNativeLocation();
      }
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        globals.userLat,
        globals.userLon,
      );
      if (!Get.currentRoute.contains('otp_verify') && (globals.authToken == null ||globals.authToken!.isEmpty)) {
        globals.CountryCode = placemarks[0].isoCountryCode!;
      }
      globals.currentLocation.value = getAddressFromPlaceMark(placemarks[0]);
      debugPrint('getCountryCode: 123 ${ globals.currentLocation.value}');
    } on Exception {
      rethrow;
    }
  }

  String _normalize(String input) {
    String s = input.toLowerCase();

    // expand common abbreviations so "Rd" and "Road" match
    final Map<String, String> replacements = {
      r'\brd\b': 'road',
      r'\bst\b': 'street',
      r'\bave\b': 'avenue',
      r'\bblvd\b': 'boulevard',
      r'\bln\b': 'lane',
      r'\bdr\b': 'drive',
      r'\bhwy\b': 'highway',
      r'\bapt\b': 'apartment',
      r'\bft\b': 'feet',
    };

    replacements.forEach((pattern, full) {
      s = s.replaceAll(RegExp(pattern), full);
    });

    // remove punctuation and collapse whitespace
    s = s.replaceAll(RegExp(r'[.,#\-]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  String getAddressFromPlaceMark(Placemark placeMark) {
    String? street = placeMark.street;
    String? country = placeMark.country;
    String? thoroughfare = placeMark.thoroughfare;
    String? postalCode = placeMark.postalCode;
    String? administrativeArea = placeMark.administrativeArea;
    String? subAdministrativeArea = placeMark.subAdministrativeArea;
    String? locality = placeMark.locality;
    String? subLocality = placeMark.subLocality;

    String first = "";
    String normalizedSoFar = "";

    void appendIfNew(String? part) {
      if (part == null || part.trim().isEmpty) return;
      String normalizedPart = _normalize(part);
      if (normalizedSoFar.contains(normalizedPart)) return;
      first = first.isEmpty ? part : "$first, $part";
      normalizedSoFar = _normalize(first);
    }

    appendIfNew(street);
    appendIfNew(thoroughfare);
    appendIfNew(subLocality);
    appendIfNew(locality);
    appendIfNew(subAdministrativeArea);
    appendIfNew(administrativeArea);
    appendIfNew(country);

    if (postalCode != null && postalCode.isNotEmpty && !normalizedSoFar.contains(postalCode)) {
      first = "$first-$postalCode";
    }
debugPrint("getAddressFromPlaceMarkname: ${placeMark.name}");
    return first;
  }

  SelectLocationModel getLocationDetails(SelectLocationEnum selectLocationEnum) {
    return globals.favoriteLocationMap[selectLocationEnum] ??
        SelectLocationModel(
            lng: 0.0,
            lat: 0.0,
            location: '',
            selectLocationEnum: SelectLocationEnum.homeLocation,
            isValidLocation: false);
  }
  onManualBookingCreatedByAdminCheck() {
    globals.socket?.off("manualBookingCreatedByAdmin-${globals.userid}");
    globals.socket?.on("manualBookingCreatedByAdmin-${globals.userid}", (data) {
      if (data is Map) {
        debugPrint("manualBookingCreatedByAdmin: ${data}");
        Get.offAllNamed(AppRoutes.APP_MAP_MAIN);
      }
    });
  }

  setLogout() {

    if (globals.authToken?.isNotEmpty ?? false) {
      globals.authToken = "";

      globals.mapEnableController(false);

      FirebaseService.deleteFcmToken().then((value) {
        FirebaseService.getFcmToken().then((token) {
          globals.socket?.off("updatePreferredCurrency-${globals.userid}");
          globals.socket?.off("userInformationChange-${globals.userid}");
          globals.socket?.off("driverApprove-${globals.userid}");
          globals.socket?.off("tripRequest-${globals.userid}");
          globals.socket?.off("updatePreferredCurrency-${globals.userid}");
          globals.socket?.off("manualBookingCreatedByAdmin-${globals.userid}");

          preferences.authToken = '';
          globals.openChatFromNotificationController.close();
          globals.openChatFromNotificationController = ''.obs;

          globals.socket?.disconnect();
          globals.deviceId = token ?? "";

          Future.delayed(Duration(milliseconds: 80)).then((value) {
            movetoInitialPage(AppRoutes.APP_SPLASH);
          });
          globals.tripStatus = "";
          globals.uploadedImage = null;
          globals.picture.value = "";
          getLocation();
          globals.contacts.clear();
          globals.favoriteLocationEnumList.forEach((element) {
            removeLocationDetails(selectLocationEnum: element);
          });
          globals.cardLastFour = null;
          globals.preferredPaymentMethod = 1;

          globals.socket?.off("loginCheck-${globals.userid}");
          var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
          globals.isDarkTheme = brightness == Brightness.dark;
          globals.theme = 1;
          if (globals.isDarkTheme) {
            AppColors().changeToDark();
          } else {
            AppColors().changeToLight();
          }
          globals.themeNotifier?.isDark = globals.isDarkTheme;
          preferences.clearPreference();
          RegisterController().dispose();

          preferences.preferredLaunguage = globals.preferredLanguage;
          globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
          clearApplicationDocumentsDirectory();
        });
      });
    }
  }

  Future<void> clearApplicationDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      if (await directory.exists()) {
        final files = directory.listSync();

        for (final file in files) {
          await file.delete(recursive: true);
        }

        print("Application Documents Directory contents cleared successfully.");
      }
    } catch (e) {
      print("Error clearing directory contents: $e");
    }
  }

  void movetoInitialPage(String routeName) {
    Get.offAllNamed(routeName);
  }

  showLocationPermissionAlert(String AlertMessage, bool isLocationDisabled, {String? permissionType}) {
    showGetDialog(PopScope(
      canPop: false,
      child: Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        return AlertDialog(
            backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
            content: Text(
              AlertMessage,
              style: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('cancel_label'.tr, style: TextStyle(color: AppColors.PROMOCODE_LINK_COLOR)),
              ),
              TextButton(
                onPressed: () {
                  if (permissionType == null) {
                    if (isLocationDisabled) {
                      openLocationSettings();
                      Get.back();
                    } else {
                      openAppSettings();
                      Get.back();
                    }
                  } else {
                    openAppSettings();
                    Get.back();
                  }
                },
                child: Text('Go_to_settings'.tr, style: TextStyle(color: AppColors.PROMOCODE_LINK_COLOR)),
              )
            ]);
      }),
    ));
  }

  Future<void> showGetDialog(Widget dialog) async {
    Get.dialog(dialog, barrierDismissible: false);
  }

  Future<void> showConfirmationDialog({String? title, required String content, required Function onConfirm, Function? onCancel,required String confirmButtonText,String? cancelButtonText,bool isDisableCancel = false }) async {
    Get.dialog(PopScope(
      canPop: false,
      child: Consumer<ModelTheme>(
          builder: (context, ModelTheme themeNotifier, child) {
            return AlertDialog(
              backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              title: title !=null ?
              Row(
                children: [
                  Image.asset(dialogLogoPng, width: 40, height: 40.0),
                  const SizedBox(width: 15),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ): null,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if(!isDisableCancel)
                      Expanded(
                        child: InkWell(
                          onTap: () => onCancel!= null ? onCancel() : Get.back(),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 10),
                            height: 50,
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                width: 1,
                                color: AppColors.PRIMARY_DARK_COLOR,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cancelButtonText ?? 'cancel_label'.tr,
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            onConfirm();
                          },
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(start: 10),
                            height: 50,
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.PRIMARY_DARK_COLOR,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                confirmButtonText,
                                style: TextStyle(
                                  color: AppColors.PRIMARY_LIGHT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
      ),
    ), barrierDismissible: false);
  }


  removeLocationDetails({required SelectLocationEnum selectLocationEnum}) {
    if (globals.favoriteLocationMap.containsKey(selectLocationEnum))
      globals.favoriteLocationMap.remove(selectLocationEnum);
  }

  Future<String?> getLocation() async {
    try {
      globals.userLat = double.parse(globals.currentLocation.value.split('///')[0]);
      globals.userLon = double.parse(globals.currentLocation.value.split('///')[1]);

      if (globals.userLat != 0.0 && globals.userLon != 0.0) {
        await getCurrentLocationAddress();
        return globals.CountryCode;
      }
    } on Exception catch (e) {
      debugPrint("Exception in getLocation $e");
    }
  }

  void showInSnackBar(String value) {
    try {
      Get.closeCurrentSnackbar();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      Get.showSnackbar(GetSnackBar(
        margin: EdgeInsets.symmetric(vertical: Get.height * 0.02, horizontal: Get.width * 0.04),
        animationDuration: Duration(milliseconds: 0),
        borderRadius: 4,
        backgroundColor: Colors.black,
        messageText: Text(value, style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 4),
        snackbarStatus: (reason) {
          if (reason == SnackBarClosedReason.swipe) showInSnackBar(value);
        },
      ));
    } on Exception catch (e) {
      debugPrint("showInSnackBar Exception: ${e}");
    } catch (error) {
      debugPrint("showInSnackBar error: ${error}--${_currentroutename}");
      if (_currentroutename == AppRoutes.APP_PHONE_AUTH)
        globals.setButtonDisabled();
      //globals.loadingController.add(2);
      else
        globals.setButtonIdle();
      //globals.setButtonIdle();
    }
  }

  void setBackNavigation() {
    svg.cache.clear();
    imageCache.clear();
    Get.back();
  }

  Future<bool> isLocationPermissionsEnabled() async{

    bool isLocationServiceenable = await isLocationServiceEnable();
    if(!isLocationServiceenable) return false;

    Permission locationPermission = Platform.isAndroid
        ? Permission.location
        : Permission.locationWhenInUse;

    PermissionStatus locationStatus = await locationPermission.status;
    if(locationStatus != PermissionStatus.granted) return false;

    return true;
  }

  Future<bool> isLocationServiceEnable() async {
    try {
      bool location = await locationChannel.invokeMethod('CheckLocationService');
      return location;
    } on PlatformException catch (e) {
      debugPrint("Failed to get location service: '${e.message}'.");
      return false;
    }
  }

  Future<bool> EnableLocationService() async {
    try {
      bool location = await locationChannel.invokeMethod('EnableLocationService');
      return location;
    } on PlatformException catch (e) {
      debugPrint("Failed to get location service: '${e.message}'.");
      return false;
    }
  }

  Widget getProgressIndicator() {
    return new Center(
      child: new Container(
        width: 100,
        height: 100,
        child:ColorFiltered(
          colorFilter: ColorFilter.mode(AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
          child: Lottie.asset(globals.isDarkTheme
              ? 'assets/lottieloader_dark.json'
              : 'assets/lottieloader.json'),
        ),
      ),
    );
  }

  LatLng? getLatLngFromLocationModel({required SelectLocationEnum selectLocationEnum}) {
    if (globals.favoriteLocationMap.containsKey(selectLocationEnum))
      return LatLng(globals.favoriteLocationMap[selectLocationEnum]!.lat,
          globals.favoriteLocationMap[selectLocationEnum]!.lng);
    return null;
  }

  String getCurrencySybmol(String currency, String symbol) {
    return switch (currency) {
      "MXN" => "MX\$",
      "HKD" => "HK\$",
      "NZD" => "NZ\$",
      "CNY" => "CN\$",
      "AUD" => "A\$",
      "CAD" => "CA\$",
      _ => NumberFormat.simpleCurrency(name: currency).currencySymbol,
    };
  }

  Future<String> getSecurityKey() async {
    try {
      String secretKey = await locationChannel.invokeMethod('securityKey');
      return secretKey;
    } on PlatformException catch (e) {
      debugPrint("Failed to get location level: '${e.message}'.");
      return "";
    }
  }

  Map paymentItemMap({Function? paymentOnTap}) {
    return {
      1: {
        'paymentId': 1,
        'paymentName': 'cash'.tr,
        'paymentSvg': moneySvg,
        'paymentOnTap': paymentOnTap,
      },
      2: {
        'paymentId': 2,
        'paymentName': 'credit_debit'.tr,
        'paymentSvg': creditCardSvg,
        'paymentOnTap': paymentOnTap,
      },
      3: {
        'paymentId': 3,
        'paymentName': 'wallet'.tr,
        'paymentSvg': walletSvg,
        'paymentOnTap': paymentOnTap,
      },
      4: {
        'paymentId': 4,
        'paymentName': "Google Pay",
        'paymentSvg': googlePaySvg,
        'paymentOnTap': paymentOnTap,
      },
      5: {
        'paymentId': 5,
        'paymentName': "PayStack",
        'paymentSvg': payStackSvg,
        'paymentOnTap': paymentOnTap,
      },
      6: {
        'paymentId': 6,
        'paymentName': "PayPal",
        'paymentSvg': paypalPaymentSvg,
        'paymentOnTap': paymentOnTap,
      },
    };
  }

  AppRoutes getAppRoutes() {
    return AppRoutes();
  }

  String getRate(String from, dynamic amount, [String? to]) {
    Map<String, dynamic> currencyObject = jsonDecode(globals.currencyRates);
    if (!currencyObject.containsKey(globals.preferredCurrency) || !currencyObject.containsKey(from)) {
      return 'currency_conversion_error'.tr;
    }

    dynamic rate = currencyObject[to != null ? to : globals.preferredCurrency];

    return (rate * (1 / currencyObject[from]) * amount).toString();
  }

  Future<Uint8List?> getBytesFromAsset1(Uint8List byte) async {
    try {
      ui.Codec codec = await ui.instantiateImageCodec(byte, targetHeight: 120);
      ui.FrameInfo fi = await codec.getNextFrame();
      return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
    } on Exception catch (e) {
      print("marker image exception: ${e.toString()}");
    }
  }

  String getHoursCheck(String hours) {
    if (hour(int.parse(hours)).isEmpty && hours.isNotEmpty) {
      return ((double.parse(hours.toString()).round() == 1) ? 'hourOne'.tr : 'hourPOther'.tr);
    } else {
      return hour(int.parse(hours));
    }
  }

  String hour(howMany) {
    return Intl.plural(howMany,
        zero: "",
        one: 'hourOne'.tr,
        two: "",
        few: "",
        many: "",
        other: 'hourPOther'.tr,
        name: 'hour',
        args: [howMany]);
  }

  String min(howMany) {
    return Intl.plural(howMany,
        zero: "",
        one: 'minOne'.tr,
        two: "",
        few: "",
        many: "",
        other: 'minPOther'.tr,
        name: 'min',
        args: [howMany]);
  }

  String getMinCheck(String minute) {
    if (min(int.parse(minute)).isEmpty && minute.isNotEmpty) {
      return ((double.parse(minute.toString()).round() == 1) ? 'minOne'.tr : 'minPOther'.tr);
    } else {
      return min(int.parse(minute));
    }
  }

  updateRxValue(RxVariable rxVariable, dynamic updatingValue) {
    rxVariable.updateValue(updatingValue);
    update([rxVariable.id]);
  }
}

class RxVariable<T> {
  String id;
  T value;

  RxVariable({required this.id, required this.value});

  void updateValue(T updateValue) {
    value = updateValue;
  }
}