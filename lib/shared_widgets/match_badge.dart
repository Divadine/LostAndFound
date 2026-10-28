import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class MatchBadge extends StatelessWidget {
  final int percentage;
  final double fontSize;

  const MatchBadge({
    super.key,
    required this.percentage,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getMatchColor(percentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(70),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        text: '$percentage% match',
        fontWeight: FontWeight.w500,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}
