import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'app_icon_widget.dart';
import 'app_text.dart';

Widget SucessCard({
  required String name,
  required String location,

  required VoidCallback onTap,
}) {
  return Container(
    height: 100,
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.lightGreen,
      border: Border.all(color: AppColors.green),
      borderRadius: BorderRadius.circular(12),
    ),

    child: Row(
      spacing: 15,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIconWidget(assetPath: AssetImages.greenRoundedTick),


        Column(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Received to ',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            AppText(
              text: name,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),

            AppText(
              text: location,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),

        Spacer(),
        AppIconWidget(assetPath: AssetImages.iosForward,)
      ],
    ).pad(16),
  ).pad();
}