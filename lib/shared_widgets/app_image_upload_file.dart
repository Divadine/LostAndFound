import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';

class AppImageUploadField extends StatelessWidget {
  final String title;
  final List<dynamic> images;
  final int maxImages;
  final VoidCallback onAdd;
  final Function(int index) onRemove;
  final double tileSize;

  const AppImageUploadField({
    super.key,
    required this.title,
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.maxImages = 4,
    this.tileSize = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: '$title ${images.length}/$maxImages',
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...images.asMap().entries.map(
                  (entry) => _buildImageTile(entry.key, entry.value),
            ),
            if (images.length < maxImages) _buildAddTile(),
          ],
        ),
      ],
    );
  }

  Widget _buildImageTile(int index, dynamic image) {
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: image is File
                  ? Image.file(image, fit: BoxFit.cover)
                  : Image.network(image as String, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.fieldGrey.withAlpha(60)),
        ),
        child: const Center(
          child:AppIconWidget(assetPath: AssetImages.add,size: 26,color: AppColors.primaryColor,)
        ),
      ),
    );
  }
}