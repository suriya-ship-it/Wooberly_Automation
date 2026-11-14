import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/models/chat_models.dart';
import 'package:wooberly_driver/models/get_cancel_reason_model.dart';
import 'package:wooberly_driver/models/thread_items.dart';


import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/utils/map_utils.dart';
import 'package:wooberly_driver/utils/socket_connection.dart';
import 'package:wooberly_driver/widgets/closable_multi_part.dart';
import 'package:wooberly_driver/widgets/map_screen_widget/rider_review_transition_view.dart';

import '../../../app/app.dart';
import '../../../app/model_theme.dart';
import '../../../graphql/graphql_config.dart';
import '../../../models/ride_comfort_model.dart';
import '../../../resources/values/app_colors.dart';
import '../../../resources/values/app_images.dart';
import '../../../resources/values/app_lang.dart';
import '../../../views/map_main_screen.dart';
import '../../../widgets/audio_chat/chat_voice_mesaage_widget.dart';
import '../../../widgets/primary_scaffold.dart';
import 'package:http/http.dart' as http;

part 'graphql_fetch_on_controller.dart';
part 'location_fetch_on_controller.dart';
part 'map_markers_settings_on_controller.dart';
part 'mapkey_uses_on_controller.dart';
part 'polyline_fetch_on_controller.dart';
part 'ride_status_fetch_on_controller.dart';
part 'socket_extention_on_controller.dart';
part 'upload_voice_chat.dart';

class MapMainController extends BaseController {
  bool  isFromAdmin = false;
  late HomeViewState homeViewState;
  var rxShowToolTip = ReactiveVariable("rxShowToolTip", false);
  dynamic tripStatusResult;
  String? confirmationCode;
  var rxOnlineStatusController = false.obs;
  RxBool isRecording = true.obs;
  bool isVoiceChatLangSelectOpen = false;

  var rxIsPrivateController = ReactiveVariable("rxIsPrivateController", false);
  ScrollController controller = ScrollController();

  var rxFinalAmountController =
      ReactiveVariable("rxFinalAmountController", 0.0);
  var rxColorChangeController = ReactiveVariable("rxColorChangeController", 0);
  var rxEstimateAmountController =
      ReactiveVariable("rxEstimateAmountController", 0.0);
  var rxPictureChangeController =
      ReactiveVariable("rxPictureChangeController", false);
  GetCancelReasonModel? getCancelReasonModel;
  var rxUpdateBookingLocationController =
      ReactiveVariable("rxUpdateBookingLocationController", false);
  var rxCancelReasonListController =
      ReactiveVariable("rxCancelReasonListController", false);
  var rxRadioListSelectController =
      ReactiveVariable("rxRadioListSelectController", false);
  var rxRiderNameTextShownController =
      ReactiveVariable("rxRiderNameTextShownController", true);
  var rxOtherReasonSelectController =
      ReactiveVariable("rxOtherReasonSelectController", true);

  var rxMapLoadingController = ReactiveVariable("rxMapLoadingController", true);
  ALLThreads allThreadsResult = ALLThreads();
  GetAllThreadItems threadItems = GetAllThreadItems();
  int unreadCount = 0;
  var rxUnReadCountController = ReactiveVariable("rxUnReadCountController", 0);
  var chatController;
  BuildContext? scaffoldContext;
  late SocketConnection socketIns;
  var cancelReasonList = [];
  dynamic selectedCancelReason = [], otherCancelReason;
  var otherReasonController = TextEditingController();
  var tollFeeController = TextEditingController();
  RxBool isTripAcceptLoading = false.obs;
  String tripStatus = "";
  bool isDriverReviewed = true;
  int totalTrips = 0;
  int createdAt = 0;
  double totalTripAmount = 0.0;
  dynamic totalEarings = -1,
      rideDistance = 0.0,
      rideDuration = 0.0;

  dynamic zeroForAPISideDistanceMatrixCalculation = 0;
  TextEditingController rideConfirmOTPEntryController =
      TextEditingController(text: '');
  var rxRideConfirmOTPScreenStatusController = ReactiveVariable(
      "rxRideConfirmOTPScreenStatusController",
      RideConfirmOTPScreenStatus.InActive);

  var rxMapPaddingController = 0.0.obs;
  var rxUpdatePaddingController =
      ReactiveVariable("rxUpdatePaddingController", 0.0);
  List<ChatMessage> messages = [];
  List<LocationData> locationData = [];
  List<RideComfortModel> rideComfortData = <RideComfortModel>[];

