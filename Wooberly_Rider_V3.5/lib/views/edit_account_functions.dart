part of 'edit_account.dart';

extension EditAccountFunctions on _EditAccountViewState {
  void _settingModalBottomSheet(bool isForGender) {
    App().showBottomSheet(
      Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
        return Container(
          color: AppColors.PRIMARY_LIGHT_COLOR,
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: isForGender
                    ? null
                    : Icon(
                        Icons.add_a_photo,
                        color: AppColors.PRIMARY_ICON_COLOR,
                      ),
                title: isForGender
                    ? Text(
                        'male'.tr,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16),
                      )
                    : Text(
                        'camera'.tr,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16),
                      ),
                onTap: () {
                  if (isForGender) {
                    checkInternetProfileUpdate(
                        "gender", "male", builderContext);
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
                        colorFilter: ColorFilter.mode(
                            AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
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
                          color: AppColors.PRIMARY_ICON_COLOR,
                        ),
                  title: isForGender
                      ? Text(
                          'female'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.w500,
                              fontSize: AppDimen.text_size_16),
                        )
                      : Text(
                          'gallery'.tr,
                          style: TextStyle(
                              color: AppColors.BLACK_TEXT_COLOR,
                              fontFamily: AppFont.font,
                              fontWeight: FontWeight.w500,
                              fontSize: AppDimen.text_size_16),
                        ),
                  onTap: () {
                    if (isForGender) {
                      checkInternetProfileUpdate(
                          "gender", "female", builderContext);
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
                          colorFilter: ColorFilter.mode(
                              AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        )
                      : const SizedBox.shrink()),
              isForGender
                  ? ListTile(
                      leading: null,
                      title: Text(
                        'other'.tr,
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16),
                      ),
                      onTap: () {
                        if (isForGender) {
                          checkInternetProfileUpdate(
                              "gender", "other", builderContext);
                        }
                      },
                      trailing: (isForGender && globals.gender == "other")
                          ? SvgPicture.asset(
                              updatedVerified,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                  AppColors.PRIMARY_ICON_COLOR,
                                  BlendMode.srcIn),
                            )
                          : const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        );
      }),
    );
  }

  Future getImage(bool value) async {
    if (value) {
      String? imagepath = await Get.to(CameraScreen());

      if(imagepath !=null) {
        try {
          _image = File(imagepath!);
          _editAccountController.setLoadingController(false);

          if (_image != null) {
            ScaffoldMessenger.of(builderContext).hideCurrentSnackBar();
            _sendImgToServer();
          } else {
            _editAccountController.checkInternet(() {}, true);
          }
        } on Exception catch (e) {
          debugPrint("gallery exception: ${e}");

          if (e.toString().contains("The user did not allow")) {
            _editAccountController.toast.show(
              context: context,
              message: 'pls_enable_permission'
                  .trParams({'field3': 'camera'.tr.toLowerCase()}),
            );
            await openAppSettings();
          }
        }
      }
    } else {
      try {
        bool hasGalleryPermission = await _requestGalleryPermission();
        if (!hasGalleryPermission) {
          _editAccountController.showPermissionDialog(permissionType:'appService',title: 'pls_enable_permission'
              .trParams({'field3': 'gallery'.tr.toLowerCase()}));
          return;
        }
        PlatformFile? result = await FilePicker.pickFile(
          type: FileType.image,
        );
        _image = File(result!.path!);
        _editAccountController.setLoadingController(false);

        if (_image != null) {
          ScaffoldMessenger.of(builderContext).hideCurrentSnackBar();

          _sendImgToServer();
        } else {
          _editAccountController.checkInternet(() {}, true);
        }
      } on Exception catch (e) {
        debugPrint("gallery exception: ${e}");
        if (e.toString().contains(" User did not allow")) {
          _editAccountController.toast.show(
            context: builderContext,
            message: 'pls_enable_permission'
                .trParams({'field3': 'gallery'.tr.toString().toLowerCase()}),
          );

          // await openAppSettings();
        }
      }
    }
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isIOS) {
      return await _requestIOSPermission();
    } else if (Platform.isAndroid) {
      return await _requestAndroidPermission();
    }
    return false;
  }

