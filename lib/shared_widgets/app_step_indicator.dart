import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class AppStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AppStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 2,
  });

  @override
  Widget build(BuildContext context) {
    final double lineWidth = AppUtils.isTab ? 200 : 40;
    final double circleRadius = AppUtils.isTab ? 14 : 12;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps * 2 - 1, (i) {
          final bool isLine = i.isOdd;
          final int step = (i ~/ 2) + 1;

          if (isLine) {
            return Container(
              width: lineWidth,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: step < currentStep
                  ? AppColors.primaryColor
                  : Colors.grey.shade300,
            );
          }

          final bool isActiveOrDone = step <= currentStep;
          return CircleAvatar(
            radius: circleRadius,
            backgroundColor:
            isActiveOrDone ? AppColors.primaryColor : Colors.grey.shade300,
            child: Text(
              '$step',
              style: TextStyle(
                color: isActiveOrDone ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: AppUtils.isTab ? 13 : 12,
              ),
            ),
          );
        }),
      ),
    );
  }
}