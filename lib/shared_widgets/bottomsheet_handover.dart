import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/screens/handover_matched_persons.dart';
import 'package:lost_and_found/screens/others_handover.dart';
import 'package:lost_and_found/screens/police_handover_proof_documents.dart';
import 'package:lost_and_found/screens/policestation_handover.dart';
import 'package:lost_and_found/screens/receive_found_person.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'app_button.dart';

class ReceiveHandoverSheet extends StatefulWidget {
  const ReceiveHandoverSheet({super.key});

  @override
  State<ReceiveHandoverSheet> createState() => _ReceiveHandoverSheetState();
}

class _ReceiveHandoverSheetState extends State<ReceiveHandoverSheet> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          AppText(
            text: 'How would you like to hand Over?',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          SizedBox(height: 10),
          AppText(
            text: 'Choose one option to continue',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          BottomSheetHandOver(
            title: 'Receive from found Person',
            subtitle: 'Receive the item from the person who found it.',
            image: AssetImages.userIcon,
            isSelected: selectedIndex == 1,
            onTap: () {
              setState(() {
                selectedIndex = 1;
              });
            },
          ),
          BottomSheetHandOver(
            title: 'Receive from Police Station',
            subtitle: 'Receive the item from the police station.',
            image: AssetImages.police,
            isSelected: selectedIndex == 2,
            onTap: () {
              setState(() {
                selectedIndex = 2;
              });
            },
          ),
          BottomSheetHandOver(
            title: 'Received to others',
            subtitle: 'Provide the others details.',
            image: AssetImages.threeDotsHorizontal,
            isSelected: selectedIndex == 3,
            onTap: () {
              setState(() {
                selectedIndex = 3;
              });
            },
          ),
          SizedBox(height: 5),
          AppButton(
            title: 'Continue',
      
            onTap: () {
              if(selectedIndex == 0)return;
              AppUiHelper.showBottomSheet(
                context: context,
                child: HandoverMatchedPersons(),
              );
              if(selectedIndex == 1)return;
             AppUiHelper.showBottomSheet(context: context, child: PoliceStationHandOver());
              if(selectedIndex == 2)return;
              AppUiHelper.showBottomSheet(context: context, child: OthersHandover());
            },

            fontSize: 14,
            bgColor: selectedIndex == 0
                ? AppColors.idCardColor
                : AppColors.primaryColor,
            textColor: selectedIndex == 0 ? AppColors.black : AppColors.white,
            radius: BorderRadius.circular(7),
          ),
        ],
      ),
    );
  }
}

Widget BottomSheetHandOver({
  required String title,
  required String subtitle,
  required String image,
  required VoidCallback onTap,
  bool isSelected = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AppContainer(
      color: isSelected ? AppColors.primaryColor : Colors.transparent,
      widget: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            child: AppIconWidget(assetPath: image),
          ).pad(),

          Flexible(
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: .start,
              children: [
                AppText(text: title, fontWeight: FontWeight.w600, fontSize: 16),
                AppText(
                  text: subtitle,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  maxLine: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ).pad(),
    ),
  );
}
