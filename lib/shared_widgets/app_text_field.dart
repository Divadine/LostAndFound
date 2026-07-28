import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

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
  final bool isTextVisible;
  final Color? textColor;
  final Color? borderColor;
  final Color? textBackgroundColor;
  final double? textSize;
  final BoxConstraints? suffixIconConstraints;
  final bool? obscureText;


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
    this.suffixIconConstraints, this.obscureText, this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.fieldGrey.withAlpha(200),
            blurRadius: 5,
           offset: Offset(0,0),
          ),
        ],
      ),
      child: TextFormField(

          style: appTextStyle(color: textBackgroundColor),
          controller: textController,
          readOnly: readOnly ?? false,
          maxLength: maxLength,
          maxLines: maxLines ?? 1,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          inputFormatters: inputFormatters,
          autovalidateMode: autoValidateMode ?? AutovalidateMode.onUserInteraction,
          obscureText: obscureText ?? false,
          validator: validator,
          keyboardType:
          textInputType ??
              (maxLines != null && maxLines! > 1
                  ? TextInputType.multiline
                  : TextInputType.text),
          textInputAction: textInputAction,
          onChanged: onChange,
          onTap: onTap,
          onFieldSubmitted: onSubmit,


          errorBuilder: (context, errorText) {
            if (errorText == null) return const SizedBox.shrink();

            return Transform.translate(
              offset: const Offset(-12, 0), // Adjust this value if needed
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
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
                        text: errorText,
                        color: AppColors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
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
              borderRadius: borderRadius ?? BorderRadius.circular(6),
              borderSide:  BorderSide(color: borderColor ?? Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(6),
              borderSide:  BorderSide(color: borderColor ?? Colors.transparent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.red),

            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.red),
            ),
          ),

      ),
    );
  }
}
