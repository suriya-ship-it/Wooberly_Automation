import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/widgets/flutter_rating_bar.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';
import '../widgets/show_done_view.dart';

class showReview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return showReviewScreenState();
  }
}

class showReviewScreenState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => showReviewScreenStateView();
}

class showReviewScreenStateView extends State<showReviewScreenState> {
  MapMainController mapMainController = Get.find();
  BuildContext? scaffoldContext;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapMainController.getDeviceDetails();
      mapMainController.init();
      mapMainController.getRideStatus();
      mapMainController.starRatingController.value = 0;
      mapMainController.tripStatusResult = null;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
          final statusBarStyle = SystemUiOverlayStyle(
            statusBarColor: AppColors.PRIMARY_LIGHT_COLOR,
            statusBarIconBrightness:
            globals.isDarkTheme ? Brightness.light : Brightness.dark,
            statusBarBrightness:
            globals.isDarkTheme ? Brightness.dark : Brightness.light,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: statusBarStyle,
            child: ColoredBox(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      PrimaryScaffold(
                        appBarTitle: !mapMainController.isFromtrips
                            ? 'payment_completed'.tr
                            : 'review'.tr,
                        appBarImage:
                        !mapMainController.isFromtrips ? '' : primaryLeftArrow,
                        customAppBarFunction: () {
                          if (mapMainController.isFromtrips) {
                            mapMainController.userRating = 0.0;
                          }
                          mapMainController.setBackNavigation();
                        },
                        body: Padding(
                          padding:
                          const EdgeInsetsDirectional.symmetric(horizontal: 24),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (!mapMainController.isFromtrips &&
                                        globals.preferredPaymentMethod == 1)
                                      Container(
                                        height: 170,
                                        width: 170,
                                        margin:
                                        const EdgeInsetsDirectional.symmetric(
                                            vertical: 20),
                                        decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(300),
                                          ),
                                        ),
                                        child: Lottie.asset(
                                            'assets/schedule_success.json'),
                                      ),
                                    Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          top: 30, bottom: 50),
                                      margin: const EdgeInsetsDirectional.only(
                                          top: 30, bottom: 110),
                                      decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_LIGHT_COLOR,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10.0)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Stack(
                                            children: <Widget>[
                                              new Icon(
                                                Icons.account_circle,
                                                size: 82,
                                                color: AppColors
                                                    .LOCATION_ARRIVED_COLOR,
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(50.0),
                                                child:
                                                mapMainController.driverPhoto !=
                                                    null &&
                                                    mapMainController
                                                        .driverPhoto
                                                        .isNotEmpty
                                                    ? CachedNetworkImage(
                                                  height: 82.0,
                                                  width: 82.0,
                                                  fit: BoxFit.cover,
                                                  imageUrl: mapMainController
                                                      .driverPhoto !=
                                                      null
                                                      ? mapMainController
                                                      .driverPhoto
                                                      : "",
                                                  placeholder: (context,
                                                      url) =>
                                                  mapMainController
                                                      .userProfilePlaceholder,
                                                )
                                                    : mapMainController
                                                    .userProfilePlaceholder,
                                              )
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .symmetric(vertical: 10.0),
                                            child: Center(
                                              child: Text('how_was_your_rider'.tr,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize:
                                                      AppDimen.text_size_14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors
                                                          .BLACK_TEXT_COLOR)),
                                            ),
                                          ),
                                          getRatingBar(0),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                        height: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom)
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: !mapMainController.isFromtrips,
                                child: Align(
                                  alignment: AlignmentDirectional.bottomCenter,
                                  child: Container(
                                    color: AppColors.COMMON_BG_COLOR,
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsetsDirectional.only(
                                        bottom: 80, top: 20),
                                    child: InkWell(
                                      onTap: () {
                                        _reviewSuccess();
                                      },
                                      child: Text(
                                        'Review_later'.tr,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppColors.PROMOCODE_LINK_COLOR,
                                            fontWeight: FontWeight.w500,
                                            fontSize: AppDimen.text_size_18,
                                            fontFamily: AppFont.font),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding:
                                  const EdgeInsetsDirectional.only(bottom: 15),
                                  child: PrimaryButton(
                                    buttonTitle: 'done'.tr,
                                    buttonImage: primaryRightArrowSvg,
                                    callback: () {
                                      if (mapMainController.userRating != 0.0) {
                                        mapMainController.updatePadding(0);
                                        mapMainController.checkInternet(
                                            sendMapScreenReview, null);
                                        SystemChannels.textInput
                                            .invokeMethod('TextInput.hide');
                                      } else {
                                        mapMainController.toast.show(
                                            context: context,
                                            message: 'rating_must_add'.tr,
                                            bgColor: AppColors.PRIMARY_LIGHT_COLOR,
                                            txtColor: AppColors.BLACK_TEXT_COLOR);
                                      }
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        onChanged: (map) {
                          scaffoldContext = map["scaffoldcontext"];
                        },
                      ),
                      Positioned(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          right: 0.0,
                          left: 0.0,
                          child: MediaQuery.of(context).viewInsets.bottom >= 175.0
                              ? InputDoneView()
                              : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget getRatingBar(double i) {
    return Obx(() {
      double rate = mapMainController.starRatingController.value;
      return new RatingBar(
        initialRating: rate,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 5,
        ratingWidget: RatingWidget(
          full: SvgPicture.asset(
            ratingFullSvg,
            colorFilter:
            ColorFilter.mode(AppColors.RATING_COLOR, BlendMode.srcIn),
          ),
          half: Icon(
            Icons.star_half,
            color: AppColors.RATING_COLOR,
          ),
          empty: SvgPicture.asset(
            ratingFullSvg,
            colorFilter:
            ColorFilter.mode(AppColors.DIVIDER_COLOR, BlendMode.srcIn),
          ),
        ),
        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
        onRatingUpdate: (rating) {
          mapMainController.userRating = rating;
          mapMainController.starRatingController(rating);
        },
      );
    });
  }

  sendMapScreenReview() {
    mapMainController.sendReview().then((value) {
      if (value == "offline") {
        mapMainController.netOffSnackbar(sendMapScreenReview, false);
      } else if (value.isNotEmpty) {
        mapMainController.showInSnackBar(value);
      } else {
        _reviewSuccess();
      }
    });
  }

  void _reviewSuccess() {
    if (mapMainController.isFromtrips) {
      mapMainController.refreshControl?.refreshController();
    } else {
      globals.mapEnableController(true);
      if (mapMainController.driverInfoAnimController != null)
        mapMainController.driverInfoAnimController?.reverse();
      if (mapMainController.vehicleCatAnimController != null)
        mapMainController.vehicleCatAnimController?.reverse();
      mapMainController.lastKnownLocation = LatLng(0.0, 0.0);
      debugPrint("destLocAnimController forward 12 45");
      mapMainController.destLocAnimController?.forward();
      mapMainController.requestPermission();
      mapMainController.setDestPlaceController("");
      mapMainController.userRating = 0.0;
      mapMainController.locationData.clear();
      if (mapMainController.sosIconController != null)
        mapMainController.sosIconController?.reverse();
    }
    mapMainController.setBackNavigation();
    mapMainController.tripFinalAmount = null;
    mapMainController.clearMap();
    mapMainController.mapPaddingController.refresh();

    globals.userLat = 0.0;
    globals.userLon = 0.0;
     mapMainController.requestPermission().then((locationvalue){
      mapMainController.lastKnownLocation = LatLng(globals.userLat, globals.userLon);
      mapMainController.getUserLocationName();
    });



  }
}