import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/device_info_helper.dart';

class AuthControllers {
  final AuthRepository authRepository;

  AuthControllers({required this.authRepository});


  Future<bool> sendOtp(String phone, {required int type}) async {
    final result = await authRepository.generateOtp(phone: phone, type: type);
    return result["status"] == 1;
  }



  Future<ResponseModel<LoginOtpResponseModel>> verifyOtp({ required String phone,required String otp,required int type, String? name,}) async {
    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceType = DeviceInfoHelper.getDeviceType();
    final deviceToken = await DeviceInfoHelper.getDeviceToken();
    final appVersion = await DeviceInfoHelper.getAppVersion();

    final verify = LoginOtpVerifyModel(phoneno: phone,otp: otp,type: type,name: name ?? '',deviceId: deviceId, deviceType: deviceType, deviceToken:deviceToken, appVersion: appVersion );
    final response = await authRepository.verifyOtp(verify: verify);

    if (response.status == 1 && response.data?.token != null) {
      await AppPreferences.saveToken(response.data!.token);
      await AppPreferences.setIsLoggedIn(true);
    }
    return response;
  }



  Future<bool> generateMobileOtp(String phone) async {
    final result = await authRepository.generateMobileOtp(phone: phone,);
    return result["status"] == 1;
  }

  Future<ResponseModel<dynamic>> verifyMobileOtp({required String phone, required String otp, required int userId}) async {

    return await authRepository.verifyMobileOtp(phone: phone, userId: userId, otp: otp);
  }

  Future<ResponseModel<dynamic>> updateProfileForm(UpdateProfileForm profile) async {
    return await authRepository.updateProfile(profile);

  }


  Future<ResponseModel<ProfileScreenModel>> getProfile() => authRepository.getProfile();

}
