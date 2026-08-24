import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:intl/intl.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';
import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/pincode_details_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/delete_post/delete_post_reasons.dart';
import 'package:lost_and_found/models/posts_model/audio_video_model.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
import 'package:lost_and_found/models/posts_model/create_post1_response_model.dart';
import 'package:lost_and_found/models/posts_model/post_list_model.dart';
import 'package:lost_and_found/models/posts_model/post_match_item.dart';
import 'package:lost_and_found/models/posts_model/single_match_item.dart';

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

  Future<ResponseModel<List<PostImageModel>>> createImage({required List<File> images}) async {
    final formData = dio.FormData();
    for (final img in images) {
      formData.files.add(
          MapEntry(
        'images',
        await dio.MultipartFile.fromFile(img.path, filename: img.path.split('/').last),
      ));
    }

    final response = await apiClient.post(ApiEndPoints.createImage, data: formData, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<List<PostImageModel>>();
    }
    final list = response.data as List;
    return ResponseModel<List<PostImageModel>>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list.map((e) => PostImageModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<ResponseModel<PostAudioModel>> createAudio({required File audio}) async {
    final formData = dio.FormData.fromMap({
      'audio': await dio.MultipartFile.fromFile(audio.path, filename: audio.path.split('/').last),
    });

    final response = await apiClient.post(ApiEndPoints.createAudio, data: formData, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<PostAudioModel>();
    }
    return ResponseModel<PostAudioModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: PostAudioModel.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<ResponseModel<PostVideoModel>> createVideo({required File video}) async {
    final formData = dio.FormData.fromMap({
      'video': await dio.MultipartFile.fromFile(video.path, filename: video.path.split('/').last),
    });

    final response = await apiClient.post(ApiEndPoints.createVideo, data: formData, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<PostVideoModel>();
    }
    return ResponseModel<PostVideoModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: PostVideoModel.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<ResponseModel<CreatePostStep1Response>> createPostStep1({
    int? id,
    required int userId,
    required int postType,
    required int categoryId,
    required int subcategoryId,
    required String itemName,
    required String postImages, // comma-separated image ids, e.g. "1,2,3"
    required List<Map<String, String>> postValues, // [{"field": "color", "value": "red"}]
  }) async {
    final body = {
      if (id != null) 'id': id,
      'userid': userId,
      'post_type': postType,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'item_name': itemName,
      'postimages': postImages,
      'post_values': postValues,
    };

    final response = await apiClient.post(ApiEndPoints.createPostStep1, data: body, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<CreatePostStep1Response>();
    }
    return ResponseModel<CreatePostStep1Response>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: CreatePostStep1Response.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<ResponseModel> completePostStep2({
    required int postId,
    required String location,
    required String address,
    required List<Map<String, String>> coordinates, // [{"latitude": "..", "longitude": ".."}]
    required DateTime postDate,
    required String description,
    int? audioId,
    int? videoId,
  }) async {
    final body = {
      'postId': postId,
      'location': location,
      'address': address,
      'coordinates': coordinates,
      'post_date':  DateFormat('yyyy-MM-dd').format(postDate),
      'description': description,
      if (audioId != null) 'audio_id': audioId,
      if (videoId != null) 'video_id': videoId,
    };

    return await apiClient.post(ApiEndPoints.completePostStep2, data: body, addToken: false);
  }


  //postType = 0->lost, 1=> found
  Future<ResponseModel<PostListModel>> getPosts({required int userId,required int postType,  int? page ,int? limit,}) async {

    final response = await apiClient.get(ApiEndPoints.getPost,queryParams: {
      'user_id': userId,
      'post_type': postType,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    },
      addToken: false,
    );

    if (!response.isSuccess) {
      return response.asFailure<PostListModel>();
    }

    return ResponseModel<PostListModel>(
      message: response.message,
      status: response.status,
      currentState: response.currentState,
      data: PostListModel.fromJson(response.data as Map<String,dynamic>),
    );

  }


  Future<ResponseModel<List<DeletePostReasons>>> getDeleteReasons() async {
    final response = await apiClient.get(ApiEndPoints.getReasonsDeletePost,);
    if(!response.isSuccess){
      return response.asFailure<List<DeletePostReasons>>();
    }

    final list = response.data as List;
    
    return ResponseModel<List<DeletePostReasons>>(
        status: response.status,
        message: response.message,
      currentState: response.currentState,
      data: list.map((e) => DeletePostReasons.fromJson(e as Map<String, dynamic> )).toList(),
    );

  }

  Future<ResponseModel> deletePost({required int postId, required String reason}) async {
   return  await  apiClient.delete(ApiEndPoints.deletePost,
      data: {
        'postId': postId,
        'reason': reason,
    },
    addToken: false,
    );
  }


  Future<ResponseModel<PostListModel>> filterPosts({
    required int userId,
    required int postType,
    String? dateFilter,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    final response = await apiClient.get(
      ApiEndPoints.filterPost,
      queryParams: {
        'user_id': userId,
        'post_type': postType,
        if (dateFilter != null) 'date_filter': dateFilter,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
      addToken: false,
    );

    if (!response.isSuccess) {
      return response.asFailure<PostListModel>();
    }

    return ResponseModel<PostListModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: PostListModel.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<ResponseModel<PostMatchesModel>> getPostMatches({required int postId}) async {
    final response = await apiClient.get('${ApiEndPoints.matchingPost}/$postId',);

    if (!response.isSuccess) {
      return response.asFailure<PostMatchesModel>();
    }

    return ResponseModel<PostMatchesModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: PostMatchesModel.fromJson(response.data as Map<String, dynamic>)
    );
  }

  Future<ResponseModel<SingleMatchModel>> getSingleMatch({required int postId, required int userId}) async {
    final response= await apiClient.get( '${ApiEndPoints.viewSingleMatch}/$postId/$userId',addToken: false);


    if (!response.isSuccess) {
      return response.asFailure<SingleMatchModel>();
    }


    return ResponseModel<SingleMatchModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: SingleMatchModel.fromJson(response.data as Map<String, dynamic>),
    );
  }
}