import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';

import '../app/app.dart';
import '../app/app_routes.dart';
import '../graphql/graphql_config.dart';
import '../models/currency_model.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart' as lang;
import '../utils/globals.dart' as globals;
import 'dart:ui' as ui;

import '../utils/globals.dart' hide App;
import '../widgets/blinking_toast.dart';

class BaseController extends FullLifeCycleController with FullLifeCycleMixin implements DisposableInterface {
  Toast toast = new Toast();

  late Directory appDocumentsDir;

  int AILangListCurrentPage = 1,AILanglistCount=0;
  RxList<Map<String,String>> AILanglist = <Map<String,String>>[].obs;

  String offlineMessageContent = 'offline_text'.tr =='offline_text' ? "You are currently offline" : 'offline_text'.tr;
  String retryContent = 'retry'.tr == 'retry'? "Retry": "retry".tr;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  BaseController() {
    initConnectivityListener();
  }

  void initConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool hasConnection = !results.contains(ConnectivityResult.none) && results.isNotEmpty;
      if (hasConnection) {
        if (globals.socket == null || !(globals.socket?.connected ?? false)) {
          debugPrint("Network connected/changed: Reconnecting socket...");
          App().reconnectSocket();
        }
      }
    });
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {
    debugPrint("socket event: ${globals.socket?.disconnected} --- ${globals.socket?.connected}");
    if (!(globals.socket?.connected ?? false)) {
      App().reconnectSocket();
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }else{
        return true;
      }
    } on PlatformException catch (e) {
      return false;
    }

  }

  Future<bool> isLocationPermissionsEnabled() async{

    bool isLocationServiceEnable = await App().isLocationServiceEnable();
    if(!isLocationServiceEnable) return false;

    Permission locationPermission = Platform.isAndroid
        ? Permission.location
        : Permission.locationWhenInUse;

    PermissionStatus locationStatus = await locationPermission.status;
    if(locationStatus != PermissionStatus.granted) return false;

    PermissionStatus locationAlwaysStatus = await Permission.locationAlways.status;
      isAlwaysAllowDenied = true;
      if(locationAlwaysStatus != PermissionStatus.granted) return false;
      isAlwaysAllowDenied = false;

    return true;
  }

     getCountryCode() async {
    try {
      // Make the HTTP GET request to the IP API
      final url = Uri.parse('http://ip-api.com/json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Decode the JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        globals.CountryCode = data['countryCode'];
      } else {
        print('Failed to load country data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching country code: $e');
      return null;
    }
  }

  void showInSnackBar(String value) {
    Get.closeCurrentSnackbar();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Get.showSnackbar(
        GetSnackBar(
          margin: EdgeInsets.symmetric(vertical: Get.height * 0.02, horizontal: Get.width * 0.04),
          animationDuration: Duration(milliseconds: 0),
          borderRadius: 4,
          backgroundColor: Colors.black,
          messageText: Text(value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: AppDimen.text_size_14,
            ),
          ),
          duration: const Duration(seconds: 5),
        )
    );
  }

  Future<File> getDownloadedFile({required String url, required String lang, isUpdate = false}) async {
    String filename = url.split("/").last;
    appDocumentsDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocumentsDir.path}/$filename';
    File file = File(filePath);
    http.Response response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
    downloadedLanguages.add(lang);
    App().appPreference.downloadedLanguages = downloadedLanguages.join(',');
    return file;
  }

  Widget getBackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
      child: SizedBox(
        width: 12,
        height: 21,
        child: RotatedBox(
          quarterTurns: globals.isRtlLang ? 2:0,
          child: SvgPicture.asset(
            primaryLeftArrow,
            fit: BoxFit.scaleDown,
            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Future<void> getUserAILanguage({bool? isShowLoader}) async {
    if(isShowLoader !=null)
      globals.isLoaderShow = isShowLoader;
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "getCurrentAILanguage_query",
        null);
    if (_login_result != null) {
      if (_login_result["userAccount"]["status"] == 200) {
        globals.aiPreferredLanguage = _login_result["userAccount"]["result"]["aiPreferredLanguage"];
        globals.preferredCurrency = _login_result["userAccount"]["result"]["preferredCurrency"];
        NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
        globals.currencySymbol = _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
        globals.currencySymbol = getCurrencySybmol(
            globals.preferredCurrency, globals.currencySymbol);
      }
    }
  }

  Future<String> getAILanguageList({bool? isShowLoader}) async {
    if(isShowLoader !=null)
      globals.isLoaderShow = isShowLoader;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "currentPage": AILangListCurrentPage,
    };

    Map<String, dynamic>? _langlistResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getAllMobileLanguage", variables);

    if (_langlistResult != null && _langlistResult["getAllMobileLanguage"]["status"] == 200) {
      AILanglistCount =_langlistResult["getAllMobileLanguage"]['count'];
      var results = _langlistResult["getAllMobileLanguage"]['results'] as List;

      if(AILangListCurrentPage == 1){
        AILanglist.clear();
      }
      for(Map<String, dynamic> item in results){
        if(item['isAIPreferredLanguage']){
          AILanglist.add({
            'language': item['language'] as String,
            'languageCode': item['languageCode'] as String,
          });
        }
      }
      AILanglist.refresh();
      return '';
    } else {
      return _langlistResult !=null ?_langlistResult["getAllMobileLanguage"]["errorMessage"] : 'offline';
    }
  }


  Future<bool> checkInternet(Function verify, bool? toastShow) async {
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_checkInternet ${point} --- ');
    bool internetConnect = await checkConnectivity();
    if (internetConnect != null && internetConnect) {
      verify();
    } else {
      if (toastShow == null) {
      } else if (toastShow) {
        toast.show(
          context: Get.overlayContext!,
          message: offlineMessageContent,
        );
      } else {
        netOffSnackbar(verify, toastShow);
      }
    }
    return Future.value(internetConnect);
  }

  closeMessage(BuildContext context) {
    if (globals.closeKeyboard) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      globals.closeKeyboard = true;
    }
  }

  Future<String> updateAILanguage(String fieldName, String fieldValue) async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };
