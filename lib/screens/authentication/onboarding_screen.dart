import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import '../../utils/app_images.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  int presentIndex = 0;
  String? selectedReason;
  PageController pageController = PageController();

  TextEditingController reasonController = TextEditingController();
  List<String> items = [
    'Item found',
    'Post Created by Mistake',
    'Duplicate Post',
    'Privacy Concern',
    'Item no longer available',
    'Others',
  ];

  List<onBoardModel> screenContents = [
    onBoardModel(
      image: AssetImages.onboard_1,
      title: 'Lost Something ?',
      subTitle: 'Find it Fast ',
      description:
          'Search lost items posted by  People nearby using map, categories and photos',
    ),
    onBoardModel(
      image: AssetImages.onboard_2,
      title: 'Found Something ?',
      subTitle: 'Post it Now.',
      description:
          'Take a photo, add location and post the item. Help the rightful  owner get it back',
    ),
    onBoardModel(
      image: AssetImages.onboard_3,
      title: 'Hand Over Safely',
      subTitle: 'Police Station',
      description:
          'Can’t identify the rightful owner?  Hand over the found item to a nearby Police station ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: SafeArea(
        child: Column(
          spacing: 20,
          children: [
            Container(
              height:MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(),
              child: PageView.builder(
                controller: pageController,
                itemCount: screenContents.length,
                onPageChanged: (value) {
                  setState(() {
                    presentIndex = value;
                  });
                },
                itemBuilder: (context, index) {
                  final model = screenContents[index];
                  return Stack(
                    children: [
                      Column(
                        spacing: 10,
                        crossAxisAlignment: .center,
                        mainAxisAlignment: .center,
                        children: [
                          Flexible(
                            child: SizedBox(
                              height: 350,
                              child: AppIconWidget(
                                assetPath: model.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          SizedBox(height: 40),
                          AppText(
                            text: model.title,
                            fontSize: 24,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          AppText(
                            text: model.subTitle,
                            fontSize: 28,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            text: model.description,
                            fontSize: 16,
                            color: AppColors.grey,
                            textAlign: .center,
                            fontWeight: FontWeight.w400,
                          ).padHorizontal(30),
                        ],
                      ),

                      if (presentIndex < 2)
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pageController.animateToPage(
                                  presentIndex + 2,
                                  duration: Duration(milliseconds: 2),
                                  curve: Curves.easeOut,
                                );
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.grey.withAlpha(150),
                              ),
                              child: AppText(
                                text: 'skip',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.white,
                              ),
                            ).pad(16),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (dots) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: presentIndex == dots ? 10 : 10,
                  decoration: BoxDecoration(
                    color: presentIndex == dots
                        ? AppColors.primaryColor
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            SizedBox(height: 15),

          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          child: AppButton(
            height: 45,
            title: presentIndex == screenContents.length - 1
                ? 'Get Start'
                : 'Next',
            onTap: () {
              if (presentIndex < screenContents.length - 1) {
                pageController.animateToPage(
                  presentIndex + 1,
                  duration: Duration(milliseconds: 2),
                  curve: Curves.easeOut,
                );
              } else {
                //AppPreferences.setIsOnboarded(true);
                AppDialogue.showPopup(
                  context: context,
                  content: DisclaimerPopUP(isFromOnBoard: true),
                );
                //AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
              }
            },
          ),
        ),
      ),
    );
  }
}

class onBoardModel {
  final String image;
  final String title;
  final String subTitle;
  final String description;

  onBoardModel({
    required this.image,
    required this.title,
    required this.subTitle,
    required this.description,
  });
}
