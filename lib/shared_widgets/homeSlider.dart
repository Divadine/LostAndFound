import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class HomePageSlider extends StatelessWidget {
  final String image;
  final int index;
  final int totalSlides;
  final String content;
  final String title;
  final String subTitle;
  final PageController pageController;

  const HomePageSlider({
    super.key,
    required this.image,
    required this.index,
    required this.totalSlides,
    required this.content,
    required this.title,
    required this.pageController,
    required BuildContext context,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      crossAxisAlignment: .center,
      mainAxisAlignment: .center,
      children: [
        Flexible(
          child: Stack(
            children: [
              AppText(text: 'skip'),
              SizedBox(
                height: 350,
                child: AppIconWidget(assetPath: image, fit: BoxFit.cover),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        AppText(
          text: title,
          fontSize: 24,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
        AppText(
          text: subTitle,
          fontSize: 28,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        AppText(
          text: content,
          fontSize: 16,
          color: AppColors.grey,
          textAlign: .center,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}
