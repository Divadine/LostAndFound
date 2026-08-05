import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

import 'app_icon_widget.dart';
import 'app_text.dart';

class  SuccessSnackBar extends StatelessWidget {
  const SuccessSnackBar ({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 35,
      //width: double.infinity,
      decoration: BoxDecoration(
        //border: Border.all(color: AppColors.primaryColor),
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconWidget(assetPath: AssetImages.sucessTick),
          SizedBox(width: 15,),
          AppText(
            text: 'Account Login successfully',
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),

        ],
      )
    );
  }
}

