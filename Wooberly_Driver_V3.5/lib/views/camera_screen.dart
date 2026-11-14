import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:image/image.dart' as img;
import '../../app/app.dart';

import '../app/model_theme.dart';
import '../resources/values/app_lang.dart';

class CameraScreen extends StatefulWidget {
  CameraScreen({
    Key? key,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Future<void>? _initializeControllerFuture;
  int selectedCamera = 0;
  var rxCameraPermissionUpdateController =
      ReactiveVariable("rxCameraPermissionUpdateController", true);
  var rxCameraViewChangeController =
      ReactiveVariable("rxCameraViewChangeController", false);

  @override
  void initState() {
    if (globals.cameraController != null)
      selectedCamera = globals.cameraController!.cameraId;

    Permission.camera.request().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        initializeCamera(selectedCamera);
      } else {
        globals.baseController
            .change(rxVariable: rxCameraViewChangeController, value: false);
        globals.baseController.change(
            rxVariable: rxCameraPermissionUpdateController, value: false);
      }
    });

    globals.appLifecycleController.addListener(() {
      String msg = globals.appLifecycleController.value;
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        if (msg == "AppLifecycleState.resumed") {
          Permission.camera.status.isGranted.then((isGranted) {
            if (isGranted) {
              initializeCamera(selectedCamera);
            } else {
              globals.baseController.change(
                  rxVariable: rxCameraPermissionUpdateController, value: false);
              globals.baseController.change(
                  rxVariable: rxCameraViewChangeController, value: false);
            }
          });
        }
      }
    });

    super.initState();
  }

  initializeCamera(int cameraIndex) async {
    if (globals.cameraController == null) {
      await App().initializeCamera(cameraId: cameraIndex);
      _initializeControllerFuture =
          Future.delayed(const Duration(milliseconds: 250));
    } else
      _initializeControllerFuture =
          Future.delayed(const Duration(milliseconds: 10));
    globals.baseController
        .change(rxVariable: rxCameraPermissionUpdateController, value: true);
    globals.baseController
        .change(rxVariable: rxCameraViewChangeController, value: true);
  }

  @override
  void dispose() {
    Future.delayed(Duration(seconds: 2), () {
      globals.baseController.change(rxVariable: rxCameraPermissionUpdateController, value: false);
      globals.baseController.change(rxVariable: rxCameraViewChangeController, value: false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = Get.size;
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.black,
            body: GetBuilder<BaseController>(
                init: globals.baseController,
                id: rxCameraPermissionUpdateController.id,
                builder: (val) {
                  return Stack(
                    children: [
                      SizedBox(
                        width: mediaSize.width,
                        child: rxCameraPermissionUpdateController.value == true
                            ? FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Transform.scale(
                                scale: ((1 /
                                    (globals.cameraController!.value
                                        .aspectRatio *
                                        mediaSize.aspectRatio)) -
                                    0.1),
                                alignment: Alignment.center,
                                child: CameraPreview(
                                    globals.cameraController!),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        )
                            : Container(
                          alignment: Alignment.center,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 15.0),
                          color: AppColors.COMMON_BG_COLOR,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                  '${Please_enable_the_permission_from_the
                                      .tr} ',
                                  style: TextStyle(color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                ),
                                TextSpan(
                                    text: '${setting.tr}.',
                                    style: TextStyle(
                                      color: AppColors.TEXT_LINK_COLOR,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        cameraPermissionDialog();
                                      }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _showImage(),
                      rxCameraPermissionUpdateController.value == true
                          ? Container(
                        width: mediaSize.width,
                        height: mediaSize.height,
                        alignment: AlignmentDirectional.bottomEnd,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GetBuilder<BaseController>(
                                init: globals.baseController,
                                id: rxCameraViewChangeController.id,
                                builder: (val) {
                                  return rxCameraViewChangeController
                                      .value ==
                                      true
                                      ? IconButton(
                                    onPressed: () async {
                                      if (App().cameras.length > 1) {
                                        selectedCamera =
                                        selectedCamera == 0
                                            ? 1
                                            : 0;
                                        await App().initializeCamera(
                                            cameraId: selectedCamera);
                                        initializeCamera(
                                            selectedCamera);
                                      } else {
                                        Get.showSnackbar(GetSnackBar(
                                          backgroundColor: Colors.black,
                                          messageText: Text(
                                              'No secondary camera found',style: TextStyle(
                                            color: Colors.white,
                                          ),),
                                          duration: const Duration(
                                              seconds: 2),
                                        ));
                                      }
                                    },
                                    icon: Icon(
                                        Icons.switch_camera_rounded,
                                        color: Colors.white),
                                  )
                                      : SizedBox(
                                    height: 60,
                                    width: 60,
                                  );
                                }),
                            GestureDetector(
                              onTap: () async {
                                await _initializeControllerFuture;
                                var xFile = await globals.cameraController
                                    ?.takePicture();
                                if (globals.cameraController?.description
                                    .lensDirection ==
                                    CameraLensDirection.front) {
                                  final flippedFile = await flipImageHorizontally(
                                      File(xFile!.path));
                                  globals.cameraFilePath = flippedFile.path;
                                } else {
                                  globals.cameraFilePath = xFile?.path;
                                }
                                Get.back(result: true);
                              },
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60,
                              width: 60,
                            ),
                          ],
                        ),
                      )
                          : SizedBox.shrink(),
                    ],
                  );
                })),
      );
    });
  }

  _showImage() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24.0, top: 22.0),
      child: InkWell(
        onTap: () {
          Get.back(result: false);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
          child: SizedBox(
            width: 12,
            height: 21,
            child: RotatedBox(
              quarterTurns: globals.isRtlLang ? 2 : 0,
              child: SvgPicture.asset(
                primaryLeftArrow,
                fit: BoxFit.scaleDown,
                colorFilter:
                    ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> cameraPermissionDialog() async {
    return Get.dialog(barrierDismissible: false, Obx(() {
      return globals.isAutoThemeUpdated.value != null
          ? AlertDialog(
              backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              content: Text(
                need_to_enable_the_permission.trParams({"field": camera.tr}),
                style:
                    TextStyle(color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(cancel.tr),
                  onPressed: () {
                    Get.back();
                  },
                ),
                TextButton(
                  child: Text(go_to_setting.tr),
                  onPressed: () {
                    Get.key.currentState!.canPop() ? Get.back() : null;
                   openAppSettings();
                  },
                )
              ],
            )
          : SizedBox.shrink();
    }));
  }

  Future<File> flipImageHorizontally(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return file;

    img.Image flipped = img.flipHorizontal(original);

    final flippedBytes = img.encodeJpg(flipped);
    final flippedFile = await file.writeAsBytes(flippedBytes, flush: true);
    return flippedFile;
  }
}