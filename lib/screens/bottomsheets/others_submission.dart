import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
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

class OthersHandover extends StatefulWidget {
  final int postId;
  final int userId;
  final bool isReceiver;

  const OthersHandover({
    super.key,
    required this.postId,
    required this.userId,
    this.isReceiver = false,
  });

  @override
  State<OthersHandover> createState() => _OthersHandoverState();
}

class _OthersHandoverState extends State<OthersHandover> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;

  bool get _isFormValid =>
      nameController.text.trim().isNotEmpty &&
      descriptionController.text.trim().isNotEmpty &&
      numberController.text.trim().length == 10;

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

    String? uploadedImageRef;
    List<String> proofPhotoUrls = [];

    if (selectedImage != null) {
      final imageResponse = await authController.createImage(images: [selectedImage!]);

      if (!mounted) return;

      if (imageResponse.isSuccess && imageResponse.data != null && imageResponse.data!.isNotEmpty) {
        uploadedImageRef = imageResponse.data!.first.id.toString();
        proofPhotoUrls = imageResponse.data!.map((img) => img.imgPath).toList();
      } else {
        setState(() => isSubmitting = false);
        AppDialogue.showPopup(
          context: context,
          content: const AppText(text: 'Failed to upload proof photo. Please try again.'),
        );
        return;
      }
    }

    final response = await authController.createHandover(
      type: widget.isReceiver ? 2 : 1,
      userId: widget.userId,
      postId: widget.postId,
      handoverImg: uploadedImageRef,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      phoneno: numberController.text.trim(),
      handoverType: 3, // others
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response.isSuccess) {
      AppRoutes.pop();
      AppDialogue.showPopup(
        context: context,
        content: TransferCompleted(
          type: widget.isReceiver ? TransferType.receiveToOthers : TransferType.handOverToOthers,
          data: TransferData(
            name: nameController.text.trim(),
            phoneNumber: numberController.text.trim(),
            description: descriptionController.text.trim(),
            proofPhotos: proofPhotoUrls,
          ),
        ),
      );
    } else {
      AppDialogue.showPopup(
        context: context,
        content: AppText(
          text: response.message.isNotEmpty ? response.message : 'Failed to complete handover',
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppContainer(
            widget: Row(
              spacing: 7,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  child: AppIconWidget(
                    assetPath: AssetImages.threeDotsHorizontal,
                  ),
                ),
                const SizedBox(width: 15),
                AppText(
                  text: widget.isReceiver ? "Receive from others" : "Hand Over to others",
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ).pad(),
          ),
          buildTextFieldWithHeading(
            title: '1. Name',
            fieldWidget: AppTextField(
              hintText: 'Enter Name',
              textController: nameController,
              onChange: (String p1) => setState(() {}),
              onSubmit: (String p1) {},
            ),
          ),
          buildProofDocuments(
            title: '2. Description',
            subTitle: 'Provide details about the handover.',
            widget: AppTextField(
              hintText: 'Write a description',
              textController: descriptionController,
              maxLines: 4,
              onChange: (v) => setState(() {}),
              onSubmit: (v) {},
            ),
          ),
          buildTextFieldWithHeading(
            title: '3. Number',
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
              hintText: 'Enter a mobile number',
              textController: numberController,
              textInputType: TextInputType.phone,
              maxLength: 10,
              onChange: (value) => setState(() {}),
              onSubmit: (v) {},
            ),
          ),
          const SizedBox(height: 5),
          AppButton(
            title: isSubmitting ? 'Please wait...' : 'Submit',
            onTap: (_isFormValid && !isSubmitting) ? _onSubmit : () {},
            fontSize: 14,
            bgColor: _isFormValid ? AppColors.primaryColor : AppColors.idCardColor,
            textColor: _isFormValid ? AppColors.white : AppColors.black,
            radius: BorderRadius.circular(7),
          ),
        ],
      ),
    );
  }
}
