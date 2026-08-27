import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';
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

  // who you're messaging
  final int otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserPhone;

  // the item this enquiry/chat is about
  final String itemName;
  final String itemImage;
  final String itemLocation;
  final String itemPostDate;

  const SendEnquiry({
    super.key,
    this.name = '',
    this.description = '',
    required this.postId,
    required this.matchedPostId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar = '',
    this.otherUserPhone = '',
    this.itemName = '',
    this.itemImage = '',
    this.itemLocation = '',
    this.itemPostDate = '',
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

    final userId = AppPreferences.getUserId();
    if (userId == null) {
      setState(() => isSubmitting = false);
      AppDialogue.showPopup(context: context, content: const AppText(text: 'Please log in again.'));
      return;
    }

    final response = await authController.createEnquiry(
      userId: userId,
      postId: widget.postId,
      matchedPostId: widget.matchedPostId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (!response.isSuccess) {
      setState(() => isSubmitting = false);
      final msg = response.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (response.message.isNotEmpty ? response.message : 'Failed to send enquiry');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
      return;
    }

    try {
      // check if room exists for these two ids, create it if not
      final roomId = await ChatService.createChatRoom(
        currentUserId: userId.toString(),
        otherUserId: widget.otherUserId.toString(),
      );

      await ChatService.sendMessage(
        roomId: roomId,
        senderId: userId.toString(),
        message: descriptionController.text.trim(),
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      AppRoutes.pop();
      AppRoutes.pushNamed(
        AppRoutes.individualChatScreen,
        arguments: {
          'roomId': roomId,
          'currentUserId': userId.toString(),
          'otherUserId': widget.otherUserId.toString(),
          'otherUserName': widget.otherUserName,
          'otherUserAvatar': widget.otherUserAvatar,
          'otherUserPhone': widget.otherUserPhone,
          'itemName': widget.itemName,
          'itemImage': widget.itemImage,
          'itemLocation': widget.itemLocation,
          'itemPostDate': widget.itemPostDate,
        },
      );
    } catch (e) {
      debugPrint('[Chat] failed to create room / send message: $e');
      if (!mounted) return;
      setState(() => isSubmitting = false);
      AppDialogue.showPopup(context: context, content: const AppText(text: 'Could not open chat. Please try again.'));
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


