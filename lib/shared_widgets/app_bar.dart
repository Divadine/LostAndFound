import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';

import 'app_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final String? leadingSvg;
  final VoidCallback? onLeadingTap;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color titleColor;
  final double elevation;
  final Color? leadingIconColor;


  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.leadingSvg,
    this.onLeadingTap,
    this.actions,
    this.backgroundColor = Colors.white,
    this.titleColor = Colors.black,
    this.elevation = 0, this.leadingIconColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingSvg != null
          ? IconButton(
        onPressed: onLeadingTap ?? () => Navigator.pop(context),
        icon: AppIconWidget( size: 15, assetPath: leadingSvg!,color:leadingIconColor ,),
      )
          : null,
      title: AppText(
        text: title,
        color: titleColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,

      ),
      actions: actions,

    );
  }
}
