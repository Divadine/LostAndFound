import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/bottomsheets/owner_selection_screen.dart';
import 'package:lost_and_found/screens/bottomsheets/others_submission.dart';
import 'package:lost_and_found/screens/bottomsheets/police_station_selection.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import '../../shared_widgets/app_button.dart';

class HandoverType {
  static const int owner = 1;
  static const int police = 2;
  static const int others = 3;
}

class ReceiveHandoverSheet extends StatefulWidget {
  final String title;
  final bool isReceiver;
  final int postId;
  final int? categoryId;

  const ReceiveHandoverSheet({
    super.key,
    required this.title,
    required this.isReceiver,
    required this.postId,
    this.categoryId,
  });

  @override
  State<ReceiveHandoverSheet> createState() => _ReceiveHandoverSheetState();
}

class _ReceiveHandoverSheetState extends State<ReceiveHandoverSheet> {
  int selectedIndex = 0;

  // Jewellery & Valuables category ID.
  // This uses categoryId, NOT title/item name/post type.
  bool get isJewellery => widget.categoryId == 9;

  @override
  void initState() {
    super.initState();

    debugPrint('========== HANDOVER SHEET ==========');
    debugPrint('[Handover] title: "${widget.title}"');
    debugPrint('[Handover] categoryId: ${widget.categoryId}');
    debugPrint('[Handover] isJewellery: $isJewellery');

    if (isJewellery) {
      // Police is the only option for Jewellery.
      selectedIndex = 2;

      debugPrint(
        '[Handover] Jewellery detected -> Police Station only',
      );
    } else {
      // Preserve original non-Jewellery flow.
      selectedIndex = 0;

      debugPrint(
        '[Handover] Non-Jewellery -> Owner / Police / Others',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          AppText(
            text: widget.isReceiver
                ? 'How would you like to Receive?'
                : 'How would you like to hand Over?',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),

          const SizedBox(height: 10),

          AppText(
            text: 'Choose one option to continue',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),

          // ==========================================================
          // JEWELLERY
          // ONLY POLICE STATION
          // ==========================================================
          if (isJewellery) ...[
            BottomSheetHandOver(
              title: widget.isReceiver
                  ? 'Receive from Police Station'
                  : 'Hand Over to Police Station',
              subtitle: widget.isReceiver
                  ? 'Receive the item from the police station.'
                  : 'Provide the Police station details.',
              image: AssetImages.police,
              isSelected: selectedIndex == 2,
              onTap: () {
                setState(() {
                  selectedIndex = 2;
                });
              },
            ),
          ]

          // ==========================================================
          // NON-JEWELLERY
          // ORIGINAL 3 OPTIONS
          // ==========================================================
          else ...[
            BottomSheetHandOver(
              title: widget.isReceiver
                  ? 'Receive from found Person'
                  : 'Hand Over to Owner directly',
              subtitle: widget.isReceiver
                  ? 'Receive the item from the person who found it.'
                  : 'Select the owner from the suggested Profiles.',
              image: AssetImages.userIcon,
              isSelected: selectedIndex == 1,
              onTap: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
            ),

            BottomSheetHandOver(
              title: widget.isReceiver
                  ? 'Receive from Police Station'
                  : 'Hand Over to Police Station',
              subtitle: widget.isReceiver
                  ? 'Receive the item from the police station.'
                  : 'Provide the Police station details.',
              image: AssetImages.police,
              isSelected: selectedIndex == 2,
              onTap: () {
                setState(() {
                  selectedIndex = 2;
                });
              },
            ),

            BottomSheetHandOver(
              title: widget.isReceiver
                  ? 'Received to others'
                  : 'Hand Over to others',
              subtitle: 'Provide the others details.',
              image: AssetImages.threeDotsHorizontal,
              isSelected: selectedIndex == 3,
              onTap: () {
                setState(() {
                  selectedIndex = 3;
                });
              },
            ),
          ],

          const SizedBox(height: 5),

          // ==========================================================
          // CONTINUE
          // ==========================================================
          AppButton(
            title: 'Continue',
            onTap: () async {
              if (selectedIndex == 0) {
                return;
              }

              AppRoutes.pop();

              final phoneNumber = AppPreferences.getPhone() ?? '';
              final userId = AppPreferences.getUserId() ?? 0;

              // ========================================================
              // OWNER
              // Non-Jewellery only
              // ========================================================
              if (!isJewellery && selectedIndex == 1) {
                AppUiHelper.showBottomSheet(
                  showHandle: false,
                  context: context,
                  child: HandoverMatchedPersons(
                    postId: widget.postId,
                    isReceiver: widget.isReceiver,
                  ),
                );
                return;
              }

              // ========================================================
              // POLICE
              // Jewellery + Non-Jewellery
              // ========================================================
              if (selectedIndex == 2) {
                AppUiHelper.showBottomSheet(
                  showHandle: false,
                  context: context,
                  child: PoliceStationHandOver(
                    postId: widget.postId,
                    userId: userId,
                    phoneNumber: phoneNumber,
                    handoverType: HandoverType.police,
                    isReceiver: widget.isReceiver,
                  ),
                );
                return;
              }

              // ========================================================
              // OTHERS
              // Non-Jewellery only
              // ========================================================
              if (!isJewellery && selectedIndex == 3) {
                AppUiHelper.showBottomSheet(
                  showHandle: false,
                  context: context,
                  child: OthersHandover(
                    postId: widget.postId,
                    userId: userId,
                    isReceiver: widget.isReceiver,
                  ),
                );
              }
            },
            fontSize: 14,
            bgColor: selectedIndex == 0
                ? AppColors.idCardColor
                : AppColors.primaryColor,
            textColor: selectedIndex == 0
                ? AppColors.black
                : AppColors.white,
            radius: BorderRadius.circular(7),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// HANDOVER OPTION WIDGET
// ==========================================================================

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
      color: isSelected
          ? AppColors.primaryColor
          : Colors.transparent,
      widget: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            child: AppIconWidget(
              assetPath: image,
            ),
          ).pad(),

          Flexible(
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
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