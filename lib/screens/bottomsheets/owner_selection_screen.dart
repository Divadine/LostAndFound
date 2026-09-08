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

      if (!mounted) return;

      if (!enquiryResponse.isSuccess) {
        setState(() {
          errorMessage = enquiryResponse.message.isNotEmpty ? enquiryResponse.message : 'Failed to fetch enquiries';
          isLoading = false;
        });
        return;
      }

      final Map<int, int> postMap = {};
      final Map<int, int> userMap = {};
      final Map<String, int> uidMap = {};
      final List<HandoverOwnerModel> newOwners = [];

      if (enquiryResponse.data != null) {
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