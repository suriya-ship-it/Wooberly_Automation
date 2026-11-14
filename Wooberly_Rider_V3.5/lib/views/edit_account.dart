import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' as a;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/widgets/bottom_sheet.dart';
import 'package:app_name/controllers/edit_account_controller.dart';
import 'package:app_name/widgets/country_code_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/databases/app_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_button.dart';
import 'camera_screen.dart';

part 'edit_account_functions.dart';

class EditAccount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EditAccountView();
  }
}

class EditAccountView extends StatefulWidget {
  @override
  _EditAccountViewState createState() => _EditAccountViewState();
}

class _EditAccountViewState extends State<EditAccountView> {
   EditAccountController _editAccountController = Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  bool passwordVisible = false;
  bool newPasswordVisible = false;
  bool _conPassVisible = false;
  bool _obscureText = true;
  bool _newPassObscureText = true;
  bool _conPassObscureText = true;
  File? _image, _netoffFile;
  bool oneTimeSend = true;
  late BuildContext builderContext;
  bool uploadSuccess = false;
  dynamic lastuploadedimage = null, _selectedimgbytes;
   Widget placeHolderWidget =   SvgPicture.asset(
     defaultProfileSvg,
     height: 120,
     width: 120,
   );

  @override
  void initState() {
    debugPrint("phoneno: ${globals.phoneNumber}");
    _editAccountController.emailController.text = globals.email;

    lastuploadedimage = globals.uploadedImage;
    super.initState();
  }

