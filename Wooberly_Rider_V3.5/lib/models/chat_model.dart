import 'package:get/get.dart';

class ChatMessage {
  String? message;
  String? audio;
  String? messageType;
  String? userTypeId;
  String? time;
  String? picture;
  int? voiceDuration;
  String? audioLangCode;
  String? audioLangName;
  RxBool isTranscribeMsgExpand = false.obs;
  String? originalText;
  ChatMessage({this.message, this.userTypeId, this.time, this.picture, this.messageType, this.voiceDuration, this.audio, this.audioLangCode, this.audioLangName, this.originalText});
}