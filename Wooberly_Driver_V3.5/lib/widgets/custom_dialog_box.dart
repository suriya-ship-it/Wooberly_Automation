import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:get/get.dart';
import '../app/model_theme.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../utils/globals.dart';

class CustomDialogBox extends StatefulWidget {
  final String? title, descriptions;
  final Widget? okButton;
  final Widget? picture;

  final void Function() callback;

  const CustomDialogBox(
      {Key? key,
        this.title,
        this.descriptions,
        this.okButton,
        this.picture,
        required this.callback,
      })
      : super(key: key);

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
  String _permission_content = location_permission_content.tr;
  List<String> get lines => _permission_content.replaceAll(r'\n', '\n').split('\n');
  @override
  Widget build(BuildContext context) {
    return contentBox(context);
  }

  contentBox(context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return Stack(
          children: [
            Container(
              width: Get.width,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: AppColors.PRIMARY_COLOR_WHITE,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha:0.2),
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                        offset: Offset(0, 3))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                GestureDetector(
                  onTap: (){
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsetsDirectional.only(top:20, end: 20),
                    alignment: AlignmentDirectional.topEnd,
                    child: SvgPicture.asset(
                      closeSvg,
                      width: 15,
                      height: 15,
                      colorFilter: ColorFilter.mode(
                          AppColors.ICON_COLOUR,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SvgPicture.asset(
                      mapPinIconSvg,
                      width: 50.0,
                      height: 63.0,
                    ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: Get.height > 190
                      ? 220
                      : Get.height - 100,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final str in lines)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -8),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 30,
                                      color: AppColors.PRIMARY_COLOR_DARK,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    str.trim(), // 👈 important
                                    softWrap: true,
                                    style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontSize: AppDimen.text_size_16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.font,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Divider(
                  thickness: 1,
                  color: AppColors.DIVIDER_COLOR,
                ),
                InkWell(
                  onTap: () {
                    widget.callback();
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      isAlwaysAllowDenied ? go_to_setting.tr : got_it.tr,
                      style: TextStyle(
                        fontSize: AppDimen.text_size_18,
                        fontFamily: AppFont.font,
                        color: AppColors.TEXT_LINK_COLOR,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20)
              ]),
            ),

          ],
        );
      }
    );
  }
}