import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart' show Get;
import 'package:provider/provider.dart';
import 'package:wooberly_driver/controller/base_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_button.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../controller/profile_controllers/edit_account_controller.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';

class VehiclePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VehiclePreviewView();
  }
}

class VehiclePreviewView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => VehiclePreviewViewState();
}

class VehiclePreviewViewState extends State<VehiclePreviewView> {
  bool updatedChildSeat = false, updatedWheelChair = false;
  var rxIsEdited = ReactiveVariable("rxIsEdited", false);
  final EditAccountController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    PrimaryScaffold.avoidLoader = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.checkInternet(_controller.getProfileInfo, false);
      updatedChildSeat = globals.isChildSeatAvailable;
      updatedWheelChair = globals.isWheelChairAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: your_vehicle_details.tr,
        body: Column(
          children: [
            Expanded(
              child: GetBuilder(
                init: EditAccountController(),
                  id: _controller.rxGetUpdatedDetailsController.id,
                  builder: (val) {
                    return (_controller.rxGetUpdatedDetailsController.value == false)
                        ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                    left: 24,
                                    right: 24,
                                    top: 30.0,
                                  ),
                                  decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_WHITE,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: <Widget>[
                                            CachedNetworkImage(
                                              height: 55.0,
                                              width: 55.0,
                                              fit: BoxFit.scaleDown,
                                              imageUrl: globals.vehicleImage,
                                              placeholder: (context, url) =>
                                                  SvgPicture.asset(
                                                    vehicleTypeSvg,
                                                    height: 55.0,
                                                    width: 55.0,
                                                  ),
                                            ),
                                            SizedBox(
                                              width: 14,
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                mainAxisSize:
                                                MainAxisSize.min,
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      vehicle_type.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleType,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.zero,
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 14,
                                            top: 10.0,
                                            right: 14.0,
                                            bottom: 14.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      vehicle_make.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleName,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(vertical: 0),
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ), Container(
                                        margin: const EdgeInsets.only(
                                            left: 14,
                                            top: 10.0,
                                            right: 14.0,
                                            bottom: 14.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      vehicle_model.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleModel,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(vertical: 0),
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ), Container(
                                        margin: const EdgeInsets.only(
                                            left: 14,
                                            top: 10.0,
                                            right: 14.0,
                                            bottom: 14.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      vehicle_year.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleYear,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(vertical: 0),
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 14,
                                            top: 10.0,
                                            right: 14.0,
                                            bottom: 14.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      license_plate.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleNumber
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(vertical: 0),
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 14,
                                            top: 10.0,
                                            right: 14.0,
                                            bottom: 14.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      vehicle_color.tr,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: AppDimen
                                                            .text_size_16,
                                                      )),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        globals.vehicleColor !=
                                                                null
                                                            ? globals
                                                                .vehicleColor
                                                            : "",
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_14,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ), Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(vertical: 0),
                                        child: new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ),
                                      InkWell(
                                        onTap:(){
                                          viewVehicleImageDialog();
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              left: 14,
                                              top: 10.0,
                                              right: 14.0,
                                              bottom: 14.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                        vehicle_image.tr,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: AppDimen
                                                              .text_size_16,
                                                        )),
                                                  ],
                                                ),
                                              ),
                                              SvgPicture.asset(
                                                rightArrowSvg,
                                                matchTextDirection: true,
                                                height: 15.0,
                                                width: 10.0,
                                                colorFilter: ColorFilter.mode(
                                                    AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 24,
                                    end: 24,
                                    top: 30,
                                  ),
                                  child: Text(
                                    Vehicle_comfort_options.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                      start: 24, end: 24, top: 20, bottom: 20),
                                  decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_WHITE,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Column(
                                    children: [
                                      GetBuilder(
                                          init: EditAccountController(),
                                          id: _controller.rxChildSeatController.id,
                                          builder: (val) {
                                            return Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              top: 10.0),
                                                      child: InkWell(
                                                        onTap: () {
                                                          bool newValue = !_controller.rxChildSeatController.value;
                                                          _controller.change(rxVariable: _controller.rxChildSeatController, value: newValue);
                                                          updatedChildSeat = newValue;
                                                          _controller.change(rxVariable: rxIsEdited, value: (updatedChildSeat != globals.isChildSeatAvailable || updatedWheelChair != globals.isWheelChairAvailable));
                                                        },
                                                        child: new Container(
                                                          height: 50,
                                                          color: AppColors.PRIMARY_COLOR_WHITE,
                                                          padding: EdgeInsetsDirectional.only(start: 20, end: 20),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                margin:
                                                                    EdgeInsetsDirectional
                                                                        .only(
                                                                            end:
                                                                                15),
                                                                height: 22,
                                                                width: 22,
                                                                decoration:
                                                                    BoxDecoration(
                                                                        color: _controller.rxChildSeatController.value ==
                                                                                true
                                                                            ? AppColors
                                                                                .PRIMARY_COLOR_DARK
                                                                            : Colors
                                                                                .transparent,
                                                                        border:
                                                                            Border
                                                                                .all(
                                                                          color: AppColors
                                                                              .PRIMARY_COLOR_DARK,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.all(
                                                                                Radius.circular(4))),
                                                                child: Visibility(
                                                                  visible: _controller.rxChildSeatController.value == true,
                                                                  child:
                                                                      SvgPicture
                                                                          .asset(
                                                                    rideComfortSelectedSvg,
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                child: SvgPicture
                                                                    .asset(
                                                                  childSeatSvg,
                                                                  width: 16,
                                                                  height: 12,
                                                                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .symmetric(
                                                                          horizontal: 11.0),
                                                                  child: Text(
                                                                    child_seat_availability.tr,
                                                                    style: TextStyle(
                                                                        color: AppColors
                                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontSize:
                                                                            AppDimen
                                                                                .text_size_14,
                                                                        fontFamily:
                                                                            AppFont
                                                                                .font),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                      GetBuilder(
                                        init: EditAccountController(),
                                          id: _controller.rxWheelChairController.id,
                                          builder: (val) {
                                            return Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                             vertical: 10.0),
                                                      child: InkWell(
                                                        onTap: () {
                                                          bool newValue = !_controller.rxWheelChairController.value;
                                                          _controller.change(rxVariable: _controller.rxWheelChairController, value: newValue);
                                                          updatedWheelChair = newValue;
                                                          _controller.change(rxVariable: rxIsEdited, value: (updatedChildSeat != globals.isChildSeatAvailable || updatedWheelChair != globals.isWheelChairAvailable));
                                                        },
                                                        child: new Container(
                                                          height: 50,
                                                          color: AppColors.PRIMARY_COLOR_WHITE,
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      start: 20,
                                                                      end: 20),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                margin:
                                                                    EdgeInsetsDirectional
                                                                        .only(
                                                                            end:
                                                                                15),
                                                                height: 22,
                                                                width: 22,
                                                                decoration:
                                                                    BoxDecoration(
                                                                        color: _controller.rxWheelChairController.value ==
                                                                                true
                                                                            ? AppColors
                                                                                .PRIMARY_COLOR_DARK
                                                                            : Colors
                                                                                .transparent,
                                                                        border:
                                                                            Border
                                                                                .all(
                                                                          color: AppColors
                                                                              .PRIMARY_COLOR_DARK,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.all(
                                                                                Radius.circular(4))),
                                                                child: Visibility(
                                                                  visible: _controller.rxWheelChairController.value == true,
                                                                  child:
                                                                      SvgPicture
                                                                          .asset(
                                                                    rideComfortSelectedSvg,
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                                                                  ),
                                                                ),
                                                              ),
                                                              SvgPicture
                                                                  .asset(
                                                                wheelChairSvg,
                                                                width: 15,
                                                                height: 16,
                                                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                              ),
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .only(
                                                                          start:
                                                                              11.0,
                                                                          end:
                                                                              11.0),
                                                                  child: Text(
                                                                    wheel_chair_availability.tr,
                                                                    style: TextStyle(
                                                                        color: AppColors
                                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontSize:
                                                                            AppDimen
                                                                                .text_size_14,
                                                                        fontFamily:
                                                                            AppFont
                                                                                .font),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink();
                  }),
            ),
            GetBuilder<EditAccountController>(
              init: EditAccountController(),
              id: rxIsEdited.id,
              builder: (val) {
                return rxIsEdited.value == true
                    ? Container(
                        padding: EdgeInsetsDirectional.only(
                            bottom: 24, start: 24, end: 24),
                        child: PrimaryButton(
                          buttonTitle: update.tr,
                          buttonImage: primaryBtnArrow,
                          callback: () {
                            _updateVehicleDetail();
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              })
          ],
        ),

      );
    });
  }

  void _updateVehicleDetail() {
    _controller
        .callVehicleDetails(updatedChildSeat, updatedWheelChair)
        .then((value) {
      if (value.isNotEmpty) {
        _controller.showInSnackBar(value);
      } else {
        _controller.showInSnackBar(UpdateSuccess.tr);
        _controller.change(rxVariable: rxIsEdited, value: false);
      }
    });
  }

   viewVehicleImageDialog() {
    Get.dialog(
        Obx(
          () {
            return globals.isAutoThemeUpdated.value != null ? AlertDialog(
              backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
              ),
              titlePadding: EdgeInsets.zero, // Remove default padding for custom layout
              contentPadding: EdgeInsets.zero,
              content: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 12,bottom: 21,start: 21,end: 21),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title section
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top:12,bottom: 24),
                          child: Center(
                            child: Text(
                              vehicle_photo.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 243,
                          height: 321,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl:
                              globals.UPLOAD_URL+ "/images/vehicle/"+globals.vehiclePhoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        Get.back(); // Close the dialog
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK,BlendMode.srcIn),
                            circleCloseSvg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ) : SizedBox.shrink();
          }
        )
    );
  }
}