debugPrint("updateAILanguage: ${variables}");
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
    debugPrint("updateAILanguage: result: ${_login_result}");
    if (_login_result != null) {
      if (_login_result["userUpdate"]["status"] == 200) {
        return "";
      } else if (_login_result["userUpdate"]["status"] == 500) {
        setLogout(Get.context!);
        return "timeout";
      } else {
        return _login_result["userUpdate"]["errorMessage"];
      }
    } else
      return "offline";
  }

  getProgressIndicator(BuildContext context, Color color,
      {String loader = ""}) {

    if (globals.currentShowingPage != AppRoutes.APP_CHAT) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    return new SizedBox(
      width: Get.width,
      height: Get.height,
      child: new Center(
        child: new ClipRect(
          child: new SizedBox(
            width: 100,
            height: 100,
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                child: Lottie.asset(loader.isNotEmpty
                    ? loader
                    : globals.isDarkTheme
                    ? 'assets/lottieloader_dark.json'
                    : 'assets/lottieloader.json'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void netOffSnackbar(Function verify, bool toastShow) {
    Get.showSnackbar(
      GetSnackBar(
        isDismissible: false,
        animationDuration: Duration(seconds: 1),
        backgroundColor: Colors.black,
        messageText: Text(
          offlineMessageContent,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            checkInternet(verify, toastShow);
          },
          child: Text(
            retryContent,
            style: TextStyle(color: AppColors.PRIMARY_COLOR_WHITE),
          ),
        ),
        duration: Duration(hours: 1),
        onTap: (snack) {
          Future.delayed(Duration(hours: 1), () {
            if (snack.isDismissible) {
              netOffSnackbar(verify, toastShow);
            }
          });
        },
      ),
    );
  }

  String getCurrencySybmol(String currency, String symbol) {
      if (currency == "MXN") {
        return "MX\$";
      } else if (currency == "HKD") {
        return "HK\$";
      } else if (currency == "NZD") {
        return "NZ\$";
      } else if (currency == "CNY") {
        return "CN\$";
      } else if (currency == "AUD") {
        return "A\$";
      } else if (currency == "CAD") {
        return "CA\$";
      }
      var format = NumberFormat.simpleCurrency(name: currency);
      return format.currencySymbol;
  }

  String getMinCheck(String minute) {
    String minutes = minute.isNotEmpty ? minute : '1';
    if ((lang.minOne.isEmpty||lang.minPOther.isEmpty) && minutes.isNotEmpty) {
      return ((double.parse(minutes.toString()).round() > 1) ? "mins" : "min");
    } else {
      return (double.parse(minutes.toString()).round() > 1)?lang.minPOther.tr:lang.minOne.tr;
    }
  }

  String getHoursCheck(String hours) {
    if (
    (lang.hourOne.isEmpty||lang.hourPOther.isEmpty) && hours.isNotEmpty) {
      return ((double.parse(hours.toString()).round() > 1) ? "hours" : "hour");
    } else {
      return (double.parse(hours.toString()).round() > 1)?lang.hourPOther.tr: lang.hourOne.tr;
    }
  }

  void setLogout(BuildContext context) {
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_setLogout ${point} --- ');
    if ((globals.authToken?.isNotEmpty ?? false) && globals.front.isNotEmpty) {
      globals.driverStatus = "";
      MapMainController mapMainController = Get.find();
      mapMainController.tripStatus = '';
      mapMainController.clearMap();
      mapMainController.markers.clear();
      mapMainController.rxRideDetailEnabledControllerSubscription?.cancel();
      globals.aiPreferredLanguage = "";
      globals.isVehicleDetailsReq = false;
      App().setTripInfo_IOS("", "");
      App().setBgLocationInfo_IOS("", "", "");
      App().stopRequestAudio();
      try {
        globals.socket?.clearListeners();
        globals.socket?.disconnect();
        globals.socket?.dispose();
      } catch (_) {}
      globals.socket = null;
      globals.tripInfo = "";
      globals.tripFromSocket = false;

      App().userLogout().then((result) {
        debugPrint("userLogout: ${result} -- ${globals.userid}");
        if (result != "offline") {
          globals.authToken = "";
          globals.userid = "";
          App().removeUserCache(context);
        } else {
          netOffSnackbar(setLogout, false);

        }
      });
    }
  }

  String getRate(String from, dynamic amount) {
    Map<String, dynamic> currencyObject = jsonDecode(globals.currencyRates);
    if (!currencyObject.containsKey(globals.preferredCurrency) ||
        !currencyObject.containsKey(from)) {
      return "Currency not found in Currency rates";
    }
    dynamic rate = currencyObject[globals.preferredCurrency];
    return (rate * (1 / currencyObject[from]) * amount).toString();
  }

  void snackBarwithAction(String value, Function() listenForPermissionStatus) {
    Get.showSnackbar(GetSnackBar(
      backgroundColor: Colors.black,
      isDismissible: false,
      messageText: Text(value,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w300,
          fontSize: AppDimen.text_size_14,
          fontFamily: AppFont.font,
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          listenForPermissionStatus();
        },
        child: Text(
          lang.retry.tr,
          style: TextStyle(color: AppColors.PRIMARY_COLOR_WHITE),
        ),
      ),
      duration: Duration(hours: 1),
    ));
  }

  Future<void>? getDeviceDetails() {
    try {
      if (Platform.isAndroid) {
        globals.deviceName = "android";
      } else if (Platform.isIOS) {
        globals.deviceName = "ios";
      }
    }  on Exception catch (e, stack) {
      debugPrint("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Map<String, dynamic> getDateTimeValue(
      [Map<String, dynamic>? dateTimeValue, DateTime? now]) {
    if (dateTimeValue == null) dateTimeValue = Map<String, dynamic>();
    if (now == null) now = DateTime.now();
    final DateFormat formatter = DateFormat(dateFormatYYYYMMDD, 'en_US');
    final String dateValue = formatter.format(now);
    final String dayValue = DateFormat('EEEE', 'en_US').format(now);
    final String startTimeValue = "${now.hour}.${now.minute}";
    dateTimeValue["dateValue"] = dateValue;
    dateTimeValue["dayValue"] = dayValue;
    dateTimeValue["startTimeValue"] = startTimeValue;

    return dateTimeValue;
  }

  change<T>({required ReactiveVariable rxVariable, required T value}) {
    rxVariable.updateValue(value);
    update([rxVariable.id]);
  }
  getCurrencyList() async {
    CurrencyModel currencyModel;
    Map<String, dynamic>? _currency_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getAllCurrencies_query", null);
    if(_currency_result !=null) {
      currencyModel = CurrencyModel.fromJson(_currency_result);
      if (currencyModel.getAllCurrencies?.status?.compareTo("200") == 0) {
        List<CurrencyResults> result = currencyModel.getAllCurrencies?.results ?? [];
        result.forEach((element) {
          if(element.isPayment == true){
            if(element.symbol != null)
              globals.paypalCurrencies.add(element.symbol);
          }
        });
      }
    }
  }
}


class ReactiveVariable<T> {
  final String id; // Variable ID
  T value; // Mutable Value

  ReactiveVariable(this.id, this.value);

  void updateValue(T newValue) {
    value = newValue;
  }
}