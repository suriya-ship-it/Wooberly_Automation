import 'dart:async';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:image/image.dart' as img;
import 'package:customization/helpers/android_xml_helper.dart';
import 'package:customization/helpers/env_helper.dart';
import 'package:customization/helpers/flutter_const_helper.dart';
import 'package:customization/helpers/flutter_lang_helper.dart';
import 'package:customization/helpers/ios_config_helper.dart';
import 'package:customization/package_changes/android_rename_steps.dart';
import 'package:customization/package_changes/flutter_rename_steps.dart';
import 'package:customization/package_changes/ios_rename_steps.dart';


class AppEnv {
  static String get _stringXml => 'android/app/src/main/res/values/strings.xml';

  static String get _appgradle => 'android/app/build.gradle.kts';

  static String get _iOSConfig => 'ios/Flutter/AppEnvConfig.xcconfig';

  static String get _flutterConfig => 'lib/utils/globals.dart';

  static String get _flutterAppColorConfig => 'lib/resources/values/app_colors.dart';

  static String get _flutterPubSpecConfig => 'pubspec.yaml';
  static Logger logger = Logger.standard();


  static Future<void> process(String envFileName) async {
    final EnvHandler env = EnvHandler(envFileName);
    final String envFilePath = await env.fileContent;

    final Map<String, String> data = await env.extract();

    logger.stdout("datamessage: ${data['PACKAGE_NAME']}");
    if (data['PACKAGE_NAME'] != null) {
      String? newpackageName = data['PACKAGE_NAME'];
      await AndroidRenameSteps(newpackageName!, _appgradle, data: data)
          .process();
      await IosRenameSteps(newpackageName).process();
      if (data['APP_NAME'] != null)
        await FlutterRenameSteps(_flutterPubSpecConfig).process(
            data['APP_NAME'] ?? '', packagename: newpackageName,appversion: formatAppVersion (data['APP_VERSION'] ?? '1.0'));
      data.remove('PACKAGE_NAME');
    }

    await AndroidXMLHandler(_stringXml, _appgradle).init(
        data: data, envHandler: env);
    await IOSConfigHandler(_iOSConfig).modify(envFilePath);
    await FlutterConstHandler(_flutterConfig, _flutterAppColorConfig).init(
        data: data, envHandler: env);

    await Future.delayed(const Duration(milliseconds: 3000));
    Process.runSync('flutter', ['pub', 'get'], runInShell: true);
  }

  static String formatAppVersion(String input) {
    RegExp threePartVersion = RegExp(r'\d+\.\d+\.\d+');
    if (threePartVersion.hasMatch(input)) {
      return input;
    } else {
      return '$input.0';
    }
  }


  static Future<void> addLang(String key, String value) async {
    logger.stdout("message: ${key}---${value}");
    final EnvHandler env = EnvHandler(key);
    String _langConfig = 'lib/resources/app_lang.dart';
    Map<String, String>? data = {};
    data[key] = value;
    await FlutterLangHandler(_langConfig).init(data: data, envHandler: env);
  }

  static Future<String?> checkAndChangeContent(
      {required String filePath, required String regexStr, required String replaceableString, bool? isReplaceAll = false, bool isRegexEnable = true }) async {
    File file = File(filePath);
    String contents = file.readAsStringSync();
    String? oldname;
    if (isRegexEnable) {

      var reg = RegExp(regexStr, caseSensitive: true, multiLine: false);
      oldname = reg.firstMatch(contents!)!.group(1);
    } else {
      oldname = regexStr;
    }
    logger.stdout("message: gradle file ${oldname} -- ${replaceableString} --- ${filePath}");
    String replacingcontents = '';
    if (isReplaceAll != null && isReplaceAll) {
      replacingcontents = contents.replaceAll(oldname!, replaceableString);
    } else {
      replacingcontents = contents.replaceFirstMapped(oldname!, (m) {
        return replaceableString;
      });
    }
    file.writeAsStringSync(replacingcontents);
    return oldname;
  }

