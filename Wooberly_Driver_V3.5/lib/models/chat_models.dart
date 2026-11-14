import 'package:get/get_rx/src/rx_types/rx_types.dart';

class ChatMessage {
  String? message;
  String? userTypeId;
  String? time;
  String? picture;
  String? messageType;
  int? voiceDuration;
  String? audioName;
  String? originalText;
  String? audioLangCode;
  String? audioLangName;
  RxBool isTranscribeMsgExpand = false.obs;
  String? audio;

  ChatMessage({this.message, this.userTypeId, this.time, this.picture, this.messageType, this.voiceDuration, this.audioName, this.originalText,  this.audioLangCode, this.audioLangName, this.audio});
}