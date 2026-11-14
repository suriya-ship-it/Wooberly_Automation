import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_scaffold.dart';
import '../widgets/show_done_view.dart';

class showTipScreenLess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return showTipScreenState();
  }
}

class showTipScreenState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => showTipScreenStateView();
}

class showTipScreenStateView extends State<showTipScreenState> {
  MapMainController mapMainController = Get.find();
  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  BuildContext? scaffoldContext;

  @override
  void initState() {
    mapMainController.getDeviceDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapMainController.init();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (DidPop, onPopInvokedWithResult) {
        if (!DidPop) {
          mapMainController.tripAmountController?.forward();
          mapMainController.setBackNavigation();
        }
      },
      child: Consumer<ModelTheme>(
          builder: (context, ModelTheme themeNotifier, child) {
          return ColoredBox(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    PrimaryScaffold(
                      appBarTitle: 'tip_label'.tr,
                      customAppBarFunction: () {
                        mapMainController.userRating = 0.0;
                        mapMainController.tripAmountController?.forward();
                        mapMainController.setBackNavigation();
                      },
                      body: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.symmetric(vertical: 30),
                              child: Wrap(
                                children: <Widget>[
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsetsDirectional.symmetric(vertical: 30),
                                          decoration: BoxDecoration(
                                            color: AppColors.PRIMARY_LIGHT_COLOR,
                                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Stack(
                                                children: <Widget>[
                                                  new Icon(
                                                    Icons.account_circle,
                                                    size: 82,
                                                    color: AppColors.LOCATION_ARRIVED_COLOR,
                                                  ),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(50.0),
                                                    child: mapMainController.driverPhoto != null &&
                                                            mapMainController.driverPhoto.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            height: 82.0,
                                                            width: 82.0,
                                                            fit: BoxFit.cover,
                                                            imageUrl: mapMainController.driverPhoto != null
                                                                ? mapMainController.driverPhoto
                                                                : "",
                                                            placeholder: (context, url) => mapMainController.userProfilePlaceholder,
                                                          )
                                                        : mapMainController.userProfilePlaceholder,
                                                  )
                                                ],
                                              ),
                                              Text(
                                                  mapMainController.driverName == null ||
                                                          mapMainController.driverName.compareTo("") == 0
                                                      ? ""
                                                      : "${'set_tip'.tr} ${mapMainController.driverName[0].toUpperCase()}${mapMainController.driverName.substring(1)}",
                                                  maxLines: 2,
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: AppDimen.text_size_18,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.BLACK_TEXT_COLOR)),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Padding(
                                                    padding: const EdgeInsetsDirectional.only(
                                                      top: 12.0,
                                                    ),
                                                    child: RichText(
                                                      textAlign: TextAlign.end,
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                          fontSize: AppDimen.text_size_22,
                                                          color: AppColors.BLACK_TEXT_COLOR,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: globals.currencySymbol,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 35,
                                                    width: 180,
                                                    child: TextFormField(
                                                      enableIMEPersonalizedLearning: false,
                                                      key: _formKey,
                                                      controller: mapMainController.tipsAmount,
                                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                      inputFormatters: <TextInputFormatter>[
                                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                                      ],
                                                      style: TextStyle(
                                                          fontSize: AppDimen.text_size_22,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.BLACK_TEXT_COLOR),
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        border: InputBorder.none,
                                                        focusedBorder: UnderlineInputBorder(
                                                          borderSide: BorderSide.none,
                                                        ),
                                                        contentPadding: const EdgeInsetsDirectional.only(top: 5),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 180,
                                                child: Divider(
                                                  color: AppColors.BLACK,
                                                  thickness: 1.1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsetsDirectional.only(top: 10.0),
                                                child: globals.isRTLLang
                                                    ? RichText(
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            color: AppColors.BLACK_TEXT_COLOR,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                                text: "${'your_trip_was'.tr} ",
                                                                style: TextStyle(
                                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                                    fontSize: AppDimen.text_size_14,
                                                                    fontWeight: FontWeight.w400)),
                                                            TextSpan(
                                                                text:
                                                                    "${mapMainController.tripFinalAmount.toStringAsFixed(2)}",
                                                                style: TextStyle(
                                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                                    fontSize: AppDimen.text_size_14,
                                                                    fontWeight: FontWeight.w400)),
                                                            TextSpan(
                                                              text: globals.currencySymbol,
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : RichText(
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            color: AppColors.BLACK_TEXT_COLOR,
                                                            fontSize: AppDimen.text_size_14,
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                          children: [
                                                            TextSpan(
                                                                text: "${'your_trip_was'.tr} ",
                                                                style: TextStyle(
                                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                                    fontSize: AppDimen.text_size_14,
                                                                    fontWeight: FontWeight.w400)),
                                                            TextSpan(
                                                              text: globals.currencySymbol,
                                                            ),
                                                            TextSpan(
                                                                text: "${mapMainController.tripFinalAmount}",
                                                                style: TextStyle(
                                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                                    fontSize: AppDimen.text_size_14,
                                                                    fontWeight: FontWeight.w400))
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: GetBuilder<MapMainController>(
                                  id: 'tipDoneButton',
                                  builder: (_) {
                                    return Padding(
                                      padding: const EdgeInsetsDirectional.only(bottom: 15),
                                      child: PrimaryButton(
                                        buttonTitle: 'done'.tr,
                                        buttonImage: primaryRightArrowSvg,
                                        callback: () {
                                          mapMainController.updatePadding(0);
                                          if (mapMainController.tipsAmount.text.isEmpty ||
                                              double.parse(mapMainController.tipsAmount.text) <= 0.0) {
                                            mapMainController.toast.show(
                                              context: context,
                                              message: 'Enter_Valid_tip'.tr,
                                              bgColor: AppColors.DIVIDER_COLOR,
                                              txtColor: AppColors.BLACK_TEXT_COLOR,
                                            );
                                            mapMainController.tipsAmount.clear();
                                          } else if (double.parse(mapMainController.tipsAmount.text) >=
                                              mapMainController.tripFinalAmount) {
                                            mapMainController.toast.show(
                                              context: context,
                                              message: 'tips_amount_less'.tr,
                                              bgColor: AppColors.DIVIDER_COLOR,
                                              txtColor: AppColors.BLACK_TEXT_COLOR,
                                            );
                                          } else {
                                            mapMainController.update(['tipDoneButton']);
                                            mapMainController.checkInternet(() {}, null).then((onValue) {
                                              if (!onValue) {
                                                mapMainController.update(['tipDoneButton']);
                                              } else {
                                                addTips();
                                              }
                                            });
                                          }
                                          SystemChannels.textInput.invokeMethod('TextInput.hide');
                                        },
                                      ),
                                    );
                                  }),
                            )
                          ],
                        ),
                      ),
                      onChanged: (map) {
                        scaffoldContext = map["scaffoldcontext"];
                      },
                    ),
                    Positioned(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        right: 0.0,
                        left: 0.0,
                        child: MediaQuery.of(context).viewInsets.bottom >= 175.0
                            ? InputDoneView()
                            : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void addTips() {
    mapMainController.updateTips().then((value) {
      if (value.isNotEmpty) {
        mapMainController.showInSnackBar(value);
      } else {
        mapMainController.getRideStatus().then((value) {
          mapMainController.setBackNavigation();
        });
      }
    });
  }
}

class refreshControllerIF {
  void refreshController() {}
}