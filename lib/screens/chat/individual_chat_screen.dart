import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';

import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/screens/bottomsheets/chat_sharing_files.dart';

import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';

import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'chat_firebaase_functions.dart';
import 'message_tick.dart';

class IndividualChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserPhone;

  // ============================================================
  // ITEM
  // ============================================================

  final String itemName;
  final String itemImage;
  final String itemLocation;
  final String itemPostDate;

  const IndividualChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar = '',
    this.otherUserPhone = '',
    this.itemName = '',
    this.itemImage = '',
    this.itemLocation = '',
    this.itemPostDate = '',
  });

  // ============================================================
  // FROM ARGS
  // ============================================================

  factory IndividualChatScreen.fromArgs(
      Map<String, dynamic> args,
      ) {
    return IndividualChatScreen(
      roomId: args['roomId']?.toString() ?? '',
      currentUserId: args['currentUserId']?.toString() ?? '',
      otherUserId: args['otherUserId']?.toString() ?? '',
      otherUserName:
      args['otherUserName']?.toString() ??
          'User ${args['otherUserId']}',
      otherUserAvatar:
      args['otherUserAvatar']?.toString() ?? '',
      otherUserPhone:
      args['otherUserPhone']?.toString() ?? '',
      itemName: args['itemName']?.toString() ?? '',
      itemImage: args['itemImage']?.toString() ?? '',
      itemLocation:
      args['itemLocation']?.toString() ?? '',
      itemPostDate:
      args['itemPostDate']?.toString() ?? '',
    );
  }

  @override
  State<IndividualChatScreen> createState() =>
      _IndividualChatScreenState();
}

