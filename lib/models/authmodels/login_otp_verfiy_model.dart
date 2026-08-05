class LoginOtpVerifyModel {
  final String phoneno;
  final String otp;
  final int type;
  final String? name;
  final String deviceId;
  final String deviceType;
  final String deviceToken;
  final String appVersion;

  LoginOtpVerifyModel({
    required this.phoneno,
    required this.otp,
    required this.type,
    this.name,
    required this.deviceId,
    required this.deviceType,
    required this.deviceToken,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      "phoneno": phoneno,
      "otp": otp,
      "type": type,
      "name": name,
      "device_id": deviceId,
      "device_type": deviceType,
      "device_token": deviceToken,
      "app_version": appVersion,
    };
  }
}