import 'package:flutter/material.dart';

import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';

import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class CategoryNotFound extends StatelessWidget {
  final bool isFromCategory;
  final Future<void> Function() onRetry;

  const CategoryNotFound({
    super.key,
    required this.isFromCategory,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIconWidget(
                      assetPath: AssetImages.noSubCategoryFound,
                    ),

                    const SizedBox(height: 16),

                    AppText(
                      text: isFromCategory
                          ? 'No Categories Found'
                          : 'No Sub Categories Found',
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: AppColors.primaryColor,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    AppText(
                      text: isFromCategory
                          ? 'We couldn’t find any categories. Try again.'
                          : 'We couldn’t find any sub category matching your search. Try again.',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    AppButton(
                      title: 'Try again',
                      onTap: onRetry,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}