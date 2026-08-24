import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lost_and_found/utils/app_colors.dart';

/// Read-only audio playback widget for voice descriptions attached to a post.
/// Visual style (play button + waveform) matches AppRecorder's recorded-state
/// UI so playback feels consistent with the recording experience elsewhere.
class AppAudioPlayer extends StatefulWidget {
  final String url;

  const AppAudioPlayer({super.key, required this.url});

  @override
  State<AppAudioPlayer> createState() => _AppAudioPlayerState();
}

class _AppAudioPlayerState extends State<AppAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();

  bool isPlaying = false;
  bool _isCompleted = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  static const List<double> _waveHeights = [
    2, 5, 8, 10, 14, 18, 20, 25, 20, 14, 10, 14, 18, 20, 25, 20,
    14, 10, 15, 18, 20, 25, 20, 14, 10, 8, 5, 2,
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      duration = await _player.setUrl(widget.url) ?? Duration.zero;
      if (mounted) setState(() {});
    } catch (_) {
      // TODO: surface a load error in the UI if needed
    }

    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => position = pos);
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) async {
      if (!mounted) return;
      setState(() => isPlaying = playerState.playing);

      if (playerState.processingState == ProcessingState.completed) {
        await _player.pause();
        _isCompleted = true;
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
        await _player.seek(Duration.zero);
      }
    });
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (_isCompleted) {
      _isCompleted = false;
      await _player.seek(Duration.zero);
    }

    await _player.play();
  }

  double get _progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Widget _buildWave() {
    final total = _waveHeights.length;
    final filledCount = (_progress * total).floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool filled = i < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: _waveHeights[i] + 6,
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryColor : AppColors.grey.withAlpha(90),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: _buildWave(),
          ),
        ),
      ],
    );
  }
}