import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/authmodels/login_otp_verfiy_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';

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
      body: Center(
        child: AppContainer(
          widget:  OtpSharedScreen(
            autoSend: widget.autoSend,
            isAlternateNumber: false,
            mobileNumber: widget.mobileNo,
            onVerifyOtp: (otp) async {
              final response = await authController.verifyOtp(
                  phone: widget.mobileNo,
                  otp: otp,
                  type: 2,
              );
              print(response);
              if(response.status == 1){
                AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
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
    );
  }
}