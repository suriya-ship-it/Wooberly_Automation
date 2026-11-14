import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:customization/customization.dart';
import 'package:customization/helpers/env_helper.dart';
import 'package:xml/xml.dart';

class FlutterConstHandler {

  File? _flutterConstFile;
  File? colorsFile;
  File? _JsonFile;
  EnvHandler? handler;
  XmlDocument? _document ;
  Logger logger = Logger.standard();
  FlutterConstHandler(String filePath, String colorsFilePath) {
    _flutterConstFile = File(filePath);
    colorsFile = File(colorsFilePath);
  }

  Future<void> removeBlockComments(File file) async {
    final content = await file.readAsString();
    final cleaned = content.replaceAll(
      RegExp(r'^\s*//.*$', multiLine: true),
      '',
    );
    await file.writeAsString(cleaned);
  }



  Future<File?> init(
      {Map<String, String>? data, EnvHandler? envHandler}) async {
    handler = envHandler!;
    final bool fileIsExists = _flutterConstFile!.existsSync();
    if (fileIsExists) {
      await _modifyString(data ?? {});
      _JsonFile = File('android/app/google-services.json');
      final iosfile = File('ios/Runner/GoogleService-Info.plist');


      final bool jsonfileIsExists = _JsonFile!.existsSync();

      if(jsonfileIsExists && iosfile.existsSync()){
        await _updateAndroidConfig();
        await _updateIOSConfig();
      }
      if (jsonfileIsExists) {
        await _updateAndroidConfig();
      } else if(iosfile.existsSync()) {
        await _updateIOSConfig();
      } else {
        var filelist = Directory('Apple Certificates').listSync();
        filelist.forEach((file) {
          if (file is File) {
            print('filename: ${(file as File).path}');
            if (!(file as File).path.toString().contains(".DS_Store") &&
                !(file as File).path.toString().contains("README.md")) {
              file.deleteSync();
            }
          } else {
            file.deleteSync();
          }
        });

        final readmeFile = File('${ Directory('Apple Certificates').path}/README.md');

        readmeFile.writeAsStringSync('''
            <please put your Development and distribution related certificates here>        
            ''');

        if(await Directory('firebaseCertificate').exists()) {
          var firebasefilelist = Directory('firebaseCertificate').listSync();
          firebasefilelist.forEach((file) {
            if (file is File) {
              print('filename: ${(file as File).path}');
              if (!(file as File).path.toString().contains(".DS_Store") &&
                  !(file as File).path.toString().contains("README.md")) {
                file.deleteSync();
              }
            } else {
              file.deleteSync();
            }
          });
        } else {
          await  Directory('firebaseCertificate').create(recursive: true);
        }

        final readmeFirebase = File('${ Directory('firebaseCertificate').path}/README.md');

        readmeFirebase.writeAsStringSync('''
            <please put your Firebase related documents here>        
            ''');

        var keystorefilelist = Directory('Keystore').listSync();
        if( keystorefilelist.length !=0) {
          keystorefilelist.forEach((file) {
            if (file is File) {
              String keyfilepath = (file as File).path.toString();
              print('keystorefilelist: ${keyfilepath}');
              if (!keyfilepath.contains(".DS_Store") &&
                  !keyfilepath.contains("README.md")) {
                file.deleteSync();
              } else if (keyfilepath.contains("README.md")) {
                file.writeAsStringSync(
                    '''key password: KEY_PASSWORD\nkey alias: KEY_ALIAS\nkeystore password: KEY_STORE_PASSWORD''');
              }
            } else {
              file.deleteSync();
            }
          });
        } else {
          final file = File('Keystore/README.md');
          await file.create(recursive: true);
          file.writeAsStringSync(
              '''key password: KEY_PASSWORD\nkey alias: KEY_ALIAS\nkeystore password: KEY_STORE_PASSWORD''');
        }

        final iosfile = File('ios/GoogleService-Info.plist');

        if (await iosfile.exists()) {
          await iosfile.delete();
        }

        final file = File('android/key.properties');

        if (await file.exists()) {
          await file.delete();
        }

        await file.create(recursive: true);

        const content = '''
keyPassword: KEY_PASSWORD
keyAlias: KEY_ALIAS
storePassword: KEY_STORE_PASSWORD
storeFile=./keystore.jks
''';

        await file.writeAsString(content);

        String keystorejksfilepath = 'android/app/keystore.jks';
        if(File(keystorejksfilepath).existsSync())
          File(keystorejksfilepath).deleteSync();

        String firebaseoptionpath = 'ios/firebase_app_id_file.json';
        Map<String, String> firebaseoptionmap = {};
        firebaseoptionmap['GOOGLE_APP_ID'] =
        '"GOOGLE_APP_ID": "GOOGLE_APP_ID",';
        firebaseoptionmap['FIREBASE_PROJECT_ID'] =
        '"FIREBASE_PROJECT_ID": "FIREBASE_PROJECT_ID",';
        firebaseoptionmap['GCM_SENDER_ID'] =
        '"GCM_SENDER_ID": "GCM_SENDER_ID" \n }';
        AppEnv.replaceLine(filePath: firebaseoptionpath,
            oldLineContent: '',
            replaceableString: '',
            replaceableContentMap: firebaseoptionmap);

        File  googleinfoPlistFile = File('ios/Runner/GoogleService-Info.plist');
        if(googleinfoPlistFile.existsSync())
          googleinfoPlistFile.deleteSync();

        logger.stdout("google-services.json file is missing");
      }
      return _flutterConstFile;
    }
    await _flutterConstFile!.create(recursive: true);
    await init(data: data, envHandler: envHandler);
    return null;
  }

