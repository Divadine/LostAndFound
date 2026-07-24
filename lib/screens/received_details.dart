import 'package:cached_network_image/cached_network_image.dart';
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
  final bool isReceivedFromPolice;
  final bool isReceivedFromFounder;
  final bool isReceivedFromOthers;

  const ReceivedDetails({
    super.key,
    required this.isReceivedFromPolice,
    required this.isReceivedFromFounder,
    required this.isReceivedFromOthers,
  });

  @override
  State<ReceivedDetails> createState() => _ReceivedDetailsState();
}

class _ReceivedDetailsState extends State<ReceivedDetails> {
  TextEditingController descriptionController = TextEditingController();
  int percentageMatch = 92;


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .start,
        mainAxisAlignment: .start,
        spacing: 10,
        children: [
          Center(
            child: AppText(
              text: 'Received Details',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (widget.isReceivedFromPolice)
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

          if (widget.isReceivedFromFounder)
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppUtils.getMatchColor(
                        percentageMatch,
                      ).withAlpha(70),
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
          if (widget.isReceivedFromOthers)
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

          buildProofDocuments(
            title: '1. Proof Photos',
            widget: Container(
              //padding: EdgeInsets.all(5),
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),

              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                
                  imageUrl:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                ),
              ),
            ),
          ),

          buildProofDocuments(
            title: '2. Description',
            widget: AppText(
              text:
                  'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),

          if (widget.isReceivedFromOthers)
            buildProofDocuments(
              title: '3. Phone Number',
              widget: AppText(
                text: '+91 9876543210',
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
        ],
      ).pad(2),
    );
  }
}