  static replaceLine(
      {required String filePath, required String oldLineContent, required String replaceableString, Map<
          String,
          String>? replaceableContentMap, String updatedString =''}) {
    var gradleFile = File(filePath);
    List<String> lines = gradleFile.readAsLinesSync();
    List<String> updatedLines = [];

    if (replaceableContentMap != null && replaceableContentMap.isNotEmpty) {
      for (String line in lines) {
        for (String key in replaceableContentMap.keys) {
          if (!line.contains(key)) {
            updatedLines.add(line);
            break;
          } else {
            updatedLines.add(replaceableContentMap[key] ?? '');
            replaceableContentMap.remove(key);
            break;
          }
        }
      }
    } else {
      String type ='';
      for (String line in lines) {
        if (!line.contains(oldLineContent)) {
          if(line.contains('static const FirebaseOptions android')){
            type = 'android';
          }else if(line.contains('static const FirebaseOptions ios')){
            type = 'ios';
          }
          updatedLines.add(line);
        } else {
          if(updatedString.isNotEmpty &&  type == 'android')
            updatedLines.add(updatedString);
          else
          updatedLines.add(replaceableString);

        }
      }
    }
    gradleFile.writeAsStringSync(updatedLines.join('\n'));
  }


  static Future<void> updateKeystore(String keystorefilepath) async {
    File sourceFile = File(keystorefilepath);

    if (!sourceFile.existsSync()) {
      print("❌ File does not exist: ${keystorefilepath}");
      return;
    }

    String destinationPath = "Keystore/keystore.jks";
    String destinationPath1 = "android/app/keystore.jks";

    try {
      // Copy the file
      sourceFile.copySync(destinationPath);
      sourceFile.copySync(destinationPath1);
      print("Enter the Keystore password:");
      String? keystorepassword = stdin.readLineSync();
      print("Enter the Key password:");
      String? keypassword = stdin.readLineSync();
      print("Enter the Key Alias:");
      String? keyalias = stdin.readLineSync();
      print("✅ File copied successfully to: ${keystorepassword} - ${keypassword} ---- ${keyalias}");

      String keystorefilepath = 'android/key.properties';
      String keystorefilepath2 = 'Keystore/README.md';
      Map<String, String> replacemap = {};
      replacemap['storePassword='] = 'storePassword= ${keystorepassword}';
      replacemap['keyPassword='] = 'keyPassword= ${keypassword}';
      replacemap['keyAlias='] = 'keyAlias= ${keyalias}';
      replacemap['storeFile='] = 'storeFile= ./keystore.jks';
      AppEnv.replaceLine(filePath: keystorefilepath,
          oldLineContent: '',
          replaceableString: '',
          replaceableContentMap: replacemap);

      Map<String, String> replacemap2 = {};
      replacemap2['key password:'] = 'key password: ${keypassword}';
      replacemap2['alias:'] = 'key alias: ${keyalias}';
      replacemap2['keystore password:'] =
      'keystore password: ${keystorepassword}';

      AppEnv.replaceLine(filePath: keystorefilepath2, oldLineContent: '', replaceableString: '',replaceableContentMap: replacemap2);


    } catch (e) {
      print("❌ Error copying file: $e");
    }
  }

