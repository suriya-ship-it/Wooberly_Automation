import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/document_controller.dart';
import 'package:wooberly_driver/controller/auth_controllers/register_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_button.dart';
import 'document_item_view.dart';

class DocumentMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DocumentVerifyStateful();
  }
}

class DocumentVerifyStateful extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DocumentVerifyState();
}

class DocumentVerifyState extends State<DocumentVerifyStateful> {
  final DocumentController controller = Get.find();
 bool firstClick = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    super.initState();
    onReceiveLoginCheck("loginCheck-${globals.userid}");
    onUserPreferenceUpdated();
    controller.getDeviceDetails();

    PaintingBinding.instance.imageCache
      ..maximumSize = 1000
      ..maximumSizeBytes = 500 << 20;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    controller.rxImageRefreshController.stream.listen((data){
      if(data) {
        getDocumentUploadStatus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getDocumentUploadStatus();
      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return   GetBuilder<DocumentController>(
        builder: (val) {
        return Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
              getDocumentUploadStatus();
          return PrimaryScaffold(
            key: _scaffoldKey,
            customAppBarFunction: () {
              var content = exit_app_content.tr;
              var cancel = btn_cancel.tr;
              var exit = exit_app.tr;
              _asyncConfirmDialog(content, cancel, exit);
            },
            actionWidgets: [
              Consumer<ModelTheme>(
                  builder: (context, ModelTheme themeNotifier, child) {
                return InkWell(
                  onTap: () {
                    controller.setLoadingController(true);
                    globals.front = "for logout";
                    controller.userLogout().then((value) {
                      controller.setLoadingController(false);
                      globals.vehicleImagePath='';
                      controller.documentFront = false;
                      controller.documentBack = false;
                      controller.rcBook = false;
                      controller.insurance = false;
                      controller.imageFront = "";
                      controller.imageBack = "";
                      controller.imageRC = "";
                      controller.imageInsu = "";
                      controller.setLogout(scoffoldcontext);
                    });
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
            body: Builder(
              builder: (BuildContext context) {
                scoffoldcontext = context;
                return Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                  child: Stack(
                    children: <Widget>[
                      new ListView(
                        children: <Widget>[
                          Text(
                            please_upload_your_personal_doc.tr,
                            style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontWeight: FontWeight.bold,
                              fontSize: AppDimen.text_size_22,
                            ),
                          ),
                          DocumentView(document_title:
                              document_front.tr),
                          DocumentView(document_title:
                          document_back.tr),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 40.0, bottom: 10.0),
                              child: Container(
                                child: Text(
                                  please_upload_your_vehicle_document.tr,
                                  style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppDimen.text_size_22,
                                  ),
                                ),
                              )),
                          DocumentView(document_title:
                          rc_book.tr),
                          DocumentView(document_title:
                          insurance.tr),
                        ],
                      ),
                      Align(
                          alignment: AlignmentDirectional.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                                child: PrimaryButton(
                              buttonTitle: finish.tr,
                              buttonImage: primaryRightArrow,
                              callback: () {
                                if (controller.documentFront &&
                                    controller.documentBack &&
                                    controller.rcBook &&
                                    controller.insurance) {
                                  if (firstClick) {
                                    PrimaryScaffold.avoidLoader = false;
                                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);

                                    firstClick = false;

                                    Future.delayed(
                                        const Duration(milliseconds: 500), () {
                                      controller.getProfileInfo().then((onValue) {
                                        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                        if (onValue.isNotEmpty) {
                                          if (onValue == "timeout") {
                                            firstClick = true;
                                            App().toast.show(
                                                  context: context,
                                                  message: session_timeout_err.tr,
                                                );
                                            App().appPreference.clearPreference();
                                            Get.offAll(AppRoutes().getWidget(AppRoutes.APP_SPLASH), predicate: (r) => false);
                                          } else {
                                            firstClick = true;
                                            controller.showInSnackBar(onValue);
                                          }
                                        } else {
                                          if (globals.theme.value == 1) {
                                            var brightness =
                                                MediaQuery.of(scoffoldcontext)
                                                    .platformBrightness;
                                            globals.isDarkTheme =
                                                brightness == Brightness.dark;
                                            App().appPreference.preferredTheme = globals.isDarkTheme;
                                            if (globals.isDarkTheme) {
                                              AppColors().changeToDark();
                                            } else {
                                              AppColors().changeToLight();
                                            }
                                          } else if (globals.theme.value == 2) {
                                            globals.isDarkTheme = false;
                                            App().appPreference.preferredTheme = globals.isDarkTheme;
                                            AppColors().changeToLight();
                                          } else {
                                            globals.isDarkTheme = true;
                                            App().appPreference.preferredTheme = globals.isDarkTheme;
                                            AppColors().changeToDark();
                                          }

                                          firstClick = true;
                                          globals.isShowMapPage = true;
                                          globals.vehicleImagePath='';
                                          controller.documentFront = false;
                                          controller.documentBack = false;
                                          controller.rcBook = false;
                                          controller.insurance = false;
                                          controller.imageFront = "";
                                          controller.imageBack = "";  controller.imageRC = "";
                                          controller.imageInsu = "";
                                          if(Platform.isIOS) Permission.camera.request();
                                          Get.offAll(AppRoutes().getWidget(AppRoutes.APP_MAP_MAIN), predicate: (r) => false);
                                        }
                                      });
                                    });
                                  }
                                } else {
                                  firstClick = true;
                                  controller.showInSnackBar(
                                      upload_all_documents.tr);
                                }
                              },
                            )),
                          ))
                    ],
                  ),
                );
              },
            ),
          );
        });
      }
    );
  }

  void getDocumentUploadStatus() {
    debugPrint("appPreference.isDoc: ${App().appPreference.isDoc}");
    if(App().appPreference.isDoc.isNotEmpty) {
      controller.documentFront = true;
      controller.imageFront = App().appPreference.isDoc;
    }

    if(App().appPreference.backPath.isNotEmpty) {
      controller.documentBack = true;
      controller.imageBack = App().appPreference.backPath;
    }

    if(App().appPreference.rcPath.isNotEmpty) {
      controller.rcBook = true;
      controller.imageRC = App().appPreference.rcPath;
    }

    if(App().appPreference.insuPath.isNotEmpty) {
      controller.insurance = true;
      controller.imageInsu = App().appPreference.insuPath;
    }
    controller.rxImageRefreshController.value = false;
  }

  Future<void> _asyncConfirmDialog(String content, String cancel, String exit) async {
    return Get.dialog(
      barrierDismissible: false,
      Obx(
        () {
          return globals.isAutoThemeUpdated.value != null ? AlertDialog(
            backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
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
                    style: TextStyle(fontSize: AppDimen.text_size_16, color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
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
                                border: Border.all(
                                    width: 1,
                                    color: AppColors.PRIMARY_COLOR_DARK)),
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
                            App().closeApp();
                          },
                          child: Container(
                            width: Get.width,
                            height: 50,
                            margin: const EdgeInsetsDirectional.only(start: 10),
                            padding: const EdgeInsetsDirectional.only(
                              start: 20,
                              end: 20,
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
      )
    );
  }

  onReceiveLoginCheck(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          String deviceID = data["data"]["data"]["deviceId"].toString();
          String userType = data["data"]["data"]["userType"].toString();
          if (deviceID != globals.deviceId && userType == "2") {
            controller.setLogout(scoffoldcontext);
            App().toast.show(
                  context: scoffoldcontext,
                  message: session_timeout_err.tr,
                );
          }
        } else if (data["data"]["status"] == 400) {
          String errorMSG = data["data"]["errorMessage"];
          App().removeUserCache(scoffoldcontext);
          App().toast.show(
                context: scoffoldcontext,
                message: errorMSG,
              );
        }
      }
    });
  }

  onUserPreferenceUpdated(){
    globals.socket?.off("userPreferenceUpdated-${globals.userid}");
    globals.socket?.on("userPreferenceUpdated-${globals.userid}", (data) {
      if (data is Map) {
        debugPrint("onUserPreferenceUpdatedMSG: ${data}");
        String? langCode = data["data"]["data"]["preferredLanguage"];
        String? currency = data["data"]["data"]["preferredCurrency"];
        if(langCode !=null) {
          globals.preferredLanguage.value = langCode;
          globals.isRtlLang = intl.Bidi.isRtlLanguage(globals.preferredLanguage.value);
        if(  Get.isRegistered<EditAccountController>()) {
          EditAccountController editAccountController = Get.find();

          int selectedPos = editAccountController.languageCode.indexOf(
              langCode);
          if (selectedPos != -1) {
            String targetLanguage = editAccountController
                .languageDropDown[selectedPos];
            String targetCode = editAccountController.languageCode[selectedPos];

            editAccountController.languageDropDown.removeAt(selectedPos);
            editAccountController.languageCode.removeAt(selectedPos);

            editAccountController.languageDropDown.insert(0, targetLanguage);
            editAccountController.languageCode.insert(0, targetCode);
          }
          debugPrint(
              "editAccountController.languageDropDown: ${editAccountController
                  .languageDropDown}");
          debugPrint(
              "editAccountController.languagecode: ${editAccountController
                  .languageCode}");
          editAccountController.setLanguage();
        }
          App().appPreference.preferredLanguage = globals.preferredLanguage.value;

          App()
              .localizationService
              .readJson(
              language: langCode, isUpdate: false, isDownloadOnly: false)
              .then((value) {
            Get.forceAppUpdate();
            globals.themeNotifier?.isDark = globals.isDarkTheme;
            debugPrint("onUserPreferenceUpdatedMSG:updated");
          });
        }

      }
    });
  }
}