import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/posts_model/single_match_item.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/screens/bottomsheets/send_enquiry.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class LostItemsDetailsScreen extends StatefulWidget {
  const LostItemsDetailsScreen({
    super.key,
  });

  @override
  State<LostItemsDetailsScreen> createState() =>
      _LostItemsDetailsScreenState();
}

class _LostItemsDetailsScreenState
    extends State<LostItemsDetailsScreen> {

  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  SingleMatchModel? postDetails;

  bool isLoading = true;
  String? errorMessage;

  int? postId;
  int? userId;
  int? percentageMatch;

  bool _argumentsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argumentsRead) return;

    _argumentsRead = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      postId = args['postId'];
      userId = args['userId'];
      percentageMatch = args['percentageMatch'];
    }

    if (postId != null && userId != null) {
      _fetchPostDetails();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid post details';
      });
    }
  }

  Future<void> _fetchPostDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getSingleMatch(
      postId: postId!,
      userId: userId!,
    );

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        postDetails = response.data;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to fetch post';
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        toolbarHeight: 0,
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

  Widget _buildDetails() {
    final post = postDetails!;

    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          CustomAppBar(
            title: 'Lost Items',
            leadingIconColor: AppColors.primaryColor,
            leadingSvg: AssetImages.backArrow,
            onLeadingTap: () {
              AppRoutes.pop();
            },
            titleColor: AppColors.primaryColor,
            centerTitle: true,
          ),

          AppContainer(
            widget: Column(
              spacing: 15,
              children: [

                // IMAGE
                if (post.imageUrl.isNotEmpty)
                  AppCachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),

                // BASIC DETAILS
                _buildBasicDetails(post),

                // MATCH
                AppContainer(
                  widget: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: 'Match',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withAlpha(50),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: AppText(
                          text:
                          '${percentageMatch ?? 0}% match',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // DYNAMIC VALUES
                _buildDynamicValues(post),

                // DESCRIPTION
                if (post.description.isNotEmpty)
                  _buildDescription(post),

                // VOICE
                if (post.audioUrl!.isNotEmpty)
                  _buildVoiceDescription(post),
              ],
            ),
          ),

          AppButton(
            title: 'Send Enquiry',
            onTap: () {
              AppUiHelper.showBottomSheet(
                showHandle: false,
                showCloseIcon: false,
                context: context,
                child: SendEnquiry(),
              );
            },
            fontSize: 14,
            radius: BorderRadius.circular(10),
          ),
        ],
      ).pad(16),
    );
  }

  Widget _buildBasicDetails(SingleMatchModel post) {
    return AppContainer(
      widget: Column(
        children: [

          _buildInfoRow(
            'Item',
            post.itemName,
          ),

          _buildInfoRow(
            'Color',
            post.color,
          ),

          _buildInfoRow(
            'Location',
            post.location,
          ),

          _buildInfoRow(
            'Date',
            _formatDate(post.postDate),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDynamicValues(
      SingleMatchModel post,
      ) {
    if (post.values.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppContainer(
      widget: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          for (final field in post.values) ...[
            AppText(
              text: field.fieldName,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),

            const SizedBox(height: 4),

            AppText(
              text: field.fieldValue,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),

            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(
      SingleMatchModel post,
      ) {
    return AppContainer(
      widget: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'Description',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),

          const SizedBox(height: 5),

          AppText(
            text: post.description,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceDescription(
      SingleMatchModel post,
      ) {
    return AppContainer(
      widget: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'Voice Description',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),

          const SizedBox(height: 10),

          AppText(
            text: post.audioUrl!,
            fontSize: 11,
          ),
        ],
      ),
    );
  }
}