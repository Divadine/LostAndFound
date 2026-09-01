import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';
import 'package:lost_and_found/models/posts_model/single_match_item.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_audio_player.dart';
import 'package:lost_and_found/shared_widgets/app_video_player.dart';
import 'package:lost_and_found/screens/bottomsheets/send_enquiry.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
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
  bool hasEnquired = false;
  String? existingRoomId;

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

  Future<void> _checkEnquiryStatus() async {
    final userId = AppPreferences.getUserId();
    if (userId == null || postDetails == null) return;

    final currentUserId = userId.toString().trim();
    final otherUserId = widget.userId.toString().trim();
    final users = [currentUserId, otherUserId]..sort();
    final roomId = '${users[0]}_${users[1]}_${postDetails!.id}';

    final room = await ChatService.getRoom(roomId);
    if (room != null) {
      if (!mounted) return;
      setState(() {
        hasEnquired = true;
        existingRoomId = roomId;
      });
    }
  }

  String _getMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final cleanUrl = url.trim();

    // Already a complete URL
    if (cleanUrl.startsWith('http://') ||
        cleanUrl.startsWith('https://')) {
      return cleanUrl;
    }

    // API returns relative paths such as:
    // uploads/video/xxxxx.mp4
    // uploads/audio/xxxxx.m4a
    return 'https://lost-and-found.skyraantech.com/backend/$cleanUrl';
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
      await _checkEnquiryStatus();
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
    final isClosed = postDetails?.status == 2;
    return Scaffold(
      backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
      appBar: AppBar(
        backgroundColor: isClosed ? AppColors.closedColor : AppColors.primaryColor,
        toolbarHeight: 0,
        elevation: 0,
      ),
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

    final isClosed = post.status == 2;

    return Column(
      children: [
        CustomAppBar(
          title: 'Found Items',
          leadingIconColor: AppColors.primaryColor,
          leadingSvg: AssetImages.backArrow,
          onLeadingTap: () => AppRoutes.pop(),
          titleColor: AppColors.primaryColor,
          centerTitle: true,
          backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
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
                  bgColor: isClosed ? AppColors.closedColor : AppColors.white,
                  widget: Column(
                    children: [
                      for (final field in displayFields)
                        _buildInfoRow(
                          field.fieldName.toLowerCase() == 'subcategory' ? 'Item Type' : field.fieldName,
                          field.fieldValue,
                        ),
                      _buildInfoRow('Color', post.color),
                    ],
                  ).padHorizontal(5),
                ),

                // 4. MATCH
                AppContainer(
                  bgColor: isClosed ? AppColors.closedColor : AppColors.white,
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
                  bgColor: isClosed ? AppColors.closedColor : AppColors.white,
                  widget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
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
                            AppAudioPlayer(
                              url: _getMediaUrl(post.audioUrl),
                            ),
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
                            AppVideoPlayer(
                              url: _getMediaUrl(post.videoUrl),
                            ),
                          ],
                        ),
                    ],
                  ).pad(5),
                ),
              ],
            ).pad(16),
          ).padBottom(20),
        ),

        // Send Enquiry or Success Card stays pinned below the scroll area.
        if (post.status == 2)
          SafeArea(
            child: SucessCard(
              name: _posterName,
              location: _formatDate(post.postDate),
              onTap: () {
                AppUiHelper.showBottomSheet(
                  context: context,
                  showHandle: false,
                  showCloseIcon: true,
                  child: ReceivedDetails(
                    type: post.postType == 0
                        ? TransferType.receiveToOwner
                        : TransferType.handOverToOwner,
                    data: TransferData(
                      name: _posterName,
                      avatarUrl: _posterAvatar,
                      userId: 'LF2489',
                      phoneNumber: '', // Not directly available here
                      description: post.description,
                      proofPhotos:
                          post.imageUrl.isNotEmpty ? [post.imageUrl] : [],
                      matchPercentage: widget.percentageMatch,
                    ),
                  ),
                );
              },
              isReceiver: post.postType == 0,
            ).padHorizontal(16).padBottom(16),
          )
        else
          AppButton(
            title: 'Send Enquiry',
            onTap: () {
              if (hasEnquired) {
                AppSnackBar.show(
                  context: context,
                  message: 'Enquiry already sent',
                );
                final userId = AppPreferences.getUserId();
                AppRoutes.pushNamed(
                  AppRoutes.individualChatScreen,
                  arguments: {
                    'roomId': existingRoomId,
                    'currentUserId': userId.toString(),
                    'otherUserId': widget.userId.toString(),
                    'otherUserName': _posterName,
                    'otherUserAvatar': _posterAvatar,
                    'otherUserPhone': postDetails?.posterName ?? '', // Fallback or correct phone if available
                    'itemName': postDetails?.itemName ?? '',
                    'itemImage': postDetails?.imageUrl ?? '',
                    'itemLocation': postDetails?.location ?? '',
                    'itemPostDate': _formatDate(postDetails?.postDate),
                    'itemPostId': postDetails?.id.toString(),
                    'enquirySenderId': userId.toString(),
                  },
                );
                return;
              }
              AppUiHelper.showBottomSheet(
                showHandle: false,
                showCloseIcon: false,
                context: context,
                child: SendEnquiry(
                  name: _posterName,
                  description: post.description,
                  postId: widget.originalPostId, // the enquirer's own lost post
                  matchedPostId: post.id,
                  otherUserId: widget.userId, // owner of the matched post
                  otherUserName: _posterName,
                  otherUserAvatar: _posterAvatar,
                  itemName: post.itemName, // adjust field name if different on SingleMatchModel
                  itemImage: post.imageUrl,
                  itemLocation: post.location,
                  itemPostDate: _formatDate(post.postDate),
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