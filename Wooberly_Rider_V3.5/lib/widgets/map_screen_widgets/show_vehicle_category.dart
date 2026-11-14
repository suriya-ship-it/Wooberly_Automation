import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/size_find_widget.dart';
import '../../app/app_routes.dart';
import '../../models/get_driver_wiht_category_price.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../primary_button.dart';
import 'package:http/http.dart' as http;

const Key centerKey = ValueKey<String>('bottom-sliver-list');
class ShowVehicleCategory extends StatefulWidget {
  final MapMainController mapMainController=Get.find();

  ShowVehicleCategory({Key? key}) : super(key: key);

  @override
  State<ShowVehicleCategory> createState() => ShowVehicleCategoryState();
}

class ShowVehicleCategoryState extends State<ShowVehicleCategory> {
  double  _bottomWidgetHeight = 175.0;
  double _minSize = 0.4, _maxSize = 1.0;
  double _currentSize = 0.4;
  DraggableScrollableController draggableScrollableController = DraggableScrollableController();
  ScrollController? _listviewController = ScrollController();
  var _isMaximized = ValueNotifier<bool>(false);
  RxBool isRideNowLoad=false.obs;
  List<Widget> _vehicleCatWidgets = [];
  Map<String,Widget> _vehicleCatImageWidget = {};

