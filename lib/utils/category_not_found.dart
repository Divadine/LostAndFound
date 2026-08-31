import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class CategoryNotFound extends StatefulWidget {
  final bool isFromCategory;

  /// Async callback provided by the parent.
  final Future<void> Function() onRetry;

  const CategoryNotFound({
    super.key,
    required this.isFromCategory,
    required this.onRetry,
  });

  @override
  State<CategoryNotFound> createState() => _CategoryNotFoundState();
}

class _CategoryNotFoundState extends State<CategoryNotFound> {
  bool isRetrying = false;

  Future<void> _handleRetry() async {
    // Prevent multiple API calls.
    if (isRetrying) return;

    if (!mounted) return;

    setState(() {
      isRetrying = true;
    });

    try {
      await widget.onRetry();
    } catch (e, stackTrace) {
      debugPrint('Retry error: $e');
      debugPrint('$stackTrace');
    } finally {
      if (!mounted) return;

      setState(() {
        isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -------------------------------------------------------------------
          // IMAGE
          // -------------------------------------------------------------------

          AppIconWidget(
            assetPath: AssetImages.noSubCategoryFound,
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------------------
          // TITLE
          // -------------------------------------------------------------------

          AppText(
            text: widget.isFromCategory
                ? 'No Categories Found'
                : 'No Sub Categories Found',
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: AppColors.primaryColor,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------------------
          // DESCRIPTION
          // -------------------------------------------------------------------

          AppText(
            text: widget.isFromCategory
                ? 'We couldn’t find any categories. Try again.'
                : 'We couldn’t find any sub category matching your search. Try again.',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // RETRY BUTTON
          // -------------------------------------------------------------------

          isRetrying
              ? const SizedBox(
            height: 48,
            width: 48,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
              : AppButton(
            title: 'Try again',

            // AppButton expects:
            // void Function()
            //
            // Therefore we wrap the async method.
            onTap: () {
              _handleRetry();
            },

            fontSize: 16,
          ),
        ],
      ).pad(),
    );
  }
}

