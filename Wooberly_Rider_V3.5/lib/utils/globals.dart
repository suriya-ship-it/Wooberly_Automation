library my_prj.globals;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/interfaces/change_payment_type.dart';
import 'package:app_name/models/currency_model.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/services/age_rating_service.dart';
import 'package:app_name/utils/google_map.dart';

import '../app/enums/button_state.dart';
import '../models/mobile_language.dart';



String SOCKET_URL = 'SOCKET_URL';
String GRAPHQL_DOMAIN = 'GRAPHQL_DOMAIN';
String UPLOAD_URL = 'UPLOAD_URL';
String MAP_KEY = ""; //dev

String SecurityKey = "x6Qbs<0]`Ed{Y{}WoA{oBro**]2V";
String APP_NAME = 'APP_NAME';
String GOOGLE_PAY_MERCHANT_ORGANIZATION = 'GOOGLE_PAY_MERCHANT_ORGANIZATION';
String GOOGLE_PAY_MERCHANT_ID = 'GOOGLE_PAY_MERCHANT_ID';

var stripePublishableKey = '';

double userLat = 0.0;
double userLon = 0.0;
String CountryCode = "US";
String DialCode = "";

 const int maxStops = 2;
double notificationInterval = 20;

String deviceName = "", deviceId = "", versionCode = "";
String? authToken, phoneNumber;
String dateFormat = 'yyyy-MM-dd';
String dateTimeFormat = '${dateFormat} HH:mm:ss.SSS';
String scheduleDateFormat = "EEE, MMM d";
String scheduleRideDateFormat = "E, MMM dd";
String scheduleTimeFormat = "hh:mm a";
String scheduleRideTimeFormat = "hh:mm aa";

Map<SelectLocationEnum, SelectLocationModel> favoriteLocationMap = {};
List<SelectLocationEnum> favoriteLocationEnumList = [
  SelectLocationEnum.homeLocation,
  SelectLocationEnum.workLocation
];


String? email, userid, gender;
bool isShowMapPage = false;
bool isDrawerOpen = false, refreshApp = false;

Socket? socket;
String distanceType = "km";
bool fcmConfigured = false;
bool isEnableOTP = false;
bool isVoiceChatEnable = false;
bool isVoiceTranslatorEnable = false;
bool isCreatedTrip = false;
int scheduleRestrictionTime = 20;
int? theme;
bool navigateToTripsPast = false;
List<EmergencyContacts> contacts = [];
RxString firstname = "".obs, lastname = "".obs, picture = "".obs;
int promoNotificationClick = 0;

String preferredCurrency = "",
    preferredLanguage = "",
    aiPreferredLanguage = "",
    currencySymbol = "",
    currencyRates = "",
    defaultLanguageCode = "en",
    defaultLanguageDisplayCode = "Eng";
String tripStatus = "";
RxString currentLocation = "".obs;
int preferredPaymentMethod = 0;
RxDouble walletBalance = 0.0.obs;
dynamic cardLastFour = 0;
dynamic uploadedImage = null;
bool closeKeyBoard = true;
bool bookingPaymentType = false;
bool isContinuousLoading = false, isLoaderShow = true;
changePayment_and_Backnav_Interface? changePayment_and_Backnav;
RxList<int>? paymentMethods = <int>[].obs;

String checkNavWallet = "";
int LocationFetchInterval = 15;
bool isRTLLang = false,
    isPromoForCategory = false,
    phoneNumberStatus = false;
String checkNavPaymentType = "";
RxString tripStatusChangedController = ''.obs;
RxBool setLocationController = false.obs;
var buttonState = ButtonState.idle.obs;

void setButtonLoading() => buttonState.value = ButtonState.loading;

void setButtonIdle() => buttonState.value = ButtonState.idle;

void setButtonDisabled() => buttonState.value = ButtonState.disabled;
RxInt selectedPaymentType = 0.obs;
RxBool locController = true.obs;
String multipleStopWaitingTime = "0";
Rx<dynamic> openChatFromNotificationController = ''.obs;
CurrencyModel? currencyModel;
String appstoreLink = "", playStoreLink = "";
List<int> nameLength = [3, 50];
bool isCurrentPassword = false;
BaseController baseController = Get.find();
List<String> langCodeJson = [];
Map<String, MobileLanguage> mobileLanguages = {};
Set<String> downloadedLanguages = Set();
List<int> namelength = [3, 50];
ModelTheme? themeNotifier;
List<Map<String, String>> locationList = [];
Map<String, dynamic> placeDetails = {};

String supportEmail = "",
    supportPhone = "",
    supportWhatsapp = "",
     autoCompleteUrl = "${UPLOAD_URL}/get_auto_complete_data",
    placeSearchUrl = "${UPLOAD_URL}/get_suggested_place_details",
    directionsUrl = "${UPLOAD_URL}/get_google_direction";
String voiceUploadUrl = "${UPLOAD_URL}/transcription-to-text";
String voicePlayUrl = UPLOAD_URL + "/images/audio/";
bool isDarkTheme = false;
Map<String, dynamic>? precautionNotifications;
bool isLocationScreen = false;
RxBool mapEnableController = true.obs;
var languageUpdateController = false.obs;
var paypalCurrencyController = TextEditingController();
List<String> paypalCurrencies = [];
double markerImagePixelRatio = 2;
int voiceRecordingSec = 30;
double polylineDrawDistance = 35;
RxBool placeSearchingController = false.obs;
late Gradient waveGradient;
AgeRestrictionStatus ageStatus = AgeRestrictionStatus.declined;

 const Map<String, ({String translationKey, Color color})> statusConfig = {
  "created": (translationKey: 'trip_created', color: AppColors.TRIP_CREATED),
  "approved": (translationKey: 'trip_approved', color: AppColors.COMPLETE_COLOR),
  "declined": (translationKey: 'trip_declined', color: AppColors.EXCEPTION_COLOR),
  "started": (translationKey: 'trip_started', color: AppColors.TRIP_STARTED),
  "cancelledByRider": (translationKey: 'cancelledByRider', color: AppColors.EXCEPTION_COLOR),
  "cancelledByDriver": (translationKey: 'cancelledByDriver', color: AppColors.EXCEPTION_COLOR),
  "completed": (translationKey: 'trip_completed', color: AppColors.COMPLETE_COLOR),
  "expired": (translationKey: 'failed', color: AppColors.EXCEPTION_COLOR),
  "scheduled": (translationKey: 'scheduled', color: AppColors.COMPLETE_COLOR),
  "locationReached": (translationKey: 'trip_reached', color: AppColors.TRIP_REACHED),
};