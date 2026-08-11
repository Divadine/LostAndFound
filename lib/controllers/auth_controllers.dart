import 'package:lost_and_found/models/api_model/response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_response_model.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
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
}
