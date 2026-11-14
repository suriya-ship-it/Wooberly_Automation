import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:ui' as ui;
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/controllers/edit_account_controller.dart';
import 'package:app_name/services/firebase_service.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/chat_model.dart';
import 'package:app_name/models/get_cancel_reason_model.dart';
import 'package:app_name/models/get_promo_code_model.dart';
import 'package:app_name/models/ride_comfort_model.dart';
import 'package:app_name/models/thread_items.dart';
import 'package:app_name/models/trip_calculation_model.dart'
    as tripCalculeModel;
import 'package:app_name/models/vehicle_type_model.dart' as vehicleModel;
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/utils/socket_connection.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/views/booking_instructions.dart';
import 'package:app_name/views/confirm_schedule_ride.dart';
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/widgets/audio_chat/chat_voice_mesaage_widget.dart';
import 'package:app_name/widgets/closable_multi_part.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import '../../app/app.dart';
import '../../app/model_theme.dart';
import '../../models/get_driver_wiht_category_price.dart';
import '../../models/nearest_drivers_category_model.dart';
import '../../models/select_location_model.dart';
import '../../resources/values/app_images.dart';
import '../../utils/globals.dart';
import '../../views/show_tips.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/select_drop_location/location_input_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
part 'package:app_name/controllers/map_main_controller/map_main_api.dart';
part 'package:app_name/controllers/map_main_controller/map_main_core.dart';
part 'package:app_name/controllers/map_main_controller/map_main_core_part2.dart';
part 'package:app_name/controllers/map_main_controller/map_main_core_part3.dart';
part 'package:app_name/controllers/map_main_controller/map_main_socket.dart';
part 'package:app_name/controllers/map_main_controller/map_main_socket_part2.dart';
part 'package:app_name/controllers/map_main_controller/map_main_transition.dart';
part 'package:app_name/controllers/map_main_controller/map_main_utils.dart';
part 'package:app_name/controllers/map_main_controller/upload_voice_chat.dart';

class MapMainController extends BaseController{
  static MapMainController? _instance;
  refreshControllerIF? refreshControl;

  dynamic  requestExpiredTimer;
  bool reloadMap = true;

  bool _updateTipsCalled = false;
  bool calledOnce = true;
  bool backCancelReason = false;
  bool netOff = true;
  bool ismultistopvia = false;
  bool isCabAvailable = false;
  bool mapLoading = true;
  bool isFromtrips = false;
  LatLng? driverOldLoc;
  RxBool mapRefreshController = true.obs;
  dynamic coordinatecurrentIndex;
  String mapStyle = "", darkmapStyle = "";
  String payStackRef = "", payStackURL = "",payPalURL='';
  double driverInfoHeight = 0.0;
  Animation<Offset>? confirmOffset,
      connectOffset,
      destLocOffset,
      rideConfirmOTPOffset,
      tripAmountOffset,
      vehicleCatDetailOffset,
      tripSharedOffset,
      sosIconOffset,
      rideTypeSelectionOffset;
  AnimationController?
  destLocAnimController,
      rideConfirmOTPAnimController,
      confirmPopupAnimController,
      connectAnimController,
      sosIconController,
      tripAmountController;

  AnimationController? vehicleCatAnimController,
      vehicleCatDetailAnimController,
      driverInfoAnimController,
      rideCancelledAnimController,
      rideTypeSelectionAnimController;
  Animation<Offset>? vehicleCatOffset,
      driverInfoOffset,
      rideCancelledOffset;

