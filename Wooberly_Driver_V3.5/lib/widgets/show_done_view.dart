import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../resources/values/app_lang.dart';

class InputDoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return keyboardHeight >= 100.0 ?
      Container(
      width: double.infinity,
      color: AppColors.SEARCH_TEXT_COLOR,
      alignment: AlignmentDirectional.topEnd,
      padding:const EdgeInsetsDirectional.only(top: 4.0),
      child: CupertinoButton(
        padding: const EdgeInsetsDirectional.only(end: 24),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Text(done.tr,
            style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_16,
                fontWeight: FontWeight.w600)),
      ),
    )  : const SizedBox.shrink();
  }
}