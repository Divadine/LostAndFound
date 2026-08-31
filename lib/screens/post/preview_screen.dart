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
                    _buildImagePreview(),

                    const SizedBox(height: 16),


                     _buildBasicInformation(),

                    const SizedBox(height: 16),

                    _buildStepTwoInformation(),

                    const SizedBox(height: 20),
                  ],
                ).pad(16),
              ),
            ),

            AppButton(
              title: 'Submit',
              onTap: () {
                //Navigator.pop(context, true);
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
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview() {
    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final imagePath = widget.imagePaths.first;

    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallRow(
                  'Item Type',
                  widget.subCategory.isNotEmpty
                      ? widget.subCategory
                      : widget.category,
                ),

                if (widget.itemName.isNotEmpty)
                  _buildSmallRow(
                    'Item Name',
                    widget.itemName,
                  ),

                if (widget.color.isNotEmpty)
                  _buildSmallRow(
                    'Color',
                    widget.color,
                  ),

                for (final field in widget.stepOneFields)
                  if (field['value']?.trim().isNotEmpty == true)
                    _buildSmallRow(
                      field['field'] ?? '',
                      field['value'] ?? '',
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
            width: 80,
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
  // STEP 1 INFORMATION
  // ============================================================

  Widget _buildBasicInformation() {
    return AppContainer(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in widget.stepOneFields)
            _buildInfoRow(
              field['field'] ?? '',
              field['value'] ?? '',
            ),

          if (widget.itemName.isNotEmpty)
            _buildInfoRow(
              'Item Name',
              widget.itemName,
            ),

          if (widget.color.isNotEmpty)
            _buildInfoRow(
              'Color',
              widget.color,
            ),
        ],
      ).pad(12),
    );
  }

  // ============================================================
  // STEP 2 INFORMATION
  // ============================================================

  Widget _buildStepTwoInformation() {
    return AppContainer(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.whereDidYouLose.trim().isNotEmpty)
            _buildLabeledBlock(
              'Where did you lose it ?',
              widget.whereDidYouLose,
            ),

          if (widget.locations.isNotEmpty)
            _buildLocations(),

          if (widget.selectedDate != null)
            _buildLabeledBlock(
              'Date',
              _formatDate(widget.selectedDate),
            ),

          if (widget.description.trim().isNotEmpty)
            _buildLabeledBlock(
              'Description',
              widget.description,
            ),

          if (widget.audioPath != null &&
              widget.audioPath!.trim().isNotEmpty)
            _buildAudioPreview(),

          if (widget.videoPath != null &&
              widget.videoPath!.trim().isNotEmpty)
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
            padding: const EdgeInsets.only(bottom: 6),
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

        const Divider(),
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

  // ============================================================
  // COMMON DETAILS
  // ============================================================

  Widget _buildInfoRow(String title, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: AppText(
              text: title,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),

          Expanded(
            child: AppText(
              text: value,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledBlock(
      String title,
      String value,
      ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
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

          const SizedBox(height: 6),

          const Divider(),
        ],
      ),
    );
  }
}
