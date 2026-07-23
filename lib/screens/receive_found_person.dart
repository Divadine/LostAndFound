import 'package:flutter/cupertino.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/bottomsheet_handover.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class ReceiveFoundPerson extends StatelessWidget {
  const ReceiveFoundPerson({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          title: 'Hand Over to Owner directly',
          subtitle: '',
          image: AssetImages.police,
          onTap: () {},
        ),

        SizedBox(height: 7),
        AppButton(
          title: 'Continue',
          onTap: () {},
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}
