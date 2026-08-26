import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/posts_model/enquiry_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
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

  Future<void> _fetchEnquiries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    debugPrint('================ ENQUIRY LIST ================');
    debugPrint('EnquiryListScreen postId: ${widget.postId}');
    debugPrint('Calling: /enquiry/viewEnquiry/${widget.postId}');

    final response = await authController.viewEnquiry(
      postId: widget.postId,
    );

    debugPrint('Response success: ${response.isSuccess}');
    debugPrint('Response message: ${response.message}');
    debugPrint(
      'Enquiries count: ${response.data?.enquiriesCount}',
    );

    for (final e in response.data?.enquiries ?? []) {
      debugPrint(
        'Enquiry ID: ${e.enquiryId}',
      );
      debugPrint(
        'Matched Post ID: ${e.matchedPostId}',
      );
      debugPrint(
        'Enquirer: ${e.enquirerName}',
      );
      debugPrint(
        'Description: ${e.description}',
      );
    }

    debugPrint('==============================================');

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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "Enquires",
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
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
                      isReceiver: false,   // this is the Found-item post -> hand over flow
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

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(text: errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(title: 'Retry', onTap: _fetchEnquiries),
          ],
        ),
      );
    }

    final post = enquiryData?.post;
    final enquiries = enquiryData?.enquiries ?? [];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        ItemCard(
          imageWidth: 170,
          isFromEnquiry: true,
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
        ),

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
                return buildEnquiryCard(
                  context: context,
                  profileImage: e.enquirerProfileImg,
                  name: e.enquirerName,
                  time: _timeAgo(e.createdAt),
                  matchPercentage: '${e.matchPercentage}%',
                  description: e.description,
                  messageOnTap: () {
                    // TODO: navigate to chat screen for this enquiry
                    // needs e.enquiryId / enquirer identity once chat route is confirmed
                  },
                  detailOnTap: () {
                   // AppRoutes.pushNamed(AppRoutes.lostItemsDetailsScreen);
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
  }) {
    return AppContainer(
      widget: Column(
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
                    : Icon(Icons.person, color: AppColors.primaryColor),
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
                    SizedBox(height: 2),

                    AppText(
                      text: 'Enquired $time',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: AppColors.grey,
                    ),

                    SizedBox(height: 5),
                    AppText(
                      text: description,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(5),
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
                  border: Border.all(color: AppColors.primaryColor),
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
                  border: Border.all(color: AppColors.primaryColor),
                  radius: BorderRadius.circular(10),
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ).pad(),
    ).pad();
  }
}