  @override
  void initState() {
    if (widget.mapMainController.isScheduleRide) {
      _bottomWidgetHeight = 218;
    } else {
      _bottomWidgetHeight = 175;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      draggableScrollableController.addListener(_onScroll);
    });
    super.initState();
  }

  void _onScroll() {
    final extent = draggableScrollableController.size;
    final isMaximized = extent >= _maxSize;

    if (isMaximized != _isMaximized.value ) {
      _isMaximized.value = isMaximized;
    }
  }

  @override
  void dispose() {
    draggableScrollableController.removeListener(_onScroll);
    draggableScrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return SlideTransition(
      position: widget.mapMainController.vehicleCatOffset!,
      child: Obx(() {
        WidgetsBinding.instance.addPostFrameCallback((_){
          if (widget.mapMainController.isScheduleRide) {
            _bottomWidgetHeight = 218;
          } else {
            _bottomWidgetHeight = 175;
          }
          isRideNowLoad.value =
              widget.mapMainController.vehicleTypeModel != null &&
                  widget.mapMainController.rideNowLoadingController.value == 1 &&
                  widget.mapMainController.tripCalculationModel != null;

          if (widget.mapMainController.rideNowLoadingController.value == 0) {
            if (  widget.mapMainController.locationData.length >= 2 &&
                widget.mapMainController.locationData.last.location !=null &&
                widget.mapMainController.locationData.last.location!.isNotEmpty) {
              widget.mapMainController.vehicleCatAnimController?.forward();
              widget.mapMainController.setLocIconPositionForCategory();
            }
            widget.mapMainController.driverInfoAnimController?.reverse();
            widget.mapMainController.confirmPopupAnimController?.reverse();
          }

            if (!isRideNowLoad.value &&   widget.mapMainController.isUserInTrip) {
              _currentSize = _minSize;
              Future.delayed(Duration(milliseconds: 500)).then((_) {
                widget.mapMainController.strServiceUnavailable = "";
              });
            }


          debugPrint('draggableScrollableController attach: ${draggableScrollableController.isAttached}');
          if (draggableScrollableController.isAttached) {
            draggableScrollableController.reset();
          }
        });
        return Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: <Widget>[
            if (isRideNowLoad.value)
              Padding(
                padding:  EdgeInsetsDirectional.only(bottom: _bottomWidgetHeight),
                child: DraggableScrollableSheet(
                  initialChildSize: _currentSize,
                  minChildSize: _minSize,
                  maxChildSize: _maxSize,
                  controller: draggableScrollableController,
                  builder: (BuildContext context, scrollController) {
                    _listviewController = scrollController;
                    return WidgetSize(
                      onChange: (Size size) {
                        widget.mapMainController.vehicleCatHeight = size.height;
                        debugPrint("widget.mapMainController.vehicleCatHeight: ${widget.mapMainController.vehicleCatHeight} --- ${widget.mapMainController.locationData}");
                          if ((!widget.mapMainController.isUserInTrip || globals.tripStatus == "") && widget.mapMainController.locationData.isNotEmpty) {
                            widget.mapMainController.updatePadding(widget.mapMainController.vehicleCatHeight + _bottomWidgetHeight);
                          }

                      },
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: AppColors.PRIMARY_LIGHT_COLOR,
                        ),
                        child: CustomScrollView(
                          cacheExtent: 9999,
                          semanticChildCount:  widget.mapMainController.nearestDriversCategoryList.length,
                          controller: _listviewController,
                          slivers: [
                            ...sliverAppBar(),
                            sliverBodyContent(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: bottomWidget(
                    isRideNowLoad.value, widget.mapMainController.rideNowLoadingController.value),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> sliverAppBar() {
    return [
      SliverToBoxAdapter(
        child: ValueListenableBuilder<bool>(
            valueListenable: _isMaximized,
            builder: (context, value,child) {
              return AnimatedOpacity(
                opacity: _isMaximized.value ? 0.0 : 1.0,
                duration: Duration(milliseconds: 600),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 4,
                    margin: const EdgeInsetsDirectional.only(top: 14.0),
                    decoration: BoxDecoration(
                        color: AppColors.PrecautionInstructionCancel,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                  ),
                ),
              );
            }),
      ),
      ValueListenableBuilder<bool>(
          valueListenable: _isMaximized,
          builder: (context, value,child) {
            return SliverAppBar(
              title: _isMaximized.value
                  ? AnimatedOpacity(
                opacity: _isMaximized.value ? 1.0 : 0.0,
                duration: Duration(milliseconds: 600),
                child: Text(
                  'pick_a_ride'.tr,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontSize: AppDimen.text_size_18),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              )
                  : AnimatedOpacity(
                opacity: _isMaximized.value ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text('choose_a_ride'.tr,
                        style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_12,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),
              primary: false,
              pinned: true,
              centerTitle: true,
              automaticallyImplyLeading: true,
              backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
              actions: <Widget>[const SizedBox.shrink()],
              leading: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _isMaximized.value ? 1.0 : 0.0,
                child: InkWell(
                  onTap: () {
                    if(_listviewController != null) {
                      _resetDraggableSheet(_listviewController!);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsetsDirectional.all(10),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.COMMON_BG_COLOR),
                    child: SvgPicture.asset(
                      primaryDownArrow,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            );
          }),
    ];
  }

  Widget sliverBodyContent() {
    _vehicleCatWidgets.clear();
    widget.mapMainController.nearestDriversCategoryList.asMap().forEach((index, value){
      getDriversWithCategoryAndPrice result = widget.mapMainController.nearestDriversCategoryList[index];
      _vehicleCatWidgets.add(
          vehicleListItem(
            key: ValueKey(
                'message-${result.id}'),
            result: result,
            index: index,
            mapMainController: widget.mapMainController,
            iconWidgetMap: _vehicleCatImageWidget,
          ));
    });

    return  SliverList(
      delegate: SliverChildBuilderDelegate(
        addRepaintBoundaries: false,
        findChildIndexCallback: (key) {
          final ValueKey<String> valueKey = key as ValueKey<String>;
          final index = widget.mapMainController.nearestDriversCategoryList
              .indexWhere((m) => 'message-${m.id}' == valueKey);
          debugPrint('findChildIndexCallback: ${index}');
          if (index > 0 ) return index;

          else return null;
        },
            (BuildContext context, int index) {

          return _vehicleCatWidgets[index];
        },
        childCount: widget.mapMainController.nearestDriversCategoryList.length,  // Total number of items
      ),

    );
  }



  bottomWidget(bool isRideNowLoad, var tripCalculateSnapshot) {
    return WidgetSize(
      onChange: (Size size) {
        if (widget.mapMainController.isScheduleRide) {
          _bottomWidgetHeight = 218;
        } else {
          _bottomWidgetHeight = 175;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.PRIMARY_LIGHT_COLOR,
          boxShadow: [
            BoxShadow(
              color: AppColors.PRIMARY_DARK_COLOR.withValues(alpha:0.1),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isRideNowLoad)
              Container(
                alignment: Alignment.center,
                color: AppColors.PRIMARY_LIGHT_COLOR,
                height: 165,
                child: Text(
                  tripCalculateSnapshot ==2 && widget.mapMainController.nearDriverErrMsg !=null && widget.mapMainController.nearDriverErrMsg!.isNotEmpty ?
                  widget.mapMainController.nearDriverErrMsg! :
                  widget.mapMainController.strServiceUnavailable.isNotEmpty
                      ? widget.mapMainController.strServiceUnavailable
                      : 'pls_wait_to_get_veh_details'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_14),
                ),
              ),
            if (isRideNowLoad)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 24, end: 24, top: 18, bottom: 20),
                child: GetBuilder<MapMainController>(
                    id:'promoListController',
                    builder: (_) {
                      return InkWell(
                        onTap: () {
                          widget.mapMainController.updateRxValue(widget.mapMainController.rideComfortController,true);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SvgPicture.asset(
                              rideComfortSvg,
                              width: 21.0,
                              height: 16.0,
                              colorFilter: ColorFilter.mode(
                                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                            ),
                            const  SizedBox(
                              width: 11.0,
                            ),
                            Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.6),
                              child: Text(
                                'Ride_comfort_option'.tr,
                                style: TextStyle(
                                    fontFamily: AppFont.font,
                                    fontSize: AppDimen.text_size_16,
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Obx((){
                              return Visibility(
                                  visible:widget.mapMainController.selectedRides.isNotEmpty
                                      ? widget.mapMainController.selectedRides.length > 0
                                      : false,
                                  child: Container(
                                    margin: const EdgeInsetsDirectional.only(
                                        bottom: 10),
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    child: Text(
                                      "${widget.mapMainController.selectedRides.length}",
                                      style: TextStyle(
                                          fontFamily: AppFont.font,
                                          fontSize: AppDimen.text_size_8,
                                          color: AppColors.PRIMARY_LIGHT_COLOR,
                                          fontWeight: FontWeight.w400),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ));
                            }),
                            Spacer(),
                            GetBuilder<MapMainController>(
                                id:'promoListController',
                                builder: (_) {
                                  return RotatedBox(
                                    quarterTurns: globals.isRTLLang ? 4 : 2,
                                    child: SvgPicture.asset(
                                      primaryLeftArrow,
                                      fit: BoxFit.scaleDown,
                                      height: 15,
                                      width: 9,
                                      colorFilter: ColorFilter.mode(
                                          AppColors.PRIMARY_ICON_COLOR,
                                          BlendMode.srcIn),
                                    ),
                                  );
                                }),
                          ],
                        ),
                      );
                    }),
              ),
            Container(
              margin:const  EdgeInsetsDirectional.symmetric(horizontal: 24),
              color: AppColors.BORDERCOLOR,
              height: 1.0,
            ),
            if (isRideNowLoad)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 24, end: 24, top: 18, bottom: 20),
                child: GetBuilder<MapMainController>(
                    id:'promoListController',
                    builder: (_) {
                      return InkWell(
                        onTap: () {
                          globals.isPromoForCategory = true;
                          widget.mapMainController
                              .setNavigation( AppRoutes.APP_PROMO_CODE);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 28.0,
                              height: 17.0,
                              child: SvgPicture.asset(
                                couponSvg,
                                colorFilter: ColorFilter.mode(
                                    AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(
                              width: 11.0,
                            ),
                            Expanded(
                              child: Text(
                                widget.mapMainController.isSpecialApplied
                                    ? "'${widget.mapMainController.appliedCoupon}' ${'coupon_applied'.tr}"
                                    : 'coupon_code'.tr,
                                style: TextStyle(
                                    fontFamily: AppFont.font,
                                    fontSize: AppDimen.text_size_16,
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            GetBuilder<MapMainController>(
                                id:'promoListController',
                                builder: (_) {
                                  return RotatedBox(
                                      quarterTurns: globals.isRTLLang ? 4 : 2,
                                      child: SvgPicture.asset(
                                        primaryLeftArrow,
                                        fit: BoxFit.scaleDown,
                                        height: 15,
                                        width: 9,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_ICON_COLOR,
                                            BlendMode.srcIn),
                                      ));
                                }),
                          ],
                        ),
                      );
                    }),
              ),
            if (widget.mapMainController.isScheduleRide && isRideNowLoad)
              Container(
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                color: AppColors.BORDERCOLOR,
                height: 1.0,
              ),
            if (widget.mapMainController.isScheduleRide && isRideNowLoad)
              Padding(
                padding:
                const EdgeInsetsDirectional.only(top: 18.0, bottom: 8.0),
                child: widget.mapMainController.selScheduleFromDateTime != null
                    ? Text(
                  "*${DateFormat(globals.scheduleRideDateFormat).format(widget.mapMainController.selScheduleFromDateTime!)} at ${DateFormat(globals.scheduleRideTimeFormat).format(widget.mapMainController.selScheduleFromDateTime!)} - ${DateFormat(globals.scheduleRideTimeFormat).format(getTimeByAddMin(widget.mapMainController.selScheduleFromDateTime!, 10))}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontSize: AppDimen.text_size_14),
                )
                    : const SizedBox.shrink(),
              ),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsetsDirectional.only(bottom: 10.0, end: 20.0, start: 20.0),
              padding: const EdgeInsetsDirectional.only(
                top: 0.0,
                bottom: 3.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.PRIMARY_DARK_COLOR,
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
              child: tripCalculateSnapshot != null &&
                  tripCalculateSnapshot == 0
                  ? Center(
                child: SizedBox(
                  height: 15.0,
                  width: 15.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    backgroundColor: AppColors.BLACK,
                    valueColor: new AlwaysStoppedAnimation<Color>(
                        AppColors.INDICATOR_COLOR),
                  ),
                ),
              )
                  : (tripCalculateSnapshot != null &&
                  tripCalculateSnapshot == 1)
                  ? ValueListenableBuilder<int>(
                  valueListenable: widget.mapMainController.getSelectedCabController(),
                  builder: (context, selectedCab,child) {
                    debugPrint("123destPlaceController.value: 345 ${widget.mapMainController.isScheduleRide}");
                    return PrimaryButton(
                      buttonTitle: !widget.mapMainController.isScheduleRide
                          ? widget.mapMainController.isCabAvailable
                          ? 'ride_now'.tr
                          : 'no_cabs'.tr
                          : 'Schedule_a_Ride'.tr,
                      buttonImage: (widget.mapMainController.isScheduleRide ||
                          widget.mapMainController.isCabAvailable)
                          ? primaryRightArrowSvg
                          : "",
                      callback: () {
                        widget.mapMainController.tripFinalAmount = null;
                        if (widget.mapMainController.isScheduleRide) {
                          globals.closeKeyBoard = false;
                          widget.mapMainController.checkInternet(
                                  () {
                                widget.mapMainController.setNavigation(
                                    AppRoutes.CONFIRM_SCHEDULE_RIDE);
                              }, true);
                        } else {
                          if (widget.mapMainController.isCabAvailable) {
                            if(_listviewController != null) {
                              _resetDraggableSheet(_listviewController!);
                            }
                            globals.closeKeyBoard = false;
                            widget.mapMainController.checkInternet(
                                widget.mapMainController.initiateRide,
                                true);
                          }
                        }
                      },
                    );
                  })
                  : (tripCalculateSnapshot != null &&
                  tripCalculateSnapshot == 2)
                  ? InkWell(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_){
                    widget.mapMainController.seRideNowLoadingController(0);
                    widget.mapMainController.checkInternet(() {
                      widget.mapMainController.openVehicleCategoryList(
                          widget.mapMainController
                              .isScheduleRideIconEnable);
                    }, true);
                  });
                },
                child: Center(
                  child: Text(
                    'try_again'.tr,
                    style: TextStyle(
                      color:
                      AppColors.WHITE_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                ),
              )
                  : Center(
                child: SizedBox(
                  height: 15.0,
                  width: 15.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    backgroundColor: AppColors.PRIMARY_DARK_COLOR,
                    valueColor: new AlwaysStoppedAnimation<Color>(
                        AppColors
                            .INDICATOR_COLOR),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _resetDraggableSheet(ScrollController scrollController) {
    draggableScrollableController.animateTo(
      _minSize,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutBack,
    );
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutBack,
    );
  }



  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
        dateTime.minute + minToAdd);
  }
}

class vehicleListItem extends StatefulWidget {
  final getDriversWithCategoryAndPrice result;
  final int index;
  final ValueKey<String> key;
  final MapMainController mapMainController;
  final Map<String,Widget> iconWidgetMap;
  vehicleListItem({
    required this.key,
    required this.result,
    required this.index,
    required this.mapMainController,
    required this.iconWidgetMap,
  }) : super(key: key);

  @override
  State<vehicleListItem> createState() => _vehicleListItemState();
}

class _vehicleListItemState extends State<vehicleListItem> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(widget.index== 0 &&widget.mapMainController.selectedCabIndex==0)
        selectCategory(widget.index, widget.result);
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    bool isCabAvailable = widget.result.lat != 0.0 &&  widget.result.lat != null;
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.index== 0 &&widget.mapMainController.selectedCabIndex==0)
        selectCategory(widget.index, widget.result);
    });
    return  InkWell(
      key:  widget.key,
      onTap: () {
        selectCategory(widget.index,widget.result);
      },
      child: ValueListenableBuilder<int>(
          valueListenable: widget.mapMainController.getSelectedCabController(),
          builder: (context, snapshot,child) {
            Get.printInfo(info: "isScheduleRide--> ${widget.mapMainController.isScheduleRide}");
            return  Visibility(
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24,vertical: 15,),
                color: (widget.mapMainController.selectedCatId ==0 ? widget.index==0 : widget.result.id ==widget. mapMainController.selectedCatId)
                    ? AppColors.COMMON_BG_COLOR
                    : Colors.transparent,
                child: Row(
                  children: [
                    _getVehicleCategoryImageWidget(url: globals.UPLOAD_URL + "/images/category/" + (widget.result.categoryImage ?? '')) ?? const SizedBox.shrink(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.result.categoryName ?? "",
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (!widget.mapMainController.isScheduleRide && isCabAvailable) ...[
                                  InkWell(
                                    onTap: () {
                                      Map<String, dynamic> map = Map<String, dynamic>();
                                      map["basePrice"] = widget.result.basePrice;
                                      map["currency"] = widget.result.convertCurrency;
                                      map["unitPrice"] = widget.result.unitPrice;
                                      map["minutePrice"] = widget.result.minutePrice;
                                      map["categoryName"] = widget.result.categoryName;
                                      map["categoryImage"] = widget.result.categoryImage;
                                      map["capacity"] = widget.result.capacity;
                                      map['waitingFare'] = widget.result.waitingFare;

                                      if (map != null) {
                                        widget.mapMainController.vehCatDetailController(map);
                                        widget.mapMainController.vehicleCatDetailAnimController?.forward();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 5.0),
                                      child: SvgPicture.asset(
                                        vehicleInfoSvg,
                                        width: 18.0,
                                        height: 18.0,
                                        colorFilter: ColorFilter.mode(
                                            AppColors.PRIMARY_ICON_COLOR,
                                            BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            if (!widget.mapMainController.isScheduleRide)
                              Text(
                                isCabAvailable ?
                                "${widget.result.driverReachDuration} ${'away'.tr}" :
                                'no_cabs'.tr,
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w400,
                                    fontSize: AppDimen.text_size_14),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        if (widget.mapMainController.isSpecialApplied &&
                            (widget.result.specialTripTotalFare ?? 0.00) > 0.00)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 2.0),
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                          color: AppColors.BLACK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_18,
                                          fontWeight: FontWeight.w600),
                                      children: [
                                        TextSpan(
                                          text: globals.currencySymbol,
                                        ),
                                        TextSpan(
                                          text: '${widget.result.specialTripTotalFare}',
                                          style: TextStyle(
                                            fontFamily: AppFont.font,
                                          ),
                                        ),
                                      ])),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 2.0),
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: RichText(
                              text: TextSpan(
                                  style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_11,
                                  ),
                                  children: [
                                    TextSpan(
                                        text: globals.currencySymbol,
                                        style: widget.mapMainController
                                            .isSpecialApplied &&
                                            (widget.result.specialTripTotalFare ??
                                                0.00) >
                                                0.00
                                            ? TextStyle(
                                            decoration:
                                            TextDecoration.lineThrough,
                                            fontSize: AppDimen.text_size_14,
                                            fontWeight: FontWeight.w400)
                                            : TextStyle(
                                            fontSize: AppDimen.text_size_18,
                                            fontWeight: FontWeight.w600)),
                                    TextSpan(
                                      text: '${widget.result.totalFareForRider}',
                                      style:widget.mapMainController.isSpecialApplied &&
                                          (widget.result.specialTripTotalFare ??
                                              0.00) >
                                              0.00
                                          ? TextStyle(
                                          decoration:
                                          TextDecoration.lineThrough,
                                          fontFamily: AppFont.font,
                                          fontSize: AppDimen.text_size_14,
                                          fontWeight: FontWeight.w400)
                                          : TextStyle(
                                          decoration: TextDecoration.none,
                                          fontFamily: AppFont.font,
                                          fontSize: AppDimen.text_size_18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  void selectCategory(int index,getDriversWithCategoryAndPrice result){
    selectVehicle(index, result);
    widget.mapMainController.selectedCatId = result.id;
    widget.mapMainController.setSelectedCabController(index, result);
  }

  Widget _getVehicleCategoryImageWidget({required String url}) {
    if( widget.iconWidgetMap[url] !=null)
      return widget.iconWidgetMap[url]!;

    return FutureBuilder<Map<String, Uint8List>>(
      future: widget.mapMainController.appPreferences!.getUint8ListMap(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.scaleDown,
                image: CachedNetworkImageProvider(url),
              ),
            ),
          );
        }

        Map<String, Uint8List> iconmap = snapshot.data!;
        Uint8List? markerimg;
        if (iconmap[url] == null) {
          http.get(Uri.parse(url)).then((request) {
            widget.mapMainController.getBytesFromAsset1(request.bodyBytes).then((image) {
              if (image != null) {
                iconmap[url] = image;
                widget.mapMainController.appPreferences!.saveUint8ListMap(dataMap: iconmap);
                if (mounted) setState(() {});
              }
            });
          });
        } else {
          markerimg = iconmap[url];
        }

        widget.iconWidgetMap[url] = Container(
          height: 58,
          width: 58,
          decoration: markerimg == null ?
          BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.scaleDown,
              image: CachedNetworkImageProvider(url),
            ),
          ) : null,
          child: markerimg != null ? Image.memory(
              markerimg,
              fit: BoxFit.scaleDown
          ) : null,
        );
        return widget.iconWidgetMap[url]!;
      },
    );
  }

  void selectVehicle(int index, getDriversWithCategoryAndPrice result) {
    bool isCabAvailable = result.lat != 0.0 &&  result.lat != null;
    widget.mapMainController.selectedVehType = result.id;
    debugPrint("result.specialTripTotalFare.toString(): ${result.specialTripTotalFare.toString()} ---${widget.mapMainController.tripCalculationModel}");
    if (widget.mapMainController.isSpecialApplied &&
        double.parse(result.specialTripTotalFare.toString()) > 0.00) {
      widget.mapMainController.estimatedScheduleAmount =
          result.specialTripTotalFare.toString();
    } else {
      if (widget.mapMainController.isSpecialApplied  && widget.mapMainController.tripCalculationModel !=null) {
        widget.mapMainController.toast.show(
          context:Get.overlayContext!,
          message: 'Coupon_Not_Applicable'.tr,
        );
      }
      widget.mapMainController.estimatedScheduleAmount = result.totalFareForRider.toString();
    }
    if (widget.mapMainController.isScheduleRide || isCabAvailable) {
      if (index != 0 ) {
        widget.mapMainController.isVehicleCatDetailOpen = true;
      }

      if (widget.mapMainController.isSpecialApplied &&
          double.parse(result.specialTripTotalFare.toString()) > 0.00) {
        widget. mapMainController.setTotalFareController(result.specialTripTotalFare.toString());
      } else {
        widget.mapMainController.setTotalFareController(result.totalFareForRider);
      }
      widget. mapMainController.baseUnit = result.basePrice;
      widget.mapMainController.riderServiceFee = result.riderServiceFee;
      widget.mapMainController.driverServiceFee = result.driverServiceFee;
      widget.mapMainController.estimatedFare = result.priceForDistance;
      widget.mapMainController.totalFare = result.totalFare;
      widget.mapMainController.vehicleTypeModel?.getCategories?.result?[index]
          .basePrice = result.basePrice;
      widget.mapMainController.vehicleTypeModel?.getCategories?.result?[index]
          .currency = result.convertCurrency;
      widget.mapMainController.vehicleTypeModel?.getCategories?.result?[index]
          .unitPrice = result.unitPrice;
      widget.mapMainController.vehicleTypeModel?.getCategories?.result?[index]
          .minutePrice = result.minutePrice;
      widget.mapMainController.isCabAvailable = true;
    } else {
      widget.mapMainController.isCabAvailable = false;
    }
  }
}