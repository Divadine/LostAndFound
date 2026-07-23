import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'handover_proff_documents.dart';

class PoliceHandoverProofDocuments extends StatefulWidget {
  const PoliceHandoverProofDocuments({super.key});

  @override
  State<PoliceHandoverProofDocuments> createState() => _PoliceHandoverProofDocumentsState();
}

class _PoliceHandoverProofDocumentsState extends State<PoliceHandoverProofDocuments> {

  File? selectedImage;
  TextEditingController textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return
      SingleChildScrollView(
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
                          text: "Peelamedu Police Station",
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          text:
                          'Fci road second street, Gandhimanagar, Coimbatore, Tamil Nadu - 641001',
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
                onTap:pickImage,
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
                //textController: textController,
                onChange: (v) {
        
                },
                onSubmit: (v) {},
                textController: textController,
              ),
            ),
        
        
        
            SizedBox(height: 5),
        
            AppButton(
              title: 'Submit',
              onTap:
                   () {
                AppDialogue.showPopup(
                  context: context,
                  content: HandOverToPolice());
              },
              fontSize: 14,
              bgColor: AppColors.primaryColor,
              radius: BorderRadius.circular(7),
            ),
          ],
        ),
      );
  }
}
