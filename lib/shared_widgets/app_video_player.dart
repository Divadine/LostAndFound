import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AppVideoPlayer extends StatefulWidget {
  final String url;
  final BorderRadius? borderRadius;

  const AppVideoPlayer({
    super.key,
    required this.url,
    this.borderRadius,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposeController();
      _initializeVideo();
    }
  }

  String _getMediaUrl(String url) {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      return '';
    }

    if (cleanUrl.startsWith('http://') ||
        cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }

    final path = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
    return 'https://lost-and-found.skyraantech.com/backend/$path';
  }

  Future<void> _initializeVideo() async {
    final videoUrl = _getMediaUrl(widget.url);

    if (videoUrl.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Video URL is empty';
      });

      return;
    }

    debugPrint('VIDEO URL: $videoUrl');

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('VIDEO INITIALIZATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load video';
      });
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // SMALL RECTANGLE
    const double videoHeight = 180;

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: videoHeight,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius:
          widget.borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return Container(
        width: double.infinity,
        height: videoHeight,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius:
          widget.borderRadius ?? BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 35,
              color: Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unable to load video',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _disposeController();
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final controller = _controller!;

    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius:
      widget.borderRadius ?? BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: videoHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // RECTANGULAR VIDEO
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            // PLAY / PAUSE
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // PROGRESS BAR
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}