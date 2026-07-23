import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? textOverflow;
  final int? maxLine;
  final double? height;
  final TextDecoration? textDecoration;
  final bool? softWrap;

  const AppText({
    super.key,
    required this.text,
    this.color,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.textOverflow,
    this.maxLine,
    this.height,
    this.textDecoration,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Text(
        text,
        overflow: textOverflow,
        textAlign: textAlign,
        maxLines: maxLine,
        softWrap: softWrap,
        style: appTextStyle(
          color: color ?? Theme.of(context).textTheme.bodyMedium!.color!,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          textDecoration: textDecoration,
        ),
      ),
    );
  }
}

TextStyle appTextStyle({
  Color? color,
  FontWeight? fontWeight,
  double? fontSize,
  double? height,
  TextDecoration? textDecoration,
}) {
  return TextStyle(
    fontFamily: 'BricolageGrotesque',
    color: color,
    fontWeight: fontWeight ?? FontWeight.w400,
    fontSize: fontSize,
    height: height,
    decoration: textDecoration,
    decorationColor: color,
  );
}
 