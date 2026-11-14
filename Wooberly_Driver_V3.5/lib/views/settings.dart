import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/auth_controllers/register_controller.dart';
import 'package:wooberly_driver/controller/base_controller.dart';


import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_lang.dart';

class Settings extends StatelessWidget {
  Settings({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsState();
  }
}

class SettingsState extends StatefulWidget {
  SettingsState();

  @override
  State<StatefulWidget> createState() => SettingsStateView();
}

class SettingsStateView extends State<SettingsState> {
  late BuildContext _scaffoldContext;
  final RegisterController _controller = Get.find();
  SettingsStateView();


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    double squareAvatarSize = 88.0;

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: setting.tr,
        customAppBarFunction: () {
          PrimaryScaffold.avoidLoader = false;
          Get.until((route) => route.settings.name == "/MapMainScreen");
        },
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: InkWell(
                        onTap: () {
                          App().setNavigation(AppRoutes.APP_ROUTE_EDIT_ACC);
                        },
                        child: GetBuilder<BaseController>(
                          init: globals.baseController,
                          id: globals.rxLoadingController.id,
                            builder: (val) {
                              return Column(
                                children: <Widget>[
                                  Stack(
                                    children: <Widget>[
                                      ClipOval(
                                        child: Container(
                                          width: squareAvatarSize,
                                          height: squareAvatarSize,
                                        ),
                                      ),
                                      Container(
                                        width: squareAvatarSize,
                                        height: squareAvatarSize,
                                        child: globals.picture != null
                                            ? globals.uploadedImage == null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100.0),
                                                    child: globals.picture != null &&
                                                            globals.picture
                                                                .isNotEmpty
                                                        ? CachedNetworkImage(
                                                            height: squareAvatarSize,
                                                            width: squareAvatarSize,
                                                            fit: BoxFit.cover,
                                                            imageUrl:
                                                                globals.picture,
                                                          )
                                                        : SvgPicture.asset(
                                                            defaultProfileSvg,
                                                            height: squareAvatarSize,
                                                            width: squareAvatarSize,
                                                          ),
                                                  )
                                                : new ClipOval(
                                                    child: Image.memory(
                                                    globals.uploadedImage,
                                                    fit: BoxFit.cover,
                                                  ))
                                            : SvgPicture.asset(
                                                defaultProfileSvg,
                                                height: squareAvatarSize,
                                                width: squareAvatarSize,
                                              ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: 15, end: 15, top: 12),
                                    child: Text(
                                      "${toBeginningOfSentenceCase(globals.firstname)}" +
                                          " " +
                                          "${globals.lastname[0].toUpperCase()}${globals.lastname.substring(1)}",
                                      style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            })),
                  ),
                  Container(
                      margin: EdgeInsetsDirectional.only(top: 30),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_COLOR_WHITE,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(_scaffoldContext)
                                  .hideCurrentSnackBar();
                              _settingModalBottomNewSheet(context);
                            },
                            child: Container(
                              padding: EdgeInsetsDirectional.only(
                                  start: 18, top: 18, bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(
                                    Appearance.tr,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.font),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(top: 11),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          margin: EdgeInsetsDirectional.only(
                                              end: 9),
                                          padding:
                                              EdgeInsetsDirectional.all(8),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.BORDERCOLOR,
                                              ),
                                              borderRadius:
                                                  BorderRadius.all(
                                                      Radius.circular(20))),
                                          child: SvgPicture.asset(
                                            globals.theme.value == 1
                                                ? defaultThemeSvg
                                                : globals.theme.value == 2
                                                    ? lightSvg
                                                    : nightmodeSvg,
                                            colorFilter: ColorFilter.mode(
                                                AppColors.ICON_COLOUR,
                                                BlendMode.srcIn),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(_getSelectedTheme(),
                                              style: TextStyle(
                                                  color: AppColors
                                                      .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                  fontSize:
                                                      AppDimen.text_size_16,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: AppFont.font)),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              )),
        ),
        onChanged: (map) {
          _scaffoldContext = map['scaffoldcontext'];
        },
      );
    });
  }

  void _settingModalBottomNewSheet(mcontext) {
    Get.bottomSheet(
        backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
        Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
            return SafeArea(
              bottom: Platform.isAndroid,
                child: Container(
                  height: 240,
                  color: AppColors.COMMON_BG_COLOR,
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Padding(
                          padding: EdgeInsetsDirectional.only(
                              start: 24, end: 24, top: 24),
                          child: Wrap(children: <Widget>[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    if (index == 0) {
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
                                      var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
                                      print("brightness: ${brightness}");
                                      globals.isDarkTheme =
                                          brightness == Brightness.dark;
                                      globals.theme.value = 1;
                                      updateAppTheme("auto");
                                      App().appPreference.preferredTheme = globals.isDarkTheme;
                                      if (globals.isDarkTheme) {
                                        AppColors().changeToDark();
                                      } else {
                                        AppColors().changeToLight();
                                      }
                                      Get.back();
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                      globals.themeNotifier?.isDark = globals.isDarkTheme;
                                      // AppBuilder.of(mcontext)?.rebuild();
                                    } else if (index == 1) {
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
                                      globals.isDarkTheme = false;
                                      globals.theme.value = 2;
                                      updateAppTheme("light");
                                      App().appPreference.preferredTheme = globals.isDarkTheme;
                                      AppColors().changeToLight();
                                      Get.back();
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                      globals.themeNotifier?.isDark = false;
                                      // AppBuilder.of(mcontext)?.rebuild();
                                    } else {
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
                                      globals.isDarkTheme = true;
                                      globals.theme.value = 3;
                                      updateAppTheme("dark");
                                      App().appPreference.preferredTheme = globals.isDarkTheme;
                                      AppColors().changeToDark();
                                      Get.back();
                                      globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                      globals.themeNotifier?.isDark = true;
                                      // AppBuilder.of(mcontext)?.rebuild();
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsetsDirectional.only(end: 13),
                                        child: SvgPicture.asset(
                                          index == 0
                                              ? defaultThemeSvg
                                              : index == 1
                                                  ? lightSvg
                                                  : nightmodeSvg,
                                          width: 18,
                                          height: 18,
                                          colorFilter: ColorFilter.mode(
                                              AppColors.ICON_COLOUR,
                                              BlendMode.srcIn),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          index == 0
                                              ? Auto.tr
                                              : index == 1
                                                  ? Light.tr
                                                  : Dark.tr,
                                          style: TextStyle(
                                              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                              fontFamily: AppFont.font,
                                              fontWeight: FontWeight.w500,
                                              fontSize: AppDimen.text_size_16),
                                        ),
                                      ),
                                      (globals.theme.value == (index + 1))
                                          ? SvgPicture.asset(
                                        updatedVerified,
                                              width: 24,
                                              height: 24,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.ICON_COLOUR,
                                                  BlendMode.srcIn),
                                            )
                                          : const SizedBox.shrink()
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(top: 10),
                                  child: Divider(
                                    color: AppColors.DIVIDER_COLOR,
                                  ),
                                ),
                              ],
                            )
                          ]));
                    },
                  ),
                ),
              );
          }
        ));
  }

  String _getSelectedTheme() {
    return globals.theme.value == 1
        ? Auto.tr
        : globals.theme.value == 2
            ? Light.tr
            : Dark.tr;
  }

  @override
  void dispose() {
    super.dispose();
  }

  updateAppTheme(String fieldValue) {
    _controller.updateProfileInfo("appTheme", fieldValue).then((value) {});
  }
}