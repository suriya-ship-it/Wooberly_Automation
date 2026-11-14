library my_prj.globals;

import 'dart:async';


import 'package:camera/camera.dart';
import 'package:wooberly_driver/services/age_rating_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/app/model_theme.dart';
import 'package:wooberly_driver/models/currency_model.dart';

import '../controller/base_controller.dart';
import '../models/mobile_language.dart';
import '../resources/values/app_colors.dart';

String SOCKET_URL = 'https://demo.wooberly.com';
String GRAPHQL_DOMAIN = 'https://demo.wooberly.com/api/graphql';
String UPLOAD_URL = 'https://demo.wooberly.com/api';
String MAP_KEY = ""; //dev
String voicePlayUrl = UPLOAD_URL+"/images/audio/";
String dateFormatMMMDDYYYY = "MMM d, yyyy";
String timeFormatHHMMA = "hh:mm a";
String dateFormatYYYYMMDD = "yyyy-MM-dd";
String dateFormatMMMD = "MMM d";

String voiceUploadUrl = "${UPLOAD_URL}/transcription-to-text";
String voicePlayerUrl = "${UPLOAD_URL}/images/audio/";

String PLATFORM_NAME = 'Wooberly';
String APP_NAME = 'Wooberly Driver';
var stripePublishableKey = '';
double userLat = 0.0;
double userLon = 0.0;
String SECURE_API_KEY = 'x6Qbs<0]`Ed{Y{}WoA{oBro**]2V';
LatLng rideCompletedAt = LatLng(0.0, 0.0);
String CountryCode = "US";
String DialCode = "";
RxMap<dynamic, dynamic> rxFcmWalletOptions = {}.obs;
var rxExistController = ReactiveVariable("rxExistController", false);
BaseController baseController = BaseController();
String deviceName = "", deviceId = "", versionCode = "", brandName = "";
String? authToken, phnNo;
String distanceType = "km";
String? email, gender;
String userid = "";
int bookingId = 0;
String driverStatus = "";
bool isActive = false,
    isShowMapPage = false;
bool isDrawerOpen = false;
Socket? socket;
bool isRtlLang = false;

final ValueNotifier<Map<String,dynamic>> driverWalletOptionController = ValueNotifier<Map<String,dynamic>>({});

bool isVehicleDetailsReq = false;
bool isEnableOTP = false;

RxString preferredLanguage = "".obs;
String aiPreferredLanguage = "";
RxBool isRefreshTripPage = false.obs;

Gradient waveGradient = LinearGradient(
  end : isRtlLang ?Alignment.centerRight : Alignment.centerRight,
  begin: isRtlLang ?Alignment.centerLeft : Alignment.centerLeft,
  colors: [
    AppColors.VOICE_WAVEFORM_COLOR1,
    AppColors.VOICE_WAVEFORM_COLOR2,
  ],
) ;

bool isVoiceChatEnable = false;
bool isVoiceTranslatorEnable = false;
List<String> langCodeJson = [];
int voiceRecordingSec = 30;
Map<String, MobileLanguage> mobileLanguages = {};
Set<String> downloadedLanguages = Set();
String firstname = "",
    lastname = "",
    picture = "",
    preferredCurrency = "",
    currencySymbol = "",
    defaultLanguageCode = "en",
    defaultLanguageDisplayCode = "en";
String front = "", back = "", RC = "", Insurance = "";
int notificationInterval = 20;
String vehicleType = "",
    vehicleName = "",
    vehicleNumber = "",
    vehicleModel='',
    vehicleYear='',
    vehiclePhoto='',
    currencyRates = "",
    baseCurrency = "",
    autoCompleteUrl = "${UPLOAD_URL}/get_auto_complete_data",
    placeSearchUrl = "${UPLOAD_URL}/get_suggested_place_details",
    directionsUrl = "${UPLOAD_URL}/get_google_direction";
String vehicleColor = "";
BitmapDescriptor? categoryImage;
String vehicleImage = "";
String vehicleImagePath = "";
int vehicleId = 0, payout = 0, idVehicleToUpdate = 0;
bool reviewComplete = false;
bool isAlwaysAllowDenied = false;
bool isPayout = false, tripFromSocket = false;
var rxLoadingController = ReactiveVariable("rxLoadingController", 1);
final ValueNotifier<String> appLifecycleController = ValueNotifier<String>('');
bool
    isEnableContinuousLoading = false,
    isChildSeatAvailable = false,
    isWheelChairAvailable = false;
bool closeKeyboard = true;
List<int> paymentMethods = [];
String payPalCurrency = "";
String stripeConnectionUrl = "";
String stripeAccountId = "";
String currentShowingPage = "";
int requestTime = 0;
CameraController? cameraController;
dynamic uploadedImage = null;
int progressLoadTime = 20;
var theme = 0.obs;
var isAutoThemeUpdated = false.obs;
int locationFetchInterval = 20;
double polylineDrawDistance = 35;
dynamic tripInfo;
bool isLoaderShow = true;
bool showDistance = false, navigateToPayout = false,
    showDuration = false,
    showEstimatedFare = false,
    showLocations = false,
    showPickUpLocation = false,
    showDropLocation = false,
    isBringAppToForeGround = false,
    playTripSound = false,
    phoneNumberStatus = false;
String screenAwake = "", tripAudioURL = "";
AudioPlayer? audioPlayer;
String startRideRadius = "";
var addressUpdateController = false.obs;
var tripStatusChangedController = false.obs;
var showDialogController = {}.obs;
TextEditingController paypalCurrencyController = TextEditingController();
List paypalCurrencies = [];
var openChatFromNotificationController = 0.obs;
var cameraFilePath;
bool navigateToTripsPast = false;
bool isTripsPage = false;
CurrencyModel? currencyModel;
AgeRestrictionStatus ageStatus = AgeRestrictionStatus.declined;

String supportEmail = "", supportPhone = "", supportSkype = "",supportWhatsapp = "",loginTripStatus = '';
String appStoreURL = "", playStoreURL = "";
List<int> nameLength = [3, 50];
bool isDarkTheme = false;
ModelTheme? themeNotifier;
var currencyChanged = "".obs;

double markerImagePixelRatio = 2;