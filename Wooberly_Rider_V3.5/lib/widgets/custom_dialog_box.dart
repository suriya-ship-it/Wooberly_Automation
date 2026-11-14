import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/widgets/primary_button.dart';

import '../resources/values/app_images.dart';

class CustomDialogBox extends StatefulWidget {
  final String? title, descriptions;
  final Widget? okButton;
  final Widget? picture;
  final void Function() callback;
  const CustomDialogBox({Key? key, this.title, this.descriptions, this.okButton,this.picture, required this.callback})
      : super(key: key);

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
  String _permission_content = 'permission_popup_content'.tr;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }
  contentBox(context) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: AppColors.PRIMARY_LIGHT_COLOR,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha:0.2),
                blurRadius: 8.0,
                spreadRadius: 2.0,
                offset: Offset(0,3)
            )
          ]),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: const EdgeInsetsDirectional.only(top: 20),
                child:  SvgPicture.asset(contactInfopopupSvg,
                  width: 50.0,
                  height: 63.0,
                )
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              child: Column(
                children: [
                  for ( var str in _permission_content.split("\n"))
                    Padding(
                        padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 10,),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Text('•', style: TextStyle(fontSize: 30,color: AppColors.PRIMARY_DARK_COLOR),),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  str,
                                  style: TextStyle(
                                    color: AppColors.BLACK_TEXT_COLOR,
                                    fontSize: AppDimen.text_size_16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFont.font,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                    ),
                ],
              ),
            ),


            const  SizedBox(height: 10),
            Divider(
              thickness: 1,
              color: AppColors.DIVIDER_COLOR,
            ),
            InkWell(
              onTap:() {
                widget.callback();
                Get.back();
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
                  child: Text("label_got_it".tr,
                  style: TextStyle(fontSize: AppDimen.text_size_18,
                    fontFamily: AppFont.font,
                    color: AppColors.PROMOCODE_LINK_COLOR,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),


            ),
            const SizedBox(height:20)

          ]),
    );
  }
}