  AppPreferences? appPreferences=AppPreferences();
  LatLng lastKnownLocation = LatLng(0.0, 0.0);
  int rideCurrency = 0;
  dynamic driverRating = 0.0;
  RxDouble mapPaddingController = 0.0.obs;
  RxBool isScheduleRideTripSelected = false.obs;
  RxInt colorChangeController = 0.obs;
  var selectedBookingType = RxVariable(id: 'selectedBookingType', value: 1);
  var couponController = TextEditingController();
  var searchPromoController = TextEditingController();
  List<ResultPromo>? promoResults;
  var otherReasonController = TextEditingController();
  var chatController = TextEditingController();
  List<LocationData> locationData = [];
  List<dynamic> apiLocationData = [];
  bool isFromAdmin = false;
  int  EditDisableLocationsDataIndex = 0;
  List<ChatMessage> messages = [];
  ScrollController controller = ScrollController();
  RxBool updateHomeMapController = false.obs;
  Map<MarkerId, Marker> HomeMarkersMap = <MarkerId, Marker>{};
  ConfirmScheduleRideIF? confirmScheduleRideIF;
  BookingInstructionIF? bookingInstructionIF;
  bool isScheduleRideIconEnable = false;
  String _initialAddress = "", estimatedScheduleAmount = "";
  ALLThreads? allThreadsResult;
  SocketConnection? socketIns;
  GetAllThreadItems? threadItems;
  DateTime? selScheduleFromDateTime;
  DateTime? selScheduleToDateTime;
  bool isHomeScreen = false;
  int unreadCount = 0;
  List<dynamic> cancelReasonList = [];
  dynamic selectedCancelReason = [],
      otherCancelReason,
      finalAmount,
      tripFinalAmount;
  double vehicleCatHeight = 0.0;
  bool isScheduleRide = false;
  bool isFromSchedule = false;
  bool isVehicleCatDetailOpen = false;
  bool isScheduleRideConfirmed = false;
  RxBool comfortExpandTileController = false.obs;
  var screenController = RxVariable(id: 'screenController', value: false);
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RxBool? closeCancelTripController = false.obs;
  RxBool closeMultipleStopSearchPageController = false.obs;
  var locationFetchController = ValueNotifier<bool>(false);
  var routeController = StreamController<LatLng>.broadcast();
  String? addressController;

  var rideStartedController =false.obs;
  var cancelReasonListController = RxVariable(id: 'cancelReasonListController', value: false);
  var radioListSelectController = RxVariable(id: 'radioListSelectController', value: false);
  var otherReasonSelectController = RxVariable(id: 'otherReasonSelectController', value: true);
  RxDouble starRatingController = 0.0.obs;
  var totalFareController = 0.0.obs;
  var selectedCabController = ValueNotifier<int>(0);
  RxInt rideNowLoadingController = 1.obs;
  RxInt cancelRequestLoadingController = 1.obs;
  RxString destPlaceController = ''.obs;
  RxString selectedPlace = ''.obs;
  var driverAvailController = true.obs;
  var SOSavailController = RxVariable(id: 'SOSavailController', value: false);
  var SOSLoadingController = RxVariable(id: 'SOSLoadingController', value: false);

  var RouteDrawController = 0.obs;
  var promoStreamController =false.obs;

  var connectingCancelController = RxVariable(id: 'connectingCancelController', value: true);
  RxBool scheduleRideScreenController = false.obs;
  RxBool confirmCancelTripScreenController = false.obs;
  RxBool mapLoadingController = true.obs;
  RxBool bookingInstructionController = false.obs;
  var rideComfortController =RxVariable(id: 'rideComfortController', value: false);
  RxBool scheduleRideBookingInstruction = false.obs;
  RxBool scheduleRideIconController = false.obs;
  RxInt rideConfirmOTPController = 0.obs;
  RxBool promoListController = false.obs;
  var isLoading;
  dynamic zeroForAPISideDistanceMatrixCalculation = 0;

  AnimationController? tripSharedController;
  RxDouble finalAmountController = 0.0.obs;
  var tipsAmount = TextEditingController();
  RxInt paymentStatusController =0.obs;
  RxMap<String,dynamic> vehCatDetailController = <String,dynamic>{}.obs;
  RxBool schedulingRideController = true.obs;

  List<Permission> permission = [Permission.location];
  bool isSpecialApplied = false;
  String appliedCoupon = "", isFromForSettings = "";
  dynamic selectedSpecialID;
  MapUtils? mapUtils;
  bool isFromAppResume = false;
  var deltaLat;
  var deltaLng;
  var numDeltas = 10;
  var delay = 60;
  int markerAnimationId = 0;
  List<double> position = [];
  double? dist_MarkerPosToCurrentLoc;
  String strServiceUnavailable = "";
  var markerMoveIteration = 0;

