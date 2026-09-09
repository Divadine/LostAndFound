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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';

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
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      owners = []; // Clear state to avoid stale data
      enquiryIdByMatchedPostId = {};
      enquiryIdByUserId = {};
      enquiryIdByUserUid = {};
    });

    try {
      final enquiryResponse = await authController.viewEnquiry(postId: widget.postId);

      // Fetch matches to get match percentages for those who might not be in the enquiry list
      final matchesResponse = await authController.getPostMatches(postId: widget.postId);
      final Map<int, int> matchPercentages = {};
      if (matchesResponse.isSuccess && matchesResponse.data != null) {
        for (final m in matchesResponse.data!.matches) {
          matchPercentages[m.userId] = m.matchPercentage;
        }
      }

      if (!mounted) return;

      final Map<int, int> postMap = {};
      final Map<int, int> userMap = {};
      final Map<String, int> uidMap = {};
      final List<HandoverOwnerModel> newOwners = [];

      if (enquiryResponse.isSuccess && enquiryResponse.data != null) {
        for (final e in enquiryResponse.data!.enquiries) {
          // Map to HandoverOwnerModel for display
          newOwners.add(HandoverOwnerModel(
            postId: e.matchedPostId,
            userId: e.enquirerUserId,
            userUid: e.userUid,
            name: e.enquirerName,
            phoneno: e.phoneno,
            profileImageUrl: e.enquirerProfileImg,
            matchPercentage: e.matchPercentage,
          ));

          // Populate lookup maps
          postMap[e.matchedPostId] = e.enquiryId;
          userMap[e.enquirerUserId] = e.enquiryId;
          uidMap[e.userUid] = e.enquiryId;
        }
      }

      // SUPPLEMENT: Also check chat rooms for enquiries where the current user is a participant.
      final currentUserId = AppPreferences.getUserId()?.toString();
      if (currentUserId != null) {
        try {
          final chatSnap = await FirebaseFirestore.instance
              .collection('chatRooms')
              .where('users', arrayContains: currentUserId)
              .get();

          for (final doc in chatSnap.docs) {
            final data = doc.data();
            final roomPostId = data['postId']?.toString() ?? '';
            final roomMatchedPostId = data['matchedPostId']?.toString() ?? '';

            // Filter rooms related to the current post (either as primary post or matched post)
            if (roomPostId != widget.postId.toString() && roomMatchedPostId != widget.postId.toString()) {
              continue;
            }

            final users = List<String>.from(data['users'] ?? []);
            final otherUserIdStr = users.firstWhere((id) => id != currentUserId, orElse: () => '');
            if (otherUserIdStr.isEmpty) continue;

            final otherUserId = int.tryParse(otherUserIdStr) ?? 0;
            
            // Skip if already added from viewEnquiry
            if (userMap.containsKey(otherUserId)) continue;

            final enquiryIdStr = data['enquiryId']?.toString() ?? '';
            final enquiryId = int.tryParse(enquiryIdStr) ?? 0;
            // If there's no enquiryId in the chat room, we can't proceed with the handover flow
            if (enquiryId == 0) continue;

            final participants = data['participants'] as Map<String, dynamic>? ?? {};
            final otherPart = participants[otherUserIdStr] as Map<String, dynamic>? ?? {};

            // The "other" post ID is the one that isn't the current widget.postId
            final otherPostIdStr = (roomPostId == widget.postId.toString()) ? roomMatchedPostId : roomPostId;
            final otherPostId = int.tryParse(otherPostIdStr) ?? 0;

            newOwners.add(HandoverOwnerModel(
              postId: otherPostId,
              userId: otherUserId,
              userUid: otherUserIdStr,
              name: otherPart['name']?.toString() ?? 'User $otherUserId',
              phoneno: otherPart['phone']?.toString() ?? '',
              profileImageUrl: otherPart['avatar']?.toString(),
              matchPercentage: matchPercentages[otherUserId] ?? 0,
            ));

            postMap[otherPostId] = enquiryId;
            userMap[otherUserId] = enquiryId;
            uidMap[otherUserIdStr] = enquiryId;
          }
        } catch (e) {
          debugPrint('Error fetching chat rooms for handover: $e');
        }
      }

      if (!mounted) return;

      if (newOwners.isEmpty && !enquiryResponse.isSuccess) {
        setState(() {
          errorMessage = enquiryResponse.message.isNotEmpty ? enquiryResponse.message : 'Failed to fetch enquiries';
          isLoading = false;
        });
        return;
      }

      setState(() {
        owners = newOwners;
        enquiryIdByMatchedPostId = postMap;
        enquiryIdByUserId = userMap;
        enquiryIdByUserUid = uidMap;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error fetching enquiries: $e\n$st');
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

    // Try lookup by Post ID from pre-fetched map
    int? enquiryId = enquiryIdByMatchedPostId[selectedOwner.postId];

    // Try lookup by User ID / UID from pre-fetched map
    enquiryId ??= enquiryIdByUserId[selectedOwner.userId];
    enquiryId ??= enquiryIdByUserUid[selectedOwner.userUid];

    if (enquiryId == null) {
      AppDialogue.showPopup(
        context: context,
        content: const AppText(
          text: 'No enquiry details found for this match.',
          textAlign: TextAlign.center,
        ),
      );
      return;
    }

    final result = await AppUiHelper.showBottomSheet(
      maxHeightFactor: 0.7,
      context: context,
      child: HandoverProofDocuments(
        selectedOwner: selectedOwner,
        postId: widget.postId,
        enquiryId: enquiryId,
        isReceiver: widget.isReceiver,
      ),
    );

    if (result != null && result is HandoverSubmissionData) {
      if (!mounted) return;

      // Close the current selection sheet (HandoverMatchedPersons)
      AppRoutes.pop();

      // Get the stable context from the navigator key for subsequent dialogs
      final activeContext = AppUtils.navigatorKey.currentContext;
      if (activeContext == null) return;

      // Show OTP screen on top of the parent screen
      final otpResult = await AppDialogue.showPopup(
        context: activeContext,
        content: OtpSharedScreen(
          isAlternateNumber: true,
          mobileNumber: result.maskedPhone,
          onVerifyOtp: (otp) async {
            final response = await authController.verifyHandoverOtp(
              phone: result.phoneno,
              otp: otp,
            );
            return response.status == 1 ? null : response.message;
          },
          onSendOtp: () async {
            final response = await authController.generateHandoverOtp(
              phone: result.phoneno,
            );
            if (response.isSuccess) return null;
            if (response.currentState == CurrentState.noInternet) {
              return 'No internet connection. Please check your network.';
            }
            return response.message.isNotEmpty ? response.message : 'Failed to send OTP';
          },
        ),
      );

      if (otpResult == true) {
        // Final submission
        await HandoverProofDocuments.submitHandover(
          context: activeContext,
          authController: authController,
          selectedImage: result.selectedImage,
          description: result.description,
          phoneno: result.phoneno,
          postId: widget.postId,
          enquiryId: enquiryId,
          isReceiver: widget.isReceiver,
          selectedOwner: selectedOwner,
          onLoading: (loading) {
            // Option to show a loading overlay if needed
          },
        );
      }
    }
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
                id: 'LF${owner.userId.toString().padLeft(4, '0')}',
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