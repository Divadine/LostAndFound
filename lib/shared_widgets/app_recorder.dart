import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'app_container.dart';
import 'app_icon_widget.dart';
import 'app_text.dart';

class AppRecorder extends StatefulWidget {
  const AppRecorder({super.key});

  @override
  State<AppRecorder> createState() => _AppRecorderState();
}

// NOTE: Added SingleTickerProviderStateMixin so we can drive a color
// animation for the waveform bars while recording / playing.
class _AppRecorderState extends State<AppRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder recorder = AudioRecorder();
  final RecorderController recorderController = RecorderController();
  final AudioPlayer audioPlayer = AudioPlayer();
  final PlayerController playerController = PlayerController();
  bool isRecording = false;
  bool showRecordUI = false;
  bool showRecordedUI = false;
  bool isPaused = false;

  bool isPlaying = false;
  String? audioPath;
  Duration recordedDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  List<double> waveformHeights = [2, 7, 4];

  // ---- Color-indication animation ----
  // Change [activeWaveColor] to whatever "active" color you want to show
  // while recording/playing. Idle color stays AppColors.grey.
  late final AnimationController _waveColorController;
  late final Animation<Color?> _waveColorAnimation;
  final Color activeWaveColor = AppColors.red; // <- pick your active color

  @override
  void initState() {
    super.initState();

    _waveColorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _waveColorAnimation = ColorTween(
      begin: AppColors.grey,
      end: activeWaveColor,
    ).animate(CurvedAnimation(
      parent: _waveColorController,
      curve: Curves.easeInOut,
    ));

    // startRecording();
    // ..androidEncoder = AndroidEncoder.aac
    // ..androidOutputFormat = AndroidOutputFormat.mpeg4
    // ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
    // ..sampleRate = 44100;
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}";
  }

  Future<void> startRecording() async {
    recorderController.reset();

    waveformHeights.clear();

    var status = await Permission.microphone.request();

    if (!status.isGranted) return;

    final dir = await getTemporaryDirectory();

    audioPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

    await recorderController.record(path: audioPath!);

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: audioPath!,
    );

    setState(() {
      isRecording = true;
      isPaused = false;
    });
  }

  Future<void> pauseRecording() async {
    await recorder.pause();
    await recorderController.pause();

    setState(() {
      isPaused = true;
    });
  }

  Future<void> resumeRecording() async {
    await recorder.resume();

    setState(() {
      isPaused = false;
    });
  }

  Future<void> saveRecording() async {
    waveformHeights = recorderController.waveData
        .map((e) => e.toDouble())
        .toList();

    await recorderController.stop();

    final path = await recorder.stop();
    if (path == null) return;
    audioPath = path;
    await audioPlayer.setFilePath(audioPath!);

    setState(() {
      showRecordedUI = true;
      showRecordUI = false;
      isRecording = false;
      isPaused = false;
      isPlaying = false;
    });

    //await generateWaveform();
  }

  Future<void> cancelRecording() async {
    try {
      // Stop recording if it's in progress
      if (await recorder.isRecording()) {
        if (await recorder.isRecording()) {
          await recorder.stop();
        }

        // Delete the file if it exists
        if (audioPath != null) {
          final file = File(audioPath!);

          if (await file.exists()) {
            await file.delete();
          }

          audioPath = null;
        }

        setState(() {
          showRecordUI = false;
          showRecordedUI = false;

          isRecording = false;
          isPaused = false;
          isPlaying = false;

          recordedDuration = Duration.zero;
        });
      }
    } catch (e) {
      debugPrint("Cancel recording error: $e");
    }
  }

  Future<void> playAudio() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      if (audioPlayer.position >= audioPlayer.duration!) {
        await audioPlayer.seek(Duration.zero);
      }
      await audioPlayer.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> stopRecording() async {
    audioPath = await recorder.stop();

    setState(() {
      isRecording = false;
    });

    print(audioPath);
  }

  @override
  void dispose() {
    _waveColorController.dispose();
    audioPlayer.dispose();
    recorder.dispose();
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showRecordedUI)
          buildRecordedUi()
        else if (showRecordUI)
          buildRecord()
        else
          AppContainer(
            widget: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText(
                  text: 'Tap the button to start recording',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: AppColors.grey,
                ),
                GestureDetector(
                  onTap: () async {
                    await startRecording();
                    setState(() {
                      showRecordUI = true;
                    });
                  },
                  child: AppIconWidget(assetPath: AssetImages.mic),
                ),
              ],
            ).pad(),
          ),
      ],
    );
  }

  Widget buildRecord() {
    // Wave bars pulse in [activeWaveColor] while actively recording
    // (i.e. recording started and not paused).
    final bool isActivelyRecording = isRecording && !isPaused;

    return AppContainer(
      widget: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            text: 'Start Recording',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),

          buildWave(isActive: isActivelyRecording),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: cancelRecording,
                child: AppIconWidget(assetPath: AssetImages.recordCancel),
              ),

              GestureDetector(
                onTap: () async {
                  if (!isRecording) {
                    await startRecording();
                  } else if (isPaused) {
                    await resumeRecording();
                  } else {
                    await pauseRecording();
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
                child: AppIconWidget(
                  assetPath: isPlaying
                      ? AssetImages.recorderPlay
                      : AssetImages.recordPause,
                ),
              ),

              GestureDetector(
                onTap: saveRecording,
                child: AppIconWidget(assetPath: AssetImages.recordTick),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [isActive] controls whether the bars animate between grey (idle) and
  // [activeWaveColor] (recording / playing). When false, bars stay grey.
  Widget buildWave({required bool isActive}) {
    final heights = [
      10, 25, 30, 20, 35, 30, 30, 15, 45, 25,
      10, 10, 25, 30, 20, 35, 30, 30, 15, 35,
      25, 10, 10, 25, 30, 20, 35, 30, 30, 15,
    ];

    return AnimatedBuilder(
      animation: _waveColorController,
      builder: (context, child) {
        final Color barColor =
        isActive ? (_waveColorAnimation.value ?? AppColors.grey) : AppColors.grey;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: heights.map((height) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 3,
              height: height.toDouble() - 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildRecordedUi() {
    return AppContainer(
      widget: Column(
        spacing: 7,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: playAudio,
                child: AppIconWidget(
                  assetPath: AssetImages.recorderPlay
                ),
              ),
              // Bars pulse in [activeWaveColor] while audio is playing.
              Flexible(child: buildWave(isActive: audioPlayer.playing)),
            ],
          ).pad(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(text: formatDuration(recordedDuration)),
              Container(
                child: Row(
                  spacing: 10,
                  children: [
                    AppIconWidget(assetPath: AssetImages.smallTick),
                    AppText(
                      text: 'Recording Saved',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // Stop audio if it's playing
                    await audioPlayer.stop();

                    setState(() {
                      showRecordedUI = false;
                      showRecordUI = true;
                      waveformHeights.clear();
                      isRecording = false;
                      isPaused = false;
                      isPlaying = false;
                    });
                    recorderController.reset();
                    //await startRecording();
                  },
                  child: AppContainer(
                    widget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconWidget(assetPath: AssetImages.refresh),
                        const SizedBox(width: 8),
                        AppText(
                          text: 'Re-record',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ).pad(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (audioPath != null) {
                      final file = File(audioPath!);

                      if (await file.exists()) {
                        await file.delete();
                      }
                    }

                    await audioPlayer.stop();

                    setState(() {
                      audioPath = null;
                      showRecordedUI = false;
                      showRecordUI = false;
                    });
                  },
                  child: AppContainer(
                    widget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconWidget(assetPath: AssetImages.delete),
                        const SizedBox(width: 8),
                        AppText(
                          text: 'Delete',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ).pad(),
                  ),
                ),
              ),
            ],
          ).pad(),
        ],
      ),
    );
  }
}