import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import '../spin_kit/three_bounce.dart';
import 'chat_voice_record_widget.dart';

class ChatVoiceMesaageWidget extends StatefulWidget {
  final int index;
  final MapMainController mapController;
  final  ChatVoiceRecordWidget? chatVoiceRecordWidget;

  const ChatVoiceMesaageWidget({
    Key? key,
    required this.index,
    required this.mapController,
     this.chatVoiceRecordWidget,

  }) : super(key: key);

  @override
  _ChatVoiceMesaageWidgetState createState() => _ChatVoiceMesaageWidgetState();
}

class _ChatVoiceMesaageWidgetState extends State<ChatVoiceMesaageWidget>
    with SingleTickerProviderStateMixin {
  late int index;
  late MapMainController mapController;
  late final  AnimationController _animationController;
  var isShowPlayPauseLoading = false.obs;


  @override
  void initState() {
    index = widget.index;
    mapController = widget.mapController;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("mapController.currentlyPlayingIndex: ${mapController.currentlyPlayingIndex}");
    return Obx(() {

      bool playing = mapController.isPlaying.isNotEmpty &&  mapController.isPlaying[index];
          print("updateingIndex: ${mapController.updateingIndex.value} --- ${index} --- ${playing} -- ${mapController.totalMillis[index]} --- ${mapController.currentMillis[index]} --- ${mapController.audioPlayerFunction !=null} -- ${mapController.currentlyPlayingIndex}");
      double currentProgress = mapController.progress.isEmpty ? 0.0 :mapController.progress[index].clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async{
                  if(mapController.isPlayRecorded.value){
                    mapController.recordedAudioPlayer.pause();
                    mapController.isPlayRecorded.value = false;
                    if( widget.chatVoiceRecordWidget !=null)
                    widget.chatVoiceRecordWidget!.recordingPlayController.reverse();
                  }
                  if(mapController.recordingTimer !=null && mapController.recordingTimer!.isActive &&  widget.chatVoiceRecordWidget !=null){
                    mapController.currentmilliSec.value = mapController.recordingSeconds.value;
                    widget.chatVoiceRecordWidget!.stopPlayback();
                    widget.chatVoiceRecordWidget!.animationController.forward();
                    widget.chatVoiceRecordWidget!.toggleRecordingPlayback();
                  }

                  debugPrint("mapController.isPlayRecorded.value: ${ mapController.isPlayRecorded.value} ---${mapController.recordingTimer?.isActive}");
                  if(  mapController.activePausePlayAnimation !=null)
                    mapController.activePausePlayAnimation!.reverse();


                  if (playing) {
                    mapController.audioPlayerFunction?.pauseAudio(index);
                    _animationController.reverse();
                  } else {

                    if (mapController.currentlyPlayingIndex == index && mapController.currentMillis[index] > 0) {
                      mapController.audioPlayerFunction?.resumeAudio(index);
                      _animationController.forward();
                      mapController.chatAudioPlayingAnimController = _animationController;
                    } else {

                      if(mapController.audioList[index] !=null) {
                        // if(Platform.isAndroid) {
                          print("setAudioSource--> start download");
                          isShowPlayPauseLoading.value = true;
                          await mapController.chatAudioPlayer.setAudioSource(mapController.audioList[index]!);
                          isShowPlayPauseLoading.value = false;
                          print("setAudioSource--> end download");
                        // } else {
                        //   String URL = mapController.audioList[index]!.uri.path;
                        //   print("audioplayer: ${URL}");
                        //  File file =  await mapController.downloadAudioFile(URL: URL);
                        //   await mapController.chatAudioPlayer.setAudioSource(AudioSource.file(file.path));
                        // }
                      }
                      mapController.audioPlayerFunction?.playAudio(index);
                      mapController.chatAudioPlayingAnimController = _animationController;
                      _animationController.forward();
                    }
                    mapController.activePausePlayAnimation = _animationController;
                  }
                },
                child: Obx(() => isShowPlayPauseLoading.value ? SpinKitThreeBounce(
                  color: AppColors.PRIMARY_DARK_COLOR,
                  size: 12.0,
                  ) : RotatedBox(
                    quarterTurns: globals.isRtlLang ? 2:0,
                    child: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _animationController,
                      color: globals.userid != widget.mapController.messages[widget.index].userTypeId && globals.isDarkTheme ?
                      Colors.grey.shade700 :
                      AppColors.PRIMARY_DARK_COLOR,
                      size: 24,
                    ),
                  ),
                )
              ),

             const  SizedBox(width: 2),
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    CustomPaint(
                      size: Size(double.infinity, 30),
                      painter: WaveformPainter(
                        progress: currentProgress,
                        activeGradient: globals.waveGradient,
                        inactiveColor: Colors.grey.shade400,
                        leadingEdgeColor:
                        mapController.progress[index] > 0 ?
                        globals.userid != widget.mapController.messages[widget.index].userTypeId && globals.isDarkTheme ?
                        Colors.grey.shade700 :
                        AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR
                            : null,
                        // inactiveGradient: mapController.currentlyPlayingIndex != index ? globals.waveGradient : null,
                      ),
                    ),

                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 30,
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
                        value: currentProgress,
                        min: 0.0,
                        max: 1.0,
                        onChangeStart: (value) {
                          mapController.draggingIndex.value = index;
                        },
                        onChanged: (value) {

                          mapController.progress[index] = value;
                          mapController.currentMillis[index] = (value * mapController.totalMillis[index]).toInt();

                          mapController.updateingIndex.value = index;
                          mapController.updateingIndex.refresh();
                        },
                        onChangeEnd: (value) {
                          debugPrint("onChangeEnd drag");
                          mapController.draggingIndex.value = -1;
                          mapController.audioPlayerFunction?.seekAudio(index, value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
             const SizedBox(width: 7),

              mapController.audioPlayerFunction !=null && (playing || mapController.currentMillis[index] > 0 || mapController.totalMillis[index]>0) ?
              Text(
                playing || mapController.currentMillis[index] > 0
                    ? mapController.audioPlayerFunction!.displayFormatted(mapController.currentMillis[index])
                    :  mapController.totalMillis[index]>0 ?
                mapController.audioPlayerFunction!.displayFormatted(mapController.totalMillis[index]) :
               '',
                style: TextStyle(
                  fontSize: AppDimen.text_size_12,
                  color: globals.userid != widget.mapController.messages[widget.index].userTypeId && globals.isDarkTheme ?
                  Colors.grey.shade700 :
                  AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                ),
              ) : SpinKitThreeBounce(
                color: AppColors.PRIMARY_DARK_COLOR,
                size: 15.0,
              ),

              // Delete button
            ],
          ),


          if(widget.mapController.messages[widget.index].originalText !=null)
          Obx(() =>
          Padding(
            padding: const EdgeInsetsDirectional.only(top:8.0),
            child: InkWell(
              onTap: () => widget.mapController.messages[widget.index].isTranscribeMsgExpand.value = !widget.mapController.messages[widget.index].isTranscribeMsgExpand.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6.0,top: 2.0),
                    child: SvgPicture.asset(
                      trans_script_icon,
                      height: 8,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(AppColors.TEXT_LINK_COLOR, BlendMode.srcIn),
                    ),
                  ),
                  Text(
                    widget.mapController.messages[widget.index].isTranscribeMsgExpand.value
                        ? "label_transcribed_from".tr + ' ${widget.mapController.messages[widget.index].audioLangName}(${widget.mapController.messages[widget.index].audioLangCode?.toUpperCase()})'
                        : "label_view_transcribed_message".tr,
                    style:  TextStyle(
                      color: AppColors.TEXT_LINK_COLOR,
                      fontSize: AppDimen.text_size_14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2.0),
                    child: Icon(
                      widget.mapController.messages[widget.index].isTranscribeMsgExpand.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.TEXT_LINK_COLOR,
                    ),
                  ),
                ],
              ),
            ),
          ),),

          if(widget.mapController.messages[widget.index].message != widget.mapController.messages[widget.index].audio && widget.mapController.messages[widget.index].audio !=null)
          Obx(() =>
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            alignment: Alignment.topCenter,
            child: widget.mapController.messages[widget.index].isTranscribeMsgExpand.value
                ? Padding(
              padding: const EdgeInsetsDirectional.only(top: 12),
              child: Text(
                widget.mapController.messages[widget.index].message!,
                style: TextStyle(
                  fontSize: AppDimen.text_size_14,
                  color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                  height: 1.4,
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),),
        ],
      );
    });
  }
}



