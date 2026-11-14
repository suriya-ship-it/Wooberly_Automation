import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/widgets/primary_appbar.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/tooltip_info_widget.dart';

import '../../app/app.dart';
import '../../utils/globals.dart' as globals;
import '../../controllers/base_controller.dart';

TextEditingController AILangTextEditController = TextEditingController();

class AILangSelectionWidget extends StatelessWidget {
  final String title;
  final String tooltipcontent;
  final bool isShowIcon;

  AILangSelectionWidget(
      {Key? key,
      required this.title,
      required this.tooltipcontent,
      required this.isShowIcon,
      bool? isshowBorder})
      : super(key: key);
  String? slectedAILangCode;
  final DraggableScrollableController _dragController = DraggableScrollableController();
  ScrollController listScrollController = ScrollController();
  RxBool isReachMaxSize = false.obs;

  draggableSheetScrollListener() {
    isReachMaxSize.value = (_dragController.size == 1);
    debugPrint("draggableSheetScrollListener: ${isReachMaxSize.value}");
  }

  @override
  Widget build(BuildContext context) {
    _dragController.removeListener(draggableSheetScrollListener);
    _dragController.addListener(draggableSheetScrollListener);
    listScrollController.addListener(() {
      if (listScrollController.position.pixels <= listScrollController.position.maxScrollExtent) {
        if (listScrollController.position.atEdge) {
          globals.baseController.AILangListCurrentPage = globals.baseController.AILangListCurrentPage + 1;
          debugPrint(
              "current page isailang: ${globals.baseController.AILangListCurrentPage} --- ${globals.baseController.AILanglistCount}");
          if (globals.baseController.AILanglistCount > globals.baseController.AILanglist.length)
            globals.baseController.getAILanguageList();
        }
      }
    });
    return !isShowIcon
        ? Visibility(
            visible: globals.isVoiceChatEnable,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TooltipInfoWidget(title: title, tooltipcontent: tooltipcontent),
                const SizedBox(height: 15.0),
                InkWell(
                  onTap: () {
                    showAILangSelectionBottomSheet(context);
                  },
                  child: Container(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Obx(
                            () {
                              globals.baseController.AILanglist.value;
                              return TextField(
                                enableIMEPersonalizedLearning: false,
                                decoration: new InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'lang_hint'.tr,
                                    hintStyle: TextStyle(
                                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                      fontWeight: FontWeight.w300,
                                      fontSize: AppDimen.text_size_18,
                                    ),
                                    hoverColor: AppColors.BLACK_TEXT_COLOR),
                                controller: getLangController(),
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_18,
                                ),
                                enabled: false,
                              );
                            }
                            ),
                          flex: 95,
                        ),
                        SvgPicture.asset(
                          primaryDownArrow,
                          width: 7.0,
                          height: 8.0,
                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : InkWell(
            onTap: () {
              if (globals.baseController.AILanglist.isEmpty) {
                globals.baseController.getAILanguageList();
              } else {
                MapMainController mapMainController = Get.find();
                if (!mapMainController.isRecording.value) showAILangSelectionBottomSheet(context);
              }
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 20),
              child: SvgPicture.asset(
                appLangSvg,
                height: 20.0,
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
              ),
            ));
  }

  showAILangSelectionBottomSheet(BuildContext context, {bool? isDismissable}) {
    Get.closeCurrentSnackbar();
    debugPrint("AILanglist: ${globals.baseController.AILanglist} --- ${globals.aiPreferredLanguage}");
    List<Map<String, String>> AILanglist = List.from(globals.baseController.AILanglist);
    if (globals.aiPreferredLanguage.isNotEmpty) {
      int selectedIndex =
          AILanglist.indexWhere((element) => element['languageCode'] == globals.aiPreferredLanguage);
      AILanglist.removeAt(selectedIndex);
      AILanglist.insert(0, globals.baseController.AILanglist[selectedIndex]);
    }

    _settingModalBottomSheet(
        context,
        'lang_hint'.tr,
        title: title,
        isDismissible: isDismissable,
        AILanglist: AILanglist,
        MediaQuery.of(context).size.height * 0.45);
  }

  TextEditingController getLangController() {
    if (globals.aiPreferredLanguage.isNotEmpty) {
      String selectedLangName = "";
      for (int i = 0; i < globals.baseController.AILanglist.length; i++) {
        if (globals.aiPreferredLanguage == globals.baseController.AILanglist[i]['languageCode']) {
          selectedLangName = globals.baseController.AILanglist[i]['language'] ?? "";
          break;
        }
      }
      AILangTextEditController.text = selectedLangName.isNotEmpty ? selectedLangName : 'label_select'.tr;
    } else {
      AILangTextEditController.text = 'label_select'.tr;
    }
    return AILangTextEditController;
  }

