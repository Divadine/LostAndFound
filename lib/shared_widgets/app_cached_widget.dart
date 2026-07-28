import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<AppCachedNetworkImage> createState() => _AppCachedNetworkImageState();
}

class _AppCachedNetworkImageState extends State<AppCachedNetworkImage> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => SizedBox(
          height: 15,
          width: 15,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              padding: EdgeInsets.all(30),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey,
          child: const Icon(Icons.broken_image, size: 40),
        ),
      ),
    );
  }
}

class EnquiredPersonsAvatar extends StatelessWidget {
  final List<String> images;

  const EnquiredPersonsAvatar({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    int displayCount = images.length > 3 ? 3 : images.length;

    // shift if only one image
    double startOffset = images.length == 1 ? 36 : 0;

    return SizedBox(
      width: 90,
      height: 20,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: startOffset + (i * 14),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.white,

                child: AppCachedNetworkImage(
                  imageUrl: images[i],
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

          if (images.length > 3)
            Positioned(
              left: startOffset + (displayCount * 14),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.white,
                child: AppText(
                  text: "+${images.length - 3}",
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
