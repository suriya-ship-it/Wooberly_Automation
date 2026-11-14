import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:app_name/utils/globals.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'lang/ar.dart';
import 'lang/en.dart';
import 'lang/es.dart';
import 'lang/fr.dart';
import 'lang/hr.dart';
import 'lang/id.dart';
import 'lang/ja.dart';
import 'lang/ru.dart';

class AppTranslations extends Translations{
  @override
  Map<String, Map<String, String>> get keys => {
    // 'en_US': en,
    'ar_SA': ar,
    'es_ES': es,
    'fr_FR': fr,
    'hr_HR': hr,
    'id_ID': id,
    'ja_JP': ja,
    'ru_RU': ru,
  };

   Future<Map<String, Map<String, String>>> readJson({required String language,required bool isOnlyDownload,bool isUpdate = false,}) async {
     final point=StackTrace.current.toString().split('\n')[1];
     print('test9_readJson ${point} --- ${mobileLanguages[language]?.languageJson}');
    File? file = await baseController.getDownloadedFile(url: mobileLanguages[language]?.languageJson ?? "", lang: language, isUpdate: isUpdate);
    String filecontent = await file?.readAsString() ?? '';
     print("filecontent -->>>> ${filecontent}");
    final langResponse = jsonDecode(filecontent);

    final keys = Map<String, Map<String, String>>();
    Map<String, String> langmap = Map.castFrom(langResponse["data"]);
    keys.addAll({language: langmap});
    Get.addTranslations(keys);
    if(!isOnlyDownload) {
      changeLocale(languageCode: language);
    }
    return keys;
  }

  changeLocale({required String languageCode}) {
    Get.updateLocale(Locale(languageCode,''));
  }

}