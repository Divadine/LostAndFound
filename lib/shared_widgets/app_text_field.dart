import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextStyle? hintStyle;
  final BorderRadius? borderRadius;
  final bool? readOnly;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autoValidateMode;
  final String? Function(String?)? validator;
  final TextInputType? textInputType;
  final TextInputAction? textInputAction;
  final Function(String) onChange;
  final Function(String) onSubmit;
  final VoidCallback? onTap;
  final int? maxLength;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? borderColor;

  final bool isTextVisible;
  final Color? textColor;
  final Color? textBackgroundColor;
  final double? textSize;
  final BoxConstraints? suffixIconConstraints;
  final bool? obscureText;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;


  const AppTextField({
    super.key,
    this.suffixIcon,
    this.prefixIcon,
    required this.hintText,
    this.hintStyle,
    this.borderRadius,
    required this.textController,
    this.readOnly,
    this.textCapitalization,
    this.inputFormatters,
    this.autoValidateMode,
    this.validator,
    this.textInputType,
    required this.onChange,
    required this.onSubmit,
    this.onTap,
    this.maxLength,
    this.maxLines,
    this.backgroundColor,
    this.isTextVisible = false,
    this.textColor,
    this.textBackgroundColor,
    this.textSize,
    this.textInputAction,
    this.suffixIconConstraints, this.obscureText, this.borderColor, this.textAlign, this.textAlignVertical, this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: textController.text,
      validator: validator,

      autovalidateMode:
      autoValidateMode ?? AutovalidateMode.onUserInteraction,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              borderRadius: borderRadius ?? BorderRadius.circular(6),
              child: TextField(
                controller: textController,
                textAlign: textAlign ?? TextAlign.start,
                textAlignVertical: textAlignVertical,
                style: appTextStyle(color: textBackgroundColor),
                readOnly: readOnly ?? false,
                maxLength: maxLength,
                maxLines: maxLines ?? 1,
                obscureText: obscureText ?? false,
                textCapitalization:
                textCapitalization ?? TextCapitalization.none,
                inputFormatters: [
                  NoLeadingSpaceFormatter(),
                  ...?inputFormatters,
                ],
                keyboardType: textInputType ??
                    (maxLines != null && maxLines! > 1
                        ? TextInputType.multiline
                        : TextInputType.text),
                textInputAction: textInputAction,
                onTap: onTap,
                onSubmitted: onSubmit,
                onChanged: (value) {
                  field.didChange(value);
                  onChange(value);
                },
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: contentPadding ?? const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  hintText: hintText,
                  hintStyle: hintStyle ?? appTextStyle(color: Colors.grey),
                  prefixIcon: prefixIcon,
                  suffixIcon: suffixIcon,
                  suffixIconConstraints: suffixIcon == null
                      ? const BoxConstraints(minWidth: 0, minHeight: 0)
                      : suffixIconConstraints ??
                      const BoxConstraints(minWidth: 0, minHeight: 0),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                    borderRadius ?? BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: borderColor ??
                          AppColors.fieldGrey.withAlpha(20),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                    borderRadius ?? BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: borderColor ??
                          AppColors.fieldGrey.withAlpha(20),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius:
                    borderRadius ?? BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius:
                    borderRadius ?? BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),

                  // Show red border when invalid
                  border: OutlineInputBorder(
                    borderRadius:
                    borderRadius ?? BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            if (field.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppText(
                        text: field.errorText!,
                        color: AppColors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }}

Widget buildErrorText({required String errorText}) {
  return Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.red, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: AppText(
            text: errorText ?? '',
            color: AppColors.red,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith(' ')) {
      final String trimmedText = newValue.text.trimLeft();
      int selectionOffset = newValue.selection.baseOffset - (newValue.text.length - trimmedText.length);
      if (selectionOffset < 0) selectionOffset = 0;
      return newValue.copyWith(
        text: trimmedText,
        selection: TextSelection.collapsed(offset: selectionOffset),
      );
    }
    return newValue;
  }
}
