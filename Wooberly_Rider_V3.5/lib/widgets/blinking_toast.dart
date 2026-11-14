import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';

class Toast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (_) {}
      _overlayEntry = null;
    }
  }

  void show({
    required BuildContext context,
    Duration duration = const Duration(seconds: 2),
    Color bgColor = Colors.black,
    Color txtColor = Colors.white,
    required String message,
  }) {
    dismiss();

    OverlayState? overlayState;
    try {
      overlayState = Overlay.maybeOf(context);
    } catch (_) {}

    if (overlayState == null && Get.overlayContext != null) {
      try {
        overlayState = Overlay.maybeOf(Get.overlayContext!);
      } catch (_) {}
    }

    if (overlayState == null && Get.key.currentState != null) {
      try {
        overlayState = Get.key.currentState?.overlay;
      } catch (_) {}
    }

    if (overlayState == null) {
      debugPrint("overlayState is null, using Get.rawSnackbar fallback for: $message");
      try {
        Get.rawSnackbar(
          messageText: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txtColor,
              fontWeight: FontWeight.w300,
              fontFamily: AppFont.font,
              fontSize: AppDimen.text_size_16,
            ),
          ),
          backgroundColor: bgColor,
          duration: duration,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(20),
          borderRadius: 30,
        );
      } catch (e) {
        debugPrint("Get.rawSnackbar error: $e");
      }
      return;
    }

    final entry = OverlayEntry(
      builder: (BuildContext ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsetsDirectional.only(
            bottom: MediaQuery.of(ctx).viewPadding.bottom + 20.0,
            end: 20.0,
            start: 20.0,
          ),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 7.0, horizontal: 20.0),
                color: bgColor,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: txtColor,
                    fontWeight: FontWeight.w300,
                    fontFamily: AppFont.font,
                    fontSize: AppDimen.text_size_16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _overlayEntry = entry;

    try {
      overlayState.insert(entry);
    } catch (e) {
      _overlayEntry = null;
      debugPrint("overlayState.insert error: $e");
      try {
        Get.rawSnackbar(
          messageText: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txtColor,
              fontWeight: FontWeight.w300,
              fontFamily: AppFont.font,
              fontSize: AppDimen.text_size_16,
            ),
          ),
          backgroundColor: bgColor,
          duration: duration,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(20),
          borderRadius: 30,
        );
      } catch (_) {}
      return;
    }

    _timer = Timer(duration, () {
      if (_overlayEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _overlayEntry = null;
      }
    });
  }
}