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
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<ResponseModel> generateOtp({required String phone, required int type}) async {
    return await apiClient.post(ApiEndPoints.generateOtp,data: LoginModel(phoneno: phone, type: type).toJson(),addToken: false);

  }


  Future<ResponseModel<LoginOtpResponseModel>> verifyOtp({required LoginOtpVerifyModel verify}) async {
    final response = await apiClient.post(ApiEndPoints.verifyOtp,data: verify.toJson(),addToken: false);
    if(!response.isSuccess){
      return ResponseModel<LoginOtpResponseModel> (status: response.status,message: response.message,currentState: response.currentState);
    }

      return ResponseModel<LoginOtpResponseModel>(status: response.status,message: response.message,data: LoginOtpResponseModel.fromJson(response.data),currentState: response.currentState);
}


  // Future<ResponseModel<LoginOtpResponseModel>> verifyOtp({required LoginOtpVerifyModel verify})async {
  //   final response = await apiClient.post(ApiEndPoints.verifyOtp, verify.toJson(),);
  //
  //   return ResponseModel<LoginOtpResponseModel>.fromJson(response.data,(json) => LoginOtpResponseModel.fromJson(json));
  //
  // }


  Future<ResponseModel<PinCodeDetailsModel>> getAddressByPinCode({required String pinCode}) async {
    final response = await apiClient.post(ApiEndPoints.getAddressByPincode,data: {"pincode" : pinCode},
        // Change to false if your backend says this API is public.
        addToken: false);

    if(!response.isSuccess){
      return ResponseModel<PinCodeDetailsModel>(
          status: response.status,
          message: response.message,
          currentState: response.currentState
         );
    }
    return ResponseModel<PinCodeDetailsModel>(
        status: response.status,
        message: response.message,
        currentState: response.currentState,
        data: PinCodeDetailsModel.fromJson(response.data as Map<String,dynamic>),
       );
  }

  // Future<ResponseModel<PinCodeDetailsModel>> getAddressByPinCode({required String pinCode}) async {
  //   final response = await apiClient.post(ApiEndPoints.getAddressByPincode, {"pincode" : pinCode});
  //   return ResponseModel<PinCodeDetailsModel>.fromJson(response.data,(json) =>PinCodeDetailsModel.fromJson(json));
  // }


  Future<ResponseModel> generateMobileOtp({required String phone}) async {
    return  await apiClient.post(ApiEndPoints.generateMobileOtp,data: {"phoneno" : phone},addToken: false,);

  }

  // Future<dynamic> generateMobileOtp({required String phone,}) async {
  //   final response = await apiClient.post(ApiEndPoints.generateMobileOtp, {"phoneno" : phone});
  //   return response.data;
  // }

  Future<ResponseModel> verifyMobileOtp({required String phone, required int userId, required String otp}) async {
    return  await apiClient.post(ApiEndPoints.verifyMobileOtp,data: {
      "phoneno": phone,
      "user_id": userId,
      "otp": otp,
    },
        addToken: false,);


}

  // Future<ResponseModel<dynamic>> verifyMobileOtp({required String phone, required int userId, required String otp}) async {
  //   final response = await apiClient.post(ApiEndPoints.verifyMobileOtp, {
  //     "phoneno": phone,
  //     "user_id": userId,
  //     "otp": otp,
  //   });
  //   print('????????/////////////////////////////////////////$response');
  //   return ResponseModel<dynamic>.fromJson(response.data,(json) => json);
  // }

  Future<ResponseModel> updateProfile(UpdateProfileForm profile) async {
    final map  =  profile.toMap();
    final file = map.remove('profileImg') as File?;
    final formData = dio.FormData.fromMap({...map,
      if(file != null)
        'profileImg' : await dio.MultipartFile.fromFile(file.path,filename: file.path.split('/').last,)
    });
    
    return  await apiClient.post(ApiEndPoints.updateProfile,data: formData,addToken: false);
  }

  // Future<ResponseModel<dynamic>>  updateProfile(UpdateProfileForm profile) async {
  //   final map  =  profile.toMap();
  //   final file = map.remove('profileImg') as File?;
  //   final formData =  dio.FormData.fromMap({
  //     ...map,
  //     if (file != null)
  //       'profileImg': await dio.MultipartFile.fromFile(
  //         file.path,
  //         filename: file.path.split('/').last,
  //       ),
  //   });
  //  final response = await  apiClient.post(ApiEndPoints.updateProfile,formData);
  //  print('response is **********************************$response');
  //   return ResponseModel<dynamic>.fromJson(response.data,(json) => json);
  // }


  Future<ResponseModel<ProfileScreenModel>> getProfile({required int userId}) async {
    final response = await apiClient.post(ApiEndPoints.getUserInfo,data:{"id": userId},addToken: false );

    if (!response.isSuccess) {
      return ResponseModel<ProfileScreenModel>(
        status: response.status,
        message: response.message,
          currentState: response.currentState
      );
    }

    final list = response.data as List;
    if(list.isEmpty){
      return ResponseModel<ProfileScreenModel>(
        status: 0,
        message: "Profile data not found.",
          currentState: response.currentState
      );
    }
    return ResponseModel<ProfileScreenModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: ProfileScreenModel.fromJson(list.first as Map<String, dynamic>,),

    );
  }
  // Future<ResponseModel<ProfileScreenModel>> getProfile({required int userId}) async {
  //   final response = await apiClient.post(ApiEndPoints.getUserInfo, {"id": userId});
  //   return ResponseModel<ProfileScreenModel>.fromJson(
  //     response.data,
  //         (json) {
  //       final list = json as List;
  //       return ProfileScreenModel.fromJson(list.first as Map<String, dynamic>);
  //     },
  //   );
  // }

  Future <ResponseModel<CategoryListModel>> getCategories({required int page, required int limit, String? search}) async {
    final response = await apiClient.get(ApiEndPoints.getCategory,queryParams: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty)
        'search': search,
    },
      addToken: false,
    );
    if (!response.isSuccess) {
      return ResponseModel<CategoryListModel>(
        status: response.status,
        message: response.message,
          currentState: response.currentState
      );
    }

    return ResponseModel<CategoryListModel>(
      status: response.status,
      message: response.message,
      data: CategoryListModel.fromJson(
        response.data as Map<String, dynamic>,
      ),

    );
  }

  // Future <ResponseModel<CategoryListModel>> getCategories({required int page, required int limit, String? search}) async {
  //  final response = await  apiClient.get(ApiEndPoints.getCategory,queryParams: {'page': page,  'limit': limit,if (search != null && search.isNotEmpty) 'search': search,});
  //  return ResponseModel<CategoryListModel>.fromJson(response.data, (json) => CategoryListModel.fromJson(json));
  // }

  Future<ResponseModel<List<SubCategoryModel>>> getSubCategories({required int catId, String? search}) async {
    final response = await apiClient.get(ApiEndPoints.getSubCategory,queryParams: {
      'category_id' : catId,
      if (search != null && search.isNotEmpty) 'search': search,
    },
      addToken: false
    );

    if (!response.isSuccess) {
      return ResponseModel<List<SubCategoryModel>>(
        status: response.status,
        message: response.message,
          currentState: response.currentState
      );
    }

    final list = response.data as List;

    return ResponseModel<List<SubCategoryModel>>(
      status: response.status,
      message: response.message,
      data: list
          .map(
            (e) => SubCategoryModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );

  }


  // Future<ResponseModel<List<SubCategoryModel>>> getSubCategories({required int catId, String? search}) async {
  //   final response = await apiClient.get(ApiEndPoints.getSubCategory,queryParams: {
  //     'category_id' : catId, if (search != null && search.isNotEmpty) 'search': search,
  //   }
  //   );
  //
  //   return ResponseModel<List<SubCategoryModel>>.fromJson(response.data,(json) => (json as List).map((e) => SubCategoryModel.fromJson(e as Map<String,dynamic>)).toList());
  // }

  Future<ResponseModel<List<DynamicFieldsModel>>> getDynamicFields({required int subCategoryId,}) async {
    final response = await apiClient.get(ApiEndPoints.getDynamicFields,queryParams: {
      'subcategory_id': subCategoryId,
    },
    addToken: false
    );

    if (!response.isSuccess) {
      return ResponseModel<List<DynamicFieldsModel>>(
        status: response.status,
        message: response.message,
          currentState: response.currentState
      );
    }

    final list = response.data as List;

    return ResponseModel<List<DynamicFieldsModel>>(
      status: response.status,
      message: response.message,
      data: list
          .map(
            (e) => DynamicFieldsModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),

    );
  }


  // Future <ResponseModel<List<DynamicFieldsModel>>> getDynamicFields({required int subCategoryId}) async{
  //  final response =  await apiClient.get(ApiEndPoints.getDynamicFields,queryParams: {'subcategory_id': subCategoryId});
  //   return ResponseModel<List<DynamicFieldsModel>>.fromJson(response.data, (json) =>(json as List).map((e) =>DynamicFieldsModel.fromJson(e as Map<String, dynamic>)).toList() );
  // }


  Future<ResponseModel<List<DynamicValueModel>>> getDynamicValues({required String brandMasterName})async {
    final response = await apiClient.get(ApiEndPoints.getDynamicValues,queryParams: {
      "master_name" : brandMasterName
    });

    if(!response.isSuccess){
      return ResponseModel(
          status: response.status,
          message: response.message,
        currentState: response.currentState
      );
    }
    final list = response.data as List;

    return ResponseModel<List<DynamicValueModel>>(
      message: response.message,
        status: response.status,
        data: list.map((e) => DynamicValueModel.fromJson(e as Map<String,dynamic>)).toList(),
        currentState: response.currentState

    );

  }

  Future <ResponseModel<List<DynamicValueModel>>> getDynamicNestedValues({required String brandMasterName, required String parentValue}) async {
    final response = await apiClient.get(ApiEndPoints.getDynamicNestedValues,queryParams:{
      'master_name':brandMasterName,
      'parent_value': parentValue,
    },
    addToken: false);

    if (!response.isSuccess) {
      return ResponseModel<List<DynamicValueModel>>(
        status: response.status,
        message: response.message,
        currentState: response.currentState,
      );
    }
    final list = response.data as List;
    return ResponseModel<List<DynamicValueModel>> (
      status: response.status,
      message: response.message,
      data: list.map((e) => DynamicValueModel.fromJson(e as Map<String,dynamic>)).toList(),
      currentState: response.currentState
    );
  }


}