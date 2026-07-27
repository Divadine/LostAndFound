// import 'package:audio_waveforms/audio_waveforms.dart';
//
// class MediaProvider extends StateNotifier<MediaState> {
//
//   final RecorderController recorderController = RecorderController();
//
//   //final AudioRecordService recorder;
//   MediaProvider() : super( MediaState()) {
//     recorderController
//       ..androidEncoder = AndroidEncoder.aac
//       ..androidOutputFormat = AndroidOutputFormat.mpeg4
//       ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
//       ..sampleRate = 44100;
//   }
//
//   String? currentPath;
//
//
//   void startRecording() async {
//
//     final dir = await getTemporaryDirectory();
//
//     currentPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
//
//     final permission = await recorderController.checkPermission();
//
//     if(!permission) return;
//
//     await recorderController.record(path: currentPath!);
//
//     //await recorder.startRecord(currentPath!);
//
//     state = state.copyWith(isRecording: true, isPaused: false);
//   }
//
//   void pauseRecording() async {
//     await recorderController.pause();
//     //await recorder.pause();
//     state = state.copyWith( isPaused: true);
//   }
//
//   void resumeRecording() async {
//     //await recorder.resume();
//     await recorderController.record();
//     state = state.copyWith(isPaused: false);
//   }
//
//   void stopRecording( ) async {
//     //final path = await recorder.stop();
//     await recorderController.stop();
//     state = state.copyWith(
//       isPaused: false,
//       isRecording: false,
//       audioPath: currentPath!,
//     );
//     currentPath = null;
//   }
//
//   void deleteAudio() {
//     state = state.copyWith(audioPath: null);
//   }
//
//
//   void setVideo(String video) {
//     state = state.copyWith(videoPath: video);
//   }
//
//   void deleteVideo() {
//     state = state.copyWith(videoPath: null);
//   }
//
//
// }
//
//
// //final audioRecorderProvider = Provider((ref) => AudioRecordService());
//
//
// final mediaProvider = StateNotifierProvider<MediaProvider, MediaState>(  (ref) =>MediaProvider(),);