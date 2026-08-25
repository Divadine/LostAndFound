import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/posts_model/single_match_item.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_audio_player.dart';
import 'package:lost_and_found/shared_widgets/app_video_player.dart';
import 'package:lost_and_found/screens/bottomsheets/send_enquiry.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class LostItemsDetailsScreen extends StatefulWidget {
  final int postId;
  final int userId;
  final int? percentageMatch;
  final String posterName;
  final String posterAvatar;
  final int originalPostId;

  const LostItemsDetailsScreen({
    super.key,
    required this.postId,
    required this.userId,
    this.percentageMatch,
    this.posterName = '',
    this.posterAvatar = '',
     this.originalPostId = 0,
  });

  @override
  State<LostItemsDetailsScreen> createState() => _LostItemsDetailsScreenState();
}

class _LostItemsDetailsScreenState extends State<LostItemsDetailsScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  SingleMatchModel? postDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.postId != 0 && widget.userId != 0) {
      _fetchPostDetails();
    } else {
      isLoading = false;
      errorMessage = 'Invalid post details';
    }
  }

  Future<void> _fetchPostDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getSingleMatch(
      postId: widget.postId,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        postDetails = response.data;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response.message.isNotEmpty ? response.message : 'Failed to fetch post';
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
  }

  // Prefer the value forwarded from AvailableMatchingScreen; fall back to
  // whatever the single-match API itself returned.
  String get _posterName =>
      widget.posterName.isNotEmpty ? widget.posterName : (postDetails?.posterName ?? '');

  String get _posterAvatar =>
      widget.posterAvatar.isNotEmpty ? widget.posterAvatar : (postDetails?.posterAvatar ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.primaryColor, toolbarHeight: 0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : postDetails == null
          ? const Center(child: AppText(text: 'No details found'))
          : _buildDetails(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(text: errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 15),
          AppButton(title: 'Retry', onTap: _fetchPostDetails),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final post = postDetails!;

    debugPrint('POST color: "${post.color}"');
    debugPrint('POST values count: ${post.values.length}');
    for (final v in post.values) {
      debugPrint('  -> name="${v.fieldName}" value="${v.fieldValue}" step=${v.step}');
    }
    final stepOneFields = post.values.where((v) => v.step == 1).toList();

    final stepOneNames = stepOneFields.map((v) => v.fieldName.toLowerCase()).toSet();
    final displayFields = post.values
        .where((v) => v.fieldName.toLowerCase() != 'color' && v.fieldValue.trim().isNotEmpty)
        .toList();
    final stepTwoFields = post.values
        .where((v) => v.step != 1 && !stepOneNames.contains(v.fieldName.toLowerCase()))
        .toList();

    return Column(
      children: [
        CustomAppBar(
          title: 'Found Items',
          leadingIconColor: AppColors.primaryColor,
          leadingSvg: AssetImages.backArrow,
          onLeadingTap: () => AppRoutes.pop(),
          titleColor: AppColors.primaryColor,
          centerTitle: true,
        ),

        // Scrollable body — grows/shrinks with however many fields this post has.
        Expanded
          (
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                // 1. UPLOADED ITEM IMAGE
                if (post.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppCachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                    ),
                  ),

                // 2. NAME + PROFILE IMAGE (no box, sits directly on background)
                if (_posterName.isNotEmpty)
                  Row(
                    spacing: 10,
                    children: [
                      ClipOval(
                        child: _posterAvatar.isNotEmpty
                            ? AppCachedNetworkImage(
                          imageUrl: _posterAvatar,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        )
                            : CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.grey.withAlpha(60),
                        ),
                      ),
                      AppText(
                        text: _posterName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ).padHorizontal(),

                // 3. STEP ONE FORM: ITEM TYPE / BRAND / MODEL / SUBCATEGORY / COLOR
                AppContainer(
                  widget: Column(
                    children: [
                      for (final field in displayFields)
                        _buildInfoRow(
                          field.fieldName.toLowerCase() == 'subcategory' ? 'Item Type' : field.fieldName,
                          field.fieldValue,
                        ),
                      _buildInfoRow('Color', post.color),
                    ],
                  ),
                ),

                // 4. MATCH
                AppContainer(
                  height: 40,
                  widget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(text: 'matches', fontSize: 14, fontWeight: FontWeight.w500),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          text: '${widget.percentageMatch ?? 0}% match',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ).padHorizontal(),
                ),

                // 5. STEP TWO FORM: LANDMARK / MATERIAL / SPECIAL MARKS / LOCATION / DATE / DESCRIPTION / AUDIO / VIDEO
                AppContainer(
                  widget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      // for (final field in stepTwoFields)
                      //   _buildLabeledBlock(field.fieldName, field.fieldValue),

                      if (post.location.isNotEmpty)
                        _buildLabeledBlock('Location', post.location),

                      if (post.postDate != null)
                        _buildLabeledBlock('Date', _formatDate(post.postDate)),

                      if (post.description.isNotEmpty)
                        _buildLabeledBlock('Description', post.description),

                      if (post.audioUrl?.isNotEmpty == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            AppText(
                              text: 'Voice Description',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                            AppAudioPlayer(url: post.audioUrl!),
                          ],
                        ),

                      if (post.videoUrl?.isNotEmpty == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            AppText(
                              text: 'Video Description',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                            AppVideoPlayer(url: post.videoUrl!),
                          ],
                        ),
                    ],
                  ).padHorizontal(16),
                ),
              ],
            ).pad(16),
          ).padBottom(20),
        ),

        // Send Enquiry stays pinned below the scroll area.

        AppButton(
          title: 'Send Enquiry',
          onTap: () {
            AppUiHelper.showBottomSheet(
              showHandle: false,
              showCloseIcon: false,
              context: context,
              child: SendEnquiry(
                name: _posterName,
                description: post.description,
                postId: widget.originalPostId,   // the enquirer's own lost post
                matchedPostId: post.id,
              ),
            );
          },
          fontSize: 14,
          radius: BorderRadius.circular(10),
        ).pad(16),
      ],

    );
  }

  Widget _buildInfoRow(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: AppText(text: title, fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Expanded(
            child: AppText(text: value, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledBlock(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        AppText(text:title, fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primaryColor,textAlign: TextAlign.left,),
        AppText(text:value , fontWeight: FontWeight.w400, fontSize: 12),
      ],
    );
  }
}