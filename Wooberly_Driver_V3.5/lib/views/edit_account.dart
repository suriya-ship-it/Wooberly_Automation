import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/bottom_sheet.dart';
import 'package:wooberly_driver/widgets/country_code_picker.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';
import 'camera_screen.dart';

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
  final EditAccountController _controller = Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  bool passwordVisible = false;
  bool newPasswordVisible = false;
  bool _conPassVisible = false;
  bool _obscureText = true;
  bool _newPassObscureText = true;
  bool _conPassObscureText = true;


  File? _image, _netoffFile;
  bool oneTimeSend = true;
  BuildContext? builderContext;
  bool uploadSuccess = false;
  Uint8List? lastuploadedimage = null, _selectedimgbytes;
  late ThemeData apptheme;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 1), () {
        _initializeCamera();
      });
    });
    lastuploadedimage = globals.uploadedImage;
    _controller.init();
    super.initState();
  }
  _initializeCamera() async{
   await  Permission.camera.request();
    Permission.camera.status.isGranted.then((isGranted) {
      if (isGranted) {
        if(globals.cameraController == null && Platform.isAndroid)
          App().initializeCamera();
      }
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 400), () {
        globals.cameraController?.dispose().then((_){
          globals.cameraController = null;
        });
      });
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    apptheme = Theme.of(context);
    return PrimaryScaffold(
      key: _scaffoldKey,
      disableAppbar: false,
      appBarTitle: edit_profile_title.tr,
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
        children: <Widget>[
          Center(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(builderContext!).hideCurrentSnackBar();
                _settingModalBottomSheet(false);
              },
              child: Container(
                width: 150.0,
                height: 150.0,
                padding: const EdgeInsetsDirectional.only(top: 10.0),
                child: Stack(children: <Widget>[
                  Center(
                    child: GetBuilder(
                      init: EditAccountController(),
                        id: _controller.rxLoadingController.id,
                        builder: (val) {
                          return Opacity(
                            opacity:
                            _controller.rxLoadingController.value == false
                                    ? 1
                                    : 0,
                            child: SvgPicture.asset(
                              defaultProfileSvg,
                              height: 120,
                              width: 120,
                            ),
                          );
                        }),
                  ),
                  Center(
                    child: GetBuilder(
                      init: EditAccountController(),
                        id: _controller.rxLoadingController.id,
                        builder: (val) {
                          if (_controller.rxLoadingController.value == true)
                            uploadSuccess = true;
                          return (_controller.rxLoadingController.value == true)
                              ? new SizedBox(
                                  width: 120.0,
                                  height: 120.0,
                                  child: _controller.getProgressIndicator(context,
                                      AppColors.PRIMARY_COLOR_DARK.withValues(alpha:0.2)))
                              : new SizedBox(
                                  width: 120.0,
                                  height: 120.0,
                                  child: globals.uploadedImage == null
                                      ? new ClipOval(
                                          child: _image != null
                                              ? Image.file(
                                                  _image!,
                                                  fit: BoxFit.cover,
                                                )
                                              : globals.picture != null &&
                                                      globals.picture.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      height: 120.0,
                                                      width: 120.0,
                                                      fit: BoxFit.cover,
                                                      imageUrl: globals.picture,
                                                      placeholder: (context,
                                                              url) =>
                                                          _controller.getProgressIndicator(
                                                              context,
                                                              AppColors.PRIMARY_COLOR_DARK
                                                                  .withValues(alpha:
                                                                      0.2)),
                                                    )
                                                  : SvgPicture.asset(
                                                      defaultProfileSvg,
                                                      height: 120.0,
                                                      width: 120.0,
                                                    ),
                                        )
                                      : new ClipOval(
                                          child: Image.memory(
                                          globals.uploadedImage,
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                                );
                        }),
                  ),
                  Positioned(
                    bottom: 8.0,
                    right: globals.isRtlLang ? null : -10.0,
                    left: globals.isRtlLang ? -10.0 : null,
                    child: RawMaterialButton(
                      child: SvgPicture.asset(
                        editingSvg,
                        fit: BoxFit.scaleDown,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_WHITE, BlendMode.srcIn),
                      ),
                      shape: new CircleBorder(),
                      elevation: 2.0,
                      fillColor: AppColors.PRIMARY_COLOR_DARK,
                      onPressed: () {
                        ScaffoldMessenger.of(builderContext!)
                            .hideCurrentSnackBar();
                        _settingModalBottomSheet(false);
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 26.0),
            child: Text(
              firstname_label.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _firstNameChild(),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              lastname_label.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _lastNameChild(),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              Gender.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _genderChild(context),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              email_label.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _emailChild(),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              phone_no_label.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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
                SizedBox(
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
                              _controller.mobile,
                              style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: Text(
                            verified_label.tr,
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
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              password_label.tr,
              style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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

                  _controller.setPasswordObserver();

                  openPasswordDialog();
                },
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      borderRadius: BorderRadius.all(Radius.circular(3))),
                  height: 50,
                  child: TextField(
                    enableIMEPersonalizedLearning: false,
                    enabled: false,
                    obscureText: true,
                    controller: _controller.passwordController,
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(0.0),
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

  void _settingModalBottomSheet(bool isForGender) {
    Get.bottomSheet(
      backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
          return SafeArea(
            bottom: Platform.isAndroid,
            child: Container(
              color: AppColors.PRIMARY_COLOR_WHITE,
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: isForGender
                        ? null
                        : Icon(
                            Icons.add_a_photo,
                            color: AppColors.PRIMARY_COLOR_DARK,
                          ),
                    title: isForGender
                        ? Text(
                            male.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16),
                          )
                        : Text(
                            camera.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16),
                          ),
                    onTap: () {
                      if (isForGender) {
                        Get.back();
                        checkInternetProfileUpdate(
                            "gender", "male", builderContext!);
                      } else {
                        Get.back();
                        getImage(true);
                      }
                    },
                    trailing: (isForGender && globals.gender == "male")
                        ? SvgPicture.asset(
                            updatedVerified,
                            width: 24,
                            height: 24,
                           colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                          )
                        : Container(
                            width: 0,
                          ),
                  ),
                  ListTile(
                    leading: isForGender
                        ? null
                        : Icon(
                            Icons.camera,
                            color: AppColors.PRIMARY_COLOR_DARK,
                          ),
                    title: isForGender
                        ? Text(
                            female.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16),
                          )
                        : Text(
                            gallery.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16),
                          ),
                    onTap: () {
                      if (isForGender) {
                        Get.back();
                        checkInternetProfileUpdate(
                            "gender", "female", builderContext!);
                      } else {
                        Get.back();
                        getImage(false);
                      }
                    },
                    trailing: (isForGender && globals.gender == "female")
                        ? SvgPicture.asset(
                            updatedVerified,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                          )
                        : Container(
                            width: 0,
                          ),
                  ),
                  isForGender
                      ? ListTile(
                          leading: null,
                          title: Text(
                            other.tr,
                            style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16),
                          ),
                          onTap: () {
                            if (isForGender) {
                              Get.back();
                              checkInternetProfileUpdate(
                                  "gender", "other", builderContext!);
                            }
                          },
                          trailing: (isForGender && globals.gender == "other")
                              ? SvgPicture.asset(
                                  updatedVerified,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                                )
                              : const SizedBox.shrink()
                        )
                      : const SizedBox.shrink()
                ],
              ),
            ),
          );
        }
      )
    );
  }

  Future getImage(bool value) async {
    if (value) {
      String imagepath = "";
      bool cameraimage = await Get.to(CameraScreen());
      if (globals.cameraFilePath != null && cameraimage) {
        imagepath = globals.cameraFilePath;
      }
      try {
        if(imagepath!=null && imagepath.isNotEmpty) {
          _image = File(imagepath);
          _controller.setLoadingController(false);
        }

        if (_image != null) {
          ScaffoldMessenger.of(builderContext!).hideCurrentSnackBar();
          _sendImgToServer();
        } else {
          _controller.checkInternet(() {}, true);
        }
      } on Exception catch (e) {
        if (e.toString().contains("The user did not allow")) {
          App().toast.show(
                context: context,
                message: pls_enable_permission.trParams({"field":camera.tr.toLowerCase()}),
              );
          bool isOpened = await openAppSettings();
        }
      }
    } else {
      try {
        PlatformFile? result = await FilePicker.pickFile(
          type: FileType.image,
        );
        _image = File(result!.path!);
        _controller.setLoadingController(false);

        if (_image != null) {
          ScaffoldMessenger.of(builderContext!).hideCurrentSnackBar();

          _sendImgToServer();
        } else {
          _controller.checkInternet(() {}, true);
        }
      } on Exception catch (e) {
        if (e.toString().contains("User did not allow")) {
          App().toast.show(
                context: builderContext!,
                message: pls_enable_permission.trParams({"field":gallery.tr.toLowerCase()}),
              );

          await openAppSettings();
        }
      }
    }
  }

  _sendImgToServer() async {
    _selectedimgbytes = await _image?.readAsBytes();

    double fileSizeInKB = _selectedimgbytes!.length / 1024;

    double fileSizeInMB = fileSizeInKB / 1024;
    globals.uploadedImage = _selectedimgbytes;
    _netoffFile = _image;
    _readytoupload();
  }

  _readytoupload() {
    _controller.checkInternet(() {}, false).then((onValue) {
      _controller.checkInternet(_uploadPhoto, false).then((onValue) {
        if (!onValue) {
            uploadSuccess = false;
            _image = null;
            globals.uploadedImage = lastuploadedimage;
        } else {
          globals.uploadedImage = null;
        }
      });
    });
  }

  _uploadPhoto() {
    uploadSuccess = false;
    if (_image == null && _netoffFile != null) {
      globals.uploadedImage = null;
      _image = _netoffFile;
    }
    _controller
        .uploadMultipart(
            _image!, "front", "${globals.UPLOAD_URL}/uploadProfilePhoto")
        .then((value) {
      if (value.isNotEmpty) {
        _image = null;
        if (value != "Offline") {
          _controller.showInSnackBar(value);
        } else {
          _image = _netoffFile;
          _readytoupload();
        }
      } else {
        oneTimeSend = true;
        uploadSuccess = true;
        saveProfilePic();
      }
    });
  }

  void saveProfilePic() async {
    globals.picture =
        globals.UPLOAD_URL + "/images/avatar/" + _controller.profileImage!;
    lastuploadedimage = _selectedimgbytes;
    globals.uploadedImage = null;
  }

  openBottomSheet(BuildContext context, String label) {
    _controller.change(rxVariable: _controller.rxSaveController, value: 0);
    BuildContext? bsctx;

    showBottomSheetCustom(
        context: context,
        builder: (BuildContext bscontext) {
          bsctx = context;
          return Consumer<ModelTheme>(
              builder: (context, ModelTheme themeNotifier, child) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Container(
                    color: AppColors.COMMON_BG_COLOR,
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 40),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 24.0, top: 22.0),
                                child: InkWell(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: AppColors.PRIMARY_COLOR_WHITE, shape: BoxShape.circle),
                                    child: SvgPicture.asset(
                                      primaryLeftArrow,
                                      matchTextDirection: true,
                                      colorFilter: ColorFilter.mode(
                                          AppColors.ICON_COLOUR, BlendMode.srcIn),
                                      fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          label != password_label.tr
                              ? Padding(
                            padding: const EdgeInsetsDirectional.only(start: 24.0, top: 30),
                            child: Align(
                              alignment: globals.isRtlLang
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                label == password_label.tr
                                    ? toBeginningOfSentenceCase(
                                    current_pass_label.tr)!
                                    : label,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                          if (label == firstname_label.tr)
                            firstNameTextField(),
                          if (label == lastname_label.tr)
                            lastNameTextField(),
                          if (label == phone_no_label.tr)
                            phoneNoTextField(),
                          if (label == email_label.tr) emailTextField(),
                          if (label == password_label.tr)
                            passwordTextField(),
                          const Spacer(),
                          GetBuilder(
                              init: EditAccountController(),
                              id: _controller.rxSaveController.id,
                              builder: (val) {
                                return Align(
                                  alignment: AlignmentDirectional.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 20, bottom: 24, start: 24, end: 24),
                                    child: PrimaryButton(
                                      buttonTitle:
                                      (_controller.rxSaveController.value == 2)
                                          ? try_again.tr
                                          : Update.tr,
                                      buttonImage: primaryBtnArrow,
                                      callback: () {
                                        if (_controller.rxSaveController.value != 2 && _controller.rxSaveController.value != 1) {
                                          if (label ==
                                              firstname_label.tr) {
                                            int firstlength = _controller.firstNameController.text
                                                .toString()
                                                .length;
                                            if (firstlength > globals.nameLength[0] - 1 &&
                                                firstlength - 1 < globals.nameLength[1]) {
                                              _controller.firstNameController.text =
                                                  toBeginningOfSentenceCase(_controller
                                                      .firstNameController.text
                                                      .toString()
                                                      .trim());
                                              _controller.change(rxVariable: _controller.rxSaveController, value: 1);
                                              checkInternetProfileUpdate("firstName",
                                                  _controller.firstNameController.text, bsctx!);
                                            } else {
                                              App().toast.show(
                                                  context: context,
                                                  message: name_length_error.trParams({"field1":label,"field2":globals.nameLength[0].toString(),"field3":globals.nameLength[1].toString()}));
                                            }
                                          } else if (label ==
                                              lastname_label.tr) {
                                            int firstlength = _controller.lastNameController.text
                                                .toString()
                                                .length;
                                            if (firstlength > globals.nameLength[0] - 1 &&
                                                firstlength - 1 < globals.nameLength[1]) {
                                              _controller.lastNameController.text =
                                                  toBeginningOfSentenceCase(_controller
                                                      .lastNameController.text
                                                      .toString()
                                                      .trim());

                                              _controller.change(rxVariable: _controller.rxSaveController, value: 1);
                                              checkInternetProfileUpdate("lastName",
                                                  _controller.lastNameController.text, bsctx!);
                                            } else {
                                              App().toast.show(
                                                  context: context,
                                                  message: name_length_error.trParams({"field1":label,"field2":globals.nameLength[0].toString(),"field3":globals.nameLength[1].toString()}));
                                            }
                                          } else if (label ==
                                              email_label.tr) {
                                            _controller.change(rxVariable: _controller.rxSaveController, value: 1);
                                            checkInternetProfileUpdate(
                                                "email", _controller.emailController.text, bsctx!);
                                          } else if (label ==
                                              password_label.tr) {
                                            bool response = _setPasswordValidation();
                                            SystemChannels.textInput.invokeMethod('TextInput.hide');
                                            if (response) {
                                              _controller.change(rxVariable: _controller.rxSaveController, value: 1);
                                              checkInternetProfileUpdate("password",
                                                  _controller.passwordController.text, bsctx!);
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }

  String validateFirstName(String? value) {
    if (value?.length == 0) {
      return empty_msg.trParams({"field":firstname_label.tr});
    } else if ((value?.length ?? 0) < 4) {
      return length_error.trParams({"field":firstname_label.tr,"field2":"2"});
    } else {
      return "";
    }
  }


  firstNameTextField() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
      child: GetBuilder(
        init: EditAccountController(),
          id: _controller.rxCursorControlController.id,
          builder: (val) {
            return Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              height: 50,
              child: TextField(
                cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                autocorrect: false,
                keyboardType: TextInputType.text,
                controller: _controller.firstNameController,
                focusNode: _controller.firstNameFocusNode,
                showCursor: _controller.rxCursorControlController.value,
                decoration: new InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(0.0),
                ),
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontFamily: AppFont.font,
                    fontWeight: FontWeight.w500,
                    fontSize: AppDimen.text_size_16),
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(globals.nameLength.last)
                ],
              ),
            );
          }),
    );
  }

  lastNameTextField() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
      child: GetBuilder(
        init: EditAccountController(),
          id: _controller.rxCursorControlController.id,
          builder: (val) {
            return Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              height: 50,
              child: TextFormField(
                cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                keyboardType: TextInputType.text,
                focusNode: _controller.lastNameFocusNode,
                controller: _controller.lastNameController,
                showCursor: _controller.rxCursorControlController.value,
                enableIMEPersonalizedLearning: false,
                decoration: new InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(0.0),
                ),
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontFamily: AppFont.font,
                    fontWeight: FontWeight.w500,
                    fontSize: AppDimen.text_size_16),
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(globals.nameLength.last)
                ],
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
            color: AppColors.PRIMARY_COLOR_WHITE,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        height: 50,
        child: TextFormField(
          cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
          keyboardType: TextInputType.phone,
          validator: validateFirstName,
          decoration: new InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(0.0),
          ),
          style: TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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
            color: AppColors.PRIMARY_COLOR_WHITE,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        height: 50,
        child: TextFormField(
          keyboardType: TextInputType.emailAddress,
          controller: _controller.emailController,
          decoration: new InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(0.0),
            hintStyle: TextStyle(
                color: AppColors.HIND_TEXT_COLOR,
                fontSize: AppDimen.text_size_16,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.font),
          ),
          style: TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontFamily: AppFont.font,
              fontWeight: FontWeight.w500,
              fontSize: AppDimen.text_size_16),
        ),
      ),
    );
  }

  passwordTextField() {
    return GetBuilder(
      init: EditAccountController(),
        id: _controller.rxSaveController.id,
        builder: (val) {
          return Column(
            children: <Widget>[
                Container(
                  margin:const  EdgeInsetsDirectional.only(start: 24, end: 24, top: 20),
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  decoration: BoxDecoration(
                      color: AppColors.PRIMARY_COLOR_WHITE,
                      borderRadius:
                      BorderRadius.all(Radius.circular(3))),
                  height: 50,
                  child: TextFormField(
                    cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    enableIMEPersonalizedLearning: false,
                    enabled: _controller.rxSaveController.value == 0,
                    keyboardType: TextInputType.text,
                    obscureText: _obscureText,
                    textInputAction: TextInputAction.next,
                    controller: _controller.passwordEditController,
                    focusNode: _controller.passwordFocusNode,
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(_controller.newPasswordFocusNode);
                    },
                    decoration: new InputDecoration(
                      border: InputBorder.none,
                      hintText: toBeginningOfSentenceCase(
                          current_pass_label.tr),
                      hintStyle: TextStyle(
                        fontSize: AppDimen.text_size_16,
                        color: AppColors.HIND_TEXT_COLOR,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.PRIMARY_COLOR_DARK,
                        ),
                        onPressed: () {
                          passwordVisible = !passwordVisible;
                          _obscureText = !_obscureText;
                          _controller.change(rxVariable: _controller.rxSaveController, value: 0);
                        },
                      ),
                    ),
                    style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_16),
                  ),
                ),
              SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 10),
                margin: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius:
                    BorderRadius.all(Radius.circular(3))),
                height: 50,
                child: TextFormField(
                  cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  enableIMEPersonalizedLearning: false,
                  enabled: _controller.rxSaveController.value == 0,
                  keyboardType: TextInputType.text,
                  obscureText: _newPassObscureText,
                  controller: _controller.newPasswordEditController,
                  focusNode: _controller.newPasswordFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(_controller.confirmPasswordFocusNode);
                  },
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText: new_pass_label.tr,
                    hintStyle: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.HIND_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        newPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.PRIMARY_COLOR_DARK,
                      ),
                      onPressed: () {
                        newPasswordVisible = !newPasswordVisible;
                        _newPassObscureText = !_newPassObscureText;
                        _controller.change(rxVariable: _controller.rxSaveController, value: 0);
                      },
                    ),
                  ),
                  style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_16),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 10),
                margin: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 10),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius:
                    BorderRadius.all(Radius.circular(3))),
                height: 50,
                child: TextFormField(
                  cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  enableIMEPersonalizedLearning: false,
                  enabled: _controller.rxSaveController.value == 0,
                  keyboardType: TextInputType.text,
                  obscureText: _conPassObscureText,
                  controller:
                  _controller.conFirmPasswordEditController,
                  focusNode: _controller.confirmPasswordFocusNode,
                  textInputAction: TextInputAction.done,
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    hintText:
                    con_pass_label.tr,
                    hintStyle: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.HIND_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(

                        _conPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.PRIMARY_COLOR_DARK,
                      ),
                      onPressed: () {
                        _conPassVisible = !_conPassVisible;
                        _conPassObscureText = !_conPassObscureText;
                        _controller.change(rxVariable: _controller.rxSaveController, value: 0);
                      },
                    ),
                  ),
                  style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimen.text_size_16),
                ),
              ),
              SizedBox(
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
          if (globals.brandName.toLowerCase() == "samsung")
            _controller.firstNameController.text = globals.firstname + " ";
          else
            _controller.firstNameController.text = globals.firstname;
          _controller.isSpaceAllow = true;

          openBottomSheet(
              context, firstname_label.tr);
        },
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 8.0),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
              borderRadius: BorderRadius.all(Radius.circular(3))),
          constraints: BoxConstraints(
            minHeight: 50,
          ),
          child: GetBuilder<BaseController>(
            init: globals.baseController,
            id: globals.rxLoadingController.id,
            builder: (val) {
              return Text(
                toBeginningOfSentenceCase(globals.firstname)!,
                style: TextStyle(
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  fontSize: AppDimen.text_size_16,
                  fontFamily: AppFont.font,
                  fontWeight: FontWeight.w500),
              );
            }
          ),
        ),
      ),
    );
  }

  _lastNameChild() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: InkWell(
        onTap: () {
          if (globals.brandName.toLowerCase() == "samsung")
            _controller.lastNameController.text = globals.lastname + " ";
          else
            _controller.lastNameController.text = globals.lastname;
          _controller.isSpaceAllow = true;
          openBottomSheet(
              context, lastname_label.tr);
        },
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 8.0),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
              borderRadius: BorderRadius.all(Radius.circular(3))),
          constraints: BoxConstraints(
            minHeight: 50,
          ),
          child: GetBuilder<BaseController>(
            init: globals.baseController,
            id: globals.rxLoadingController.id,
            builder: (val) {
              return Text(
                toBeginningOfSentenceCase(globals.lastname)!,
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_16,
                    fontFamily: AppFont.font,
                    fontWeight: FontWeight.w500),
              );
            }
          ),
        ),
      ),
    );
  }

  _genderChild(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(builderContext!).hideCurrentSnackBar();
          _settingModalBottomSheet(true);
        },
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
              borderRadius: BorderRadius.all(Radius.circular(3))),
          constraints: BoxConstraints(
            minHeight: 50,
          ),
          child: GetBuilder<BaseController>(
            init: globals.baseController,
            id: globals.rxLoadingController.id,
            builder: (val) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Expanded(
                      child: (globals.gender != null && globals.gender != "null")
                          ? Text(
                              _controller.getGender(globals.gender!),
                              style: TextStyle(
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w500),
                            )
                          : Text(
                              select_your_gender.tr,
                              style: TextStyle(
                                  color: AppColors.HIND_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w400),
                            ),
                    ),
                  ),
                  SvgPicture.asset(
                    primaryDownArrow,
                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_COLOR_DARK, BlendMode.srcIn),
                  )
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  _emailChild() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
            color: AppColors.DISABLE_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        constraints: BoxConstraints(
          minHeight: 50,
        ),
        child: Text(
          _controller.emailController.text,
          style: TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontSize: AppDimen.text_size_16,
              fontFamily: AppFont.font,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  _changeProfile(String fieldName, String fieldValue, BuildContext context) {
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);

    if (fieldName == "password") {
      _controller.updatePassword().then((value) {
        _controller.change(rxVariable: _controller.rxSaveController, value: 0);
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        if (value.isNotEmpty) {
          App().toast.show(
                context: context,
                message: value,
              );
        } else {
          Get.back();
        }
      });
    } else {
      PrimaryScaffold.avoidLoader = false;
      _controller.updateProfileInfo(fieldName, fieldValue).then((value) {
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        if (value.isNotEmpty) {
          _controller.showInSnackBar(value);
        } else {
            if (fieldName == "firstName")
              globals.firstname = _controller.firstNameController.text;
            if (fieldName == "lastName")
              globals.lastname = _controller.lastNameController.text;
            if (fieldName == "gender") {
              globals.gender = fieldValue;
            }
            _controller.email = _controller.emailController.text;
            globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
          if (fieldName != "gender") Get.back();
        }
      });
    }
  }

  checkInternetProfileUpdate(
      String fieldName, String fieldValue, BuildContext ctx) {
    _controller.checkInternet(() {}, true).then((connection) {
      if (connection != null && connection) {
        _changeProfile(fieldName, fieldValue, ctx);
      } else {
        FocusScope.of(context).unfocus();
        _controller.firstNameController.text = globals.firstname + " ";
        _controller.lastNameController.text = globals.lastname + " ";
        _controller.emailController.text = globals.email;
        _controller.change(rxVariable: _controller.rxSaveController, value: 0);
      }
    });
  }

  bool _setPasswordValidation() {
    bool passstr = _controller.passwordEditController.text == null ||
        _controller.passwordEditController.text.toString().isEmpty ||
        _controller.passwordEditController.text.toString().length < 7;

    if (passstr) {
      App().toast.show(
          context: context,
          message: old_password_error.trParams({"field":current_pass_label.tr}));
      return false;
    } else if (_controller.newPasswordEditController.text == null ||
        _controller.newPasswordEditController.text.toString().isEmpty) {
      App().toast.show(
          context: context,
          message: empty_msg.trParams({"field":new_pass_label.tr}).toLowerCase());
      return false;
    } else if (_controller.newPasswordEditController.text.toString().length <
        8) {
      App().toast.show(
          context: context,
          message: length_error.trParams({"field":password_label.tr, "field2":8.toString()}));
      return false;
    } else if (_controller.conFirmPasswordEditController.text == null ||
        _controller.conFirmPasswordEditController.text.toString().isEmpty) {
      App().toast.show(
          context: context,
          message: empty_msg.trParams({"field":con_pass_label.tr}));
      return false;
    } else if (_controller.conFirmPasswordEditController.text.toString() !=
        _controller.newPasswordEditController.text.toString()) {
      App().toast.show(
          context: context,
          message: mismatch_pass_error.tr);
      return false;
    }
    return true;
  }

  void openPasswordDialog() {
    openBottomSheet(context, password_label.tr);
  }
}