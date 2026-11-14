import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';

import '../../app/app.dart';
import '../../app/app_routes.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_lang.dart';
import '../flutter_rating_bar.dart';
import '../primary_button.dart';
import '../primary_scaffold.dart';

class RiderReviewTransitionView extends StatefulWidget {
  const RiderReviewTransitionView({Key? key}) : super(key: key);

  @override
  State<RiderReviewTransitionView> createState() =>
      _RiderReviewTransitionViewState();
}

class _RiderReviewTransitionViewState extends State<RiderReviewTransitionView>
    with TickerProviderStateMixin {
  final MapMainController _controller = Get.find();
  double _imagesize = 86.0;
  late Widget placeHolderWidget;

  @override
  void initState() {
    placeHolderWidget = SvgPicture.asset(
      defaultProfileSvg,
      height: _imagesize,
      width: _imagesize,
    );
    _controller.change(rxVariable: _controller.rxStarRatingController, value: 0.0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      disableAppbar: false,
      appBarTitle: Review.tr,
      appBarImage: !_controller.isFromtrips ? '' : primaryLeftArrow,
      customAppBarFunction: () {
        if (_controller.isFromtrips) {
          App().setBackNavigation();
          globals.isRefreshTripPage.value = true;
          globals.isRefreshTripPage.refresh();
        } else {
          _controller.homeViewState.tripAmountController?.forward();
          App().setBackNavigation();
        }
      },
      body: Padding(
        padding: const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Wrap(
                children: <Widget>[
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_WHITE,
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Stack(
                                children: <Widget>[
                                  placeHolderWidget,
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50.0),
                                    child: _controller.riderPhoto != null &&
                                            _controller.riderPhoto.isNotEmpty
                                        ? CachedNetworkImage(
                                            height: _imagesize,
                                            width: _imagesize,
                                            fit: BoxFit.cover,
                                            imageUrl:
                                                _controller.riderPhoto != null
                                                    ? _controller.riderPhoto
                                                    : "",
                                            placeholder: (context, url) =>
                                            placeHolderWidget,
                                          )
                                        : placeHolderWidget,
                                  )
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Center(
                                  child: Text(
                                      how_was_your_rider.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_14,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ),
                              getRatingBar(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: !_controller.isFromtrips,
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding:const EdgeInsetsDirectional.only(bottom: 70),
                  child: InkWell(
                    onTap: () {
                      _controller.clearMap();
                      _controller.homeViewState.tripAmountController?.reverse();
                      _controller.homeViewState.tripCashPopupController?.reverse();
                      Get.until((route) => route.settings.name == "/MapMainScreen");
                      Get.off(AppRoutes().getWidget(AppRoutes.APP_MAP_MAIN), arguments: "reviewPage");
                    },
                    child: Text(
                      Review_later.tr,
                      style: TextStyle(
                          color: AppColors.TEXT_LINK_COLOR,
                          fontWeight: FontWeight.w400,
                          fontSize: AppDimen.text_size_18,
                          fontFamily: AppFont.font),
                    ),
                  ),
                ),
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: PrimaryButton(
                  buttonTitle: done.tr,
                  buttonImage: primaryBtnArrow,
                  callback: () {
                    if ( _controller.rxStarRatingController.value != 0.0) {
                      if (_controller.isFromtrips) {
                        _controller.checkInternet(writeReview, false);
                      } else {
                        _controller.checkInternet(writeReview, false);
                        debugPrint("riderInfoAnimController reverse 3");
                        _controller.homeViewState.riderInfoAnimController?.reverse();
                      }
                    } else {
                      App().toast.show(context: context, message: rating_must_add.tr,);
                    }
                  },
                ))
          ],
        ),
      ),
    );
  }

  Widget getRatingBar() {
    return GetBuilder(
        init: MapMainController(),
        id: _controller.rxStarRatingController.id,
        builder: (val) {
          double rate = _controller.rxStarRatingController.value;
          return new RatingBar(
            initialRating: rate,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            ratingWidget: RatingWidget(
              full: SvgPicture.asset(
                ratingFullSvg,
                colorFilter: ColorFilter.mode(
                    AppColors.READING_COLOR, BlendMode.srcIn),
              ),
              half: Icon(
                Icons.star_half,
                color: AppColors.READING_COLOR,
              ),
              empty: SvgPicture.asset(
                ratingFullSvg,
                colorFilter: ColorFilter.mode(
                    AppColors.DIVIDER_COLOR, BlendMode.srcIn),
              ),
            ),
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            onRatingUpdate: (rating) {
              _controller.setStarRatingController(rating);
            },
          );
        });
  }

  writeReview() {
    _controller.clearMap();
    _controller.writeReview().then((value) {
      if (value.isNotEmpty) {
        if (value == "timeout") {
          App().toast.show(
                context: context,
                message: session_timeout_err.tr,
              );
          _controller.setLogout(context);
        } else if (value == "offline") {
          _controller.netOffSnackbar(writeReview, false);
        } else {
          _controller
              .showInSnackBar(value);
        }
      } else {
        if (_controller.isFromtrips) {
          App().setBackNavigation();
          if(globals.isRefreshTripPage.value != true)
            globals.isRefreshTripPage.value = true;
          else
            globals.isRefreshTripPage.refresh();
        } else {
          _controller.homeViewState.rideCompleteAnimController?.reverse();
          _controller.homeViewState.closeApp = true;
          _controller.setDriverStatus(true);
          _controller.clearMap();
          Get.until((route) => route.settings.name == "/MapMainScreen");
          Get.off(AppRoutes().getWidget(AppRoutes.APP_MAP_MAIN), arguments: "reviewPage");
        }
      }
    });
  }
}