class AudioPlayerFunction {
  final MapMainController mapController;
  final AnimationController animationController;
  const AudioPlayerFunction({ required this.mapController,required this.animationController,});


  void stopAudio(int index) {
    debugPrint("animationController stopAudio ${index}");
   animationController.reverse();
    mapController.chatAudioPlayer.stop();
    mapController.chatAudioPlayingTimer?.cancel();
    mapController.isPlaying[index] = false;
    mapController.progress[index] = 0.0;
    mapController.currentMillis[index] = 0;
    mapController.currentlyPlayingIndex = -1;
    mapController.updateingIndex.value = index;
    mapController.updateingIndex.refresh();
  }

void pauseAudio(int index) {
    debugPrint("animationController pauseAudio ${index}");
   animationController.reverse();
    mapController.chatAudioPlayer.stop();
  mapController.chatAudioPlayingTimer?.cancel();
  mapController.isPlaying[index] = false;
  mapController.updateingIndex.value = index;
    mapController.updateingIndex.refresh();

}

void resumeAudio(int index) {
    mapController.isPlaying[index] = true;
      mapController.updateingIndex.value = index;
    mapController.updateingIndex.refresh();
    animationController.forward();
    debugPrint("currentmilli: ${mapController.currentMillis[index]}");
    mapController.chatAudioPlayer.seek(Duration(milliseconds: mapController.currentMillis[index]));
    mapController.chatAudioPlayer.play();
  startTimer(index);
}

void playAudio(int index) {
  // Stop previous audio if different
  if (mapController.currentlyPlayingIndex != -1 && mapController.currentlyPlayingIndex != index) {
    pauseAudio( mapController.currentlyPlayingIndex ?? 0);
  }

  mapController.currentlyPlayingIndex = index;

  // Reset if starting fresh
  if (mapController.currentMillis[index] == 0) {
    mapController.progress[index] = 0.0;
  }

  debugPrint("play:newPosition ${mapController.currentMillis[index]}");
  mapController.isPlaying[index] = true;

  mapController.updateingIndex.value = index;
  mapController.updateingIndex.refresh();
  animationController.forward();
  if (mapController.currentMillis[index] != 0) {
    mapController.chatAudioPlayer.seek(
      Duration(milliseconds: mapController.currentMillis[index]),).then((_) {
      mapController.chatAudioPlayer.play();
    });
  } else{
    mapController.chatAudioPlayer.play();
  }

  startTimer(index);
}

void seekAudio(int index, double seekValue) {
  final newPosition = (seekValue * mapController.totalMillis[index]).toInt();
  debugPrint("seekAudio:newPosition ${newPosition}");

  mapController.currentMillis[index] = newPosition;
  mapController.progress[index] = seekValue;
  if(index == mapController.updateingIndex.value)
    mapController.updateingIndex.refresh();
  else
    mapController.updateingIndex.value = index;



  debugPrint("mapController.isPlaying[index]: ${mapController.isPlaying[index]}");
  // If audio was playing, restart from new position
  if (mapController.isPlaying[index]) {
    mapController.chatAudioPlayingTimer?.cancel();
    animationController.reverse();

    // Small delay for clean restart
    Future.delayed(Duration(milliseconds: 50), () {
      if (mapController.isPlaying[index]) {
        animationController.forward();
        mapController.chatAudioPlayer.seek(Duration(milliseconds: newPosition),);
        startTimer(index);
      }
    });
  }
}

void startTimer(int index) {
  mapController.chatAudioPlayingTimer?.cancel();

  mapController.chatAudioPlayingTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
    // Don't update if user is dragging this specific audio
    if (mapController.draggingIndex == index) return;

    mapController.currentMillis[index] += 100;

    if (mapController.currentMillis[index] >= mapController.totalMillis[index]) {
      // Audio finished playing
      stopAudio(index);
      if(mapController.activePausePlayAnimation !=null)
        mapController.activePausePlayAnimation!.reverse();
      return;
    }
        mapController.progress[index] = (mapController.totalMillis[index] > 0)
            ? mapController.currentMillis[index] / mapController.totalMillis[index]
            : 0.0;

    mapController.updateingIndex.value = index;
    mapController.updateingIndex.refresh();

  });
}