  @override
  void dispose() {
    globals.setButtonIdle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          key: _scaffoldKey,
          disableAppbar: false,
          appBarTitle: 'edit_profile_title'.tr,
          body: ListView(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(builderContext).hideCurrentSnackBar();
                    _settingModalBottomSheet( false);
                  },
                  child: Container(
                    width: 150.0,
                    height: 150.0,
                    padding: const EdgeInsetsDirectional.only(top: 10.0),
                    child: Stack(children: <Widget>[
                      Center(
                        child: Obx((){
                              return Opacity(
                                opacity:
                                     !_editAccountController.loading.value ? 1 : 0,
                                child: placeHolderWidget,
                              );
                            }),
                      ),
                      Center(
                        child: Obx(() {
                              if (_editAccountController.loading.value )
                                uploadSuccess = true;
                              return (_editAccountController.loading.value )
                                  ? new Container(
                                      width: 120.0,
                                      height: 120.0,
                                      child: _editAccountController.getProgressIndicator())
                                  : new Container(
                                      width: 120.0,
                                      height: 120.0,
                                      child: globals.uploadedImage == null
                                          ? new ClipOval(
                                              child: _image != null
                                                  ? Image.file(
                                                      _image!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : globals.picture.value != null &&
                                                          globals.picture.value.isNotEmpty
                                                      ? CachedNetworkImage(
                                                          height: 120.0,
                                                          width: 120.0,
                                                          fit: BoxFit.cover,
                                                          imageUrl: globals.picture.value,
                                                          memCacheWidth: 300,
                                                          memCacheHeight: 300,
                                                          placeholder: (context,
                                                                  url) =>
                                                              placeHolderWidget,
                                                        )
                                                      : placeHolderWidget,
                                            )
                                          : new ClipOval(
                                              child: Image.memory(
                                              globals.uploadedImage,
                                              fit: BoxFit.cover,
                                            )),
                                    );
                            }),
                      ),
                      PositionedDirectional(
                        bottom: 8.0,
                        end: globals.isRTLLang ? null : -10.0,
                        start: globals.isRTLLang ? -10.0 : null,
                        child: IgnorePointer(
                          child: RawMaterialButton(
                            child: SvgPicture.asset(
                              editingSvg,
                              fit: BoxFit.scaleDown,
                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                            ),
                            shape: new CircleBorder(),
                            elevation: 2.0,
                            fillColor: AppColors.PRIMARY_ICON_COLOR,
                            onPressed: () {  },
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 26.0),
                child: Text(
                  'firstname_label'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _firstNameChild(),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 24.0),
                child: Text(
                  'lastname_label'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _lastNameChild(),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 24.0),
                child: Text(
                  'Gender'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _genderChild(context),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 24.0),
                child: Text(
                  'Email'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _emailChild(),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 24.0),
                child: Text(
                  'phoneno_label'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    CountryCodePicker(
                      initialSelection: globals.CountryCode,
                      isFromEditPage: true,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.DISABLE_COLOR,
                            borderRadius: BorderRadius.all(Radius.circular(3))),
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsetsDirectional.only(start: 20),
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  globals.phoneNumber ?? '',
                                  style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontFamily: AppFont.font,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 10),
                              child: Text(
                                'verified_label'.tr,
                                style: TextStyle(
                                    color: AppColors.VERIFY_COLOR,
                                    fontFamily: AppFont.font,
                                    fontSize: AppDimen.text_size_14,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 24.0),
                child: Text(
                  'password_hint'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 13, bottom: 50),
                child: InkWell(
                    onTap: () {
                      passwordVisible = false;
                      newPasswordVisible = false;
                      _conPassVisible = false;
                      _obscureText = true;
                      _newPassObscureText = true;
                      _conPassObscureText = true;
                      _editAccountController.setPasswordObserver();
                      openBottomSheet(
                          context, 'password_hint'.tr);
                    },
                    child: Container(
                      alignment: AlignmentDirectional.centerStart,
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20,),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_LIGHT_COLOR,
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                      height: 50,
                      child: TextField(
                        enabled: false,
                        obscureText: true,
                        controller: _editAccountController.passwordController,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_14,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsetsDirectional.all(0.0),
                        ),
                      ),
                    )),
              ),
            ],
          ),
          onChanged: (map) {
            builderContext = map["scaffoldcontext"];
            _scaffoldKey = map["scaffoldkey"];
          },
        );
      }
    );
  }

  String? validateFirstName(String? value) {
    if (value!.length == 0) {
      return 'empty_msg'.trParams({'field':
      'firstname_label'.tr});

    } else if (value!.length < 21) {
      
      return 'length_error'.trParams({'field1':'firstname_label'.tr,'field2': "2"});
    } else {
      return null;
    }
  }

  firstNameTextField() {
    return  Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
            child: Obx(() {
                  return Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        borderRadius: BorderRadius.all(Radius.circular(3))),
                    height: 50,
                    child: TextField(
                      cursorColor: AppColors.BLACK_TEXT_COLOR,
                      enableIMEPersonalizedLearning: false,
                      autocorrect: false,
                      keyboardType: TextInputType.text,
                      controller: _editAccountController.firstNameController,
                      focusNode: _editAccountController.firstNameFocusNode,
                      showCursor:  _editAccountController.cursorControlController.value == null
                          ? false
                          : _editAccountController.cursorControlController.value,
                      inputFormatters: <a.TextInputFormatter>[
                        a.LengthLimitingTextInputFormatter(
                            globals.nameLength.last)
                      ],
                      decoration: new InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsetsDirectional.all(0.0),
                      ),
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16),
                    ),
                  );
                }),
          );
  }

  lastNameTextField() {
    return  Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
            child: Obx(() {
                  return Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        borderRadius: BorderRadius.all(Radius.circular(3))),
                    height: 50,
                    child: TextFormField(
                      cursorColor: AppColors.BLACK_TEXT_COLOR,
                      enableIMEPersonalizedLearning: false,
                      keyboardType: TextInputType.text,
                      focusNode: _editAccountController.lasttNameFocusNode,
                      controller: _editAccountController.lastNameController,
                      showCursor: _editAccountController.cursorControlController.value,
                      inputFormatters: <a.TextInputFormatter>[
                        a.LengthLimitingTextInputFormatter(
                            globals.nameLength.last)
                      ],
                      decoration: new InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsetsDirectional.all(0.0),
                      ),
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontFamily: AppFont.font,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16),
                    ),
                  );
                }),
          );

  }

  phoneNoTextField() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        height: 50,
        child: TextFormField(
          keyboardType: TextInputType.phone,
          validator: (value){
            validateFirstName(value);
          },
          onSaved: (String? val) {},
          decoration: new InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsetsDirectional.all(0.0),
          ),
          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontFamily: AppFont.font,
              fontWeight: FontWeight.w500,
              fontSize: AppDimen.text_size_16),
        ),
      ),
    );
  }

  emailTextField() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        height: 50,
        child: TextFormField(
          keyboardType: TextInputType.emailAddress,
          controller: _editAccountController.emailController,
          decoration: new InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsetsDirectional.all(0.0),
          ),
          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontFamily: AppFont.font,
              fontWeight: FontWeight.w500,
              fontSize: AppDimen.text_size_16),
        ),
      ),
    );
  }

  passwordTextField() {
    return Obx(() {
          return Column(
            children: <Widget>[
              if (globals.isCurrentPassword)
                Container(
                    margin:const  EdgeInsetsDirectional.only(start: 24, end: 24, top: 20),
                    padding: const EdgeInsetsDirectional.only(start: 10),
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      borderRadius:
                      BorderRadius.all(Radius.circular(3))),
                  height: 50,
                  child: TextFormField(
                    cursorColor: AppColors.BLACK_TEXT_COLOR,
                    enableIMEPersonalizedLearning: false,
                    enabled: _editAccountController.saveController.value == null ||
                        _editAccountController.saveController.value == 0,
                    keyboardType: TextInputType.text,
                    obscureText: _obscureText,
                    textInputAction: TextInputAction.next,
                    controller: _editAccountController.passwordEditController,
                    focusNode: _editAccountController.passwordFocusNode,
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(
                          _editAccountController.newPasswordFocusNode);
                    },
                    decoration: new InputDecoration(
                      border: InputBorder.none,
                      hintText: toBeginningOfSentenceCase(
                          'current_pass_label'.tr),
                      hintStyle: TextStyle(
                        fontSize: AppDimen.text_size_16,
                        color: AppColors.PLACEHOLDER_TEXT_COLOR,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.PRIMARY_DARK_COLOR,
                        ),
                        onPressed: () {
                          passwordVisible = !passwordVisible;
                          _obscureText = !_obscureText;
                          _editAccountController.saveController.refresh();
                        },
                      ),
                    ),
                    style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_16),
                  ),
                ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 10),
                 margin: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius:
                    BorderRadius.all(Radius.circular(3))),
                height: 50,
                child: TextFormField(
                  cursorColor: AppColors.BLACK_TEXT_COLOR,
                  enableIMEPersonalizedLearning: false,
                  enabled: _editAccountController.saveController.value == 0,
                  keyboardType: TextInputType.text,
                  obscureText: _newPassObscureText,
                  controller: _editAccountController.newpasswordEditController,
                  focusNode: _editAccountController.newPasswordFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(
                        _editAccountController.confirmPasswordFocusNode);
                  },
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText:
                    'new_pass_label'.tr,
                    hintStyle: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        newPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.PRIMARY_DARK_COLOR,
                      ),
                      onPressed: () {
                        newPasswordVisible = !newPasswordVisible;
                        _newPassObscureText = !_newPassObscureText;
                        _editAccountController.saveController.refresh();
                      },
                    ),
                  ),
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_16),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 10),
                margin: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius:
                    BorderRadius.all(Radius.circular(3))),
                height: 50,
                child: TextFormField(
                  cursorColor: AppColors.BLACK_TEXT_COLOR,
                  enableIMEPersonalizedLearning: false,
                  enabled: _editAccountController.saveController.value == null ||
                      _editAccountController.saveController.value == 0,
                  keyboardType: TextInputType.text,
                  obscureText: _conPassObscureText,
                  controller:
                  _editAccountController.confirmpasswordEditController,
                  focusNode: _editAccountController.confirmPasswordFocusNode,
                  textInputAction: TextInputAction.done,
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText:
                    'con_pass_label'.tr,
                    hintStyle: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(

                        _conPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.PRIMARY_DARK_COLOR,
                      ),
                      onPressed: () {
                        _conPassVisible = !_conPassVisible;
                        _conPassObscureText = !_conPassObscureText;
                        _editAccountController.saveController.refresh();
                      },
                    ),
                  ),
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_16),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          );
        });
  }

  _firstNameChild() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: InkWell(
        onTap: () {
          _editAccountController.firstNameController.text = globals.firstname.value;
          _editAccountController.isSpaceAllow = true;
          openBottomSheet(context, 'firstname_label'.tr);
        },
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              borderRadius: BorderRadius.all(Radius.circular(3))),
          height: 50,
          child:
                Obx(()=>
                   Text(
                    toBeginningOfSentenceCase(globals.firstname.value)!,
                    style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_16,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500),
                  ),
                ),
        ),
      ),
    );
  }

}