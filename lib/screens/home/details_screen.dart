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
  final bool isLostPost;
  final bool hideEnquiryButton;

  const LostItemsDetailsScreen({
    super.key,
    required this.postId,
    required this.userId,
    this.percentageMatch,
    this.posterName = '',
    this.posterAvatar = '',
    this.originalPostId = 0,
    this.isLostPost = false,
    this.hideEnquiryButton = false,
  });

  @override
  State<LostItemsDetailsScreen> createState() =>
      _LostItemsDetailsScreenState();
}

class _LostItemsDetailsScreenState extends State<LostItemsDetailsScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
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

  // ============================================================
  // MEDIA URL HELPER
  // ============================================================

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

    // Remove accidental leading slash
    final normalizedPath = cleanUrl.startsWith('/')
        ? cleanUrl.substring(1)
        : cleanUrl;

    return 'https://lost-and-found.skyraantech.com/backend/$normalizedPath';
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  String get _itemImageUrl {
    return _getMediaUrl(postDetails?.imageUrl);
  }

  String get _posterAvatarUrl {
    final avatar = widget.posterAvatar.isNotEmpty
        ? widget.posterAvatar
        : (postDetails?.posterAvatar ?? '');

    return _getMediaUrl(avatar);
  }

  // ============================================================
  // ENQUIRY STATUS
  // ============================================================

  Future<void> _checkEnquiryStatus() async {
    final userId = AppPreferences.getUserId();

    if (userId == null || postDetails == null) {
      return;
    }

    final currentUserId = userId.toString().trim();
    final otherUserId = widget.userId.toString().trim();

    final users = [
      currentUserId,
      otherUserId,
    ]..sort();

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

  // ============================================================
  // FETCH DETAILS
  // ============================================================

  Future<void> _fetchPostDetails() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
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

        // ========================================================
        // IMAGE DEBUG
        // ========================================================

        debugPrint('========================================');
        debugPrint('         POST DETAILS DEBUG');
        debugPrint('========================================');

        debugPrint('Post ID       : ${postDetails?.id}');
        debugPrint('User ID       : ${postDetails?.userId}');
        debugPrint('Item Name     : ${postDetails?.itemName}');

        debugPrint('----------------------------------------');

        debugPrint('RAW IMAGE URL : ${postDetails?.imageUrl}');
        debugPrint('FINAL IMAGE   : $_itemImageUrl');

        debugPrint('----------------------------------------');

        debugPrint('Location      : ${postDetails?.location}');
        debugPrint('Description   : ${postDetails?.description}');
        debugPrint('Audio URL     : ${postDetails?.audioUrl}');
        debugPrint('Video URL     : ${postDetails?.videoUrl}');

        debugPrint('========================================');

        await _checkEnquiryStatus();
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to fetch post';

          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('ERROR FETCHING POST DETAILS: $e');

      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
        isLoading = false;
      });
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return DateFormat('d MMM yyyy').format(date);
  }

  // ============================================================
  // POSTER DETAILS
  // ============================================================

  String get _posterName {
    return widget.posterName.isNotEmpty
        ? widget.posterName
        : (postDetails?.posterName ?? '');
  }

  String get _posterAvatar {
    return widget.posterAvatar.isNotEmpty
        ? widget.posterAvatar
        : (postDetails?.posterAvatar ?? '');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isClosed = postDetails?.status == 2;

    return Scaffold(
      backgroundColor:
      isClosed ? AppColors.closedColor : AppColors.white,
      appBar: AppBar(
        backgroundColor:
        isClosed ? AppColors.closedColor : AppColors.primaryColor,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? _buildError()
          : postDetails == null
          ? const Center(
        child: AppText(
          text: 'No details found',
        ),
      )
          : _buildDetails(),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text: errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          AppButton(
            title: 'Retry',
            onTap: _fetchPostDetails,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildDetails() {
    final post = postDetails!;

    final brandField = post.values.firstWhere(
          (v) => v.fieldName?.toLowerCase() == 'brand',
      orElse: () => SingleMatchValue(
        fieldName: 'Brand',
        fieldValue: '',
      ),
    );

    final modelField = post.values.firstWhere(
          (v) => v.fieldName?.toLowerCase() == 'model',
      orElse: () => SingleMatchValue(
        fieldName: 'Model',
        fieldValue: '',
      ),
    );

    final subCategoryField = post.values.firstWhere(
          (v) => v.fieldName?.toLowerCase() == 'subcategory',
      orElse: () => SingleMatchValue(
        fieldName: 'Item Type',
        fieldValue: '',
      ),
    );

    final displayFields = post.values
        .where(
          (v) =>
      v.fieldName != null &&
          v.fieldName!.toLowerCase() != 'color' &&
          v.fieldName!.toLowerCase() != 'brand' &&
          v.fieldName!.toLowerCase() != 'model' &&
          v.fieldName!.toLowerCase() != 'subcategory' &&
          v.fieldValue != null &&
          v.fieldValue!.trim().isNotEmpty,
    )
        .toList();

    final isClosed = post.status == 2;

    return Column(
      children: [
        // ========================================================
        // APP BAR
        // ========================================================

        CustomAppBar(
          title: widget.isLostPost ? 'Lost Item' : 'Found Item',
          leadingIconColor: AppColors.primaryColor,
          leadingSvg: AssetImages.backArrow,
          onLeadingTap: () => AppRoutes.pop(),
          titleColor: AppColors.primaryColor,
          centerTitle: true,
          backgroundColor:
          isClosed ? AppColors.closedColor : AppColors.white,
        ),

        // ========================================================
        // CONTENT
        // ========================================================

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // 1. ITEM IMAGE
                // ==================================================

                if (_itemImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppCachedNetworkImage(
                      imageUrl: _itemImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ==================================================
                // 2. NAME + PROFILE IMAGE
                // ==================================================

                if (_posterName.isNotEmpty)
                  Row(
                    children: [
                      ClipOval(
                        child: _posterAvatarUrl.isNotEmpty
                            ? AppCachedNetworkImage(
                          imageUrl: _posterAvatarUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        )
                            : CircleAvatar(
                          radius: 17,
                          backgroundColor:
                          AppColors.grey.withAlpha(60),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppText(
                        text: _posterName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ).padHorizontal(),

                const SizedBox(height: 16),

                // ==================================================
                // 3. ITEM TYPE / BRAND / MODEL / COLOR
                // ==================================================

                AppContainer(
                  bgColor:
                  isClosed ? AppColors.closedColor : AppColors.white,
                  widget: Column(
                    children: [
                      _buildInfoRow(
                        'Item Type',
                        (subCategoryField.fieldValue?.isNotEmpty ?? false)
                            ? subCategoryField.fieldValue!
                            : (post.itemName.isNotEmpty
                            ? post.itemName
                            : 'Item'),
                      ),

                      if (brandField.fieldValue?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Brand',
                          brandField.fieldValue!,
                        ),

                      if (modelField.fieldValue?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Model',
                          modelField.fieldValue!,
                        ),

                      _buildInfoRow(
                        'Color',
                        post.color,
                      ),
                    ],
                  ).padHorizontal(5),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // 4. MATCH
                // ==================================================

                AppContainer(
                  bgColor:
                  isClosed ? AppColors.closedColor : AppColors.white,
                  height: 50,
                  widget: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        text: 'matches',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AppText(
                          text:
                          '${widget.percentageMatch ?? 0}% match',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ).padHorizontal(),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // 5. OTHER DETAILS
                // ==================================================

                AppContainer(
                  bgColor:
                  isClosed ? AppColors.closedColor : AppColors.white,
                  widget: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // Dynamic fields
                      for (int i = 0;
                      i < displayFields.length;
                      i++)
                        _buildDividerLabeledBlock(
                          displayFields[i].fieldName!,
                          displayFields[i].fieldValue!,
                          isFirst: i == 0,
                        ),

                      // Location
                      _buildDividerLabeledBlock(
                        'Location',
                        post.location,
                        isFirst: displayFields.isEmpty,
                      ),

                      // Date
                      if (post.postDate != null)
                        _buildDividerLabeledBlock(
                          'Date',
                          _formatDate(post.postDate),
                        ),

                      // Description
                      if (post.description.isNotEmpty)
                        _buildDividerLabeledBlock(
                          'Description',
                          post.description,
                        ),

                      // ==================================================
                      // AUDIO
                      // ==================================================

                      if (post.audioUrl?.isNotEmpty == true)
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Divider(
                              color: AppColors.fieldGrey,
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 8),
                            const AppText(
                              text: 'Voice Description',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(height: 8),
                            AppAudioPlayer(
                              url: _getMediaUrl(post.audioUrl),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                      // ==================================================
                      // VIDEO
                      // ==================================================

                      if (post.videoUrl?.isNotEmpty == true)
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Divider(
                              color: AppColors.fieldGrey,
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 8),
                            const AppText(
                              text: 'Video Description',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(height: 8),
                            AppVideoPlayer(
                              url: _getMediaUrl(post.videoUrl),
                            ),
                          ],
                        ),
                    ],
                  ).pad(10),
                ),
              ],
            ).pad(16),
          ).padBottom(20),
        ),

        // ========================================================
        // CLOSED POST
        // ========================================================

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
                      avatarUrl: _posterAvatarUrl,
                      userId: post.userId.toString(),
                      phoneNumber: '',
                      description: post.description,
                      proofPhotos: _itemImageUrl.isNotEmpty
                          ? [_itemImageUrl]
                          : [],
                      matchPercentage:
                      widget.percentageMatch,
                    ),
                  ),
                );
              },
              isReceiver: post.postType == 0,
            )
                .padHorizontal(16)
                .padBottom(16),
          )

        // ========================================================
        // SEND ENQUIRY
        // ========================================================

        else if (!widget.hideEnquiryButton)
          AppButton(
            title: 'Send Enquiry',
            onTap: () {
              // ==================================================
              // EXISTING ENQUIRY
              // ==================================================

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
                    'otherUserAvatar': _posterAvatarUrl,
                    'otherUserPhone':
                    postDetails?.posterName ?? '',
                    'itemName':
                    postDetails?.itemName ?? '',
                    'itemImage': _itemImageUrl,
                    'itemLocation':
                    postDetails?.location ?? '',
                    'itemPostDate':
                    _formatDate(postDetails?.postDate),
                    'itemPostId':
                    postDetails?.id.toString(),
                    'enquirySenderId':
                    userId.toString(),
                  },
                );

                return;
              }

              // ==================================================
              // DEBUG
              // ==================================================

              debugPrint(
                '========== SEND ENQUIRY DEBUG ==========',
              );

              debugPrint(
                'CURRENT USER ID       : '
                    '${AppPreferences.getUserId()}',
              );

              debugPrint(
                'CURRENT USER NAME     : '
                    '${AppPreferences.getUserName()}',
              );

              debugPrint('----------------------------------------');

              debugPrint(
                'post.id               : ${post.id}',
              );

              debugPrint(
                'post.userId            : ${post.userId}',
              );

              debugPrint(
                'post.itemName          : ${post.itemName}',
              );

              debugPrint(
                'RAW post.imageUrl      : ${post.imageUrl}',
              );

              debugPrint(
                'FINAL post.imageUrl    : $_itemImageUrl',
              );

              debugPrint(
                'post.location          : ${post.location}',
              );

              debugPrint(
                'post.postDate          : ${post.postDate}',
              );

              debugPrint(
                'post.description       : ${post.description}',
              );

              debugPrint(
                'post.postType          : ${post.postType}',
              );

              debugPrint(
                'post.status            : ${post.status}',
              );

              debugPrint('----------------------------------------');

              debugPrint(
                'widget.postId          : ${widget.postId}',
              );

              debugPrint(
                'widget.userId          : ${widget.userId}',
              );

              debugPrint(
                'widget.originalPostId  : '
                    '${widget.originalPostId}',
              );

              debugPrint(
                'widget.isLostPost      : '
                    '${widget.isLostPost}',
              );

              debugPrint(
                'widget.percentageMatch : '
                    '${widget.percentageMatch}',
              );

              debugPrint('----------------------------------------');

              debugPrint(
                '_posterName            : $_posterName',
              );

              debugPrint(
                '_posterAvatar RAW      : $_posterAvatar',
              );

              debugPrint(
                '_posterAvatar FINAL    : $_posterAvatarUrl',
              );

              debugPrint(
                '========================================',
              );

              // ==================================================
              // SEND ENQUIRY BOTTOM SHEET
              // ==================================================

              AppUiHelper.showBottomSheet(
                showHandle: false,
                showCloseIcon: false,
                context: context,
                child: SendEnquiry(
                  name:
                  AppPreferences.getUserName() ?? '',
                  description: post.description,
                  postId: post.id,
                  matchedPostId: widget.originalPostId,
                  otherUserId: widget.userId,
                  otherUserName: _posterName,
                  otherUserAvatar: _posterAvatarUrl,
                  itemName: post.itemName,

                  // IMPORTANT:
                  // Pass complete image URL
                  itemImage: _itemImageUrl,

                  itemLocation: post.location,
                  itemPostDate:
                  _formatDate(post.postDate),
                  isLostPost: widget.isLostPost,
                ),
              );
            },
            fontSize: 14,
            radius: BorderRadius.circular(10),
          ).pad(16),
      ],
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
      String title,
      String value,
      ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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

  // ============================================================
  // DIVIDER LABELED BLOCK
  // ============================================================

  Widget _buildDividerLabeledBlock(
      String title,
      String value, {
        bool isFirst = false,
      }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          const Divider(
            color: AppColors.fieldGrey,
            thickness: 0.5,
          ),

        const SizedBox(height: 8),

        AppText(
          text: title,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor,
          textAlign: TextAlign.left,
        ),

        const SizedBox(height: 4),

        AppText(
          text: value,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