String displayFormatted(int ms) {
    debugPrint("displayFormatted -- ms: ${ms}");
  int totalSec = ms ~/ 1000;
  int min = totalSec ~/ 60;
  int sec = totalSec % 60;
  return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
}
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Gradient activeGradient;
  final Gradient? inactiveGradient;
  final Color inactiveColor;
  final Color? leadingEdgeColor;
  final int leadingEdgeWidth;

  WaveformPainter({
    required this.progress,
    required this.activeGradient,
    required this.inactiveColor,
     this.inactiveGradient,
    this.leadingEdgeColor,
    this.leadingEdgeWidth = 1,
  });

  final List<double> barHeights = [
    0.01, 0.10, 0.25, 0.20, 0.30,
    0.50, 0.30, 0.10, 0.15, 0.20,
    0.5, 0.75, 0.55, 0.45, 0.60,
    0.50, 0.60, 0.40, 0.25, 0.40,
    0.25, 0.15, 0.5, 0.15, 0.45,
    0.25, 0.40, 0.30, 0.50, 0.15,
    0.25, 0.20, 0.10, 0.25, 0.05
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final isRTL = globals.isRtlLang;
    final barCount = barHeights.length;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    final gradientShader = activeGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    Shader? inactivegradientShader;
    if(inactiveGradient !=null)
     inactivegradientShader = inactiveGradient?.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final activePaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = gradientShader;

    final inactivePaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    Paint? leadingEdgePaint;
    if (leadingEdgeColor != null) {
      leadingEdgePaint = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = leadingEdgeColor!;
    }

      if(inactivegradientShader!=null)
        inactivePaint.shader = inactivegradientShader;
      else
        inactivePaint.color = inactiveColor;

    int activeBars = (barCount * progress).floor();

    for (int i = 0; i < barCount; i++) {
      double x;
      Paint paint;

      if (isRTL) {
        x = size.width - (i * barWidth + barWidth / 2);
      } else {
        x = i * barWidth + barWidth / 2;
      }

      bool isLeadingEdge = leadingEdgePaint != null &&
          i >= activeBars &&
          i < activeBars + leadingEdgeWidth;

      double barHeight = size.height * barHeights[i];

      if (isLeadingEdge) {
        paint = leadingEdgePaint!;
        barHeight = 28;
      } else {

        paint = (i < activeBars) ? activePaint : inactivePaint;
      }

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override

  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeGradient != activeGradient ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.leadingEdgeColor != leadingEdgeColor ||
        oldDelegate.leadingEdgeWidth != leadingEdgeWidth ;
  }

}