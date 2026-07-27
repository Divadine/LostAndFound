// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class RecordingTimer extends StateNotifier<int> {
//   RecordingTimer() : super(0);
//
//   bool _running = false;
//
//   void start() {
//     _running = true;
//     state = 0;
//     _tick();
//   }
//
//   void _tick() async {
//     while (_running) {
//       await Future.delayed(const Duration(seconds: 1));
//       state++;
//     }
//   }
//   void pause() {
//     _running = false;
//   }
//
//   void reset() {
//     _running = false;
//
//     state = 0;
//   }
//
// }
//
// final recordTiming =StateNotifierProvider<RecordingTimer, int> ((ref) => RecordingTimer());
//
