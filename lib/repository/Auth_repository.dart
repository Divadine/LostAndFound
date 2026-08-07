import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';
import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/pincode_details_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<dynamic> generateOtp({required String phone, required int type}) async {
    final response = await apiClient.post(ApiEndPoints.generateOtp,LoginModel(phoneno: phone, type: type).toJson()  );
    return response.data;
  }


  Future<ResponseModel<LoginOtpResponseModel>> verifyOtp({required LoginOtpVerifyModel verify})async {
    final response = await apiClient.post(ApiEndPoints.verifyOtp, verify.toJson(),);

    return ResponseModel<LoginOtpResponseModel>.fromJson(response.data,(json) => LoginOtpResponseModel.fromJson(json));

  }

  Future<ResponseModel<PinCodeDetailsModel>> getAddressByPinCode({required String pinCode}) async {
    final response = await apiClient.post(ApiEndPoints.getAddressByPincode, {"pincode" : pinCode});
    return ResponseModel<PinCodeDetailsModel>.fromJson(response.data,(json) =>PinCodeDetailsModel.fromJson(json));
  }


  Future<dynamic> generateMobileOtp({required String phone,}) async {
    final response = await apiClient.post(ApiEndPoints.generateMobileOtp, {"phoneno" : phone});
    return response.data;
  }

  Future<ResponseModel<dynamic>> verifyMobileOtp({required String phone, required int userId, required String otp}) async {
    final response = await apiClient.post(ApiEndPoints.verifyMobileOtp, {
      "phoneno": phone,
      "user_id": userId,
      "otp": otp,
    });
    print('????????/////////////////////////////////////////$response');
    return ResponseModel<dynamic>.fromJson(response.data,(json) => json);
  }

  Future<ResponseModel<dynamic>>  updateProfile(UpdateProfileForm profile) async {
    final map  =  profile.toMap();
    final file = map.remove('profileImg') as File?;
    final formData =  dio.FormData.fromMap({
      ...map,
      if (file != null)
        'profileImg': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
    });
   final response = await  apiClient.post(ApiEndPoints.updateProfile,formData);
   print('response is **********************************$response');
    return ResponseModel<dynamic>.fromJson(response.data,(json) => json);
  }


  Future<ResponseModel<ProfileScreenModel>> getProfile({required int userId}) async {
    final response = await apiClient.post(ApiEndPoints.getUserInfo, {"id": userId});
    return ResponseModel<ProfileScreenModel>.fromJson(
      response.data,
          (json) {
        final list = json as List;
        return ProfileScreenModel.fromJson(list.first as Map<String, dynamic>);
      },
    );
  }
}