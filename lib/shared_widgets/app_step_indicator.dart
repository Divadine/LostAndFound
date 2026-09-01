import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';

/// Circle-and-line step indicator used across the Post Lost/Found flow.
/// `currentStep` is 1-indexed (1 = first screen active, 2 = second screen active).
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
    final List<Widget> children = [];

    for (int step = 1; step <= totalSteps; step++) {
      final bool isActiveOrDone = step <= currentStep;

      children.add(
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActiveOrDone ? AppColors.primaryColor : Colors.grey.shade300,
          ),
          child: Text(
            '$step',
            style: TextStyle(
              color: isActiveOrDone ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Connecting line between this circle and the next one.
      if (step != totalSteps) {
        final bool lineActive = (step + 1) <= currentStep;
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: lineActive ? AppColors.primaryColor : Colors.grey.shade300,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 80),
      child: Row(children: children),
    );
  }
}