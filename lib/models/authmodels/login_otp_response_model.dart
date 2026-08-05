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
      userId: json["user_id"],
      userUid: json["user_uid"],
      name: json["name"],
      status: json["status"],
      phoneno: json["phoneno"],
      token: json["token"],
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