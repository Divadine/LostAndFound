import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/police_handover_proof_documents.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'handover_proff_documents.dart';

class PoliceStationHandOver extends StatefulWidget {
  const PoliceStationHandOver({super.key});

  @override
  State<PoliceStationHandOver> createState() => _PoliceStationHandOverState();
}

class _PoliceStationHandOverState extends State<PoliceStationHandOver> {
  TextEditingController mapTextController = TextEditingController();
  TextEditingController textController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          text: 'Hand Over to Police Station',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        AppText(
          text: 'Please Provide the Police Station information',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        buildTextFieldWithHeading(
          title: 'Police Station Location',
          fieldWidget: AppTextField(
            hintText: 'Enter Police station name or location',
            textController: mapTextController,
            onChange: (v) {},
            onSubmit: (v) {},
          ),
        ),

        Align(
          alignment: AlignmentGeometry.centerLeft,
          child: AppText(
            text: 'Example : T. Nagar Police station, Chennai',
            fontWeight: FontWeight.w300,
            fontSize: 10,
            color: AppColors.black.withAlpha(100),
          ),
        ),

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            AppText(
              text: 'Police station location Pin',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ).pad(1),
            SizedBox(height: 7,),

            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.fieldGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Image background
                  Positioned.fill(
                    child: AppIconWidget(
                      assetPath: AssetImages.map,
                      // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Bottom button
                  Center(
                    child: AppTextField(
                      hintText: '',
                      textController: TextEditingController(
                        text: "Pin Location on Map",
                      ),
                      textBackgroundColor: AppColors.primaryColor,
                      onChange: (e) {},
                      suffixIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ).pad(12),
                      readOnly: true,
                      onSubmit: (e) {},
                      prefixIcon: AppIconWidget(
                        assetPath: AssetImages.map_marker,
                        size: 20,
                      ).pad(12),
                    ).padHorizontal(15),
                  ),
                ],
              ),
            ),
          ],
        ),


        buildTextFieldWithHeading(
          title: 'Full Address',
          fieldWidget: AppTextField(
            hintText: 'Enter Police station name or location',
            textController: textController,
            onChange: (v) {},
            onSubmit: (v) {},
          ),
        ),


        AppButton(
          title: 'Submit',
          onTap:(){
            AppRoutes.pop();
             AppUiHelper.showBottomSheet(
                 showHandle: false,

                 context: context, child: PoliceHandoverProofDocuments());

          },
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          radius: BorderRadius.circular(7),
        ),

      ],
    );
  }
}
