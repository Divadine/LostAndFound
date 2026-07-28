import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class CategoryNotFound extends StatelessWidget {
  const CategoryNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        AppIconWidget(assetPath: AssetImages.noSubCategoryFound,),
        AppText(text: 'No Sub Categories Found',fontWeight: FontWeight.w500,fontSize: 18,color: AppColors.primaryColor,),
        AppText(text: 'We couldn’t find any sub category matching your search. Try a different keyword.',fontSize: 14,fontWeight: FontWeight.w400,),
        
        AppButton(title: 'Try again', onTap: (){},fontSize: 16,)
      ],
    );
  }
}
