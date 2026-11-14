import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/primary_scaffold.dart';

import '../../controllers/map_main_controller/map_main_controller.dart';
import '../app/model_theme.dart';

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
  MapMainController _mapMainController = Get.find();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      //  return Obx((){
      return PrimaryScaffold(
        customAppBarFunction: () {
          _isDeleting == true ? null : _mapMainController.setBackNavigation();
        },
        appBarTitle: 'manage_your_account'.tr,
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
        },
        body: Container(
          margin: const EdgeInsetsDirectional.only(top: 40.0, end: 24.0, start: 24.0),
          padding: const EdgeInsetsDirectional.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
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
                    colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text('delete_account'.tr,
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
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
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimen.text_size_14,
                    fontFamily: AppFont.font,
                  ),
                  children: [
                    TextSpan(
                      text: "${'caution'.tr}: ",
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font,
                      ),
                    ),
                    TextSpan(
                      text: "${'delete_content'.trParams({'field': globals.APP_NAME})}",
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
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
                  _asyncConfirmDialog(context);
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: 2,
                      ),
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                        color: AppColors.EXCEPTION_COLOR,
                        width: 1.5,
                      ))),
                      child: Text(
                        'delete_permanently'.tr,
                        style: TextStyle(
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.w200,
                          color: AppColors.EXCEPTION_COLOR,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 5, end: 5, top: 5.0, bottom: 2.0),
                      child: RotatedBox(
                        quarterTurns: globals.isRTLLang ? 2 : 0,
                        child: SvgPicture.asset(
                          primaryRightArrowSvg,
                          height: 12.0,
                          width: 12.0,
                          colorFilter: ColorFilter.mode(AppColors.EXCEPTION_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      // });
    });
  }

  Future<void> _asyncConfirmDialog(BuildContext context) async {
    _mapMainController.showConfirmationDialog(
      title: 'delete_account_title'.tr,
        content: 'delete_title'.tr,
       cancelButtonText: 'no'.tr,
        onConfirm: () {
          _isDeleting = true;
          globals.isContinuousLoading = true;
          globals.setButtonLoading();
          Get.back();
          _mapMainController.checkInternet(deleteUser, false);
        },
        confirmButtonText: 'yes'.tr);
  }

  void deleteUser() {
    debugPrint("deleteUserglobals.tripstatus: ${globals.tripStatus}");
    if(globals.tripStatus != "approved" &&
        globals.tripStatus != "locationReached" &&
        globals.tripStatus != "started") {
      _mapMainController.setLogout();
    }
    _mapMainController.deleteUser().then((value) {
      if (value.isNotEmpty) {
        _isDeleting = false;
        switch (value) {
          case "timeout":
            _mapMainController.toast.show(
              context: scoffoldcontext,
              message: 'session_timeout_err'.tr,
              duration: const Duration(seconds: 5),
            );
            break;
          case "offline":
            _mapMainController.netOffSnackbar(deleteUser, false);
            break;
          case "null":
            _mapMainController.checkInternet(deleteUser, false);
            break;
          default:
            globals.isContinuousLoading = false;
            globals.setButtonIdle();
            _mapMainController.showInSnackBar(value);
        }
      } else {
        globals.isContinuousLoading = false;
        globals.setButtonIdle();
      }
    });
  }
}