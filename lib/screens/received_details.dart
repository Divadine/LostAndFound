import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'handover_proff_documents.dart';

class ReceivedDetails extends StatefulWidget {
  const ReceivedDetails({super.key});

  @override
  State<ReceivedDetails> createState() => _ReceivedDetailsState();
}

class _ReceivedDetailsState extends State<ReceivedDetails> {
  TextEditingController descriptionController = TextEditingController();
  int percentageMatch = 92;
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () {
              AppRoutes.pop();
            },
            child: AppIconWidget(
              assetPath: AssetImages.crossIcon,
            ),
          ),
        ),

        AppText(text: 'Received Details',fontSize: 16,fontWeight: FontWeight.w600,),

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


        AppContainer(
          widget: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                child: AppCachedNetworkImage(
                  imageUrl:
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',

                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      text: 'Dinesh',
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue_3,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppText(
                        text: 'ID : LF2489',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppUtils.getMatchColor(percentageMatch).withAlpha(70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  text: "${percentageMatch}% Match",
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  //color: AppUtils.getMatchColor(percentageMatch),
                ),
              ),


            ],
          ).pad(),
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
            readOnly: true,
            textController: descriptionController,
          ),
        ),



      ],
    );
  }
}
