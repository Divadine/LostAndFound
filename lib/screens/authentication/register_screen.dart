import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/otp_screen.dart';
import 'package:lost_and_found/screens/authentication/profile_screen.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? errorText;
  String? nameErrorText;
  late final AuthControllers authController;
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController textController = TextEditingController();

  StreamController<String?> numberStream = StreamController.broadcast();
  StreamController<String?> nameStream = StreamController.broadcast();

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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: Center(
        child: Form(
          key: _formKey,
          child: AppContainer(
            widget: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 20,
                  children: [
                    AppText(
                      text: 'Register Screen',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    AppText(
                      text:
                          'Start your journey by registering now. Fill in Your details to create an account.',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      textAlign: TextAlign.center,
                    ).padHorizontal(),
                
                    StreamBuilder(
                      stream: nameStream.stream,
                      builder: (context, asyncSnapshot) {
                        final nameData = asyncSnapshot.data;
                        return buildTextFieldWithHeading(
                          title: 'Name',
                          fieldWidget: Column(
                            children: [
                              AppTextField(
                                hintText: 'Enter Name',
                                textController: textController,
                                onChange: (v) {
                                  nameStream.add(AppUtils.validateName(v));
                                  // setState(() {
                                  //   nameErrorText = AppUtils.validateName(v);
                                  // });
                                },
                
                                onSubmit: (v) {},
                              ),
                              if (nameData != null)
                                buildErrorText(errorText: nameData),
                            ],
                          ),
                        );
                      },
                    ),
                
                    // +91
                    StreamBuilder(
                      stream: numberStream.stream,
                      builder: (context, asyncSnapshot) {
                        final numberData = asyncSnapshot.data;
                        return buildTextFieldWithHeading(
                          title: 'Mobile Number',
                          fieldWidget: Column(
                            children: [
                              Row(
                                spacing: 10,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      hintText: '+91',
                                      textController: TextEditingController(),
                                      onChange: (v) {},
                                      onSubmit: (v) {},
                                    ),
                                  ),
                
                                  Expanded(
                                    flex: 8,
                                    child: AppTextField(
                                      maxLength: 10,
                                      hintText: 'Enter a mobile number',
                                      textController: phoneController,
                                      onChange: (v) {
                                        print(v);
                                        numberStream.add(
                                          AppUtils.validateMobileNumber(v),
                                        );
                                        // setState(() {
                                        //   errorText =  AppUtils.validateMobileNumber(v);
                                        //
                                        // });
                                      },
                                      onSubmit: (v) {},
                                      textInputType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              if (numberData != null)
                                buildErrorText(errorText: numberData),
                            ],
                          ),
                        );
                      },
                    ),
                
                    AppButton(
                      title: 'Register',
                      onTap: () async{
                        if (_formKey.currentState!.validate()) {
                          //api
                          await authController.sendOtp(phoneController.text, type: 1);
                          //popup
                          AppDialogue.showPopup(context: context, content: OtpSharedScreen(
                              isAlternateNumber: false,
                              mobileNumber: phoneController.text,
                            onVerifyOtp: ( otp) async {
                
                            final response = await authController.verifyOtp(phone: phoneController.text, otp: otp, type: 1,name:textController.text);
                            if(response.status == 1){
                              print('^^^^^^^^^^^^^^^^^^^^^^^^^^^${response.data?.name}');
                              AppRoutes.pop();
                              AppRoutes.pushNamed(AppRoutes.profileScreen,arguments:
                              ProfileScreenModel(
                                isFromEdit: false,name: response.data?.name ?? textController.text.trim(),mobile: response.data?.phoneno ?? phoneController.text.trim(),userId: response.data?.userId, altMobileVerified: false,)
                              );
                              return null;
                            }
                            return response.message ;
                          },
                            onSendOtp: () async {
                              final response = await authController.sendOtp(phoneController.text, type: 1);
                              if (response.isSuccess) return null;
                              if (response.currentState == CurrentState.noInternet) {
                                return 'No internet connection. Please check your network.';
                              }
                              return response.message.isNotEmpty ? response.message : 'Failed to send OTP';
                            },
                
                          )
                          );
                          // AppRoutes.pushNamed(
                          //   AppRoutes.profileScreen,
                          //   arguments: ProfileScreenModel(
                          //     isFromEdit: false,
                          //     name: textController.text.trim(),
                          //     mobile: phoneController.text.trim(),
                          //     userId: null,
                          //   ),
                          // );
                        }
                      },
                      radius: BorderRadius.circular(8),
                    ).padHorizontal(30),
                
                    SizedBox(height: 15),
                
                    AuthChangeText(
                      text1: "Already have an Account?",
                      tappableText: 'Login',
                      onTap: () {
                        AppRoutes.pushNamed(AppRoutes.loginScreen);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ).pad(18),
        ),
      ),
    );
  }
}

Widget buildTextFieldWithHeading({
  required String title,
  required Widget fieldWidget,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText(text: title, fontSize: 14, fontWeight: FontWeight.w500),
      fieldWidget,
    ],
  );
}
