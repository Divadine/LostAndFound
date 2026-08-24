import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'app_container.dart';
import 'app_icon_widget.dart';
import '../services/app_recorder_service.dart';
import 'app_text.dart';

class AppRecorder extends StatefulWidget {
  const AppRecorder({super.key});

  @override
  State<AppRecorder> createState() => _AppRecorderState();
}

class _AppRecorderState extends State<AppRecorder> {
  final AppRecorderService _service = AppRecorderService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() => setState(() {});

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_service.state) {
      case RecorderState.recorded:
        return _buildRecordedUi();
      case RecorderState.recording:
      case RecorderState.paused:
        return _buildRecordingUi();
      case RecorderState.idle:
        return _buildIdleUi();
    }
  }

  Widget _buildIdleUi() {
    return AppContainer(
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
              print("Function called");
              final v = await _service.startRecording();
              print("Function returned");


            },
            child: AppIconWidget(assetPath: AssetImages.mic),
          ),
        ],
      ).pad(),
    );
  }

  Widget _buildRecordingUi() {
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

          _buildWave(),

          AppText(
            text: _service.formatDuration(_service.elapsed),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _service.cancelRecording,
                child: AppIconWidget(assetPath: AssetImages.recordCancel),
              ),
              GestureDetector(
                onTap: () {
                  if (_service.isPaused) {
                    _service.resumeRecording();
                  } else {
                    _service.pauseRecording();
                  }
                },
                child: AppIconWidget(
                  assetPath: _service.isPaused
                      ? AssetImages.recordingPause
                      : AssetImages.recordingPlay,
                ),
              ),
              GestureDetector(
                onTap: _service.saveRecording,
                child: AppIconWidget(assetPath: AssetImages.recordTick),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedUi() {
    final remaining = _service.recordedDuration - _service.playbackPosition;
    final displayDuration = remaining.isNegative ? Duration.zero : remaining;

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
                onTap: _service.togglePlayback,
                child: AppIconWidget(
                  assetPath: _service.isPlaying
                      ? AssetImages.recordingPlay
                      : AssetImages.recordingPause
                  ,
                ),
              ),
              Flexible(child: _buildWave()),
            ],
          ).pad(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(text: _service.formatDuration(displayDuration)),
              Row(
                spacing: 10,
                children: [
                  AppIconWidget(assetPath: AssetImages.recordSave),
                  AppText(
                    text: 'Recording Saved',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  prefixIcon: AssetImages.refresh,
                  bgColor: AppColors.white,
                  title: 'Re-record',
                  textColor: AppColors.primaryColor,
                  fontSize: 12,
                  border: Border.all(color: AppColors.fieldGrey),
                  height: 35,
                  onTap: () {
                    _service.reRecord();
                  },
                ),

              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                AppButton(
                  prefixIcon: AssetImages.delete,
                  size: 17,
                  bgColor: AppColors.white,
                  title: 'Delete',
                  textColor: AppColors.red,
                  fontSize: 12,
                  border: Border.all(color: AppColors.fieldGrey),
                  height: 35,
                  onTap: () {
                    _service.deleteRecording();
                  },
                )
              ),
            ],
          ).pad(),
        ],
      ),
    );
  }

  static const List<double> _waveHeights = [
    2,
    5,
    8,
    10,
    14,
    18,
    20,
    25,
    20,
    14,
    10,
    14,
    18,
    20,
    25,
    20,
    14,
    10,
    15,
    18,
    20,
    25,
    20,
    14,
    10,
    8,
    5,
    2,
  ];

  Widget _buildWave() {
    final progress = _service.waveProgress;
    final total = _waveHeights.length;
    final filledCount = (progress * total).floor();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool filled = i < filledCount;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 3,
          height: _waveHeights[i] + 6,
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryColor : AppColors.grey,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
