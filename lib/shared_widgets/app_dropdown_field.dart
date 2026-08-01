import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class AppDropdownField<T> extends StatefulWidget {
  final T? value;
  final String hintText;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T?) onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? hintStyle;
  final BorderRadius? borderRadius;
  final AutovalidateMode? autoValidateMode;
  final String? Function(T?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textBackgroundColor;
  final Color? selectedItemColor;
  final Color? selectedItemTextColor;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.hintStyle,
    this.borderRadius,
    this.autoValidateMode,
    this.validator,
    this.backgroundColor,
    this.borderColor,
    this.textBackgroundColor,
    this.selectedItemColor,
    this.selectedItemTextColor,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final FocusNode _focusNode = FocusNode();
  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    // The menu closes when the field loses focus (tap outside, item selected, etc.)
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && isOpen) {
        setState(() => isOpen = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(6);

    return DropdownButtonFormField<T>(
      value: widget.value,
      focusNode: _focusNode,
      isExpanded: true,
      onTap: () => setState(() => isOpen = true),
      icon: AppIconWidget(
        assetPath: isOpen ? AssetImages.dropUp : AssetImages.dropDown,size: 1,


      ),
      dropdownColor: Colors.white,
      borderRadius: radius,
      menuMaxHeight: 240,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      autovalidateMode: widget.autoValidateMode ?? AutovalidateMode.onUserInteraction,
      validator: widget.validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.backgroundColor ?? Colors.white,
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? const TextStyle(color: Colors.grey),
        prefixIcon: widget.prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: widget.borderColor ?? AppColors.idCardColor.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: widget.borderColor ?? AppColors.idCardColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.red),
        ),
        errorStyle: const TextStyle(color: AppColors.red, fontSize: 12),
      ),
      selectedItemBuilder: (context) {
        return widget.items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text: widget.itemLabel(item),
              color: widget.textBackgroundColor,
            ),
          );
        }).toList();
      },
      items: widget.items.map((item) {
        final bool isSelected = item == widget.value;
        return DropdownMenuItem<T>(
          value: item,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            color: isSelected ? AppColors.idCardColor : Colors.transparent,
            child: AppText(
              text: widget.itemLabel(item),
              color: isSelected ? (widget.selectedItemTextColor ?? Colors.white) : widget.textBackgroundColor,
            ),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => isOpen = false);
        widget.onChanged(val);
      },
    );
  }
}