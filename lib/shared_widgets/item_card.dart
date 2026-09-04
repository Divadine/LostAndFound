import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class ItemCard extends StatelessWidget {
  final String imgUrl;
  final String postId;
  final String? profileName;
  final Color? bg;
  final String title;
  final String location;
  final String? time;
  final int? foundCount;
  final String? profileUrl;
  final int? percentageMatch;
  final String date;
  final List<String>? enquiredProfile;
  final String? newMessageCount;
  final bool isFromEnquiry;
  final bool isFound;
  final String? description;
  final void Function() onTap;
  final void Function()? onEnquiryTap; // NEW
  final String? profileId;
  final bool? isFromHomePage;
  final bool showPostId;
  final bool isTopAvailabilityCard;
  final double? imageWidth;
  final int? postIntId; // NEW — numeric id for API calls
  final void Function(int)? onDeleted; // NEW — refresh trigger after successful delete
  final VoidCallback? onViewAll;
  final int? status;
  final bool showClosedStamp;

  const ItemCard({
    super.key,
    required this.imgUrl,
    required this.title,
    required this.location,
    this.foundCount,
    this.profileUrl,
    this.percentageMatch,
    required this.date,
    this.profileName,
    this.enquiredProfile,
    this.newMessageCount,
    this.isFromEnquiry = false,
    this.isFound = false,
    this.description,
    required this.postId,
    this.time,
    required this.onTap,
    this.onEnquiryTap, // NEW
    this.bg,
    this.profileId,
    this.isFromHomePage,
    required this.showPostId,
    this.isTopAvailabilityCard = false,
    this.imageWidth,
    this.postIntId,
    this.onDeleted,
    this.onViewAll,
    this.status,
    this.showClosedStamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = bg ?? AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        bgColor: cardBg,
        widget: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (percentageMatch != null ||
                profileName != null ||
                profileUrl != null ||
                profileId != null) ...[
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: status == 2
                      ? Colors.transparent
                      : AppColors.grey.withAlpha(20),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    topRight: Radius.circular(10),
                    topLeft: Radius.circular(10),
                  ),
                ),
                child: Row(
                  spacing: 15,
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (profileUrl != null && profileUrl!.trim().isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppCachedNetworkImage(
                          imageUrl: profileUrl!,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ).padVertical(5),
                    if (profileName != null && profileName!.trim().isNotEmpty)
                      AppText(
                        text: profileName!,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),
                    if (profileId != null && profileId!.trim().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == 2
                              ? AppColors.white.withAlpha(100)
                              : AppColors.lightBlue_3,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          text: 'ID : ${profileId ?? '-'}',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    Spacer(),
                    if (percentageMatch != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppUtils.getMatchColor(
                            percentageMatch!,
                          ).withAlpha(70),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          text: '$percentageMatch% match',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: AppUtils.getMatchColor(percentageMatch!),
                        ),
                      ),
                  ],
                ).padHorizontal(18),
              ),
            ],
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCachedNetworkImage(
                      imageUrl: imgUrl,
                      height: 100,
                      width: imageWidth ?? 140,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                          AppText(
                            text: title,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                          if (showPostId)
                            AppText(
                              text: "Posted ID : $postId",
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              color: AppColors.grey,
                            ),
                          SizedBox(height: 5),
                          AppText(
                            text: location,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            maxLine: 1,
                            textOverflow: TextOverflow.ellipsis,
                            color: AppColors.black,
                          ),
                          AppText(
                            text: '${isFound ? 'Found' : 'Lost'} on $date',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                    ),
                    if (profileUrl == null &&
                        !isFromEnquiry &&
                        postIntId != null &&
                        status != 2)
                      PopupMenuButton(
                        color: AppColors.white,
                        icon: AppIconWidget(assetPath: AssetImages.more),
                        offset: const Offset(0, 40),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            height: 0,
                            value: 'delete',
                            //height: 25
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.fieldGrey.withAlpha(50)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AppText(
                                text: 'Delete',
                                color: AppColors.red,
                                fontSize: 14,
                                textAlign: TextAlign.center,
                              ).pad(),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            print('DELETE TAPPED — postIntId: $postIntId');
                            AppDialogue.showPopup(
                              context: context,
                              content: DeletePostReasonsDialog(
                                postId: postIntId!,
                                onDeleted: onDeleted,
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ).pad(),
                if (status == 2 && showClosedStamp)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10), // Moves the stamp down slightly
                            child: Transform.rotate(
                              angle: -0.3, // Slight tilt
                              child: Image.asset(
                                AssetImages.closed,
                                width: 130, // Reduced width to ensure it stays within bounds
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (time != null)
              Row(
                children: [
                  Spacer(),
                  AppText(
                    text: "Posted : $time",
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: AppColors.grey,
                  ).padRight(10),
                ],
              ),
            SizedBox(height: 10),
            if (foundCount != null && status != 2 && !isFound)
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  height: 35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    //border: Border.all(color: AppColors.primaryColor),
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GestureDetector(
                    onTap: onViewAll,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 20,
                      children: [
                        Flexible(
                          child: AppText(
                            text:
                                'Available Matching item - $foundCount founded',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            AppText(
                              text: 'View All',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                            AppIconWidget(assetPath: AssetImages.iosForward),
                          ],
                        ),
                      ],
                    ).padHorizontal(),
                  ),
                ).pad(),
              ),
            if (newMessageCount != null && status != 2)
              Container(
                height: 35,
                width: double.infinity,
                decoration: BoxDecoration(
                  //border: Border.all(color: AppColors.primaryColor),
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // spacing: 20,
                  children: [
                    AppText(
                      text: 'Enquires ',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryBlack,
                    ),
                    if (enquiredProfile != null && enquiredProfile!.isNotEmpty)
                      EnquiredPersonsAvatar(images: enquiredProfile!),
                    GestureDetector(
                      onTap: onEnquiryTap,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 10,
                        children: [
                          AppText(
                            text: 'New Messages',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                          Container(
                            //height: 15,width: 15,
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // borderRadius: BorderRadius.circular(30),
                              color: AppColors.primaryColor,
                            ),
                            child: Center(
                              child: AppText(
                                text: newMessageCount!,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          AppIconWidget(assetPath: AssetImages.iosForward),
                        ],
                      ),
                    ),
                  ],
                ).padHorizontal(),
              ).pad(),
            if (status == 2)
              Container(
                height: 35,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.closedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: 'Closed',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        AppText(
                          text: 'View Details',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.green,
                        ),
                        AppIconWidget(
                          assetPath: AssetImages.iosForward,
                          color: AppColors.green,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ).padHorizontal(),
              ).pad(),
          ],
        ),
      ),
    );
  }
}
