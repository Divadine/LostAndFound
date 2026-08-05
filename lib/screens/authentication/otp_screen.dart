import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/otp_flow.dart';
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

  const OtpScreen({super.key, });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  TextEditingController mobileNumberController = TextEditingController();
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
            isAlternateNumber: false,
            onVerified: (phone, otp)async {
           final v=  await authController.verifyOtp(phone: phone, otp: otp);
           if(v) {
             AppRoutes.pushNamed(AppRoutes.bottomScreen);
           }
           else{
             AppSnackBar.show(context: context, message: 'not loged in');
           }

            },
            authController: authController,
            mobileNumber: mobileNumberController.text,

          ).pad(),
        ).padHorizontal(18),
      ),
    );
  }
}