  double zoomLevel = 3.0;
  Map<MarkerId, Marker> markersMap = <MarkerId, Marker>{};
  Polyline polyLines = Polyline(polylineId: PolylineId(''));
  dynamic oldCoordinate;
  List<LatLng> _oldCoordinates = [];
  bool _isNewPolylines = false;
  int toForceCurrentLocation = 0;
  int _isCalculatepoint = 0;

  bool _isCompleteMarkerMovement = true;
  List<MarkerId> _vehicleCatMarkerIds = [];
  GoogleMapController? mapController;
  Completer<GoogleMapController> mapControllerCompleter = Completer();

  BitmapDescriptor? pickupIcon,
      destIcon,
      currentLocPin,
      selectedCatIcon,
      stopLocIcon;
   double bearing = 0;
  String? _vehiclemarkerimg;
  int selectedCatId = 0;
  bool isSelectMapLocation = false;
  GetPromoCodeModel? promoList;
  GetCancelReasonModel? getCancelReasonModel;
  String driverName = "", driverId = "", driverVehNum = "";
  dynamic driverPhone, expDate;
  int? bookingPaymentType;
  bool isInitialGetTripStatusLoading = true;
  vehicleModel.VehicleTypeModel? vehicleTypeModel;
  tripCalculeModel.TripCalculationModel? tripCalculationModel;
  dynamic selectedVehType,
      baseUnit,
      riderServiceFee,
      driverServiceFee,
      totalFare;
  dynamic baseFare, estimatedFare;
  int bookingId = 0;
  MarkerId? driverVehicleId;
  double userRating = 0.0;
  String? nearDriverErrMsg;

  NearestDriversCategory? nearestDriversCategory;
  String? lastNearestDriverEmail;
  List<getDriversWithCategoryAndPrice> nearestDriversCategoryList = <getDriversWithCategoryAndPrice>[];
  int selectedCabIndex = 0;
  var driverPhoto;
  Widget userProfilePlaceholder = SvgPicture.asset(
    defaultProfileSvg,
    height: 82,
    width: 82,
  );
  var tripStatusResult;
  bool avoidZoom = false;

  Marker? _pin_marker, _start_point_marker, _end_point_marker;

  RxList<RideComfortModel> selectedRides = <RideComfortModel>[].obs;
  List<int> selectedComfortRideFromAPI = [];
  String paymentStatus = '';

  var clientSecret = "";
  var paymentIntent = "";
  var amountSendToPayPlugin = "";

  //for audio chat
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
  RxBool isMessageUpdate = false.obs;
  AnimationController? activePausePlayAnimation;
  LinearGradient? blackLinearGradient;
  String driveraiPrefLang = '';

  RxBool isRecording = false.obs;
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
  String? mergedPath;
  bool isMergeInprogress = false;

  final Map<String, BitmapDescriptor> _iconCache = {};
// In-flight fetch guards so two overlapping setMarkers() calls don't both
// hit the network for the same icon.
  final Map<String, Future<BitmapDescriptor>> _iconFetchInFlight = {};


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

  setPaymentType(bool type) {
    update(['paymentController']);
  }
  factory MapMainController() {
    _instance ??= MapMainController._internal();
    return _instance!;
  }

  void getMarkerIcon() async {
    driverVehicleId = MarkerId("vehicle");

    if(currentLocPin ==null) {
      final Uint8List? currIcon = await getBytesFromAsset(pinPng, 70);
      currentLocPin = BitmapDescriptor.bytes(currIcon!, imagePixelRatio: globals.markerImagePixelRatio);
    }

    if(pickupIcon ==null) {
      final Uint8List? markerIcon = await getBytesFromAsset(startingPointPng, 45);
      pickupIcon = BitmapDescriptor.bytes(markerIcon!, imagePixelRatio: globals.markerImagePixelRatio);
    }

    if(destIcon ==null) {
      final Uint8List? endmarkerIcon = await getBytesFromAsset(endingPointPng, 45);
      destIcon = BitmapDescriptor.bytes(endmarkerIcon!, imagePixelRatio: globals.markerImagePixelRatio);
    }

    if(stopLocIcon ==null) {
      final Uint8List? stopmarkerIcon = await getBytesFromAsset(stopMarkerPng, 45);
      stopLocIcon = BitmapDescriptor.bytes(stopmarkerIcon!, imagePixelRatio: globals.markerImagePixelRatio);
    }
  }

