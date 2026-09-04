import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppAudioPlayer extends StatefulWidget {
  final String url;

  const AppAudioPlayer({
    super.key,
    required this.url,
  });

  @override
  State<AppAudioPlayer> createState() => _AppAudioPlayerState();
}

class _AppAudioPlayerState extends State<AppAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;

  static const List<double> _waveHeights = [
    2, 5, 8, 10, 14, 18, 20, 25, 20, 14, 10, 14, 18, 20, 25, 20, 14, 10, 15, 18, 20, 25, 20, 14, 10, 8, 5, 2,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  @override
  void didUpdateWidget(covariant AppAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _initializeAudio();
    }
  }

  String _getAudioUrl(String url) {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      return '';
    }

    // Already complete URL
    if (cleanUrl.startsWith('http://') ||
        cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }

    // API returns:
    // uploads/audio/filename.m4a
    return 'https://lost-and-found.skyraantech.com/backend/$cleanUrl';
  }

  Future<void> _initializeAudio() async {
    final audioUrl = _getAudioUrl(widget.url);

    if (audioUrl.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Audio URL is empty';
      });

      return;
    }

    debugPrint('AUDIO URL: $audioUrl');

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _audioPlayer.setUrl(audioUrl);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AUDIO INITIALIZATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load audio';
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (_isLoading || _errorMessage != null) {
      return;
    }

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        // If audio finished, start from beginning.
        if (_audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }

        await _audioPlayer.play();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('AUDIO PLAY ERROR: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to play audio';
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlayer();
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const SizedBox(
        height: 55,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 55,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: _initializeAudio,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final processingState =
            playerState?.processingState ?? ProcessingState.idle;

        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                final progress = (duration.inMilliseconds > 0)
                    ? (position.inMilliseconds / duration.inMilliseconds)
                    : 0.0;

                return Row(
                  children: [
                    // PLAY BUTTON
                    GestureDetector(
                      onTap: _toggleAudio,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // WAVEFORM
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              if (duration.inMilliseconds > 0) {
                                final seekProgress = details.localPosition.dx /
                                    constraints.maxWidth;
                                _audioPlayer.seek(
                                  Duration(
                                    milliseconds: (duration.inMilliseconds *
                                            seekProgress)
                                        .toInt(),
                                  ),
                                );
                              }
                            },
                            child: _buildWave(progress),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWave(double progress) {
    final total = _waveHeights.length;
    final filledCount = (progress * total).floor();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
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
      ),
    );
  }
}