  static Future<void> createKeystore() async {
    print("Enter the Keystore password:");
    String? keystorepassword = stdin.readLineSync();
    if (keystorepassword == null || keystorepassword.isEmpty) {
      print("❌ Keystore password cannot be empty");
      return;
    }

    print("Enter the Key password:");
    String? keypassword = stdin.readLineSync();
    if (keypassword == null || keypassword.isEmpty) {
      print("❌ Key password cannot be empty");
      return;
    }

    print("Enter the Key Alias:");
    String? keyalias = stdin.readLineSync();
    if (keyalias == null || keyalias.isEmpty) {
      print("❌ Key Alias cannot be empty");
      return;
    }

    print("Enter First and Last Name (CN):");
    String? cn = stdin.readLineSync();
    if (cn == null || cn.isEmpty) cn = 'Unknown';

    print("Enter Organizational Unit (OU):");
    String? ou = stdin.readLineSync();
    if (ou == null || ou.isEmpty) ou = 'Unknown';

    print("Enter Organization (O):");
    String? o = stdin.readLineSync();
    if (o == null || o.isEmpty) o = 'Unknown';

    print("Enter City or Locality (L):");
    String? l = stdin.readLineSync();
    if (l == null || l.isEmpty) l = 'Unknown';

    print("Enter State or Province (ST):");
    String? st = stdin.readLineSync();
    if (st == null || st.isEmpty) st = 'Unknown';

    print("Enter Country Code (XX):");
    String? c = stdin.readLineSync();
    if (c == null || c.isEmpty) c = 'Unknown';

    String dname = 'CN=$cn, OU=$ou, O=$o, L=$l, ST=$st, C=$c';
    String tempKeystorePath = 'temp_keystore.jks';

    try {
      if (File(tempKeystorePath).existsSync()) {
        File(tempKeystorePath).deleteSync();
      }

      var result = Process.runSync('keytool', [
        '-genkey',
        '-v',
        '-keystore', tempKeystorePath,
        '-alias', keyalias,
        '-keyalg', 'RSA',
        '-keysize', '2048',
        '-validity', '25000',
        '-storepass', keystorepassword,
        '-keypass', keypassword,
        '-dname', dname
      ]);

      if (result.exitCode != 0) {
        print("❌ Error generating keystore: ${result.stderr}");
        return;
      }

      String destinationPath = "keystore/keystore.jks";
      String destinationPath1 = "android/app/keystore.jks";

      File(tempKeystorePath).copySync(destinationPath);
      File(tempKeystorePath).copySync(destinationPath1);
      File(tempKeystorePath).deleteSync();

      print("✅ Keystore generated successfully.");

      String keystorefilepath = 'android/key.properties';
      String keystorefilepath2 = 'keystore/README.md';

      Map<String, String> replacemap = {};
      replacemap['storePassword='] = 'storePassword=$keystorepassword';
      replacemap['keyPassword='] = 'keyPassword=$keypassword';
      replacemap['keyAlias='] = 'keyAlias=$keyalias';
      replacemap['storeFile='] = 'storeFile=./keystore.jks';
      AppEnv.replaceLine(filePath: keystorefilepath,
          oldLineContent: '',
          replaceableString: '',
          replaceableContentMap: replacemap);

      Map<String, String> replacemap2 = {};
      replacemap2['key password:'] = 'key password: $keypassword';
      replacemap2['alias:'] = 'alias: $keyalias';
      replacemap2['keystore password:'] = 'keystore password: $keystorepassword';

      AppEnv.replaceLine(filePath: keystorefilepath2, oldLineContent: '', replaceableString: '', replaceableContentMap: replacemap2);

    } catch (e) {
      print("❌ Error: $e");
    }
  }

