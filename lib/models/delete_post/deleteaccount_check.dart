class UserCheckModel {
  final int status;   // 0 = no account, 1 = deleted, 2 = reported, 3 = already submitted
  final String message;
  final int userId;

  UserCheckModel({
    required this.status,
    required this.message,
    required this.userId,
  });

  factory UserCheckModel.fromJson(Map<String, dynamic> json) {
    int uid = 0;
    final data = json['data'];
    if (data is List && data.isNotEmpty && data.first is Map) {
      uid = int.tryParse(data.first['user_id']?.toString() ?? '') ?? 0;
    } else if (data is Map) {
      uid = int.tryParse(data['user_id']?.toString() ?? '') ?? 0;
    }

    return UserCheckModel(
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
      userId: uid,
    );
  }

  bool get isDeletedAccount => status == 1;
  bool get isReported => status == 2;
  bool get isAlreadySubmitted => status == 3;
}