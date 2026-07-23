import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppButton extends StatelessWidget {
  final String title;
  final void Function() onTap;
  final String? icon;
  final String? prefixIcon;
  final Color? textColor;
  final Color? bgColor;
  final BoxBorder? border;
  final BorderRadiusGeometry? radius;
  final double? fontSize;
  final double? height;
  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.prefixIcon,
    this.textColor,
    this.bgColor,
    this.border, this.radius, this.fontSize, this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.primaryColor,
          border: border,
          borderRadius: radius ?? BorderRadius.circular(20),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              if (prefixIcon != null) AppIconWidget(assetPath: prefixIcon!),

              AppText(
                text: title,
                fontSize:fontSize ??  18,
                color: textColor ?? AppColors.white,
                textAlign: TextAlign.center,
              ),

              if (icon != null) AppIconWidget(assetPath: icon!),
            ],
          ),
        ),
      ),
    );
  }
}
