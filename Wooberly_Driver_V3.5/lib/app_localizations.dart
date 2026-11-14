import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/lang/ar.dart';
import 'package:wooberly_driver/lang/en.dart';
import 'package:wooberly_driver/lang/es.dart';
import 'package:wooberly_driver/lang/fr.dart';
import 'package:wooberly_driver/lang/id.dart';
import 'package:wooberly_driver/lang/ja.dart';
import 'package:wooberly_driver/lang/ru.dart';
import 'package:wooberly_driver/utils/globals.dart';

class LocalizationService extends Translations {

  @override
  Map<String, Map<String, String>> get keys => {
    // 'en': enLang,
    'es': esLang,
    'fr': frLang,
    'id': idLang,
    'ja': jaLang,
    'ru': ruLang,
    'ar': arLang,
  };

  Future<Map<String, Map<String, String>>> readJson({required String language,required bool isDownloadOnly ,bool isUpdate = false}) async {
    File file = await baseController.getDownloadedFile(url: mobileLanguages[language]?.languageJson ?? "", lang: language, isUpdate: isUpdate);
    String filecontent = await file.readAsString();
    final langResponse = jsonDecode(filecontent);
    final keys = Map<String, Map<String, String>>();
    Map<String, String> langmap = Map.castFrom(langResponse["data"]);
    keys.addAll({language: langmap});
    Get.addTranslations(keys);
    if(!isDownloadOnly) {
      changeLocale(languageCode: language);
    }
    return keys;
  }

  changeLocale({required String languageCode}) {
    Get.updateLocale(Locale(languageCode,''));
  }

}