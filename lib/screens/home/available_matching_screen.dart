import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/posts_model/post_match_item.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:intl/intl.dart';

class AvailableMatchingScreen extends StatefulWidget {
  final int postId;
  final String imgUrl;
  final String title;
  final String location;
  final String date;
  final String postUid;
  final int? foundCount;
  final bool isReceived;

  const AvailableMatchingScreen({
    super.key,
    required this.postId,
    required this.imgUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.postUid,
    this.foundCount,
    this.isReceived = false,
  });

  @override
  State<AvailableMatchingScreen> createState() => _AvailableMatchingScreenState();
}

class _AvailableMatchingScreenState extends State<AvailableMatchingScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  List<MatchItemModel> matches = [];
  int matchingCount = 0;
  bool isLoadingMatches = true;
  String? matchesErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      isLoadingMatches = true;
      matchesErrorMessage = null;
    });

    final response = await authController.getPostMatches(postId: widget.postId);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        matches = response.data!.matches;
        matchingCount = response.data!.matchingCount;
        isLoadingMatches = false;
      });
    } else {
      setState(() {
        matchesErrorMessage = response.message.isNotEmpty ? response.message : 'Failed to fetch matches';
        isLoadingMatches = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
  }

  Future<void> _onMatchTap(MatchItemModel match) async {
    if (!mounted) return;

    AppRoutes.pushNamed(
      AppRoutes.lostItemsDetailsScreen,
      arguments: {
        'postId': match.postId,
        'userId': match.userId,
        'percentageMatch': match.matchPercentage,
        'posterName': match.posterName,
        'posterAvatar': match.posterAvatar,
        'originalPostId': widget.postId,   // NEW — needed for creating an enquiry later
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Available Matching item - ${isLoadingMatches ? (widget.foundCount ?? 0) : matchingCount} founded',
        leadingSvg: AssetImages.backArrow,
        titleColor: AppColors.primaryColor,
        leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () => AppRoutes.pop(),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 10,
          children: [

            ItemCard(
              isFromEnquiry: true,
              isFound: false,
              imgUrl: widget.imgUrl,
              title: widget.title,
              location: widget.location,
              date: widget.date,
              postId: widget.postUid,
              bg: AppColors.lightBlue_2,
              onTap: () {},
              showPostId: true,
            ),

            AppContainer(
              widget: AppText(
                text: 'Matching Items(${isLoadingMatches ? (widget.foundCount ?? 0) : matchingCount})',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                textAlign: TextAlign.center,
              ).pad(12),
            ),


            Expanded(
              child: isLoadingMatches
                  ? const Center(child: CircularProgressIndicator())
                  : matches.isEmpty
                  ? const Center(child: AppText(text: 'No matches found yet'))
                  : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return ItemCard(
                    imageWidth: 170,
                    isFromEnquiry: true,
                    isFound: true,
                    imgUrl: match.postImages.trim(),
                    title: match.name,
                    location: match.location,
                    date: _formatDate(match.postDate),
                    postId: match.postUid,
                    onTap: () => _onMatchTap(match),
                    percentageMatch: match.matchPercentage,
                    showPostId: false,
                    profileId: match.userUid,
                    profileUrl: match.posterAvatar.isNotEmpty ? match.posterAvatar : null,
                    profileName: match.posterName,
                  ).padBottom(10);
                },
              ),
            ),
          ],
        ).pad(),
      ),
      bottomNavigationBar: widget.isReceived
          ? SafeArea(
        child: SucessCard(
          name: 'Dinesh',
          location: '22 May 2026',
          onTap: () {
            AppUiHelper.showBottomSheet(
              context: context,
              child: ReceivedDetails(
                isReceivedFromPolice: false,
                isReceivedFromFounder: false,
                isReceivedFromOthers: false,
              ),
            );
          },
          isReceiver: false,
        ).pad(),
      )
          : (matches.isEmpty)
          ? null
          : SafeArea(
        child: AppContainer(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                title: 'Receive',
                onTap: () {
                  AppUiHelper.showBottomSheet(
                    context: context,
                    child: ReceiveHandoverSheet(title:widget.title,  isReceiver: true, postId:  widget.postId, ),
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
}