import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/cupertino.dart';
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
import 'package:lost_and_found/models/categories_model/color_model.dart';
import 'package:lost_and_found/models/delete_post/delete_post_reasons.dart';
import 'package:lost_and_found/models/handover/handover_owner.dart';
import 'package:lost_and_found/models/handover/location_suggestion.dart';
import 'package:lost_and_found/models/handover/police_station.dart';
import 'package:lost_and_found/models/posts_model/audio_video_model.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
import 'package:lost_and_found/models/posts_model/create_post1_response_model.dart';
import 'package:lost_and_found/models/posts_model/enquiry_model.dart';
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
    required String color,
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
      'color': color,
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

  Future<ResponseModel<List<HandoverOwnerModel>>> getOwnersList({
    required int postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '${ApiEndPoints.getHandoverOwnerList}/$postId',
      queryParams: {
        'page': page,
        'pageSize': pageSize,
      },
      addToken: false,
    );

    if (!response.isSuccess) {
      return response.asFailure<List<HandoverOwnerModel>>();
    }

    final outer = response.data as Map<String, dynamic>;
    final list = outer['data'] as List;

    return ResponseModel<List<HandoverOwnerModel>>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list
          .map((e) => HandoverOwnerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }



  Future<ResponseModel> generateHandoverOtp({required String phone}) async {
    return await apiClient.post(
      ApiEndPoints.generateHandoverOtp,
      data: {"phoneno": phone},
      addToken: false,
    );
  }

  Future<ResponseModel> verifyHandoverOtp({required String phone, required String otp}) async {
    return await apiClient.post(
      ApiEndPoints.verifyHandoverOtp,
      data: {"phoneno": phone, "otp": otp},
      addToken: false,
    );
  }

  Future<ResponseModel> createHandover({
    int? enquiryId,
    required int type,
    required int userId,
    required int postId,
    int? receiverId,
    int? receiverPostId,
    String? handoverImg,
    String? stationName,
    String? stationAddress,
    String? name,
    required String description,
    required String phoneno,
    required int handoverType,
  }) async {
    final body = {
      if (enquiryId != null) 'enquiry_id': enquiryId,
      'type': type,
      'user_id': userId,
      'post_id': postId,
      if (receiverId != null) 'receiver_id': receiverId,
      if (receiverPostId != null) 'receiver_postid': receiverPostId,
      if (handoverImg != null) 'handover_img': handoverImg,
      if (stationName != null) 'station_name': stationName,
      if (stationAddress != null) 'station_address': stationAddress,
      if (name != null) 'name': name,
      'description': description,
      'phoneno': phoneno,
      'handover_type': handoverType,
    };

    debugPrint('[Handover] JSON body: ${jsonEncode(body)}');
    debugPrint('[Handover] Request body: $body'); // <-- add this

    final response = await apiClient.post(ApiEndPoints.createHandover, data: body, addToken: false);

    debugPrint('[Handover] Raw response: status=${response.status}, '
        'message=${response.message}, data=${response.data}'); // <-- and this

    return response;
  }

  Future<ResponseModel<List<LocationSuggestionModel>>> searchLocation({required String query, int limit = 5,}) async {
    final response = await apiClient.get(ApiEndPoints.searchLocation,queryParams: {
      'query': query,
      'limit': limit,
    },
      addToken: false
    );

    if (!response.isSuccess) {
      return response.asFailure<List<LocationSuggestionModel>>();
    }

    final list = response.data as List;
    return ResponseModel<List<LocationSuggestionModel>> (
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list.map((e) => LocationSuggestionModel.fromJson(e as Map<String,dynamic>)).toList(),
    );
  }

  Future<ResponseModel<List<PoliceStationModel>>> getNearByPoliceStations({required double latitude, required double longitude,double radiusKm = 15,}) async {

    final response = await apiClient.get(ApiEndPoints.nearbyPoliceStations,addToken: false,queryParams: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radiusKm': radiusKm,
    });

    if (!response.isSuccess) {
      return response.asFailure<List<PoliceStationModel>>();
    }

    final list = response.data as List;
    return ResponseModel<List<PoliceStationModel>>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list
          .map((e) => PoliceStationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }


  Future<ResponseModel<List<ColorModel>>> getColors() async {
    final response = await apiClient.post(ApiEndPoints.getColors, data: {}, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<List<ColorModel>>();
    }

    final list = response.data as List;
    return ResponseModel<List<ColorModel>>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list.map((e) => ColorModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }


  Future<ResponseModel> createEnquiry({
    required int userId,
    required int postId,
    required int matchedPostId,
    required String name,
    required String description,
  }) async {
    final response = await apiClient.post(
      ApiEndPoints.createEnquiry,
      data: {
        'user_id': userId,
        'post_id': postId,
        'matched_postid': matchedPostId,
        'name': name,
        'description': description,
      },
      addToken: false,
    );

    debugPrint('[Enquiry] status=${response.status}, message=${response.message}, data=${response.data}');

    return response;
  }


  Future<ResponseModel<PostEnquiriesModel>> viewEnquiry({required int postId}) async {
    final response = await apiClient.get('${ApiEndPoints.viewEnquiry}/$postId', addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<PostEnquiriesModel>();
    }

    return ResponseModel<PostEnquiriesModel>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: PostEnquiriesModel.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<ResponseModel> logout({required int userId}) async {
    final response = await apiClient.post(
      ApiEndPoints.logout,
      data: {'userId': userId},
      addToken: false,
    );

    debugPrint('[Logout] status=${response.status}, message=${response.message}');

    return response;
  }



  Future<ResponseModel<List<DeletePostReasons>>> getDeleteAccountReasons() async {
    final response = await apiClient.get(ApiEndPoints.getReasonsDeleteAccount, addToken: false);

    if (!response.isSuccess) {
      return response.asFailure<List<DeletePostReasons>>();
    }

    final list = response.data as List;
    return ResponseModel<List<DeletePostReasons>>(
      status: response.status,
      message: response.message,
      currentState: response.currentState,
      data: list.map((e) => DeletePostReasons.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<ResponseModel> deleteAccount({required int userId, required String reason}) async {
    final response = await apiClient.delete(
      ApiEndPoints.deleteAccount,
      data: {
        'userId': userId,
        'reason': reason,
      },
      addToken: false,
    );

    debugPrint('[DeleteAccount] status=${response.status}, message=${response.message}');

    return response;
  }

  Future<ResponseModel> deleteProfileImage({required int userId}) async {
    return await apiClient.delete(
      ApiEndPoints.deleteProfileImage,
      data: {'userId': userId},
      addToken: false,
    );
  }


  Future<ResponseModel> createReport({
    required int userId,
    required String name,
    required String mobileno,
    required String email,
    required String description,
    String? imageId,
  }) async {
    final body = {
      'user_id': userId,
      'name': name,
      'mobileno': mobileno,
      'email': email,
      'description': description,
      if (imageId != null) 'image_id': imageId,
    };

    final response = await apiClient.post(
      ApiEndPoints.createReport,
      data: body,
      addToken: false,
    );

    print('[Report] status=${response.status}, message=${response.message}, data=${response.data}');

    return response;
  }
}