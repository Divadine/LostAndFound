import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/handover/handover_owner.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'owner_proof_submission.dart';

class HandoverMatchedPersons extends StatefulWidget {
  final int postId;
  final bool isReceiver;
  const HandoverMatchedPersons({super.key, required this.postId, this.isReceiver = false});

  @override
  State<HandoverMatchedPersons> createState() => _HandoverMatchedPersonsState();
}

class _HandoverMatchedPersonsState extends State<HandoverMatchedPersons> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  int? selectedIndex;
  List<HandoverOwnerModel> owners = [];


  Map<int, int> enquiryIdByMatchedPostId = {};
  Map<int, int> enquiryIdByUserId = {};
  Map<String, int> enquiryIdByUserUid = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUserId = AppPreferences.getUserId();
      final ownersFuture = authController.getHandoverOwnerLists(postId: widget.postId);
      final enquiryFuture = authController.viewEnquiry(postId: widget.postId);

      final ownersResponse = await ownersFuture;
      final enquiryResponse = await enquiryFuture;

      if (!mounted) return;

      if (!ownersResponse.isSuccess || ownersResponse.data == null) {
        setState(() {
          errorMessage = ownersResponse.message.isNotEmpty ? ownersResponse.message : 'Failed to fetch owners';
          isLoading = false;
        });
        return;
      }

      final Map<int, int> postMap = {};
      final Map<int, int> userMap = {};
      final Map<String, int> uidMap = {};

      if (enquiryResponse.isSuccess && enquiryResponse.data != null) {
        final currentUserPhone = AppPreferences.getPhone();
        for (final e in enquiryResponse.data!.enquiries) {
          // 1. Map by Post ID (Direction-agnostic)
          int otherPostId = 0;
          if (e.postId != widget.postId && e.postId != 0) {
            otherPostId = e.postId;
          } else if (e.matchedPostId != widget.postId && e.matchedPostId != 0) {
            otherPostId = e.matchedPostId;
          }

          if (otherPostId != 0) {
            postMap[otherPostId] = e.enquiryId;
          }

          // 2. Map by User ID
          if (e.enquirerUserId != 0 && e.enquirerUserId != currentUserId) {
            userMap[e.enquirerUserId] = e.enquiryId;
          }

          // 3. Map by User UID
          if (e.userUid.isNotEmpty && e.userUid != currentUserPhone) {
            uidMap[e.userUid] = e.enquiryId;
          }
        }
      }

      setState(() {
        owners = (ownersResponse.data as List<HandoverOwnerModel>);
        enquiryIdByMatchedPostId = postMap;
        enquiryIdByUserId = userMap;
        enquiryIdByUserUid = uidMap;
        isLoading = false;
      });
      debugPrint('========================================================');
    } catch (e, st) {
      debugPrint('Error fetching owners/enquiries: $e\n$st');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Something went wrong: $e';
        isLoading = false;
      });
    }
  }

  void _onNext() async {
    if (selectedIndex == null) return;
    final selectedOwner = owners[selectedIndex!];
    final currentUserId = AppPreferences.getUserId();

    debugPrint('================ HANDOVER/RECEIVE LOOKUP DEBUG ================');
    debugPrint('Current User ID: $currentUserId');
    debugPrint('isReceiver: ${widget.isReceiver}');
    debugPrint('Viewer Post ID (widget.postId): ${widget.postId}');
    debugPrint('Selected Owner Post ID: ${selectedOwner.postId}');

    // 1. Try lookup by Post ID from pre-fetched map
    int? enquiryId = enquiryIdByMatchedPostId[selectedOwner.postId];

    // 2. Try lookup by User ID / UID from pre-fetched map
    enquiryId ??= enquiryIdByUserId[selectedOwner.userId];
    enquiryId ??= enquiryIdByUserUid[selectedOwner.userUid];

    // 3. Robust Fallback: Check BOTH posts for enquiries if not found in initial map
    if (enquiryId == null) {
      debugPrint('  Enquiry not found in local maps. Trying deep lookup...');

      setState(() => isLoading = true);

      final postIdsToQuery = [widget.postId, selectedOwner.postId].where((id) => id != 0).toList();

      try {
        for (final pid in postIdsToQuery) {
          if (enquiryId != null) break;

          debugPrint('  Querying viewEnquiry for Post ID: $pid');
          final response = await authController.viewEnquiry(postId: pid);
          if (response.isSuccess && response.data != null) {
            for (final e in response.data!.enquiries) {
              // A. Strongest Match: Both Post IDs match
              bool matchesPosts = (e.postId == widget.postId && e.matchedPostId == selectedOwner.postId) ||
                  (e.postId == selectedOwner.postId && e.matchedPostId == widget.postId);

              // B. Medium Match: One side enquired about the other's post
              // If we are querying the founder's post, check if we are the enquirer
              bool isMeEnquiringFounder = (pid == selectedOwner.postId &&
                  (e.enquirerUserId == currentUserId || (e.userUid.isNotEmpty && e.userUid == AppPreferences.getPhone())));

              // If we are querying our own post, check if founder is the enquirer
              bool isFounderEnquiringMe = (pid == widget.postId &&
                  (e.enquirerUserId == selectedOwner.userId || (e.userUid.isNotEmpty && e.userUid == selectedOwner.userUid)));

              if (matchesPosts || isMeEnquiringFounder || isFounderEnquiringMe) {
                enquiryId = e.enquiryId;
                debugPrint('  MATCH FOUND! Enquiry ID: $enquiryId (via ${matchesPosts ? 'Posts' : isMeEnquiringFounder ? 'Me->Founder' : 'Founder->Me'})');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('  Deep lookup error: $e');
      }

      setState(() => isLoading = false);
    }

    debugPrint('Final Match Result: ${enquiryId != null}');
    debugPrint('========================================================');

    if (!mounted) return;

    if (enquiryId == null) {
      AppDialogue.showPopup(
        context: context,
        content: const AppText(
          text: 'No enquiry found for this match yet. Please send an enquiry first.',
          textAlign: TextAlign.center,
        ),
      );
      return;
    }

    AppRoutes.pop();
    AppUiHelper.showBottomSheet(
      maxHeightFactor: 0.7,
      context: context,
      child: HandoverProofDocuments(
        selectedOwner: selectedOwner,
        postId: widget.postId,
        enquiryId: enquiryId,
        isReceiver: widget.isReceiver,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        AppText(
          text: widget.isReceiver ? 'Select the Founder' : 'Select the Owner',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        AppText(
          text: widget.isReceiver
              ? 'Choose the correct person who found your item'
              : 'Choose the correct person from the suggested matches',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(text: errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(title: 'Retry', onTap: _fetchData),
              ],
            ),
          )
              : owners.isEmpty
              ? const Center(child: AppText(text: 'No matches available'))
              : ListView.builder(
            itemCount: owners.length,
            itemBuilder: (context, index) {
              final owner = owners[index];
              return buildHandOverMatchedId(
                index: index,
                image: owner.profileImageUrl,
                profileName: owner.name,
                id: owner.userUid,
                percentageMatch: owner.matchPercentage,
              );
            },
          ),
        ),

        SizedBox(height: 7),
        AppButton(
          title: 'Next',
          onTap: selectedIndex == null ? () {} : _onNext,
          fontSize: 14,
          bgColor: selectedIndex == null ? AppColors.idCardColor : AppColors.primaryColor,
          textColor: selectedIndex == null ? AppColors.black : AppColors.white,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }

  Widget buildHandOverMatchedId({
    required int index,
    required String? image,
    required String profileName,
    required String id,
    required int percentageMatch,
  }) {
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: AppContainer(
        widget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Radio<int>(
              value: index,
              groupValue: selectedIndex,
              activeColor: AppColors.primaryColor,
              onChanged: (value) => setState(() => selectedIndex = value),
            ),
            (image != null && image.isNotEmpty)
                ? AppCachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.circular(26),
                  )
                : CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.fieldGrey,
                    child: Icon(Icons.person, color: AppColors.primaryColor),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(text: profileName, fontSize: 13, color: AppColors.primaryColor, fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.lightBlue_3, borderRadius: BorderRadius.circular(20)),
                    child: AppText(text: id, fontWeight: FontWeight.w500, fontSize: 10, color: AppColors.primaryColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppUtils.getMatchColor(percentageMatch).withAlpha(70),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(text: '$percentageMatch% match', fontWeight: FontWeight.w500, fontSize: 10, color: AppUtils.getMatchColor(percentageMatch)),
            ),
          ],
        ).pad(),
      ).pad(),
    );
  }
}