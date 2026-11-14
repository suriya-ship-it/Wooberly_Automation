import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/widgets/show_done_view.dart';

import '../databases/app_preferences.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_button.dart';
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
  late RegisterController _registerController = Get.find();
  final FocusNode fnfirstname = FocusNode();
  final FocusNode fnlastname = FocusNode();
  final FocusNode fnemail = FocusNode();
  final FocusNode fnpassword = FocusNode();
  final FocusNode fnconpassword = FocusNode();
  late BuildContext scoffoldcontext;
  final _scrollController = ScrollController();




  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return Stack(
        children: [
          PrimaryScaffold(
            customAppBarFunction: () {
              fnpassword.unfocus();
              fnconpassword.unfocus();
              var content = 'are_you_sure'.tr + " " + 'exit_app_content'.tr;
              var cancel = toBeginningOfSentenceCase('cancel_label'.tr.toLowerCase());
              var exit = toBeginningOfSentenceCase('exit_app'.tr.toLowerCase());
              _asyncConfirmDialog(content, cancel!, exit!);
            },
            resizeToAvoidBottomInset: true,
            body: _showContentData(),
            onChanged: (map) {
              scoffoldcontext = map["scaffoldcontext"];
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
      );
    });
  }

  Future<void> _asyncConfirmDialog(String content, String cancel, String exit) async {
    return _registerController.showConfirmationDialog(
        content: content,
        onConfirm: (){
      Get.back();
      Get.until((route) {
        return Get.currentRoute == AppRoutes.APP_ROUTE_LOGIN;
      });
      _registerController.dispose();
      _registerController.closeApp();
    }, confirmButtonText: exit,cancelButtonText: cancel);
  }

  void _validateInputs() {
    if (validateFirstName().isEmpty &&
        validateLastName().isEmpty &&
        validateEmail().isEmpty &&
        validateLocation().isEmpty &&
        validatePassword().isEmpty &&
        validateconformPassword().isEmpty) {
      _registerController.checkInternet(verifyEmail, false);
    }
  }

  String validateFirstName() {
    String value = _registerController.firstNameController.text.toString().trim();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = 'empty_msg'.trParams({'field': 'firstname_label'.tr.toString().toLowerCase()});
    } else if (!(value.trim().length > globals.nameLength[0] - 1 &&
        value.trim().length - 1 < globals.nameLength[1])) {
      errormsg = 'name_length_error'.trParams({
        'field1': 'firstname_label'.tr,
        'field2': globals.nameLength[0].toString(),
        'field3': globals.nameLength[1].toString()
      });
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validateLastName() {
    String value = _registerController.lastNameController.text.toString().trim();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = 'empty_msg'.trParams({'field': 'lastname_label'.tr.toString().toLowerCase()});
    } else if (!(value.trim().length > globals.nameLength[0] - 1 &&
        value.trim().length - 1 < globals.nameLength[1])) {
      errormsg = 'name_length_error'.trParams({
        'field1': 'lastname_label'.tr,
        'field2': globals.nameLength[0].toString(),
        'field3': globals.nameLength[1].toString()
      });
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validateEmail() {
    String value = _registerController.emailController.text.toString().trim();
    String errormsg = "";
    Pattern pattern =
        r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
    RegExp regex = new RegExp(pattern.toString());
    if (value.trim().length == 0) {
      errormsg = 'empty_msg'.trParams({'field': 'email_label'.tr.toString().toLowerCase()});
    } else if (!regex.hasMatch(value)) {
      errormsg = 'valid_msg'.trParams({'field': 'email_label'.tr.toString().toLowerCase()});
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validateGender() {
    String errormsg = "";
    if (_registerController.genderController.text != null &&
        _registerController.genderController.text.toString().isNotEmpty) {
      errormsg = "";
    } else {
      errormsg = 'please_select_your_gender'.tr;
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validateLocation() {
    String errormsg = "";
    if (_registerController.selectedLocationController.text != null &&
        _registerController.selectedLocationController.text.toString().isNotEmpty) {
      errormsg = "";
    } else {
      errormsg = 'empty_msg'.trParams({'field': 'your_location'.tr});
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validatePassword() {
    String errormsg = "";
    String value = _registerController.passwordController.text.toString();
    if (value.trim().length == 0) {
      errormsg = 'empty_msg'.trParams({'field': 'password_hint'.tr.toString().toLowerCase()});
    } else if (value.length < 8) {
      errormsg = 'length_error'.trParams({'field1': 'password_hint'.tr, 'field2': "7".toString()});
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  String validateconformPassword() {
    String value = _registerController.confirmpasswordController.text.toString();
    String errormsg = "";
    if (value.trim().length == 0) {
      errormsg = 'empty_msg'.trParams({'field': 'con_pass_label'.tr.toLowerCase()});
    } else if (_registerController.passwordController.text != value) {
      errormsg = 'mismatch_pass_error'.tr;
    } else {
      errormsg = "";
    }
    if (errormsg.isNotEmpty) _registerController.showInSnackBar(errormsg);
    return errormsg;
  }

  @override
  void dispose() {
    globals.setButtonIdle();
    super.dispose();
  }

  void verifyEmail() {
    debugPrint("verifySignup: ${globals.authToken}");
    if (globals.authToken != null && globals.authToken!.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 1)).then((_) {
        _registerController.checkInternet(getProfileInfo, false);
      });
    } else {
      _registerController.validateEmailAddress().then((value) {
        if (value.isNotEmpty) {
          _registerController.showInSnackBar(value);
        } else {
          verifySignup();
        }
      });
    }
  }

  _showContentData() {
    return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 25.0,),
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
                      'enter_your'.trParams({'field2': 'details'.tr.toLowerCase()}),
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
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
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              height: 50,
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                              margin: const EdgeInsetsDirectional.only(end: 7.0,),
                              child: TextFormField(
                                enableIMEPersonalizedLearning: false,
                                keyboardType: TextInputType.text,
                                maxLength: 20,
                                textInputAction: TextInputAction.next,
                                focusNode: fnfirstname,
                                onFieldSubmitted: (term) {
                                  fnfirstname.unfocus();
                                  FocusScope.of(context).requestFocus(fnlastname);
                                },
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(globals.nameLength.last)
                                ],
                                controller: _registerController.firstNameController,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'firstname_label'.tr,
                                    counterText: '',
                                    hintStyle: TextStyle(
                                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_16,
                                    )),
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            )),
                        Expanded(
                          child: Container(
                            color: AppColors.PRIMARY_LIGHT_COLOR,
                            height: 50,
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                            margin: const EdgeInsetsDirectional.only(start: 7.0,),
                            child: new TextFormField(

                              enableIMEPersonalizedLearning: false,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              maxLength: 20,
                              controller: _registerController.lastNameController,
                              inputFormatters: <TextInputFormatter>[
                                LengthLimitingTextInputFormatter(globals.nameLength.last)
                              ],
                              focusNode: fnlastname,
                              onFieldSubmitted: (term) {
                                fnlastname.unfocus();
                                FocusScope.of(context).requestFocus(fnemail);
                              },
                              decoration: new InputDecoration(
                                  counterText: '',
                                  hintText: 'lastname_label'.tr,
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                    fontWeight: FontWeight.w400,
                                    fontSize: AppDimen.text_size_16,
                                  )),
                              style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _settingModalBottomSheet(context, 220);
                      },
                      child: Container(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        height: 50,
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: TextFormField(

                                enableIMEPersonalizedLearning: false,
                                controller: _registerController.genderController,
                                decoration: InputDecoration(
                                    hintText: 'select_your_gender'.tr,
                                    border: InputBorder.none,
                                    enabled: false,
                                    hintStyle: TextStyle(
                                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_16,
                                    )),
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: 5, end: 20),
                              child: SvgPicture.asset(
                                primaryDownArrow,
                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
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
                      'whats_email_id'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      height: 50,
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: new TextFormField(
                        scrollPadding: EdgeInsets.only(bottom: 70),
                        enableIMEPersonalizedLearning: false,
                        keyboardType: TextInputType.emailAddress,
                        controller: _registerController.emailController,
                        textInputAction: TextInputAction.done,
                        focusNode: fnemail,
                        decoration: InputDecoration(
                            hintText: 'email_label'.tr,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: AppColors.PLACEHOLDER_TEXT_COLOR,
                              fontWeight: FontWeight.w400,
                              fontSize: AppDimen.text_size_16,
                            )),
                        style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Text(
                      'whats_your_location_'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    InkWell(
                      onTap: () {
                        debugPrint("MediaQuery.of(context).viewPadding.bottom: ${MediaQuery.of(context).viewInsets.bottom}");
                        FocusManager.instance.primaryFocus?.unfocus();
                        _registerController.setNavigation(AppRoutes.APP_CITY_SEARCH);
                      },
                      child: Container(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 20,
                        ),
                        child: new TextFormField(

                          controller: _registerController.selectedLocationController,
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: 10,
                          textInputAction: TextInputAction.done,
                          enabled: false,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'your_location'.tr,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: AppColors.PLACEHOLDER_TEXT_COLOR,
                              fontWeight: FontWeight.w400,
                              fontSize: AppDimen.text_size_16,
                            ),
                          ),
                          style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
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
                      'set_your_password'.tr,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_22,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      height: 50,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: Obx(() {
                        bool isVisible = _registerController.passwordVisibleController.value;
                        return Row(
                          children: [
                            Expanded(
                              child: new TextFormField(
                                scrollPadding: EdgeInsets.only(bottom: 70),
                                enableIMEPersonalizedLearning: false,
                                keyboardType: TextInputType.text,
                                controller: _registerController.passwordController,
                                textInputAction: TextInputAction.done,
                                obscureText: isVisible,
                                focusNode: fnpassword,
                                decoration: InputDecoration(
                                    hintText: 'password_hint'.tr,
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_16,
                                    )),
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _registerController.passwordVisibleController(!isVisible);
                              },
                              child: Container(
                                height: 50,
                                child: SvgPicture.asset(
                                  isVisible == false ? visibilityOnSvg : visibilityOffSvg,
                                  width: isVisible == false ? 12.5 : 16,
                                  height: isVisible == false ? 12.5 : 16,
                                  colorFilter:
                                  ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            InkWell(
                                onTap: () {
                                  _registerController.passwordVisibleController(!isVisible);
                                },
                                child: Container(
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
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      height: 50,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: Obx(() {
                        bool isVisible = _registerController.conPasswordVisibleController.value;
                        return Row(
                          children: [
                            Expanded(
                              child: new TextFormField(
                                scrollPadding: EdgeInsets.only(bottom: 70),
                                enableIMEPersonalizedLearning: false,
                                controller: _registerController.confirmpasswordController,
                                focusNode: fnconpassword,
                                obscureText: isVisible,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                    hintText: 'con_pass_label'.tr,
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                      fontWeight: FontWeight.w400,
                                      fontSize: AppDimen.text_size_16,
                                    )),
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _registerController.conPasswordVisibleController(!isVisible);
                              },
                              child: Container(
                                height: 50,
                                child: SvgPicture.asset(
                                  isVisible == false ? visibilityOnSvg : visibilityOffSvg,
                                  width: isVisible == false ? 12.5 : 16,
                                  height: isVisible == false ? 12.5 : 16,
                                  colorFilter:
                                  ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            InkWell(
                                onTap: () {
                                  _registerController.conPasswordVisibleController(!isVisible);
                                },
                                child: Container(
                                  width: 20,
                                  height: 50,
                                )),
                          ],
                        );
                      }),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom != null &&
                          MediaQuery.of(context).viewInsets.bottom > 0
                          ? 70
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
                    buttonTitle: 'finish'.tr,
                    buttonImage: primaryBtnArrow,
                    callback: () {
                      fnpassword.unfocus();
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

  void _settingModalBottomSheet(mcontext, double value) {
    App().showBottomSheet(
      Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        return SafeArea(
          child: SizedBox(
            height: value,
            child: ListView.builder(
              padding: const EdgeInsetsDirectional.only(top: 10.0),
              itemCount: _registerController.genderList.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return new Wrap(children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          _registerController.genderController.text = _registerController.genderList[index];
                          Get.back();
                        },
                        child: Container(
                          alignment: AlignmentDirectional.centerStart,
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_registerController.genderList[index],
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16,
                                        fontFamily: AppFont.font)),
                              ),
                              _registerController.genderController.text ==
                                  _registerController.genderList[index]
                                  ? SvgPicture.asset(
                                updatedVerified,
                                width: 20.0,
                                height: 20.0,
                                colorFilter:
                                ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              )
                                  : const SizedBox.shrink()
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
                        child: new Divider(
                          color: AppColors.DIVIDER_COLOR,
                        ),
                      ),
                    ],
                  )
                ]);
              },
            ),
          ),
        );
      }),
    );
  }

  void verifySignup() {
    _registerController.callSignUpAPI().then((value) {
      if (value.isNotEmpty) {
        _registerController.showInSnackBar(value);
      } else {
        globals.uploadedImage = null;
        globals.picture.value = "";

        _registerController.preferences.authToken= globals.authToken!;
        Future.delayed(Duration(milliseconds: 1)).then((_) {
          _registerController.checkInternet(getProfileInfo, false);
        });
      }
    });
  }

  void getProfileInfo() {
    _registerController.getProfileInfo().then((value) {
      if (value!.isNotEmpty) {
        if (value == "timeout") {
          _registerController.toast.show(
            context: context,
            message: 'session_timeout_err'.tr,
          );
          _registerController.preferences.clearPreference();
          _registerController.setNavigation(AppRoutes.APP_ROUTE_LOGIN);
        } else if (value == "offline") {
          _registerController.netOffSnackbar(getProfileInfo, false);
        } else {
          _registerController.showInSnackBar(value);
        }
      } else {
        if (globals.theme == 1) {
          var brightness = MediaQuery.of(context).platformBrightness;
          globals.isDarkTheme = brightness == Brightness.dark;
          if (globals.isDarkTheme) {
            AppColors().changeToDark();
          } else {
            AppColors().changeToLight();
          }
        } else if (globals.theme == 2) {
          globals.isDarkTheme = false;
          AppColors().changeToLight();
        } else {
          globals.isDarkTheme = true;
          AppColors().changeToDark();
        }
        globals.isShowMapPage = true;
        Get.offNamed(AppRoutes.APP_HOME);
      }
    });
  }
}