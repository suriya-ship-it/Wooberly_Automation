import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/register_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/flutter_google_places.dart';
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';

class NameFields extends StatelessWidget {
  static BuildContext? ctx;

  @override
  Widget build(BuildContext context) {
    ctx = context;
    return NameFieldsView();
  }
}

class NameFieldsView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NameFieldsState();
}

class NameFieldsState extends State<NameFieldsView> {
  final RegisterController _controller = Get.find();
  final FocusNode fnfirstname = FocusNode();
  final FocusNode fnlastname = FocusNode();
  final FocusNode fnemail = FocusNode();
  final FocusNode fnpassword = FocusNode();
  final FocusNode fnconpassword = FocusNode();
  late BuildContext scoffoldcontext;
  GlobalKey<State> _EmailWidgetKey = new GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          customAppBarFunction: () {
            fnpassword.unfocus();
            fnconpassword.unfocus();
            var content = exit_app_content.tr;
            var cancel = toBeginningOfSentenceCase(
                btn_cancel.tr.toLowerCase());
            var exit = toBeginningOfSentenceCase(
                exit_app.tr.toLowerCase());
            _asyncConfirmDialog(content, cancel ?? "", exit ?? "");
          },
          resizeToAvoidBottomInset: true,
          body: _showContentData(),
          onChanged: (map) {
            scoffoldcontext = map["scaffoldcontext"];
          },
        );
      }
    );
  }

  Future<void> _asyncConfirmDialog(
      String content, String cancel, String exit) async {
    return Get.dialog(barrierDismissible: false, Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return Obx(() {
        return globals.isAutoThemeUpdated.value != null
            ? AlertDialog(
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
                        style: TextStyle(fontSize: AppDimen.text_size_16,color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
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
                                margin: const EdgeInsetsDirectional.only(end: 10),
                                height: 50,
                                padding:
                                    const EdgeInsetsDirectional.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      toBeginningOfSentenceCase(
                                          cancel.toLowerCase())!,
                                      style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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
                                Get.until((route) => route.settings.name == "/Main");
                                App().closeApp();
                              },
                              child: Container(
                                width: Get.width,
                                height: 50,
                                margin: const EdgeInsetsDirectional.only(start: 10),
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                    color: AppColors.PRIMARY_COLOR_DARK,
                                    borderRadius: BorderRadius.circular(4)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      toBeginningOfSentenceCase(exit.toLowerCase())!,
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
        }
      )
    );
  }

  void _validateInputs() {
    if (validateFirstName().isEmpty &&
        validateLastName().isEmpty &&
        validateGender().isEmpty &&
        validateEmail().isEmpty &&
        validateLocation().isEmpty &&
        validatePassword().isEmpty &&
        validateconformPassword().isEmpty) {
      _controller.checkInternet(verifyEmail, false);
    }
  }

  String validateFirstName() {
    String value = _controller.firstNameController.text.toString().trim();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = empty_msg.trParams({"field":firstname_label.tr.toLowerCase()});
    } else if (!(value.trim().length > globals.nameLength[0] - 1 &&
        value.trim().length - 1 < globals.nameLength[1])) {
      errormsg = name_length_error.trParams({
        "field":firstname_label.tr,
        "field1":globals.nameLength[0].toString(),
        "field2":globals.nameLength[1].toString()
      });
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validateLastName() {
    String value = _controller.lastNameController.text.toString().trim();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = empty_msg.trParams({"field":lastname_label.tr.toLowerCase()});
    } else if (!(value.trim().length > globals.nameLength[0] - 1 &&
        value.trim().length - 1 < globals.nameLength[1])) {
      errormsg = name_length_error.trParams({
        "field":lastname_label.tr,
        "field1":globals.nameLength[0].toString(),
        "field2":globals.nameLength[1].toString()
      });
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validateEmail() {
    String value = _controller.emailController.text.toString().trim();
    String errormsg = "";
    Pattern pattern = r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
    RegExp regex = new RegExp(pattern.toString());
    if (value.trim().length == 0) {
      errormsg = empty_msg.trParams({"field":email_label.tr.toLowerCase()});
    }
    else if (!regex.hasMatch(value)) {
      errormsg = valid_msg.trParams({"field":email_label.tr.toLowerCase()});
    }
    else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validateGender() {
    String errormsg = "";
    if (_controller.genderController.text != null &&
        _controller.genderController.text.toString().isNotEmpty) {
      errormsg = "";
    } else {
      errormsg = please_select_your_gender.tr;
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validateLocation() {
    String errormsg = "";
    if (_controller.selectedLocationController.text != null &&
        _controller.selectedLocationController.text.toString().isNotEmpty) {
      errormsg = "";
    } else {
      errormsg = empty_msg.trParams({"field":your_location.tr});
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validatePassword() {
    String errormsg = "";
    String value = _controller.passwordController.text.toString();
    if (value.trim().length == 0) {
      errormsg = empty_msg.trParams({"field":password_label.tr.toLowerCase()});
    } else if (value.length < 8) {
      errormsg = length_error.trParams({"field":password_label.tr, "field2":"7"});
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  String validateconformPassword() {
    String value = _controller.confirmpasswordController.text.toString();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = empty_msg.trParams({"field":con_pass_label.tr.toLowerCase()});
    } else if (_controller.passwordController.text != value) {
      errormsg = mismatch_pass_error.tr;
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _controller.showInSnackBar( errormsg);
    return errormsg;
  }

  @override
  void dispose() {
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    PlacesAutocompleteState.queryTextController = null;
    PlacesAutocompleteState.focus = false;
    PlacesAutocompleteWidget.isRegister = false;
    super.dispose();
  }

  void verifyEmail() {
    _controller.validateEmailAddress().then((value) {
      if (value.isNotEmpty) {
        _controller.showInSnackBar( value);
      } else {
        App().setNavigation(AppRoutes.APP_ROUTE_DETAILS);
      }
    });
  }

  _showContentData() {
    return Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 0.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: ClampingScrollPhysics(),
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 25,
                    ),
                    Text(
                      enter_your.trParams({"field2":details.tr.toLowerCase()}),
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: Container(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          height: 50,
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                          margin: const EdgeInsetsDirectional.only(
                            end: 7.0,
                          ),
                          child: TextFormField(
                            keyboardType: TextInputType.text,
                            enableIMEPersonalizedLearning: false,
                            maxLength: 20,
                            textInputAction: TextInputAction.next,
                            focusNode: fnfirstname,
                            onFieldSubmitted: (term) {
                              fnfirstname.unfocus();
                              FocusScope.of(context).requestFocus(fnlastname);
                            },
                            controller: _controller.firstNameController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: firstname_label.tr,
                                counterText: '',
                                hintStyle: TextStyle(
                                  color: AppColors.HIND_TEXT_COLOR,
                                  fontWeight: FontWeight.w400,
                                  fontSize: AppDimen.text_size_16,
                                )),
                            style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontWeight: FontWeight.w500,
                              fontSize: AppDimen.text_size_16,
                            ),
                          ),
                        )),
                        Expanded(
                          child: Container(
                            color: AppColors.PRIMARY_COLOR_WHITE,
                            height: 50,
                            padding:
                               const EdgeInsetsDirectional.symmetric(horizontal: 20),
                            margin: const EdgeInsetsDirectional.only(
                              start: 7.0,
                            ),
                            child: new TextFormField(
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              maxLength: 20,
                              controller: _controller.lastNameController,
                              enableIMEPersonalizedLearning: false,
                              focusNode: fnlastname,
                              onFieldSubmitted: (term) {
                                fnlastname.unfocus();
                                FocusScope.of(context).requestFocus(fnemail);
                              },
                              decoration: new InputDecoration(
                                  counterText: '',
                                  hintText: lastname_label.tr,
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: AppColors.HIND_TEXT_COLOR,
                                    fontWeight: FontWeight.w400,
                                    fontSize: AppDimen.text_size_16,
                                  )),
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox (
                      height: 20,
                    ),
                    InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _settingModalBottomSheet(220);
                      },
                      child: Container(
                        color: AppColors.PRIMARY_COLOR_WHITE,
                        height: 50,
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: TextFormField(
                                enableIMEPersonalizedLearning: false,
                                controller: _controller.genderController,
                                decoration: InputDecoration(
                                    hintText: select_your_gender.tr,
                                    border: InputBorder.none,
                                    enabled: false,
                                    hintStyle: TextStyle(
                                      color: AppColors.HIND_TEXT_COLOR,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_16,
                                    )),
                                style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                const
                                EdgeInsetsDirectional.only(start: 5, end: 20),
                              child: SvgPicture.asset(
                                primaryDownArrow,
                                colorFilter: ColorFilter.mode(
                                    AppColors.ICON_COLOUR, BlendMode.srcIn),
                                width: 6.0,
                                height: 7.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Text(
                      whats_email_id.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const  SizedBox(
                      height: 25,
                    ),
                    Container(
                      height: 50,
                      key: _EmailWidgetKey,
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: new TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        enableIMEPersonalizedLearning: false,
                        controller: _controller.emailController,
                        textInputAction: TextInputAction.done,
                        focusNode: fnemail,
                        decoration: InputDecoration(
                            hintText: email_label.tr,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: AppColors.HIND_TEXT_COLOR,
                              fontWeight: FontWeight.w400,
                              fontSize: AppDimen.text_size_16,
                            )),
                        style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    const  SizedBox(
                      height: 35,
                    ),
                    Text(
                      whats_your_location.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        App().setNavigation(AppRoutes.APP_CITY_SEARCH);
                      },
                      child: Container(
                        color: AppColors.PRIMARY_COLOR_WHITE,
                        padding:
                           const EdgeInsetsDirectional.symmetric(horizontal: 20),
                        child: new TextFormField(
                          controller: _controller.selectedLocationController,
                          enableIMEPersonalizedLearning: false,
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: 10,
                          textInputAction: TextInputAction.done,
                          enabled: false,
                          decoration: InputDecoration(
                            hintText:
                                your_location.tr,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: AppColors.HIND_TEXT_COLOR,
                              fontWeight: FontWeight.w400,
                              fontSize: AppDimen.text_size_16,
                            ),
                          ),
                          style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Text(
                      set_your_password.tr,
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      height: 50,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: GetBuilder(
                        init: RegisterController(),
                          id: _controller.rxPasswordVisibleController.id,
                          builder: (val) {
                            bool isVisible = _controller.rxPasswordVisibleController.value == true;
                            return Row(
                              children: [
                                Expanded(
                                  child: new TextFormField(
                                    enableIMEPersonalizedLearning: false,
                                    keyboardType: TextInputType.text,
                                    controller: _controller.passwordController,
                                    textInputAction: TextInputAction.done,
                                    obscureText: isVisible,
                                    focusNode: fnpassword,
                                    decoration: InputDecoration(
                                        hintText: password_label.tr,
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color:
                                              AppColors.HIND_TEXT_COLOR,
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                        )),
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppDimen.text_size_16,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _controller.change(rxVariable: _controller.rxPasswordVisibleController, value: !isVisible);
                                  },
                                  child:  SizedBox(
                                    height: 50,
                                    child: SvgPicture.asset(
                                      _controller.rxPasswordVisibleController.value == false
                                          ? visibilityOnSvg
                                          : visibilityOffSvg,
                                      width: _controller.rxPasswordVisibleController.value == false ? 12.5 : 16,
                                      height:
                                      _controller.rxPasswordVisibleController.value == false ? 12.5 : 16,
                                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                InkWell(
                                    onTap: () {
                                      _controller.change(rxVariable: _controller.rxPasswordVisibleController, value: !isVisible);
                                    },
                                    child: const SizedBox(
                                      width: 20,
                                      height: 50,
                                    )),
                              ],
                            );
                          }),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      height: 50,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: GetBuilder(
                        init: RegisterController(),
                          id: _controller.rxConPasswordVisibleController.id,
                          builder: (val) {
                            bool isVisible = _controller.rxConPasswordVisibleController.value == true;
                            return Row(
                              children: [
                                Expanded(
                                  child: new TextFormField(
                                    controller:
                                        _controller.confirmpasswordController,
                                    focusNode: fnconpassword,
                                    obscureText: isVisible,
                                    enableIMEPersonalizedLearning: false,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                        hintText: con_pass_label.tr,
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color:
                                              AppColors.HIND_TEXT_COLOR,
                                          fontWeight: FontWeight.w400,
                                          fontSize: AppDimen.text_size_16,
                                        )),
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppDimen.text_size_16,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _controller.change(rxVariable: _controller.rxConPasswordVisibleController, value: !isVisible);
                                  },
                                  child:  SizedBox(
                                    height: 50,
                                    child: SvgPicture.asset(
                                      _controller.rxConPasswordVisibleController.value == false
                                          ? visibilityOnSvg
                                          : visibilityOffSvg,
                                      width: _controller.rxConPasswordVisibleController.value == false ? 12.5 : 16,
                                      height:
                                      _controller.rxConPasswordVisibleController.value == false ? 12.5 : 16,
                                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                                InkWell(
                                    onTap: () {
                                      _controller.change(rxVariable: _controller.rxConPasswordVisibleController, value: !isVisible);
                                    },
                                    child: const SizedBox(
                                      width: 20,
                                      height: 50,
                                    )),
                              ],
                            );
                          }),
                    ),
                    SizedBox(
                      height:
                          MediaQuery.of(context).viewInsets.bottom != null &&
                                  MediaQuery.of(context).viewInsets.bottom > 0
                              ? 20
                              : 100,
                    ),
                  ]),
            ),
            Visibility(
              visible: MediaQuery.of(context).viewInsets.bottom <= 5.0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(bottom: 24.0),
                  color: AppColors.COMMON_BG_COLOR,
                  child: PrimaryButton(
                    buttonTitle: finish.tr,
                    buttonImage: primaryBtnArrow,
                    callback: () {
                      fnconpassword.unfocus();
                      _validateInputs();
                    },
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  void _settingModalBottomSheet(double value) {
    Get.bottomSheet(
        backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
        SafeArea(
          bottom: Platform.isAndroid,
            child: Consumer<ModelTheme>(
                builder: (context, ModelTheme themeNotifier, child) {
                return Container(
                  height: value,
                  color: AppColors.COMMON_BG_COLOR,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ListView.builder(
                    itemCount: _controller.genderList.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Container(
                          child: new Wrap(children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                _controller.genderController.text =
                                    _controller.genderList[index];
                                Get.back();
                              },
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10.0,
                                      bottom: 10.0,
                                      right: 20.0,
                                      left: 20.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(_controller.genderList[index],
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontWeight: FontWeight.w500,
                                                fontSize: AppDimen.text_size_16,
                                                fontFamily: AppFont.font)),
                                      ),
                                      _controller.genderController.text ==
                                              _controller.genderList[index]
                                          ? SvgPicture.asset(
                                              updatedVerified,
                                              width: 20.0,
                                              height: 20.0,
                                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                            )
                                          : const SizedBox.shrink()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: new Divider(
                                color: AppColors.DIVIDER_COLOR,
                              ),
                            ),
                          ],
                        )
                      ]));
                    },
                  ),
                );
              }
            ),
          ));
  }
}