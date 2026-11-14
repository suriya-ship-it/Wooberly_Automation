import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:customization/customization.dart';


class FlutterRenameSteps {
  File? _flutterPubSpecFile;
  Logger logger = Logger.standard();

  FlutterRenameSteps(String filePath) {
    _flutterPubSpecFile = File(filePath);
  }
  Future<void> process(String appname, {required String packagename}) async {
    final bool fileIsExists = _flutterPubSpecFile!.existsSync();
    if (fileIsExists) {
      final content =await  _flutterPubSpecFile!.readAsStringSync();
      var reg = RegExp('name: (.*)', caseSensitive: true, multiLine: false);
      var oldname = reg.firstMatch(content)!.group(1);
      print('FLutter package change: ${oldname} --- ${appname}');
      String  updatedcontents = content!.replaceFirstMapped(oldname!, (m) {return '${appname.replaceAll(' ', '_').toLowerCase()}';});

      var reg2 = RegExp('A (.*) Flutter project', caseSensitive: true, multiLine: false);
      var oldprojname = reg2.firstMatch(content)!.group(1);
        updatedcontents = updatedcontents!.replaceFirstMapped(oldprojname!, (m) {return '${appname}';});
        _flutterPubSpecFile!.writeAsStringSync(updatedcontents!.trim(), );

     changeImportPackageName(directory: 'lib/', oldname: 'package:${oldname}/',newName:   'package:${appname.replaceAll(' ', '_').toLowerCase()}/' );
    //   var _buildFile = File('build.yaml');
    //   final buildcontent = _buildFile.readAsStringSync();

      // String buildupdatedcontents = buildcontent!.replaceAll(oldname,appname.replaceAll(' ', '_').toLowerCase());
      // _buildFile!.writeAsStringSync(buildupdatedcontents!.trim(),);
      // await AppEnv.checkAndChangeContent(filePath: "lib/screens/views/auth/login/login.dart",regexStr: 'clientId: \'(.*)\',',replaceableString:packagename ?? '',isReplaceAll: true  );
    }
  }


  void changeImportPackageName({required String directory, required String oldname, required String newName, }) {
    var filelist =  Directory(directory).listSync();
    filelist.forEach((file){
       if (file is File) {
         if(!(file as File).path.toString().contains(".DS_Store")) {
           final content = file.readAsStringSync();
           String updatedcontents = content!.replaceAll(oldname!,newName);
           file!.writeAsStringSync(updatedcontents!.trim(),);
         }
       } else {
         changeImportPackageName(directory: file.path, oldname: oldname, newName: newName);
       }
    });

  }


}