  var rxRouteController = LatLng(0.0, 0.0).obs;
  var rxRideDetailEnabledController = false.obs;
  var rxSwipeStartController = ReactiveVariable("rxSwipeStartController", 0);
  var rxNavigationButtonstatus =
      ReactiveVariable("rxNavigationButtonstatus", -1);
  var rxStarRatingController = ReactiveVariable("rxStarRatingController", 0.0);
  var rxMessageUpdateController =
      ReactiveVariable("rxMessageUpdateController", true);
  var rxLoadingController =
      ReactiveVariable("rxMessageUpdateController", false);
  var rxOnlineStatus = ReactiveVariable("rxOnlineStatus", globals.isActive);
  var rxComfortExpandTileController =
      ReactiveVariable("rxComfortExpandTileController", false);
  var rxLoadTimerController = ReactiveVariable("rxLoadTimerController", false);
  var rxTripstartedResController =
      ReactiveVariable("rxTripstartedResController", false);
  var rxTotalDurationController =
      ReactiveVariable("rxTotalDurationController", "");
  var rxProfileInfoupdateController =
      ReactiveVariable("rxProfileInfoupdateController", false);
  var rxConfirmCancelTripScreenController = false.obs;
  var rxOnlineSliderController =
      ReactiveVariable("rxOnlineSliderController", false);

  var showLocationController = ValueNotifier<String>('');

  RxList<dynamic> getMobileLanguageList = [].obs;

  bool isAppResume = true,  isFromtrips = false;


  var rxPaymentType = ReactiveVariable("rxPaymentType", 1);

  double distanceBwStartDest = 0.0;
  MapUtils mapUtils = MapUtils();
  dynamic coordinatecurrentIndex;
  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  LatLng mapLocation = LatLng(0.0, 0.0),
      rideStartedAt = LatLng(0.0, 0.0),
      polylineoldLocation = LatLng(0.0, 0.0),
      rideEndedAt = LatLng(0.0, 0.0);
  LatLng oldCoordinate = LatLng(0.0, 0.0);
  List<LatLng> _oldCoordinates = [];
  int _isCalculatepoint = 0;
  String riderID = "",
      riderName = "",
      riderLoc = "",
      pickUpLoc = "",
      dropLoc = "",
      riderNumber = "",
      rideEndLoc = "",
      riderImage = "",
      paymentStatus = "";
  int? isCashPaid;
  int bookingID = 0;
  dynamic rating;
  dynamic totalDuration;
  double pickLat = 0.0, pickLon = 0.0, dropLat = 0.0, dropLng = 0.0;
  dynamic bookingType = 1;
  dynamic riderPhoto;
  String lastChatTime = "";
  List<dynamic> selectedComfortRide = [];
  double zoomLevel = 15.0;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId carMarker = MarkerId(""), _endingMarkerId = MarkerId("");
  Marker _endingMarker = Marker(markerId: MarkerId(""));
  LatLng polyinewaypoint = LatLng(0.0, 0.0);
  Polyline polylines = Polyline(polylineId: PolylineId(''));
  GoogleMapController? mapController;
  Timer? privacyTimer;
  bool riderinfoview = false;
  AnimationController? progressController;
  Timer? paymentSettingTimer;
  String previoustollamount = "";
  Animation<double>? tripRequestAnimation;
  String rideraiPrefLag ='';

  var numDeltas = 30;
  var delay = 33;
  int markerAnimationId = 0;
  double dist_MarkerPosToCurrentLoc = 0;
  int toForceCurrentLocation = 0;
  var markerMoveIteration = 0;
  bool _isNewPolylines = false;
  double deltaLat = 0.0;
  double deltaLng = 0.0;

  List<double>? position;
  double rotationbearing = 0.0;

  RxBool isPlayRecorded = false.obs;
  Timer? recordingTimer;
  RxInt recordingSeconds = 0.obs;
  RxBool resumeRecording = false.obs;
  String? recordingPath;
  AudioRecorder audioRecorder = AudioRecorder();
  List<String> recordingsegments = [];
  RxDouble recordingprogress = 0.0.obs;
  RxInt currentmilliSec = 0.obs;
  RxBool islocalDragging = false.obs;
  AudioPlayer recordedAudioPlayer = AudioPlayer();
  StreamSubscription? recordingpositionSubscription;
  StreamSubscription? recordingplayStateSubscription;
  StreamSubscription? rxRideDetailEnabledControllerSubscription;
  String? mergedPath;
  bool isMergeInprogress = false;

