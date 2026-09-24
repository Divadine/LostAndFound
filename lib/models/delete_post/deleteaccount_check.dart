class UserCheckModel {
  final int status; // 0 = not deleted / no account, 1 = deleted account
  final String message;

  UserCheckModel({required this.status, required this.message});

  factory UserCheckModel.fromJson(Map<String, dynamic> json) {
    return UserCheckModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  bool get isDeletedAccount => status == 1;
}