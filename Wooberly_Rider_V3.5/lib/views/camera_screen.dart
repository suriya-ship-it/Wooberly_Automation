import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';

import '../../app/app.dart';

class CameraScreen extends StatefulWidget {
  CameraScreen({
    Key? key,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  BaseController baseController = Get.find();
  Future<void>? _initializeControllerFuture;
  int selectedCamera = 0;
  var cameraPermissionUpdateController = true.obs;
  var cameraViewChangeController = false.obs;

  @override
  void initState() {
    Permission.camera.request().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        initializeCamera(selectedCamera);
      } else {
        cameraViewChangeController(false);
        cameraPermissionUpdateController(false);
      }
    });
    AppLifecycleListener(
      onResume: () async {
          if (await Permission.camera.isGranted) {
            initializeCamera(selectedCamera);
          } else {
            cameraViewChangeController(false);
            cameraPermissionUpdateController(false);
          }
      }
    );
    super.initState();
  }

  initializeCamera(int cameraIndex) async {
    availableCameras().then((value) {
      App().cameras = value;
      _controller = CameraController(App().cameras[cameraIndex], ResolutionPreset.medium, enableAudio: false);
      _initializeControllerFuture = _controller?.initialize();
      cameraPermissionUpdateController(true);
      cameraPermissionUpdateController.refresh();
      cameraViewChangeController(true);
      cameraViewChangeController.refresh();
    });
  }

  @override
  void dispose() {
    cameraPermissionUpdateController.close();
    cameraViewChangeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body:  Obx(() {
          return Stack(
          children: [
            SizedBox(
              width: mediaSize.width,
              child:
                 cameraPermissionUpdateController.value == true
                    ? FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return Transform.scale(
                                scale: ((1 / (_controller!.value.aspectRatio * mediaSize.aspectRatio)) - 0.1),
                                alignment: Alignment.center,
                                child: CameraPreview(_controller!));
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      )
                    : Container(
                   color: AppColors.COMMON_BG_COLOR,
                        alignment: Alignment.center,
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${'Please_enable_the_permission_from_the'.tr} ',
                                style: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
                              ),
                              TextSpan(
                                  text: '${'settings'.tr}.',
                                  style: TextStyle(
                                    color: AppColors.PROMOCODE_LINK_COLOR,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      cameraPermissionDialog(context);
                                    }),
                            ],
                          ),
                        ),
                      )
            ),
            backArrow(),
            cameraPermissionUpdateController.value == true?
            Obx(() {
              return Container(
                width: mediaSize.width,
                height: mediaSize.height,
                alignment: AlignmentDirectional.bottomEnd,
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    cameraViewChangeController.value == true
                        ? IconButton(
                            onPressed: () {
                              if (App().cameras.length > 1) {
                                selectedCamera = selectedCamera == 0 ? 1 : 0;
                                initializeCamera(selectedCamera);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('no_secondary_camera_found'.tr),
                                  duration: const Duration(seconds: 2),
                                ));
                              }
                            },
                            icon: Icon(Icons.switch_camera_rounded, color: Colors.white),
                          )
                        : SizedBox(
                            height: 60,
                            width: 60,
                          ),
                    GestureDetector(
                      onTap: () async {
                        await _initializeControllerFuture;
                        var xFile = await _controller!.takePicture();
                        if (_controller!.description.lensDirection == CameraLensDirection.front) {
                          final flippedFile = await flipImageHorizontally(File(xFile.path));
                          xFile = XFile(flippedFile.path);
                        }

                        Get.back(result: xFile?.path);
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
              );
            }): SizedBox.shrink(),
          ],
        );}),
      ),
    );
  }

  backArrow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24.0, top: 22.0),
      child: InkWell(
          onTap: () {
            Get.back();
            _controller?.dispose();
          },
          child: baseController.getBackIcon()),
    );
  }

  Future<void> cameraPermissionDialog(BuildContext context) async {
    return baseController.showGetDialog(AlertDialog(
      backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
      content: Text('need_to_enable_the_permission'.trParams({'field': 'camera'.tr})),
      actions: <Widget>[
        TextButton(
          child: Text('cancel_label'.tr),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Text('Go_to_settings'.tr),
          onPressed: () {
            Get.back();
            openAppSettings();
          },
        )
      ],
    ));
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