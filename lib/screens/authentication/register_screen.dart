import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            AppContainer(
              widget: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                child: Column(
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

                    buildTextFieldWithHeading(
                      title: 'Name',
                      fieldWidget:
                      Column(
                        children: [
                          AppTextField(
                            hintText: 'Enter Name',
                            textController: textController,

                            onChange: (v) {
                              setState(() {
                                nameErrorText = AppUtils.validateName(v);
                              });
                            },

                            onSubmit: (v) {},
                          ),
                          if (nameErrorText != null)
                            buildErrorText(errorText: nameErrorText ?? ''),
                        ],
                      ),

                    ),

                    // +91
                    buildTextFieldWithHeading(
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

                                    setState(() {
                                      errorText =  AppUtils.validateMobileNumber(v);

                                    });


                                  },
                                  onSubmit: (v) {},
                                  textInputType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          if (errorText != null)
                            buildErrorText(errorText: errorText ?? ''),
                        ],
                      ),
                    ),

                    AppButton(
                      title: 'Register',
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          AppDialogue.showPopup(
                            context: context,
                            content: DisclaimerPopUP(isFromOnBoard: true),
                          );
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
          ],
        ).pad(18),
      ),
    );
  }
}

Widget buildTextFieldWithHeading({
  required String title,
  required Widget fieldWidget,
}) {
  return Column(
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText(text: title, fontSize: 14, fontWeight: FontWeight.w500),
      fieldWidget,
    ],
  );
}
