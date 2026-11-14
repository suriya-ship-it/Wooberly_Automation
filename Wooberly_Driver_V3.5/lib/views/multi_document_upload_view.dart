import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:wooberly_driver/controller/auth_controllers/document_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/edit_account_controller.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import 'camera_screen.dart';

class MultiDocumentUpload extends StatelessWidget {
  const MultiDocumentUpload({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiDocumentUploadView();
  }
}
class MultiDocumentUploadView extends StatefulWidget {
  const MultiDocumentUploadView({Key? key}) : super(key: key);

  @override
  State<MultiDocumentUploadView> createState() => _MultiDocumentUploadViewState();
}

class _MultiDocumentUploadViewState extends State<MultiDocumentUploadView>  {
  File? _image;
  final DocumentController _controller = Get.find();
  List<Permission> _Permission = [
    Permission.storage,
    Permission.camera
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool netConnect = true;
  bool isFromVehicleDetails=false;
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 400), () {
        _initializeCamera();
      });
    });
    _controller.setLoadingController(false);

    onReceiveLoginCheck("loginCheck-${globals.userid}");
    requestPermission(_Permission);
    PaintingBinding.instance.imageCache
      ..maximumSize = 1000
      ..maximumSizeBytes = 500 << 20;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  _initializeCamera() async{
    await  Permission.camera.request();
    Permission.camera.status.isGranted.then((isGranted) {
      if (isGranted) {
        if (globals.cameraController == null)
          App().initializeCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(ModalRoute.of(context)!.settings.arguments!=null)
    isFromVehicleDetails=ModalRoute.of(context)!.settings.arguments! as bool;
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child){
      return  PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop,onPopInvokedWithResult) {
          if(!didPop) {
            _goBack(context);
          }
        },
        child: PrimaryScaffold(
          key: _scaffoldKey,
          customAppBarFunction: (){
            _goBack(context);
          },
          body: Builder(
            builder: (BuildContext context) {
              scoffoldcontext = context;
              return Stack(
                children: <Widget>[
                  ListView(
                    padding:
                    const EdgeInsets.only(top: 30.0, left: 24.0, right: 24.0),
                    children: <Widget>[
                      Text(isFromVehicleDetails?take_vehicle_photo.tr:
                      take_a_photo.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_22,
                            fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 7.0),
                        child: Text(
                          visible.tr,
                          style: TextStyle(
                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                              fontSize: AppDimen.text_size_14,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      GetBuilder(
                          init: _controller,
                          id: _controller.rxLoadingController.id,
                          builder: (val) {
                            return (_controller.rxLoadingController.value == true)
                                ? const SizedBox.shrink() : Container(
                                height: 280,
                                width: 200,
                                decoration: BoxDecoration(
                                    color: ((_controller.selectedImage != null &&
                                        _controller.selectedImage.isNotEmpty) &&
                                        netConnect) ? Colors.transparent : AppColors.PRIMARY_COLOR_WHITE ,
                                    borderRadius: BorderRadius.all(Radius.circular(6))
                                ),
                                margin: const EdgeInsetsDirectional.all(50.0),
                                child: InkWell(
                                  onTap: (){
                                    if  (!(_controller.selectedImage != null &&
                                        _controller.selectedImage.isNotEmpty) && netConnect)
                                      _settingModalBottomSheet();
                                  },
                                  child: Stack(
                                    children: [
                                      ((_controller.selectedImage != null &&
                                          _controller.selectedImage.isNotEmpty) &&
                                          netConnect) ? Align(
                                          alignment: AlignmentDirectional.center,
                                          child: setImage()
                                      ):
                                      Align(
                                        alignment: AlignmentDirectional.center,
                                        child: Container(
                                          height: 60,width: 60,
                                          padding: const EdgeInsets.all(17),
                                          decoration: BoxDecoration(
                                              color: AppColors.PRIMARY_COLOR_DARK,
                                              borderRadius: BorderRadius.all(Radius.circular(50))
                                          ),
                                          child: SvgPicture.asset(
                                            addSvg,
                                            colorFilter: ColorFilter.mode(AppColors.WHITE_ICON_COLOR, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                            );
                          }),
                      GetBuilder(
                          init: _controller,
                          id: _controller.rxButtonController.id,
                          builder: (val) {
                            return getSaveButton(context);
                          })
                    ],
                  ),
                  GetBuilder(
                      init: _controller,
                      id: _controller.rxLoadingController.id,
                      builder: (val) {
                        return (_controller.rxLoadingController.value == true)
                            ? _controller.getProgressIndicator(
                            context, Colors.transparent)
                            : const SizedBox.shrink();
                      })
                ],
              );
            },
          ),
        ),
      );
    });
  }

  Widget setImage() {
    String img =_controller.selectedImage;
    if (img != null && img.compareTo("") != 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: CachedNetworkImage(
          imageUrl:img,
          placeholder: (context, url) =>
          (img.compareTo("") != 0)
              ? _controller.getProgressIndicator(scoffoldcontext, AppColors.PRIMARY_COLOR_WHITE)
              : const SizedBox.shrink(),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

   _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Get.back();
    } else {
      Get.off(AppRoutes().getWidget(AppRoutes.APP_DOCUMENT_MAIN));
    }
  }

  Widget getSaveButton(BuildContext ctx) {
    return (_controller.selectedImage == null ||
        _controller.selectedImage.compareTo("") == 0)
        ? const SizedBox.shrink()
        : Padding(
        padding: const EdgeInsets.only(left: 40.0, right: 40.0,top: 5),
        child: GetBuilder(
            init: _controller,
            id: _controller.rxLoadingController.id,
            builder: (val) {
              return (_controller.rxLoadingController.value == true) ? const SizedBox.shrink()
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () {
                        _settingModalBottomSheet();
                      },
                      child: Container(
                        height: 55,width: 55,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_DARK,
                            borderRadius: BorderRadius.all(Radius.circular(50))
                        ),
                        child: SvgPicture.asset(
                          editSvg,
                          width: 23,
                          height: 23,
                         colorFilter: ColorFilter.mode(AppColors.WHITE_ICON_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () {
                        _goBack(context);
                      },
                      child: Container(
                        height: 55,width: 55,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_DARK,
                            borderRadius: BorderRadius.all(Radius.circular(50))
                        ),
                        child: SvgPicture.asset(
                          checkSvg,
                         colorFilter: ColorFilter.mode(AppColors.WHITE_ICON_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
        ));
  }

  Future getImage(bool value) async {
    if (value) {
      String imagepath;
      globals.cameraFilePath = null;
        bool cameraimage = await Get.to(CameraScreen());
        if ( globals.cameraFilePath != null && cameraimage) {
          imagepath =  globals.cameraFilePath;
            _image = File(imagepath);
          _controller.checkInternet(uploadSelectedDocument, false)
                .then((value) {
              if (!value) {
                  netConnect = false;
              }
            });

        }
    } else {
      PlatformFile? result = await FilePicker.pickFile(
        type: FileType.image,
      );
        _image = File(result!.path!);
      _controller.checkInternet(uploadSelectedDocument, false)
            .then((value) {
          if (!value) {
              netConnect = false;
          }
        });
    }
  }

  Future<void> requestPermission(List<Permission> permission) async {
    await permission.request();
  }

  void _settingModalBottomSheet() {
    Get.bottomSheet(
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
          return SafeArea(
            bottom: Platform.isAndroid,
            child: ColoredBox(
              color: AppColors.PRIMARY_COLOR_WHITE,
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.add_a_photo,color: AppColors.PRIMARY_COLOR_DARK),
                      title: Text(camera.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16
                        ),
                      ),
                      onTap: () => {
                        Get.back(),
                        getImage(true),
                      }),
                  new ListTile(
                      leading: new Icon(Icons.camera,color: AppColors.PRIMARY_COLOR_DARK),
                      title: new Text(gallery.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            fontSize: AppDimen.text_size_16
                        ),
                      ),
                      onTap: () => {
                        Get.back(),
                        getImage(false),
                      }),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  uploadSelectedDocument() {
    netConnect = true;
    _controller
        .uploadMultipart(
        _image!, "", "")
        .then((value) {
      if (value!.isNotEmpty) {
        if (value!.compareTo("Offline") == 0) {
            netConnect = false;
            _controller.checkInternet(uploadSelectedDocument, false);
        } else {
            netConnect = false;
            _image = null;
          if(value.toString().contains("database")){
            _controller.setLogout(scoffoldcontext);
          }
            _controller.showInSnackBar( value);
        }
      }
    });
  }

  onReceiveLoginCheck(String eventName) {
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          String deviceID = data["data"]["data"]["deviceId"].toString();
          String userType = data["data"]["data"]["userType"].toString();
          if (deviceID != globals.deviceId && userType == "2") {
            _controller.setLogout(scoffoldcontext);
            App().toast.show(
              context: scoffoldcontext,
              message: session_timeout_err.tr,
            );
          }
        }else if(data["data"]["status"] == 400){
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
              String targetCode = editAccountController
                  .languageCode[selectedPos];

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
  @override
  void dispose() {
    super.dispose();
    globals.cameraController?.dispose().then((_){
      globals.cameraController = null;
    });
  }
}