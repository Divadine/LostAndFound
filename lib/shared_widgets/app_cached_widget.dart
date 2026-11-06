import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class AppCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  State<AppCachedNetworkImage> createState() => _AppCachedNetworkImageState();
}

class _AppCachedNetworkImageState extends State<AppCachedNetworkImage> {
  // Base URL for the backend — used to resolve relative image paths
  // returned by getPost / Match / viewEnquiry etc.
  static const String _baseUrl = 'https://lost-and-found.skyraantech.com/backend/';

  String get _resolvedUrl {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // already absolute (e.g. from createImage response)
    }
    final cleanPath = url.startsWith('/') ? url.substring(1) : url;
    return '$_baseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = _resolvedUrl.toLowerCase();
    if (cleanUrl.isEmpty ||
        cleanUrl.endsWith('/backend/') ||
        cleanUrl.endsWith('/backend')) {
      return widget.errorWidget ??
          Container(
            color: Colors.grey,
            width: widget.width,
            height: widget.height,
            child: const Icon(Icons.image_not_supported, size: 40),
          );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: _resolvedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => const SizedBox(
          height: 20,
          width: 20,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) =>
            widget.errorWidget ??
            const NoInternetWidget(size: 40, showText: false),
      ),
    );
  }
}

class EnquiredPersonsAvatar extends StatelessWidget {
  final List<String> images;

  const EnquiredPersonsAvatar({super.key, required this.images});

  bool _hasValidImage(String? url) {
    final u = (url ?? '').trim().toLowerCase();
    if (u.isEmpty || u == 'null' || u == 'undefined') return false;
    if (u.endsWith('/backend/') || u.endsWith('/backend')) return false;
    return true;
  }

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
                backgroundColor: AppColors.fieldGrey,
                child: !_hasValidImage(images[i])
                    ? const Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.primaryColor,
                      )
                    : AppCachedNetworkImage(
                        imageUrl: images[i],
                        borderRadius: BorderRadius.circular(40),
                        height: 20,
                        width: 20,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
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