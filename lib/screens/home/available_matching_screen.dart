import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';

class AvailableMatchingScreen extends StatefulWidget {
  final int postId;
  final String imgUrl;
  final String title;
  final String location;
  final String date;
  final String postUid;
  final int? foundCount;
  final bool isReceived;
  final int? status;
  final bool isFound;
  final int? categoryId;

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
    this.status,
    this.isFound = false,
    this.categoryId,
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
  MatchedPostSummary? postSummary;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    debugPrint('========== AVAILABLE MATCHING INIT ==========');
    debugPrint('widget.postId   : ${widget.postId}');
    debugPrint('widget.postUid  : ${widget.postUid}');
    debugPrint('widget.isFound  : ${widget.isFound}');
    debugPrint('widget.status   : ${widget.status}');
    debugPrint('widget.isReceived : ${widget.isReceived}');
    debugPrint('==============================================');
    _initConnectivityListener();
    _fetchMatches();
  }

  void _initConnectivityListener() async {
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOfflineStatus);
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;
    setState(() {
      _isOffline = offline;
    });

    if (!offline && matches.isEmpty && !isLoadingMatches) {
      _fetchMatches();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      isLoadingMatches = true;
      matchesErrorMessage = null;
    });

    final response = await authController.getPostMatches(postId: widget.postId);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      debugPrint('========== GET POST MATCHES DEBUG ==========');
      debugPrint('Requested postId : ${widget.postId}');
      debugPrint('matchingCount    : ${response.data!.matchingCount}');
      debugPrint('matches.length   : ${response.data!.matches.length}');

      for (final match in response.data!.matches) {
        debugPrint('----- MATCH -----');
        debugPrint('postId          : ${match.postId}');
        debugPrint('postUid         : ${match.postUid}');
        debugPrint('userId          : ${match.userId}');
        debugPrint('userUid         : ${match.userUid}');
        debugPrint('posterName      : ${match.posterName}');
        debugPrint('posterAvatar    : ${match.posterAvatar}');
        debugPrint('name            : ${match.name}');
        debugPrint('description     : ${match.description}');
        debugPrint('postImages      : ${match.postImages}');
        debugPrint('matchPercentage : ${match.matchPercentage}');
        debugPrint('status          : ${match.status}');
      }

      debugPrint('============================================');

      setState(() {
        matches = response.data!.matches;
        matchingCount = response.data!.matchingCount;
        postSummary = response.data!.post;
        isLoadingMatches = false;
      });

      // ============================================================
      // FALLBACK FOR CLOSED POSTS:
      // If handover_info is missing from Match API, try viewEnquiry API.
      // Both sides must read the SAME completed handover record.
      // ============================================================
      if (widget.status == 2 || widget.isReceived) {
        if (postSummary != null && postSummary!.handoverType == 0) {
          debugPrint('[HandoverFallback] handover_info missing in Match API for postId=${widget.postId}. Trying viewEnquiry...');
          final enqResp = await authController.viewEnquiry(postId: widget.postId);
          if (enqResp.isSuccess && enqResp.data != null) {
            final enqPost = enqResp.data!.post;
            if (enqPost != null && enqPost.handoverType != 0) {
              debugPrint('[HandoverFallback] Found handover info in viewEnquiry API!');
              if (mounted) {
                setState(() {
                  postSummary = MatchedPostSummary(
                    id: postSummary!.id,
                    postUid: postSummary!.postUid,
                    name: postSummary!.name,
                    userId: postSummary!.userId,
                    location: postSummary!.location,
                    postDate: postSummary!.postDate,
                    createdAt: postSummary!.createdAt,
                    images: postSummary!.images,
                    handoverType: enqPost.handoverType,
                    handoverName: enqPost.handoverName,
                    stationName: enqPost.stationName,
                    stationAddress: enqPost.stationAddress,
                    handoverDescription: enqPost.handoverDescription,
                    handoverPhoneno: enqPost.handoverPhoneno,
                    handoverImg: enqPost.handoverImg,
                    handoverMatchPercentage: enqPost.handoverMatchPercentage,
                    handoverUserUid: enqPost.handoverUserUid,
                    handoverDate: enqPost.handoverDate,
                    handoverAvatar: enqPost.handoverAvatar,
                  );
                });
              }
            }
          }
        }
      }
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

    debugPrint('========== MATCH TAP DEBUG ==========');
    debugPrint('match.postId       : ${match.postId}');
    debugPrint('match.userId       : ${match.userId}');
    debugPrint('match.posterName   : ${match.posterName}');
    debugPrint('widget.postId (original) : ${widget.postId}');
    debugPrint('=====================================');
    AppRoutes.pushNamed(
      AppRoutes.lostItemsDetailsScreen,
      arguments: {
        'postId': match.postId,
        'userId': match.userId,
        'percentageMatch': match.matchPercentage,
        'posterName': match.posterName,
        'posterAvatar': match.posterAvatar,
        'originalPostId': widget.postId,
        'isLostPost': widget.isFound, // If the main post is Found (true), the match is Lost (true). If main is Lost (false), match is Found (false).
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.status == 2;

    // Find the winning match if the post is closed
    MatchItemModel? winnerMatch;
    if (isClosed || widget.isReceived) {
      for (final m in matches) {
        if (m.status == 2) {
          winnerMatch = m;
          break;
        }
      }
      winnerMatch ??= matches.isNotEmpty ? matches.first : null;
      debugPrint('[WinnerMatch] isClosed=$isClosed isReceived=${widget.isReceived} '
          'matches=${matches.length} winnerMatch=${winnerMatch?.posterName ?? "NULL"}');
    }

    final winnerName = (postSummary != null && postSummary!.handoverName.isNotEmpty)
        ? postSummary!.handoverName
        : ((winnerMatch != null && winnerMatch.posterName.isNotEmpty)
            ? winnerMatch.posterName
            : (widget.isFound ? 'Owner' : 'Finder'));

    return Scaffold(
      backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
      appBar: CustomAppBar(
        backgroundColor: isClosed ? AppColors.closedColor : AppColors.white,
        title: 'Available Matching item - ${isLoadingMatches ? (widget.foundCount ?? 0) : matchingCount} founded',
        leadingSvg: AssetImages.backArrow,
        titleColor: AppColors.primaryColor,
        leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () => AppRoutes.pop(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 10,
              children: [

                ItemCard(
                  isFromEnquiry: true,
                  isFound: widget.isFound,
                  imgUrl: widget.imgUrl,
                  title: widget.title,
                  location: widget.location,
                  date: widget.date,
                  postId: widget.postUid,
                  bg: AppColors.lightBlue_2,
                  onTap: () {},
                  showPostId: true,
                  status: widget.status,
                ).pad(),

                AppContainer(
                  bgColor: isClosed ? AppColors.closedColor : AppColors.white,
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
                      ? _isOffline
                          ? const NoInternetWidget()
                          : const Center(
                              child: CircularProgressIndicator(),
                            )
                      : matches.isEmpty
                      ? const Center(child: AppText(text: 'No matches found yet'))
                      : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];

                      return ItemCard(
                        imageWidth: 170,
                        isFromEnquiry: true,
                        isFound: !widget.isFound, // Matches for Lost item are Found, matches for Found item are Lost.
                        imgUrl: match.postImages,
                        title: match.name,
                        location: match.location,
                        date: _formatDate(match.postDate),
                        postId: match.postUid,
                        bg: AppColors.white,
                        onTap: () => _onMatchTap(match),
                        percentageMatch: match.matchPercentage,
                        showPostId: false,
                        profileId: match.userUid,
                        profileUrl: match.posterAvatar.isNotEmpty ? match.posterAvatar : null,
                        profileName: match.posterName,
                        status: match.status,
                      ).padBottom(10);
                    },
                  ),
                ),
              ],
            ).pad(),
            if (_isOffline)
              Container(
                color: Colors.white,
                child: const NoInternetWidget(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: widget.status == 2
          ? SafeArea(
              child: SucessCard(
                name: winnerName,
                location: widget.date,
                isReceiver: !widget.isFound,
                onTap: () {
                  TransferType type;
                  final hType = postSummary?.handoverType ?? 0;
                  final isJewellery = (postSummary?.name.toLowerCase().contains('jewellery') ?? false) ||
                      (postSummary?.name.toLowerCase().contains('valuable') ?? false) ||
                      (widget.categoryId == 9);

                  if (hType == 2 || isJewellery) {
                    type = widget.isFound ? TransferType.handOverToPolice : TransferType.receiveToPolice;
                  } else if (hType == 3) {
                    type = widget.isFound ? TransferType.handOverToOthers : TransferType.receiveToOthers;
                  } else {
                    type = widget.isFound ? TransferType.handOverToOwner : TransferType.receiveToOwner;
                  }

                  // Data source prioritization: 
                  // Name and userUid from Handover record (postSummary)
                  // Fallback to Match item (winnerMatch)
                  final actorName = postSummary?.handoverName.isNotEmpty == true 
                      ? postSummary!.handoverName 
                      : (winnerMatch?.posterName ?? (widget.isFound ? 'Owner' : 'Finder'));
                  
                  final actorUid = postSummary?.handoverUserUid.isNotEmpty == true
                      ? postSummary!.handoverUserUid
                      : (winnerMatch?.userUid ?? '');

                  final actorAvatar = postSummary?.handoverAvatar.isNotEmpty == true
                      ? postSummary!.handoverAvatar
                      : (winnerMatch?.posterAvatar ?? '');

                  final handoverDesc = postSummary?.handoverDescription.isNotEmpty == true
                      ? postSummary!.handoverDescription
                      : 'Item successfully closed';

                  final handoverImgs = postSummary?.handoverImg ?? [];

                  final matchPercentage = winnerMatch?.matchPercentage ?? postSummary?.handoverMatchPercentage;

                  debugPrint('========== HANDOVER ACTOR ==========');
                  debugPrint('userUid: $actorUid');
                  debugPrint('name: $actorName');
                  debugPrint('avatar: $actorAvatar');
                  debugPrint('=====================================');

                  debugPrint('========== HANDOVER DATA ============');
                  debugPrint('description: $handoverDesc');
                  debugPrint('images: $handoverImgs');
                  debugPrint('date: ${postSummary?.handoverDate}');
                  debugPrint('handoverType: $hType');
                  debugPrint('=====================================');

                  debugPrint('========== MATCH DATA ===============');
                  debugPrint('winnerMatch.matchPercentage: ${winnerMatch?.matchPercentage}');
                  debugPrint('postSummary.handoverMatchPercentage: ${postSummary?.handoverMatchPercentage}');
                  debugPrint('matchPercentage resolved: $matchPercentage');
                  debugPrint('=====================================');

                  AppUiHelper.showBottomSheet(
                    showHandle: false,
                    showCloseIcon: true,
                    onClose: () {
                      AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
                    },
                    context: context,
                    child: ReceivedDetails(
                      type: type,
                      data: TransferData(
                        name: actorName,
                        avatarUrl: actorAvatar,
                        userId: actorUid,
                        phoneNumber: postSummary?.handoverPhoneno ?? '',
                        description: handoverDesc,
                        proofPhotos: handoverImgs,
                        matchPercentage: matchPercentage,
                        handoverDate: postSummary?.handoverDate ?? '',
                        policeStationName: postSummary?.stationName ?? '',
                        policeStationAddress: postSummary?.stationAddress ?? '',
                      ),
                    ),
                  );
                },
              ).padHorizontal(16).padBottom(16),
            )
          : widget.isReceived
              ? SafeArea(
                  child: SucessCard(
                    name: winnerName,
                    location: widget.date,
                    onTap: () {
                      final actorName = postSummary?.handoverName.isNotEmpty == true 
                          ? postSummary!.handoverName 
                          : (winnerMatch?.posterName ?? (widget.isFound ? 'Owner' : 'Finder'));
                      
                      final actorUid = postSummary?.handoverUserUid.isNotEmpty == true
                          ? postSummary!.handoverUserUid
                          : (winnerMatch?.userUid ?? '');

                      final actorAvatar = postSummary?.handoverAvatar.isNotEmpty == true
                          ? postSummary!.handoverAvatar
                          : (winnerMatch?.posterAvatar ?? '');

                      final handoverDesc = postSummary?.handoverDescription.isNotEmpty == true
                          ? postSummary!.handoverDescription
                          : 'Successfully processed';

                      final matchPercentage = winnerMatch?.matchPercentage ?? postSummary?.handoverMatchPercentage;

                      debugPrint('========== HANDOVER ACTOR (isReceived) ==========');
                      debugPrint('userUid: $actorUid');
                      debugPrint('name: $actorName');
                      debugPrint('avatar: $actorAvatar');
                      debugPrint('=================================================');

                      AppUiHelper.showBottomSheet(
                        showHandle: false,
                        showCloseIcon: true,
                        onClose: () {
                          AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
                        },
                        context: context,
                        child: ReceivedDetails(
                          type: TransferType.receiveToOwner,
                          data: TransferData(
                            name: actorName,
                            avatarUrl: actorAvatar,
                            userId: actorUid,
                            phoneNumber: postSummary?.handoverPhoneno ?? '',
                            description: handoverDesc,
                            proofPhotos: postSummary?.handoverImg ?? [],
                            matchPercentage: matchPercentage,
                            handoverDate: postSummary?.handoverDate ?? '',
                          ),
                        ),
                      );
                    },
                    isReceiver: true,
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
                              title: widget.isFound ? 'Hand Over' : 'Receive',
                              onTap: () {
                                debugPrint('[Handover] Opening ReceiveHandoverSheet from AvailableMatching');
                                debugPrint('[Handover] postId: ${widget.postId}');
                                debugPrint('[Handover] categoryId passed: ${widget.categoryId}');

                                AppUiHelper.showBottomSheet(
                                  context: context,
                                  child: ReceiveHandoverSheet(
                                    title: widget.title,
                                    isReceiver: !widget.isFound,
                                    postId: widget.postId,
                                    categoryId: widget.categoryId,
                                    enquiryId: null, // No enquiry yet from match list
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
}
