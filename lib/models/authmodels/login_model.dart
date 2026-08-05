class LoginModel {
  final String phoneno;
  final int type;

  LoginModel({required this.phoneno, required this.type});

  Map<String, dynamic> toJson() {
    return {
      "phoneno": phoneno,
      "type": type,
    };
  }
}