import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/home/home_screen.dart';
import 'package:lost_and_found/screens/authentication/login_screen.dart';
import 'package:lost_and_found/screens/nearby/map_screen.dart';
import 'package:lost_and_found/screens/report_justification.dart';
import 'package:lost_and_found/screens/profile/settings_screen.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'chat/chat_screen.dart';
import 'authentication/role_chosen_screen.dart';

class BottomScreen extends StatefulWidget {
  const BottomScreen({super.key});

  @override
  State<BottomScreen> createState() => _BottomScreenState();
}

class _BottomScreenState extends State<BottomScreen> {
  int selectedIndex = 0;
  final pages = [
    HomeScreen(),
    MapScreen(),
    SizedBox(),
    ChatScreen(),
    SettingsScreen(),
  ];
  List<String> image = [
    AssetImages.home,
    AssetImages.location,
    AssetImages.addBottom,
    AssetImages.chat,
    AssetImages.profile,
  ];
  List<String> labels = ["Home", "Nearby", "Post", "Enquiry", "Profile"];

  void _showPostBottomSheet() {
    AppUiHelper.showCustomBottomDialog(
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);

                AppRoutes.pushNamed(
                  AppRoutes.categoryRadioScreen,
                  arguments: true,
                );
              },
              child: buildHomeBottomSheet(
                image: AssetImages.searchLostItem,
                title: "I Lost Something",
                description: "Post details about the item you lost.",
              ),
            ),
          ),

          SizedBox(
            height: 150,
            child: VerticalDivider(
              color: AppColors.fieldGrey,
              thickness: 1,
              width: 1,
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);

                AppRoutes.pushNamed(
                  AppRoutes.categoryRadioScreen,
                  arguments: true,
                );
              },
              child: buildHomeBottomSheet(
                image: AssetImages.homeFoundItem,
                title: "I Found Something",
                description: "Share details about the item you found.",
              ),
            ),
          ),
        ],
      ),

      // showHandle: false,
      // context: context,
      // maxHeightFactor: .45,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[selectedIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(image.length, (index) {
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  if (index == 2) {
                    _showPostBottomSheet();
                    return;
                  }

                  setState(() {
                    selectedIndex = index;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 50,
                  child: Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconWidget(assetPath: image[index]),
                      if (isSelected)
                        AppText(
                          text: labels[index],
                          fontSize: 12,
                          color: AppColors.white,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

Widget buildHomeBottomSheet({
  required String image,
  required String title,
  required String description,
}) {
  return Column(
    spacing: 10,
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AppIconWidget(assetPath: image),
      AppText(text: title, fontSize: 14, fontWeight: FontWeight.w600),
      AppText(text: description, fontWeight: FontWeight.w400, fontSize: 10),
      SizedBox(height: 15),
    ],
  );
}