class _IndividualChatScreenState
    extends State<IndividualChatScreen> {
  final TextEditingController textController =
  TextEditingController();

  String? selectedMessageId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeChat();

    ChatService.markRoomAsRead(
      roomId: widget.roomId,
      userId: widget.currentUserId,
    );
  }

  // ============================================================
  // INITIALIZE CHAT
  // ============================================================

  Future<void> _initializeChat() async {
    try {
      // ========================================================
      // If item information came through navigation,
      // make sure the room has the item information.
      // ========================================================

      if (widget.itemName.trim().isNotEmpty) {
        await ChatService.ensureItemCardMessage(
          roomId: widget.roomId,
          senderId: widget.currentUserId,
          itemName: widget.itemName,
          itemImage: widget.itemImage,
          itemLocation: widget.itemLocation,
          itemPostDate: widget.itemPostDate,
        );

        return;
      }

      // ========================================================
      // Existing room:
      // Try to get item information from the room.
      // ========================================================

      await ChatService.ensureItemCardFromRoom(
        roomId: widget.roomId,
        currentUserId: widget.currentUserId,
      );
    } catch (e) {
      debugPrint('ITEM CARD ERROR: $e');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _send() async {
    final text = textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      await ChatService.sendMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        message: text,
      );

      textController.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _call() async {
    if (widget.otherUserPhone.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: widget.otherUserPhone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================
  // BLOCK
  // ============================================================

  Future<void> _blockChat() async {
    await ChatService.blockChat(
      roomId: widget.roomId,
      userId: widget.currentUserId,
    );
  }

  // ============================================================
  // UNBLOCK
  // ============================================================

  Future<void> _unblockChat() async {
    await ChatService.unblockChat(
      roomId: widget.roomId,
      userId: widget.currentUserId,
    );
  }

  // ============================================================
  // CLEAR CHAT
  // ============================================================

  Future<void> _clearChat() async {
    await ChatService.clearChat(
      roomId: widget.roomId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primaryColor,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              selectedMessageId != null
                  ? _buildSelectionTopRow()
                  : _buildHeaderRow(),

              const SizedBox(height: 10),

              const Divider(),

              // ==================================================
              // PHONE / SEND REQUEST
              // ==================================================

              _buildPhoneRow(),

              const SizedBox(height: 8),

              // ==================================================
              // ITEM CARD
              //
              // IMPORTANT:
              // This is OUTSIDE the Firestore messages ListView.
              // ==================================================

              _buildTopItemCard(),

              const SizedBox(height: 8),

              // ==================================================
              // STAY SAFE CARD
              // ==================================================

              _buildSafetyCard(),

              const SizedBox(height: 5),

              // ==================================================
              // TODAY + MESSAGES
              // ==================================================

              Expanded(
                child: _buildMessagesList(),
              ),
            ],
          ),
        ),
      ),

      // ==========================================================
      // MESSAGE INPUT
      // ==========================================================

      bottomNavigationBar: _buildBottomArea(),
    );
  }

  // ============================================================
  // TOP ITEM CARD
  // ============================================================

  Widget _buildTopItemCard() {
    // ==========================================================
    // FIRST PRIORITY:
    // Item data passed through navigation.
    // ==========================================================

    if (widget.itemName.trim().isNotEmpty) {
      return ItemCard(
        imageWidth: 170,
        isFromEnquiry: true,

        imgUrl: widget.itemImage,

        title: widget.itemName,

        location: widget.itemLocation,

        date: widget.itemPostDate,

        postId: '',

        showPostId: false,

        onTap: () {
          // Keep your existing ItemCard onTap logic here.
        },
      );
    }

    // ==========================================================
    // SECOND PRIORITY:
    // Read item data from chat room.
    //
    // IMPORTANT:
    // This reads from chatRooms/{roomId}.
    // It does NOT read from messages.
    // ==========================================================

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .snapshots(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final roomData =
        snapshot.data?.data();

        if (roomData == null) {
          return const SizedBox.shrink();
        }

        final roomItemName =
            roomData['itemName']?.toString() ?? '';

        if (roomItemName.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final roomItemImage =
            roomData['itemImage']?.toString() ?? '';

        final roomItemLocation =
            roomData['itemLocation']?.toString() ?? '';

        final roomItemPostDate =
            roomData['itemPostDate']?.toString() ?? '';

        return ItemCard(
          imageWidth: 170,
          isFromEnquiry: true,

          imgUrl: roomItemImage,

          title: roomItemName,

          location: roomItemLocation,

          date: roomItemPostDate,

          postId: '',

          showPostId: false,

          onTap: () {
            // Keep your existing ItemCard onTap logic here.
          },
        );
      },
    );
  }

  // ============================================================
  // SAFETY CARD
  // ============================================================

  Widget _buildSafetyCard() {
    return AppContainer(
      bgColor: AppColors.idCardColor,

      widget: Row(
        children: [
          AppIconWidget(
            assetPath: AssetImages.shieldBorder,
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: AppText(
              text:
              'Stay safe! Keep Conversations in the app.\n'
                  'Never Share personal info.',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              maxLine: 2,
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            onTap: () {
              // Do NOT pop the whole chat screen.
              //
              // If you want to hide this card, create a bool
              // such as _showSafetyCard and set it to false.
            },

            child: AppIconWidget(
              assetPath: AssetImages.crossIcon,
            ),
          ),
        ],
      ).padRight(),
    );
  }

  // ============================================================
  // BOTTOM AREA
  // ============================================================

  Widget _buildBottomArea() {
    return StreamBuilder<bool>(
      stream: ChatService.chatBlockedStream(
        roomId: widget.roomId,
      ),

      builder: (context, snapshot) {
        final isBlocked =
            snapshot.data ?? false;

        // ======================================================
        // BLOCKED
        // ======================================================

        if (isBlocked) {
          return SafeArea(
            top: false,

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: _buildBlockedContainer(),
            ),
          );
        }

        // ======================================================
        // NORMAL
        // ======================================================

        return SafeArea(
          top: false,

          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom,
            ),

            child: Row(
              children: [
                // ==================================================
                // ATTACHMENT
                // ==================================================

                buildIconContainer(
                  onTap: () {
                    AppUiHelper.showBottomSheet(
                      context: context,
                      child: ChatSharingFiles(),
                    );
                  },

                  height: 50,
                  width: 50,

                  context,

                  icon: AssetImages.add,

                  bgColor: AppColors.white,

                  iconColor: AppColors.black,

                  borderColor: AppColors.fieldGrey,
                ),

                const SizedBox(width: 8),

                // ==================================================
                // TEXT FIELD
                // ==================================================

                Expanded(
                  child: Container(
                    height: 50,

                    decoration: BoxDecoration(
                      color: AppColors.white,

                      borderRadius:
                      BorderRadius.circular(30),

                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),

                    child: AppTextField(
                      hintText:
                      'Write your message..',

                      textController:
                      textController,

                      onChange: (v) {},

                      onSubmit: (v) => _send(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ==================================================
                // SEND
                // ==================================================

                buildIconContainer(
                  height: 50,
                  width: 50,

                  context,

                  icon: AssetImages.send,

                  bgColor:
                  AppColors.primaryColor,

                  iconColor: AppColors.white,

                  onTap: _send,
                ),
              ],
            ).pad(),
          ),
        );
      },
    );
  }

  // ============================================================
  // BLOCKED CONTAINER
  // ============================================================

  Widget _buildBlockedContainer() {
    return InkWell(
      onTap: _showBlockedPopup,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color:
          AppColors.fieldGrey.withAlpha(40),

          borderRadius:
          BorderRadius.circular(12),

          border: Border.all(
            color: AppColors.fieldGrey,
          ),
        ),

        child: Row(
          children: [
            AppIconWidget(
              assetPath:
              AssetImages.blockChatBorder,
              size: 25,
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: AppText(
                text:
                'This chat has been blocked',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BLOCK POPUP
  // ============================================================

  void _showBlockedPopup() {
    AppUiHelper.showBottomSheet(
      showHandle: false,

      context: context,

      child: BlockChat(
        onUnblock: () async {
          await _unblockChat();
        },

        onDeleteChat: () async {
          await _clearChat();
        },
      ),

      showCloseIcon: false,

      color: AppColors.primaryColor,

      iconColor: AppColors.white,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // ========================================================
        // BACK
        // ========================================================

        GestureDetector(
          onTap: () => AppRoutes.pop(),

          child: AppIconWidget(
            assetPath:
            AssetImages.backArrow,
          ),
        ),

        const SizedBox(width: 20),

        // ========================================================
        // PROFILE IMAGE
        // ========================================================

        Stack(
          children: [
            CircleAvatar(
              radius: 18,

              child: ClipOval(
                child: widget.otherUserAvatar
                    .isNotEmpty
                    ? AppCachedNetworkImage(
                  imageUrl:
                  widget.otherUserAvatar,
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.person,
                  color:
                  AppColors.primaryColor,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              right: -5,

              child: Container(
                padding:
                const EdgeInsets.all(4),

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: AppColors
                      .fieldGrey
                      .withAlpha(70),
                ),

                child: AppIconWidget(
                  assetPath:
                  AssetImages.statusIcon,
                  size: 15,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 15),

        // ========================================================
        // USER NAME
        // ========================================================

        Expanded(
          child: AppText(
            text: widget.otherUserName
                .isNotEmpty
                ? widget.otherUserName
                : 'User ${widget.otherUserId}',

            fontSize: 16,

            fontWeight:
            FontWeight.w500,
          ),
        ),

        // ========================================================
        // MENU
        // ========================================================

        Container(
          height: 30,
          width: 30,

          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.fieldGrey,
            ),

            borderRadius:
            BorderRadius.circular(20),
          ),

          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,

            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20),
            ),

            color: AppColors.white,

            icon: AppIconWidget(
              assetPath: AssetImages.more,
              size: 20,
              color: AppColors.black,
            ),

            offset: const Offset(0, 40),

            onSelected: (value) async {
              switch (value) {
              // ==================================================
              // CLEAR
              // ==================================================

                case 'clear':
                  await _clearChat();
                  break;

              // ==================================================
              // BLOCK
              // ==================================================

                case 'block':
                  await _blockChat();

                  if (!mounted) {
                    return;
                  }

                  _showBlockedPopup();
                  break;

              // ==================================================
              // REPORT
              // ==================================================

                case 'report':
                  AppUiHelper.showBottomSheet(
                    context: context,

                    child:
                    ReportChatReasonSheet(
                      userId: int.parse(
                        widget.currentUserId,
                      ),

                      userName: '',

                      userMobile: '',

                      userEmail: '',

                      roomId: widget.roomId,

                      authControllers:
                      AuthControllers(
                        authRepository:
                        AuthRepository(
                          apiClient:
                          ApiClient(),
                        ),
                      ),
                    ),

                    showCloseIcon: true,

                    color:
                    AppColors.primaryColor,

                    iconColor:
                    AppColors.white,
                  );

                  break;
              }
            },

            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                height: 36,

                child: Text(
                  'Clear Chat',
                ),
              ),

              const PopupMenuItem(
                value: 'block',
                height: 36,

                child: Text(
                  'Block',
                ),
              ),

              const PopupMenuItem(
                value: 'report',
                height: 36,

                child: Text(
                  'Report',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PHONE ROW
  // ============================================================

  Widget _buildPhoneRow() {
    if (widget.otherUserPhone.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppContainer(
      widget: Row(
        children: [
          AppIconWidget(
            assetPath:
            AssetImages.mobileIcon,
          ),

          const SizedBox(width: 8),

          AppText(
            text:
            widget.otherUserPhone,

            fontWeight:
            FontWeight.w400,

            fontSize: 12,
          ),

          const Spacer(),

          GestureDetector(
            onTap: _call,

            child: AppIconWidget(
              assetPath:
              AssetImages.mobileIcon,
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

  // ============================================================
  // MESSAGES LIST
  // ============================================================

  Widget _buildMessagesList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: ChatService.messagesStream(
        widget.roomId,
      ),

      builder: (context, snapshot) {
        // ========================================================
        // LOADING
        // ========================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ========================================================
        // ERROR
        // ========================================================

        if (snapshot.hasError) {
          debugPrint(
            'MESSAGES ERROR: ${snapshot.error}',
          );

          return const Center(
            child: AppText(
              text:
              'Unable to load messages',
              fontSize: 12,
            ),
          );
        }

        // ========================================================
        // NO DATA
        // ========================================================

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // ========================================================
        // DELETE FOR ME FILTER
        // ========================================================

        final docs =
        snapshot.data!.docs.where(
              (doc) {
            final data = doc.data();

            final deletedFor =
            List<String>.from(
              data['deletedFor'] ?? [],
            );

            return !deletedFor.contains(
              widget.currentUserId,
            );
          },
        ).toList();

        // ========================================================
        // TODAY
        // ========================================================

        return Column(
          children: [
            const SizedBox(height: 5),

            const Center(
              child: AppText(
                text: 'Today',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 5),

            // ====================================================
            // MESSAGE LIST ONLY
            // ====================================================

            Expanded(
              child: docs.isEmpty
                  ? const Center(
                child: AppText(
                  text: 'Say hello 👋',
                ),
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 10,
                ),

                itemCount:
                docs.length,

                itemBuilder:
                    (context, index) {
                  final doc =
                  docs[index];

                  final data =
                  doc.data();

                  // ========================================
                  // MESSAGE TYPE
                  // ========================================

                  final messageType =
                      data['messageType']
                          ?.toString() ??
                          'text';

                  // ========================================
                  // IMPORTANT
                  //
                  // Old item-card messages may still
                  // exist in Firestore.
                  //
                  // DO NOT render them here.
                  //
                  // The ItemCard is already rendered
                  // above this StreamBuilder.
                  // ========================================

                  if (messageType ==
                      'item') {
                    return const SizedBox
                        .shrink();
                  }

                  // ========================================
                  // NORMAL TEXT MESSAGE
                  // ========================================

                  return _buildTextMessage(
                    data: data,
                    docId: doc.id,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TEXT MESSAGE
  // ============================================================

  Widget _buildTextMessage({
    required Map<String, dynamic> data,
    required String docId,
  }) {
    final isMe =
        data['senderId']?.toString() ==
            widget.currentUserId;

    final isDeleted =
        data['isDeleted'] == true;

    final isSelected =
        selectedMessageId == docId;

    DateTime? date;

    final timestamp =
    data['createdAt'];

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }

    final time =
    date != null
        ? _formatTime(date)
        : '';

    return GestureDetector(
      // ==========================================================
      // LONG PRESS
      // ==========================================================

      onLongPress: () {
        if (isDeleted) {
          return;
        }

        setState(() {
          selectedMessageId = docId;
        });
      },

      // ==========================================================
      // TAP
      // ==========================================================

      onTap: () {
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
          });
        }
      },

      child: Container(
        width: double.infinity,

        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,

        child: Align(
          alignment: isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,

          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,

            children: [
              // ==================================================
              // MESSAGE BUBBLE
              // ==================================================

              Container(
                margin:
                const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),

                constraints:
                BoxConstraints(
                  maxWidth:
                  MediaQuery.of(context)
                      .size
                      .width *
                      0.6,
                ),

                decoration:
                BoxDecoration(
                  color: isDeleted
                      ? AppColors.fieldGrey
                      : isMe
                      ? AppColors.chatByMe
                      : AppColors.chatByOther,

                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),

                child: AppText(
                  text: isDeleted
                      ? 'This message was deleted'
                      : data['message']
                      ?.toString() ??
                      '',

                  fontSize: 12,

                  fontWeight:
                  FontWeight.w400,
                ),
              ),

              // ==================================================
              // TIME + TICK
              // ==================================================

              Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  if (isMe && !isDeleted)
                    MessageTick(
                      read:
                      data['read'] ==
                          true,

                      delivered:
                      data['delivered'] ==
                          true,
                    ),

                  const SizedBox(width: 3),

                  AppText(
                    text: time,

                    fontSize: 10,

                    fontWeight:
                    FontWeight.w400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTION TOP ROW
  // ============================================================

  Widget _buildSelectionTopRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedMessageId = null;
            });
          },

          child: AppIconWidget(
            assetPath:
            AssetImages.backArrow,
          ),
        ),

        const Spacer(),

        PopupMenuButton<String>(
          offset:
          const Offset(0, 40),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),

          color: AppColors.white,

          icon: AppIconWidget(
            assetPath:
            AssetImages.delete,
            size: 22,
          ),

          onSelected:
              (value) async {
            final id =
                selectedMessageId;

            if (id == null) {
              return;
            }

            try {
              // ==================================================
              // DELETE FOR ME
              // ==================================================

              if (value == 'me') {
                await ChatService
                    .deleteForMe(
                  roomId:
                  widget.roomId,

                  messageId: id,

                  currentUserId:
                  widget.currentUserId,
                );
              }

              // ==================================================
              // DELETE FOR EVERYONE
              // ==================================================

              else if (value ==
                  'everyone') {
                await ChatService
                    .deleteForEveryone(
                  roomId:
                  widget.roomId,

                  messageId: id,

                  currentUserId:
                  widget.currentUserId,
                );
              }

              if (!mounted) {
                return;
              }

              setState(() {
                selectedMessageId = null;
              });
            } catch (e) {
              if (!mounted) {
                return;
              }

              setState(() {
                selectedMessageId = null;
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString()
                        .replaceFirst(
                      'Exception: ',
                      '',
                    ),
                  ),
                ),
              );
            }
          },

          itemBuilder:
              (context) => [
            const PopupMenuItem(
              value: 'me',

              child: AppText(
                text:
                'Delete for me',

                fontSize: 14,

                fontWeight:
                FontWeight.w500,
              ),
            ),

            const PopupMenuItem(
              value: 'everyone',

              child: AppText(
                text:
                'Delete for everyone',

                fontSize: 14,

                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime dt) {
    final h =
    dt.hour % 12 == 0
        ? 12
        : dt.hour % 12;

    final m =
    dt.minute.toString().padLeft(
      2,
      '0',
    );

    final ampm =
    dt.hour >= 12
        ? 'PM'
        : 'AM';

    return '$h:$m $ampm';
  }
}