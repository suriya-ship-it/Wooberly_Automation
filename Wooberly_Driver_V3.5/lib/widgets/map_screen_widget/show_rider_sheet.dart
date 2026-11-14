import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../app/app.dart';
import '../../app/app_routes.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../controller/profile_controllers/edit_account_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_images.dart';
import '../../resources/values/app_lang.dart';
import '../../views/map_main_screen.dart';
import '../ai_lang_selection_widget.dart';
import '../size_find_widget.dart';
import '../time_line_widget.dart';
import 'location_data_widget.dart';

class ShowRiderInfoSheet extends StatefulWidget {
  final MapMainController controller = Get.find();
  final HomeViewState homeViewState;

  ShowRiderInfoSheet(
      {Key? key, required this.homeViewState})
      : super(key: key);

  @override
  State<ShowRiderInfoSheet> createState() => ShowRiderInfoSheetState();
}

class ShowRiderInfoSheetState extends State<ShowRiderInfoSheet> {
  double _initialChildSize = 0.18, _maxSize = 0.75;
  double _currentSize = 0.0;
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _bottomKey = GlobalKey();
  DraggableScrollableController _draggableController =
      DraggableScrollableController();
  double opacity = 1;
  final EditAccountController controller = Get.find();
  List<Map<String, dynamic>>? _locationData;
  LocationDataWidget? _locationDataWidget;

  String selectLang = "";
  int selectInd = 0;

