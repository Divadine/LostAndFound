import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

// =============================================================================
// NO-EDIT FORMATTER
// =============================================================================

class _NoEditTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return oldValue;
  }
}

// =============================================================================
// APP DROPDOWN FIELD
// =============================================================================

class AppDropdownField<T> extends StatefulWidget {
  final T? value;

  final String hintText;

  final double? height;

  final List<T> items;

  final String Function(T) itemLabel;

  final void Function(T?)? onChanged;

  final Color? backgroundColor;

  final Color? borderColor;

  final Color? selectedItemColor;

  final Color? selectedItemTextColor;

  final double? menuHeight;

  final Widget? suffixIcon;

  final EdgeInsetsGeometry? contentPadding;

  final Widget? selectedSuffixIcon;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.backgroundColor,
    this.borderColor,
    this.selectedItemColor,
    this.selectedItemTextColor,
    this.menuHeight,
    this.suffixIcon,
    this.selectedSuffixIcon,
    this.height,
    this.contentPadding,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

// =============================================================================
// STATE
// =============================================================================

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late TextEditingController controller;

  late AnimationController rotationController;

  // MenuAnchor controller.
  final MenuController menuController = MenuController();

  bool isOpen = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.value == null ? '' : widget.itemLabel(widget.value as T),
    );

    // -------------------------------------------------------------------------
    // Rotation animation
    //
    // 0.0 = closed
    // 0.5 = 180 degrees
    // -------------------------------------------------------------------------

    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      controller.text = widget.value == null
          ? ''
          : widget.itemLabel(widget.value as T);
    }
  }

  @override
  void dispose() {
    rotationController.dispose();
    controller.dispose();

    super.dispose();
  }

  // =============================================================================
  // OPEN MENU
  // =============================================================================

  void _openMenu() {
    if (menuController.isOpen) {
      return;
    }

    menuController.open();

    setState(() {
      isOpen = true;
    });

    rotationController.forward();
  }

  // =============================================================================
  // CLOSE MENU
  // =============================================================================

  void _closeMenu() {
    if (!menuController.isOpen) {
      return;
    }

    menuController.close();

    setState(() {
      isOpen = false;
    });

    rotationController.reverse();
  }

  // =============================================================================
  // TOGGLE MENU
  // =============================================================================

  void _toggleMenu() {
    if (menuController.isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  // =============================================================================
  // SUFFIX ICON
  // =============================================================================

  Widget _buildSuffixIcon() {
    final Widget closedIcon =
        widget.suffixIcon ?? AppIconWidget(assetPath: AssetImages.dropDown);

    final Widget openIcon =
        widget.selectedSuffixIcon ??
        widget.suffixIcon ??
        AppIconWidget(assetPath: AssetImages.dropUp);

    return Container(
      height: 30,
      width: 30,
      child: Center(child: isOpen ? AppIconWidget(assetPath: AssetImages.dropUp) : AppIconWidget(assetPath: AssetImages.dropDown))
    );
  }

  // =============================================================================
  // BUILD
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: menuController,

          // -------------------------------------------------------------------
          // Detect when menu opens/closes.
          // -------------------------------------------------------------------
          onOpen: () {
            if (!mounted) return;

            setState(() {
              isOpen = true;
            });

            rotationController.forward();
          },

          onClose: () {
            if (!mounted) return;

            setState(() {
              isOpen = false;
            });

            rotationController.reverse();
          },

          // -------------------------------------------------------------------
          // MENU STYLE
          // -------------------------------------------------------------------
          style: MenuStyle(
            maximumSize: WidgetStateProperty.all(
              Size(constraints.maxWidth, widget.menuHeight ?? 300),
            ),

            elevation: WidgetStateProperty.all(2),

            backgroundColor: WidgetStateProperty.all(Colors.white),

            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),

          // -------------------------------------------------------------------
          // MENU ITEMS
          // -------------------------------------------------------------------
          menuChildren: widget.items.map((item) {
            final bool selected = item == widget.value;

            return MenuItemButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20),
                ),

                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (selected) {
                    return widget.selectedItemColor ?? AppColors.idCardColor;
                  }

                  return Colors.white;
                }),

                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (selected) {
                    return widget.selectedItemTextColor ?? AppColors.black;
                  }

                  return Colors.black;
                }),

                textStyle: WidgetStateProperty.all(appTextStyle()),
              ),

              onPressed: () {
                // -------------------------------------------------------------
                // Update text.
                // -------------------------------------------------------------

                controller.text = widget.itemLabel(item);

                // -------------------------------------------------------------
                // Notify parent.
                // -------------------------------------------------------------

                widget.onChanged?.call(item);

                // -------------------------------------------------------------
                // Close menu.
                // -------------------------------------------------------------

                _closeMenu();
              },

              child: SizedBox(
                width: constraints.maxWidth - 40,
                child: Text(widget.itemLabel(item), style: appTextStyle()),
              ),
            );
          }).toList(),

          // -------------------------------------------------------------------
          // DROPDOWN FIELD
          // -------------------------------------------------------------------
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,

              onTap: _toggleMenu,

              child: AbsorbPointer(
                absorbing: true,

                child: InputDecorator(
                  decoration: InputDecoration(
                    // =========================================================
                    // HINT
                    // =========================================================
                    hintText: widget.value == null ? widget.hintText : null,

                    hintStyle: appTextStyle(color: Colors.grey),

                    // =========================================================
                    // BACKGROUND
                    // =========================================================
                    filled: true,

                    fillColor: widget.backgroundColor ?? Colors.white,

                    // =========================================================
                    // DENSITY
                    // =========================================================
                    isDense: true,

                    // =========================================================
                    // PADDING
                    // =========================================================
                    contentPadding:
                        widget.contentPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),

                    // =========================================================
                    // BORDER
                    // =========================================================
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),

                      borderSide: BorderSide(
                        color:
                            widget.borderColor ??
                            AppColors.fieldGrey.withAlpha(20),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),

                      borderSide: BorderSide(
                        color:
                            widget.borderColor ??
                            AppColors.fieldGrey.withAlpha(20),
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),

                      borderSide: BorderSide(
                        color:
                            widget.borderColor ??
                            AppColors.fieldGrey.withAlpha(20),
                      ),
                    ),

                    // =========================================================
                    // CUSTOM ROTATING SUFFIX
                    // =========================================================
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildSuffixIcon(),
                    ),
                  ),

                  // ===========================================================
                  // SELECTED VALUE / HINT
                  // ===========================================================
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value == null
                          ? ''
                          : widget.itemLabel(widget.value as T),
                      style: appTextStyle(color: AppColors.black),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
