import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class FirstHomeScreen extends StatefulWidget {
  const FirstHomeScreen({super.key});

  @override
  State<FirstHomeScreen> createState() => _FirstHomeScreenState();
}

class _FirstHomeScreenState extends State<FirstHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        //crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          AppIconWidget(assetPath: AssetImages.lostFoundImage),
          AppText(
            text: 'What would you like to do ?',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          AppText(
            text: 'Choose an option below to get started',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          buildLostContainer(
            leftImg: AssetImages.bag,
            title: 'I lost Something',

            description:
                'Post details about the item you lost and let others help you find it.',
            rightImg: AssetImages.right_arrow,
            onTap: () {
              AppRoutes.pushNamed(AppRoutes.categoryRadioScreen);
            },
          ),

          buildLostContainer(
            leftImg: AssetImages.box_image,
            title: 'I Found Something',

            description:
                'Share details about the item. you found and help it reach its owner.',
            rightImg: AssetImages.right_arrow,
            onTap: () {
              AppRoutes.pushNamed(AppRoutes.categoryRadioScreen);
            },
          ),

          SizedBox(height: 10),

          GestureDetector(
            onTap: (){
              AppRoutes.pushNamed(AppRoutes.bottomScreen);
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shieldBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                //mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10,
                children: [
                  AppIconWidget(assetPath: AssetImages.shieldTick),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        AppText(
                          text: 'Safety First',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                        AppText(
                          text:
                              'We recommend handing over found items to the nearest police station for everyone’s safety',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).pad(16),
    );
  }


}

Widget buildLostContainer({
  required String title,
  required String description,
  required String leftImg,
  required String rightImg,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.fieldGrey),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconWidget(assetPath: leftImg),
          Expanded(
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                AppText(
                  text: description,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ).padHorizontal(16),
          ),

          AppIconWidget(assetPath: rightImg).pad(),
        ],
      ),
    ),
  );
}
