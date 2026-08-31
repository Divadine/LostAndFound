import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/handover/handover_owner.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import '../post/first_stepper_screen.dart';

class HandoverProofDocuments extends StatefulWidget {
  final HandoverOwnerModel selectedOwner;
  final int postId;
  final int enquiryId;

  const HandoverProofDocuments({
    super.key,
    required this.selectedOwner,
    required this.postId,
    required this.enquiryId,
  });

  @override
  State<HandoverProofDocuments> createState() => _HandoverProofDocumentsState();
}

class _HandoverProofDocumentsState extends State<HandoverProofDocuments> {
  bool isFormValid = false;
  bool isSubmitting = false;
  File? selectedImage;

  late final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  TextEditingController textController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PhoneMaskFormatter _phoneFormatter = PhoneMaskFormatter();

  @override
  void initState() {
    super.initState();
    _phoneFormatter.setInitialValue(widget.selectedOwner.phoneno);
    phoneController.text = _phoneFormatter.maskedValue;
    checkFormValidation();
  }

  @override
  void dispose() {
    textController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => selectedImage = File(image.path));
      checkFormValidation();
    }
  }

  void checkFormValidation() {
    setState(() {
      isFormValid = selectedImage != null && textController.text.trim().isNotEmpty;
    });
  }

  void _showError(String message) {
    AppDialogue.showPopup(
      context: context,
      content: AppText(text: message, textAlign: TextAlign.center),
    );
  }

  // Called only after OTP verification succeeds.
  Future<void> _submitHandover() async {
    if (selectedImage == null) return;

    setState(() => isSubmitting = true);

    try {
      final imageResponse = await authController.createImage(images: [selectedImage!]);
      debugPrint('[Handover] createImage -> status=${imageResponse.status}, '
          'message=${imageResponse.message}, data=${imageResponse.data}');

      if (!imageResponse.isSuccess || imageResponse.data == null || imageResponse.data!.isEmpty) {
        _showError(imageResponse.message.isNotEmpty ? imageResponse.message : 'Failed to upload photo');
        return;
      }
      final imageIds = imageResponse.data!.map((img) => img.id.toString()).join(',');

      final currentUserId = await AppPreferences.getUserId();
      if (currentUserId == null) {
        _showError('User ID not found. Please login again.');
        return;
      }

      if (widget.enquiryId == 0) {
        _showError('Missing enquiry reference. Please try again.');
        return;
      }

      // NOTE: `type` / `handoverType` values — confirm exact enum with backend.
      final handoverResponse = await authController.createHandover(
        type: 1,
        userId: currentUserId,
        postId: widget.postId,
        enquiryId: widget.enquiryId,
        receiverId: widget.selectedOwner.userId,
        receiverPostId: widget.selectedOwner.postId,
        handoverImg: imageIds,
        description: textController.text.trim(),
        phoneno: _phoneFormatter.actualValue,
        handoverType: 1,
      );

      debugPrint('[Handover] createHandover -> status=${handoverResponse.status}, '
          'message=${handoverResponse.message}, '
          'currentState=${handoverResponse.currentState}');

      if (!mounted) return;

      if (handoverResponse.isSuccess) {
        // Backend marks the post as completed as part of createHandover —
        // no separate "complete post" call needed.
        AppRoutes.pop();
        AppDialogue.showPopup(
          context: context,
          content:
          TransferCompleted(
            type: TransferType.handOverToOwner,
            data: TransferData(
              name: apiName,
              avatarUrl: apiImage,
              matchPercentage: apiMatchPercentage,
              phoneNumber: apiPhone,
              description: apiDescription,
              proofPhotos: apiProofPhotos,
            ),
          )
        );
      } else {
        _showError(handoverResponse.message.isNotEmpty
            ? handoverResponse.message
            : 'Failed to create handover');
      }
    } catch (e, st) {
      debugPrint('[Handover] Exception: $e');
      debugPrint('[Handover] StackTrace: $st');
      if (mounted) {
        _showError('Something went wrong while creating the handover.\n$e');
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
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
                  child: (widget.selectedOwner.profileImageUrl != null &&
                      widget.selectedOwner.profileImageUrl!.isNotEmpty)
                      ? AppCachedNetworkImage(
                    imageUrl: widget.selectedOwner.profileImageUrl!,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(30),
                  )
                      : Icon(Icons.person, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 15),
                AppText(
                  text: widget.selectedOwner.name,
                  fontSize: 13,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppUtils.getMatchColor(widget.selectedOwner.matchPercentage).withAlpha(70),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    text: '${widget.selectedOwner.matchPercentage}% match',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: AppUtils.getMatchColor(widget.selectedOwner.matchPercentage),
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
              onChange: (v) => checkFormValidation(),
              onSubmit: (v) {},
            ),
          ),

          buildProofDocuments(
            title: '3. Phone Number',
            subTitle: 'OTP will be sent to this number for confirmation.',
            widget: buildTextFieldWithHeading(
              title: '',
              fieldWidget: AppTextField(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.fieldGrey)),
                  ),
                  child: AppText(
                    text: '+91',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.numberGrey,
                  ),
                ),
                suffixIcon: AppIconWidget(assetPath: AssetImages.phoneVerified).padHorizontal(),
                hintText: 'Enter a mobile number',
                textController: phoneController,
                readOnly: true,
                textInputType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [_phoneFormatter],
                validator: (e) {
                  if (e == null) return null;
                  return AppUtils.validateMobileNumber(_phoneFormatter.actualValue);
                },
                onChange: (value) => checkFormValidation(),
                onSubmit: (v) {},
              ),
            ),
          ),

          SizedBox(height: 5),

          AppButton(
            title: isSubmitting ? 'Sending...' : 'Send OTP',
            onTap: (isFormValid && !isSubmitting)
                ? () {
              AppDialogue.showPopup(
                context: context,
                content: OtpSharedScreen(
                  isAlternateNumber: true,
                  mobileNumber: _phoneFormatter.maskedValue,
                  onVerifyOtp: (otp) async {
                    final response = await authController.verifyHandoverOtp(
                      phone: _phoneFormatter.actualValue,
                      otp: otp,
                    );
                    if (response.status == 1) {
                      await _submitHandover();
                      return null;
                    }
                    return response.message;
                  },
                  onSendOtp: () async {
                    final response = await authController.generateHandoverOtp(
                      phone: _phoneFormatter.actualValue,
                    );
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
            bgColor: isFormValid ? AppColors.primaryColor : AppColors.idCardColor,
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
      child: Column(
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

  void setInitialValue(String phone) {
    actualValue = phone.length > 10 ? phone.substring(phone.length - 10) : phone;
  }

  String get maskedValue => actualValue.length > 2
      ? '${'*' * (actualValue.length - 2)}${actualValue.substring(actualValue.length - 2)}'
      : actualValue;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.length < oldValue.text.length) {
      actualValue = actualValue.isEmpty ? '' : actualValue.substring(0, actualValue.length - 1);
    } else {
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