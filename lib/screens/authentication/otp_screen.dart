import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/authentication/profile_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String otp = '';
  Timer? timer;
  int seconds = 30;
  int? enableRestart;
  String? errorText;

  final List<TextEditingController> _controller = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNode = List.generate(4, (_) => FocusNode());
  List<bool> otpError = List.generate(4, (_) => false);
  List<bool> isFocused = List.generate(4, (_) => false);

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _startTimer();
    for (int i = 0; i < focusNode.length; i++) {
      focusNode[i].addListener(() {
        setState(() {
          isFocused[i] = focusNode[i].hasFocus;
        });
      });
    }
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      focusNode[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNode[index - 1].requestFocus();
    }

    otp = _controller.map((e) => e.text).join();
    if (otp.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 30;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    timer?.cancel();

    for (var controller in _controller) {
      controller.dispose();
    }

    for (var node in focusNode) {
      node.dispose();
    }

    super.dispose();
  }

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
                    text: 'Verification',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                  AppText(
                    text:
                        'Please enter the OTP sent to your entered mobile number to continue.',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    textAlign: TextAlign.center,
                  ).padHorizontal(),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: List.generate(_controller.length, (index) {
                      return Container(
                        height: 50,
                        width: 50,

                        child: TextField(
                          controller: _controller[index],
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isFocused[index]
                                    ? AppColors.grey
                                    : otpError[index]
                                    ? AppColors.red
                                    : _controller[index].text.isEmpty
                                    ? AppColors.grey
                                    : AppColors.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                width: 1.5,
                                color: isFocused[index]
                                    ? AppColors.grey
                                    : otpError[index]
                                    ? AppColors.red
                                    : _controller[index].text.isEmpty
                                    ? AppColors.grey
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ),
                          focusNode: focusNode[index],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.phone,
                          onChanged: (v) {
                            if (v.contains(' ') ||
                                v.contains('.') ||
                                v.contains(',') ||
                                v.contains('-')) {
                              setState(() {
                                errorText =
                                    "OTP cannot contain special character";
                                otpError[index] = true;
                              });
                              return;
                            }

                            setState(() {
                              errorText = null;
                              otpError[index] = false;
                            });

                            _onChanged(index, v);

                            _controller[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _controller[index].text.length,
                            );
                          },
                        ),
                      );
                    }),
                  ),

                  if (errorText != null)
                    AppText(
                      text: errorText!,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.errorRed,
                    ),

                  Container(
                    height: 20,
                    width: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.fieldGrey),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      spacing: 7,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconWidget(assetPath: AssetImages.time),
                        AppText(
                          text: _formatTime(seconds),
                          color: AppColors.navyBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),

                  AuthChangeText(
                    text1: 'Didn’t receive ?',
                    fadeColor: seconds != 0 ? AppColors.fadeColor : null,

                    tappableText: 'Resend',
                    onTap: () {
                      if (seconds == 0) {
                        setState(() {
                          _startTimer();
                        });
                      }
                    },
                  ),

                  AppButton(
                    title: 'Verify',
                    onTap: () {
                      otp = _controller.map((e) => e.text).join();

                      if (otp.length != 4) {
                        setState(() {
                          errorText = "Please enter OTP";

                          for (int i = 0; i < otpError.length; i++) {
                            otpError[i] = true;
                          }
                        });

                        return;
                      }

                      if (otp != "1234") {
                        setState(() {
                          errorText = "Please enter valid OTP";

                          for (int i = 0; i < otpError.length; i++) {
                            otpError[i] = true;
                          }
                        });

                        return;
                      }

                      // OTP success
                      setState(() {
                        errorText = null;

                        for (int i = 0; i < otpError.length; i++) {
                          otpError[i] = false;
                        }
                      });

                      // Navigate next screen

                      AppRoutes.pushNamed(
                        AppRoutes.profileScreen,
                        arguments: ProfileScreenModel(isFromEdit: false),
                      );
                    },
                    radius: BorderRadius.circular(8),
                  ).padHorizontal(30),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ).pad(18),
    );
  }
}