  void _settingModalBottomSheet(mcontext, String option, double value,
      {String? title, bool? isDismissible, required List<Map<String, String>> AILanglist}) {
    debugPrint(":AILanglist.length: ${AILanglist}");
    final int itemCount = AILanglist.length;

    double reducingHeight = 0.0;
    if (itemCount < 3) reducingHeight = 0.1;
    const double itemHeight = 65.0;
    const double headerHeight = 150.0;
    final double screenHeight = MediaQuery.of(mcontext).size.height;

    final double contentHeight = (itemCount * itemHeight) + headerHeight;

    double calculatedSize = contentHeight / screenHeight;

    double dynamicMaxChildSize = calculatedSize.clamp(0.5 - reducingHeight, 1); // Clamp between 30% and 90%

    showModalBottomSheet(
      context: mcontext,
      isDismissible: isDismissible ?? true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: const Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          bottom: Platform.isAndroid,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5 - reducingHeight,
            minChildSize: 0.3,
            controller: _dragController,
            maxChildSize: dynamicMaxChildSize,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              if (_dragController.isAttached)
                debugPrint("scrollController.size: ${scrollController.position}");
              return ColoredBox(
                color: AppColors.PRIMARY_LIGHT_COLOR,
                child: Obx(
                  () => AnimatedPadding(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(top: isReachMaxSize.value ? 20.0 : 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PreferredSize(
                          preferredSize: const Size.fromHeight(75),
                          child: PrimaryAppBar(
                            BGColor: AppColors.PRIMARY_LIGHT_COLOR,
                            pageTitle: 'label_user_preferred_lang'.tr,
                            backImage: primaryLeftArrow,
                            callback: () {
                              Get.back();
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: new Divider(
                            color: AppColors.DIVIDER_COLOR,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: AILanglist.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return ColoredBox(
                                color: AppColors.PRIMARY_LIGHT_COLOR,
                                child: new Wrap(
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: <Widget>[
                                        InkWell(
                                          onTap: () {
                                            Get.back();
                                            slectedAILangCode = AILanglist[index]['languageCode'];
                                            globals.baseController.checkInternet(updateAILang, false);
                                          },
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  alignment: AlignmentDirectional.centerStart,
                                                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                                                  child: Text(
                                                    '${AILanglist[index]['languageCode'].toString().toUpperCase()} - ${AILanglist[index]['language']}',
                                                    textDirection: TextDirection.ltr,
                                                    style: TextStyle(
                                                      color: AppColors.BLACK_TEXT_COLOR,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: AppDimen.text_size_18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (index == 0 && globals.aiPreferredLanguage.isNotEmpty)
                                                SvgPicture.asset(
                                                  updatedVerified,
                                                  width: 23.0,
                                                  height: 23.0,
                                                  colorFilter: ColorFilter.mode(
                                                      AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                ),
                                            ],
                                          ),
                                        ),
                                        new Divider(
                                          color: AppColors.DIVIDER_COLOR,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((value) {
      debugPrint("close sheet: ${isDismissible}");
      if (isDismissible ?? false) {
        Get.back();
      }
    });
  }

  updateAILang() {
    globals.baseController.updateAILanguage("aiPreferredLanguage", slectedAILangCode!).then((value) {
      debugPrint("updateAILang: ${value} --- ${slectedAILangCode}");
      if (value.isEmpty) {
        globals.aiPreferredLanguage = slectedAILangCode!;
        globals.baseController.AILanglist.refresh();
      }
    });
  }
}

class VoiceChatBottomSheet {
  VoiceChatBottomSheet({required Function NavigateFunction}) {
    debugPrint("globals.aiPreferredLanguage: ${globals.aiPreferredLanguage}");
    if (globals.aiPreferredLanguage.isNotEmpty || !globals.isVoiceTranslatorEnable) {
      NavigateFunction();
      return;
    } else {
      globals.baseController.getAILanguageList();
    }
    App().showBottomSheet(Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return ColoredBox(
        color: AppColors.COMMON_BG_COLOR,
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                aiAnimationsSvg,
                height: 50,
              ),
              const SizedBox(height: 18),
              Text('label_voice_to_text_chat'.tr,
                  style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimen.text_size_20,
                  )),
              const SizedBox(height: 6),
              Text(
                "label_voice_to_text_chat_description".tr,
                style: TextStyle(
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontWeight: FontWeight.w400,
                  fontSize: AppDimen.text_size_14,
                ),
              ),
              const SizedBox(height: 18),
              AILangSelectionWidget(
                  title: "label_user_preferred_lang".tr,
                  tooltipcontent: "label_tooltip_chat_lang_unselected".tr,
                  isShowIcon: false),
              const SizedBox(height: 18),
              PrimaryButton(
                buttonTitle: 'label_btn_continue'.tr,
                buttonImage: primaryBtnArrow,
                callback: () {
                  if (globals.aiPreferredLanguage.isNotEmpty) {
                    Get.back();
                    NavigateFunction();
                  } else {
                    globals.baseController
                        .showInSnackBar('label_select_your_preferred_language_to_continue'.tr);
                  }
                },
              )
            ],
          ),
        )),
      );
    }), AppColors.COMMON_BG_COLOR, true);
  }
}