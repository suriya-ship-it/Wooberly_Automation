import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/payment_type.dart';
import 'package:app_name/views/settings.dart';
import 'package:app_name/views/static_page.dart';
import 'package:app_name/widgets/drawer_navigation_item.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../models/select_location_model.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../controllers/map_main_controller/map_main_controller.dart';

class MapMainDrawer extends StatelessWidget {
  late DrawerCallback callback;
  final MapMainController mapMainController=Get.find();

  MapMainDrawer({required this.callback});

  @override
  Widget build(BuildContext context) {
    return MapMainDrawerState(
        callback: callback, mapMainController: mapMainController);
  }
}

class MapMainDrawerState extends StatefulWidget {
  late DrawerCallback callback;
  late MapMainController mapMainController;

  MapMainDrawerState({required this.callback,required this.mapMainController});

  @override
  _MapMainDrawerState createState() =>
      _MapMainDrawerState(callback, mapMainController);
}

class _MapMainDrawerState extends State<MapMainDrawerState> {
  DrawerCallback callback;
  MapMainController mapMainController;
  _MapMainDrawerState(this.callback, this.mapMainController);

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
    print('auth${globals.authToken}');
    return Container(
      width: MediaQuery.of(context).size.width,
      color: AppColors.COMMON_BG_COLOR,
      child: PopScope(
        canPop: false,
        child: PrimaryScaffold(
          body: ListView(
            padding:  EdgeInsetsDirectional.zero,
            children: <Widget>[
              InkWell(
                onTap: () {
                 mapMainController.setNavigation( AppRoutes.APP_ROUTE_EDIT_ACC);
                },
                child: Column(
                  children: <Widget>[
                    Obx(() {
                      // 1. Extract values to local variables for cleaner logic
                      String pictureUrl = globals.picture.value;
                      final uploadedImage = globals.uploadedImage;
                      const size = 80.0;

                      debugPrint("pictureUrl: ${pictureUrl}");

                      // 2. Determine the correct child widget to display
                      Widget avatarChild;

                      // if (uploadedImage != null) {
                      //   avatarChild = Image.memory(uploadedImage, fit: BoxFit.cover);
                      // } else
                        if (pictureUrl != null && pictureUrl.isNotEmpty) {
                          pictureUrl =  pictureUrl.replaceAll("medium_", "small_");
                        avatarChild = CachedNetworkImage(
                          imageUrl: pictureUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (context, url) => SvgPicture.asset(defaultProfileSvg, width: size, height: size),
                        );
                      } else {
                        avatarChild = SvgPicture.asset(defaultProfileSvg, width: size, height: size);
                      }

                      // 3. Return the structured, scannable layout
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipOval(
                                child: avatarChild,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(end: 15.0, top: 13.0, start: 15.0),
                        child: Obx((){
                          final String name =  "${intl.toBeginningOfSentenceCase(globals.firstname.trim())}" +
                              " " +
                              "${intl.toBeginningOfSentenceCase(globals.lastname.trim())}";
                          final TextStyle nameTextStyle = TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontWeight: FontWeight.w600,
                            fontSize: AppDimen.text_size_20,
                          );
                          final Size txtSize = _getTextSize(name, nameTextStyle);

                          return Container(
                            width:  (txtSize.width > (MediaQuery.of(context).size.width-50) ? MediaQuery.of(context).size.width-50 : txtSize.width+10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(width: 1.0, color: AppColors.PRIMARY_DARK_COLOR),
                              ),
                            ),
                            child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: nameTextStyle
                            ),
                          );
                        }),

                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          globals.checkNavWallet = "";
                         mapMainController.setNavigation( AppRoutes.APP_WALLET);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              SvgPicture.asset(
                                drawerWalletSvg,
                                width: 25.0,
                                height: 25.0,
                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'your_wallet'.tr,
                                style: TextStyle(
                                    fontSize: AppDimen.text_size_16,
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                         mapMainController.setNavigation( AppRoutes.APP_TRIPS);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_LIGHT_COLOR,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              SvgPicture.asset(
                                drawerTripsSvg,
                                width: 25.0,
                                height: 25.0,
                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'drawer_trips'.tr,
                                style: TextStyle(
                                    fontSize: AppDimen.text_size_16,
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontWeight: FontWeight.w500),
                              ),
                              const  SizedBox(height: 15),
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
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 25.0),
                child: Divider(
                  color: AppColors.DIVIDER_COLOR,
                  thickness: 1,
                ),
              ),
              DrawerNavigationItem(
                drawerIcon: drawerPaymentSvg,
                navigationName: "${'payment'.tr}",
                onTap: () {
                  globals.bookingPaymentType = false;
                  globals.checkNavPaymentType = "";
                 mapMainController.setNavigation(AppRoutes.APP_PAYMENT_TYPE);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerCurrLangSvg,
                navigationName:
                    "${'currency_languages'.tr}",
                onTap: () {
                 mapMainController.setNavigation(AppRoutes.APP_CURRENCY_LANGUAGE);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerSettingsSvg,
                navigationName: "${'settings'.tr}",
                onTap: () {
                  Get.to( Settings(
                    isFromForSettings:
                    widget.mapMainController.isFromForSettings,
                  ),binding: HomeBinding(), duration: Duration(milliseconds: 215),transition: Transition.rightToLeft);
                  
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerManageAccSvg,
                navigationName:
                    "${'manage_your_account'.tr}",
                onTap: () {
                 mapMainController.setNavigation(AppRoutes.DELETE_ACCOUNT);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerSupportSvg,
                navigationName:
                    "${'support_label'.tr}",
                onTap: () {
                 mapMainController.setNavigation( AppRoutes.APP_SUPPORT_INFO);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerPrivacyPolicySvg,
                navigationName:
                    "${'privacy_policy'.tr}",
                onTap: () {
                  Get.to( StaticPageStateLess(
                    staticPageTitle: 'privacy_policy'.tr,
                    staticPageContentId: 4,
                  ),binding: HomeBinding(),duration: Duration(milliseconds: 215),transition: Transition.rightToLeft);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerLegalSvg,
                navigationName:
                    "${'legal_information'.tr}",
                onTap: () {
                  Get.to(StaticPageStateLess(
                    staticPageTitle: 'legal_information'.tr,
                    staticPageContentId: 5,
                  ), duration: Duration(milliseconds: 215),transition: Transition.rightToLeft);
                },
              ),
              DrawerNavigationItem(
                drawerIcon: drawerLogoutSvg,
                navigationName: "${'signout'.tr}",
                onTap: () {
                  _asyncConfirmDialog();
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding:  const EdgeInsetsDirectional.symmetric(horizontal: 25.0),
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
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontFamily: AppFont.font,
                        fontSize: AppDimen.text_size_14,
                        fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: 'version'.tr,
                      ),
                      TextSpan(
                        text: " - ${globals.versionCode}",
                        style: TextStyle(
                            color: AppColors.BLACK_TEXT_COLOR,
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
      ),
    );
  }

  Future<void> _asyncConfirmDialog() async {
    return mapMainController.showConfirmationDialog(
      title: 'signout'.tr,
      content: "${'are_you_sure'.tr} ${'logout_title'.tr}",
      confirmButtonText: 'signout'.tr,
      onConfirm: (){
        Get.back();
        checkInternet(Get.context!);
      }
    );
  }

  Size _getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style), maxLines: 1,textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  checkInternet(BuildContext context) {
   mapMainController.checkInternet(_setLogout, true);
  }

  _setLogout() {
    globals.locController(false);
    globals.refreshApp = true;
    globals.isContinuousLoading = true;
    globals.setButtonLoading();
    mapMainController.locationData.clear();
    mapMainController.clearMap();
    mapMainController.userLogout();
   mapMainController.setLogout();

    mapMainController.dispose();
  }
}