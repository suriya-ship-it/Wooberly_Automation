import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/databases/app_preferences.dart';
import 'package:app_name/controllers/base_controller.dart';

class ModelTheme extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  BaseController baseController=Get.find();

  ModelTheme() {
    _isDark = false;
  }

  set isDark(bool value) {
    _isDark = value;
    debugPrint('isDark: $value');
    notifyListeners();
  }
}