// ─── iOS ───────────────────────────────────────────────────────────────────

  Future<bool> _requestIOSPermission() async {
    PermissionStatus status = await Permission.photos.status;

    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited) {
      return true;
    }

    status = await Permission.photos.request();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

// ─── Android ───────────────────────────────────────────────────────────────

  Future<bool> _requestAndroidPermission() async {

    final sdkInt = await _editAccountController.getAndroidSDKVersion();

    if (sdkInt >= 33) {
      // Android 13+ (API 33, 34, 35, 36/Android 17...):
      // System Photo Picker — no permission needed
      return true;
    } else {
      // Android 12 and below (API <= 32):
      return await _checkAndRequest(Permission.storage);
    }
  }

  Future<bool> _checkAndRequest(Permission permission) async {
    PermissionStatus status = await permission.status;
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited) {
      return true;
    }
    status = await permission.request();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }


  _sendImgToServer() async {
    _selectedimgbytes = await _image?.readAsBytes();
    globals.uploadedImage = _selectedimgbytes;
    _netoffFile = _image;
    _readytoupload();
  }

  _readytoupload() {
    _editAccountController.checkInternet(() {}, false).then((onValue) {
      _editAccountController.checkInternet(_uploadPhoto, false).then((onValue) {
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
    _editAccountController
        .uploadMultipart(
            _image!, "front", "${globals.UPLOAD_URL}/uploadProfilePhoto")
        .then((value) {
      if (value.isNotEmpty) {
        _image = null;

        if (value != "Offline") {
          _editAccountController.showInSnackBar(value);
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
    globals.picture.value = _editAccountController.profileImage != null
        ? globals.UPLOAD_URL +
            "/images/avatar/medium_" +
            _editAccountController.profileImage!
        : "";
    lastuploadedimage = _selectedimgbytes;
    globals.uploadedImage = null;
  }

  openBottomSheet(BuildContext context, String label) {
    BuildContext? bsctx;

    showBottomSheetCustom(builder: (BuildContext bscontext) {
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
                  const SizedBox(
                    height: 40,
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 24.0, top: 22.0),
                        child: InkWell(
                          onTap: () {
                            Get.back();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.PRIMARY_LIGHT_COLOR,
                                shape: BoxShape.circle),
                            child: RotatedBox(
                              quarterTurns: globals.isRTLLang ? 2 : 0,
                              child: SvgPicture.asset(
                                primaryLeftArrow,
                                colorFilter: ColorFilter.mode(
                                    AppColors.PRIMARY_ICON_COLOR,
                                    BlendMode.srcIn),
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  label != 'password_hint'.tr
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 24.0, top: 30),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              label == 'password_hint'.tr
                                  ? toBeginningOfSentenceCase(
                                      'current_pass_label'.tr)!
                                  : label,
                              style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontSize: AppDimen.text_size_16,
                                  fontFamily: AppFont.font,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  if (label == 'firstname_label'.tr) firstNameTextField(),
                  if (label == 'lastname_label'.tr) lastNameTextField(),
                  if (label == 'phoneno_label'.tr) phoneNoTextField(),
                  if (label == 'email_label'.tr) emailTextField(),
                  if (label == 'password_hint'.tr) passwordTextField(),
                  const Spacer(),
                  Obx(() {
                    return Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 20, bottom: 24, start: 24, end: 24),
                        child: PrimaryButton(
                          buttonTitle:
                              (_editAccountController.saveController.value == 2)
                                  ? 'try_again'.tr
                                  : 'Update'.tr,
                          buttonImage: primaryBtnArrow,
                          callback: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            if (_editAccountController.saveController.value !=
                                    2 &&
                                _editAccountController.saveController.value !=
                                    1) {
                              if (label == 'firstname_label'.tr) {
                                int firstlength = _editAccountController
                                    .firstNameController.text
                                    .toString()
                                    .length;

                                if (firstlength > globals.nameLength[0] - 1 &&
                                    firstlength - 1 < globals.nameLength[1]) {
                                  _editAccountController
                                          .firstNameController.text =
                                      toBeginningOfSentenceCase(
                                          _editAccountController
                                              .firstNameController.text
                                              .toString()
                                              .trim());
                                  checkInternetProfileUpdate(
                                      "firstName",
                                      _editAccountController
                                          .firstNameController.text,
                                      bsctx!);
                                } else {
                                  _editAccountController.toast.show(
                                      context: context,
                                      message: 'name_length_error'.trParams({
                                        'field1': label,
                                        'field2':
                                            globals.nameLength[0].toString(),
                                        'field3':
                                            globals.nameLength[1].toString()
                                      }));
                                }
                              } else if (label == 'lastname_label'.tr) {
                                int firstlength = _editAccountController
                                    .lastNameController.text
                                    .toString()
                                    .length;

                                if (firstlength > globals.nameLength[0] - 1 &&
                                    firstlength - 1 < globals.nameLength[1]) {
                                  _editAccountController
                                          .lastNameController.text =
                                      toBeginningOfSentenceCase(
                                          _editAccountController
                                              .lastNameController.text
                                              .toString()
                                              .trim());

                                  checkInternetProfileUpdate(
                                      "lastName",
                                      _editAccountController
                                          .lastNameController.text,
                                      bsctx!);
                                } else {
                                  _editAccountController.toast.show(
                                      context: context,
                                      message: 'name_length_error'.trParams({
                                        'field1': label,
                                        'field2':
                                            globals.nameLength[0].toString(),
                                        'field3':
                                            globals.nameLength[1].toString()
                                      }));
                                }
                              } else if (label == 'email_label'.tr) {
                                checkInternetProfileUpdate(
                                    "email",
                                    _editAccountController.emailController.text,
                                    bsctx!);
                              } else if (label == 'password_hint'.tr) {
                                bool response = _setPasswordValidation();
                                a.SystemChannels.textInput
                                    .invokeMethod('TextInput.hide');
                                if (response) {
                                  checkInternetProfileUpdate(
                                      "password",
                                      _editAccountController
                                          .passwordController.text,
                                      bsctx!);
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        );
      });
    });
  }

  _lastNameChild() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: InkWell(
        onTap: () {
          _editAccountController.lastNameController.text =
              globals.lastname.value;
          _editAccountController.isSpaceAllow = true;
          openBottomSheet(context, 'lastname_label'.tr);
        },
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              borderRadius: BorderRadius.all(Radius.circular(3))),
          height: 50,
          child: Obx(
            () => Text(
              toBeginningOfSentenceCase(globals.lastname.value)!,
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

  _genderChild(BuildContext context) {
    debugPrint("_editAccountController.gender.value: ${globals.gender}");
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(builderContext).hideCurrentSnackBar();
          _settingModalBottomSheet(true);
        },
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              borderRadius: BorderRadius.all(Radius.circular(3),
              ),
          ),
          height: 50,
          child: Obx(() {
            _editAccountController.gender.value;
            _editAccountController.getGender(globals.gender);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Expanded(
                    child: (globals.gender != null && globals.gender != "null" && globals.gender!.isNotEmpty)
                        ? Text(
                            _editAccountController.gender.value,
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w500),
                          )
                        : Text(
                            'select_your_gender'.tr,
                            style: TextStyle(
                                color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                fontSize: AppDimen.text_size_16,
                                fontFamily: AppFont.font,
                                fontWeight: FontWeight.w400),
                          ),
                  ),
                ),
                SvgPicture.asset(
                  primaryDownArrow,
                  colorFilter: ColorFilter.mode(
                      AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  _emailChild() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 13),
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 20,
        ),
        decoration: BoxDecoration(
            color: AppColors.DISABLE_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(3))),
        height: 50,
        child: Text(
          _editAccountController.emailController.text,
          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontSize: AppDimen.text_size_16,
              fontFamily: AppFont.font,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  _changeProfile(String fieldName, String fieldValue, BuildContext context) {
    if (fieldName == "password") {
      _editAccountController.updatePassword().then((value) {
        _editAccountController.saveController.refresh();
        globals.setButtonIdle();

        if (value.isNotEmpty) {
          _editAccountController.toast.show(
            context: context,
            message: value,
          );
        } else {
          Get.back();
        }
      });
    } else {
      _editAccountController
          .updateProfileInfo(fieldName, fieldValue)
          .then((value) {
        if (value.isNotEmpty) {
          _editAccountController.showInSnackBar(value);
        } else {
          if (fieldName == "firstName")
            globals.firstname.value =
                _editAccountController.firstNameController.text;
          if (fieldName == "lastName")
            globals.lastname.value =
                _editAccountController.lastNameController.text;
          if (fieldName == "gender") {
            globals.gender = fieldValue;
            _editAccountController.gender.value = fieldValue;
          }
          if (fieldName != "gender") Get.back();
          globals.setButtonIdle();
          PrimaryScaffold.avoidLoader.value = false;
        }
      });
    }
  }

  checkInternetProfileUpdate(
      String fieldName, String fieldValue, BuildContext ctx) {
    globals.isContinuousLoading = true;
    if (fieldName != "gender") PrimaryScaffold.avoidLoader.value = true;
    globals.setButtonLoading();

    _editAccountController.checkInternet(() {}, true).then((connection) {
      if (connection != null && connection) {
        if (fieldName == "gender") Get.back();
        _changeProfile(fieldName, fieldValue, ctx);
      } else {
        FocusScope.of(context).unfocus();
        _editAccountController.firstNameController.text =
            globals.firstname.value + " ";
        _editAccountController.lastNameController.text =
            globals.lastname.value + " ";
        _editAccountController.emailController.text = globals.email;
        _editAccountController.saveController.refresh();
      }
    });
  }

  bool _setPasswordValidation() {
    bool passstr = (globals.isCurrentPassword) &&
        (_editAccountController.passwordEditController.text == null ||
            _editAccountController.passwordEditController.text
                .toString()
                .isEmpty ||
            _editAccountController.passwordEditController.text
                    .toString()
                    .length <
                7);
    if (passstr) {
      _editAccountController.toast.show(
          context: context,
          message:
              'old_pass_error'.trParams({'field': 'current_pass_label'.tr}));
      return false;
    } else if (_editAccountController.newpasswordEditController.text == null ||
        _editAccountController.newpasswordEditController.text
            .toString()
            .isEmpty) {
      _editAccountController.toast.show(
          context: context,
          message: 'empty_msg'
              .trParams({'field': 'new_pass_label'.tr}).toLowerCase());
      return false;
    } else if (_editAccountController.newpasswordEditController.text
            .toString()
            .length <
        8) {
      _editAccountController.toast.show(
          context: context,
          message: 'length_error'.trParams(
              {'field1': 'password_hint'.tr, "field2": 8.toString()}));
      return false;
    } else if (_editAccountController.confirmpasswordEditController.text ==
            null ||
        _editAccountController.confirmpasswordEditController.text
            .toString()
            .isEmpty) {
      _editAccountController.toast.show(
          context: context,
          message: 'empty_msg'.trParams({'field': 'con_pass_label'.tr}));
      return false;
    } else if (_editAccountController.confirmpasswordEditController.text
            .toString() !=
        _editAccountController.newpasswordEditController.text.toString()) {
      _editAccountController.toast
          .show(context: context, message: 'mismatch_pass_error'.tr);
      return false;
    }
    return true;
  }
}