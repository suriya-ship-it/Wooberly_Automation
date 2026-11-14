part of 'package:wooberly_driver/controller/home_controllers/map_main_controller/map_main_controller.dart';


extension UploadVoiceChat on MapMainController {

  Future<String> uploadMultipart(File imageFile, String uploadURL,int voiceDuration, Function? onNewVoice, String targetAILang) async {
    voiceChatLoading.value = true;

    var stream = new http.ByteStream(imageFile.openRead());
    stream.cast();
    var length = await imageFile.length();
    String ext = imageFile.path
        .split(".")
        .last;

    print("fileType--> $ext");

    var uri = Uri.parse(uploadURL);

    Map<String, String> headers = {"auth": globals.authToken!};

    var request = new CloseableMultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path)
    );
    request.files.add(multipartFile);
    request.fields["bookingId"] = bookingID.toString();
    request.fields["targetLanguage"] = targetAILang;
    request.fields["platformSecretKey"] = globals.SECURE_API_KEY;
    request.fields["originalAudioLanguage"] = globals.aiPreferredLanguage;
    request.fields["voiceDuration"] = voiceDuration.toString();
    request.headers.addAll(headers);

    http.Response response;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        response = await http.Response.fromStream(await request.send());
      } else {
        voiceChatLoading.value = false;
        isVoiceRecorderValue.value = false;
        return "Offline";
      }
      final _result = json.decode(response.body);
      if (_result['status'] == 200) {
        ChatMessage chatmessage = ChatMessage(
          message: _result['message'],
          messageType: _result['messageType'],
          audio: _result['audioName'],
          userTypeId: _result['authorId'],
          voiceDuration: voiceDuration*1000,
          time: DateFormat("hh:mm a").format(DateTime.now()),
        );
        if(onNewVoice !=null)
          onNewVoice(chatmessage);
        voiceChatLoading.value = false;
        isVoiceRecorderValue.value = false;
        return "";
      } else {
        voiceChatLoading.value = false;
        isVoiceRecorderValue.value = false;
        return _result["errorMessage"] ?? _result["error"];
      }
    } on SocketException catch (_) {
      voiceChatLoading.value = false;
      isVoiceRecorderValue.value = false;
      return "Offline";
    } on Exception catch (_) {
      voiceChatLoading.value = false;
      isVoiceRecorderValue.value = false;
      return "Offline";
    }
  }
}