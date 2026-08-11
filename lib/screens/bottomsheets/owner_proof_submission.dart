import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/screens/authentication/otp_screen.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';

class HandoverProofDocuments extends StatefulWidget {
  const HandoverProofDocuments({super.key});

  @override
  State<HandoverProofDocuments> createState() => _HandoverProofDocumentsState();
}

class _HandoverProofDocumentsState extends State<HandoverProofDocuments> {
  bool isPhoneValid = false;
  bool isFormValid = false;
  bool isPinCodeValid = false;
  bool isVerified = false;
  File? selectedImage;
  String otp = '';
  Timer? timer;
  int seconds = 30;
  int? enableRestart;
  String? errorText;

  late final AuthControllers authController;
  TextEditingController textController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PhoneMaskFormatter _phoneFormatter = PhoneMaskFormatter();

  final List<FocusNode> focusNode = List.generate(4, (_) => FocusNode());
  List<bool> otpError = List.generate(4, (_) => false);
  List<bool> isFocused = List.generate(4, (_) => false);
  final ImagePicker picker = ImagePicker();

  void _onPinCodeChanged(String value) {
    setState(() {
      isPinCodeValid = AppUtils.validatePincode(value) == null;
    });
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

  final List<TextEditingController> _controller = List.generate(
    4,
    (_) => TextEditingController(),
  );

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });

      checkFormValidation();
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

  void checkFormValidation() {
    setState(() {
      isFormValid =
          selectedImage != null &&
          textController.text.trim().isNotEmpty &&
          _phoneFormatter.actualValue.length == 10;
    });
  }

  String maskPhone(String phone) {
    if (phone.length <= 2) return phone;

    return '${'*' * (phone.length - 2)}${phone.substring(phone.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        crossAxisAlignment: .start,
        mainAxisAlignment: .start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppContainer(
            widget: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  child: AppCachedNetworkImage(
                    imageUrl: "https://i.pravatar.cc/150?img=1",
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                const SizedBox(width: 15),

                AppText(
                  text: "Rahul Sharma",
                  fontSize: 13,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppUtils.getMatchColor(98).withAlpha(70),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    text: '${98}% match',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: AppUtils.getMatchColor(98),
                  ),
                ),
              ],
            ).pad(),
          ),

          buildProofDocuments(
            title: '1. Upload Proof Photos',
            subTitle: 'Upload clear photos as proof of handover.',
            widget: GestureDetector(
              onTap: pickImage,
              child: buildDottedBorder(
                title: "Add Photo",
                image: AssetImages.plus,
                selectedImage: selectedImage,
              ),
            ),
          ),

          buildProofDocuments(
            title: '2. Description',
            subTitle: 'Provide details about the handover.',
            widget: AppTextField(
              maxLines: 4,
              hintText: 'Write a describe',
              textController: textController,
              onChange: (v) {
                checkFormValidation();
              },
              onSubmit: (v) {},
            ),
          ),

          buildProofDocuments(
            title: '3. Phone Number',
            subTitle: 'OTP will be sent to this number for confirmation.',
            widget: buildTextFieldWithHeading(
              title: '',
              fieldWidget: AppTextField(
                //obscureText: obscurePhone,
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    //color: AppColors.fieldGrey.withAlpha(90),
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

                suffixIcon: AppIconWidget(
                  assetPath: AssetImages.phoneVerified,
                ).padHorizontal(),
                hintText: 'Enter a mobile number',
                textController: phoneController,
                textInputType: TextInputType.phone,

                maxLength: 10,
                inputFormatters: [_phoneFormatter],
                // <-- do the masking here, not in onChange
                validator: (e) {
                  if (e == null) return null;
                  return AppUtils.validateMobileNumber(
                    _phoneFormatter.actualValue,
                  );
                },
                onChange: (value) {
                  checkFormValidation();
                },
                onSubmit: (v) {},
              ),
            ),
          ),

          SizedBox(height: 5),

          AppButton(
            title: 'Send OTP',
            onTap: !isFormValid
                ? () {
                    AppDialogue.showPopup(
                      context: context,
                      content: OtpSharedScreen(
                        isAlternateNumber: false,
                        mobileNumber:phoneController.text ,
                        onVerifyOtp: (otp) async {
                          final response = await authController.verifyOtp(
                            phone: phoneController.text,
                            otp: otp,
                            type: 2,
                          );
                          if(response.status == 1){
                            AppDialogue.showPopup(context: context, content: HandOverToOwner());
                            AppRoutes.pushNamed(AppRoutes.bottomScreen);
                            return null;
                          }
                          return response.message;
                        },
                        onSendOtp: () async {
                          final response = await authController.sendOtp(phoneController.text, type: 0);
                          if (response.isSuccess) return null;
                          if (response.currentState == CurrentState.noInternet) {
                            return 'No internet connection. Please check your network.';
                          }
                          return response.message.isNotEmpty ? response.message : 'Failed to send OTP';
                        },

                      ),
                    );
                  }
                : () {},
            fontSize: 14,
            bgColor: isFormValid
                ? AppColors.primaryColor
                : AppColors.idCardColor,
            textColor: isFormValid ? AppColors.white : AppColors.black,
            radius: BorderRadius.circular(7),
          ),
        ],
      ).pad(2),
    );
  }
}

Widget buildDottedBorder({
  required String title,
  required String image,
  File? selectedImage,
}) {
  if (selectedImage != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        selectedImage,
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
  return DottedBorder(
    borderType: BorderType.RRect,
    radius: const Radius.circular(12),
    dashPattern: const [6, 4],
    color: AppColors.primaryColor,
    child: Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      child: selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                selectedImage,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconWidget(assetPath: image),
                const SizedBox(height: 8),
                AppText(
                  text: title,
                  fontSize: 12,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
    ),
  );
}

Widget buildProofDocuments({
  required String title,
  String? subTitle,
  required Widget widget,
}) {
  return Column(
    crossAxisAlignment: .start,
    mainAxisAlignment: .start,
    spacing: 10,

    children: [
      AppText(text: title, fontWeight: FontWeight.w500, fontSize: 14),
      if (subTitle != null)
        AppText(text: subTitle, fontWeight: FontWeight.w400, fontSize: 12),
      widget,
    ],
  );
}

class PhoneMaskFormatter extends TextInputFormatter {
  String actualValue = '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Detect delete
    if (newValue.text.length < oldValue.text.length) {
      actualValue = actualValue.substring(0, actualValue.length - 1);
    }
    // Detect typing
    else {
      String newChar = newValue.text.replaceAll('*', '');

      if (newChar.isNotEmpty) {
        actualValue += newChar.substring(newChar.length - 1);
      }
    }

    if (actualValue.length > 10) {
      actualValue = actualValue.substring(0, 10);
    }

    String masked = actualValue.length > 2
        ? '${'*' * (actualValue.length - 2)}${actualValue.substring(actualValue.length - 2)}'
        : actualValue;

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}
