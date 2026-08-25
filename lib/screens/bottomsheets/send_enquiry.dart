import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';

import '../post/first_stepper_screen.dart';


class SendEnquiry extends StatefulWidget {
  final String name;
  final String description;
  final int postId;         // the enquirer's own (lost) post
  final int matchedPostId;  // the found post being enquired about

  const SendEnquiry({
    super.key,
    this.name = '',
    this.description = '',
    required this.postId,
    required this.matchedPostId,
  });

  @override
  State<SendEnquiry> createState() => _SendEnquiryState();
}

class _SendEnquiryState extends State<SendEnquiry> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  late final TextEditingController nameController =
  TextEditingController(text: widget.name);
  late final TextEditingController descriptionController =
  TextEditingController(text: widget.description);

  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (nameController.text.trim().isEmpty) {
      AppDialogue.showPopup(context: context, content: const AppText(text: 'Name is required'));
      return;
    }
    if (widget.postId == 0 || widget.matchedPostId == 0) {
      AppDialogue.showPopup(context: context, content: const AppText(text: 'Something went wrong. Please try again.'));
      return;
    }

    setState(() => isSubmitting = true);

    final userId = await AppPreferences.getUserId();

    debugPrint('==========================================');
    debugPrint('SENDING ENQUIRY');
    debugPrint('userId = $userId');
    debugPrint('postId = ${widget.postId}');
    debugPrint('matchedPostId = ${widget.matchedPostId}');
    debugPrint('name = ${nameController.text.trim()}');
    debugPrint('description = ${descriptionController.text.trim()}');
    debugPrint('==========================================');
    final response = await authController.createEnquiry(
      userId: userId ?? 0,
      postId: widget.postId,
      matchedPostId: widget.matchedPostId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
    );

    debugPrint('========== CREATE ENQUIRY RESPONSE ==========');
    debugPrint('success = ${response.isSuccess}');
    debugPrint('message = ${response.message}');
    debugPrint('state = ${response.currentState}');

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response.isSuccess) {
      final check = await authController.viewEnquiry(postId: widget.matchedPostId);
      debugPrint(
        'CHECK enquiries_count = ${check.data?.enquiriesCount}',
      );

      for (final e in check.data?.enquiries ?? []) {
        print('[Enquiry] id=${e.enquiryId} matchedPost=${e.matchedPostId} from=${e.enquirerName}');
      }


    }
    if (response.isSuccess) {
      AppRoutes.pop();
      AppRoutes.pushNamed(AppRoutes.individualChatScreen);
    } else {
      final msg = response.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (response.message.isNotEmpty ? response.message : 'Failed to send enquiry');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(text: 'Send Enquiry',fontSize: 18,fontWeight: FontWeight.w600,color: AppColors.primaryColor,),
            InkWell(child: AppIconWidget(assetPath: AssetImages.crossIcon),onTap: (){AppRoutes.pop();},),
          ],
        ),
        buildTextFieldWithHeading(title: 'Name*', fieldWidget: AppTextField(hintText: '', textController: nameController, readOnly : true,onChange: (v){}, onSubmit: (v){})),
        buildTextFieldWithHeading(title: 'Description*', fieldWidget: AppTextField(hintText: '', textController: descriptionController, readOnly : true, onChange: (v){}, onSubmit: (v){},maxLines: 5,)),

        AppButton(
          title: isSubmitting ? 'Please wait...' : 'Send Enquiry',
          onTap: isSubmitting ? () {} : _onSubmit,
        )

      ],
    );
  }
}


// class SendEnquiry extends StatefulWidget {
//   final String name;
//   final String description;
//   final int postId;         // the enquirer's own (lost) post
//   final int matchedPostId;  // the found post being enquired about
//
//   const SendEnquiry({
//     super.key,
//     this.name = '',
//     this.description = '',
//     required this.postId,
//     required this.matchedPostId,
//   });
//
//   @override
//   State<SendEnquiry> createState() => _SendEnquiryState();
// }
//
// class _SendEnquiryState extends State<SendEnquiry> {
//   final authController = AuthControllers(
//     authRepository: AuthRepository(apiClient: ApiClient()),
//   );
//
//   late final TextEditingController nameController =
//   TextEditingController(text: widget.name);
//   late final TextEditingController descriptionController =
//   TextEditingController(text: widget.description);
//
//   bool isSubmitting = false;
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     descriptionController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onSubmit() async {
//     if (nameController.text.trim().isEmpty) {
//       AppDialogue.showPopup(context: context, content: const AppText(text: 'Name is required'));
//       return;
//     }
//     if (widget.postId == 0 || widget.matchedPostId == 0) {
//       AppDialogue.showPopup(context: context, content: const AppText(text: 'Something went wrong. Please try again.'));
//       return;
//     }
//
//     setState(() => isSubmitting = true);
//
//     final userId = await AppPreferences.getUserId();
//
//     final response = await authController.createEnquiry(
//       userId: userId ?? 0,
//       postId: widget.postId,
//       matchedPostId: widget.matchedPostId,
//       name: nameController.text.trim(),
//       description: descriptionController.text.trim(),
//     );
//
//     if (!mounted) return;
//     setState(() => isSubmitting = false);
//
//     if (response.isSuccess) {
//       // Confirm the enquiry actually landed against this post.
//       final check = await authController.viewEnquiry(postId: widget.postId);
//       debugPrint('[Enquiry] enquiries_count=${check.data?.enquiriesCount}');
//       for (final e in check.data?.enquiries ?? []) {
//         debugPrint('[Enquiry] id=${e.enquiryId} matchedPost=${e.matchedPostId} from=${e.enquirerName}');
//       }
//
//       if (!mounted) return;
//       AppRoutes.pop();
//       AppRoutes.pushNamed(AppRoutes.individualChatScreen);
//     } else {
//       final msg = response.currentState == CurrentState.noInternet
//           ? 'No internet connection. Please check your network.'
//           : (response.message.isNotEmpty ? response.message : 'Failed to send enquiry');
//       AppDialogue.showPopup(context: context, content: AppText(text: msg));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 10,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             AppText(text: 'Send Enquiry',fontSize: 18,fontWeight: FontWeight.w600,color: AppColors.primaryColor,),
//             InkWell(child: AppIconWidget(assetPath: AssetImages.crossIcon),onTap: (){AppRoutes.pop();},),
//           ],
//         ),
//         buildTextFieldWithHeading(title: 'Name*', fieldWidget: AppTextField(hintText: '', textController: nameController, readOnly : true,onChange: (v){}, onSubmit: (v){})),
//         buildTextFieldWithHeading(title: 'Description*', fieldWidget: AppTextField(hintText: '', textController: descriptionController, readOnly : true, onChange: (v){}, onSubmit: (v){},maxLines: 5,)),
//
//         AppButton(
//           title: isSubmitting ? 'Please wait...' : 'Send Enquiry',
//           onTap: isSubmitting ? () {} : _onSubmit,
//         )
//
//       ],
//     );
//   }
// }