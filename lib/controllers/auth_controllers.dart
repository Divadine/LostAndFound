import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/utils/app_preferences.dart';

class AuthControllers {
  final AuthRepository authRepository;

  AuthControllers({required this.authRepository});

  Future<bool> sendOtp(String phone) async {
    final result = await authRepository.generateOtp(phone: phone, type: 2);

    if(result["status"] == 1){
      print(' ---------------------------$result');
      print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ${result["message"]}");
      return true;
    }
    return false;
  }

  Future<bool> verifyOtp({ required String phone,required String otp,}) async {
    final verify = LoginOtpVerifyModel(phoneno: phone, otp: otp, type: 1, name: "John",deviceId: "device123", deviceType: "Android", deviceToken: "abc123token", appVersion:  "1.0.0");

    final response = await authRepository.verifyOtp(verify: verify);
    if(response.status == 1){
      await AppPreferences.saveToken(response.data!.token);
      await AppPreferences.setIsLoggedIn(true);
      print('@@@@@tokenn--------  ${AppPreferences.saveToken(response.data!.token)}');
    }
    print('*********>>>>>>>>>>the response is --------------$response');
    print('*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response.status}');
    print('*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response.message}');
    print('*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response.data?.name}');
    print('*********>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response.data?.token}');
    return response.status == 1;
  }

  Future<ResponseModel<dynamic>> verifyMobileOtp({required String phone, required String otp, required int userId}) async {

    return await authRepository.verifyMobileOtp(phone: phone, userId: userId, otp: otp);
  }


}