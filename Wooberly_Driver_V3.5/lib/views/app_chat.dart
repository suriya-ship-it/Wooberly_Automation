import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

import '../app/app.dart';
import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../models/chat_models.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart';
import '../widgets/ai_lang_selection_widget.dart';
import '../widgets/audio_chat/chat_voice_mesaage_widget.dart';
import '../widgets/audio_chat/chat_voice_record_widget.dart';
import '../widgets/spin_kit/three_bounce.dart';
import 'circular_reveal_animations.dart';

class AppChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppChatView();
  }
}

class AppChatView extends StatefulWidget {
  @override
  _AppChatViewState createState() => _AppChatViewState();
}

class _AppChatViewState extends State<AppChatView> with TickerProviderStateMixin, WidgetsBindingObserver {
  final MapMainController _mapMainController=Get.find();
  String firstName = "";
  int pageCount = 1;
  int totalPageCount = 1;
  bool isListLoading = false;
  FocusNode chatText = FocusNode();
  StreamController<String> riderNameController = StreamController<String>.broadcast();
  late AnimationController _animController,_animationController,_recordingPlayController;
  ChatVoiceRecordWidget? chatAudioWidget;
  late AnimationController _revealAnimationController;
  late Animation<double> _revealAnimation;
  String? _message;
  AILangSelectionWidget? aiLangSelectionWidget;
  Widget _defaultProfileWidget =  SvgPicture.asset(
    defaultProfileSvg,
    height: 34.0,
    width: 34.0,
  );

  @override
  void initState() {
    _mapMainController.chatAudioPlayer = AudioPlayer();
    globals.currentShowingPage = AppRoutes.APP_CHAT;
    WidgetsBinding.instance.addObserver(this);
    _mapMainController.getDeviceDetails();
    _mapMainController.currentlyPlayingIndex = -1;
    _mapMainController.init();

    if (!(globals.socket?.connected ?? false)) {
      App().reconnectSocket();
    }
    _mapMainController.listenChatSocket(fun: (){
      getAllThreads(isClearFirst: false);
    });

    _mapMainController.controller.addListener(() async {
      if (!isListLoading) {
        if (_mapMainController.controller.offset >=
            _mapMainController.controller.position.maxScrollExtent - 50) {
          if (pageCount <= totalPageCount && pageCount != totalPageCount) {
            isListLoading = true;
            loadMore();
          }
        }
      }
    });
    globals.isLoaderShow = false;

    Future.wait([
      getAllThreads(),
      globals.baseController.getAILanguageList(isShowLoader:  false),
      globals.baseController.getUserAILanguage(isShowLoader:  false),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_){
      globals.baseController.AILanglist.clear();
      _mapMainController.isTextEntered.value = false;
      if(globals.aiPreferredLanguage.isEmpty && aiLangSelectionWidget !=null){
        aiLangSelectionWidget!.showAILangSelectionBottomSheet(context,isDismissable: false);
      }

    });
debugPrint("authto: ${globals.authToken}");

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _mapMainController.audioPlayerFunction = AudioPlayerFunction(mapController: _mapMainController,animationController: _animController );

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _recordingPlayController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _revealAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );


    _revealAnimation = CurvedAnimation(
      parent: _revealAnimationController,
      curve: Curves.easeIn,
    );
    _mapMainController.isTextEntered.value = false;
    _mapMainController.chatController.addListener((){
      _mapMainController.isTextEntered.value = _mapMainController.chatController.text.trim().isNotEmpty;
    });

