import 'dart:io';

import 'package:cli_util/cli_logging.dart';

class IOSConfigHandler {
  File? _file;
  String? _filePath;
  Logger logger = Logger.standard();
  IOSConfigHandler(String filePath) {
    _filePath = filePath;
  }

  Future<void> _checkFileExistOrCreate() async {
    _file = File(_filePath!);
    final bool fileIsExists = _file!.existsSync();

    if (fileIsExists) return;
  }
  Future<void> modify(String content) async {
    await _checkFileExistOrCreate();
    String fileContent = await _file!.readAsString();
    content =  content.replaceAll('//', '/\$()/');


    const excludedKeys = {
      'GOOGLE_PAY_MERCHANT_ORGANIZATION',
      'GOOGLE_PAY_MERCHANT_ID',
      'APP_COLOR_PRIMARY',
      'APP_COLOR_SECONDARY',
      'PLATFORM_NAME'
    };

    final filteredContent = content
        .split('\n')
        .where((line) {
      final key = line.split('=').first.trim();
      return !excludedKeys.contains(key);
    }).join('\n');

    final buffer = StringBuffer()
      ..writeln(iOSConfigFileContent)
      ..writeln('PRODUCT_BUNDLE_IDENTIFIER = \$(PACKAGE_NAME)')
      ..writeln(filteredContent);

    await _file!.writeAsString(buffer.toString());
  }
  Future<void> update(String content) async {
    await _checkFileExistOrCreate();
    String fileContent = await _file!.readAsString();
    logger.stdout("reverseclientid:${content}");
    fileContent = '$fileContent$content';
    _file!.writeAsString(fileContent);
  }
}

const iOSConfigFileContent = '''
#include "Flutter/Generated.xcconfig"
''';
