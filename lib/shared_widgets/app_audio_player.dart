import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: _buildPlayer(),
    );
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // PLAY BUTTON
                GestureDetector(
                  onTap: _toggleAudio,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // PROGRESS
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, positionSnapshot) {
                      final position =
                          positionSnapshot.data ?? Duration.zero;

                      return StreamBuilder<Duration?>(
                        stream: _audioPlayer.durationStream,
                        builder: (context, durationSnapshot) {
                          final duration =
                              durationSnapshot.data ?? Duration.zero;

                          final max =
                          duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0;

                          final value =
                          position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble();

                          return Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape:
                                  const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape:
                                  const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  min: 0,
                                  max: max,
                                  value: value,
                                  onChanged: duration.inMilliseconds <= 0
                                      ? null
                                      : (newValue) {
                                    _audioPlayer.seek(
                                      Duration(
                                        milliseconds:
                                        newValue.toInt(),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // BUFFERING / COMPLETED STATUS
            if (processingState == ProcessingState.buffering)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
}