import 'dart:io';

import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/posts_model/audio_video_model.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
import 'package:lost_and_found/models/posts_model/create_post1_response_model.dart';
import 'package:lost_and_found/models/posts_model/post_list_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/device_info_helper.dart';

class AuthControllers {
  final AuthRepository authRepository;

  AuthControllers({required this.authRepository});


  Future<ResponseModel> sendOtp(String phone, {required int type}) async {
    return await authRepository.generateOtp(phone: phone, type: type);

  }


  Future<ResponseModel<LoginOtpResponseModel>> verifyOtp({ required String phone,required String otp,required int type, String? name,}) async {
    final deviceId = await DeviceInfoHelper.getDeviceId();
    final deviceType = DeviceInfoHelper.getDeviceType();
    final deviceToken = await DeviceInfoHelper.getDeviceToken();
    final appVersion = await DeviceInfoHelper.getAppVersion();

    final verify = LoginOtpVerifyModel(phoneno: phone,otp: otp,type: type,name: name ?? '',deviceId: deviceId, deviceType: deviceType, deviceToken:deviceToken, appVersion: appVersion );
    final response = await authRepository.verifyOtp(verify: verify);

    if(response.isSuccess && response.data != null){
      final user = response.data!;

      if (user.token.isNotEmpty) {
        await AppPreferences.saveToken(user.token);
      }

      await AppPreferences.saveUserId(user.userId);
      await AppPreferences.setIsLoggedIn(true);
    }
    // if (response.status == 1 && response.data?.token != null) {
    //   await AppPreferences.saveToken(response.data!.token);
    //   await AppPreferences.saveUserId(response.data!.userId);
    //   await AppPreferences.setIsLoggedIn(true);
    // }
    return response;
  }



  Future<ResponseModel> generateMobileOtp(String phone) async {
    return  await authRepository.generateMobileOtp(phone: phone,);

  }

  Future<ResponseModel> verifyMobileOtp({required String phone, required String otp, required int userId}) async {

    return await authRepository.verifyMobileOtp(phone: phone, userId: userId, otp: otp);
  }

  Future<ResponseModel> updateProfileForm(UpdateProfileForm profile) async {
    return await authRepository.updateProfile(profile);

  }


  Future<ResponseModel<ProfileScreenModel>> getProfile({required int userId}) => authRepository.getProfile(userId: userId);

  Future<ResponseModel<CategoryListModel>> getCategories({required int page,required int limit, String? search }) async {
    return await authRepository.getCategories(page: page, limit: limit,search: search);
  }

  Future<ResponseModel<List<SubCategoryModel>>> getSubCategories({required int catId, String? search}) async {
    return await authRepository.getSubCategories(catId: catId,search: search);
  }

  Future<ResponseModel<List<DynamicFieldsModel>>> getDynamicFields({required int subCatId}) async {

    return await authRepository.getDynamicFields(subCategoryId: subCatId);
  }


  Future<ResponseModel<List<DynamicValueModel>>> getDynamicValues({required String brandMasterName}) async {
    return await authRepository.getDynamicValues(brandMasterName: brandMasterName);
  }

  Future<ResponseModel<List<DynamicValueModel>>> getDynamicNestedValues({required String brandMasterName, required String parentValue}) async {
    return await authRepository.getDynamicNestedValues(brandMasterName: brandMasterName, parentValue: parentValue);
  }

  Future<ResponseModel<List<PostImageModel>>> createImage({required List<File> images}) async {
    return await authRepository.createImage(images: images);
  }

  Future<ResponseModel<PostAudioModel>> createAudio({required File audio}) async {
    return await authRepository.createAudio(audio: audio);
  }

  Future<ResponseModel<PostVideoModel>> createVideo({required File video}) async {
    return await authRepository.createVideo(video: video);
  }

  Future<ResponseModel<CreatePostStep1Response>> createPostStep1({
    int? id,
    required int userId,
    required int postType,
    required int categoryId,
    required int subcategoryId,
    required String itemName,
    required String postImages,
    required List<Map<String, String>> postValues,
  }) async {
    return await authRepository.createPostStep1(
      id: id,
      userId: userId,
      postType: postType,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      itemName: itemName,
      postImages: postImages,
      postValues: postValues,
    );
  }

  Future<ResponseModel> completePostStep2({
    required int postId,
    required String location,
    required String address,
    required List<Map<String, String>> coordinates,
    required DateTime postDate,
    required String description,
    int? audioId,
    int? videoId,
  }) async {
    return await authRepository.completePostStep2(
      postId: postId,
      location: location,
      address: address,
      coordinates: coordinates,
      postDate: postDate,
      description: description,
      audioId: audioId,
      videoId: videoId,
    );
  }

  Future<ResponseModel<PostListModel>> getPost({required int userId,  required int postType,int? page, int? limit}) async {

    return await authRepository.getPosts(userId: userId, postType: postType,limit: limit,page: page);
}

}
