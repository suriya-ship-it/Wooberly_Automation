import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/spin_kit/three_bounce.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';

class PromoCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PromoCodeView();
  }
}

class PromoCodeView extends StatefulWidget {
  @override
  _PromoCodeState createState() => _PromoCodeState();
}

class _PromoCodeState extends State<PromoCodeView> {
  MapMainController _mapMainController = Get.find();
  FocusNode _focus = new FocusNode();
  FocusNode _searchFocus = new FocusNode();

  double circularRadius = 15.0;

  @override
  void initState() {
    _mapMainController = MapMainController();
    _mapMainController.refreshCouponCodeController();
    if (_mapMainController.promoResults != null) {
      _mapMainController.promoResults?.clear();
    }
    _mapMainController.isLoading = true;
    if (!_mapMainController.isSpecialApplied) {
      _mapMainController.selectedSpecialID = 0;
      _mapMainController.couponController.clear();
      _mapMainController.promoStreamController(true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.setButtonLoading();
    });
    Future.delayed(Duration(seconds: 1)).then((_) {
      _mapMainController.checkInternet(getPromoCode, false);
    });

    _focus.addListener(_onFocusChange);

    if (_mapMainController.selectedSpecialID != null && _mapMainController.selectedSpecialID != 0)
      _mapMainController.couponController.text = _mapMainController.appliedCoupon;
    super.initState();
  }

  void _onFocusChange() {}

