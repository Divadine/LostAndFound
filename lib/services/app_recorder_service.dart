import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lost_and_found/services/media_playback_coordinator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum RecorderState { idle, recording, paused, recorded }



class AppRecorderService extends ChangeNotifier {

  AppRecorderService._({this.maxRecordingDuration = const Duration(seconds: 30)}) {
    _positionSub = _player.positionStream.listen((pos) {
      playbackPosition = pos;
      notifyListeners();
    });



    _playerStateSub = _player.playerStateStream.listen((playerState) async {
      isPlaying = playerState.playing;

      if (playerState.processingState == ProcessingState.completed) {
        await _player.pause();
        isPlaying = false;
        _isCompleted = true;
        playbackPosition = recordedDuration;
        // await _player.seek(Duration.zero); // Don't seek to zero immediately
        notifyListeners();
      }
    });

    _mediaCoordinatorSub = MediaPlaybackCoordinator.instance.onPlayRequested.listen((id) {
      if (id != MediaPlaybackCoordinator.audioId && _player.playing) {
        _player.pause();
      }
    });
  }

  static final AppRecorderService instance = AppRecorderService._();

  final Duration maxRecordingDuration;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  RecorderState state = RecorderState.idle;
  String? audioPath;
  Duration elapsed = Duration.zero;
  Duration recordedDuration = Duration.zero;
  Duration playbackPosition = Duration.zero;
  bool isPlaying = false;
  bool _isCompleted = false;
  Timer? _recordTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<String>? _mediaCoordinatorSub;
  bool get isRecording => state == RecorderState.recording;
  bool get isPaused => state == RecorderState.paused;
  bool get isRecorded => state == RecorderState.recorded;

  double get waveProgress {
    switch (state) {
      case RecorderState.recording:
      case RecorderState.paused:
        if (maxRecordingDuration.inMilliseconds == 0) return 0;
        return (elapsed.inMilliseconds / maxRecordingDuration.inMilliseconds)
            .clamp(0.0, 1.0);
      case RecorderState.recorded:
        if (recordedDuration.inMilliseconds == 0) return 0;
        return (playbackPosition.inMilliseconds /
            recordedDuration.inMilliseconds)
            .clamp(0.0, 1.0);
      case RecorderState.idle:
        return 0;
    }
  }

  Future<bool> _ensureMicPermission() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      return hasPermission;
    } catch (e) {
      debugPrint("Error checking mic permission: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------

  Future<String?> startRecording() async {
    try {
      if (!await _ensureMicPermission()) return null;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final dir = await getTemporaryDirectory();
      audioPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

      elapsed = Duration.zero;
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioPath!,
      );

      state = RecorderState.recording;
      _startTimer();
      notifyListeners();

      return audioPath;
    } catch (e) {
      debugPrint("Error starting recording: $e");
      state = RecorderState.idle;
      notifyListeners();
      return null;
    }
  }

  Future<void> pauseRecording() async {
    if (state != RecorderState.recording) return;
    await _recorder.pause();
    state = RecorderState.paused;
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (state != RecorderState.paused) return;
    await _recorder.resume();
    state = RecorderState.recording;
    _startTime = DateTime.now().subtract(elapsed);
    notifyListeners();
  }

  Future<String?> saveRecording() async {
    final path = await _recorder.stop();
    _recordTimer?.cancel();

    if (path == null) {
      state = RecorderState.idle;
      notifyListeners();
      return null;
    }

    audioPath = path;
    recordedDuration = elapsed;

    try {
      await _player.setFilePath(audioPath!);
    } catch (e) {
      debugPrint("Error loading recording into player: $e");
    }

    state = RecorderState.recorded;
    notifyListeners();

    return audioPath;
  }

  Future<void> cancelRecording() async {
    _recordTimer?.cancel();

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _deleteFileIfExists();

    audioPath = null;
    elapsed = Duration.zero;
    recordedDuration = Duration.zero;
    state = RecorderState.idle;
    notifyListeners();
  }


  Future<void> togglePlayback() async {
    if (audioPath == null) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (_isCompleted) {
      _isCompleted = false;
      await _player.seek(Duration.zero);
    }

    MediaPlaybackCoordinator.instance.requestPlay(MediaPlaybackCoordinator.audioId);
    await _player.play();
  }
  Future<void> reRecord() async {
    await _player.stop();
    await _deleteFileIfExists();
    audioPath = null;
    elapsed = Duration.zero;
    recordedDuration = Duration.zero;
    playbackPosition = Duration.zero;
    isPlaying = false;
    await startRecording();
  }
  Future<void> deleteRecording() async {
    await _player.stop();
    await _deleteFileIfExists();

    audioPath = null;
    recordedDuration = Duration.zero;
    elapsed = Duration.zero;
    playbackPosition = Duration.zero;
    isPlaying = false;
    state = RecorderState.idle;
    notifyListeners();
  }


  DateTime? _startTime;

  void _startTimer() {
    _startTime = DateTime.now().subtract(elapsed);
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state == RecorderState.recording) {
        elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });
  }

  Future<void> _deleteFileIfExists() async {
    if (audioPath == null) return;
    final file = File(audioPath!);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}";
  }

  @override
  void dispose() {
    // A singleton should typically not be disposed as it lives for the 
    // entire app lifecycle. We cancel timers and subscriptions but 
    // avoid calling super.dispose() which would permanently disable listeners.
    _recordTimer?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    
    // We stop the players but don't dispose the underlying objects 
    // so they can be reused if the singleton is accessed again.
    _player.stop();
    _recorder.stop();
  }
}