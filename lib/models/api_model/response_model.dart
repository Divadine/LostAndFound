import 'package:lost_and_found/enums/current_state.dart';

class ResponseModel<R> {
  final int status;
  final String message;
  final R? data;
  final CurrentState? currentState;


  ResponseModel({required this.status, required this.message, this.data,this.currentState});

  bool get isSuccess => status == 1;

  factory ResponseModel.fromJson(Map<String, dynamic> json, R Function(dynamic) fromJson,) {
    final status = json["status"];
    final message = json["message"];
    return ResponseModel(
      status: status,
      message: message,
      data: status == 1 ? fromJson(json['data']) : null,
    );
  }

  ResponseModel<T> asFailure<T>() {
    return ResponseModel<T>(
      status: status,
      message: message,
      currentState: currentState,
    );
  }


  @override
  String toString() {
    return 'ResponseModel(status: $status, message: $message, currentState: $currentState, data: $data)';
  }
}