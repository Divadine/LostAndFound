import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class NoInternetWidget extends StatelessWidget {
  final double? size;
  const NoInternetWidget({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconWidget(
            assetPath: AssetImages.noInternet,
            size: size ?? 200,
          ),
          SizedBox(height: 15,),
          AppText(text: "No Internet Connection",fontSize: 18,fontWeight: FontWeight.w700,color: AppColors.primaryColor,),
        ],
      ),
    );
  }
}
