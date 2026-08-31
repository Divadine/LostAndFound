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

import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';

import '../post/first_stepper_screen.dart';

class SendEnquiry extends StatefulWidget {
  // ============================================================
  // ENQUIRER'S POST
  // ============================================================

  final String name;
  final String description;
  final int postId;

  // ============================================================
  // MATCHED / FOUND POST
  // ============================================================

  final int matchedPostId;

  // ============================================================
  // OTHER USER
  // ============================================================

  final int otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserPhone;

  // ============================================================
  // ITEM INFORMATION
  // ============================================================

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
  // ============================================================
  // AUTH CONTROLLER
  // ============================================================

  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  bool isSubmitting = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.name,
    );

    descriptionController = TextEditingController(
      text: widget.description,
    );

    debugPrint(
      '[SendEnquiry] INIT',
    );

    debugPrint(
      '[SendEnquiry] otherUserId: ${widget.otherUserId}',
    );

    debugPrint(
      '[SendEnquiry] otherUserName: ${widget.otherUserName}',
    );

    debugPrint(
      '[SendEnquiry] otherUserPhone: "${widget.otherUserPhone}"',
    );

    debugPrint(
      '[SendEnquiry] matchedPostId: ${widget.matchedPostId}',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT ENQUIRY
  //
  // IMPORTANT:
  //
  // This method DOES NOT send contact request.
  //
  // It only:
  //
  // 1. Creates enquiry in API
  // 2. Creates Firestore chat room
  // 3. Saves item information
  // 4. Saves other user's phone
  // 5. Sends initial enquiry message
  // 6. Opens chat
  //
  // Contact request is sent ONLY when user taps
  // "Send Request" inside IndividualChatScreen.
  // ============================================================

  Future<void> _onSubmit() async {
    // ============================================================
    // VALIDATE NAME
    // ============================================================

    if (nameController.text.trim().isEmpty) {
      AppDialogue.showPopup(
        context: context,
        content: const AppText(
          text: 'Name is required',
        ),
      );

      return;
    }

    // ============================================================
    // VALIDATE POST IDS
    // ============================================================

    if (widget.postId == 0 ||
        widget.matchedPostId == 0) {
      AppDialogue.showPopup(
        context: context,
        content: const AppText(
          text:
          'Something went wrong. Please try again.',
        ),
      );

      return;
    }

    // ============================================================
    // PREVENT DOUBLE SUBMIT
    // ============================================================

    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // ============================================================
    // GET CURRENT USER
    // ============================================================

    final userId = AppPreferences.getUserId();

    if (userId == null) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }

      AppDialogue.showPopup(
        context: context,
        content: const AppText(
          text: 'Please log in again.',
        ),
      );

      return;
    }

    final currentUserId = userId.toString().trim();

    final otherUserId =
    widget.otherUserId.toString().trim();

    try {
      // ==========================================================
      // CHECK FOR DUPLICATE ENQUIRY
      // ==========================================================

      final users = [currentUserId, otherUserId]..sort();
      final roomIdCheck = '${users[0]}_${users[1]}_${widget.matchedPostId}';

      debugPrint('[SendEnquiry] Checking for existing room: $roomIdCheck');
      final existingRoom = await ChatService.getRoom(roomIdCheck);

      if (existingRoom != null) {
        if (!mounted) return;
        setState(() => isSubmitting = false);

        AppSnackBar.show(
          context: context,
          message: 'Already sent enquiry',
        );

        // Optionally, close sheet and go to chat directly
        AppRoutes.pop();
        AppRoutes.pushNamed(
          AppRoutes.individualChatScreen,
          arguments: {
            'roomId': roomIdCheck,
            'currentUserId': currentUserId,
            'otherUserId': otherUserId,
            'otherUserName': widget.otherUserName,
            'otherUserAvatar': widget.otherUserAvatar,
            'otherUserPhone': widget.otherUserPhone,
            'itemName': widget.itemName,
            'itemImage': widget.itemImage,
            'itemLocation': widget.itemLocation,
            'itemPostDate': widget.itemPostDate,
            'itemPostId': widget.matchedPostId.toString(),
          },
        );
        return;
      }

      // ==========================================================
      // DEBUG
      // ==========================================================

      debugPrint(
        '==================================================',
      );

      debugPrint(
        '[SendEnquiry] START',
      );

      debugPrint(
        '[SendEnquiry] currentUserId: $currentUserId',
      );

      debugPrint(
        '[SendEnquiry] otherUserId: $otherUserId',
      );

      debugPrint(
        '[SendEnquiry] postId: ${widget.postId}',
      );

      debugPrint(
        '[SendEnquiry] matchedPostId: ${widget.matchedPostId}',
      );

      debugPrint(
        '[SendEnquiry] otherUserPhone: "${widget.otherUserPhone}"',
      );

      // ==========================================================
      // STEP 1
      //
      // CREATE ENQUIRY IN API
      // ==========================================================

      debugPrint(
        '[SendEnquiry] Creating enquiry API...',
      );

      final response =
      await authController.createEnquiry(
        userId: userId,
        postId: widget.postId,
        matchedPostId: widget.matchedPostId,
        name: nameController.text.trim(),
        description:
        descriptionController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      // ==========================================================
      // API FAILURE
      // ==========================================================

      if (!response.isSuccess) {
        setState(() {
          isSubmitting = false;
        });

        final msg =
        response.currentState ==
            CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : response.message.isNotEmpty
            ? response.message
            : 'Failed to send enquiry';

        AppDialogue.showPopup(
          context: context,
          content: AppText(
            text: msg,
          ),
        );

        return;
      }

      debugPrint(
        '[SendEnquiry] Enquiry API SUCCESS',
      );

      // ==========================================================
      // STEP 2
      //
      // CREATE FIRESTORE ROOM
      //
      // IMPORTANT:
      //
      // matchedPostId is used as postId because this is the
      // item that this enquiry is about.
      //
      // Example:
      //
      // current user = 55
      // other user   = 54
      // post          = 127
      //
      // room:
      //
      // 54_55_127
      //
      // ==========================================================

      debugPrint(
        '[Chat] Creating Firestore room...',
      );

      final roomId =
      await ChatService.createChatRoom(
        currentUserId: currentUserId,

        otherUserId: otherUserId,

        // Current/enquiry person's information.
        currentUserName:
        nameController.text.trim(),

        currentUserAvatar: '',

        // If you have current user's phone available,
        // pass it here. Blank is safe.
        currentUserPhone: '',

        // Found/other user's information.
        otherUserName:
        widget.otherUserName,

        otherUserAvatar:
        widget.otherUserAvatar,

        // IMPORTANT:
        // Save found person's phone in Firestore.
        otherUserPhone:
        widget.otherUserPhone,

        // Current user is the enquiry sender.
        enquirySenderId:
        currentUserId,

        // Item information.
        itemName:
        widget.itemName,

        itemImage:
        widget.itemImage,

        itemLocation:
        widget.itemLocation,

        itemPostDate:
        widget.itemPostDate,

        // IMPORTANT:
        // This makes the room unique per post.
        postId:
        widget.matchedPostId.toString(),
      );

      debugPrint(
        '[Chat] Room created/found: $roomId',
      );

      // ==========================================================
      // IMPORTANT
      //
      // DO NOT CALL:
      //
      // ChatService.sendContactRequest()
      //
      // HERE.
      //
      // Contact request must remain "none".
      // ==========================================================

      debugPrint(
        '[Chat] Contact request NOT sent automatically.',
      );

      // ==========================================================
      // STEP 3
      //
      // SEND INITIAL ENQUIRY MESSAGE
      // ==========================================================

      final description =
      descriptionController.text.trim();

      if (description.isNotEmpty) {
        debugPrint(
          '[Chat] Sending initial enquiry message...',
        );

        await ChatService.sendMessage(
          roomId: roomId,
          senderId: currentUserId,
          message: description,
        );

        debugPrint(
          '[Chat] Initial enquiry message sent.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      // ==========================================================
      // STEP 4
      //
      // CLOSE SEND ENQUIRY
      // ==========================================================

      AppRoutes.pop();

      // ==========================================================
      // STEP 5
      //
      // OPEN CHAT
      // ==========================================================

      debugPrint(
        '[Chat] Opening room: $roomId',
      );

      AppRoutes.pushNamed(
        AppRoutes.individualChatScreen,
        arguments: {
          'roomId': roomId,

          'currentUserId':
          currentUserId,

          'otherUserId':
          otherUserId,

          'otherUserName':
          widget.otherUserName,

          'otherUserAvatar':
          widget.otherUserAvatar,

          'otherUserPhone':
          widget.otherUserPhone,

          'itemName':
          widget.itemName,

          'itemImage':
          widget.itemImage,

          'itemLocation':
          widget.itemLocation,

          'itemPostDate':
          widget.itemPostDate,

          'itemPostId':
          widget.matchedPostId.toString(),
        },
      );

      debugPrint(
        '[SendEnquiry] COMPLETE',
      );

      debugPrint(
        '==================================================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SendEnquiry] ERROR: $e',
      );

      debugPrint(
        '[SendEnquiry] STACK TRACE: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      AppDialogue.showPopup(
        context: context,
        content: AppText(
          text: e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========================================================
        // HEADER
        // ========================================================

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              text: 'Send Enquiry',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),

            InkWell(
              onTap: isSubmitting
                  ? null
                  : () {
                AppRoutes.pop();
              },
              child: AppIconWidget(
                assetPath:
                AssetImages.crossIcon,
              ),
            ),
          ],
        ),

        // ========================================================
        // NAME
        // ========================================================

        buildTextFieldWithHeading(
          title: 'Name*',
          fieldWidget: AppTextField(
            hintText: '',
            textController:
            nameController,
            readOnly: true,
            onChange: (v) {},
            onSubmit: (v) {},
          ),
        ),

        // ========================================================
        // DESCRIPTION
        // ========================================================

        buildTextFieldWithHeading(
          title: 'Description*',
          fieldWidget: AppTextField(
            hintText: '',
            textController:
            descriptionController,
            readOnly: true,
            onChange: (v) {},
            onSubmit: (v) {},
            maxLines: 5,
          ),
        ),

        // ========================================================
        // SEND BUTTON
        // ========================================================

        AppButton(
          title: isSubmitting
              ? 'Please wait...'
              : 'Send Enquiry',
          onTap: isSubmitting
              ? () {}
              : _onSubmit,
        ),
      ],
    );
  }
}