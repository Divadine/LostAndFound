import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
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
  // final authController = AuthControllers(
  //     AuthRepository(
  //         ApiClient()
  //     )
  // );

  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorText;

  StreamController<String?> numberStream = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
   // phoneController.text = AppPreferences.getPhone() ?? '';
  }

  @override
  void dispose() {
    phoneController.dispose(


    );
    numberStream.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                          fieldWidget: StreamBuilder(
                            stream: numberStream.stream,
                            builder: (context, snapshot) {
                              final snapData = snapshot.data;
                              errorText = snapData;
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 10,
                                    children: [
                                      //+91
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          readOnly: true,
                                          hintText: '+91',
                                          textController:
                                              TextEditingController(),
                                          textInputType: TextInputType.phone,
                                          maxLength: 10,
                                          onChange: (v) {},
                                          onSubmit: (v) {},
                                        ),
                                      ),

                                      Expanded(
                                        flex: 8,
                                        child: AppTextField(
                                          hintText: 'Enter a mobile number',
                                          textController: phoneController,
                                          textInputType: TextInputType.phone,
                                          maxLength: 10,
                                          onChange: (v) {
                                            errorText =
                                                AppUtils.validateMobileNumber(
                                                  v,
                                                );
                                            numberStream.add(errorText);
                                          },

                                          onSubmit: (v) {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (errorText != null)
                                    buildErrorText(errorText: errorText ?? ''),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppButton(
                    radius: BorderRadius.circular(8),
                    title: "Login",
                    onTap: () async {
                      errorText = AppUtils.validateMobileNumber(
                        phoneController.text,
                      );

                      numberStream.add(errorText);
                      if (errorText == null &&
                          phoneController.text.isNotEmpty) {
                        print('________________________________________________');
                        print(phoneController.text);
                        //AppUiHelper.showLoadingDialog(context);
                        final response = await authController.sendOtp(phoneController.text, type: 2,);
                        if (!mounted) return;

                        if(response.isSuccess){
                          AppRoutes.pushNamed(AppRoutes.otpScreen, arguments: {
                            'mobileNo': phoneController.text,
                            'autoSend': false,
                          });
                        }else if (response.currentState == CurrentState.noInternet) {
                          AppSnackBar.show(
                            context: context,
                            message: 'No internet connection. Please check your network and try again.',
                          );
                        }

                        else{
                          AppSnackBar.show(context: context, message: response.message.isNotEmpty ? response.message  : 'OTP generation failed');
                        }
                      }



                    },
                  ).padHorizontal(30),
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
