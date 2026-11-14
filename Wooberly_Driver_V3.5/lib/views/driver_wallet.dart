import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_button.dart';

import '../app/model_theme.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';

class DriverWallet extends StatelessWidget {
  const DriverWallet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DriverWalletState();
  }
}

class DriverWalletState extends StatefulWidget {
  const DriverWalletState({Key? key}) : super(key: key);

  @override
  State<DriverWalletState> createState() => _DriverWalletStateState();
}

class _DriverWalletStateState extends State<DriverWalletState> {
  late BuildContext scoffoldcontext;
  final MapMainController controller = Get.find();
  bool _isHelppage = false;

  @override
  void initState() {
    globals.currentShowingPage = AppRoutes.APP_DRIVER_WALLET;
    Map<String,dynamic> walletoptions =  {};
    walletoptions.addAll(globals.driverWalletOptionController.value);
    Map<dynamic,dynamic> fcmwallet = globals.rxFcmWalletOptions.value;
    globals.rxFcmWalletOptions.stream.listen((fcmwallet){
      if(_isHelppage) Get.key.currentState!.canPop() ? Get.back() : null;
      _updateWalletInfo(walletoptions: walletoptions, fcmwallet: fcmwallet);
    });
    _updateWalletInfo(walletoptions: walletoptions, fcmwallet: fcmwallet);

    walletoptions['isDisablePage'] = 'wallet';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.driverWalletOptionController.value = walletoptions;
      globals.currentShowingPage = AppRoutes.APP_DRIVER_WALLET;
    });
    super.initState();
  }
  _updateWalletInfo({required Map<String,dynamic> walletoptions, required Map<dynamic,dynamic> fcmwallet }){
    if(walletoptions["isDriverEligible"] != fcmwallet["isDriverEligible"] ||
        walletoptions["walletBalance"] != fcmwallet["walletBalance"] ||
        walletoptions["minimumWalletAmount"] != fcmwallet["minimumWalletAmount"]
    ) {
      controller.checkIsDriverEligible();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: wallet.tr,
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
        body: Stack(
          children: <Widget>[
            Container(
              margin: EdgeInsetsDirectional.only(top: 36, start: 24, end: 24),
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 18,vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: AppColors.COMMON_BG_COLOR,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          height: 74,
                          width: 88,
                          padding: EdgeInsetsDirectional.all(15),
                          child: SvgPicture.asset(
                            walletSvg,
                            colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(
                          width: 24,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                your_wallet_amount.tr,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.font),
                              ),
                              ValueListenableBuilder<Map<String,dynamic>>(
                                valueListenable: globals.driverWalletOptionController,
                                builder: (context, position, child) {
                                  return RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                          fontSize: AppDimen.text_size_28,
                                          fontWeight: FontWeight.w600),
                                      children: [
                                        TextSpan(
                                            text: globals.currencySymbol,
                                            style: TextStyle(
                                                color: AppColors
                                                    .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontSize:
                                                AppDimen.text_size_28,
                                                fontWeight: FontWeight.w600)),
                                        TextSpan(
                                          text: double.parse(globals.driverWalletOptionController.value["walletBalance"].toString()).toStringAsFixed(2),
                                          style: TextStyle(
                                              color:
                                              AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_28,
                                              fontFamily: AppFont.font,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 2.5,
                    color: AppColors.COMMON_BG_COLOR,
                  ),
                  ValueListenableBuilder<Map<String,dynamic>>(
                      valueListenable: globals.driverWalletOptionController,
                      builder: (context, position, child) {
                        return Padding(
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             const SizedBox(height: 16),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, right: 10.0, top: 3.0, bottom: 5.0),
                                  decoration: BoxDecoration(
                                    borderRadius: new BorderRadius.circular(20.0),
                                    color: globals.driverStatus.contains("_NotEligible") || globals.driverStatus.contains('pending') || globals.driverStatus.contains('inactive') ? AppColors.RIDE_NOT_ELIGIBLE_COLOR : AppColors.RIDE_ELIGIBLE_COLOR,
                                  ),
                                  child: Text(
                                    globals.driverStatus.contains("_NotEligible") || globals.driverStatus.contains('pending') || globals.driverStatus.contains('inactive') ? not_eligible_for_ride_request.tr : eligible_for_ride_request.tr,
                                    style: TextStyle(
                                        fontSize: AppDimen.text_size_14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.WHITE_TEXT_COLOR),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            const  SizedBox(height: 18),
                              Row(
                                children: [
                                 Expanded(
                                   child: Text(
                                    minimum_amount_for_ride_request.tr,
                                    maxLines: 3,
                                    style: TextStyle(
                                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                        fontSize: AppDimen.text_size_14,
                                        fontFamily: AppFont.font),
                                  ),
                                 ),
                                  const  SizedBox(width: 18),
                                    RichText(
                                        text: TextSpan(children: [
                                          TextSpan(
                                            text: "${globals.currencySymbol}",
                                            style: TextStyle(
                                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_14,
                                                fontFamily: "Roboto"),
                                          ),
                                          TextSpan(
                                            text:
                                            '${double.parse(globals.driverWalletOptionController.value["minimumWalletAmount"].toString()).toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_14,
                                                fontFamily: AppFont.font),
                                          ),
                                        ]))


                                  ],
                                ),
                             const SizedBox(height: 18),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
                child: PrimaryButton(
                  buttonTitle: contact_admin.tr,
                  buttonImage: primaryBtnArrow,
                  innerPadding: 6,
                  mainAxisSize: MainAxisSize.max,
                  callback: () {
                    _isHelppage = true;
                    App().setNavigation(AppRoutes.APP_HELP_INFO, isEnableShowingPage: false).then((value){
                      _isHelppage = false;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        customAppBarFunction: (){
          globals.currentShowingPage ="";
          Map<String,dynamic> walletoption = {};
          walletoption.addAll(globals.driverWalletOptionController.value);
          walletoption['isDisablePage'] = '';
          globals.driverWalletOptionController.value = walletoption;
          App().setBackNavigation();
        },
      );
    });
  }
  @override
  void dispose() {
    globals.currentShowingPage ="";
    globals.rxFcmWalletOptions.value = {};
    Map<String,dynamic> walletoption = {};
    walletoption.addAll(globals.driverWalletOptionController.value);
    walletoption['isDisablePage'] = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.driverWalletOptionController.value = walletoption;
    });
    super.dispose();
  }

}