  static Future<void> createAppIcon() async {
    File sourceFile = File('app_images/app_icon.png');
    if (!sourceFile.existsSync()) {
      print("❌ app_images/app_icon.png not found.");
      return;
    }

    img.Image? sourceImage = img.decodeImage(sourceFile.readAsBytesSync());
    if (sourceImage == null) {
      print("❌ Failed to decode app_icon.png.");
      return;
    }

    // Ensure the image has an alpha channel
    if (sourceImage.numChannels != 4) {
      sourceImage = sourceImage.convert(numChannels: 4);
    }

    // ── Prompt user for adaptive icon content scale ──────────────────────────
    double adaptiveScale = 0.66; // default
    while (true) {
      stdout.write(
        '\n🎯 Android Adaptive Icon — content scale\n'
        '   The foreground image is placed on a canvas.\n'
        '   Android safe zone is ~66 %. Enter 100 to fill the full canvas.\n'
        '\n'
        '   Enter content percentage (10 – 100) [default: 66]: ',
      );
      final String? input = stdin.readLineSync()?.trim();

      // Accept empty input → use default
      if (input == null || input.isEmpty) {
        adaptiveScale = 0.66;
        print('   ℹ️  Using default: 66 %');
        break;
      }

      final double? parsed = double.tryParse(input);
      if (parsed == null || parsed < 10 || parsed > 100) {
        print('   ❌ Invalid input. Please enter a number between 10 and 100.');
        continue;
      }

      adaptiveScale = parsed / 100.0;
      print('   ✅ Using content scale: ${parsed.toStringAsFixed(0)} %');
      break;
    }
    // ─────────────────────────────────────────────────────────────────────────

    List<String> targetDirs = [
      'android/app/src/main/res/mipmap-mdpi',
      'android/app/src/main/res/mipmap-hdpi',
      'android/app/src/main/res/mipmap-xhdpi',
      'android/app/src/main/res/mipmap-xxhdpi',
      'android/app/src/main/res/mipmap-xxxhdpi',
      'android/app/src/main/res/mipmap_mdpi',
      'android/app/src/main/res/mipmap_hdpi',
      'android/app/src/main/res/mipmap_xhdpi',
      'android/app/src/main/res/mipmap_xxhdpi',
      'android/app/src/main/res/mipmap_xxxhdpi',
      'ios/Assets.xcassets/AppIcon.appiconset',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    ];

    print('');
    for (String dirPath in targetDirs) {
      Directory dir = Directory(dirPath);
      if (dir.existsSync()) {
        List<FileSystemEntity> files = dir.listSync();
        for (FileSystemEntity file in files) {
          if (file is File &&
              file.path.toLowerCase().endsWith('.png') &&
              !file.path.toLowerCase().endsWith('_round.png')) {
            _replaceImage(sourceImage, file, true, adaptiveScale: adaptiveScale);
          }
        }
      }
    }

    // ── iOS LaunchImage: generate at exact fixed sizes ────────────────────────
    // 1x = 58×58, 2x = 114×114, 3x = 180×180
    final List<Map<String, dynamic>> iosLaunchSizes = [
      {'filename': 'LaunchImage.png',    'size': 58},
      {'filename': 'LaunchImage@2x.png', 'size': 114},
      {'filename': 'LaunchImage@3x.png', 'size': 180},
    ];

    final List<String> iosLaunchDirs = [
      'ios/Assets.xcassets/LaunchImage.imageset',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset',
    ];

    for (final String launchDir in iosLaunchDirs) {
      final Directory dir = Directory(launchDir);
      if (dir.existsSync()) {
        for (final Map<String, dynamic> entry in iosLaunchSizes) {
          final int size = entry['size'] as int;
          final File outFile = File('$launchDir/${entry['filename']}');
          final img.Image resized = img.copyResize(
            sourceImage,
            width: size,
            height: size,
            interpolation: img.Interpolation.average,
          );
          final img.Image circleResized = _makeCircleIcon(resized);
          outFile.writeAsBytesSync(img.encodePng(circleResized));
          print('Updated ${outFile.path} ($size x $size) (Circle)');
        }
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

    print('\n✅ App icons created successfully.');
  }

  /// [adaptiveScale] controls how much of the canvas the content fills for
  /// ic_launcher_foreground.png (0.10 – 1.00). Transparent padding fills the rest.
  static void _replaceImage(
    img.Image sourceImage,
    File targetFile,
    bool generateRound, {
    double adaptiveScale = 0.66,
  }) {
    try {
      img.Image? targetImage = img.decodeImage(targetFile.readAsBytesSync());
      if (targetImage != null) {
        int width = targetImage.width;
        int height = targetImage.height;

        // If placeholder is 1x1 (like in some LaunchImage placeholders), use original size
        if (width == 1 && height == 1) {
          width = sourceImage.width;
          height = sourceImage.height;
        }

        img.Image finalImage;

        final bool isForeground =
            targetFile.path.toLowerCase().endsWith('ic_launcher_foreground.png');

        if (isForeground) {
          // The foreground layer of an Android adaptive icon is placed on a canvas
          // that is larger than the visible area. The content must be scaled down
          // so transparent padding surrounds it — preventing the OS mask from clipping it.
          final double scale = adaptiveScale.clamp(0.10, 1.00);
          final int contentW = (width * scale).round();
          final int contentH = (height * scale).round();
          final int offsetX = ((width - contentW) / 2).round();
          final int offsetY = ((height - contentH) / 2).round();

          // Create a fully transparent canvas
          finalImage = img.Image(width: width, height: height, numChannels: 4);
          img.fill(finalImage, color: img.ColorRgba8(0, 0, 0, 0));

          // Resize source to the inner content area
          img.Image content = img.copyResize(
            sourceImage,
            width: contentW,
            height: contentH,
            interpolation: img.Interpolation.average,
          );
          if (content.numChannels != 4) {
            content = content.convert(numChannels: 4);
          }

          // Composite content centered on the transparent canvas
          img.compositeImage(finalImage, content, dstX: offsetX, dstY: offsetY);
        } else {
          finalImage = img.copyResize(
            sourceImage,
            width: width,
            height: height,
            interpolation: img.Interpolation.average,
          );
          if (finalImage.numChannels != 4) {
            finalImage = finalImage.convert(numChannels: 4);
          }
        }

        targetFile.writeAsBytesSync(img.encodePng(finalImage));
        print('Updated ${targetFile.path} ($width x $height)');

        if (generateRound && targetFile.path.contains('mipmap')) {
          String roundPath = '';
          if (targetFile.path.endsWith('ic_launcher.png')) {
            roundPath = targetFile.path.replaceAll(
                'ic_launcher.png', 'ic_launcher_round.png');
          } else if (targetFile.path.endsWith('ic_launcher_foreground.png')) {
            roundPath = targetFile.path.replaceAll(
                'ic_launcher_foreground.png', 'ic_launcher_round.png');
          }

          if (roundPath.isNotEmpty) {
            // ic_launcher_round.png uses the same padded foreground image.
            // Android applies the round mask at runtime.
            File roundFile = File(roundPath);
            img.Image roundImg = _makeCircleIcon(finalImage);
            roundFile.writeAsBytesSync(img.encodePng(roundImg));
            print('Updated ${roundFile.path} ($width x $height) (Round)');
          }
        }
      }
    } catch (e) {
      print('❌ Error replacing ${targetFile.path}: $e');
    }
  }

  /// Creates a circular icon by masking pixels outside the circle to fully transparent.
  /// Pixels inside the circle are fully opaque (alpha=255), outside fully transparent.
  static img.Image _makeCircleIcon(img.Image src) {
    final int w = src.width;
    final int h = src.height;
    final double cx = w / 2.0;
    final double cy = h / 2.0;
    final double radius = (w < h ? w : h) / 2.0;
    final double radiusSq = radius * radius;

    // Create a fully transparent output canvas
    img.Image result = img.Image(width: w, height: h, numChannels: 4);
    img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final double dx = x - cx + 0.5;
        final double dy = y - cy + 0.5;
        final double distSq = dx * dx + dy * dy;
        if (distSq <= radiusSq) {
          final pixel = src.getPixel(x, y);
          // Force alpha=255: source PNG may have alpha=0 after RGB→RGBA conversion
          result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255);
        }
        // else: stays fully transparent (0,0,0,0)
      }
    }
    return result;
  }

}



