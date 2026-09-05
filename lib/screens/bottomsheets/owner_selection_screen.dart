import 'package:flutter/cupertino.dart';
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

  // matched_postid -> enquiry_id, built from viewEnquiry so we know which
  // enquiry a given owner's match corresponds to. createHandover requires
  // enquiry_id (the backend marks that enquiry resolved), but
  // getHandoverOwnerList doesn't return it — so we cross-reference here.
  Map<int, int> enquiryIdByMatchedPostId = {};

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

      final map = <int, int>{};
      if (enquiryResponse.isSuccess && enquiryResponse.data != null) {
        for (final e in enquiryResponse.data!.enquiries) {
          // If a matched post has multiple enquiries, keep the most recent
          // one (list order from API is assumed chronological; adjust if not).
          map[e.matchedPostId] = e.enquiryId;
        }
      } else {
        debugPrint('[Handover] viewEnquiry failed: ${enquiryResponse.message}');
      }

      setState(() {
        owners = (ownersResponse.data as List<HandoverOwnerModel>);
        enquiryIdByMatchedPostId = map;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error fetching owners/enquiries: $e\n$st');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Something went wrong: $e';
        isLoading = false;
      });
    }
  }

  void _onNext() {
    if (selectedIndex == null) return;
    final selectedOwner = owners[selectedIndex!];

    final enquiryId = enquiryIdByMatchedPostId[selectedOwner.postId];
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