import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

import 'app_images.dart';
import 'app_utils.dart';

class AppUiHelper {
  static const double pad4 = 4.0;
  static const double pad8 = 8.0;
  static const double pad12 = 12.0;
  static const double pad14 = 14.0;
  static const double pad16 = 16.0;
  static const double pad18 = 18.0;
  static const double pad20 = 20;
  static const double pad40 = 40;
  static const double buttonHeight = 50;

  static void showCustomBottomDialog(Widget child, {bool barrier = false}) {
    final context = AppUtils.navigatorKey.currentContext;

    if (context == null) return;

    showGeneralDialog(
      context: context,

      barrierDismissible: barrier,

      barrierLabel: "Dismiss",

      barrierColor: Colors.black54,

      transitionDuration: const Duration(milliseconds: 300),

      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,

          child: Material(
            color: Colors.transparent,

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),

              child: Container(
                // margin: const EdgeInsets.only(bottom: 60),

                //
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),

                child: SafeArea(top: false, child: child),
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),

            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),

          child: child,
        );
      },
    );
  }

  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? titleWidget,
    double maxHeightFactor = 0.65,
    bool minHeight = false,
    bool isDismissible = true,
    bool showHandle = true,
    bool showCloseIcon = false,
    Color? color,
    Color? iconColor,
    Color bgColor = AppColors.white,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,

      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * maxHeightFactor;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomNavHeight = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset + bottomNavHeight),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    minHeight: minHeight == true ? maxHeight : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Handle bar
                      if (showHandle)
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.fieldGrey.withAlpha(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                      /// Optional title
                      if (title != null)
                        AppText(
                          text: title,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.start,
                        ).padBottom(10),
                      if (titleWidget != null) titleWidget,

                      /// Content
                      Flexible(child: child),
                    ],
                  ),
                ),
                if (showCloseIcon)
                  Positioned(
                    top: -35,
                    right: 10,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color ?? AppColors.white,
                        ),
                        child: Icon(
                          Icons.close,
                          color: iconColor ?? AppColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension WidgetPadding on Widget {
  Widget pad([double value = AppUiHelper.pad8]) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }

  Widget padVertical([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: value),
      child: this,
    );
  }

  Widget padHorizontal([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value),
      child: this,
    );
  }

  Widget padRight([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(right: value),
      child: this,
    );
  }

  Widget padLeft([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(left: value),
      child: this,
    );
  }

  Widget padTop([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(top: value),
      child: this,
    );
  }

  Widget padBottom([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(bottom: value),
      child: this,
    );
  }

  Widget padExceptRight([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(bottom: value, top: value, left: value),
      child: this,
    );
  }

  Widget padExceptLeft([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(bottom: value, top: value, right: value),
      child: this,
    );
  }

  Widget padExceptTop([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(bottom: value, left: value, right: value),
      child: this,
    );
  }

  Widget padExceptBottom([double value = AppUiHelper.pad8]) {
    return Padding(
      padding: EdgeInsets.only(top: value, left: value, right: value),
      child: this,
    );
  }
}
