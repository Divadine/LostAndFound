import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'owner_proof_submission.dart';

class PoliceHandoverProofDocuments extends StatefulWidget {
  final int postId;
  final int userId;
  final String phoneNumber;
  final int? enquiryId;
  final int? receiverId;
  final int? receiverPostId;
  final int handoverType; // owner=1 / police=2 / others=3
  final String stationName;
  final String stationAddress;
  final String? latitude;
  final String? longitude;

  const PoliceHandoverProofDocuments({
    super.key,
    required this.postId,
    required this.userId,
    required this.phoneNumber,
    this.enquiryId,
    this.receiverId,
    this.receiverPostId,
    required this.handoverType,
    required this.stationName,
    required this.stationAddress,
    this.latitude,
    this.longitude,
  });

  @override
  State<PoliceHandoverProofDocuments> createState() => _PoliceHandoverProofDocumentsState();
}

class _PoliceHandoverProofDocumentsState extends State<PoliceHandoverProofDocuments> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  File? selectedImage;
  final TextEditingController textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool isSubmitting = false;

  bool get _isFormValid => selectedImage != null && textController.text.trim().isNotEmpty;

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  Future<void> _onSubmit() async {
    if (!_isFormValid || isSubmitting) return;

    setState(() => isSubmitting = true);

    final imageResponse = await authController.createImage(images: [selectedImage!]);

    if (!mounted) return;

    if (!imageResponse.isSuccess || imageResponse.data == null || imageResponse.data!.isEmpty) {
      setState(() => isSubmitting = false);
      AppDialogue.showPopup(
        context: context,
        content: const AppText(text: 'Failed to upload proof photo. Please try again.'),
      );
      return;
    }

    final uploadedImageRef = imageResponse.data!.first.id.toString();

    final response = await authController.createHandover(
      enquiryId: widget.enquiryId,
      // `type` — CONFIRM with backend what this represents; kept separate
      // from `handoverType` (owner/police/others) below.
      type: 1,
      userId: widget.userId,
      postId: widget.postId,
      receiverId: widget.receiverId,
      receiverPostId: widget.receiverPostId,
      handoverImg: uploadedImageRef,
      stationName: widget.stationName,
      stationAddress: widget.stationAddress,
      description: textController.text.trim(),
      phoneno: widget.phoneNumber,
      handoverType: widget.handoverType,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response.isSuccess) {
      AppRoutes.pop();
      AppDialogue.showPopup(
        context: context,
        content: HandOverToPolice(),
        // If HandOverToPolice's constructor accepts stationName/stationAddress,
        // pass widget.stationName / widget.stationAddress here.
      );
    } else {
      AppDialogue.showPopup(
        context: context,
        content: AppText(text: response.message.isNotEmpty ? response.message : 'Failed to complete handover'),
      );
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppIconWidget(assetPath: AssetImages.policeStation),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: widget.stationName.isNotEmpty ? widget.stationName : 'Police Station',
                        fontSize: 14,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      AppText(
                        text: widget.stationAddress,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.fieldGrey,
                        textOverflow: TextOverflow.ellipsis,
                        maxLine: 3,
                      ),
                    ],
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
              hintText: 'Write a description',
              onChange: (v) => setState(() {}),
              onSubmit: (v) {},
              textController: textController,
            ),
          ),

          SizedBox(height: 5),

          AppButton(
            title: isSubmitting ? 'Please wait...' : 'Submit',
            onTap: (_isFormValid && !isSubmitting) ? _onSubmit : () {},
            fontSize: 14,
            bgColor: _isFormValid ? AppColors.primaryColor : AppColors.idCardColor,
            textColor: _isFormValid ? AppColors.white : AppColors.black,
            radius: BorderRadius.circular(7),
          ),
        ],
      ).pad(2),
    );
  }
}