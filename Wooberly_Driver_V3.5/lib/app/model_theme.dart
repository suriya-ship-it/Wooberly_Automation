import 'package:flutter/material.dart';

import 'app.dart';

class ModelTheme extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ModelTheme() {
    _isDark = false;
    getPreferences();
  }

  set isDark(bool value) {
    _isDark = value;
    App().appPreference.preferredTheme = value;
    notifyListeners();
  }

  getPreferences() async {
    isDark = App().appPreference.preferredTheme;
    notifyListeners();
  }
}