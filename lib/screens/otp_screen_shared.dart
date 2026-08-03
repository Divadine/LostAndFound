import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class OtpSharedScreen extends StatefulWidget {
  final bool isAlternateNumber;
  final String mobileNumber;
  final VoidCallback? onVerified;

  const OtpSharedScreen({
    super.key,
    required this.isAlternateNumber,
    required this.mobileNumber,
    this.onVerified,
  });

  @override
  State<OtpSharedScreen> createState() => _OtpSharedScreenState();
}

class _OtpSharedScreenState extends State<OtpSharedScreen> {
  String otp = '';
  Timer? timer;
  int seconds = 30;
  int? enableRestart;
  String? errorText;
  StreamController<String> otpStream = StreamController.broadcast();
  StreamController<int> timeStream = StreamController.broadcast();



  final List<TextEditingController> _controller = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNode = List.generate(4, (_) => FocusNode());
  List<bool> otpError = List.generate(4, (_) => false);
  List<bool> isFocused = List.generate(4, (_) => false);

  @override
  void initState() {
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

    otpStream.add(otp);
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 30;
    timeStream.add(seconds);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
          seconds--;

          timeStream.add(seconds);
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
    otpStream.close();

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        if (widget.isAlternateNumber)
          AppIconWidget(assetPath: AssetImages.enterOtpIcon),
        AppText(
          text: widget.isAlternateNumber ? "Enter OTP" : "Verification",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
        AppText(
          text: widget.isAlternateNumber
              ? "We have sent a 4-digit OTP to +91 ${widget.mobileNumber}"
              : 'Please enter the OTP sent to your entered mobile number to continue.',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: AppColors.primaryColor,
          textAlign: TextAlign.center,
        ).padHorizontal(),

        StreamBuilder<String>(
          stream: otpStream.stream,
            initialData: '',
          builder: (context, asyncSnapshot) {
            final otpData = asyncSnapshot.data ?? '';
            return Row(
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
                              :otpData.length <= index
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
                              :otpData.length <= index
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
                          errorText = "OTP cannot contain special character";
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
            );
          }
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
              StreamBuilder(
                stream: timeStream.stream,
                builder: (context, asyncSnapshot) {
                  final timeData = asyncSnapshot.data ?? 0;
                  return AppText(
                    text: _formatTime(timeData),
                    color: AppColors.navyBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  );
                }
              ),
            ],
          ),
        ),

        StreamBuilder(
          stream: timeStream.stream,
            //initialData: 30,
          builder: (context, asyncSnapshot) {

            final reSendData = asyncSnapshot.data ?? 0;
            return AuthChangeText(
              text1: 'Didn’t receive ?',
              fadeColor: reSendData != 0 ? AppColors.fadeColor : null,
              tappableText: 'Resend',
              onTap: () {
                if (reSendData == 0) {
                  setState(() {

                    _startTimer();
                  });
                }
              },
            );
          }
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

            widget.onVerified?.call();

            //want to change based on altrnatenumber,handover
            // setState(() {
            //
            // });
            // AppRoutes.pushNamed(AppRoutes.bottomScreen);

          },
          radius: BorderRadius.circular(8),
        ).padHorizontal(30),
        SizedBox(height: 15),
      ],
    );
  }
}
