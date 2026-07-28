import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  TextEditingController mobileNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: AppContainer(
          widget:  OtpSharedScreen(
            isAlternateNumber: false,
            mobileNumber: '',

          ).pad(),
        ).padHorizontal(18),
      ),
    );
  }
}