  Future<void> _modifyString(Map<String, String> data) async {
    try {
      await removeBlockComments(_flutterConstFile!);
      for (var key in data.keys) {
        if (!key.contains('_VERSION') && !key.contains('APP_COLOR_') && !key.contains('IPHONEOS')) {

          AppEnv.replaceLine(filePath: _flutterConstFile!.path,
              oldLineContent:'String ${key}',
              replaceableString: 'String ${key} = \'${data[key]}\';');

        } else if (key.contains('APP_COLOR_PRIMARY')) {
          AppEnv.replaceLine(filePath: colorsFile!.path,
              oldLineContent: 'Color lightPrimaryColor',
              replaceableString: '\t static const Color lightPrimaryColor = Color(0xFF${data[key]});');
        } else if (key.contains('APP_COLOR_SECONDARY')) {
          AppEnv.replaceLine(filePath: colorsFile!.path,
              oldLineContent: 'Color lightsecondaryColor',
              replaceableString: '\t static const Color lightsecondaryColor = Color(0xFF${data[key]});');
        }
      }
    } catch (_) {}
  }

  Future<void> _updateAndroidConfig() async {

  }

  Future<void> _updateIOSConfig() async {
    String serviceinfoPath = 'ios/Runner/GoogleService-Info.plist';
    if (!File(serviceinfoPath).existsSync()) return;

    _document = XmlDocument.parse(File(serviceinfoPath).readAsStringSync());
    Map<String, String> plist = parsePlist();

    Map<String, String> firebaseoptionmap = {};
    firebaseoptionmap['GOOGLE_APP_ID'] = '"GOOGLE_APP_ID": "${plist['GOOGLE_APP_ID']}",';
    firebaseoptionmap['FIREBASE_PROJECT_ID'] = '"FIREBASE_PROJECT_ID": "${plist['PROJECT_ID']}",';
    firebaseoptionmap['GCM_SENDER_ID'] = '"GCM_SENDER_ID": "${plist['GCM_SENDER_ID']}" \n }';
    AppEnv.replaceLine(filePath: 'ios/firebase_app_id_file.json',
        oldLineContent: '',
        replaceableString: '',
        replaceableContentMap: firebaseoptionmap);
  }

  Map<String, String> parsePlist() {
    final dict = _document!.findAllElements('dict').first;
    final elements = dict.children.whereType<XmlElement>().toList();

    Map<String, String> data = {};
    for (int i = 0; i < elements.length; i += 2) {
      if (i + 1 < elements.length) {
        String key = elements[i].innerText;
        var valueElement = elements[i + 1];
        if (valueElement.name.local == 'string') {
          data[key] = valueElement.innerText;
        } else if (valueElement.name.local == 'integer') {
          data[key] = (int.tryParse(valueElement.innerText) ?? 0).toString();
        } else if (valueElement.name.local == 'true') {
          data[key] = true.toString();
        } else if (valueElement.name.local == 'false') {
          data[key] = false.toString();
        }
      }
    }
    return data;
  }

}
