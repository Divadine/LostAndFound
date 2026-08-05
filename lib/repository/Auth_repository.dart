import 'dart:convert';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';
import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/pincode_details_model.dart';

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


  Future<dynamic> generateMobileOtp({required String phone}) async {
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
}