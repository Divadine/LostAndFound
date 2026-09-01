import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';
import 'package:lost_and_found/models/posts_model/enquiry_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class EnquiryListScreen extends StatefulWidget {
  final int postId;

  const EnquiryListScreen({super.key, required this.postId});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  bool isLoading = true;
  String? errorMessage;
  PostEnquiriesModel? enquiryData;

  @override
  void initState() {
    super.initState();
    _fetchEnquiries();
  }

  Future<void> _openChat(
      dynamic enquiry,
      EnquiryPostModel? post,
      ) async {
    try {
      final currentUserId = AppPreferences.getUserId();

      if (currentUserId == null) {
        debugPrint('[Chat] Current user ID is null');
        return;
      }

      final otherUserId = enquiry.enquirerUserId;

      if (otherUserId == null) {
        debugPrint('[Chat] Enquirer user ID is null');
        return;
      }

      debugPrint('[Chat] Current user: $currentUserId');
      debugPrint('[Chat] Other user: $otherUserId');
      debugPrint('[Chat] Enquiry sender: $otherUserId');

      final roomId = await ChatService.createChatRoom(
        currentUserId: currentUserId.toString(),
        otherUserId: otherUserId.toString(),

        /// Pass item details to ensure consistency
        itemName: post?.name ?? '',
        itemImage: post != null && post.images.isNotEmpty ? post.images.first : '',
        itemLocation: post?.location ?? '',
        itemPostDate: post?.postDate != null
            ? DateFormat('d MMM yyyy').format(post!.postDate!)
            : '',
        postId: widget.postId.toString(),

        /// The enquirer is the person who
        /// sent the enquiry.
        enquirySenderId: otherUserId.toString(),
      );

      if (!mounted) return;

      AppRoutes.pushNamed(
        AppRoutes.individualChatScreen,
        arguments: {
          'roomId': roomId,
          'currentUserId': currentUserId.toString(),
          'otherUserId': otherUserId.toString(),
          'otherUserName': enquiry.enquirerName,
          'otherUserAvatar': enquiry.enquirerProfileImg,
          'otherUserPhone': '',
          'itemName': post?.name ?? '',
          'itemImage': post != null && post.images.isNotEmpty ? post.images.first : '',
          'itemLocation': post?.location ?? '',
          'itemPostDate': post?.postDate != null
              ? DateFormat('d MMM yyyy').format(post!.postDate!)
              : '',
          'itemPostId': widget.postId.toString(),
          'enquirySenderId': otherUserId.toString(),
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[Chat] Error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open chat'),
        ),
      );
    }
  }

  Future<void> _fetchEnquiries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    debugPrint('================ ENQUIRY LIST ================');
    print('EnquiryListScreen postId: ${widget.postId}');
    print('Calling: /enquiry/viewEnquiry/${widget.postId}');

    final response = await authController.viewEnquiry(
      postId: widget.postId,
    );

    print('Response success: ${response.isSuccess}');
    print('Response message: ${response.message}');
    print('Enquiries count: ${response.data?.enquiriesCount}');

    for (final e in response.data?.enquiries ?? []) {
      print('Enquiry ID: ${e.enquiryId}');
      print('Matched Post ID: ${e.matchedPostId}');
      print('Enquirer: ${e.enquirerName}');
      print('Description: ${e.description}');
    }

    print('==============================================');

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        enquiryData = response.data;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to load enquiries';
        isLoading = false;
      });
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = enquiryData?.post?.status == 2;

    return Scaffold(
      backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
      appBar: CustomAppBar(
        title: "Enquires",
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
        backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: isClosed
          ? SafeArea(
        child: SucessCard(
          name: 'Karthi Kumar', // TODO: Get actual owner name from handover details
          location: enquiryData?.post?.postDate != null
              ? DateFormat('d MMM yyyy').format(enquiryData!.post!.postDate!)
              : '',
          isReceiver: false,
          onTap: () {
            // Show Handover Details bottom sheet directly
            AppUiHelper.showBottomSheet(
              context: context,
              showHandle: false,
              showCloseIcon: true,
              child: ReceivedDetails(
                type: TransferType.handOverToOwner,
                data: TransferData(
                  name: 'Karthi Kumar',
                  avatarUrl: '',
                  userId: 'LF2489',
                  phoneNumber: '9751333333',
                  description:
                  'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                  proofPhotos: [
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_u2Fv-qj6_jO_Z_qX_L9f-l4Xj_Y_Y7_Lw&s'
                  ],
                  matchPercentage: 95,
                ),
              ),
            );
          },
        ).padHorizontal(16).padBottom(16),
      )
          : SafeArea(
        child: AppContainer(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              AppButton(
                title: 'Hand Over',
                onTap: () {
                  AppUiHelper.showBottomSheet(
                    context: context,
                    child: ReceiveHandoverSheet(
                      title: enquiryData?.post?.name ?? '',
                      isReceiver: false, // this is the Found-item post -> hand over flow
                      postId: widget.postId,
                    ),
                  );
                },
                radius: BorderRadius.circular(14),
              ),
            ],
          ),
        ).pad(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final post = enquiryData?.post;
    final enquiries = enquiryData?.enquiries ?? [];
    final isClosed = post?.status == 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        ItemCard(
          imageWidth: 170,
          isFromEnquiry: true,
          isFound: true,
          imgUrl: post != null && post.images.isNotEmpty ? post.images.first : '',
          title: post?.name ?? '',
          location: post?.location ?? '',
          date: post?.postDate != null
              ? DateFormat('d MMM yyyy').format(post!.postDate!)
              : '',
          postId: post?.postUid ?? '',
          bg: AppColors.lightBlue_2,
          onTap: () {
            AppRoutes.pushNamed(AppRoutes.lostItemsDetailsScreen);
          },
          showPostId: true,
          status: post?.status,
        ).pad(10),

        Row(
          children: [
            AppText(
              text: 'Enquires Received',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              textAlign: TextAlign.center,
            ).pad(12),
          ],
        ),

        Expanded(
          child: enquiries.isEmpty
              ? const Center(child: AppText(text: 'No enquiries yet'))
              : RefreshIndicator(
            onRefresh: _fetchEnquiries,
            child: ListView.builder(
              itemCount: enquiries.length,
              itemBuilder: (context, index) {
                final e = enquiries[index];

                // Only the specific enquiry that was actually accepted /
                // handed over gets highlighted once the post is closed.
                // (Using match % as a fallback is unreliable — it can
                // highlight the wrong card, or more than one card.)
                final isWinner = isClosed && e.status == 2;

                // TEMP DEBUG — remove once we confirm what field/value
                // actually marks an enquiry as accepted.
                debugPrint(
                  'Enquiry ${e.enquiryId}: status=${e.status}, '
                      'matchedPostId=${e.matchedPostId}, isClosed=$isClosed, '
                      'isWinner=$isWinner',
                );

                return buildEnquiryCard(
                  context: context,
                  bgColor: isWinner ? AppColors.closedColor : AppColors.white,
                  profileImage: e.enquirerProfileImg,
                  name: e.enquirerName,
                  time: _timeAgo(e.createdAt),
                  matchPercentage: '${e.matchPercentage}%',
                  description: e.description,
                  messageOnTap: () async {
                    await _openChat(e, post);
                  },
                  detailOnTap: () {
                    AppRoutes.pushNamed(
                      AppRoutes.lostItemsDetailsScreen,
                      arguments: {
                        'postId': e.matchedPostId,
                        'userId': e.enquirerUserId,
                        'percentageMatch': e.matchPercentage,
                        'posterName': e.enquirerName,
                        'posterAvatar': e.enquirerProfileImg,
                        'originalPostId': widget.postId,
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    ).pad();
  }

  Widget buildEnquiryCard({
    required BuildContext context,
    required String profileImage,
    required String name,
    required String time,
    required String matchPercentage,
    required String description,
    required void Function() messageOnTap,
    required void Function() detailOnTap,
    Color? bgColor,
  }) {
    return AppContainer(
      bgColor: bgColor,
      widget: InkWell(
        onTap: detailOnTap,
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  child: profileImage.isNotEmpty
                      ? AppCachedNetworkImage(
                    borderRadius: BorderRadius.circular(20),
                    imageUrl: profileImage,
                  )
                      : Icon(
                    Icons.person,
                    color: AppColors.primaryColor,
                  ),
                ),

                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: name,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),

                      const SizedBox(height: 2),

                      AppText(
                        text: 'Enquired $time',
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: AppColors.grey,
                      ),

                      const SizedBox(height: 5),

                      AppText(
                        text: description,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),

                Spacer(),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withAlpha(30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AppText(
                    text: '$matchPercentage match',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),

            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: AppButton(
                    title: 'Message',
                    fontSize: 14,
                    height: 30,
                    onTap: messageOnTap,
                    border: Border.all(
                      color: AppColors.primaryColor,
                    ),
                    radius: BorderRadius.circular(10),
                    prefixIcon: AssetImages.message_icon,
                    bgColor: Colors.transparent,
                    textColor: AppColors.primaryColor,
                  ),
                ),

                Expanded(
                  child: AppButton(
                    title: 'View Details',
                    height: 30,
                    fontSize: 14,
                    onTap: detailOnTap,
                    border: Border.all(
                      color: AppColors.primaryColor,
                    ),
                    radius: BorderRadius.circular(10),
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ).pad(),
      ),
    ).pad(10);
  }
}