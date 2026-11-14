part of 'app_chat.dart';

extension AppChatFunctions on _AppChatViewState{


  sendMessageApiCall() {
    debugPrint("sendMessageApiCall: ${_message} --- ${_mapMainController.chatController.text}");
    _mapMainController.sendMessage(_message!).then((value) {
      if (value.isNotEmpty) {
        if (value == "offline") {
          _mapMainController.showInSnackBar('offline_text'.tr);
        } else {
          _mapMainController.showInSnackBar(value);
        }
      }
    });
    _mapMainController.isVoiceRecorderValue.value = false;
    Future.delayed(const Duration(milliseconds: 250), () {
      getAllThreads(isClearFirst: false);
    });
  }

  Future<void> getAllThreads({bool isClearFirst = true}) async {
    if (isClearFirst) {
      _mapMainController.update(['chatLoadingController']);
      isListLoading = true;
      _mapMainController.messages.clear();
    }
    String value = await _mapMainController.getAllThreads(1);
    try {
      if (value == "") {
        double count = _mapMainController.threadItems!.count! / 20;
        firstName = _mapMainController.threadItems?.result?.userDetails?.profile?.firstName ?? "";
        riderNameController.add(firstName);
        print("riderNameController--->>> ${firstName}");
        totalPageCount = count.ceil();
        _mapMainController.messages.clear();
        Map<int, LockCachingAudioSource> audioSourcesList = {};
        Map<int, String> audioURLList = {};
        _mapMainController.threadItems?.result?.threadItems?.asMap().forEach((index, element) {
          _mapMainController.messages.add(ChatMessage(
              message: element.messageType != 'chat' && element.authorId == globals.userid
                  ? element.originalText
                  : element.message,
              originalText: element.originalText,
              userTypeId: element.authorId,
              time: formatDate(element.createdAt!),
              picture: _mapMainController.threadItems?.result?.userDetails?.profile?.picture != null &&
                  _mapMainController.threadItems?.result?.userDetails?.profile?.picture != ""
                  ? globals.UPLOAD_URL +
                  "/images/avatar/" +
                  _mapMainController.threadItems!.result!.userDetails!.profile!.picture!
                  : "",
              messageType: element.messageType,
              voiceDuration: element.voiceDuration != null ? (element.voiceDuration! * 1000) : 0,
              audioLangCode: element.originalAudioLanguageCode,
              audioLangName: element.originalAudioLanguage,
              audio: element.audioName));
          debugPrint(
              "audiourlmessageType: --- ${element.messageType} --- ${element.originalAudioLanguageCode} --- ${element.originalAudioLanguage}");
          if ((element.messageType == 'audio' || element.messageType == 'translate-audio') &&
              element.audioName != null) {
            debugPrint(
                "audiourl: ${'${globals.voicePlayUrl}${element.audioName}'} --- ${element.messageType}");
            LockCachingAudioSource audioSource = LockCachingAudioSource(
                Uri.parse(globals.voicePlayUrl + element.audioName!),
                tag: element.audioName);
            audioSourcesList[index] = audioSource;
            audioURLList[index] = globals.voicePlayUrl + element.audioName!;

            debugPrint(
                " audioSource.duration: ${audioSource.duration} --- ${element.audioName} -- ${element.voiceDuration}");
          }
        });

        intAudioPayer(audioSourcesList, audioURLList);
        _mapMainController.update(['chatLoadingController']);

        isListLoading = false;
        _mapMainController.readThreadCount();
      } else if (value == "null") {
        getAllThreads();
      } else if (value == "Offline") {
        _mapMainController.showInSnackBar('offline_text'.tr);
      } else {
        _mapMainController.showInSnackBar(value);
      }
    } on Exception catch (e) {
      _mapMainController.showInSnackBar('something_went_wrong'.tr);
    }
    ;
  }

  Future<void> intAudioPayer(
      Map<int, LockCachingAudioSource> audioSourcesList, Map<int, String> audioURLList) async
  {
    _mapMainController.isPlaying = List.generate(_mapMainController.messages.length, (_) => false);
    _mapMainController.progress = List.generate(_mapMainController.messages.length, (_) => 0.0);
    _mapMainController.totalMillis = List.generate(
        _mapMainController.messages.length, (index) => _mapMainController.messages[index].voiceDuration ?? 0);
    _mapMainController.currentMillis = List.generate(_mapMainController.messages.length, (_) => 0);
    _mapMainController.audioList.clear();
    _mapMainController.audioList.addAll(audioSourcesList);

    for (int i = 0; i < _mapMainController.messages.length; i++) {
      ChatMessage message = _mapMainController.messages[i];
      if (Platform.isIOS && audioURLList[i] != null && audioURLList[i]!.isNotEmpty) {
        print("_mapMainController.audioURLList[i]: ${audioURLList[i]}");
        await _mapMainController.downloadAudioFile(URL: audioURLList[i]!);
      }
      if (message.messageType == 'audio' && message.voiceDuration != null && message.voiceDuration != 0) {
        print("_mapMainController.message.voiceDuration: ${message.voiceDuration}");
        if (Platform.isAndroid) {
          _mapMainController.totalMillis.add(message.voiceDuration!);
          _mapMainController.updateingIndex.value = i;
        }
      } else if (message.messageType == 'audio') {
        print("_mapMainController.audioSourcesList: ${audioSourcesList}");
        if (audioSourcesList[i] != null) findAudioDuration(audioSourcesList[i]!, i, audioURLList[i]);
      }
    }

    _mapMainController.update(['chatLoadingController']);
    print('StreamintAudioPayer finished.: ${_mapMainController.totalMillis}');
  }

