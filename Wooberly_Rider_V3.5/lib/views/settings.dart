import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/views/select_map_location.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';

class Settings extends StatelessWidget {
 final String? isFromForSettings;
  bool movetoSetting;
  Settings({Key? key,this.isFromForSettings,this.movetoSetting = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsState(this.isFromForSettings!,this.movetoSetting);
  }
}

class SettingsState extends StatefulWidget {
  final String isFromForSettings;
   bool movetoSetting;
  SettingsState(this.isFromForSettings,this.movetoSetting);
  @override
  State<StatefulWidget> createState() =>
      SettingsStateView(this.isFromForSettings);
}

class SettingsStateView extends State<SettingsState> {
  late BuildContext _scaffoldContext;
  RegisterController _registerController=Get.find();
  String? _locId;
  bool _removeLocclick = true;
  final String isFromForSettings;
  SettingsStateView(this.isFromForSettings);




  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: false,
        appBarTitle: 'settings'.tr,
        customAppBarFunction: () {
          PrimaryScaffold.avoidLoader.value = false;
          debugPrint("customAppBarFunction: ${widget.movetoSetting} --- ");

          if (widget.movetoSetting) {
            if (isFromForSettings == "homepage") {
              globals.isDrawerOpen = true;
              Get.offAllNamed(AppRoutes.APP_HOME);

            } else {
              globals.isDrawerOpen = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(AppRoutes.APP_MAP_MAIN);
              });
            }
            widget.movetoSetting = false;
          } else {
            _registerController.setBackNavigation();
          }


        },
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsetsDirectional.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: InkWell(
                      onTap: () {
                       _registerController.setNavigation(
                            AppRoutes.APP_ROUTE_EDIT_ACC);
                      },
                      child: Column(
                        children: <Widget>[
                          Obx(() {
                              return Stack(
                                children: <Widget>[
                                  ClipOval(
                                    child: Container(
                                      width: 88.0,
                                      height: 88.0,
                                    ),
                                  ),
                                  Container(
                                    width: 88.0,
                                    height: 88.0,
                                    child: globals.uploadedImage == null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100.0),
                                                child: globals.picture.value.isNotEmpty
                                                    ? CachedNetworkImage(
                                                        height: 88.0,
                                                        width: 88.0,
                                                        memCacheWidth: 200,
                                                        memCacheHeight: 200,
                                                        fit: BoxFit.cover,
                                                        imageUrl: globals.picture.value,
                                                        
                                                      )
                                                    : SvgPicture.asset(
                                                        defaultProfileSvg,
                                                        height: 88.0,
                                                        width: 88.0,
                                                      ),
                                              )
                                            : new ClipOval(
                                                child: Image.memory(
                                                globals.uploadedImage,
                                                fit: BoxFit.cover,
                                              ))

                                  ),
                                ],
                              );
                            }
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 15, end: 15, top: 12),
                            child: Obx((){
                                  return Text(
                                    "${toBeginningOfSentenceCase(globals.firstname.value)}" +
                                        " " +
                                        "${globals.lastname.value[0].toUpperCase()}${globals.lastname.substring(1)}",
                                    style: TextStyle(
                                      color: AppColors.BLACK_TEXT_COLOR,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppFont.font,
                                      fontSize: AppDimen.text_size_16,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GetBuilder<RegisterController>(
                    builder: (_) {
                      return Container(
                        margin: const EdgeInsetsDirectional.only(top: 30),
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_LIGHT_COLOR,
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsetsDirectional.all(18),
                              child: Text(
                                'favorites'.tr,
                                style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontFamily: AppFont.font,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          _getFavoriteLocationWidget(SelectLocationEnum.homeLocation,'Add_home'.tr,'home'.tr, addhomeSvg),
                            const SizedBox(
                              height: 10,
                            ),
                            Divider(
                              height: 5,
                              color: AppColors.DIVIDER_COLOR,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            _getFavoriteLocationWidget(SelectLocationEnum.workLocation,'Add_work'.tr,'work'.tr, addworkSvg),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  Container(
                      margin: const EdgeInsetsDirectional.only(top: 30),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_LIGHT_COLOR,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                             _registerController.setNavigation(
                                  AppRoutes.TRUSTED_CONTACT);
                            },
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  start: 18, top: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'manage_contacts'.tr,
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.font),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                       margin: const EdgeInsetsDirectional.only(
                                            top: 2, start: 3),
                                        child: RotatedBox(
                                          quarterTurns: globals.isRTLLang ? 2:0,
                                          child:
                                        SvgPicture.asset(
                                          primaryRightArrowSvg,
                                          fit: BoxFit.scaleDown,
                                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                        ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _borderWithSvgImage(emergencyContactSvg),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                              end: 18, top: 10, bottom: 10),
                                          child: Text(
                                              'manage_contacts_content'.tr,
                                              style: TextStyle(
                                                  color: AppColors
                                                      .BLACK_TEXT_COLOR,
                                                  fontSize:
                                                      AppDimen.text_size_16,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: AppFont.font)),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                  Container(
                      margin: const EdgeInsetsDirectional.only(top: 30),
                      decoration: BoxDecoration(
                          color: AppColors.PRIMARY_LIGHT_COLOR,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(_scaffoldContext)
                                  .hideCurrentSnackBar();
                             _registerController.showThemeModeBottomSheet(
                                context,
                                scaffoldContext: _scaffoldContext,
                                ThemeChangeCallback: (mode) {
                                  if (mode == 2)
                                    updateAppTheme("light");
                                  else if (mode == 3)
                                    updateAppTheme("dark");
                                  else
                                    updateAppTheme("auto");
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  start: 18, top: 18, bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(
                                    'Appearance'.tr,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.font),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.only(top: 11),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _borderWithSvgImage(
                                        globals.theme == 1
                                        ? defaultThemeSvg
                                        : globals.theme == 2
                                        ? homeLightSvg
                                        : homeDarkSvg),
                                        Expanded(
                                          child: Text(_getSelectedTheme(),
                                              style: TextStyle(
                                                  color: AppColors
                                                      .BLACK_TEXT_COLOR,
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

  Widget _borderWithSvgImage(String svgImage){
    return Padding(
        padding: const EdgeInsetsDirectional.only(end: 9),
        child: Container(
          padding: const EdgeInsetsDirectional.all(8),
          decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.BORDERCOLOR,
              ),
              borderRadius:
              BorderRadius.all(
                  Radius.circular(20))),
          child: SvgPicture.asset(
            svgImage,
            colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
          ),
        ));
  }

  String _getSelectedTheme() {
    return globals.theme == 1
        ? 'Auto'.tr
        : globals.theme == 2
            ? 'Light'.tr
            : 'Dark'.tr;
  }

 

  removeLoc(SelectLocationEnum locationEnum) {
    _registerController.removeFavoriteLocation(_locId!).then((value) {
      _removeLocclick = true;
      if (value.isNotEmpty) {
        globals.setButtonIdle();
       _registerController.showInSnackBar( value);
      } else {
        globals.setButtonIdle();
       _registerController.removeLocationDetails(selectLocationEnum: locationEnum);
      }
      _registerController.update();
    });
  }

  removeFavoriteLoc(SelectLocationEnum locationEnum) {
    if (_removeLocclick ) {
      _removeLocclick = false;
      globals.setButtonLoading();
      SelectLocationModel homeLocModel =  _registerController.getLocationDetails( locationEnum);


      if (homeLocModel.id !=null) {
        _locId = homeLocModel.id!.toString();
       _registerController.checkInternet((){
         removeLoc(locationEnum);
       }, true);
      } else {
        _removeLocclick = true;
        globals.setButtonIdle();
       _registerController.showInSnackBar( 'something_went_wrong'.tr);
      }
    }
  }

  updateAppTheme(String fieldValue) {
    _registerController.updateProfileInfo("appTheme", fieldValue).then((value) {});
  }

  _getFavoriteLocationWidget(SelectLocationEnum locationEnum,String emptyAdd, String locationType, String Svg) {
    return InkWell(
      onTap: () async {
        if ((await Permission.location.serviceStatus).isDisabled) {
         _registerController.showLocationPermissionAlert(
              'Enable_the_location_service'.tr,
              true);
          return;
        }
        var locationPermissionStatus = await _registerController.listenForPermissionStatus1(Permission.location);
        switch (locationPermissionStatus) {
          case PermissionStatus.granted:

              widget.movetoSetting = true;
              Get.offAll(SelectMapLocation(
                  selectedPlace:_registerController.getLocationDetails(locationEnum).location,
                  multiStopFrom: "settingspage###${isFromForSettings}"),   arguments: {'locationEnum': locationEnum, 'movetoSetting':widget.movetoSetting});
            break;
          case PermissionStatus.denied:
           _registerController.showLocationPermissionAlert(
                'Enable_the_location_service'.tr, false);
            break;
          default:
           _registerController.showLocationPermissionAlert(
                'Enable_the_location_service'.tr,
                false);
            break;
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 18),
            child:_borderWithSvgImage(Svg),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                     _registerController.getLocationDetails(locationEnum).location == ''
                          ? emptyAdd
                          : locationType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_16,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.font),
                    ),
                  ],
                ),
               _registerController.getLocationDetails(locationEnum).location != ''
                    ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                      end: 10),
                  child: Text(
                   _registerController.getLocationDetails(locationEnum).location.toString().toRemoveCommaString(),
                    style: TextStyle(
                        color: AppColors
                            .BLACK_TEXT_COLOR,
                        fontSize:
                        AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                        fontWeight: FontWeight.w400),
                  ),
                )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
         _registerController.getLocationDetails(locationEnum).location != ''
              ? InkWell(
            onTap: () {
              removeFavoriteLoc(locationEnum);
            },
            child: Container(
              height: 50,
              width: 24,
              alignment: Alignment.center,
              margin: const EdgeInsetsDirectional.only(
                  start: 10, end: 18),
              child: SvgPicture.asset(
                closeCircleIcon,
                height: 25,
                width: 25,
                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
            ),
          )
              : Container(
            height: 50,
            width: 24,
            alignment: Alignment.center,
            margin: const EdgeInsetsDirectional.only(
                start: 10, end: 18),
            child: SvgPicture.asset(
              addSvg,
              height: 25,
              width: 25,
              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}