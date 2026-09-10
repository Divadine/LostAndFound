import 'dart:async';

/// Simple app-wide broadcaster: whoever is about to start playing calls
/// [requestPlay] with their own id. Anyone else currently playing listens
/// on [onPlayRequested] and pauses itself if the incoming id isn't theirs.
///
/// This keeps the video player and the audio recorder/player decoupled —
/// neither widget needs to know the other exists.
class MediaPlaybackCoordinator {
  MediaPlaybackCoordinator._();
  static final MediaPlaybackCoordinator instance = MediaPlaybackCoordinator._();

  static const String videoId = 'video';
  static const String audioId = 'audio';

  final StreamController<String> _controller = StreamController<String>.broadcast();

  /// Emits the id of whoever just started playing.
  Stream<String> get onPlayRequested => _controller.stream;

  void requestPlay(String id) {
    _controller.add(id);
  }

  void dispose() {
    _controller.close();
  }
}