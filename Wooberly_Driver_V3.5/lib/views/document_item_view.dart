import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import '../app/app.dart';
import '../controller/auth_controllers/document_controller.dart';
import '../controller/auth_controllers/register_controller.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../utils/globals.dart' as globals;

class DocumentView extends StatelessWidget {
  final DocumentController controller = Get.find();
  final RegisterController registerController = Get.find();
  final String document_title;
  final int mainFlexSize = 90;
  final bool isFromVehicleDetails;

  DocumentView({super.key, required this.document_title, this.isFromVehicleDetails=false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR_WHITE,
              borderRadius: BorderRadius.all(Radius.circular(3),
              ),
          ),
          margin: const EdgeInsets.only(
            top: 22,
          ),
          padding:
          const EdgeInsetsDirectional.symmetric(horizontal:20,vertical:5,),
          child:  InkWell(
            onTap: () async {
              await getDocumentUploadStatus();

              controller!.documentType = document_title;
              if (document_title.compareTo(
                  document_front.tr) ==
                  0) {
                controller!.selectedImage = controller!.imageFront;
              } else if (document_title
                  .compareTo(document_back.tr) ==
                  0) {
                controller!.selectedImage = controller!.imageBack;
              } else if (document_title
                  .compareTo(rc_book.tr) ==
                  0) {
                controller!.selectedImage = controller!.imageRC;
              } else if(document_title
                  .compareTo(insurance.tr) ==
                  0){
                controller!.selectedImage = controller!.imageInsu;
              }else{
                debugPrint("globals.vehicleImagePath: ${globals.vehicleImagePath}");
                if(globals.vehicleImagePath !=null && globals.vehicleImagePath.isNotEmpty)
                  controller.selectedImage=  globals.UPLOAD_URL + "/images/vehicle/" + globals.vehicleImagePath;
                else
                  controller.selectedImage=globals.vehicleImagePath;
              }
              if(isFromVehicleDetails){
                Get.to(AppRoutes().getWidget(AppRoutes.APP_MULTI_DOCUMENT_UPLOAD),arguments: true);
              }else {
                Get.to(AppRoutes().getWidget(AppRoutes.APP_MULTI_DOCUMENT_UPLOAD), arguments: false);
              }
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: mainFlexSize,
                  child: Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      document_title,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                    flex: 80 - mainFlexSize,
                    child: getIcon(document_title)

                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Future<void> getDocumentUploadStatus() async {
    debugPrint("appPreferenceisDoc: ${App().appPreference.isDoc}");
    if(App().appPreference.isDoc.isNotEmpty) {
      controller!.documentFront = true;
      controller!.imageFront = App().appPreference.isDoc;
    }

    if(App().appPreference.backPath.isNotEmpty) {
      controller!.documentBack = true;
      controller!.imageBack = App().appPreference.backPath;
    }

    if(App().appPreference.rcPath.isNotEmpty) {
      controller!.rcBook = true;
      controller!.imageRC = App().appPreference.rcPath;
    }

    if(App().appPreference.insuPath.isNotEmpty) {
      controller!.insurance = true;
      controller!.imageInsu = App().appPreference.insuPath;
    }

    controller.rxImageRefreshController.value = false;
  }
  Widget getIcon(String docName) {
    if (docName.compareTo(document_front.tr) == 0 && controller!.documentFront) {
      return SvgPicture.asset(
        checkSvg,
        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
      );
    } else if (docName.compareTo(document_back.tr) ==
        0 &&
        controller!. documentBack) {
      return SvgPicture.asset(
        checkSvg,
        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
      );
    } else if (docName.compareTo(rc_book.tr) == 0 &&
        controller!.rcBook) {
      return SvgPicture.asset(
        checkSvg,
        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
      );
    } else if (docName.compareTo(insurance.tr) ==
        0 &&
        controller!.insurance) {
      return SvgPicture.asset(
        checkSvg,
        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
      );
    }else if (globals.vehicleImagePath.isNotEmpty&&isFromVehicleDetails) {
      return SvgPicture.asset(
        checkSvg,
        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
      );
    } else
      return SvgPicture.asset(rightArrowSvg,
          colorFilter:
          ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
          matchTextDirection: true);
  }
}