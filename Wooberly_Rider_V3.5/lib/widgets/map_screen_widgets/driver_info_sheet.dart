import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/widgets/audio_chat/ai_lang_selection_widget.dart';
import 'package:app_name/widgets/primary_button.dart';

import '../../app/app_routes.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../views/map_main_screen.dart';
import '../size_find_widget.dart';
import '../time_line_widget.dart';
import 'location_data_widget.dart';

class ShowDriverInfoSheet extends StatefulWidget {
  final MapMainController mapMainController=Get.find();
  late final HomeViewState state;

  ShowDriverInfoSheet({Key? key, required this.state}) : super(key: key);

  @override
  State<ShowDriverInfoSheet> createState() => ShowDriverInfoSheetState();
}

class ShowDriverInfoSheetState extends State<ShowDriverInfoSheet> {
  double _initialChildSize = 0.18, _maxSize = 0.75;
  double _currentSize = 0.0;
  final GlobalKey _headerKey = GlobalKey();
  DraggableScrollableController _draggableController = DraggableScrollableController();
  double opacity = 1;

  List<Map<String, dynamic>> _locationData = [];
  LocationDataWidget? _locationDataWidget;

  ScrollController? _sheetScrollController;

  @override
  void initState() {
    _currentSize = _initialChildSize;
    _locationDataWidget = LocationDataWidget();
    widget.mapMainController.driverInfoAnimController
      ?..addStatusListener((AnimationStatus status) {
        widget.mapMainController.update(['updateBookingLocationController']);

        if (status == AnimationStatus.reverse && _draggableController.isAttached) {
          _draggableController.animateTo(
            _initialChildSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          );
          _currentSize = _initialChildSize;
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate_initialChildSize();
    });
    super.initState();
  }

  void _calculate_initialChildSize() {
    final context = _headerKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox;
      final headerHeight = renderBox.size.height;
        _initialChildSize = (headerHeight / MediaQuery.of(context).size.height).clamp(0.1, 0.8) + 0.03;
        _currentSize = _initialChildSize;
        widget.mapMainController.rideStartedController(widget.mapMainController.rideStartedController.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.mapMainController.driverInfoOffset!,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Obx(() {
          WidgetsBinding.instance.addPostFrameCallback((_){
            if (widget.mapMainController.driverAvailController.value == false) {
              widget.mapMainController.updateRxValue(widget.mapMainController.SOSavailController,false);
              widget.mapMainController.tripSharedController?.reverse();
            }
          });
          return widget.mapMainController.driverAvailController.value == true
                  ?
                          NotificationListener<
                            DraggableScrollableNotification>(
                          onNotification: (notification) {
                            _currentSize = notification.extent;
                            if (_currentSize <= _initialChildSize && _sheetScrollController != null && _sheetScrollController!.hasClients) {
                              if (_sheetScrollController!.offset > 0) {
                                _sheetScrollController!.jumpTo(0);
                              }
                            }
                            widget.mapMainController.update(['updateBookingLocationController']);

                            return true;
                          },
                          child: SafeArea(
                            child: DraggableScrollableSheet(
                              controller: _draggableController,
                              initialChildSize: _initialChildSize,
                              minChildSize: _initialChildSize,
                              maxChildSize: _maxSize,
                              builder: (BuildContext context, ScrollController scrollController) {
                                _sheetScrollController = scrollController;
                                return _draggableScrollableSheet(scrollController);
                              },
                            ),
                          ),
                        )
                  : WidgetSize(
                      onChange: (Size size) {
                        widget.mapMainController.driverInfoHeight = 200;
                      },
                      child: Container(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        height: 200,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                SvgPicture.asset(
                                  cautionSvg,
                                  height: 64,
                                  width: 64,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(start: 20),
                                    child: Text(
                                        "${'oops_label'.tr} ${'no_driver'.tr}",
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_18,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 30, bottom: 20),
                              child: PrimaryButton(
                                buttonTitle:
                                    'try_again'.tr,
                                buttonImage: primaryRightArrowSvg,
                                callback: () {
                                  widget.mapMainController.destLocAnimController?.forward();
                                  widget.mapMainController.driverInfoAnimController?.reverse();
                                  widget.mapMainController.tripCalculationModel = null;
                                  widget.mapMainController.seRideNowLoadingController(0);
                                  widget.mapMainController.getScheduleCategoryList( widget.mapMainController.isScheduleRideIconEnable);
                                  widget.mapMainController.updatePadding(220);
                                  widget.mapMainController.avoidZoom = true;
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
            }),
      ),
    );
  }

  Widget _draggableScrollableSheet(ScrollController scrollController) {
    return WidgetSize(
      onChange: (Size size) {
        widget.mapMainController.driverInfoHeight = size.height;
      },
      child: Container(
        color: AppColors.PRIMARY_LIGHT_COLOR,
        child: GetBuilder<MapMainController>(
          id: 'updateBookingLocationController',
            builder: (_) {
              opacity = _calculateOpacity();
              return Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    children: [
                      _headerContent(),
                      AnimatedOpacity(
                          opacity: _currentSize == _initialChildSize ? 0 : 1,
                          duration: Duration(milliseconds: 600),
                          child: _bodyContent()),
                    ],
                  ),
                  _arrowView(),
                  _topView(),
                  _footerContent(),
                ],
              );
            }),
      ),
    );
  }

  _headerContent() {

    return Container(
      key: _headerKey,
      padding: const EdgeInsetsDirectional.all(24.0),
      color: AppColors.PRIMARY_LIGHT_COLOR,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          InkWell(
            onTap: () {
              widget.mapMainController.checkInternet(() {
                UrlLauncher.launchUrl(
                    Uri.parse("tel:${widget.mapMainController.driverPhone}"));
              }, false);
            },
            child: SizedBox(
              width: 65,
              child: Stack(
                children: [
                  GetBuilder<MapMainController>(
                    id:'pictureChangeController',
                    builder: (_) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(50.0),
                        child: widget.mapMainController.driverPhoto != null &&
                                widget.mapMainController.driverPhoto.isNotEmpty
                            ? CachedNetworkImage(
                                height: 62.0,
                                width: 62.0,
                                fit: BoxFit.cover,
                                imageUrl: widget.mapMainController.driverPhoto != null
                                    ? widget.mapMainController.driverPhoto
                                    : "",
                                placeholder: (context, url) => SvgPicture.asset(
                                  defaultProfileSvg,
                                  width: 62,
                                ),
                              )
                            : SvgPicture.asset(
                                defaultProfileSvg,
                                width: 62,
                              ),
                      );
                    },
                  ),
                  new Positioned(
                    bottom: 5,
                    right: 1.0,
                    child: new InkWell(
                      onTap: () async {
                        widget. mapMainController.checkInternet(() {
                          UrlLauncher.launchUrl(
                              Uri.parse("tel:${widget.mapMainController.driverPhone}"));
                        }, false);
                      },
                      child: SvgPicture.asset(
                        callOnTripSvg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Flexible(
                      child: new Text(
                        "${toBeginningOfSentenceCase(widget.mapMainController.driverName.split(" ")[0])}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontWeight: FontWeight.w600,
                          fontSize: AppDimen.text_size_18,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsetsDirectional.only(start: 5, end: 20.0),
                      padding: const EdgeInsetsDirectional.only(
                          start: 6, end: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.DIVIDER_COLOR,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "${double.parse(widget.mapMainController.driverRating.toString()).toStringAsFixed(1)}",
                            style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontWeight: FontWeight.w500,
                              fontSize: AppDimen.text_size_12,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 2.0),
                            child: SvgPicture.asset(
                              ratingFullSvg,
                              width: 8.5,
                              height: 8.5,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Padding(
                        padding:
                            const EdgeInsetsDirectional.only(start: 1.0, end: 6.0),
                        child: SvgPicture.asset(
                          driverVehicleSvg,
                          colorFilter: ColorFilter.mode(
                              AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        )),
                    Text(
                      widget.mapMainController.driverVehNum != null
                          ? widget.mapMainController.driverVehNum.toUpperCase()
                          : "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _bodyContent() {
    debugPrint("widget.mapMainController.EditDisableLocationsDataIndex: ${widget.mapMainController.EditDisableLocationsDataIndex} ");
    _locationData = widget.mapMainController.locationData
        .map((h) => {
              "id": h.id,
              "latLng": h.latLng,
              "location": h.location,
              "fieldType": h.fieldType,
              "locationStatus": h.locationStatus,
              "locationType": h.locationType,
              "locationDistanceType": h.locationDistanceType,
            })
        .toList();
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, bottom: 130.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: AppColors.DIVIDER_COLOR,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 20),
            child: Timeline(
              children: _locationDataWidget!.frameDisplayLocationWidgets(
                  _locationData, globals.tripStatus),
            ),
          ),
          if(!(widget.mapMainController.EditDisableLocationsDataIndex >= widget.mapMainController.locationData.length-1 && widget.mapMainController.locationData.length ==4))
          InkWell(
            onTap: () {
              Get.to(
                SelectDropLocation(false),
                binding: HomeBinding(),
                transition: Transition.rightToLeft,
              );
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, bottom: 20),
              child: Text(
                widget.mapMainController.locationData.length ==4
                    ? toBeginningOfSentenceCase(
                    'change'.tr.toLowerCase())!
                    : 'add_or_change'.tr,
                  style: TextStyle(
                      color: AppColors.PROMOCODE_LINK_COLOR,
                      fontSize: AppDimen.text_size_14,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.font),
              ),
            ),
          ),
          Divider(
            color: AppColors.DIVIDER_COLOR,
            height: 1,
          ),
          if (widget.mapMainController.selectedComfortRideFromAPI.length > 0) ...[
            Container(
              margin: const EdgeInsetsDirectional.only(bottom: 5, top: 5.0),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ListTileTheme(
                  dense: true,
                  horizontalTitleGap: 0.0,
                  minLeadingWidth: 0,
                  child: ExpansionTile(
                    leading: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4, end: 6.0),
                        child: SvgPicture.asset(
                          rideComfortSvg,
                          width: 20,
                          height: 13,
                          colorFilter: ColorFilter.mode(
                              AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        )),
                    title: Text(
                      'ride_comfort'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.font),
                    ),
                    childrenPadding:
                        const EdgeInsetsDirectional.only( end: 15),
                    initiallyExpanded: false,
                    onExpansionChanged: (value) {
                      widget.mapMainController.comfortExpandTileController(value);
                    },
                    trailing: Obx((){
                          return SvgPicture.asset(
                            widget.mapMainController.comfortExpandTileController.value == true
                                ? primaryUpArrowSvg
                                : primaryDownArrow,
                            colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                          );
                        }),
                    children: [
                      for (var item
                          in widget.mapMainController.selectedComfortRideFromAPI)
                        getSelectedComfortRide(item),
                    ],
                  ),
                ),
              ),
            ),
            Obx((){
                  return Padding(
                    padding:  EdgeInsetsDirectional.only(
                        top: widget.mapMainController.comfortExpandTileController.value == true
                            ? 15.0
                            : 0.0),
                    child: Divider(
                      color: AppColors.DIVIDER_COLOR,
                      height: 1,
                    ),
                  );
                }),
          ],
          const SizedBox(height: 20.0),
          Row(
            children: [
              SvgPicture.asset(
                widget.mapMainController.bookingPaymentType == 1
                    ? moneySvg
                    : widget.mapMainController.bookingPaymentType == 2
                        ? creditCardSvg
                        : walletSvg,
                colorFilter:
                    ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'estimated_amount'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.font),
                ),
              ),
              RichText(
                text: TextSpan(
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: globals.currencySymbol,
                      ),
                      TextSpan(
                        text: "${widget.mapMainController.totalFare ?? widget.mapMainController.totalFareController.value}",
                        style: TextStyle(fontFamily: AppFont.font),
                      ),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _arrowView() {
    debugPrint("widget.mapMainController.comfortExpandTileController.value: ${_currentSize} --- ${_initialChildSize} --- ${_maxSize}");
    return Positioned(
      top: 20,
      right: globals.isRTLLang ? null : 20,
      left: globals.isRTLLang ? 20 : null,
      child: InkWell(
          onTap: () {
            if (_currentSize == _initialChildSize) {
              _draggableController.animateTo(
                _maxSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
              Scrollable.ensureVisible(Get.context!);
              _currentSize = _maxSize;
            } else {
              _draggableController.animateTo(
                _initialChildSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
              Scrollable.ensureVisible(Get.context!);
              _currentSize = _initialChildSize;
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
            child: SizedBox(
                width: 12,
                height: 12,
                child: RotatedBox(
                  quarterTurns: globals.isRTLLang ? 2 : 0,
                  child: SvgPicture.asset(
                    _currentSize == _maxSize
                        ? primaryDownArrow
                        : primaryUpArrowSvg,
                    colorFilter: ColorFilter.mode(
                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                    fit: BoxFit.scaleDown,
                  ),
                ),
            ),
          ),
      ),
    );
  }

  Widget _topView() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 80,
        height: 4,
        margin: const EdgeInsetsDirectional.only(top: 12.0),
        decoration: BoxDecoration(
            color: AppColors.PrecautionInstructionCancel,
            borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
    );
  }

  Widget _footerContent() {
    return (_currentSize != _initialChildSize)
        ? Positioned(
            bottom: -(1 - opacity) * 120,
            left: 0,
            right: 0,
            child: Opacity(opacity: opacity, child: bottomNavWidgets()),
          )
        : const SizedBox.shrink();
  }

  double _calculateOpacity() {
    if (_maxSize > _initialChildSize) {
      if (_currentSize! <= _initialChildSize)
        return 0;
      else if (_currentSize! >= _maxSize)
        return 1;
      else
        return (_currentSize! - _initialChildSize) /
            (_maxSize - _initialChildSize);
    } else {
      if (_currentSize! <= _maxSize)
        return 1;
      else if (_currentSize! >= _initialChildSize)
        return 0;
      else
        return (_currentSize! - _maxSize) / (_initialChildSize - _maxSize);
    }
  }


  Widget getSelectedComfortRide(int id) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Container(
            height: 16,
            width: 16,
            margin: const EdgeInsetsDirectional.only(top: 3, end: 15.0),
            child: SvgPicture.asset(
              widget.mapMainController.rideComfortData[id - 1].icon,
              height: 16,
              width: 16,
              colorFilter:
                  ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
          ),
          Text(
            widget.mapMainController.rideComfortData[id - 1].title,
            style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.font),
          ),
        ],
      ),
    );
  }

  Widget bottomNavWidgets() {
    return Container(
      decoration: BoxDecoration(color: AppColors.PRIMARY_LIGHT_COLOR, boxShadow: [
        BoxShadow(
            color: AppColors.LOCATION_ARRIVED_COLOR.withAlpha(30),
            blurRadius: 5.0,
            spreadRadius: 3.0,
            offset: Offset(-1, -1)),
      ]),
      child: Obx(() {
            bool isStart = widget.mapMainController.rideStartedController.value ;
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    widget. mapMainController.checkInternet(() {
                      UrlLauncher.launchUrl(
                          Uri.parse(("tel:${widget.mapMainController.driverPhone}")));
                    }, false);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                      ),
                      Container(
                          decoration: BoxDecoration(
                              color: AppColors.COMMON_BG_COLOR,
                              shape: BoxShape.circle),
                          padding: const EdgeInsetsDirectional.all(13),
                          child: SvgPicture.asset(
                            callIconSvg,
                            height: 22,
                            width: 22,
                            colorFilter: ColorFilter.mode(
                                AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                          )),
                      Text(
                        'btn_contact'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_16,
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
                if(!widget.mapMainController.isFromAdmin)
                InkWell(
                    onTap: () async {
                      VoiceChatBottomSheet(NavigateFunction: () async{
                        bool internetConnect = await widget.mapMainController.checkConnectivity();
                        if (internetConnect != null && internetConnect) {
                          widget.mapMainController.setNavigation(AppRoutes.APP_CHAT);
                        } else {
                          widget.mapMainController.showInSnackBar('offline_text'.tr);
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 24,
                        ),
                        GetBuilder<MapMainController>(
                          id:'unReadCountController',
                          builder: (_) {
                            return ClipRRect(
                              child: Container(
                                decoration: BoxDecoration(
                                    color: AppColors.COMMON_BG_COLOR,
                                    shape: BoxShape.circle),
                                padding: const EdgeInsetsDirectional.all(13),
                                child: widget.mapMainController.unreadCount == 0
                                    ? SvgPicture.asset(
                                        updatedChatSvg,
                                        height: 22,
                                        width: 22,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_ICON_COLOR,
                                            BlendMode.srcIn),
                                      )
                                    : globals.isDarkTheme?
                                SvgPicture.asset(
                                        updatedUnreadChatDarkSvg,
                                        height: 22,
                                        width: 22,)
                              :SvgPicture.asset(
                                  updatedUnreadChatLightSvg,
                                  height: 22,
                                  width: 22,

                                ),
                              ),
                            );
                          },
                        ),
                        Text(
                          'chat'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFont.font,
                              fontSize: AppDimen.text_size_16,
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                if (!isStart)
                  InkWell(
                    onTap: () {
                      widget.mapMainController.updateRxValue(   widget.mapMainController.radioListSelectController,  false);
                      widget.mapMainController.selectedCancelReason = null;
                      widget.state.openCancelReasonScreen();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 24,
                        ),
                        Container(
                            decoration: BoxDecoration(
                                color: AppColors.COMMON_BG_COLOR,
                                shape: BoxShape.circle),
                            padding: const EdgeInsetsDirectional.all(13),
                            child: SvgPicture.asset(
                              updatedCancelSvg,
                              height: 22,
                              width: 22,
                              colorFilter: ColorFilter.mode(
                                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                            )),
                        Text(
                          'cancel_label'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFont.font,
                              fontSize: AppDimen.text_size_16,
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
    );
  }
}