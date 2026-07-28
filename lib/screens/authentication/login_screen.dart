import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/authentication/profile_screen.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: Column(

        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          AppContainer(
            widget: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                spacing: 20,
                children: [
                  AppText(
                    text: 'Login',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                  AppText(
                    text: 'Welcome back! We’re excited to have you here again.',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    textAlign: TextAlign.center,
                  ).padHorizontal(),

                  Form(
                    key: _formKey,
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTextFieldWithHeading(
                            title: 'Mobile Number',
                            fieldWidget: AppTextField(
                              prefixIcon: Container(
                                width: 20,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldGrey.withAlpha(90),
                                  border: Border(
                                    right: BorderSide(color: AppColors.fieldGrey),
                                  ),
                                ),
                                child: AppText(
                                  text: '+91',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: AppColors.numberGrey,
                                ),
                              ),
                              hintText: 'Enter a mobile number',
                              textController: phoneController,
                              textInputType: TextInputType.phone,
                              maxLength: 10,
                              validator: (e) {
                                if (e == null) return null;

                                return AppUtils.validateMobileNumber(e);
                              },
                              onChange: (v) {},
                              onSubmit: (v) {},
                            ),
                        ),


                      ],
                    ),
                  ),

                  AppButton(
                    title: "Login",
                    onTap: () async {
                      AppRoutes.pushNamed(AppRoutes.otpScreen);
                      // final verified = await AppDialogue.showPopup(
                      //   context: context,
                      //   content: OtpDialog(
                      //     mobileNumber: phoneController.text,
                      //     isAlternateNumber: false,
                      //   ),
                      // );
                      //
                      // if (verified) {
                      //   AppRoutes.pushNamed(
                      //     AppRoutes.profileScreen,
                      //     arguments: ProfileScreenModel(isFromEdit: false),
                      //   );
                      // }
                    },
                  ).padHorizontal(30),
                  // AppButton(
                  //   title: 'Login',
                  //   onTap: () {
                  //
                  //     if (_formKey.currentState!.validate()) {
                  //       if(AppPreferences.getIsLoggedIn() == true){
                  //         AppRoutes.pushNamed(AppRoutes.bottomScreen);
                  //
                  //       }
                  //       AppPreferences.setIsLoggedIn(true);
                  //
                  //
                  //     }
                  //   },
                  //   radius: BorderRadius.circular(8),
                  // ).padHorizontal(30),

                  SizedBox(height: 15),

                  AuthChangeText(
                    text1: "Don't have an account?",
                    tappableText: 'Register',
                    onTap: () {

                      AppRoutes.pushNamed(AppRoutes.registerScreen);
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ).pad(18),
    );
  }
}
