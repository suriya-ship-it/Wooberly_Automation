import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/binding/home_binding.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/static_page.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../controller/base_controller.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../views/settings.dart';
import 'drawer_navigation_item.dart';

class MapMainDrawer extends StatelessWidget {
  DrawerCallback callback;
  BuildContext builderctx;

  MapMainDrawer(
      {required this.callback,
      required this.builderctx});

  @override
  Widget build(BuildContext context) {
    debugPrint("Auth--> ${globals.authToken}");
    return MapMainDrawerState(
      callback: callback,
      builderctx: builderctx,
    );
  }
}

class MapMainDrawerState extends StatefulWidget {
  DrawerCallback callback;
  BuildContext builderctx;

  MapMainDrawerState(
      {required this.callback,
      required this.builderctx});

  @override
  _MapMainDrawerState createState() =>
      _MapMainDrawerState(callback);
}

class _MapMainDrawerState extends State<MapMainDrawerState> {
  DrawerCallback callback;
  final MapMainController controller = Get.find();
  String _categroyImage = "";
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  _MapMainDrawerState(this.callback);

  @override
  void initState() {
    widget.callback(true);
    super.initState();
  }

  @override
  void dispose() {
    widget.callback(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      color: AppColors.COMMON_BG_COLOR,
      child: PrimaryScaffold(
        onChanged: (map) {
          scaffoldKey = map["scaffoldkey"];
        },
        body: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            InkWell(
              onTap: () {
                App().setNavigation(AppRoutes.APP_ROUTE_EDIT_ACC);
              },
              child: GetBuilder<BaseController>(
                  init: globals.baseController,
                  id: globals.rxLoadingController.id,
                  builder: (val) {
                    final String name =
                        "${intl.toBeginningOfSentenceCase(globals.firstname.trim())}" +
                            " " +
                            "${intl.toBeginningOfSentenceCase(globals.lastname.trim())}";
                    final TextStyle nameTextStyle = TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimen.text_size_20,
                    );
                    final Size txtSize = _getTextSize(name, nameTextStyle);
                    return Column(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            SizedBox(
                              width: 80.0,
                              height: 80.0,
                              child: globals.picture != null
                                  ? globals.uploadedImage == null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(100.0),
                                          child: globals.picture != null &&
                                                  globals.picture.isNotEmpty
                                              ? CachedNetworkImage(
                                                  height: 80.0,
                                                  width: 80.0,
                                                  fit: BoxFit.cover,
                                                  imageUrl: globals.picture,
                                                  placeholder: (context, url) =>
                                                      SvgPicture.asset(
                                                    defaultProfileSvg,
                                                    height: 80.0,
                                                    width: 80.0,
                                                  ),
                                                )
                                              : SvgPicture.asset(
                                                  defaultProfileSvg,
                                                  height: 80.0,
                                                  width: 80.0,
                                                ),
                                        )
                                      : new ClipOval(
                                          child: Image.memory(
                                          globals.uploadedImage,
                                          fit: BoxFit.cover,
                                        ),
                              )
                                  : SvgPicture.asset(
                                      defaultProfileSvg,
                                      height: 80.0,
                                      width: 80.0,
                                    ),
                            ),
                          ],
                        ),
                        Container(
                          width: (txtSize.width >
                                  (Get.width - 50)
                              ? Get.width - 50
                              : txtSize.width + 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 1.0,
                                  color: AppColors.PRIMARY_COLOR_DARK),
                            ),
                          ),
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: nameTextStyle),
                        ),
                      ],
                    );
                  }),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: Get.width,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        globals.isShowMapPage = false;
                        App().setNavigation(AppRoutes.APP_EARNINGS);
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_WHITE,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0),
                                ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            SvgPicture.asset(
                              drawerEarningSvg,
                              width: 25.0,
                              height: 25.0,
                              colorFilter: ColorFilter.mode(
                                  AppColors.ICON_COLOUR, BlendMode.srcIn),
                            ),
                            const  SizedBox(height: 10),
                            Text(
                              earnings.tr,
                              style: TextStyle(
                                  fontSize: AppDimen.text_size_16,
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500),
                            ),
                            const  SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        globals.isShowMapPage = false;
                        App().setNavigation(AppRoutes.APP_TRIPS);
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_WHITE,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0),
                                ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            SvgPicture.asset(
                              drawerTripsSvg,
                              width: 25.0,
                              height: 25.0,
                              colorFilter: ColorFilter.mode(
                                  AppColors.ICON_COLOUR, BlendMode.srcIn),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              drawer_trips.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: AppDimen.text_size_16,
                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Divider(
                color: AppColors.DIVIDER_COLOR,
                thickness: 1,
              ),
            ),
            DrawerNavigationItem(
              drawerIcon: drawerDocsSvg,
              navigationName: "${documents.tr}",
              onTap: () {
                globals.isShowMapPage = false;
                App().setNavigation(AppRoutes.APP_DOCUMENT_PREVIEW);
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerVehicleDetailSvg,
              navigationName:
                  "${vehicle_details.tr}",
              onTap: () {
                globals.isShowMapPage = false;
                _categroyImage = globals.vehicleImage;
                App()
                    .setNavigation(AppRoutes.APP_VEHICLE_PREVIEW)
                    .then((value) {
                  if (_categroyImage != globals.vehicleImage)
                    controller.setMarkerprocess();
                });
              },
            ),
            ValueListenableBuilder<Map<String,dynamic>>(
                valueListenable: globals.driverWalletOptionController,
                builder: (context, position, child) {
                  Map<String,dynamic> walletoption = globals.driverWalletOptionController.value;
                  debugPrint("walletoption: ${walletoption}");
                  if(walletoption["driverWalletOption"] == "1" ){
                    return DrawerNavigationItem(
                      drawerIcon: drawerWalletSvg,
                      navigationName: '${ wallet.tr}: ',
                      walletAmount: '${double.parse(walletoption["walletBalance"].toString()).toStringAsFixed(2)}',
                      onTap: () {
                        globals.isShowMapPage = false;
                        App().setNavigation(AppRoutes.APP_DRIVER_WALLET);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }
            ),
        ValueListenableBuilder<Map<String,dynamic>>(
            valueListenable: globals.driverWalletOptionController,
            builder: (context, position, child) {
              Map<String,dynamic> walletoption = globals.driverWalletOptionController.value;
              debugPrint("walletoption: ${walletoption}");
              if(walletoption["driverWalletOption"] == "1" && walletoption["walletFlow"] == "allPaymentMethods"){
                return const SizedBox.shrink();
              }
                return DrawerNavigationItem(
                  drawerIcon: drawer_payoutSvg,
                  navigationName:  payout.tr,
                  onTap: () {
                    globals.isShowMapPage = false;
                    App().setNavigation(AppRoutes.APP_PAYOUT_DISPLAY);
                  },
                );
              }
            ),
            DrawerNavigationItem(
              drawerIcon: drawerCurrLangSvg,
              navigationName:
                  "${currency_languages.tr}",
              onTap: () {
                globals.isShowMapPage = false;
                App().setNavigation(AppRoutes.APP_CURRENCY_LANGUAGE);
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerManageAccSvg,
              navigationName:
                  "${manage_your_account.tr}",
              onTap: () {
                App().setNavigation(AppRoutes.DELETE_ACCOUNT);
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerSettingsSvg,
              navigationName: setting.tr,
              onTap: () {
                App().setNavigation(AppRoutes.APP_SETTINGS);
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerSupportSvg,
              navigationName: "${support_label.tr}",
              onTap: () {
                globals.isShowMapPage = false;
                App().setNavigation(AppRoutes.APP_HELP_INFO);
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerPrivacyPolicySvg,
              navigationName: "${privacy_policy.tr}",
              onTap: () {
                Get.to(
                  StaticPageStateLess(staticPageContentId: 4,staticPageTitle: privacy_policy.tr,),
                  transition: Transition.leftToRight,
                  binding: HomeBinding(),
                  duration: Duration(milliseconds: 215)
                );
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerLegalSvg,
              navigationName:
                  "${legal_information.tr}",
              onTap: () {
                globals.isShowMapPage = false;
                Get.to(
                  StaticPageStateLess(staticPageContentId: 5,staticPageTitle: legal_information.tr,),
                  transition: Transition.leftToRight,
                  binding: HomeBinding(),
                  duration: Duration(milliseconds: 215)
                );
              },
            ),
            DrawerNavigationItem(
              drawerIcon: drawerLogoutSvg,
              navigationName: "${sign_out.tr}",
              onTap: () {
                _asyncConfirmDialog();
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Divider(
                color: AppColors.DIVIDER_COLOR,
                thickness: 1,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                      fontFamily: AppFont.font,
                      fontSize: AppDimen.text_size_14,
                      fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                      text: version.tr,
                    ),
                    TextSpan(
                      text: " - ${globals.versionCode}",
                      style: TextStyle(
                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                           fontFamily: AppFont.font,
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _asyncConfirmDialog() async {
    return Get.dialog(
      barrierDismissible: false,
      Obx(
         () {
          return globals.isAutoThemeUpdated.value != null ? AlertDialog(
            backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(const Radius.circular(10.0),
                ),
            ),
            title: Row(
              children: [
                Image.asset(dialogLogoPng, width: 40, height: 40.0),
                const SizedBox(width: 15),
                Text(
                  sign_out.tr,
                  style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logout_title.tr,
                  style: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                ),
                const  SizedBox(height: 30),
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
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_WHITE,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  width: 1, color: AppColors.PRIMARY_COLOR_DARK),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(cancel.tr,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          App().stopRequestAudio();
                          Get.key.currentState!.canPop() ? Get.back() : null;
                          controller.checkInternet(setLogout, true);
                        },
                        child: Container(
                          width: Get.width,
                          height: 50,
                          margin: const EdgeInsetsDirectional.only(start: 10),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_DARK,
                              borderRadius: BorderRadius.circular(4),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(sign_out.tr,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ) : SizedBox.shrink();
        }
      )
    );
  }

  setLogout() {
    PrimaryScaffold.avoidLoader = false;
    globals.isEnableContinuousLoading = true;
    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
    globals.tripFromSocket = false;
    controller.setLoadingController(true);
    controller.setLogout(widget.builderctx);
    stopAndroidService();
  }

  Size _getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  Future<void> stopAndroidService() async {
    if (Platform.isAndroid) {
      var authToken = "${globals.authToken}&&${globals.userid}";
      var methodChannel = MethodChannel("Stop Service Channel");
      var result = await methodChannel
          .invokeMethod("stopService", {"authWithUserId": authToken});
    }
  }
}