class LoginOtpResponseModel {
  final int userId;
  final String userUid;
  final String name;
  final int status;
  final String phoneno;
  final String token;

  LoginOtpResponseModel({
    required this.userId,
    required this.userUid,
    required this.name,
    required this.status,
    required this.phoneno,
    required this.token,
  });

  factory LoginOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginOtpResponseModel(
      userId: json["user_id"] is int // NEW
          ? json["user_id"] // NEW
          : (int.tryParse(json["user_id"]?.toString() ?? '') ?? 0), // NEW
      userUid: json["user_uid"]?.toString() ?? '', // NEW
      name: json["name"]?.toString() ?? '', // NEW
      status: json["status"] is int // NEW
          ? json["status"] // NEW
          : (int.tryParse(json["status"]?.toString() ?? '') ?? 0), // NEW
      phoneno: json["phoneno"]?.toString() ?? '', // NEW
      token: json["token"]?.toString() ?? '', // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "user_uid": userUid,
      "name": name,
      "status": status,
      "phoneno": phoneno,
      "token": token,
    };
  }
}
