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
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'owner_proof_submission.dart';

class HandoverMatchedPersons extends StatefulWidget {
  final int postId;
  const HandoverMatchedPersons({super.key, required this.postId});

  @override
  State<HandoverMatchedPersons> createState() => _HandoverMatchedPersonsState();
}

class _HandoverMatchedPersonsState extends State<HandoverMatchedPersons> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  int? selectedIndex;
  List<HandoverOwnerModel> owners = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await authController.getHandoverOwnerLists(postId: widget.postId);

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          owners = response.data!;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty ? response.message : 'Failed to fetch owners';
          isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching owners: $e\n$st');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Something went wrong: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        AppText(text: 'Select the Owner', fontWeight: FontWeight.w600, fontSize: 14),
        AppText(text: 'Choose the correct person from the suggested matches', fontSize: 12, fontWeight: FontWeight.w400),

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
                AppButton(title: 'Retry', onTap: _fetchOwners),
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
          onTap: () {
            if (selectedIndex == null) return;
            final selectedOwner = owners[selectedIndex!];
            AppRoutes.pop();
            AppUiHelper.showBottomSheet(
              maxHeightFactor: 0.7,
              context: context,
              child: HandoverProofDocuments(selectedOwner: selectedOwner, postId: widget.postId,),
            );
          },
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
            CircleAvatar(
              radius: 26,
              child: (image != null && image.isNotEmpty)
                  ? AppCachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(30),
              )
                  : Icon(Icons.person, color: AppColors.primaryColor),
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