  Future<void> findAudioDuration(LockCachingAudioSource audioSource, int index, URL) async {
    AudioPlayer temp = AudioPlayer();
    try {
      Duration? duration;
      print('dfindAudioDurationuration.:1 ${duration} --- ${URL}');
      if (Platform.isAndroid)
        duration = await temp.setAudioSource(audioSource);
      else {
        final file = await _mapMainController.downloadAudioFile(URL: URL);
        duration = await temp.setAudioSource(AudioSource.file(file.path));
      }
      print('dfindAudioDurationuration.:2 ${duration}');
      _mapMainController.totalMillis[index] = duration?.inMilliseconds ?? 0;
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
            Map<int, LockCachingAudioSource> audioSourcesList = {};
            Map<int, String> audioURLList = {};
            _mapMainController.threadItems?.result?.threadItems?.asMap().forEach((index, element) {
              _mapMainController.messages.add(
                ChatMessage(
                  message: element.messageType != 'chat' && element.authorId == globals.userid
                      ? element.originalText
                      : element.message,
                  originalText: element.originalText,
                  userTypeId: element.authorId,
                  voiceDuration: element.voiceDuration != null ? (element.voiceDuration! * 1000) : 0,
                  audio: element.audioName,
                  time: formatDate(element.createdAt!),
                  picture: _mapMainController.threadItems?.result?.userDetails?.profile?.picture != null &&
                      _mapMainController.threadItems?.result?.userDetails?.profile?.picture != ""
                      ? globals.UPLOAD_URL +
                      "/images/avatar/" +
                      _mapMainController.threadItems!.result!.userDetails!.profile!.picture!
                      : "",
                  messageType: element.messageType,
                  audioLangCode: element.originalAudioLanguageCode,
                  audioLangName: element.originalAudioLanguage,
                ),
              );
              if (element.messageType == 'audio') {
                debugPrint("audiourl: ${'${globals.voicePlayUrl}${element.audioName}'}");
                LockCachingAudioSource audioSource = LockCachingAudioSource(
                    Uri.parse('${globals.voicePlayUrl}${element.audioName}'),
                    tag: element.audioName);
                audioSourcesList[index] = audioSource;
                audioURLList[index] = '${globals.voicePlayUrl}${element.audioName}';
                debugPrint(" audioSource.duration: ${audioSource.duration} --- ${element.audioName}");
              }
            });

            intAudioPayer(audioSourcesList, audioURLList);

            isListLoading = false;
          } else if (value == "null") {
            pageCount--;
            loadMore();
          } else if (value == "Offline") {
            _mapMainController.showInSnackBar('offline_text'.tr);
          } else {
            _mapMainController.showInSnackBar(value);
          }
        } on Exception catch (e) {
          _mapMainController.showInSnackBar('something_went_wrong'.tr);
        }
      });
    });
  }


  addNewVoice(ChatMessage chatmessage) {
    debugPrint(
        "onNewVoice: obx ${chatmessage.voiceDuration} --- ${chatmessage.message} --- ${chatmessage.audio} ");
    _mapMainController.messages.insert(0, chatmessage);
    _mapMainController.update(['chatLoadingController']);
    LockCachingAudioSource audioSource = LockCachingAudioSource(
        Uri.parse('${globals.voicePlayUrl}${chatmessage.audio}'),
        tag: chatmessage.audio);
    Map<int, LockCachingAudioSource> map = {};
    Map<int, String> urlmap = {};
    map[0] = audioSource;
    urlmap[0] = '${globals.voicePlayUrl}${chatmessage.audio}';
    intAudioPayer(map, urlmap);
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
                        color: AppColors.PLACEHOLDER_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_14,
                        fontFamily: AppFont.font)),
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
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
                  duration: Duration(milliseconds: !globals.isVoiceChatEnable ? 0 : 200),
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
                        Permission.microphone.request().then((value) {
                          print("microphonepermission: ${value}");

                          if (value == PermissionStatus.granted) {
                            _mapMainController.resetRecordingProcess();
                            _mapMainController.isVoiceRecorderValue.value = true;
                            if (_revealAnimationController.status != AnimationStatus.completed) {
                              _mapMainController.isRecording.value= true;
                              _revealAnimationController.forward();
                            }
                            Future.delayed(const Duration(milliseconds: 450), () {
                              chatAudioWidget?.startRecording();
                            });
                          } else if (value == PermissionStatus.permanentlyDenied) {
                            _mapMainController.showLocationPermissionAlert(
                                'enable_the_microphone_permission'.tr, false,
                                permissionType: 'microphone');
                          }
                        });
                      }
                    },
                    child: Padding(
                      padding:  EdgeInsetsDirectional.only(
                          end: !globals.isVoiceChatEnable || _mapMainController.isTextEntered.value
                              ? 4.0
                              : 0.0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(globals.isRTLLang ? math.pi : 0),
                        child: SvgPicture.asset(
                          !globals.isVoiceChatEnable
                              ? sendSvg
                              : _mapMainController.isTextEntered.value
                              ? sendSvg
                              : recordMicSvg,
                          height: 20.0,
                          fit: BoxFit.fill,
                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
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
}