    super.initState();
  }

  sendMessageApiCall() {
    debugPrint("sendMessageApiCall: ${_message} --- ${_mapMainController.chatController.text}");
    _mapMainController.sendMessage(_message!).then((value) {
      if (value.isNotEmpty) {
        if (value == "offline") {
          _mapMainController.showInSnackBar(
              'offline_text'.tr);
        } else {
          _mapMainController.showInSnackBar(value);
        }
      }
    });
    _mapMainController.isVoiceRecorderValue.value = false;
    Future.delayed(const Duration(milliseconds: 150), () {
      getAllThreads(isClearFirst: false);
    });

  }

  Future<void> getAllThreads({bool isClearFirst = true}) async{
    if(isClearFirst) {
      _mapMainController.update(['chatLoadingController']);
      isListLoading = true;
      _mapMainController.messages.clear();
    }
    String? value  = await _mapMainController.getAllThreads(1);
    try {
      if (value == "") {
        double count = _mapMainController.threadItems!.count! / 20;
        firstName =_mapMainController.threadItems?.result?.userDetails?.profile?.firstName??"";
        riderNameController.add(firstName);
        print("riderNameController--->>> ${firstName}");
        totalPageCount = count.ceil();
        _mapMainController.messages.clear();
        Map<int,LockCachingAudioSource> audioSourcesList = {};
        Map<int,String> audioURLList = {};
        _mapMainController.threadItems?.result?.threadItems?.asMap().forEach((index,element) {

          _mapMainController.messages.add(ChatMessage(
              message: element.messageType != 'chat' && element.authorId == globals.userid ?
              element.originalText :
              element.message,
              originalText: element.originalText,
              userTypeId: element.authorId,
              time: formatDate(element.createdAt!),
              picture:
              _mapMainController.threadItems?.result?.userDetails?.profile?.picture != null &&
                  _mapMainController.threadItems?.result?.userDetails?.profile?.picture != ""
                  ? globals.UPLOAD_URL +
                  "/images/avatar/" +
                  _mapMainController.threadItems!.result!.userDetails!.profile!.picture!
                  : "",
              messageType:  element.messageType,
              voiceDuration: element.voiceDuration!=null? (element.voiceDuration!*1000): 0,
              audioLangCode: element.originalAudioLanguageCode,
              audioLangName: element.originalAudioLanguage,
              audio: element.audioName));
          debugPrint("audiourlmessageType: --- ${element.messageType} --- ${element.originalAudioLanguageCode} --- ${element.originalAudioLanguage}");
          if((element.messageType == 'audio' || element.messageType == 'translate-audio') && element.audioName !=null) {
            debugPrint("audiourl: ${'${globals.voicePlayUrl}${element.audioName}'} --- ${element.messageType}");
            LockCachingAudioSource audioSource = LockCachingAudioSource(Uri.parse(globals.voicePlayUrl+element.audioName!),tag: element.audioName );
            audioSourcesList[index] = audioSource;
            audioURLList[index] = globals.voicePlayUrl+element.audioName!;

            debugPrint(" audioSource.duration: ${ audioSource.duration} --- ${element.audioName} -- ${element.voiceDuration}");
          }
        });

        intAudioPayer(audioSourcesList,audioURLList);
        _mapMainController.update(['chatLoadingController']);

        isListLoading = false;
        if (globals.currentShowingPage == AppRoutes.APP_CHAT) {
          _mapMainController.readThreadCount();
        }
      }
      else if (value == "null") {
        getAllThreads();
      } else if (value == "Offline") {
        _mapMainController.showInSnackBar('offline_text'.tr);
      } else {
        _mapMainController.showInSnackBar(value ?? "");
      }
    } on Exception catch (e) {
      _mapMainController.showInSnackBar( "Something went wrong");
    }
    ;
  }


  Future<void>  intAudioPayer( Map<int,LockCachingAudioSource> audioSourcesList,Map<int,String> audioURLList) async{
    _mapMainController.isPlaying = List.generate(_mapMainController.messages.length, (_) => false);
    _mapMainController.progress = List.generate(_mapMainController.messages.length, (_) => 0.0);
    _mapMainController.totalMillis = List.generate(_mapMainController.messages.length, (index) => _mapMainController.messages[index].voiceDuration ?? 0);
    _mapMainController.currentMillis = List.generate(_mapMainController.messages.length, (_) => 0);
    _mapMainController.audioList.clear();
    _mapMainController.audioList.addAll(audioSourcesList);

    for (int i = 0; i < _mapMainController.messages.length; i++) {
      ChatMessage message =  _mapMainController.messages[i];
      if(Platform.isIOS && audioURLList[i] !=null && audioURLList[i]!.isNotEmpty) {
        print("_mapMainController.audioURLList[i]: ${audioURLList[i]}");
        await _mapMainController.downloadAudioFile(URL: audioURLList[i]!);
      }
      if(message.messageType == 'audio' && message.voiceDuration !=null && message.voiceDuration !=0){
        print("_mapMainController.message.voiceDuration: ${ message.voiceDuration}");
        if(Platform.isAndroid) {
          _mapMainController.totalMillis.add(message.voiceDuration!);
          _mapMainController.updateingIndex.value = i;
        }
      } else if(message.messageType == 'audio'){
        print("_mapMainController.audioSourcesList: ${ audioSourcesList}");
        if(audioSourcesList[i] !=null)
          findAudioDuration(audioSourcesList[i]!,i,audioURLList[i]);
      }
    }

    _mapMainController.update(['chatLoadingController']);
    print('StreamintAudioPayer finished.: ${ _mapMainController.totalMillis}');
  }

  Future<void> findAudioDuration( LockCachingAudioSource audioSource,int index,URL) async {
    AudioPlayer temp = AudioPlayer();
    try {
      Duration? duration;
      print('dfindAudioDurationuration.:1 ${duration} --- ${URL}');
      if(Platform.isAndroid)
        duration = await temp.setAudioSource(audioSource);
      else {
        final file  = await _mapMainController.downloadAudioFile(URL: URL);
        duration = await  temp.setAudioSource(AudioSource.file(file.path));
      }
      print('dfindAudioDurationuration.:2 ${duration}');
      _mapMainController.totalMillis[index] =  duration?.inMilliseconds ?? 0;
      _mapMainController.updateingIndex.value = index;
      await temp.dispose();
    } catch (e) {
      debugPrint("duration error: $e");
    } finally {
      await temp.dispose();
    }
  }


  loadMore() {
    Future.delayed(Duration(seconds: 2)).then((value) {
      pageCount++;

      _mapMainController.getAllThreads(pageCount).then((value) {
        debugPrint("getallthread pagination called");
        try {
          if (value == "") {
            Map<int,LockCachingAudioSource> audioSourcesList = {};
            Map<int,String> audioURLList = {};
            _mapMainController.threadItems?.result?.threadItems?.asMap().forEach((index,element) {
              _mapMainController.messages.add(ChatMessage(
                message:  element.messageType != 'chat' && element.authorId == globals.userid ?
                element.originalText :
                element.message,
                originalText: element.originalText,
                userTypeId: element.authorId,
                voiceDuration: element.voiceDuration!=null? (element.voiceDuration!*1000): 0,
                audio: element.audioName,
                time: formatDate(element.createdAt!),
                picture: _mapMainController.threadItems?.result?.userDetails?.profile?.picture !=
                    null &&
                    _mapMainController.threadItems?.result?.userDetails?.profile?.picture !=
                        ""
                    ? globals.UPLOAD_URL +
                    "/images/avatar/" +
                    _mapMainController.threadItems!.result!.userDetails!.profile!.picture!
                    : "",
                messageType: element.messageType,
                audioLangCode: element.originalAudioLanguageCode,
                audioLangName: element.originalAudioLanguage,
              ),);
              if(element.messageType == 'audio') {
                debugPrint("audiourl: ${'${globals.voicePlayUrl}${element.audioName}'}");
                LockCachingAudioSource audioSource = LockCachingAudioSource(Uri.parse('${globals.voicePlayUrl}${element.audioName}'),tag: element.audioName );
                audioSourcesList[index] = audioSource;
                audioURLList[index] = '${globals.voicePlayUrl}${element.audioName}';
                debugPrint(" audioSource.duration: ${  audioSource.duration} --- ${element.audioName}");
              }
            });

            intAudioPayer(audioSourcesList,audioURLList);

            isListLoading = false;
          } else if (value == "null") {
            pageCount--;
            loadMore();
          } else if (value == "Offline") {
            _mapMainController.showInSnackBar(
                'offline_text'.tr);
          } else {
            _mapMainController.showInSnackBar(value ?? "");
          }
        } on Exception catch (e) {
          _mapMainController.showInSnackBar( "Something went wrong");
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
          _mapMainController.blackLinearGradient = LinearGradient(
            begin: globals.isRtlLang ? Alignment.centerRight : Alignment.centerRight,
            end: globals.isRtlLang ?Alignment.centerLeft : Alignment.centerLeft,
            colors: [
              AppColors.PRIMARY_DARK_COLOR,
              AppColors.PRIMARY_DARK_COLOR,
            ],
          );
          return ColoredBox(
            color: AppColors.COMMON_BG_COLOR,
            child: SafeArea(
              child: Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: AppColors.COMMON_BG_COLOR,
                appBar: AppBar(
                  centerTitle: true,
                  title: Container(
                      padding: EdgeInsetsDirectional.only( top: 22.0),
                      child: StreamBuilder(stream: riderNameController.stream,
                          builder: (context,snapshot){
                            return Text(riderName(snapshot.data??""),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: AppDimen.text_size_18,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            );
                          })
                  ),
                  elevation: 0,
                  backgroundColor: AppColors.COMMON_BG_COLOR,
                  leading:  Container(
                    height: 50,
                    width: 50,
                    margin: EdgeInsetsDirectional.only(top: 15,start:15),
                    child: InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_WHITE, shape: BoxShape.circle),
                        child: SvgPicture.asset(
                          primaryLeftArrow,
                          matchTextDirection: true,
                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if(globals.isVoiceTranslatorEnable)
                      Builder(
                          builder: (context) {
                            aiLangSelectionWidget = AILangSelectionWidget(title: "label_user_preferred_lang".tr, tooltipcontent: "label_tooltip_app_text_lang".tr, isShowIcon: true);
                            return aiLangSelectionWidget!;
                          }
                      ),
                    InkWell(
                      onTap: () {
                        _mapMainController.checkInternet(() {
                          UrlLauncher.launchUrl(Uri.parse("tel:${_mapMainController.riderNumber}"));
                        }, false);
                      },
                      child: Padding(
                        padding: EdgeInsetsDirectional.only( end: 22,start: 20,top: globals.isRtlLang ?25 : 20),
                        child: SvgPicture.asset(
                          callIconSvg,
                          height: 20.0,
                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    )
                  ],
                ),

                body: GetBuilder<MapMainController>(
                    id: 'chatLoadingController',
                    builder: (_) {
                      debugPrint("_mapMainController.isVoiceRecorderValue.value: ${_mapMainController.isVoiceRecorderValue.value} --- ${globals.isVoiceChatEnable} ");
                      return GestureDetector(
                        onTap: () {
                          if (_mapMainController.chatController == '\s') {
                            _mapMainController.chatController.text.trim();
                          };
                          if (chatText.hasPrimaryFocus) {
                            chatText.unfocus();
                          }
                        },
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsetsDirectional.only(top: 10),
                                child:  _mapMainController.messages.length >0 ?
                                ListView.builder(
                                  controller: _mapMainController.controller,
                                  itemCount: _mapMainController.messages.length + 1,
                                  reverse: true,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  addAutomaticKeepAlives: true,
                                  itemBuilder: (BuildContext context, int index) {
                                    if (index == _mapMainController.messages.length) {
                                      if (pageCount < totalPageCount) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional.all(10.0),
                                            child: SpinKitThreeBounce(
                                              color: AppColors.PRIMARY_DARK_COLOR,
                                              size: 22.0,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    } else {
                                      debugPrint("messag23e: ${_mapMainController.messages[index].message} --- ${_mapMainController.messages[index].userTypeId ==globals.userid } ");
                                      return Padding(
                                          padding: _mapMainController.messages[index].userTypeId == globals.userid
                                              ? EdgeInsetsDirectional.only(top: 12, bottom: 12, end: 20.0, start: 30)
                                              : EdgeInsetsDirectional.only(
                                              top: 12,
                                              bottom: 12,
                                              start: 20.0,
                                              end: 50),
                                            child: _mapMainController.messages[index].userTypeId != globals.userid
                                              ? Stack(
                                            children: [
                                              Padding(
                                                padding:
                                                EdgeInsetsDirectional
                                                    .only(top: 3),
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      34.0),
                                                  child: _mapMainController
                                                      .messages[
                                                  index]
                                                      .picture !=
                                                      null &&
                                                      _mapMainController
                                                          .messages[
                                                      index]
                                                          .picture !=
                                                          ""
                                                      ? CachedNetworkImage(
                                                    height: 34,
                                                    width: 34,
                                                    fit: BoxFit.cover,
                                                    imageUrl: _mapMainController.messages[index].picture != null
                                                        ? _mapMainController.messages[index].picture! : "",
                                                    placeholder:
                                                        (context,
                                                        url) =>
                                                        _defaultProfileWidget,
                                                  )
                                                      : _defaultProfileWidget,
                                                ),
                                              ),
                                              Container(
                                                margin:
                                                EdgeInsetsDirectional
                                                    .only(
                                                  start: 20,
                                                ),
                                                child: Stack(children: [
                                                  Container(
                                                    margin:
                                                    EdgeInsetsDirectional.only(start: 8),
                                                    height: 40,
                                                    child:SvgPicture.asset(
                                                      globals.isRtlLang ? sendChatWhiteRTL : sendChatWhite,
                                                      fit: BoxFit.fill,
                                                      colorFilter: ColorFilter.mode(AppColors.APP_CHAT_COLOR, BlendMode.srcIn),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin:
                                                    EdgeInsetsDirectional
                                                        .only(
                                                        start: 18.5,
                                                        top: 0.5),
                                                    decoration: BoxDecoration(
                                                        borderRadius: BorderRadiusDirectional.only(bottomEnd: Radius.circular(8), bottomStart: Radius.circular(8), topEnd: Radius.circular(8)),
                                                        color: AppColors
                                                            .APP_CHAT_COLOR),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Padding(
                                                          padding: EdgeInsetsDirectional.only(start: 10, top: 7, end: 10),
                                                          child:

                                                          _mapMainController.messages[index].messageType == 'translate-audio' ?

                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start
                                                            ,children: [
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Padding(
                                                                  padding: const EdgeInsetsDirectional.only(end: 4.0,top: 2.0),
                                                                  child: SvgPicture.asset(
                                                                    trans_script_icon,
                                                                    height: 8,
                                                                    fit: BoxFit.fill,
                                                                    colorFilter: ColorFilter.mode(AppColors.TEXT_LINK_COLOR, BlendMode.srcIn),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "label_translated_from".tr + ' ${_mapMainController.messages[index].audioLangName}(${_mapMainController.messages[index].audioLangCode})',
                                                                  style:  TextStyle(
                                                                    color: AppColors.TEXT_LINK_COLOR,
                                                                    fontSize: AppDimen.text_size_14,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              "${_mapMainController.messages[index].message}",
                                                              style: TextStyle(
                                                                  fontSize: AppDimen.text_size_14,
                                                                  fontFamily: AppFont.font,
                                                                  color: AppColors.PRIMARY_COLOR_DARK_TRAN,
                                                                  fontWeight: FontWeight.w400),
                                                            ),
                                                          ],
                                                          ) :_mapMainController.messages[index].messageType == 'chat' ?
                                                          Text(
                                                            "${_mapMainController.messages[index].message}",
                                                            style: TextStyle(
                                                                fontSize:
                                                                AppDimen
                                                                    .text_size_14,
                                                                fontFamily:
                                                                AppFont
                                                                    .font,
                                                                color:  AppColors.PRIMARY_COLOR_DARK_TRAN,
                                                                fontWeight: FontWeight.w400),
                                                          )
                                                              : ChatVoiceMesaageWidget(index: index, mapController: _mapMainController,chatVoiceRecordWidget: chatAudioWidget,)
                                                          ,
                                                        ),
                                                        Container(
                                                            margin:  EdgeInsetsDirectional.only(end: 7, bottom: 3, top: 5),
                                                            alignment: AlignmentDirectional.bottomEnd,
                                                            child: Text(
                                                              "${_mapMainController.messages[index].time}",
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.w400,
                                                                  color: AppColors.SEARCH_TEXT_COLOR,
                                                                  fontFamily: AppFont.font,
                                                                  fontSize: AppDimen.text_size_10),
                                                            ))
                                                      ],
                                                    ),
                                                  ),
                                                ]),
                                              )
                                            ],
                                          )
                                              : Stack(
                                            alignment:
                                            AlignmentDirectional.topEnd,
                                            children: [
                                              Padding(
                                                padding:
                                                EdgeInsetsDirectional
                                                    .only(top: 3),
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      34.0),
                                                  child: globals.picture != ""
                                                      ? CachedNetworkImage(
                                                    height: 34.0,
                                                    width: 34.0,
                                                    fit: BoxFit.cover,
                                                    imageUrl: globals.picture,
                                                    placeholder:
                                                        (context,
                                                        url) =>
                                                        _defaultProfileWidget,
                                                  )
                                                      : _defaultProfileWidget,
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsetsDirectional.only(end: 25, start: 20),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      margin: globals.isRtlLang
                                                          ? EdgeInsetsDirectional
                                                          .only(
                                                          start:
                                                          11.6)
                                                          : EdgeInsetsDirectional
                                                          .only(
                                                          start:
                                                          13.3),
                                                      height: 50,
                                                      alignment: AlignmentDirectional.centerEnd,
                                                      child:SvgPicture.asset(
                                                        globals.isRtlLang ?  sendChatWhite : sendChatWhiteRTL,
                                                        fit: BoxFit.fill,
                                                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                                                      ),

                                                    ),
                                                    Container(
                                                      margin:
                                                      EdgeInsetsDirectional.only(end: 15, top: 0.5),
                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                                                          color: AppColors.PRIMARY_LIGHT_COLOR),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .start,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          Padding(
                                                            padding: EdgeInsetsDirectional
                                                                .only(start: 8, top: 7, end: 10),
                                                            child:
                                                            _mapMainController.messages[index].messageType == 'chat' ?
                                                            Text(
                                                              "${_mapMainController.messages[index].message}",
                                                              style: TextStyle(
                                                                  fontSize: AppDimen.text_size_14,
                                                                  fontFamily: AppFont.font,
                                                                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                                                            )
                                                                : ChatVoiceMesaageWidget(index: index, mapController: _mapMainController,chatVoiceRecordWidget: chatAudioWidget,),
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsetsDirectional.only(end: 8, bottom: 3, top: 8),
                                                            child:
                                                            Container(
                                                              alignment: AlignmentDirectional.bottomEnd,
                                                              child:
                                                              Text(
                                                                "${_mapMainController.messages[index].time}",
                                                                style: TextStyle(
                                                                    color: AppColors.HIND_TEXT_COLOR,
                                                                    fontFamily: AppFont.font,
                                                                    fontSize: AppDimen.text_size_10),
                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          )
                                      );
                                    }
                                  },
                                ) :  const SizedBox.shrink(),
                              ),
                            ),
                            Obx(() {
                              chatAudioWidget =   ChatVoiceRecordWidget(
                                  mapController: _mapMainController,
                                  animationController: _animationController,
                                  recordingPlayController: _recordingPlayController,
                                  onStop: () {
                                    if (_revealAnimationController.status != AnimationStatus.dismissed) {
                                      _revealAnimationController.reverse();
                                    }
                                  },
                                  onNewVoice: addNewVoice);
                              debugPrint("_mapMainController.isVoiceRecorderValue.value: obx ${_mapMainController.isVoiceRecorderValue.value} --- ${globals.isVoiceChatEnable} ");
                              return _mapMainController.isVoiceRecorderValue.value ?
                              CircularRevealAnimation(
                                  animation: _revealAnimation,
                                  centerOffset: Offset(
                                      globals.isRtlLang ? 30 : MediaQuery.of(context).size.width - 85,
                                      25),
                                  child: chatAudioWidget ?? const SizedBox.shrink())
                                  : buildMessageTextField();
                            }
                            ),
                          ],
                        ),
                      );
                    }),
              ),
            ),
          );
        });
  }

  addNewVoice(ChatMessage chatmessage){
    debugPrint("onNewVoice: obx ${chatmessage.voiceDuration} --- ${chatmessage.message} --- ${chatmessage.audio} ");
    _mapMainController.messages.insert(0, chatmessage);
    _mapMainController.update(['chatLoadingController']);
    LockCachingAudioSource audioSource = LockCachingAudioSource(
        Uri.parse('${globals.voicePlayUrl}${chatmessage.audio}'),
        tag: chatmessage.audio);
    Map<int,LockCachingAudioSource> map = {};
    Map<int,String> urlmap = {};
    map[0] = audioSource;
    urlmap[0] = '${globals.voicePlayUrl}${chatmessage.audio}';
    intAudioPayer(map,urlmap);
    getAllThreads(isClearFirst: false);

  }


  Widget buildMessageTextField() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 24, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 51,
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR, borderRadius: BorderRadius.circular(26.0)),
              padding: const EdgeInsetsDirectional.only(start: 15.0, bottom: 5.0, end: 15.0),
              child: TextFormField(
                focusNode: chatText,
                enableIMEPersonalizedLearning: false,
                controller: _mapMainController.chatController,
                keyboardType: TextInputType.multiline,
                maxLength: null,
                minLines: 1,
                maxLines: 8,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsetsDirectional.all(0.0),
                    hintText: 'type_something'.tr,
                    hintStyle: TextStyle(
                        color: AppColors.HIND_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font)),
                style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontWeight: FontWeight.w500,
                    fontSize: AppDimen.text_size_14,
                    fontFamily: AppFont.font),
                onTap: () {},
              ),
            ),
          ),

          SizedBox(
            height: 51,
            width: 51,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 5.0),
              child: Obx(
                    () => AnimatedSwitcher(
                  duration:  Duration(milliseconds: !globals.isVoiceChatEnable ? 0 : 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(child: child, scale: animation);
                  },
                  child: FloatingActionButton(
                    key: ValueKey<bool>(_mapMainController.isTextEntered.value),
                    backgroundColor: AppColors.PRIMARY_DARK_COLOR,
                    onPressed: () async {
                      if (_mapMainController.isTextEntered.value || !globals.isVoiceChatEnable) {
                        if (_mapMainController.chatController.text.trim().isNotEmpty) {
                          _message = _mapMainController.chatController.text.trim();
                          _mapMainController.chatController.clear();
                          _mapMainController.chatController.text = "";
                          _mapMainController.checkInternet(sendMessageApiCall, false);
                        }

                      } else {
                        Permission.microphone.request().then((value){

                          if(value == PermissionStatus.granted) {
                            _mapMainController.resetRecordingProcess();
                            _mapMainController.isVoiceRecorderValue.value = true;
                            if (_revealAnimationController.status != AnimationStatus.completed) {
                              _mapMainController.isRecording.value= true;
                              _revealAnimationController.forward();
                            }
                            Future.delayed(const Duration(milliseconds: 450), () {
                              chatAudioWidget?.startRecording();
                            });
                          } else if(value == PermissionStatus.permanentlyDenied){
                            _mapMainController.showLocationPermissionAlert('enable_the_microphone_permission'.tr,false, permissionType: 'microphone');
                          }
                        });

                      }
                    },
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: !globals.isVoiceChatEnable || _mapMainController.isTextEntered.value ? 4.0 : 0.0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(globals.isRtlLang ? math.pi : 0),
                        child: SvgPicture.asset(
                          !globals.isVoiceChatEnable ? sendSvg: _mapMainController.isTextEntered.value  ? sendSvg : voice_icon,
                          height: 20.0,
                          fit: BoxFit.fill,
                          colorFilter: ColorFilter.mode( AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )

        ],
      ),
    );
  }

  String riderName(String name){
    return name.trim().length > 20
        ? name.trim().substring(0, 20) + "..."
        :name.trim();
  }

  String formatDate(String dateUtc) {
    if (dateUtc != "") {
      var formattedDateTime = DateFormat("hh:mm a")
          .format(DateTime.fromMillisecondsSinceEpoch(int.parse(dateUtc)));
      return formattedDateTime;
    } else {
      return "";
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.inactive) {
      _mapMainController.audioRecorder.cancel();
      _mapMainController.recordingTimer?.cancel();
      _mapMainController.isRecording.value = false;
      _mapMainController.recordingSeconds.value = 0;
      _mapMainController.isVoiceRecorderValue.value = false;
      if (_revealAnimationController.status != AnimationStatus.dismissed) {
        _revealAnimationController.reverse();
      }
      chatAudioWidget?.stopPlayback();
      _mapMainController.recordingprogress.value = 0.0;
      _mapMainController.recordingsegments.clear();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    globals.currentShowingPage = '';
    _animationController.dispose();
    _recordingPlayController.dispose();
    _revealAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    chatAudioWidget?.stopRecording();
    _mapMainController.isVoiceRecorderValue.value = false;
    _mapMainController.isPlaying.clear();
    _mapMainController.progress.clear();
    _mapMainController.audioList.clear();
    _mapMainController.totalMillis.clear();
    _mapMainController.currentMillis.clear();
    _mapMainController.recordedAudioPlayer.pause();
    _mapMainController.chatAudioPlayingTimer?.cancel();
    _mapMainController.chatAudioPlayer.dispose();
    _mapMainController.activePausePlayAnimation?.dispose();
    _mapMainController.activePausePlayAnimation = null;
    super.dispose();
  }
}