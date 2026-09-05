import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'app_icon_widget.dart';
import 'app_text.dart';

Widget SucessCard({
  required String name,
  required String location,
  required bool isReceiver,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        border: Border.all(
          color: AppColors.green,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppIconWidget(
            assetPath: AssetImages.greenRoundedTick,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: isReceiver
                      ? 'Received by'
                      : 'Hand Over to',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),

                const SizedBox(height: 5),

                AppText(
                  text: name,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),

                const SizedBox(height: 5),

                AppText(
                  text: location,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          AppIconWidget(
            assetPath: AssetImages.iosForward,
          ),
        ],
      ).pad(16),
    ),
  ).pad();
}