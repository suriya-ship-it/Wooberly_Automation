import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DeleteAccountState();
  }
}

class DeleteAccountState extends StatefulWidget {
  const DeleteAccountState({Key? key}) : super(key: key);

  @override
  State<DeleteAccountState> createState() => _DeleteAccountStateState();
}

class _DeleteAccountStateState extends State<DeleteAccountState> {
  late BuildContext scoffoldcontext;
  final MapMainController controller = Get.find();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        customAppBarFunction: () {
          Get.until((route) => route.settings.name == "/MapMainScreen");
          Get.closeCurrentSnackbar();
        },
        appBarTitle: manage_your_account.tr,
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
        body: Container(
          margin: const EdgeInsets.only(top: 40.0, left: 24.0, right: 24.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_COLOR_WHITE,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    deleteUserSvg,
                    height: 20.0,
                    width: 20.0,
                    colorFilter: ColorFilter.mode(
                        AppColors.ICON_COLOUR, BlendMode.srcIn),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(delete_account_title.tr,
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimen.text_size_16,
                        fontFamily: AppFont.font,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimen.text_size_14,
                    fontFamily: AppFont.font,
                  ),
                  children: [
                    TextSpan(
                      text: "${caution.tr}: ",
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                      ),
                    ),
                    TextSpan(
                      text: "${delete_content.tr}",
                      style: TextStyle(
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w400,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () {
                  _asyncConfirmDialog();
                },
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                        color: AppColors.ONLINE_STATUS,
                        width: 1.5,
                      ))),
                      child: Text(
                        delete_permanently.tr,
                        style: TextStyle(
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.w200,
                          color: AppColors.ONLINE_STATUS,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 5, right: 5, top: 5.0, bottom: 2.0),
                      child: SvgPicture.asset(
                        rightArrowSvg,
                        matchTextDirection: true,
                        height: 12.0,
                        width: 12.0,
                        colorFilter: ColorFilter.mode(
                            AppColors.ONLINE_STATUS, BlendMode.srcIn),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _asyncConfirmDialog() async {
    return Get.dialog(
      barrierDismissible: false,
      Obx(
        () {
          return globals.isAutoThemeUpdated.value != null ? AlertDialog(
            backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            title: Row(
              children: [
                Image.asset(dialogLogoPng, width: 40, height: 40.0),
                const SizedBox(width: 15),
                Flexible(
                  child: Text(
                    delete_account_title.tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delete_title.tr,
                  style: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                ),
               const SizedBox(height: 30),
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
                              border:
                                  Border.all(width: 1, color: AppColors.PRIMARY_COLOR_DARK)),
                          child: Center(
                            child: Text(no.tr,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          globals.isEnableContinuousLoading = true;
                          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
                          Get.key.currentState!.canPop() ? Get.back() : null;
                          controller.checkInternet(deleteUser, false);
                        },
                        child: Container(
                          width: Get.width,
                          height: 50,
                          margin: const EdgeInsetsDirectional.only(start: 10),
                          padding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 20,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.PRIMARY_COLOR_DARK,
                              borderRadius: BorderRadius.circular(4)),
                          child: Center(
                            child: Text(yes,
                                style: TextStyle(
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontFamily: AppFont.font,
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppDimen.text_size_16)),
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

  void deleteUser() {
    controller.deleteUser().then((value) {
      if (value.isNotEmpty) {
        if (value == "timeout") {
          globals.isEnableContinuousLoading = false;
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
          App().toast.show(
              context: scoffoldcontext,
              message: session_timeout_err.tr,
              seconds: 5);
        } else if (value == "offline") {
          controller.netOffSnackbar(deleteUser, false);
        } else if (value == "null") {
          controller.checkInternet(deleteUser, false);
        } else {
          globals.isEnableContinuousLoading = false;
          globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
          controller.showInSnackBar( value);
        }
      } else {
        globals.isEnableContinuousLoading = false;
        globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
        controller.setLogout(scoffoldcontext);
      }
    });
  }
}