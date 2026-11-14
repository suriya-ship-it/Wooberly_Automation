import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';


class CustomRichText extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTapResult;

  CustomRichText({required this.text, required this.onTapResult});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('///');

    return RichText(
      text: TextSpan(
        children: _buildTextSpans(parts),
      ),
      textAlign: TextAlign.start,
    );
  }

  List<TextSpan> _buildTextSpans(List<String> parts) {
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
              fontFamily: AppFont.font,
              color: AppColors.BLACK_TEXT_COLOR,
              fontSize: AppDimen.text_size_14,
              fontWeight: FontWeight.w400
          ),
        ),
      );

      if (i < parts.length - 1) {
        final linkText = parts[i + 1];
        spans.add(
          TextSpan(
            text: linkText,
            style: TextStyle(
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_14,
                fontWeight: FontWeight.w400,
                 color: AppColors.PROMOCODE_LINK_COLOR,
               decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = () {
              onTapResult(linkText);
            },
          ),
        );
        i++;
      }
    }

    return spans;
  }
}