  int? currentlyPlayingIndex;
  List<bool> isPlaying = [];
  List<double> progress = [];
  List<int> totalMillis = [];
  List<int> currentMillis = [];
  AnimationController? chatAudioPlayingAnimController;
  Map<int,LockCachingAudioSource?> audioList = {};
  RxInt draggingIndex = 9999999.obs;
  AudioPlayerFunction? audioPlayerFunction;
  RxInt updateingIndex = 9999999.obs;
  AudioPlayer chatAudioPlayer = AudioPlayer();
  Timer? chatAudioPlayingTimer;
  RxBool voiceChatLoading = false.obs;
  RxBool isVoiceRecorderValue = false.obs;
  RxBool isTextEntered = false.obs;
  AnimationController? activePausePlayAnimation;
  late LinearGradient? blackLinearGradient ;

  @override
  void onInit() {
    mapLocation = LatLng(globals.userLat, globals.userLon);
    if (globals.userLat != 0.0 && globals.userLon != 0.0 && globals.categoryImage != null) {
      setMarkerprocess();
    }

    getBytesFromAsset(endingPointPng, 45).then((value) {
      _endingMarkerId = MarkerId("marker_id_2");
      BitmapDescriptor endMarkerIcon = BitmapDescriptor.bytes(value,
          imagePixelRatio: globals.markerImagePixelRatio);
      _endingMarker = Marker(
          markerId: _endingMarkerId,
          position: mapLocation,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: endMarkerIcon);
    });

    tollFeeController.addListener(() {
      String fname = tollFeeController.text.toString();
      if (fname.contains(".") && fname.split(".").length > 2)
        tollFeeController.text = previoustollamount;
      else
        previoustollamount = tollFeeController.text.toString();
    });

    loadComfortDatas();
    super.onInit();
  }

  resetRecordingProcess(){
    isRecording = false.obs;
    isPlayRecorded = false.obs;
    recordingTimer = null;
    recordingSeconds = 0.obs;
    resumeRecording = false.obs;
    recordingPath = null;
    audioRecorder = AudioRecorder();
    recordingsegments = [];
    recordingprogress = 0.0.obs;
    currentmilliSec = 0.obs;
    islocalDragging = false.obs;
    recordedAudioPlayer = AudioPlayer();
    recordingpositionSubscription = null;
    recordingplayStateSubscription = null;
    mergedPath = null;
    isMergeInprogress = false;
  }

