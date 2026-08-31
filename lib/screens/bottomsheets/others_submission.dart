import 'package:flutter/material.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';
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
  const OthersHandover({super.key});

  @override
  State<OthersHandover> createState() => _OthersHandoverState();
}

class _OthersHandoverState extends State<OthersHandover> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
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
                text: "Receive to others",
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
            onChange: (String p1) {},
            onSubmit: (String p1) {},
          ),
        ),

        buildProofDocuments(
          title: '2. Description',
          subTitle: 'Provide details about the handover.',
          widget: GestureDetector(
            onTap: () {},
            child: AppTextField(
              hintText: 'Write a description',
              textController: descriptionController,
              maxLines: 4,
              onChange: (v) {},
              onSubmit: (v) {},
            ),
          ),
        ),

        buildTextFieldWithHeading(
          title: '3. Number',
          fieldWidget: AppTextField(
            //obscureText: obscurePhone,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                //color: AppColors.fieldGrey.withAlpha(90),
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

            //inputFormatters: [_phoneFormatter],
            // <-- do the masking here, not in onChange
            onChange: (value) {},
            onSubmit: (v) {},
          ),
        ),

        AppButton(
          title: 'Submit',
          onTap: () {
            AppRoutes.pop();
            AppDialogue.showPopup(
              context: context,
              content:
              TransferCompleted(
                type: TransferType.handOverToOthers,
                data: TransferData(
                  name: apiName,
                  avatarUrl: apiImage,
                  phoneNumber: apiPhone,
                  description: apiDescription,
                  proofPhotos: apiProofPhotos,
                ),
              )
            );
          },
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}
