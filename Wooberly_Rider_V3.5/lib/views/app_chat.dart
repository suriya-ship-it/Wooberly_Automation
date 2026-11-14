import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:app_name/app/app.dart';
import 'package:app_name/models/chat_model.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/audio_chat/ai_lang_selection_widget.dart';
import 'package:app_name/widgets/audio_chat/chat_voice_mesaage_widget.dart';
import 'package:app_name/widgets/audio_chat/chat_voice_record_widget.dart';
import 'package:app_name/widgets/cicular_reveal_animation/circular_reveal_animation.dart';

import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../controllers/map_main_controller/map_main_controller.dart';
import '../widgets/spin_kit/three_bounce.dart';
part 'app_chat_functions.dart';

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
  final MapMainController _mapMainController = Get.find();
  String firstName = "";
  int pageCount = 1;
  int totalPageCount = 1;
  bool isListLoading = false;
  FocusNode chatText = FocusNode();
  StreamController<String> riderNameController = StreamController<String>.broadcast();
  late AnimationController _animController, _animationController, _recordingPlayController;
  ChatVoiceRecordWidget? chatAudioWidget;
  late AnimationController _revealAnimationController;
  late Animation<double> _revealAnimation;
  String? _message;
  AILangSelectionWidget? aiLangSelectionWidget;
  Widget placeHolderWidget =   SvgPicture.asset(
    defaultProfileSvg,
    height: 34.0,
    width: 34.0,
  );

  @override
  void initState() {
    _mapMainController.chatAudioPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);
    _mapMainController.getDeviceDetails();
    _mapMainController.currentlyPlayingIndex = -1;
    _mapMainController.init();

    if (!(globals.socket?.connected ?? false)) {
      globals.socket?.connect();
    }

    _mapMainController.isMessageUpdate.listen((value){
      getAllThreads(isClearFirst: false);
    });

    _mapMainController.listenChatSocket(_mapMainController.bookingId);

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
      globals.baseController.getAILanguageList(isShowLoader: false),
      globals.baseController.getUserAILanguage(isShowLoader: false),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapMainController.isTextEntered.value = false;
      if (globals.aiPreferredLanguage.isEmpty && aiLangSelectionWidget != null) {
        aiLangSelectionWidget!.showAILangSelectionBottomSheet(context, isDismissable: false);
      }
    });


    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _mapMainController.audioPlayerFunction =
        AudioPlayerFunction(mapController: _mapMainController, animationController: _animController);

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
    _mapMainController.chatController.addListener(() {
      _mapMainController.isTextEntered.value = _mapMainController.chatController.text.trim().isNotEmpty;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
      return ColoredBox(
        color: AppColors.COMMON_BG_COLOR,
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppColors.COMMON_BG_COLOR,
            appBar: AppBar(
              centerTitle: true,
              title: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 22.0),
                  child: StreamBuilder(
                      stream: riderNameController.stream,
                      builder: (context, snapshot) {
                        return Text(
                          riderName(snapshot.data ?? ""),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.BLACK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_18,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        );
                      })),
              elevation: 0,
              backgroundColor: AppColors.COMMON_BG_COLOR,
              leading: Container(
                height: 50,
                width: 50,
                margin: const EdgeInsetsDirectional.only(top: 15, start: 15),
                child: InkWell(
                  onTap: () {
                    App().setBackNavigation(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppColors.WHITE, shape: BoxShape.circle),
                    child: SvgPicture.asset(
                      primaryLeftArrow,
                      matchTextDirection: true,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
              actions: [
                if (globals.isVoiceTranslatorEnable)
                  Builder(builder: (context) {
                    aiLangSelectionWidget = AILangSelectionWidget(
                        title: "label_user_preferred_lang".tr,
                        tooltipcontent: "label_tooltip_app_text_lang".tr,
                        isShowIcon: true);
                    return aiLangSelectionWidget!;
                  }),
                InkWell(
                  onTap: () {
                    _mapMainController.checkInternet(() {
                      UrlLauncher.launchUrl(Uri.parse("tel:${_mapMainController.driverPhone}"));
                    }, false);
                  },
                  child: Padding(
                    padding:  EdgeInsetsDirectional.only(end: 22, start: 20, top: globals.isRTLLang ? 25 : 20),
                    child: SvgPicture.asset(
                      phoneSvg,
                      height: 20.0,
                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                    ),
                  ),
                )
              ],
            ),
            body: GetBuilder<MapMainController>(
                id: 'chatLoadingController',
                builder: (_) {
                  debugPrint(
                      "_mapMainController.isVoiceRecorderValue.value: ${_mapMainController.isVoiceRecorderValue.value} --- ${globals.isVoiceChatEnable} ");
                  return SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        if (_mapMainController.chatController == '\s') {
                          _mapMainController.chatController.text.trim();
                        }
                        ;
                        if (chatText.hasPrimaryFocus) {
                          chatText.unfocus();
                        }
                      },
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(top: 10),
                              child: _mapMainController.messages.length > 0
                                  ? ListView.builder(
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
                                          debugPrint(
                                              "messag23e: ${_mapMainController.messages[index].message} --- ${_mapMainController.messages[index].audioLangName}");
                                          return Padding(
                                              padding: _mapMainController.messages[index].userTypeId ==
                                                      globals.userid
                                                  ? EdgeInsetsDirectional.only(
                                                      top: 12,
                                                      bottom: 12,
                                                      end: 24.0,
                                                    )
                                                  : EdgeInsetsDirectional.only(
                                                      top: 12, bottom: 12, start: 20.0, end: 24),
                                              child: _mapMainController.messages[index].userTypeId !=
                                                      globals.userid
                                                  ? Stack(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsetsDirectional.only(top: 3),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(34.0),
                                                            child:
                                                                _mapMainController.messages[index].picture !=
                                                                            null &&
                                                                        _mapMainController
                                                                                .messages[index].picture !=
                                                                            ""
                                                                    ? CachedNetworkImage(
                                                                        height: 34,
                                                                        width: 34,
                                                                        fit: BoxFit.cover,
                                                                        imageUrl: _mapMainController
                                                                                    .messages[index]
                                                                                    .picture !=
                                                                                null
                                                                            ? _mapMainController
                                                                                .messages[index].picture!
                                                                            : "",
                                                                        placeholder: (context, url) =>
                                                                        placeHolderWidget,
                                                                      )
                                                                    : placeHolderWidget,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsetsDirectional.only(start: 20,),
                                                          child: Stack(children: [
                                                            Container(
                                                              margin: const EdgeInsetsDirectional.only(start: 7),
                                                              height: 40,
                                                              child: SvgPicture.asset(
                                                                globals.isRTLLang
                                                                    ? sendChatWhite
                                                                    : sendChatWhiteRTL,
                                                                fit: BoxFit.fill,
                                                                colorFilter: ColorFilter.mode(
                                                                    AppColors.APP_CHAT_COLOR,
                                                                    BlendMode.srcIn),
                                                              ),
                                                            ),
                                                            Container(
                                                              margin: const EdgeInsetsDirectional.only(start: 16.5, top: 0.5),
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadiusDirectional.only(
                                                                      bottomEnd: Radius.circular(8),
                                                                      bottomStart: Radius.circular(8),
                                                                      topEnd: Radius.circular(8)),
                                                                  color: AppColors.APP_CHAT_COLOR),
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsetsDirectional.only(
                                                                        start: 10, top: 7, end: 10),
                                                                    child: _mapMainController.messages[index]
                                                                                .messageType ==
                                                                            'translate-audio'
                                                                        ? Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize:
                                                                                    MainAxisSize.min,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding:
                                                                                        const EdgeInsetsDirectional
                                                                                            .only(
                                                                                            end: 4.0,
                                                                                            top: 2.0),
                                                                                    child: SvgPicture.asset(
                                                                                      audioTranscriptedSvg,
                                                                                      height: 8,
                                                                                      fit: BoxFit.fill,
                                                                                      colorFilter:
                                                                                          ColorFilter.mode(
                                                                                              AppColors
                                                                                                  .PROMOCODE_LINK_COLOR,
                                                                                              BlendMode
                                                                                                  .srcIn),
                                                                                    ),
                                                                                  ),
                                                                                  Text(
                                                                                    "label_translated_from"
                                                                                            .tr +
                                                                                        ' ${_mapMainController.messages[index].audioLangName}(${_mapMainController.messages[index].audioLangCode})',
                                                                                    style: TextStyle(
                                                                                      color: AppColors
                                                                                          .PROMOCODE_LINK_COLOR,
                                                                                      fontSize: AppDimen
                                                                                          .text_size_14,
                                                                                      fontWeight:
                                                                                          FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Text(
                                                                                "${_mapMainController.messages[index].message}",
                                                                                style: TextStyle(
                                                                                    fontSize:
                                                                                        AppDimen.text_size_14,
                                                                                    fontFamily: AppFont.font,
                                                                                    color: _mapMainController
                                                                                                .messages[
                                                                                                    index]
                                                                                                .userTypeId ==
                                                                                            globals.userid
                                                                                        ? AppColors
                                                                                            .BLACK_TEXT_COLOR
                                                                                        : AppColors
                                                                                            .B3_BLACK_COLOR,
                                                                                    fontWeight:
                                                                                        FontWeight.w400),
                                                                              ),
                                                                            ],
                                                                          )
                                                                        : _mapMainController.messages[index]
                                                                                    .messageType ==
                                                                                'chat'
                                                                            ? Text(
                                                                                "${_mapMainController.messages[index].message}",
                                                                                style: TextStyle(
                                                                                    fontSize:
                                                                                        AppDimen.text_size_14,
                                                                                    fontFamily: AppFont.font,
                                                                                    color: _mapMainController
                                                                                                .messages[
                                                                                                    index]
                                                                                                .userTypeId ==
                                                                                            globals.userid
                                                                                        ? AppColors
                                                                                            .BLACK_TEXT_COLOR
                                                                                        : AppColors
                                                                                            .B3_BLACK_COLOR,
                                                                                    fontWeight:
                                                                                        FontWeight.w400),
                                                                              )
                                                                            : ChatVoiceMesaageWidget(
                                                                                index: index,
                                                                                mapController:
                                                                                    _mapMainController,
                                                                                chatVoiceRecordWidget:
                                                                                    chatAudioWidget,
                                                                              ),
                                                                  ),
                                                                  Container(
                                                                      margin: const EdgeInsetsDirectional.only(end: 7, bottom: 3, top: 5),
                                                                      alignment:
                                                                          AlignmentDirectional.bottomEnd,
                                                                      child: Text(
                                                                        "${_mapMainController.messages[index].time}",
                                                                        style: TextStyle(
                                                                            fontWeight: FontWeight.w400,
                                                                            color:
                                                                                AppColors.SEARCH_TEXT_COLOR,
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
                                                      alignment: AlignmentDirectional.topEnd,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsetsDirectional.only(top: 3),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(34.0),
                                                            child: globals.picture.value != ""
                                                                ? CachedNetworkImage(
                                                                    height: 34.0,
                                                                    width: 34.0,
                                                                    fit: BoxFit.cover,
                                                                    imageUrl: globals.picture.value,
                                                                    placeholder: (context, url) =>
                                                                    placeHolderWidget,
                                                                  )
                                                                : placeHolderWidget,
                                                          ),
                                                        ),
                                                        Container(
                                                          margin: const EdgeInsetsDirectional.symmetric(horizontal: 20,),
                                                          child: Stack(
                                                            children: [
                                                              Container(
                                                                alignment: AlignmentDirectional.centerEnd,
                                                                margin: const EdgeInsetsDirectional.only(end: 10),
                                                                height: 30,
                                                                child: SvgPicture.asset(
                                                                  globals.isRTLLang
                                                                      ? sendChatWhiteRTL
                                                                      : sendChatWhite,
                                                                  fit: BoxFit.fill,
                                                                  colorFilter: ColorFilter.mode(
                                                                      AppColors.PRIMARY_LIGHT_COLOR,
                                                                      BlendMode.srcIn),
                                                                ),
                                                              ),
                                                              Container(
                                                                margin: const EdgeInsetsDirectional.only(
                                                                    end: 18.5, top: 0.5),
                                                                decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    color: AppColors.PRIMARY_LIGHT_COLOR),
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Padding(
                                                                      padding: const EdgeInsetsDirectional.only(
                                                                          start: 8, top: 7, end: 10),
                                                                      child: _mapMainController
                                                                                  .messages[index]
                                                                                  .messageType ==
                                                                              'chat'
                                                                          ? Text(
                                                                              "${_mapMainController.messages[index].message}",
                                                                              style: TextStyle(
                                                                                  fontSize:
                                                                                      AppDimen.text_size_14,
                                                                                  fontFamily: AppFont.font,
                                                                                  color: AppColors
                                                                                      .BLACK_TEXT_COLOR),
                                                                            )
                                                                          : ChatVoiceMesaageWidget(
                                                                              index: index,
                                                                              mapController:
                                                                                  _mapMainController,
                                                                              chatVoiceRecordWidget:
                                                                                  chatAudioWidget,
                                                                            ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsetsDirectional.only(
                                                                          start: 15, bottom: 3, top: 8, end: 8),
                                                                      child: Container(
                                                                        alignment:
                                                                            AlignmentDirectional.bottomEnd,
                                                                        child: Text(
                                                                          "${_mapMainController.messages[index].time}",
                                                                          style: TextStyle(
                                                                              color: AppColors
                                                                                  .PLACEHOLDER_TEXT_COLOR,
                                                                              fontFamily: AppFont.font,
                                                                              fontSize:
                                                                                  AppDimen.text_size_10),
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
                                                    ));
                                        }
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          Obx(() {
                            chatAudioWidget = ChatVoiceRecordWidget(
                                mapController: _mapMainController,
                                animationController: _animationController,
                                recordingPlayController: _recordingPlayController,
                                onStop: () {
                                  if (_revealAnimationController.status != AnimationStatus.dismissed) {
                                    _revealAnimationController.reverse();
                                  }
                                },
                                onNewVoice: addNewVoice);
                            debugPrint(
                                "_mapMainController.isVoiceRecorderValue.value: obx ${_mapMainController.isVoiceRecorderValue.value} --- ${globals.isVoiceChatEnable} ");
                            return _mapMainController.isVoiceRecorderValue.value
                                ? CircularRevealAnimation(
                                    animation: _revealAnimation,
                                    centerOffset: Offset(
                                        globals.isRTLLang ? 30 : MediaQuery.of(context).size.width - 85, 25),
                                    child: chatAudioWidget ?? const SizedBox.shrink())
                                : buildMessageTextField();
                          }),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ),
      );
    });
  }

  String riderName(String name) {
    return name.trim().length > 20 ? name.trim().substring(0, 20) + "..." : name.trim();
  }

  String formatDate(String dateUtc) {
    if (dateUtc != "") {
      var formattedDateTime =
          DateFormat(globals.scheduleTimeFormat).format(DateTime.fromMillisecondsSinceEpoch(int.parse(dateUtc)));
      return formattedDateTime;
    } else {
      return "";
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
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
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _recordingPlayController.dispose();
    _revealAnimationController.dispose();
    chatText.dispose();
    riderNameController.close();
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