  @override
  void initState() {
    _currentSize = _initialChildSize;
    _locationDataWidget = LocationDataWidget();
    widget.homeViewState.riderInfoAnimController!
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.reverse) {
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
        _initialChildSize = (headerHeight / Get.height).clamp(0.1, 0.8) + 0.03;
        _currentSize = _initialChildSize;
      widget.controller.change(rxVariable: widget.controller.rxUpdateBookingLocationController, value: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draggableController == null)
      _draggableController = DraggableScrollableController();

    return SlideTransition(
      position: widget.homeViewState.riderInfoOffset!,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            _currentSize = notification.extent;
            widget.controller.change(rxVariable: widget.controller.rxUpdateBookingLocationController, value: true);
            return false;
          },
          child: SafeArea(
            child: DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: _initialChildSize,
              minChildSize: _initialChildSize,
              maxChildSize: _maxSize,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return _draggableScrollableSheet(scrollController);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _draggableScrollableSheet(ScrollController scrollController) {
    return WidgetSize(
      onChange: (Size size) {
        widget.homeViewState.riderInfoHeight = size.height;
      },
      child: ColoredBox(
        color: AppColors.PRIMARY_COLOR_WHITE,
        child: GetBuilder(
            init: MapMainController(),
            id: widget.controller.rxUpdateBookingLocationController.id,
            builder: (val) {
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
                  _arrowView(context),
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
        color: AppColors.PRIMARY_COLOR_WHITE,
        child: GetBuilder(
            init: MapMainController(),
            id: widget.controller.rxPictureChangeController.id,
            builder: (val) {
              return Container(
                padding: const EdgeInsets.all(24.0),
                color: AppColors.PRIMARY_COLOR_WHITE,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        widget.controller.checkInternet(() {
                          UrlLauncher.launchUrl(
                              Uri.parse("tel:${widget.controller.riderNumber}"));
                        }, false);
                      },
                      child: SizedBox(
                        width: 65,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50.0),
                              child: widget.controller.riderPhoto != null &&
                                      widget.controller.riderPhoto.isNotEmpty
                                  ? CachedNetworkImage(
                                      height: 62.0,
                                      width: 62.0,
                                      fit: BoxFit.cover,
                                      imageUrl:
                                          widget.controller.riderPhoto != null
                                              ? widget.controller.riderPhoto
                                              : "",
                                      placeholder: (context, url) =>
                                          SvgPicture.asset(
                                        defaultProfileSvg,
                                        height: 62.0,
                                        width: 62.0,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      defaultProfileSvg,
                                      height: 62.0,
                                      width: 62.0,
                                    ),
                            ),
                            new Positioned(
                              bottom: 0,
                              right: 3.0,
                              child: new InkWell(
                                onTap: () async {
                                  widget.controller.checkInternet(() {
                                    UrlLauncher.launchUrl(Uri.parse(
                                        "tel:${widget.controller.riderNumber}"));
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
                    GetBuilder(
                      init: MapMainController(),
                        id: widget.controller.rxTripstartedResController.id,
                        builder: (val) {
                          return Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: [
                                    Flexible(
                                      child: new Text(
                                        "${toBeginningOfSentenceCase(widget.controller.riderName.split(" ")[0])}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppDimen.text_size_18,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsetsDirectional.only(
                                          start: 5, end: 20),
                                      padding: const EdgeInsetsDirectional.symmetric(
                                          horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.DIVIDER_COLOR,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            "${widget.controller.rating != null ? double.parse(widget.controller.rating.toString()).toStringAsFixed(1) : "0.0"}",
                                            style: TextStyle(
                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                              fontWeight: FontWeight.w500,
                                              fontSize: AppDimen.text_size_12,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(start: 2.0),
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
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 1.0, end: 6.0),
                                      child: widget.controller.rxPaymentType.value != 4 &&
                                              widget.controller.rxPaymentType.value != 5&&
                                              widget.controller.rxPaymentType.value != 6
                                          ? SvgPicture.asset(
                                              widget.controller.rxPaymentType.value == 1
                                                  ? moneySvg
                                                  : widget.controller.rxPaymentType.value == 2
                                                      ? creditCardSvg
                                                      : walletSvg,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.ICON_COLOUR,
                                                  BlendMode.srcIn),
                                            )
                                          : widget.controller.rxPaymentType.value == 4
                                              ? SvgPicture.asset(
                                                  GpaySvg,
                                                  width: 30.0,
                                                  height: 30.0,
                                                )
                                              : widget.controller.rxPaymentType.value == 6
                                                  ? SvgPicture.asset(
                                                      payPalPaymentSVG,
                                                      width: 16.0,
                                                      height: 16.0,
                                                    )
                                                  : SvgPicture.asset(
                                                      payStackSvg,
                                                      width: 15,
                                                      height: 15),
                                    ),
                                    Text(
                                      switch (widget.controller.rxPaymentType.value) {
                                        1 => cash_trip.tr,
                                        2 => card.tr,
                                        3 => wallet.tr,
                                        4 => 'Google Pay',
                                        6 => 'PayPal',
                                        _ => 'Pay Stack',
                                      },
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              );
            }));
  }

  Widget _bodyContent() {
    _locationData = widget.controller.locationData
        .map((h) => {
              "id": h.id,
              "latLng": h.latLng,
              "location": h.location,
              "fieldType": h.fieldType,
              "locationStatus": h.locationStatus,
              "locationType": h.locationType,
            })
        .toList();
    return Padding(
      padding:
      const  EdgeInsetsDirectional.only(start: 15.0, end: 15.0, bottom: 130.0),
      child: Column(
        children: [
          Divider(
            color: AppColors.DIVIDER_COLOR,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 20),
            child: Timeline(
              children: _locationDataWidget!.frameDisplayLocationWidgets(
                  _locationData, widget.controller.tripStatus),
            ),
          ),
          const SizedBox(height: 20.0),
          Divider(
            color: AppColors.DIVIDER_COLOR,
            height: 1,
          ),
          (widget.controller.selectedComfortRide != null &&
                  widget.controller.selectedComfortRide.isNotEmpty)
              ? Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ListTileTheme(
                          dense: true,
                          horizontalTitleGap: 0.0,
                          minLeadingWidth: 0,
                          contentPadding: const EdgeInsets.all(0),
                          child: ExpansionTile(
                            leading: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    top: 4, end: 6.0),
                                child: SvgPicture.asset(
                                  rideComfortSvg,
                                  width: 20,
                                  height: 13,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.ICON_COLOUR, BlendMode.srcIn),
                                )),
                            title: Text(
                              ride_comfort.tr,
                              style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.font),
                            ),
                            childrenPadding:
                            const EdgeInsetsDirectional.only(start: 0, end: 15),
                            initiallyExpanded: false,
                            onExpansionChanged: (value) {
                              widget.controller.change(rxVariable: widget.controller.rxComfortExpandTileController, value: value);
                            },
                            trailing: GetBuilder(
                              init: MapMainController(),
                                id: widget.controller.rxComfortExpandTileController.id,
                                builder: (val) {
                                  return SvgPicture.asset(
                                    widget.controller.rxComfortExpandTileController.value == true
                                        ? primaryUpArrow
                                        : primaryDownArrow,
                                    colorFilter: ColorFilter.mode(
                                        AppColors.ICON_COLOUR, BlendMode.srcIn),
                                  );
                                }),
                            children: [
                              for (var item
                                  in widget.controller.selectedComfortRide)
                                getSelectedComfortRide(item),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      color: AppColors.DIVIDER_COLOR,
                      height: 1,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          const  SizedBox(height: 20.0),
          Row(
            children: [
              SvgPicture.asset(
                estEarningsSvg,
                colorFilter:
                    ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  estimated_earnings.tr,
                  style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.font),
                ),
              ),
              RichText(
                text: TextSpan(
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: globals.currencySymbol,
                        style: TextStyle(
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${double.parse(widget.controller.rxEstimateAmountController.value.toString()).toStringAsFixed(2)}",
                        style: TextStyle(
                            fontSize: AppDimen.text_size_16,
                            fontFamily: AppFont.font),
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

  Widget _arrowView(BuildContext context) {
    return Positioned(
      top: 20,
      right: globals.isRtlLang ? null : 20,
      left: globals.isRtlLang ? 20 : null,
      child: InkWell(
          onTap: () {
            if (_currentSize == _initialChildSize) {
              _draggableController.animateTo(
                _maxSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
              Scrollable.ensureVisible(_bottomKey.currentContext ?? context);
              _currentSize = _maxSize;
            } else {
              _draggableController.animateTo(
                _initialChildSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
              Scrollable.ensureVisible(_headerKey.currentContext!);
              _currentSize = _initialChildSize;
            }
          },
          child: Container(
            width: 40,
            height: 40,
            padding: EdgeInsetsDirectional.all(12),
            decoration: BoxDecoration(
                color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
            child: SizedBox(
                width: 20,
                height: 20,
                child: RotatedBox(
                  quarterTurns: globals.isRtlLang ? 2 : 0,
                  child: SvgPicture.asset(
                    _currentSize == _maxSize
                        ? primaryDownArrow
                        : primaryUpArrow,
                    colorFilter: ColorFilter.mode(
                        AppColors.ICON_COLOUR, BlendMode.srcIn),
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
        margin: const EdgeInsets.only(top: 12.0),
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
        :const SizedBox.shrink();
  }

  double _calculateOpacity() {
    if (_maxSize > _initialChildSize) {
      if (_currentSize <= _initialChildSize)
        return 0;
      else if (_currentSize >= _maxSize)
        return 1;
      else
        return (_currentSize - _initialChildSize) /
            (_maxSize - _initialChildSize);
    } else {
      if (_currentSize <= _maxSize)
        return 1;
      else if (_currentSize >= _initialChildSize)
        return 0;
      else
        return (_currentSize - _maxSize) / (_initialChildSize - _maxSize);
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
            margin: const EdgeInsetsDirectional.only(top: 3, end: 8.0),
            child: SvgPicture.asset(
              widget.controller.rideComfortData[id - 1].icon,
              height: 16,
              width: 16,
              colorFilter:
                  ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
            ),
          ),
          Text(
            widget.controller.rideComfortData[id - 1].title,
            style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.font),
          ),
        ],
      ),
    );
  }

  Widget bottomNavWidgets() {
    return Container(
      decoration: BoxDecoration(color: AppColors.PRIMARY_COLOR_WHITE, boxShadow: [
        BoxShadow(
            color: AppColors.GRAY.withAlpha(30),
            blurRadius: 5.0,
            spreadRadius: 3.0,
            offset: Offset(-1, -1)),
      ]),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              widget.controller.checkInternet(() {
                UrlLauncher.launchUrl(
                    Uri.parse("tel:${widget.controller.riderNumber}"));
              }, false);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const  SizedBox(
                  height: 24,
                ),
                Container(
                    decoration: BoxDecoration(
                        color: AppColors.OFFLINE_COLOR,
                        shape: BoxShape.circle),
                    padding: EdgeInsetsDirectional.all(13),
                    child: SvgPicture.asset(
                      callIconSvg,
                      height: 22,
                      width: 22,
                      colorFilter: ColorFilter.mode(
                          AppColors.ICON_COLOUR, BlendMode.srcIn),
                    )),
                Text(
                  call.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppFont.font,
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
          if (!widget.controller.isFromAdmin)
            InkWell(
              onTap: () async {
                  VoiceChatBottomSheet(NavigateFunction: () async{
                    bool internetConnect = await widget.controller.checkConnectivity();
                    if (internetConnect != null && internetConnect) {
                      MapMainController mapMainController = Get.find();
                      mapMainController.isRecording.value = false;
                      App().setNavigation(AppRoutes.APP_CHAT);
                    } else {
                      widget.controller.showInSnackBar('offline_text'.tr);
                    }
                  });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const  SizedBox(
                    height: 24,
                  ),
                  GetBuilder(
                    init: MapMainController(),
                    id: widget.controller.rxUnReadCountController.id,
                    builder: (val) {
                      return ClipRRect(
                        child: Container(
                          decoration: BoxDecoration(
                              color: AppColors.OFFLINE_COLOR,
                              shape: BoxShape.circle),
                          padding: EdgeInsetsDirectional.all(13),
                          child: widget.controller.unreadCount == 0
                              ? SvgPicture.asset(
                                  updatedChatSvg,
                                  height: 22,
                                  width: 22,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.ICON_COLOUR, BlendMode.srcIn),
                                )
                              : globals.isDarkTheme
                                  ? SvgPicture.asset(
                                      updatedUnreadChatDarkSvg,
                                      height: 22,
                                      width: 22,
                                    )
                                  : SvgPicture.asset(
                                      updatedUnreadChatLightSvg,
                                      height: 22,
                                      width: 22,
                            colorMapper: ChatIconColorMapper(AppColors.ICON_COLOUR),
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    chat_title.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFont.font,
                        fontSize: AppDimen.text_size_16,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ),
          if (widget.controller.tripStatus != "started")
            InkWell(
              onTap: () {
                if ( widget.controller.tripStatus != "started") {
                  widget.controller.change(rxVariable:   widget.controller.rxRadioListSelectController, value: false);
                  widget.controller.selectedCancelReason = null;
                  widget.controller.otherReasonController.text = '';
                  _draggableController.animateTo(
                    _initialChildSize,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                  );
                  Scrollable.ensureVisible(_headerKey.currentContext!);
                  _currentSize = _initialChildSize;
                  widget.homeViewState.openCancelReasonScreen();
                  widget.homeViewState.singleClick = false;
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  Container(
                      decoration: BoxDecoration(
                          color: AppColors.OFFLINE_COLOR,
                          shape: BoxShape.circle),
                      padding: EdgeInsetsDirectional.all(13),
                      child: SvgPicture.asset(
                        updatedCancelSvg,
                        height: 22,
                        width: 22,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      )),
                  Text(
                    cancel.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFont.font,
                        fontSize: AppDimen.text_size_16,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
  getPreferredController() {
    if (controller.preferredController.text
        .toString()
        .isNotEmpty) {
      return controller.preferredController;
    } else if (controller.preferredController == null ||
        controller.preferredController.text == null ||
        controller.preferredController.text
            .toString()
            .isEmpty) {
      if (controller.preferredController == null)
        controller.preferredController = TextEditingController();
      return controller.getAIPreferredLanguage();
    }
  }


  bool checkVerified(String option, int index) {
    int index1 = controller.getMobileLanguageList
        .indexWhere((element) => element['language'] == selectLang);
    return index1 == index;
  }

}