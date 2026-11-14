import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/register_controller.dart';

import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/models/vehicle_type_model.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';
import 'document_item_view.dart';
import 'document_main.dart';

class VehicleDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VehicleDetailsView();
  }
}

class VehicleDetailsView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => VehicleDetailsViewState();
}

class VehicleDetailsViewState extends State<VehicleDetailsView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  String _vehicleModel = "Vehicle model";
  String selectedYear = "Vehicle manufacture year";
  final RegisterController _controller = Get.find();
  late List<Result> _modelDropDown;
  late BuildContext scoffoldcontext;

  final FocusNode fnvehiclename = FocusNode();
  final FocusNode fnvehiclemodel = FocusNode();
  final FocusNode fnvehicleno = FocusNode();
  final FocusNode fnvehiclecolor = FocusNode();
  bool firstClick = true;

  @override
  void initState() {
    _initPref();
    graphQlObject.loadGraphQLJson("login_graphql");
    Future.delayed(const Duration(milliseconds: 10), () {
      _controller.checkInternet(getVehicleCategories, false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
    graphQlObject.getGraphQlClientWithHeader();
  }

  Future<void> _initPref() async {
    globals.phnNo = App().appPreference.LoginNo.replaceFirst(RegExp(r'^0+'), '');
    globals.DialCode = App().appPreference.CountryCode;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          key: _scaffoldKey,
          appBarImage: !globals.isVehicleDetailsReq ? null : closeSvg,
          actionWidgets: [
            !globals.isVehicleDetailsReq
                ? const SizedBox.shrink()
                : Consumer<ModelTheme>(
                    builder: (context, ModelTheme themeNotifier, child) {
                    return InkWell(
                        onTap: () {
                          _controller.setLoadingController(true);
                          globals.front = "for logout";
                          _controller.setLogout(scoffoldcontext);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            sign_out.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_18),
                          ),
                        ),
                      );
                  })
          ],
          customAppBarFunction: () {
            if (!globals.isVehicleDetailsReq) {
              App().setBackNavigation();
            } else {
              var content = exit_app_content.tr;
              var cancel = btn_cancel.tr;
              var exit = exit_app.tr;
              exitConfirmDialog(content, cancel, exit);
            }
          },
          body: Builder(
            builder: (BuildContext context) {
              scoffoldcontext = context;
              return Stack(
                children: <Widget>[
                  new SingleChildScrollView(
                      child: new Form(
                          key: _formKey,
                          autovalidateMode: _autoValidate,
                          child: new Padding(
                            padding: EdgeInsets.only(bottom: 100),
                            child: new Column(
                              children: <Widget>[
                                new Row(children: <Widget>[
                                  Expanded(
                                      child: new Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24.0,
                                        top: 20.0,
                                        right: 24.0,
                                        bottom: 10.0),
                                    child: new Text(
                                      enter_vehicle_details.tr,
                                      style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_22,
                                          fontFamily: AppFont.font,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ))
                                ]),
                                new Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                          left: 24.0,
                                          top: 10.0,
                                          right: 24.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _settingModalBottomSheet(context);
                                          },
                                          child: new Container(
                                            color: AppColors.PRIMARY_COLOR_WHITE,
                                            child: Row(
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    enableIMEPersonalizedLearning:
                                                        false,
                                                    readOnly: true,
                                                    maxLines: 1,
                                                    onTap: () {
                                                      _settingModalBottomSheet(context);
                                                    },
                                                    decoration: new InputDecoration(
                                                      border: InputBorder.none,
                                                      hintText: vehicle_type.tr,
                                                      hintStyle: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight: FontWeight.w400,
                                                        fontSize:
                                                            AppDimen.text_size_16,
                                                      ),
                                                    ),
                                                    controller: _controller
                                                        .vehicleModelController,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                      fontWeight: FontWeight.w300,
                                                      fontSize:
                                                          AppDimen.text_size_18,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                SvgPicture.asset(
                                                  primaryDownArrow,
                                                  width: 15,
                                                  height: 9,
                                                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  color: AppColors.PRIMARY_COLOR_WHITE,
                                  margin: const EdgeInsets.only(
                                      left: 24.0,
                                      top: 20.0,
                                      right: 24.0,
                                      bottom: 10.0),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
                                  child: new TextFormField(
                                    keyboardType: TextInputType.text,
                                    enableIMEPersonalizedLearning: false,
                                    controller: _controller.vehicleNameController,
                                    textInputAction: TextInputAction.next,
                                    focusNode: fnvehiclename,
                                    onFieldSubmitted: (term) {
                                      fnvehiclename.unfocus();
                                      FocusScope.of(context).requestFocus(fnvehicleno);
                                    },
                                    decoration: new InputDecoration(
                                        border: InputBorder.none,
                                        hintText: vehicle_make.tr,
                                        hintStyle: TextStyle(
                                          color: AppColors.HIND_TEXT_COLOR,
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                        )),
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontWeight: FontWeight.w300,
                                      fontSize: AppDimen.text_size_18,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: new Container(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        margin: const EdgeInsets.only(
                                            left: 24.0,
                                            top: 10.0,
                                            right: 24.0,
                                            bottom: 10.0),
                                        padding:
                                        EdgeInsetsDirectional.symmetric(horizontal: 20),
                                        child: TextFormField(
                                          keyboardType: TextInputType.text,
                                          enableIMEPersonalizedLearning: false,
                                          controller: _controller.vehicleModelNameController,
                                          textInputAction: TextInputAction.next,
                                          focusNode: fnvehiclemodel,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                                RegExp("[a-zA-Z0-9 ]")),
                                            LengthLimitingTextInputFormatter(255)
                                          ],
                                          decoration: new InputDecoration(
                                              border: InputBorder.none,
                                              hintText: vehicle_model.tr,
                                              hintStyle: TextStyle(
                                                color: AppColors
                                                    .HIND_TEXT_COLOR,
                                                fontWeight: FontWeight.w400,
                                                fontSize: AppDimen.text_size_16,
                                              )),
                                          style: TextStyle(
                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontWeight: FontWeight.w300,
                                            fontSize: AppDimen.text_size_18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                          padding: const EdgeInsetsDirectional.symmetric(
                                          horizontal: 24,vertical: 10,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _showYearBottomSheet();
                                          },
                                          child: new Container(
                                            color: AppColors.PRIMARY_COLOR_WHITE,
                                            child: Row(
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    enableIMEPersonalizedLearning:
                                                    false,
                                                    decoration: new InputDecoration(
                                                      border: InputBorder.none,
                                                      hintText: vehicle_year.tr,
                                                      hintStyle: TextStyle(
                                                        color: AppColors
                                                            .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                        fontWeight: FontWeight.w400,
                                                        fontSize:
                                                        AppDimen.text_size_16,
                                                      ),
                                                    ),
                                                    controller: _controller
                                                        .vehicleYearController,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                      fontWeight: FontWeight.w300,
                                                      fontSize:
                                                      AppDimen.text_size_18,
                                                    ),
                                                    enabled: false,
                                                  ),
                                                ),
                                                SvgPicture.asset(
                                                  primaryDownArrow,
                                                  width: 15,
                                                  height: 9,
                                                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                new Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: new Container(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        margin: const EdgeInsets.only(
                                            left: 24.0,
                                            top: 10.0,
                                            right: 24.0,
                                            bottom: 10.0),
                                        padding:
                                            EdgeInsetsDirectional.symmetric(horizontal: 20),
                                        child: TextFormField(
                                          keyboardType: TextInputType.text,
                                          enableIMEPersonalizedLearning: false,
                                          controller: _controller.vehicleNoController,
                                          textInputAction: TextInputAction.next,
                                          focusNode: fnvehicleno,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                                RegExp("[a-zA-Z0-9 ]")),
                                            LengthLimitingTextInputFormatter(15)
                                          ],
                                          decoration: new InputDecoration(
                                              border: InputBorder.none,
                                              hintText:license_plate.tr,
                                              hintStyle: TextStyle(
                                                color: AppColors
                                                    .HIND_TEXT_COLOR,
                                                fontWeight: FontWeight.w400,
                                                fontSize: AppDimen.text_size_16,
                                              )),
                                          style: TextStyle(
                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontWeight: FontWeight.w300,
                                            fontSize: AppDimen.text_size_18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: new Container(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        margin: const EdgeInsets.only(
                                            left: 24.0,
                                            top: 10.0,
                                            right: 24.0,
                                            bottom: 10.0),
                                        padding:
                                            EdgeInsetsDirectional.symmetric(horizontal: 20),
                                        child: TextFormField(
                                          keyboardType: TextInputType.text,
                                          enableIMEPersonalizedLearning: false,
                                          controller: _controller.vehicleColorController,
                                          textInputAction: TextInputAction.done,
                                          focusNode: fnvehiclecolor,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                                RegExp("[a-zA-Z0-9 ]"))
                                          ],
                                          decoration: new InputDecoration(
                                              border: InputBorder.none,
                                              hintText: vehicle_color.tr,
                                              hintStyle: TextStyle(
                                                color: AppColors
                                                    .HIND_TEXT_COLOR,
                                                fontWeight: FontWeight.w400,
                                                fontSize: AppDimen.text_size_16,
                                              )),
                                          style: TextStyle(
                                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                            fontWeight: FontWeight.w300,
                                            fontSize: AppDimen.text_size_18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
                                  child: DocumentView(
                                    document_title: vehicle_image.tr,
                                    isFromVehicleDetails: true,
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24.0,
                                        top: 30.0,
                                        right: 24.0,
                                        bottom: 10.0),
                                    child: new Text(
                                      vehicle_availability.tr,
                                      style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_22,
                                          fontFamily: AppFont.font,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                GetBuilder(
                                  init: RegisterController(),
                                    id: _controller.rxChildSeatController.id,
                                    builder: (val) {
                                      return Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Padding(
                                                  padding: const EdgeInsets.only(
                                                  left: 24.0,
                                                  top: 10.0,
                                                  right: 24.0,
                                                  bottom: 10.0),
                                              child: InkWell(
                                                onTap: () {
                                                  if (_controller.rxChildSeatController.value == true) {
                                                    _controller.change(rxVariable: _controller.rxChildSeatController, value: false);
                                                    _controller.childController =
                                                        false;
                                                  } else {
                                                    _controller.change(rxVariable: _controller.rxChildSeatController, value: true);
                                                    _controller.childController =
                                                        true;
                                                  }
                                                },
                                                child: new Container(
                                                  height: 50,
                                                  color: AppColors.PRIMARY_COLOR_WHITE,
                                                  padding: EdgeInsets.only(
                                                      left: 10, right: 10, top: 0),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        margin:
                                                            EdgeInsetsDirectional
                                                                .only(
                                                                    start: 13,
                                                                    end: 13),
                                                        height: 22,
                                                        width: 22,
                                                        decoration: BoxDecoration(
                                                            color: _controller.rxChildSeatController.value ==
                                                                    true
                                                                ? AppColors
                                                                    .PRIMARY_COLOR_DARK
                                                                : Colors
                                                                    .transparent,
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .PRIMARY_COLOR_DARK,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        4))),
                                                        child: Visibility(
                                                          visible:
                                                          _controller.rxChildSeatController.value == true,
                                                          child: SvgPicture.asset(
                                                            rideComfortSelectedSvg,
                                                            fit: BoxFit.scaleDown,
                                                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            right: 0),
                                                        child: SvgPicture.asset(
                                                          childSeatSvg,
                                                          width: 16,
                                                          height: 12,
                                                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional.symmetric(horizontal: 7.0),
                                                        child: Text(
                                                          child_seat_availability.tr,
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: AppDimen
                                                                .text_size_16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                GetBuilder(
                                    init: RegisterController(),
                                    id: _controller.rxWheelChairController.id,
                                    builder: (val) {
                                      return Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 24.0,
                                                  top: 10.0,
                                                  right: 24.0,
                                                  bottom: 10.0),
                                              child: InkWell(
                                                onTap: () {
                                                  if (_controller.rxWheelChairController.value == true) {
                                                    _controller.change(rxVariable: _controller.rxWheelChairController, value: false);
                                                    _controller.wheelController =
                                                        false;
                                                  } else {
                                                    _controller.change(rxVariable: _controller.rxWheelChairController, value: true);
                                                    _controller.wheelController =
                                                        true;
                                                  }
                                                },
                                                child: new Container(
                                                  height: 50,
                                                  color: AppColors.PRIMARY_COLOR_WHITE,
                                                  padding: EdgeInsets.only(
                                                      left: 10, right: 10, top: 0),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        margin:
                                                            EdgeInsetsDirectional
                                                                .only(
                                                                    start: 13,
                                                                    end: 13),
                                                        height: 22,
                                                        width: 22,
                                                        decoration: BoxDecoration(
                                                            color: _controller.rxWheelChairController.value ==
                                                                    true
                                                                ? AppColors
                                                                    .PRIMARY_COLOR_DARK
                                                                : Colors
                                                                    .transparent,
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .PRIMARY_COLOR_DARK,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        4))),
                                                        child: Visibility(
                                                          visible:
                                                          _controller.rxWheelChairController.value == true,
                                                          child: SvgPicture.asset(
                                                            rideComfortSelectedSvg,
                                                            fit: BoxFit.scaleDown,
                                                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            right: 0),
                                                        child: SvgPicture.asset(
                                                          wheelChairSvg,
                                                          width: 15,
                                                          height: 16,
                                                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional.symmetric(horizontal: 7.0),
                                                        child: Text(
                                                          wheel_chair_availability.tr,
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: AppDimen
                                                                .text_size_16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                SizedBox(
                                  height: MediaQuery.of(context).viewInsets.bottom,
                                )
                              ],
                            ),
                          ))),
                  Visibility(
                    visible: MediaQuery.of(context).viewInsets.bottom <= 5.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: EdgeInsetsDirectional.only(
                            start: 24.0, end: 24.0, bottom: 24.0),
                        color: AppColors.COMMON_BG_COLOR,
                        child: PrimaryButton(
                          buttonTitle: next.tr,
                          buttonImage: primaryBtnArrow,
                          callback: () {
                            _validateInputs();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildModelItem(BuildContext context, int index) {
    return ColoredBox(
      color: AppColors.COMMON_BG_COLOR,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: () {
                _vehicleModel = _modelDropDown[index].categoryName!;
                _controller.vehicleModelId = _modelDropDown[index].id!;
                _controller.vehicleModelController.text = _vehicleModel;
                Get.back();
                FocusScope.of(context).unfocus();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      alignment: AlignmentDirectional.centerStart,
                      padding: EdgeInsets.all(15.0),
                      child: Text(_modelDropDown[index].categoryName!,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                  ),
                  (_controller.vehicleModelController.text == _modelDropDown[index].categoryName)
                      ? Container(
                        height: 24, width: 24,
                        padding: EdgeInsets.all(5.0),
                        margin: globals.isRtlLang ? EdgeInsets.only(left: 24) : EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50)),
                            border: Border.all(
                                color: AppColors.PRIMARY_COLOR_DARK, width: 1.5)),
                        child: SvgPicture.asset(
                          checkSvg,
                          colorFilter: ColorFilter.mode(
                              AppColors.ICON_COLOUR, BlendMode.srcIn),
                        ),
                      )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: new Divider(
                color: AppColors.DIVIDER_COLOR,
              ),
            ),
          ],
        ));
  }

  void _settingModalBottomSheet(mcontext) {
    int delayMilliSeconds = 0;
    if(fnvehiclename.hasFocus || fnvehiclemodel.hasFocus || fnvehicleno.hasFocus || fnvehiclecolor.hasFocus) {
      delayMilliSeconds = 400;
      fnvehiclename.unfocus();
      fnvehiclemodel.unfocus();
      fnvehicleno.unfocus();
      fnvehiclecolor.unfocus();
    }
    Future.delayed(Duration(milliseconds: delayMilliSeconds), () {
      Get.bottomSheet(
        backgroundColor: AppColors.COMMON_BG_COLOR,
        Consumer<ModelTheme>(
              builder: (context, ModelTheme themeNotifier, child) {
            return SafeArea(
              bottom: Platform.isAndroid,
              child: ListView.builder(
                itemCount: _modelDropDown.length,
                primary: true,
                shrinkWrap: true,
                itemBuilder: _buildModelItem,
              ),
            );
          }
        )
      );
    });
  }

  String _validateInputs() {
    String errormsg = "";

    if (_controller.vehicleModelController.text.toString().isEmpty) {
      _controller.showInSnackBar(
          empty_selection.trParams({"field":vehicle_type.tr.toLowerCase()}));
    } else if (_controller.vehicleNameController.text == null ||
        _controller.vehicleNameController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":vehicle_make.tr.toLowerCase()}));
    }else if (_controller.vehicleModelNameController.text == null ||
        _controller.vehicleModelNameController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":vehicle_model.tr.toLowerCase()}));
    }else if (_controller.vehicleYearController.text == null ||
        _controller.vehicleYearController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_selection.trParams({"field":vehicle_year.tr.toLowerCase()}));
    }
    else if (_controller.vehicleNoController.text == null ||
        _controller.vehicleNoController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":license_plate.tr.toLowerCase()}));
    } else if (_controller.vehicleColorController.text == null ||
        _controller.vehicleColorController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":vehicle_color.tr.toLowerCase()}));
    }
    else if (_controller.vehicleColorController.text == null ||
        _controller.vehicleColorController.text.isEmpty) {
      _controller.showInSnackBar(
          empty_msg.trParams({"field":vehicle_color.tr.toLowerCase()}));
    } else if (globals.vehicleImagePath.isEmpty) {
      _controller.showInSnackBar(
          empty_selection.trParams({"field":vehicle_image.tr.toLowerCase()}));
    } else {
      _formKey.currentState?.save();
      _controller.setLoadingController(true);
      fnvehiclename.unfocus();
      fnvehicleno.unfocus();
      fnvehiclecolor.unfocus();
      showSignupdialog(context);
    }

    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  Future<void> exitConfirmDialog(String content, String cancel, String exit) async {
    return Get.dialog(
      barrierDismissible: false,
      Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return Obx(
          () {
            return globals.isAutoThemeUpdated.value != null ? AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
              content: Container(
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(fontSize: AppDimen.text_size_16),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.key.currentState!.canPop() ? Get.back() : null;
                            },
                            child: Container(
                              width: Get.width,
                              margin: EdgeInsetsDirectional.only(end: 10),
                              height: 50,
                              padding:
                                  EdgeInsetsDirectional.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_COLOR_WHITE,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    toBeginningOfSentenceCase(
                                        cancel.toLowerCase())!,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              App().closeApp();
                            },
                            child: Container(
                              width: Get.width,
                              height: 50,
                              margin: EdgeInsetsDirectional.only(start: 10),
                              padding: EdgeInsetsDirectional.only(
                                start: 20,
                                end: 20,
                              ),
                              decoration: BoxDecoration(
                                  color: AppColors.PRIMARY_COLOR_DARK,
                                  borderRadius: BorderRadius.circular(4)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    toBeginningOfSentenceCase(
                                        exit.toLowerCase())!,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_WHITE,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16)),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ) : SizedBox.shrink();
          }
        );
      })
    );
  }






  @override
  void dispose() {
    fnvehiclename.dispose();
    fnvehiclemodel.dispose();
    fnvehicleno.dispose();
    fnvehiclecolor.dispose();
    _controller.setLoadingController(false);
    super.dispose();
  }


  showSignupdialog(BuildContext context) {
    String signup = sign_up.tr;
    String signupcontent = are_you_sure_to_signup.tr;
    String cancel = btn_cancel.tr;
    String confirmLabel = confirm.tr;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                title: Text(
                  signup,
                  style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      signupcontent,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        margin: EdgeInsets.only(top: 20),
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  margin: EdgeInsetsDirectional.only(end: 5),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_WHITE,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      cancel,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: AppDimen.text_size_18,
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _controller.setLoadingController(false);
                                  FocusScope.of(Get.context!).unfocus();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  margin: EdgeInsetsDirectional.only(start: 5),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: AppColors.PRIMARY_COLOR_DARK,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      confirmLabel,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: AppDimen.text_size_18,
                                          color: AppColors.PRIMARY_COLOR_WHITE),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  debugPrint("firstClick: ${firstClick}");
                                  // if (firstClick) {
                                  //   firstClick = false;
                                    Navigator.of(context).pop();
                                    FocusScope.of(Get.context!).unfocus();
                                    App().checkInternet(
                                        scoffoldcontext, verifySignup, false);
                                //  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  verifySignup() {
    if (!globals.isVehicleDetailsReq) {
      _controller.callSignUpAPI().then((value) {
        _controller.setLoadingController(false);
        if (value.isNotEmpty) {
          _controller.showInSnackBar( value);
          firstClick = true;
        } else {
          App().appPreference.authToken = globals.authToken;
          App().appPreference.userId = globals.userid;
          App().setNavigation(AppRoutes.APP_DOCUMENT_MAIN);
        }
      });
    } else {
      _controller.callVehicleDetails().then((value) {
        _controller.setLoadingController(false);
        if (value.isNotEmpty) {
          _controller.showInSnackBar( value);
          firstClick = true;
        } else {
          App().appPreference.authToken = globals.authToken;
          App().appPreference.userId = globals.userid;
          App().setNavigation(AppRoutes.APP_DOCUMENT_MAIN);
        }
      });
    }
  }

  void getVehicleCategories() {
    _controller.getVehicleTypes().then((value) {
      _controller.setLoadingController(false);
      if (value.isNotEmpty) {
        _controller.showInSnackBar( value);
      } else {
        _modelDropDown = _controller.getCategories!.getCategories!.result!;
      }
    });
  }

  void _showYearBottomSheet() {
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (index) => (currentYear - index).toString());
    int delayMilliSeconds = 0;
    if(fnvehiclename.hasFocus || fnvehiclemodel.hasFocus || fnvehicleno.hasFocus || fnvehiclecolor.hasFocus) {
      delayMilliSeconds = 400;
      fnvehiclename.unfocus();
      fnvehiclemodel.unfocus();
      fnvehicleno.unfocus();
      fnvehiclecolor.unfocus();
    }
    Future.delayed(Duration(milliseconds: delayMilliSeconds), () {
      Get.bottomSheet(
        backgroundColor: AppColors.COMMON_BG_COLOR,
          Consumer<ModelTheme>(
              builder: (context, ModelTheme themeNotifier, child) {
            return SafeArea(
              bottom: Platform.isAndroid,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  return _buildModelItemForYears(context, years, index);
                },
              ),
            );
          }
        )
      );
    });
  }

  Widget _buildModelItemForYears(BuildContext context, List<String> years, int index) {
    return ColoredBox(
      color: AppColors.COMMON_BG_COLOR,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () {
               selectedYear = years[index];
              _controller.vehicleYearController.text = selectedYear;
              Get.back();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    alignment: AlignmentDirectional.centerStart,
                    padding: EdgeInsets.all(15.0),
                    child: Text(
                      years[index],
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_16,
                      ),
                    ),
                  ),
                ),
                (selectedYear == years[index])
                    ? Container(
                  height: 24, width: 24,
                  padding: EdgeInsets.all(5.0),
                  margin:  EdgeInsetsDirectional.only(end: 24),
                  decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.all(Radius.circular(50)),
                      border: Border.all(
                          color: AppColors.PRIMARY_COLOR_DARK, width: 1.5)),
                  child: SvgPicture.asset(
                    checkSvg,
                    colorFilter: ColorFilter.mode(
                        AppColors.ICON_COLOUR, BlendMode.srcIn),
                  ),
                )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13.0),
            child: Divider(
              color: AppColors.DIVIDER_COLOR,
            ),
          ),
        ],
      ),
    );
  }
}