import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/auth_controllers/splash_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/custom_dialog.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart' as lang;
import '../widgets/primary_scaffold.dart';

class DocumentPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DocumentPreviewView();
  }
}

class DocumentPreviewView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DocumentVerifyState();
}

class DocumentVerifyState extends State<DocumentPreviewView>
    with TickerProviderStateMixin {
  int mainFlexSize = 90;


  Uint8List? licenceFront, licenceBack, vehicleRC, vehicleInsurance;
  final SplashController splashController = Get.find();

  Animation<double>? animation;
  AnimationController? controller;

  @override
  void initState() {
    initPref();
    PaintingBinding.instance.imageCache
      ..maximumSize = 1000
      ..maximumSizeBytes = 500 << 20;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(controller!);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: lang.doc_title.tr,
        body: ListView(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  bottom: 20,
                  top: 24.0,
                  right: 24.0,
                ),
                child: Container(
                  child: Text(
                    lang.doc_title.tr,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                )),
            Container(
              height: 50,
              margin:
                  const EdgeInsets.only(bottom: 20.0, right: 24.0, left: 24.0),
              padding: globals.isRtlLang
                  ? EdgeInsetsDirectional.only(end: 20)
                  : EdgeInsetsDirectional.only(start: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              child: new InkWell(
                onTap: () {
                  splashController.checkInternet(() {}, true);
                  Get.dialog(
                    Obx(() {
                      return globals.isAutoThemeUpdated.value != null ? customDialog(
                          title: lang.document_front.tr,
                          image: licenceFront,
                          imgURL: globals.front
                      ) : SizedBox.shrink();
                    }
                  )
                  );
                },
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: mainFlexSize,
                      child: Text(
                        lang.document_front.tr,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 105 - mainFlexSize,
                      child: SvgPicture.asset(
                        checkSvg,
                        width: 15,
                        height: 10,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
              padding:  EdgeInsetsDirectional.only(start: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              child: new InkWell(
                onTap: () {
                  splashController.checkInternet(() {}, true);
                  Get.dialog(
                    Obx(() {
                      return globals.isAutoThemeUpdated.value != null ? customDialog(
                        context: context,
                        title: lang.document_back.tr,
                        image: licenceBack,
                        imgURL: globals.back
                      ) : SizedBox.shrink();
                    })
                  );
                },
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: mainFlexSize,
                      child: Text(
                        lang.document_back.tr,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 105 - mainFlexSize,
                      child: SvgPicture.asset(
                        checkSvg,
                        width: 15,
                        height: 10,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, top: 40.0, right: 24.0, bottom: 20),
                child: Container(
                  child: Text(
                    lang.vehicle_doc.tr,
                    style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimen.text_size_16,
                    ),
                  ),
                )),
            Container(
              height: 50,
              margin: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 20.0,
              ),
              padding:  EdgeInsetsDirectional.only(start: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              child: new InkWell(
                onTap: () {
                  splashController.checkInternet(() {}, true);
                  Get.dialog(
                    Obx(() {
                      return globals.isAutoThemeUpdated.value != null ?
                      customDialog(
                        context: context,
                        title: lang.rc_book.tr,
                        image: vehicleRC,
                        imgURL: globals.RC
                      ) : SizedBox.shrink();
                    })
                  );
                },
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: mainFlexSize,
                      child: Text(
                        lang.rc_book.tr,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 105 - mainFlexSize,
                      child: SvgPicture.asset(
                        checkSvg,
                        width: 15,
                        height: 10,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.only(
                  top: 5.0, bottom: 5.0, right: 24.0, left: 24.0),
              padding:EdgeInsetsDirectional.only(start: 20),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(3))),
              child: new InkWell(
                onTap: () {
                  splashController.checkInternet(() {}, true);
                  Get.dialog(
                    Obx(() {
                      return globals.isAutoThemeUpdated.value != null ?
                      customDialog(
                        context: context,
                        title: lang.insurance.tr,
                        image: vehicleInsurance,
                        imgURL: globals.Insurance
                      ) : SizedBox.shrink();
                    })
                  );
                },
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: mainFlexSize,
                      child: Text(
                        lang.insurance.tr,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontWeight: FontWeight.w500,
                          fontSize: AppDimen.text_size_16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 105 - mainFlexSize,
                      child: SvgPicture.asset(
                        checkSvg,
                        width: 15,
                        height: 10,
                        colorFilter: ColorFilter.mode(
                            AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

      );
    });
  }

  customDialog(
      {BuildContext? context,
      String? title,
      Uint8List? image,
      String? imgURL}) {
    controller?.forward();
    return ChangedDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      backgroundColor: AppColors.COMMON_BG_COLOR,
      elevation: 0.0,
      child: Container(
        padding: const EdgeInsets.only(top: 10.0, left: 10, right: 10.0),
        width: Get.width,
        height: 6 * Get.height / 8,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      title!,
                      style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    controller?.reverse();
                    Get.back();
                  },
                  child: Container(
                    margin: EdgeInsets.all(10),
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          border:
                              Border.all(color: AppColors.ICON_COLOUR, width: 1.5)),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        child: SvgPicture.asset(
                          closeSvg,
                          matchTextDirection: true,
                          colorFilter: ColorFilter.mode(
                              AppColors.ICON_COLOUR, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: image == null || image.isEmpty
                  ? CachedNetworkImage(
                      height: Get.height / 1.6,
                      width: Get.width,
                      fit: BoxFit.contain,
                      imageUrl: imgURL!,
                      imageBuilder: (context, imageProvider) =>
                          InteractiveViewer(
                        panAxis: PanAxis.aligned,
                        panEnabled: false,
                        maxScale: 10.0,
                        minScale: 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            image: DecorationImage(image: imageProvider),
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Container(
                        height: Get.height / 1.6,
                        width: Get.width,
                        child: new Center(
                            child: new CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              AppColors.PRIMARY_COLOR_DARK),
                        )),
                      ),
                    )
                  : FadeTransition(
                      opacity: animation!,
                      child: Container(
                        width: Get.width,
                        height: Get.height / 1.6,
                        child: Image.memory(
                          image,
                        ),
                      )),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initPref() async {
    if(App().appPreference.LicenceFront.isNotEmpty) {
      Uint8List thumbImage = base64.decode(App().appPreference.LicenceFront);
      licenceFront = thumbImage;
    }

    if(App().appPreference.LicenceBack.isNotEmpty) {
      Uint8List thumbImage = base64.decode(App().appPreference.LicenceBack);
      licenceBack = thumbImage;
    }

    if(App().appPreference.vehicleRC.isNotEmpty) {
      Uint8List thumbImage = base64.decode(App().appPreference.vehicleRC);
      vehicleRC = thumbImage;
    }

    if(App().appPreference.vehicleInsurance.isNotEmpty) {
      Uint8List thumbImage = base64.decode(App().appPreference.vehicleInsurance);
      vehicleInsurance = thumbImage;
    }
  }
}