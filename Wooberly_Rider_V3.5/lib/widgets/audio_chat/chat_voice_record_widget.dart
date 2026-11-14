import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';

import 'chat_voice_mesaage_widget.dart';

class ChatVoiceRecordWidget extends StatelessWidget {
  final MapMainController mapController;
  final  AnimationController animationController;
  final  AnimationController recordingPlayController;
  Function? onStop;
  Function? onNewVoice;
  bool issentToAPI = false;
  bool isEnablePausePlay = true;
  bool isDisableSendVoiceMsg = false;


  ChatVoiceRecordWidget({Key? key, required this.mapController, required this.animationController, required this.recordingPlayController,this.onStop,this.onNewVoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
          () {
        debugPrint("mapController.recordingSeconds.value: ${mapController.recordingSeconds.value} --- ${ mapController.currentmilliSec.value} --- ${mapController.resumeRecording.value}");
        return Padding(
          padding:  EdgeInsetsDirectional.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 30,
                margin: const EdgeInsetsDirectional.only(bottom: 11, end: 20, start: 20),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 16),
                decoration:  BoxDecoration(
                    borderRadius:const BorderRadius.only(
                      bottomLeft: const Radius.circular(20),
                      bottomRight:const  Radius.circular(20),
                    ),
                    gradient: globals.waveGradient

                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  borderRadius:  BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(globals.isVoiceTranslatorEnable)...[
                      Text(
                        "speak_in".trParams({"field" : getLanguageName(globals.aiPreferredLanguage)}),
                        style: TextStyle(
                          fontSize: AppDimen.text_size_20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.BLACK_TEXT_COLOR
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if(!mapController.resumeRecording.value && globals.isVoiceTranslatorEnable && mapController.recordingSeconds.value <30)
                          Container(
                            width: 45,
                            height: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.COMMON_BG_COLOR,
                            ),
                            child: Text(
                              globals.aiPreferredLanguage.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: AppDimen.text_size_16,
                                color:  AppColors.PLACEHOLDER_TEXT_COLOR,
                              ),
                            ),
                          ),
                        if(mapController.resumeRecording.value || mapController.recordingSeconds.value >=30)
                          InkWell(
                            onTap: () async {
                              if(!issentToAPI) {
                                mapController.isPlayRecorded.value = !mapController.isPlayRecorded.value;
                                debugPrint("stopaudioplay: isPlayRecorded ${mapController.isPlayRecorded.value} --- ${mapController.recordingSeconds.value}");
                                if (mapController.isPlayRecorded.value) {
                                  startPlayback();
                                  recordingPlayController.forward();
                                } else {
                                  stopPlayback();
                                }
                              }
                            },
                            child: Container(
                              width: 35,
                              height: 35,
                              alignment: AlignmentDirectional.centerEnd,
                              child: RotatedBox(
                                quarterTurns: globals.isRTLLang ? 2:0,
                                child: AnimatedIcon(
                                  icon: AnimatedIcons.play_pause,
                                  progress: recordingPlayController,
                                  color: AppColors.PRIMARY_DARK_COLOR,
                                  size: 35,
                                ),
                              ),
                            ),
                          ),
                        if(!mapController.resumeRecording.value && globals.isVoiceTranslatorEnable && mapController.recordingSeconds.value <30)
                          SizedBox(width: 10)
                        else
                          const SizedBox(width: 5),

                        Expanded(
                          child: mapController.resumeRecording.value || mapController.recordingSeconds.value >=30 ?
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() =>
                                    Stack(
                                      alignment: AlignmentDirectional.centerStart,
                                      children: [
                                        CustomPaint(
                                          size: const Size(double.infinity, 32),
                                          painter: WaveformPainter(
                                            progress: mapController.recordingprogress.value,
                                            activeGradient: globals.waveGradient,
                                            leadingEdgeColor: AppColors.PRIMARY_DARK_COLOR,
                                            inactiveColor: Colors.grey.shade400,
                                            // inactiveGradient: !mapController.isPlayRecorded.value ?  globals.waveGradient : null,
                                          ),
                                        ),

                                        SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 32,
                                            thumbShape: RoundSliderThumbShape(
                                              enabledThumbRadius: 0,
                                            ),
                                            overlayShape: RoundSliderOverlayShape(
                                              overlayRadius: 0,
                                            ),
                                            activeTrackColor: Colors.transparent,
                                            inactiveTrackColor: Colors.transparent,
                                          ),
                                          child: Slider(
                                            value: mapController.recordingprogress.value>1.0 ? 1.0: mapController.recordingprogress.value ,
                                            min: 0.0,
                                            max: 1.0,
                                            onChangeStart: (val) {
                                              mapController.islocalDragging.value = true;
                                              if(mapController.isPlayRecorded.value) {
                                                stopPlayback(isPausePlay: false);
                                              }
                                            },
                                            onChanged: (val) {
                                              mapController.recordingprogress.value = val;
                                              mapController.currentmilliSec.value = (val * mapController.recordingSeconds.value).toInt();
                                              mapController.islocalDragging.refresh();
                                            },
                                            onChangeEnd: (val) {
                                              mapController.islocalDragging.value = false;
                                              final position = Duration(
                                                  milliseconds: ((mapController.recordingSeconds.value*1000) * val).toInt()
                                              );
                                              debugPrint("slider onchanged called: ${val} --- ${position}");
                                              mapController.recordedAudioPlayer.seek(position,);
                                              if(mapController.isPlayRecorded.value) {
                                                startPlayback();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                ),
                              ],
                            ),
                          ) :

                          AnimatedBuilder(
                            animation: animationController,
                            builder: (context, child) {
                              return CustomPaint(
                                  size: Size(double.infinity, 40),
                                  painter:  RecordingWavePainter(
                                    animationValue: animationController.value,
                                    gradient: (mapController.isRecording.value || issentToAPI) ? mapController.blackLinearGradient! : globals.waveGradient,
                                  )
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 10),
                        SizedBox(
                          width: 45,
                          child: Text(
                            textAlign: TextAlign.start,
                            mapController.audioPlayerFunction!.displayFormatted( (mapController.resumeRecording.value || mapController.recordingSeconds.value >= globals.voiceRecordingSec ? mapController.currentmilliSec.value: mapController.recordingSeconds.value) * 1000),
                            style: TextStyle(
                              fontSize: AppDimen.text_size_16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.BLACK_TEXT_COLOR,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if(!issentToAPI) {
                              await mapController.audioRecorder.cancel();
                              mapController.recordingTimer?.cancel();
                              mapController.isRecording.value = false;
                              mapController.recordingSeconds.value = 0;
                              mapController.isVoiceRecorderValue.value = false;
                              if (onStop != null) onStop!();
                              stopPlayback();
                              mapController.recordingprogress.value = 0.0;
                              mapController.recordingsegments.clear();
                            }
                          },
                          child:  Container(
                            width: 45,
                            height: 45,
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              deleteVoiceMsg,
                              height: 20,
                              fit: BoxFit.fill,
                              colorFilter: ColorFilter.mode(
                                  AppColors.PRIMARY_DARK_COLOR, BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Obx(() =>
                            InkWell(
                              onTap: () async {
                                if(!isDisableSendVoiceMsg) {
                                  if(mapController.audioPlayerFunction!.displayFormatted( (mapController.resumeRecording.value || mapController.recordingSeconds.value >= globals.voiceRecordingSec ? mapController.currentmilliSec.value: mapController.recordingSeconds.value) * 1000) != "00:00") {
                                    isDisableSendVoiceMsg = true;
                                    Future.delayed(Duration(seconds: 2), () {
                                      isDisableSendVoiceMsg = false;
                                    });
                                    issentToAPI = true;
                                    stopRecording(isSendToAPI: true);
                                  }
                                }
                              },
                              child: RotatedBox(
                                quarterTurns: globals.isRTLLang ? 2:0,
                                child: Container(
                                  padding: const EdgeInsetsDirectional.all(15),
                                  decoration: BoxDecoration(
                                    color:AppColors.PRIMARY_DARK_COLOR,
                                    shape: BoxShape.circle,
                                  ),
                                  child:mapController.voiceChatLoading.value?
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.CIRCULAR_PROGRESS_BAR_LOADING_COLOR,
                                      strokeWidth: 2,
                                    ),
                                  ) :
                                  SvgPicture.asset(
                                    sendVoiceMsg,
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.fill,
                                    colorFilter: ColorFilter.mode(
                                        AppColors.WHITE, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: (){
                            print("mapController.recordingSeconds.value: mapController.isMergeInprogress ${mapController.recordingSeconds.value} --- ${mapController.isMergeInprogress} ---- ${issentToAPI}");
                            if(!issentToAPI && isEnablePausePlay) {
                              isEnablePausePlay = false;
                              Future.delayed(Duration(milliseconds: 500), () {
                                isEnablePausePlay = true;
                              });
                              if(!mapController.isMergeInprogress) {
                                if (mapController.recordingSeconds.value < globals.voiceRecordingSec) {
                                  stopPlayback();
                                  animationController.forward();
                                  toggleRecordingPlayback();
                                }
                                mapController.currentmilliSec.value = mapController.recordingSeconds.value;
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end:15.0),
                            child: Icon(
                              mapController.resumeRecording.value ? Icons.mic : Icons.pause,
                              color: mapController.resumeRecording.value ? Colors.green :  mapController.recordingSeconds.value <globals.voiceRecordingSec ?AppColors.PRIMARY_DARK_COLOR: Colors.grey,
                              size: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> startRecording() async {

    if (await mapController.audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      mapController.recordingPath = '${directory.path}/recording_$timestamp.m4a';
      issentToAPI = false;

      debugPrint("mapController.chatAudioPlayer.play: ${mapController.chatAudioPlayer.playerState}");
      stopChatAudioPlayer();
      await mapController.audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: mapController.recordingPath!,
      );

      mapController.mergedPath = null;
      mapController.isRecording.value = true;
      mapController.recordingSeconds.value = 0;


      mapController.recordingTimer?.cancel();
      mapController.recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        mapController.recordingSeconds.value++;

        if (mapController.recordingSeconds >= globals.voiceRecordingSec) {
          mapController.recordingTimer?.cancel();
          await stopRecording();
        }
      });
    }
  }


  Future<void> stopRecording({bool isSendToAPI = false}) async {
    stopPlayback();
    debugPrint("mapController.isRecording.value: ${mapController.isRecording.value} --- ${ mapController.recordingSeconds.value}");
    if (mapController.isRecording.value) {
      final path = await mapController.audioRecorder.stop();
      if (path != null) {
        mapController.recordingsegments.add(path);
      }

      if(mapController.mergedPath ==null)
        await _mergeSegments(mapController.recordingsegments);
      if (mapController.mergedPath != null && !isSendToAPI) {
        await mapController.recordedAudioPlayer.setAudioSource(AudioSource.file(mapController.mergedPath!));
      }
      debugPrint("stopRecording--mapController.mergedPath: ${isSendToAPI} --- ${mapController.mergedPath} -- ${mapController.recordingSeconds.value}");
      mapController.currentmilliSec.value = mapController.recordingSeconds.value;
      if(mapController.recordingTimer?.isActive ?? false) {
        mapController.recordingTimer?.cancel();
      }
      mapController.isRecording.value = false;

      if (mapController.mergedPath != null && isSendToAPI) {
        print("stored pathssss ${mapController.mergedPath} --- ${mapController.recordingSeconds.value}");
        _uploadAudio();
      }
    } else if(mapController.recordingSeconds.value >=30 && isSendToAPI){
      _uploadAudio();
    }
  }

  void stopPlayback({bool isPausePlay = true}) {
    mapController.recordedAudioPlayer.pause();
    if(isPausePlay) {
      mapController.isPlayRecorded.value = false;
    }
    mapController.recordingpositionSubscription?.cancel();
    mapController.recordingplayStateSubscription?.cancel();
    if(isPausePlay) {
      recordingPlayController.reverse();
    }
    debugPrint("stopaudioplay: ${mapController.currentmilliSec.value} --- ${mapController.recordingSeconds.value}");


  }

  void startPlayback() async {
    stopChatAudioPlayer();
    print("startPlayback New position: ");

    mapController.recordingprogress.value = 0.0;
     mapController.recordedAudioPlayer.play();

    mapController.recordingpositionSubscription = mapController.recordedAudioPlayer.positionStream.listen((position) {

      mapController.currentmilliSec.value = position.inSeconds;

      double value = mapController.recordingSeconds.value > 0
          ? position.inMilliseconds / (mapController.recordingSeconds.value*1000)
          : 0.0;
      if(mapController.recordingprogress.value <=value)
      mapController.recordingprogress.value = value;
      print("New position: ${ mapController.recordingprogress.value} --- --- ${ mapController.recordingSeconds.value} -- ${position.inMilliseconds} -- ${value}");
    });

    mapController.recordingplayStateSubscription = mapController.recordedAudioPlayer.playerStateStream.listen((state){
      print("mapController.recordedAudioPlayerplayerstate: ${state.processingState}");
      if(state.processingState == ProcessingState.completed){
        mapController.recordedAudioPlayer.seek(Duration.zero);
        stopPlayback();
      }

    });
  }

  Future<void> toggleRecordingPlayback() async {
    print("mapController.isPlayRecorded.value: >>>>${mapController.resumeRecording.value }");
    if (mapController.resumeRecording.value == false) {
      mapController.isMergeInprogress = true;
      animationController.stop();
      if(mapController.recordingTimer?.isActive ?? false) {
        mapController.recordingTimer?.cancel();
      }
      final path = await mapController.audioRecorder.stop();
      if (path != null) {
        mapController.recordingsegments.add(path);
        String? mergeSegmentPath = await _mergeSegments(mapController.recordingsegments);
        if(mergeSegmentPath !=null) {
          Duration? duration =  await mapController.recordedAudioPlayer.setAudioSource(AudioSource.file(mergeSegmentPath));
          print('✅ Segment ${mapController.recordingsegments.length} saved: $path ---- ${mergeSegmentPath} --- ${duration}');
          if(duration !=null)
            mapController.recordingSeconds.value = duration.inSeconds;
        }
      }

      mapController.isMergeInprogress = false;
      mapController.resumeRecording.value = true;
      print('⏸️ Recording preview paused');
    } else {
      stopChatAudioPlayer();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch; // ← ADD THIS
      final segmentPath = '${directory.path}/segment_${mapController.recordingsegments.length}_$timestamp.m4a';  // ← UNIQUE PATH
      mapController.mergedPath = null;
      await mapController.audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: segmentPath,
      );
      mapController.recordingTimer?.cancel();
      mapController.recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        mapController.recordingSeconds.value++;
        print("<><><><><><><><><><><${mapController.recordingSeconds.value}>");
        if (mapController.recordingSeconds >=  globals.voiceRecordingSec) {
          if(mapController.recordingTimer?.isActive ?? false) {
            mapController.recordingTimer?.cancel();
          }
          mapController.currentmilliSec.value = mapController.recordingSeconds.value;
          final path = await mapController.audioRecorder.stop();
          if (path != null) {
            mapController.recordingsegments.add(path);
            String? mergeSegmentPath = await _mergeSegments(mapController.recordingsegments);
            if(mergeSegmentPath !=null) {
              Duration? duration = await mapController.recordedAudioPlayer.setAudioSource(AudioSource.file(mergeSegmentPath));
              print('✅ Segment ${mapController.recordingsegments.length} saved: $path ---- ${mergeSegmentPath} --- ${duration}');
              if(duration !=null)
                mapController.recordingSeconds.value = duration.inSeconds;
            }
          }
        }
      });
      animationController.repeat(reverse: true);
      mapController.resumeRecording.value = false;
      print('▶️ Recording preview resumed');
    }

    print("resume PLaying >>>>${mapController.resumeRecording.value }");
  }

  Future<String?> _mergeSegments(List<String> segments) async {
    if (segments.isEmpty) return null;
    if (segments.length == 1) {
      mapController.mergedPath = segments.first;
      return segments.first;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      String outputPath = '${dir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (Platform.isIOS || Platform.isAndroid) {
        try {
          final channel = MethodChannel('audio_merge');
          final String? result = await channel.invokeMethod('mergeAudioFiles', {
            'inputPaths': segments,
            'outputPath': outputPath,
          });

          if(result != null) {
            mapController.mergedPath = result;
            return result;
          }
        } catch (e) {
          debugPrint("Native merge failed: $e");
        }
      }

      print('❌ Error merging audio: Native merge failed or not supported platform');
      return null;
    } catch (e) {
      print('❌ Error merging audio: $e');
      return null;
    }
  }

  void _uploadAudio() {
    mapController.uploadMultipart(File(mapController.mergedPath!), globals.voiceUploadUrl,mapController.recordingSeconds.value,onNewVoice,mapController.driveraiPrefLang ).then((value){
      if(value.isEmpty){
        mapController.isVoiceRecorderValue.value = false;
        if(onStop!=null) onStop!();
        mapController.recordingSeconds.value = 0;
      } else {
        if(value.toLowerCase() != "offline") {
          mapController.showInSnackBar(value);
        }
      }
    });

  }

  String getLanguageName(String code) {
    final lang = globals.baseController.AILanglist.firstWhere(
    (e) => e["languageCode"] == code,
    );
    return lang["language"] ?? code;
  }

  void stopChatAudioPlayer() {
    if(mapController.chatAudioPlayer.playerState.playing) {
      mapController.audioPlayerFunction?.pauseAudio(mapController.updateingIndex.value);
      mapController.chatAudioPlayingAnimController?.reverse();
    }
  }
}

class RecordingWavePainter extends CustomPainter {
  final double animationValue;
  final Gradient gradient;

  RecordingWavePainter({
    required this.animationValue,
    required this.gradient,
  });

  final List<double> barHeights = [
    0.01, 0.10, 0.25, 0.20, 0.30,
    0.50, 0.30, 0.10, 0.15, 0.20,
    0.50, 0.75, 0.55, 0.45, 0.60,
    0.50, 0.60, 0.40, 0.25, 0.40,
    0.25, 0.15, 0.50, 0.15, 0.45,
    0.25, 0.40, 0.30, 0.50, 0.15,
    0.25, 0.20, 0.10, 0.25, 0.05,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = barHeights.length;

    final barWidth = (size.width / barCount) * 0.6; // bar thickness
    final space = (size.width / barCount) * 0.4;     // gap between bars

    final centerY = size.height / 2;

    final shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final paint = Paint()
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    for (int i = 0; i < barCount; i++) {
      final baseHeight = size.height * barHeights[i];

      /// Add smooth animation (±10%)
      final animNoise = sin(animationValue * 4 + i * 0.8) * 0.4;

      final finalHeight = baseHeight * (1 + animNoise);

      final x = (i * (barWidth + space)) + barWidth;

      canvas.drawLine(
        Offset(x, centerY - finalHeight / 2),
        Offset(x, centerY + finalHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RecordingWavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        gradient != oldDelegate.gradient;
  }
}