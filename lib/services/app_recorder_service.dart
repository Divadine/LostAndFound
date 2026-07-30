import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum RecorderState { idle, recording, paused, recorded }

class AppRecorderService extends ChangeNotifier {
  AppRecorderService({this.maxRecordingDuration = const Duration(seconds: 30)}) {
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
        playbackPosition = Duration.zero;
        await _player.seek(Duration.zero);
        notifyListeners();
      }
    });  }

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
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ---------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------

  Future<void> startRecording() async {
    if (!await _ensureMicPermission()) return;

    final dir = await getTemporaryDirectory();
    audioPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: audioPath!,
    );

    elapsed = Duration.zero;
    state = RecorderState.recording;

    _startTimer();
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> saveRecording() async {
    final path = await _recorder.stop();
    _recordTimer?.cancel();

    if (path == null) {
      state = RecorderState.idle;
      notifyListeners();
      return;
    }

    audioPath = path;
    recordedDuration = elapsed;

    await _player.setFilePath(audioPath!);

    state = RecorderState.recorded;
    notifyListeners();
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


  void _startTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == RecorderState.recording) {
        elapsed += const Duration(seconds: 1);
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
    _recordTimer?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}