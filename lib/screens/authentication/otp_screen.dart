import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/posts_model/post_list_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNo;
  final bool autoSend;

  const OtpScreen({super.key, required this.mobileNo, this.autoSend = true});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  // TextEditingController mobileNoNumberController = TextEditingController();
  late final AuthControllers authController;


  @override
  void initState() {
    super.initState();
    authController = AuthControllers(
      authRepository: AuthRepository(
        apiClient: ApiClient(),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: AppUtils.isTab ? 600 : double.infinity,),
            child: AppContainer(
              widget:  OtpSharedScreen(
                autoSend: widget.autoSend,
                isAlternateNumber: false,
                mobileNumber: widget.mobileNo,
                shouldPop: false,
                onVerifyOtp: (otp) async {
                  final response = await authController.verifyOtp(
                      phone: widget.mobileNo,
                      otp: otp,
                      type: 2,
                  );
                  print(response);
                  if(response.status == 1 && response.data != null){
                    final int userId = response.data!.userId;
                    final int status = response.data!.status;
        
                    if (status >= 1) {
                      // Profile completed. Check for posts before deciding navigation.
                      bool hasPosted = false;
                      try {
                        final postResults = await Future.wait([
                          authController.getPost(userId: userId, postType: 0, limit: 1),
                          authController.getPost(userId: userId, postType: 1, limit: 1),
                        ]);
        
                        if (postResults[0].isSuccess &&
                            postResults[0].data != null &&
                            postResults[0].data!.total > 0) {
                          hasPosted = true;
                        } else if (postResults[1].isSuccess &&
                            postResults[1].data != null &&
                            postResults[1].data!.total > 0) {
                          hasPosted = true;
                        }
                      } catch (e) {
                        debugPrint('OTP: Failed to check post status: $e');
                      }
        
                      if (hasPosted) {
                        await AppPreferences.setProfileStatus(2);
                        AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
                      } else {
                        await AppPreferences.setProfileStatus(1);
                        AppRoutes.pushAndRemoveUntil(AppRoutes.firstHomeScreen);
                      }
                    } else {
                      final profileResponse = await authController.getProfile(userId: userId);
                      if (profileResponse.isSuccess && profileResponse.data != null) {
                        AppRoutes.pushAndRemoveUntil(
                          AppRoutes.profileScreen,
                          arguments: profileResponse.data,
                        );
                      } else {
                        // Fallback to profile screen with basic info if fetch fails
                        AppRoutes.pushAndRemoveUntil(
                          AppRoutes.profileScreen,
                          arguments: ProfileScreenModel(
                            isFromEdit: false,
                            userId: userId,
                            name: response.data!.name,
                            mobile: response.data!.phoneno,
                            altMobileVerified: false,
                          ),
                        );
                      }
                    }
                    return null;
                  }
                  return response.message;
                },
                onSendOtp: () async {
                  final response = await authController.sendOtp(widget.mobileNo, type: 2);
                  if (response.isSuccess) return null;
                  if (response.currentState == CurrentState.noInternet) {
                    return 'No internet connection. Please check your network.';
                  }
                  return response.message.isNotEmpty ? response.message : 'Failed to send OTP';
                },
        
        
              ).pad(),
            ).padHorizontal(18),
          ),
        ),
      ),
    );
  }
}