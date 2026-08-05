class ResponseModel<R> {
  final int status;
  final String message;
  final R? data;

  ResponseModel({required this.status, required this.message, this.data});

  factory ResponseModel.fromJson(
      Map<String, dynamic> json,
      R Function(dynamic) fromJson,
      ) {
    final status = json["status"];
    final message = json["message"];

    return ResponseModel(
      status: status,
      message: message,
      data: status == 1 ? fromJson(json['data']) : null,
    );
  }
}