  Future<File> downloadAudioFile({required String URL})async {
    String filename = URL.toString().split('/').last;
    final fileName = filename.contains('m4a') ? filename : '${filename}.m4a' ;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));

    if (!await file.exists()) {
      print("Downloading to cache...");
      final request = await HttpClient().getUrl(Uri.parse(URL));
      final response = await request.close();
      final bytes = await response.expand((chunk) => chunk).toList();

      await file.writeAsBytes(bytes);
    }
    return file;

  }

  void updateShowLocationController(String location) {
    showLocationController.value = location;
  }

  void loadComfortDatas() {
    rideComfortData.clear();
    rideComfortData.add(RideComfortModel(
        1, Women_driver.tr, womenonlySvg, false, false, false));
    rideComfortData.add(
        RideComfortModel(2, Child_seat.tr, childSeatSvg, false, false, false));
    rideComfortData.add(RideComfortModel(
        3, Wheel_chair.tr, wheelChairSvg, false, false, false));
  }

  setNavigationStatus(int status) {
    change(rxVariable: rxNavigationButtonstatus, value: status);
  }

  init() {
    getCurrencyRates();
    chatController = TextEditingController(text: "");
    otherReasonController = TextEditingController(text: "");
    otherReasonController.addListener(() {
      String value = otherReasonController.text.toString();
      if (value[0] == " ") otherReasonController.text = "";
      if (value[0] == "\n") otherReasonController.text = "";
    });
    App().appPreference.onlineStatus
        ? rxOnlineStatusController.value = true
        : rxOnlineStatusController.value = false;
  }


  void setStatus(bool status) {
    App().appPreference.onlineStatus = status;
    rxOnlineStatusController.value = status;
  }

  void setPrivateMode(bool mode) {
    mode
        ? {
            change(rxVariable: rxShowToolTip, value: true),
            startTimer(),
          }
        : {
            if (privacyTimer != null) privacyTimer?.cancel(),
            change(rxVariable: rxShowToolTip, value: false),
          };
    change(rxVariable: rxIsPrivateController, value: mode);
    App().appPreference.privateMode = mode;
  }

  bool isDriverAccept(){
    return (tripStatus == "approved" ||
        tripStatus == "started" ||
        tripStatus == "locationReached");
  }


  void getPrivateStatus() async {
    if (App().appPreference.privateMode) {
      change(rxVariable: rxIsPrivateController, value: true);
      startTimer();
    } else {
      change(rxVariable: rxIsPrivateController, value: false);
    }
  }



  void setSwipeStart(int swipekey) {
    change(rxVariable: rxSwipeStartController, value: swipekey);
  }

  void loadInitial() {
    setSwipeStart(1);
    setStarRatingController(0);
  }

  startTimer() {
    privacyTimer = new Timer(const Duration(milliseconds: 5000), () {
      change(rxVariable: rxShowToolTip, value: false);
    });
  }

  clearMap() {
    final point=StackTrace.current.toString().split('\n')[1];
    markers.remove(_endingMarkerId);
    polylines = Polyline(polylineId: PolylineId(''));
    if (mapUtils != null) {
      mapUtils.coordinates.clear();
      mapUtils.MarkerMovementcoordinates.clear();
    }
  }

  void setStarRatingController(double v) {
    change(rxVariable: rxStarRatingController, value: v);
  }

  Future<void> getDeviceDetails() async {
    try {
      if (Platform.isAndroid) {
        globals.deviceName = "android";
      } else if (Platform.isIOS) {
        globals.deviceName = "ios";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  void setLoadingController(bool param0) {
    change(rxVariable: rxLoadingController, value: param0);
  }

  Future<void> currentLocationUpdateInstant([dynamic isfromResume]) async {
    print("isFromResume ${isfromResume}");
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_currentLocationUpdateInstant ${point} --- ');
    try {
      if (globals.userLat == 0.0 && globals.userLon == 0.0) {
        await App().getNativeLocation();



        if (globals.userLat != 0.0 && globals.userLon != 0.0) {
          globals.rideCompletedAt = LatLng(globals.userLat, globals.userLon);
          List<Placemark> placemark = await geocoding.Geocoding().placemarkFromCoordinates(globals.userLat, globals.userLon,);
          Placemark first = placemark[0];
          getInitialLocation(9);
          if (globals.currentShowingPage != AppRoutes.APP_OTP_VERIFY) {
            globals.CountryCode = first.isoCountryCode!;
            globals.addressUpdateController.value = true;
          }
        }
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
  Future<void> openMap(
      double currLat, double currLong, double destLat, double destLong) async {
    if (Platform.isAndroid) {
      String googleUrl =
          "https://www.google.com/maps/dir/?api=1&origin=$currLat,$currLong&destination=$destLat,$destLong&travelmode=driving&dir_action=navigate";
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open the map.';
      }
    } else if (Platform.isIOS) {
      String googleUrl =
          "comgooglemaps://?saddr=$currLat,$currLong&daddr=$destLat,$destLong&directionsmode=driving";
      bool mapCheck = await canLaunchUrl(Uri.parse(googleUrl));
      if (mapCheck) {
        await launchUrl(Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication);
      } else {
        String iosUrl =
            "http://maps.apple.com/?saddr=$currLat,$currLong&daddr=$destLat,$destLong";
        if (await canLaunchUrl(Uri.parse(iosUrl))) {
          await launchUrl(Uri.parse(iosUrl),
              mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not open the map.';
        }
      }
    }
  }

  void onCameraMove(CameraPosition position) {
    if (position.zoom > 5.0 && mapLocation.latitude != 0.0 &&
        mapLocation.longitude != 0.0) {
      zoomLevel = position.zoom;
    }
  }

  String socketFormatDate(String dateMilliseconds) {
    if (dateMilliseconds != "") {
      var dateFormat = DateFormat(
              "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", globals.defaultLanguageCode)
          .parse(dateMilliseconds, true);
      var formattedDateTime =
          DateFormat("hh:mm a").format(dateFormat.toLocal());
      return formattedDateTime;
    } else {
      return "";
    }
  }

  Future<String> deleteUser() async {
    try {
      Map<String, dynamic>? status_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "deleteUser_mutation",
              null);
      if (status_result?["deleteUser"]["status"] == 200) {
        return "";
      } else if (status_result?["deleteUser"]["status"] == 400) {
        return status_result?["deleteUser"]["errorMessage"];
      } else {
        return "timeout";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<String> getAllLanguage() async {
    Map<String, dynamic>? _language_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClient, "getAllMobileLanguage", null);
    if (_language_result != null) {
      if (_language_result["getAllMobileLanguage"]["status"] == 200) {
        getMobileLanguageList.value = _language_result["getAllMobileLanguage"]["results"];
        return "";
      } else
      if (_language_result["getAllMobileLanguage"]["status"] == 400) {
        return _language_result["getAllMobileLanguage"]["errorMessage"];
      } else {
        return "timeout";
      }
    } else {
      return "offline";
    }
  }

  Future<String> confirmCashPayment() async {
    try {
      var variables = <String, dynamic>{
        "bookingId": bookingID,
      };
      Map<String, dynamic>? status_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "confirmCashPayment_mutation",
              variables);
      if (status_result != null) {
        if (status_result["confirmCashPayment"]["status"] == 200) {
          return "";
        } else if (status_result["confirmCashPayment"]["status"] == 400) {
          return status_result["confirmCashPayment"]["errorMessage"];
        } else {
          return "timeout";
        }
      } else {
        return "offline";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  updateMapPaddingController(double height) {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_rxMapPaddingController ${point} --- ');
    debugPrint("rxMapPaddingController 1: ${height}");
    rxMapPaddingController.value = height;
  }

  showLocationPermissionAlert( String AlertMessage, bool isLocationDisabled, {String? permissionType}) {
    Get.dialog(
      barrierDismissible: false,
        PopScope(
      canPop: false,
      child: Consumer<ModelTheme>(
          builder: (context, ModelTheme themeNotifier, child) {
            return AlertDialog(
                backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                content: Text(AlertMessage, style: TextStyle(color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text('cancel_label'.tr,
                        style: TextStyle(color: AppColors.TEXT_LINK_COLOR)),
                  ),
                  TextButton(
                    onPressed: () {
                      if(permissionType == null) {
                        if (isLocationDisabled) {
                          App().openLocationSettings();
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
                    child: Text('Go_to_settings'.tr,
                        style: TextStyle(color: AppColors.TEXT_LINK_COLOR)),
                  )
                ]);
          }
      ),
    ));
  }

  setDriverStatus(bool driverStatus) {
    final point = StackTrace.current.toString().split('\n')[1];
    print('test9_setDriverStatus ${point} --- ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tripStatus == "approved" ||
          tripStatus == "started" ||
          tripStatus == "locationReached" ||
          tripStatus == "created") {
        change(rxVariable: rxOnlineStatus, value: true);
        globals.isActive = true;
      } else {
        checkLocationAndSetOnlineStatus(driverStatus);
      }
    });
  }

  Future<void> checkLocationAndSetOnlineStatus(bool driverStatus) async {
    // 1. Ensure location service (GPS) is enabled
    bool isLocationEnabled = await App().isLocationServiceEnable();

    if (!isLocationEnabled) {
      bool systemLocationEnabled = await App().EnableLocationService();
      if (!systemLocationEnabled) {
        _setOffline();
        return;
      }

      // re-check after prompting the system dialog
      isLocationEnabled = await App().isLocationServiceEnable();
      if (!isLocationEnabled) {
        _setOffline();
        return;
      }
    }

    // 2. Check/request platform-specific permission
    final bool hasPermission = await _hasLocationPermission();

    if (hasPermission) {
      change(rxVariable: rxOnlineStatus, value: driverStatus);
    } else {
      _setOffline();
    }
  }

  /// Handles the Android vs iOS permission difference in one place.
  Future<bool> _hasLocationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationAlways.status;
      return status == PermissionStatus.granted;
    } else {
      final status = await Permission.location.request();
      return status.isGranted;
    }
  }

  void _setOffline() {
    globals.isActive = false;
    change(rxVariable: rxOnlineStatus, value: false);
  }
}

enum RideConfirmOTPScreenStatus { Active, InActive, Loading }