  Future<String?> ideal() {
    return getUserLocationName();
  }

  MapMainController._internal() {
    mapUtils = MapUtils();
    couponController.text = "";
    updateRxValue(connectingCancelController, false);
    getInitialLocation();

    if (globals.cardLastFour != null) {
      cardLastFour = globals.cardLastFour.toString();
      update(['paymentController']);
    }
    getMarkerIcon();
    super.onInit();
  }
  init() {
    chatController = TextEditingController(text: "");
    otherReasonController = TextEditingController(text: "");
    otherReasonController.addListener(() {
      String value = otherReasonController.text.toString();
      if (value.isNotEmpty && value[0] == " ") otherReasonController.text = "";
      if (value.isNotEmpty && value[0] == "\n") otherReasonController.text = "";
    });
    couponController.addListener(() {
      refreshCouponCodeController();
      updateRxValue(SOSavailController,true);
    });


    searchPromoController = TextEditingController(text: "");
    WidgetsBinding.instance.addPostFrameCallback((_){
      loadComfortDatas();
    });


  }

  void loadComfortDatas() {
    selectedRides.value = [];
    getRideComfortList();
  }

  void moveToUserLocation() {
    if (globals.userLat != 0.0 || globals.userLon != 0.0) {
      LatLng mapLocation = LatLng(globals.userLat, globals.userLon);
      if (mapController != null)
        mapControllerCompleter.future.then((value) {
          debugPrint("move user location");
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: mapLocation,
              zoom: 15,
            ),
          ));
        });
    }
  }


  Future<File> downloadAudioFile({required String URL})async {
    String filename = URL.toString().split('/').last;
    final fileName = filename.contains('m4a') ? filename : '${filename}.m4a' ;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));

    if (!await file.exists()) {
      final request = await HttpClient().getUrl(Uri.parse(URL));
      final response = await request.close();
      final bytes = await response.expand((chunk) => chunk).toList();

      await file.writeAsBytes(bytes);
    }
    return file;

  }

  void onClickPrecautionButtons(int buttonType) {
    bookingInstructionIF?.onClickActionsInPrecautionPage(buttonType);
  }

  void updateGoogleMap() {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_updateGoogleMap ${point} --- ');
    routeController.add(LatLng(globals.userLat, globals.userLon));
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
    } on Exception catch (e) {
      return "offline";
    }
  }

  void filterPromoCodes(String text) {
    promoResults = promoList?.getPromoCode?.result?.where((element) {
      return element.code!.contains(text);
    }).toList();
    update(['filterTypeController']);
  }

  void dispose() {

    if (globals.refreshApp) {
      mapControllerCompleter.future.then((value) {
        if (mapController != null) mapController?.dispose();
      });

      globals.refreshApp = false;
    }
  }

  Future<String> removeCardDetails() async {
    graphQlObject.getGraphQlClientWithHeader();

    Map<String, dynamic>? _removePayment_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "remove_Card_mutation",
            null);

    if (_removePayment_result?["removeCardDetails"]["status"] == 200) {
      return "";
    } else {
      return _removePayment_result?["removeCardDetails"]["errorMessage"];
    }
  }

  Future<String> updatepaymentMethod(int paymentMethod) async {
    graphQlObject.getGraphQlClientWithHeader();

    var variables = <String, dynamic>{"paymentMethodId": paymentMethod};

    Map<String, dynamic>? _paymentMethod_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "paymentMethod_mutation",
            variables);

    if (_paymentMethod_result?["updatePaymentMethod"]["status"] == 200) {
      globals.preferredPaymentMethod = paymentMethod;
      globals.selectedPaymentType.value=(globals.preferredPaymentMethod);
      return "";
    } else {
      return _paymentMethod_result?["updatePaymentMethod"]["errorMessage"];
    }
  }

  Future<String> changePaymentTypePayment() async {
    graphQlObject.getGraphQlClientWithHeader();

    var variables = <String, dynamic>{
      "paymentType": globals.preferredPaymentMethod,
      "bookingId": bookingId,
      "currency": globals.preferredCurrency,
    };

    Map<String, dynamic>? _changePaymentType_result =
        await graphQlObject.getMutationValues(
            graphQlObject.graphQLClientWithHeader,
            "changePaymentType_mutation",
            variables);

    if (_changePaymentType_result?["changePaymentType"]["status"] == 200) {
      return "";
    } else {
      return _changePaymentType_result?["changePaymentType"]["errorMessage"];
    }
  }

  Future<String> createPaymentIntent(bool isGooglePay) async {
    try {
      var variables = <String, dynamic>{
        "bookingId": tripStatusResult["result"]["id"],
        "currency": tripStatusResult["result"]["currency"],
        "amount": tripFinalAmount,
      };
      print("createPaymentIntent: ${variables}");

      Map<String, dynamic>? paymentIntents =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "createPaymentIntent",
              variables);

      if (paymentIntents != null) {
        if (paymentIntents["makePaymentIntentID"]["status"] == 200) {
          clientSecret = paymentIntents["makePaymentIntentID"]["result"]["client_secret"];
          paymentIntent = paymentIntents["makePaymentIntentID"]["result"]["paymentIntentId"];
          amountSendToPayPlugin = "${paymentIntents["makePaymentIntentID"]["result"]["riderPayableFare"]}";
          return "";
        } else {
          showInSnackBar(
              "${paymentIntents["makePaymentIntentID"]["errorMessage"]}");

          return "Something went wrong 1";
        }
      } else {
        showInSnackBar( "ApI call received NULL");
        return "Something went wrong 2";
      }
    } on Exception catch (e) {
      return "offline";
    }
  }

  void callStripeForGooglePay(dynamic token, Function paymentSuccessFunction) async {
    try {
      final tokenJson = Map.castFrom(json.decode(token));

      final params = PaymentMethodParams.cardFromToken(
          paymentMethodData:
              PaymentMethodDataCardFromToken(token: tokenJson['id']));

      Stripe.publishableKey = globals.stripePublishableKey;
      Stripe.urlScheme = 'stripesdk';
      await Stripe.instance.applySettings();
      globals.setButtonLoading();
      await Stripe.instance
          .confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: params,
      )
          .then((value) {
        if (value.status == PaymentIntentsStatus.Succeeded) {
          paymentIntent = value.id;
          onsendTripPayment('tripPayment-${globals.userid}', paymentSuccessFunction);
          paymentStatus = 'completed';
          sendTripPayment();
        } else {
          paymentStatusController(0);
          showInSnackBar(
               "Error: ${value.status} --- ${value.id}");
        }
      });
    } catch (e) {
      paymentStatusController(0);
      showInSnackBar( "Error: $e");
    }
  }

  Future<dynamic> onLoadMapStyle() async {
    globals.mapEnableController(true);
    if (globals.isDarkTheme) {
      rootBundle.loadString('assets/map_style_dark.txt').then((string) {
        darkmapStyle = string;
      });
    } else {
      rootBundle.loadString('assets/map_style.txt').then((string) {
        mapStyle = string;
      });
    }
  }
  Future<void> drawDestRoute(LatLng startLoc, LatLng destLoc) async {
    debugPrint("drawDestRoute called: --- locationData count=${locationData.length}");
   // markersMap.clear();

    if (!isUserInTrip) {
          List<LatLng> tempLatLng = locationData
              .where((item) => item.latLng != null)
              .map((item) => item.latLng!)
              .toList();

          if (tempLatLng.isNotEmpty) {
            Polyline? routePolyline = await mapUtils?.getPolylinesWithLocation(tempLatLng, bookingId);
            if (routePolyline != null) {
              polyLines = routePolyline;
              mapLoadingController(false);
            }

            if (polyLines == Polyline(polylineId: PolylineId(''))) {
              return;
            }

            List<LatLng> boundsPoints = (mapUtils?.coordinates.isNotEmpty ?? false)
                ? mapUtils!.coordinates
                : tempLatLng;
            if (boundsPoints.isNotEmpty && mapController != null) {
              LatLngBounds latLngBounds = getBounds(boundsPoints);
              mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(latLngBounds, 110),
              );
            }
          }

        setPolyLinesAndVehicles(startLoc, destLoc);
    } else {
      List<LatLng> tempLatLng = [];
      if (globals.tripStatus == "started") {
        LatLng? driverLoc = getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
        if (driverLoc != null) {
          tempLatLng.add(driverLoc);
        }
        List<LocationData> data = locationData.map((item) => LocationData.clone(item)).toList();
        for (int i = 1; i < data.length; i++) {
          if (data[i].fieldType != 'disabled' && data[i].latLng != null) {
            tempLatLng.add(data[i].latLng!);
          }
        }
      } else {
        if (locationData.isNotEmpty && locationData.first.latLng != null) {
          tempLatLng.add(locationData.first.latLng!);
        }
        LatLng? driverLoc = getLatLngFromLocationModel(selectLocationEnum: SelectLocationEnum.bookingDriverLocation);
        if (driverLoc != null) {
          tempLatLng.add(driverLoc);
        }
      }
        String tripstatus = globals.tripStatus;
        List<LatLng> polyLatLng = [];
        if (globals.tripStatus == "started") {
          if (driverOldLoc != null) polyLatLng.add(driverOldLoc!);
          polyLatLng.addAll(tempLatLng);
        } else {
          polyLatLng.addAll(tempLatLng);
          if (driverOldLoc != null) polyLatLng.add(driverOldLoc!);
          polyLatLng = List.of(polyLatLng.reversed);
        }

        if (isFromAppResume) {
          mapUtils?.isPolylineResultPending = false;
        }

        if (mapUtils?.isPolylineResultPending == false && polyLatLng.isNotEmpty) {
          Polyline? valuepolylines;
          bool isOldDriverIncluded = driverOldLoc != null;
          AppLifecycleState? currentState = SchedulerBinding.instance.lifecycleState;
          print("Current App Lifecycle State: 7 $currentState");
          if (currentState == AppLifecycleState.resumed) {
            if (isFromAppResume) {
              isOldDriverIncluded = false;
              isFromAppResume = false;
            }
            debugPrint("drawdestroutepolyLatLng: ${polyLatLng}");
            valuepolylines = await mapUtils?.getPolylinesWithLocation(polyLatLng, bookingId, isOldDriverIncluded: isOldDriverIncluded);
          } else {
            mapUtils?.isPolylineResultPending = true;
          }

          if (tripstatus == globals.tripStatus) {
            if (valuepolylines != null) {
              polyLines = valuepolylines;
              coordinatecurrentIndex = null;
              _isNewPolylines = true;
              updateGoogleMap();
            }
          }

          setMarkers(tempLatLng);
        }

    }
  }
  void setPolyLinesAndVehicles(LatLng startLoc, LatLng destLoc) {
    if(polyLines != Polyline(polylineId: PolylineId(''))) {
      updateObx(RouteDrawController, 1);
      List<LatLng> latLngData = [];
      List<LocationData> data = locationData.map((item) => new LocationData.clone(item)).toList();
      data.forEach((element) {
        latLngData.add(element.latLng!);
      });

      if(polyLines != Polyline(polylineId: PolylineId(''))){
        setMarkers(latLngData);
      }
    }
    else{
      updateObx(RouteDrawController, 2);
    }
  }

  void updatePadding(double value){
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_updatePadding ${point} --- ${value} -- ${mapPaddingController.value} ');
    if(mapPaddingController.value!=value){
      mapPaddingController(value);
    }
  }

}