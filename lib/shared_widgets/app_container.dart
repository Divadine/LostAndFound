import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppContainer extends StatelessWidget {
  final Widget widget;
  final Color? bgColor;
  final Color? color;
  final double? width;

  const AppContainer({
    super.key,
    required this.widget,
    this.bgColor,
    this.color, this.width,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: color ?? Colors.transparent),
        borderRadius: BorderRadius.circular(14),
        color: bgColor ?? AppColors.white,
        boxShadow: [BoxShadow(
          color: AppColors.fieldGrey,
          blurRadius: 1,
          offset: Offset(0, 0)
        )]
      ),
      child: widget,
    );
  }
}
