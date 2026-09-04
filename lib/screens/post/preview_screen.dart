import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lost_and_found/shared_widgets/app_audio_player.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/shared_widgets/app_video_player.dart';

class PostPreviewScreen extends StatefulWidget {
  final String category;
  final String subCategory;
  final String itemName;
  final String color;

  final List<Map<String, String>> stepOneFields;
  final List<String> imagePaths;

  final String whereDidYouLose;
  final List<String> locations;
  final DateTime? selectedDate;
  final String description;
  final String itemTypeLabel;
  final String itemTypeValue;

  final String? audioPath;
  final String? videoPath;

  const PostPreviewScreen({
    super.key,
    required this.category,
    required this.subCategory,
    required this.itemName,
    required this.color,
    required this.stepOneFields,
    required this.imagePaths,
    required this.whereDidYouLose,
    required this.locations,
    required this.selectedDate,
    required this.description,
    required this.itemTypeLabel,
    required this.itemTypeValue,
    this.audioPath,
    this.videoPath,
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Preview',
              centerTitle: true,
              leadingSvg: AssetImages.backArrow,
              leadingIconColor: AppColors.primaryColor,
              onLeadingTap: () => AppRoutes.pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFirstContainer(),

                    const SizedBox(height: 16),

                    _buildSecondContainer(),

                    const SizedBox(height: 20),
                  ],
                ).pad(16),
              ),
            ),

            AppButton(
              title: 'Submit',
              onTap: () {
                AppDialogue.showPopup(context: context, content: PostLive());
              },
              radius: BorderRadius.circular(10),
              fontSize: 14,
            ).pad(20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FIRST CONTAINER: Item Image + Basic Details
  // ============================================================

  Widget _buildFirstContainer() {
    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final imagePath = widget.imagePaths.first;

    final brandField = widget.stepOneFields.firstWhere(
      (f) => f['field']?.toLowerCase().trim() == 'brand',
      orElse: () => {},
    );
    final modelField = widget.stepOneFields.firstWhere(
      (f) => f['field']?.toLowerCase().trim() == 'model',
      orElse: () => {},
    );

    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallRow(
                  'Item Type',
                  widget.itemTypeValue,
                ),
                if (brandField.isNotEmpty && brandField['value']?.isNotEmpty == true)
                  _buildSmallRow(
                    'Brand',
                    brandField['value']!,
                  ),
                if (modelField.isNotEmpty && modelField['value']?.isNotEmpty == true)
                  _buildSmallRow(
                    'Model',
                    modelField['value']!,
                  ),
                if (widget.color.isNotEmpty)
                  _buildSmallRow(
                    'Color',
                    widget.color,
                  ),
              ],
            ),
          ),
        ],
      ).pad(8),
    );
  }

  Widget _buildSmallRow(String title, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: AppText(
              text: title,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: AppText(
              text: value,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECOND CONTAINER: Landmark, Dynamic Fields, Location, Date, Description, Media
  // ============================================================

  Widget _buildSecondContainer() {
    final otherStepOneFields = widget.stepOneFields.where((f) {
      final name = f['field']?.toLowerCase().trim();
      return name != 'brand' && name != 'model' && name != 'subcategory' && name != 'color';
    }).toList();

    return AppContainer(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Land Mark
          if (widget.whereDidYouLose.trim().isNotEmpty)
            _buildLabeledBlock(
              'Land Mark',
              widget.whereDidYouLose,
            ),

          // 2. Step 1 Other fields (IMEI, Serial, Watch Face Type, etc.)
          for (final field in otherStepOneFields)
            if (field['value']?.trim().isNotEmpty == true)
              _buildLabeledBlock(
                field['field'] ?? '',
                field['value'] ?? '',
              ),

          // 3. Location
          if (widget.locations.isNotEmpty)
            _buildLocations(),

          // 4. Date
          if (widget.selectedDate != null)
            _buildLabeledBlock(
              'Date',
              _formatDate(widget.selectedDate),
            ),

          // 5. Description
          if (widget.description.trim().isNotEmpty)
            _buildLabeledBlock(
              'Description',
              widget.description,
            ),

          // 6. Voice
          if (widget.audioPath != null && widget.audioPath!.trim().isNotEmpty)
            _buildAudioPreview(),

          // 7. Video
          if (widget.videoPath != null && widget.videoPath!.trim().isNotEmpty)
            _buildVideoPreview(),
        ],
      ).pad(12),
    );
  }

  Widget _buildLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Location',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor,
        ),

        const SizedBox(height: 6),

        for (int i = 0; i < widget.locations.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconWidget(
                  assetPath: AssetImages.mapIcon,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: AppText(
                    text: widget.locations[i],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildAudioPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Voice Description',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor,
        ),

        const SizedBox(height: 8),

        AppAudioPlayer(
          url: widget.audioPath!,
        ),

        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Video Description',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor,
        ),

        const SizedBox(height: 8),

        AppVideoPlayer(
          url: widget.videoPath!,
        ),
      ],
    );
  }

  Widget _buildLabeledBlock(String title, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: title,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor,
        ),

        const SizedBox(height: 4),

        AppText(
          text: value,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),

        const SizedBox(height: 8),

        const Divider(),

        const SizedBox(height: 14),
      ],
    );
  }
}
