import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:intl/intl.dart' as intl;


class Toast {
  static Toast instance = Toast._internal();
  factory Toast() => instance;
  Toast._internal();
  bool _isShowing = false;
  OverlayEntry? _overlayEntry;
  Timer? _timer;

  void show({String message = "", double seconds = 2, Widget? overlayWidget,BuildContext? context}) {
    _timer?.cancel();
    if (_isShowing) {
      _overlayEntry?.remove();
      _isShowing = false;
    }

    _overlayEntry = OverlayEntry(builder: (context) {
      return Directionality(
        textDirection: intl.Bidi.isRtlLanguage(Get.locale?.languageCode) ? TextDirection.rtl : TextDirection.ltr,
        child: overlayWidget != null
            ? Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => dismiss(),
            child:
            Stack(
           children:  [
              overlayWidget,
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: dismiss,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
            ),
          ),
        )
            : IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding:const EdgeInsets.symmetric(vertical: 15.0,horizontal: 15.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      color: AppColors.PRIMARY_COLOR_DARK,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.PRIMARY_COLOR_WHITE,
                                fontWeight: FontWeight.w200,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ),
          ),
        ),
        ),
      );
    });

    final overlay = Get.key.currentState?.overlay;

    if (overlay != null) {
      overlay.insert(_overlayEntry!);
      _isShowing = true;

      _timer = Timer(Duration(milliseconds: (seconds * 1000).toInt()), () {
        dismiss();
      });
    } else {
      debugPrint("Error: Could not find Overlay via Get.key");
    }
  }

  void dismiss() {
    if (_isShowing) {
      _overlayEntry?.remove();
      _isShowing = false;
      _timer?.cancel();
    }
  }
}