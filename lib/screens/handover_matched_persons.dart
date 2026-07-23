import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/bottomsheet_handover.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'handover_proff_documents.dart';

class HandoverMatchedPersons extends StatefulWidget {
  const HandoverMatchedPersons({super.key});

  @override
  State<HandoverMatchedPersons> createState() => _HandoverMatchedPersonsState();
}

class _HandoverMatchedPersonsState extends State<HandoverMatchedPersons> {
  int? selectedIndex;

  final List<Map<String, dynamic>> matchedPersons = [
    {
      "image": "https://i.pravatar.cc/150?img=1",
      "profileName": "Rahul Sharma",
      "id": "LF-1001",
      "percentageMatch": 98,
    },
    {
      "image": "https://i.pravatar.cc/150?img=2",
      "profileName": "Priya Kumar",
      "id": "LF-1002",
      "percentageMatch": 70,
    },
    {
      "image": "https://i.pravatar.cc/150?img=3",
      "profileName": "Arun Raj",
      "id": "LF-1003",
      "percentageMatch": 35,
    },
    {
      "image": "https://i.pravatar.cc/150?img=4",
      "profileName": "Divya S",
      "id": "LF-1004",
      "percentageMatch": 56,
    },
    {
      "image": "https://i.pravatar.cc/150?img=5",
      "profileName": "Karthik V",
      "id": "LF-1005",
      "percentageMatch": 100,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        AppText(
          text: 'Select the Owner',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        AppText(
          text: 'Choose the correct person from the suggested matches',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),

        Expanded(
          child: ListView.builder(
            itemCount: matchedPersons.length,
            itemBuilder: (context, index) {
              final persons = matchedPersons[index];
              return buildHandOverMatchedId(
                index: index,
                image: persons['image']!,
                profileName: persons['profileName']!,
                id: persons['id']!,
                percentageMatch: persons['percentageMatch']!,
              );
            },
          ),
        ),

        SizedBox(height: 7),
        AppButton(
          title: 'Next',
          onTap: () {
            if (selectedIndex == null) return;
            AppRoutes.pop();
            AppUiHelper.showBottomSheet(
              maxHeightFactor: 0.7,
              context: context,
              child: HandoverProofDocuments(),
            );
          },
          fontSize: 14,
          bgColor: selectedIndex == null
              ? AppColors.idCardColor
              : AppColors.primaryColor,
          textColor: selectedIndex == null ? AppColors.black : AppColors.white,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }

  Widget buildHandOverMatchedId({
    required int index,
    required String image,
    required String profileName,
    required String id,
    required int percentageMatch,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child:
      AppContainer(
        widget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Radio<int>(
              value: index,
              groupValue: selectedIndex,
              activeColor: AppColors.primaryColor,
              hoverColor: AppColors.primaryColor,
              onChanged: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),

            CircleAvatar(
              radius: 26,
              child: AppCachedNetworkImage(
                imageUrl: image,
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
                    text: profileName,
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
                      text: id,
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
                text: '$percentageMatch% match',
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: AppUtils.getMatchColor(percentageMatch),
              ),
            ),
          ],
        ).pad(),
      ).pad(),
    );
  }
}
