import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';

import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'owner_proof_submission.dart';


class ReceivedDetails extends StatefulWidget {
  final TransferType type;
  final TransferData data;

  const ReceivedDetails({
    super.key,
    required this.type,
    required this.data,
  });

  @override
  State<ReceivedDetails> createState() =>
      _ReceivedDetailsState();
}

class _ReceivedDetailsState extends State<ReceivedDetails> {
  // ============================================================
  // TYPE CHECKS
  // ============================================================

  bool get isPolice {
    return widget.type == TransferType.receiveToPolice ||
        widget.type == TransferType.handOverToPolice;
  }

  bool get isOthers {
    return widget.type == TransferType.receiveToOthers ||
        widget.type == TransferType.handOverToOthers;
  }

  bool get isOwner {
    return widget.type == TransferType.receiveToOwner ||
        widget.type == TransferType.handOverToOwner;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          const Center(
            child: AppText(
              text: 'Handover Details',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ======================================================
          // USER / POLICE / OTHERS
          // ======================================================

          _buildSourceCard(),

          // ======================================================
          // PROOF PHOTOS
          // ======================================================

          buildProofDocuments(
            title: '1. Proof Photos',
            widget: _buildProofPhotos(),
          ),

          // ======================================================
          // DESCRIPTION
          // ======================================================

          buildProofDocuments(
            title: '2. Description',
            widget: AppText(
              text: widget.data.description.isNotEmpty
                  ? widget.data.description
                  : 'No description available',
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),

          // ======================================================
          // PHONE
          // ======================================================

          if (widget.data.phoneNumber.isNotEmpty)
            buildProofDocuments(
              title: '3. Phone Number',
              widget: AppText(
                text: widget.data.phoneNumber,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
        ],
      ).pad(2),
    );
  }

  // ============================================================
  // SOURCE CARD
  // ============================================================

  Widget _buildSourceCard() {
    if (isPolice) {
      return _buildPoliceCard();
    }

    if (isOthers) {
      return _buildOthersCard();
    }

    return _buildOwnerCard();
  }

  // ============================================================
  // OWNER CARD
  // ============================================================

  Widget _buildOwnerCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            child: widget.data.avatarUrl.isNotEmpty
                ? AppCachedNetworkImage(
              imageUrl: widget.data.avatarUrl,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(30),
            )
                : Icon(
              Icons.person,
              color: AppColors.primaryColor,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget.data.name.isNotEmpty
                      ? widget.data.name
                      : 'Unknown User',
                  fontSize: 13,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),

                if (widget.data.matchPercentage != null) ...[
                  const SizedBox(height: 5),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppUtils
                          .getMatchColor(
                        widget.data.matchPercentage!,
                      )
                          .withAlpha(70),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppText(
                      text:
                      'ID : ${widget.data.userId ?? '-'}',
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (widget.data.matchPercentage != null)
            _buildMatch(
              widget.data.matchPercentage!,
            ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // OTHERS CARD
  // ============================================================

  Widget _buildOthersCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            child: widget.data.avatarUrl.isNotEmpty
                ? AppCachedNetworkImage(
              imageUrl: widget.data.avatarUrl,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(30),
            )
                : AppIconWidget(
              assetPath: AssetImages.threeDotsHorizontal,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget.data.name.isNotEmpty
                      ? widget.data.name
                      : 'Others',
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),

                if (widget.data.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  AppText(
                    text: widget.data.phoneNumber,
                    fontSize: 11,
                    color: AppColors.fieldGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ],
            ),
          ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // POLICE CARD
  // ============================================================

  Widget _buildPoliceCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconWidget(
            assetPath: AssetImages.policeStation,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget
                      .data
                      .policeStationName
                      .isNotEmpty
                      ? widget.data.policeStationName
                      : 'Police Station',
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),

                AppText(
                  text: widget
                      .data
                      .policeStationAddress
                      .isNotEmpty
                      ? widget.data.policeStationAddress
                      : 'Address not available',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fieldGrey,
                  textOverflow: TextOverflow.ellipsis,
                  maxLine: 3,
                ),
              ],
            ),
          ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // MATCH
  // ============================================================

  Widget _buildMatch(int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppUtils
            .getMatchColor(percentage)
            .withAlpha(70),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        text: '$percentage% Match',
        fontWeight: FontWeight.w500,
        fontSize: 10,
        color: AppUtils.getMatchColor(
          percentage,
        ),
      ),
    );
  }

  // ============================================================
  // PROOF PHOTOS
  // ============================================================

  Widget _buildProofPhotos() {
    if (widget.data.proofPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.fieldGrey.withAlpha(50),
          ),
        ),
        child: AppText(
          text: 'No proof photos available',
          fontSize: 12,
          color: AppColors.fieldGrey,
        ),
      );
    }

    return Column(
      spacing: 8,
      children: [
        for (final imageUrl in widget.data.proofPhotos)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported,
                    color: AppColors.fieldGrey,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}