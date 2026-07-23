import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class AuthChangeText extends StatelessWidget {
  final String text1;
  final String tappableText;
  final String? text2;
  final String? tappableText2;

  final void Function() onTap;
  final void Function()? onTap2;
  final Color? fadeColor;

  const AuthChangeText({
    super.key,
    required this.text1,
    required this.tappableText,
    required this.onTap,
    this.fadeColor,
    this.text2,
    this.tappableText2, this.onTap2,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.black, fontSize: 14),
        children: [
          TextSpan(text: text1, style: TextStyle(fontSize: 14)),
          TextSpan(
            text: '  $tappableText',
            style: TextStyle(color: fadeColor ?? AppColors.blue, fontSize: 14),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
          if (text2 != null)
            TextSpan(text: text2, style: TextStyle(fontSize: 14)),
          if (tappableText2 != null)
            TextSpan(
              text: '  $tappableText2',
              style: TextStyle(
                color: fadeColor ?? AppColors.blue,
                fontSize: 14,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap2,
            ),
        ],
      ),
    );
  }
}
