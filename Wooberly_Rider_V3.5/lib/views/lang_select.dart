import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/app.dart';
import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;
import '../controllers/base_controller.dart';
import '../controllers/edit_account_controller.dart';

class LangSelect extends StatefulWidget {
  final String isFrom;

  const LangSelect({super.key, required this.isFrom});

  @override
  State<LangSelect> createState() => _LangSelectState();
}

class _LangSelectState extends State<LangSelect> {
  EditAccountController editAccountController = Get.find();
  final RxList<int> _filteredIndices = <int>[].obs;
  final RxList<String> _list = <String>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool isOneTimeClick = false.obs;
  final RxSet<String> _loadingLanguageCodes = RxSet<String>();

  void loadList() async {
    _isLoading.value = true;
    _list.value = editAccountController.languageDropDown;
    _filteredIndices.value = List.generate(_list.length, (index) => index);
    _isLoading.value = false;
    _isLoading.refresh();
  }

  void _onSearch(text) {
    if (text == null || text.isEmpty) {
      _isLoading.value = true;
      _filteredIndices.value = List.generate(_list.length, (index) => index);
      _isLoading.value = false;
    } else {
      _isLoading.value = true;
      _filteredIndices.clear();
      for (int i = 0; i < _list.length; i++) {
        if (_list[i].toLowerCase().contains(text.toString().toLowerCase())) {
          _filteredIndices.add(i);
        }
      }
      _isLoading.value = false;
    }
    _isLoading.refresh();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      loadList();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: "select_your_language".tr,
        body: Padding(
          padding: const EdgeInsetsDirectional.only(top: 10.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR, borderRadius: BorderRadius.all(Radius.circular(3))),
                height: 50,
                child: TextField(
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  keyboardType: TextInputType.text,
                  onChanged: (value) {
                    _onSearch(value);
                  },
                  showCursor: true,
                  decoration: InputDecoration(
                    hintText: "select_your_language".tr,
                    hintStyle: const TextStyle(fontSize: AppDimen.text_size_18),
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
              const SizedBox(
                height: 20,
              ),
              Obx(() {
                return !(_isLoading.value)
                    ? _filteredIndices.isEmpty
                        ? showEmptyView()
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _filteredIndices.length,
                              itemBuilder: (BuildContext ctxt, int index) {
                                int originalIndex = _filteredIndices[index];
                                String langName = _list[originalIndex];
                                String langCode = editAccountController.languageCode[originalIndex];
                                debugPrint("_filteredIndices: ${originalIndex} --- ${langName} --- ${langCode}");

                                return Wrap(children: <Widget>[
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      InkWell(
                                        onTap: () {
                                          if(!isOneTimeClick.value) {
                                            isOneTimeClick.value = true;
                                            editAccountController.checkInternet(
                                                    () =>
                                                    updateLangCurrency(originalIndex, false), false);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    alignment: AlignmentDirectional.centerStart,
                                                    child: Padding(
                                                        padding: const EdgeInsetsDirectional.symmetric(
                                                          vertical: 15.0,
                                                          horizontal: 24.0,
                                                        ),
                                                        child: Text(langName,
                                                            style: TextStyle(
                                                              color: AppColors.BLACK_TEXT_COLOR,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: AppDimen.text_size_18,
                                                            ))),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      if (!_loadingLanguageCodes.contains(langCode) && !isOneTimeClick.value) {
                                                        isOneTimeClick.value = true;
                                                        editAccountController.checkInternet(
                                                            () => updateLangCurrency(originalIndex, true),
                                                            false);
                                                      }
                                                    },
                                                    child: Obx(() {
                                                      return _loadingLanguageCodes.contains(langCode)
                                                          ? const CupertinoActivityIndicator()
                                                          : globals.downloadedLanguages.contains(langCode) ||
                                                                  originalIndex == 0
                                                              ? SvgPicture.asset(
                                                                  downloadComplete,
                                                                  width: 23.0,
                                                                  height: 23.0,
                                                                  colorFilter: ColorFilter.mode(
                                                                      AppColors.PRIMARY_ICON_COLOR,
                                                                      BlendMode.srcIn),
                                                                )
                                                              : SvgPicture.asset(
                                                                  languageDownload,
                                                                  width: 23.0,
                                                                  height: 23.0,
                                                                  colorFilter: ColorFilter.mode(
                                                                      AppColors.PRIMARY_ICON_COLOR,
                                                                      BlendMode.srcIn),
                                                                );
                                                    }),
                                                  )
                                                ],
                                              ),
                                            ),
                                            checkVerified(originalIndex)
                                                ? SvgPicture.asset(
                                                    updatedVerified,
                                                    width: 23.0,
                                                    height: 23.0,
                                                    colorFilter: ColorFilter.mode(
                                                        AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                  )
                                                : const SizedBox.shrink(),
                                            checkVerified(originalIndex)
                                                ? const SizedBox(width: 24)
                                                : const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
                                        child: Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  )
                                ]);
                              },
                            ),
                          )
                    : App().getProgressIndicator();
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget showEmptyView() {
    return Expanded(
      child: Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 26,),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(emptyLanguageSvg),
              SizedBox(height: 40,),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 3.0),
                child: Text(
                  'no_result_found'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFont.font),
                ),
              )
            ],
          )),
    );
  }

  bool checkVerified(int originalIndex) {
    int index1 =
        editAccountController.languageCode.indexWhere((element) => element == globals.preferredLanguage);
    return index1 == originalIndex;
  }

  updateLangCurrency(int originalIndex, bool isOnlyDownload) {
    String langName = editAccountController.languageDropDown[originalIndex];
    String langCode = editAccountController.languageCode[originalIndex];

    if (widget.isFrom == "phone_no") {
      _loadingLanguageCodes.add(langCode);
      if (!isOnlyDownload) {
        editAccountController.languageController.text = langName;
        globals.preferredLanguage = langCode;
        globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
        int targetIndex = editAccountController.languageCode.indexOf(langCode);
        if (targetIndex != -1) {
          String targetLang = editAccountController.languageDropDown[targetIndex];
          String targetCode = editAccountController.languageCode[targetIndex];
          editAccountController.languageDropDown.removeAt(targetIndex);
          editAccountController.languageCode.removeAt(targetIndex);
          editAccountController.languageDropDown.insert(0, targetLang);
          editAccountController.languageCode.insert(0, targetCode);
        }
        editAccountController.preferences.preferredLaunguage= globals.preferredLanguage;
      }
      App()
          .translations
          .readJson(language: langCode, isUpdate: false, isOnlyDownload: isOnlyDownload)
          .then((value) {
        _loadingLanguageCodes.remove(langCode);
        if (!isOnlyDownload && isOneTimeClick.value) {
          Get.back();
        }
        isOneTimeClick.value = false;
      });
      globals.setButtonIdle();
    } else {
      if (isOnlyDownload) {
        _loadingLanguageCodes.add(langCode);
        App().translations.readJson(language: langCode, isUpdate: false, isOnlyDownload: true).then((value) {
          _loadingLanguageCodes.remove(langCode);
          isOneTimeClick.value = false;
        });
        globals.setButtonIdle();
      } else {
        _loadingLanguageCodes.add(langCode);
        editAccountController.updateProfileInfo("preferredLanguage", langCode).then((value) {
          if (value == "timeout") {
            _loadingLanguageCodes.remove(langCode);
            editAccountController.toast.show(
              context: context,
              message: 'session_timeout_err'.tr,
            );
            editAccountController.setLogout();
          } else if (value == "offline") {
            _loadingLanguageCodes.remove(langCode);
            editAccountController.netOffSnackbar(
                () => updateLangCurrency(originalIndex, isOnlyDownload), false);
          } else if (value.isNotEmpty) {
            _loadingLanguageCodes.remove(langCode);
            editAccountController.showInSnackBar(value);
          } else {
            editAccountController.languageController.text = langName;
            globals.preferredLanguage = langCode;
            globals.isRTLLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage);
            int targetIndex = editAccountController.languageCode.indexOf(langCode);
            if (targetIndex != -1) {
              String targetLang = editAccountController.languageDropDown[targetIndex];
              String targetCode = editAccountController.languageCode[targetIndex];
              editAccountController.languageDropDown.removeAt(targetIndex);
              editAccountController.languageCode.removeAt(targetIndex);
              editAccountController.languageDropDown.insert(0, targetLang);
              editAccountController.languageCode.insert(0, targetCode);
            }
            editAccountController.preferences.preferredLaunguage= globals.preferredLanguage;
            debugPrint("update locale");
            App()
                .translations
                .readJson(language: langCode, isUpdate: false, isOnlyDownload: false)
                .then((value) {
              _loadingLanguageCodes.remove(langCode);
              isOneTimeClick.value = false;
              Get.back();
            });
            globals.setButtonIdle();
          }
        });
      }
    }
  }
}