  @override
  Widget build(BuildContext context) {
    double opaVal = 0.0;
    if (_mapMainController.isScheduleRide && _mapMainController.selScheduleFromDateTime != null) {
      _mapMainController.selScheduleToDateTime =
          getTimeByAddMin(_mapMainController.selScheduleFromDateTime!, 10);
    }
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: !globals.isPromoForCategory ?'coupon_code_title'.tr :'coupon_code'.tr,
        body: Container(
          color: AppColors.COMMON_BG_COLOR,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                globals.isPromoForCategory
                    ? ColoredBox(
                        color: AppColors.COMMON_BG_COLOR,
                        child:  GetBuilder<MapMainController>(
                            id: 'CouponCodeController',
                            builder: (_) {
                              if (_mapMainController.couponController.text.isEmpty) {
                                opaVal = 0.0;
                              } else {
                                opaVal = 1.0;
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_LIGHT_COLOR,
                                  borderRadius: BorderRadius.all(Radius.circular(3.0)),
                                ),
                                margin: const EdgeInsetsDirectional.only(start: 24,end:24,top: 37),
                                padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    SvgPicture.asset(
                                      couponSvg,
                                      width: 13.0,
                                      height: 13.0,
                                      colorFilter:
                                      ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
                                        child: TextField(
                                          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
                                          textCapitalization: TextCapitalization.characters,
                                          textAlign: TextAlign.start,
                                          controller: _mapMainController.couponController,
                                          focusNode: _focus,
                                          // optional: stop it from ever wrapping/growing vertically
                                          maxLines: 1,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            hintText: 'enter_promo_code'.tr,
                                            hintStyle: TextStyle(
                                                color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                                fontWeight: FontWeight.w400,
                                                fontSize: AppDimen.text_size_16,
                                                fontFamily: AppFont.font),
                                          ),
                                          style: TextStyle(
                                              color: AppColors.BLACK_TEXT_COLOR,
                                              fontWeight: FontWeight.w400,
                                              fontSize: AppDimen.text_size_16,
                                              fontFamily: AppFont.font),
                                        ),
                                      ),
                                    ),
                                    GetBuilder<MapMainController>(
                                      id: 'promoListController',
                                      builder: (_) {
                                        bool isShowApply = true;
                                        if (_mapMainController.selectedSpecialID == null ||
                                            _mapMainController.selectedSpecialID == 0) {
                                          isShowApply = true;
                                        } else if (_mapMainController.promoResults != null &&
                                            _mapMainController.promoResults!.isNotEmpty) {
                                          for (var promoItem in _mapMainController.promoResults!) {
                                            if (_mapMainController.selectedSpecialID == promoItem.id &&
                                                _mapMainController.couponController.text.toUpperCase() ==
                                                    promoItem.code!.toUpperCase()) {
                                              isShowApply = false;
                                              break;
                                            } else if (_mapMainController.selectedSpecialID ==
                                                promoItem.id &&
                                                _mapMainController.couponController.text.toUpperCase() !=
                                                    promoItem.code!.toUpperCase()) {
                                              isShowApply = true;
                                              break;
                                            } else if (_mapMainController.selectedSpecialID !=
                                                promoItem.id &&
                                                _mapMainController.couponController.text.toUpperCase() ==
                                                    promoItem.code!.toUpperCase()) {
                                              isShowApply = true;
                                              break;
                                            } else {
                                              isShowApply = false;
                                            }
                                          }
                                        } else {
                                          isShowApply = false;
                                        }

                                        return Visibility(
                                          visible: opaVal == 1.0 && !_mapMainController.isLoading,
                                          child: PrimaryButton(
                                            buttonTitle: isShowApply ? 'apply'.tr : 'remove'.tr,
                                            titleSize: AppDimen.text_size_14,
                                            titleWeight: FontWeight.w400,
                                            buttonImage: primaryBtnArrow,
                                            iconWidth: 12,
                                            iconHeight: 9,
                                            maxWidth: 100,
                                            innerPadding: 10.0,
                                            height: 30,
                                            callback: () {
                                              if (isShowApply) {
                                                _mapMainController.isLoading = true;
                                                _mapMainController.couponController.text =
                                                    _mapMainController.couponController.text
                                                        .toUpperCase();
                                                _mapMainController.checkInternet(vaildatePromoCode, false);
                                              } else {
                                                _mapMainController.isSpecialApplied = false;
                                                _mapMainController.selectedSpecialID = 0;
                                                _mapMainController.couponController.clear();
                                                _mapMainController.tripCalculationModel = null;
                                                _mapMainController.promoStreamController(true);
                                                _mapMainController.promoStreamController.refresh();
                                                _mapMainController.isLoading = false;
                                                Get.back();
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                      )
                    : const SizedBox.shrink(),
                Container(
                    color: AppColors.COMMON_BG_COLOR,
                    margin: const EdgeInsetsDirectional.only(bottom: 10.0, top: 20.0, start: 24, end: 24),
                    height: globals.isPromoForCategory
                        ? MediaQuery.of(context).size.height / 1.4
                        : MediaQuery.of(context).size.height / 1.2,
                    child: Obx(
                      () {
                        int length = 0;
                        if (_mapMainController.promoList?.getPromoCode?.result != null) {
                          length = _mapMainController.promoList!.getPromoCode!.result!.length;
                        }
                        return _mapMainController.promoListController.value == true &&
                                !_mapMainController.isLoading &&
                                length == 0
                            ? Align(
                                alignment: Alignment.center,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    SvgPicture.asset(
                                      noPromoSvg,
                                      width: 60.0,
                                      height: 60.0,
                                      colorFilter:
                                          ColorFilter.mode(AppColors.LOCATION_ARRIVED_COLOR, BlendMode.srcIn),
                                    ),
                                    const SizedBox(
                                      height: 20.0,
                                    ),
                                    Text('no_promo_code'.tr,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : !_mapMainController.isLoading
                                ? Column(
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text('related_offers'.tr,
                                            style: TextStyle(
                                                color: AppColors.BLACK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppFont.font)),
                                      ),
                                      const SizedBox(
                                        height: 23,
                                      ),
                                      Container(
                                        height: 42,
                                        color: AppColors.PRIMARY_LIGHT_COLOR,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsetsDirectional.only(start: 15, end: 6),
                                              child: SvgPicture.asset(
                                                searchSvg,
                                                width: 13.0,
                                                height: 13.0,
                                                colorFilter: ColorFilter.mode(
                                                    AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                              ),
                                            ),
                                            Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsetsDirectional.only(top: 19),
                                                  child: TextField(
                                                    textAlign: TextAlign.start,
                                                    inputFormatters: <TextInputFormatter>[
                                                      UpperCaseTextFormatter()
                                                    ],
                                                    textCapitalization: TextCapitalization.characters,
                                                    onChanged: (text) {
                                                      _mapMainController.filterPromoCodes(text);
                                                    },
                                                    focusNode: _searchFocus,
                                                    decoration: new InputDecoration(
                                                        border: InputBorder.none,
                                                        hintText: 'Search_promo_code'.tr,
                                                        hintStyle: TextStyle(
                                                            color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: AppDimen.text_size_16,
                                                            fontFamily: AppFont.font)),
                                                    style: TextStyle(
                                                        color: AppColors.BLACK_TEXT_COLOR,
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: AppDimen.text_size_16,
                                                        fontFamily: AppFont.font),
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 23,
                                      ),
                                      Expanded(
                                        child: GetBuilder<MapMainController>(
                                            id: 'filterTypeController',
                                            builder: (_) {
                                              if (_mapMainController.promoResults != null &&
                                                  _mapMainController.promoResults!.length == 0 &&
                                                  !_mapMainController.isLoading) {
                                                return Container(
                                                  child: Text('No_result'.tr,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                                          fontSize: AppDimen.text_size_16,
                                                          fontWeight: FontWeight.bold)),
                                                );
                                              } else {
                                                return ListView.builder(
                                                    itemCount: _mapMainController.promoResults != null
                                                        ? _mapMainController.promoResults!.length
                                                        : 0,
                                                    itemBuilder: (BuildContext ctxt, int index) {
                                                      return createListItem(ctxt, index);
                                                    });
                                              }
                                            }),
                                      )
                                    ],
                                  )
                                : const SizedBox.shrink();
                      },
                    ))
              ],
            ),
          ),
        ),
      );
    });
  }
  Widget createListItem(BuildContext context, int index) {
    return InkWell(
      onTap: () {
        if (globals.isPromoForCategory) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          if (_mapMainController.couponController.text.isNotEmpty) {
            _mapMainController.couponController.text = _mapMainController.promoResults![index].code!;
            _mapMainController.refreshCouponCodeController();
          } else {
            _mapMainController.couponController.text = _mapMainController.promoResults![index].code!;
            _mapMainController.refreshCouponCodeController();
          }
        }
      },
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 23),
        decoration: BoxDecoration(
          color: AppColors.PRIMARY_LIGHT_COLOR,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                GetBuilder<MapMainController>(
                    id: 'CouponCodeController',
                    builder: (_) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.all(14),
                        child: _mapMainController.promoResults![index].image != null &&
                                _mapMainController.promoResults![index].image!.isNotEmpty
                            ? Container(
                                height: 62.0,
                                width: 62.0,
                                child: CachedNetworkImage(
                                  imageUrl: globals.UPLOAD_URL +
                                      "/images/promocode/" +
                                      _mapMainController.promoResults![index].image!,
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(scale: 1.5, image: imageProvider, fit: BoxFit.cover),
                                    ),
                                  ),
                                  placeholder: (context, url) => SpinKitThreeBounce(
                                    color: AppColors.PRIMARY_ICON_COLOR,
                                    size: 22.0,
                                  ),
                                  errorWidget: (context, _, url) => SvgPicture.asset(
                                    giftOpenSvg,
                                    width: 62.0,
                                    height: 62.0,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  ),
                                ),
                              )
                            : SvgPicture.asset(
                                giftOpenSvg,
                                width: 62.0,
                                height: 62.0,
                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              ),
                      );
                    }),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsetsDirectional.only(bottom: 2.0, top: 5),
                        padding: const EdgeInsetsDirectional.only(end: 5),
                        child: Text(_mapMainController.promoResults![index].title!,
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16,
                                fontFamily: AppFont.font)),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 5, bottom: 5),
                        child: Text(_mapMainController.promoResults![index].description!,
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontWeight: FontWeight.w400,
                                fontSize: AppDimen.text_size_12,
                                fontFamily: AppFont.font)),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Divider(
              color: AppColors.DIVIDER_COLOR,
              thickness: 1,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: 14,
                horizontal: 19,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 150,
                    ),
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        dashPattern: [4, 3],
                        color: AppColors.RADIO_BUTTON_COLOR,
                        radius: const Radius.circular(6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        strokeWidth: 1.2,
                      ),
                      child: Center(
                        child: Text(
                          _mapMainController.promoResults![index].code ?? "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_12,
                            fontFamily: AppFont.font,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GetBuilder<MapMainController>(
                      id: 'promoListController',
                      builder: (_) {
                        return Visibility(
                          visible: globals.isPromoForCategory,
                          child: InkWell(
                            onTap: () {
                              if (!_mapMainController.isLoading) {
                                if (_mapMainController.selectedSpecialID !=
                                    _mapMainController.promoResults![index].id) {
                                  _mapMainController.selectedSpecialID =
                                      _mapMainController.promoResults![index].id;
                                  _mapMainController.couponController.text =
                                      _mapMainController.promoResults![index].code!;
                                  _mapMainController.isLoading = true;
                                  _mapMainController.checkInternet(vaildatePromoCode, false);
                                } else {
                                  _mapMainController.isSpecialApplied = false;
                                  _mapMainController.selectedSpecialID = 0;
                                  _mapMainController.couponController.clear();
                                  _mapMainController.tripCalculationModel = null;
                                  _mapMainController.promoStreamController(true);
                                  _mapMainController.promoStreamController.refresh();
                                  _mapMainController.isLoading = false;
                                  Get.back();
                                }
                              }
                            },
                            child: Text(
                              _mapMainController.selectedSpecialID !=
                                      _mapMainController.promoResults![index].id
                                  ? 'apply'.tr
                                  : 'remove'.tr,
                              style: TextStyle(
                                  color: AppColors.PROMOCODE_LINK_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_12,
                                  fontFamily: AppFont.font),
                            ),
                          ),
                        );
                      })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute + minToAdd);
  }

  getPromoCode() {
    _mapMainController.setPromoListController(false);
    _mapMainController.isLoading = true;
    _mapMainController.getPromoCodeList().then((promoValues) {
      if (promoValues == "offline") {
        _mapMainController.netOffSnackbar(getPromoCode, false);
      } else if (promoValues.isNotEmpty) {
        _mapMainController.isLoading = false;
        _mapMainController.showInSnackBar(promoValues);
      } else {
        _mapMainController.isLoading = false;
        _mapMainController.setPromoListController(true);
        _mapMainController.refreshCouponCodeController();
      }
    });
  }

  vaildatePromoCode() {
    _mapMainController.isLoading = true;
    _mapMainController.setPromoListController(false);
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _mapMainController.vaildateCode().then((promoValues) {
      _mapMainController.setPromoListController(true);
      if (promoValues != null) {
        if (promoValues == "offline") {
          _mapMainController.checkInternet(vaildatePromoCode, false);
        } else if (promoValues.isNotEmpty) {
          _mapMainController.isLoading = false;
          _mapMainController.showInSnackBar(promoValues);
        } else {
          _mapMainController.updatePadding(220);
          _mapMainController.tripCalculationModel = null;
          _mapMainController.promoStreamController(true);
          _mapMainController.promoStreamController.refresh();
          _mapMainController.isLoading = false;
          Get.back();
        }
      } else {
        _mapMainController.isLoading = false;
      }
    });
  }

  @override
  void dispose() {
    if(!globals.isPromoForCategory)
    globals.isPromoForCategory = true;
    super.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}