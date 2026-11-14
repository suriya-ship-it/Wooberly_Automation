import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;


class InputDoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.SEARCH_TEXT_COLOR,
      alignment: AlignmentDirectional.topEnd,
      padding: const EdgeInsetsDirectional.only(top: 4.0),
      child: CupertinoButton(
        padding: const EdgeInsetsDirectional.only(end: 24),
        onPressed: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Text(
            'done'.tr,
            style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_16,
                fontWeight: FontWeight.w600
            )
        ),
      ),
    );
  }
}