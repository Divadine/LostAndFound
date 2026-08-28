import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';

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
      roomId:
      args['roomId']?.toString() ?? '',

      currentUserId:
      args['currentUserId']?.toString() ?? '',

      otherUserId:
      args['otherUserId']?.toString() ?? '',

      otherUserName:
      args['otherUserName']?.toString() ??
          'User ${args['otherUserId']}',

      otherUserAvatar:
      args['otherUserAvatar']?.toString() ??
          '',

      otherUserPhone:
      args['otherUserPhone']?.toString() ??
          '',

      itemName:
      args['itemName']?.toString() ?? '',

      itemImage:
      args['itemImage']?.toString() ?? '',

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
  // LOCAL PHONE
  // ============================================================

  String _otherUserPhone = '';

  // ============================================================
  // REQUEST DIALOG
  // ============================================================

  bool _contactDialogShowing = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _otherUserPhone =
        widget.otherUserPhone.trim();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      '[ChatScreen] OPEN',
    );

    debugPrint(
      '[ChatScreen] roomId: ${widget.roomId}',
    );

    debugPrint(
      '[ChatScreen] currentUserId: ${widget.currentUserId}',
    );

    debugPrint(
      '[ChatScreen] otherUserId: ${widget.otherUserId}',
    );

    debugPrint(
      '[ChatScreen] otherUserPhone: ${widget.otherUserPhone}',
    );

    // Load phone directly from Firestore.
    _loadOtherUserPhone();

    _initializeChat();

    ChatService.markRoomAsRead(
      roomId: widget.roomId,
      userId: widget.currentUserId,
    );
  }

  // ============================================================
  // LOAD PHONE
  // ============================================================

  Future<void> _loadOtherUserPhone() async {
    try {
      // ==========================================================
      // FIRST:
      // If navigation already contains phone, save it.
      // ==========================================================

      if (widget.otherUserPhone.trim().isNotEmpty) {
        _otherUserPhone =
            widget.otherUserPhone.trim();

        await ChatService.updateParticipantPhone(
          roomId: widget.roomId,
          userId: widget.otherUserId,
          phone: _otherUserPhone,
        );

        if (mounted) {
          setState(() {});
        }

        debugPrint(
          '[PHONE] Phone received from navigation: '
              '$_otherUserPhone',
        );

        return;
      }

      // ==========================================================
      // SECOND:
      // Load phone from Firestore.
      // ==========================================================

      final phone =
      await ChatService.getParticipantPhone(
        roomId: widget.roomId,
        userId: widget.otherUserId,
      );

      if (phone.isNotEmpty) {
        _otherUserPhone = phone;

        if (mounted) {
          setState(() {});
        }

        debugPrint(
          '[PHONE] Phone loaded from Firestore: '
              '$_otherUserPhone',
        );
      } else {
        debugPrint(
          '[PHONE] Firestore phone is EMPTY '
              'for user ${widget.otherUserId}',
        );
      }
    } catch (e) {
      debugPrint(
        '[PHONE] Failed to load phone: $e',
      );
    }
  }

  // ============================================================
  // INITIALIZE CHAT
  // ============================================================

  Future<void> _initializeChat() async {
    try {
      final navHasAnyItemData =
          widget.itemName.trim().isNotEmpty ||
              widget.itemImage.trim().isNotEmpty ||
              widget.itemLocation.trim().isNotEmpty ||
              widget.itemPostDate.trim().isNotEmpty;

      if (navHasAnyItemData) {
        await ChatService.createChatRoom(
          currentUserId:
          widget.currentUserId,

          otherUserId:
          widget.otherUserId,

          currentUserPhone:
          '',

          otherUserPhone:
          _otherUserPhone,

          otherUserName:
          widget.otherUserName,

          otherUserAvatar:
          widget.otherUserAvatar,

          enquirySenderId:
          widget.currentUserId,

          itemName:
          widget.itemName,

          itemImage:
          widget.itemImage,

          itemLocation:
          widget.itemLocation,

          itemPostDate:
          widget.itemPostDate,

          // IMPORTANT:
          // If your navigation has postId, add it here.
          postId: _extractPostId(),
        );

        return;
      }

      await ChatService.ensureItemCardFromRoom(
        roomId: widget.roomId,
        currentUserId:
        widget.currentUserId,
      );
    } catch (e) {
      debugPrint(
        '[ChatScreen] INITIALIZE ERROR: $e',
      );
    }
  }

  // ============================================================
  // POST ID
  // ============================================================

  String _extractPostId() {
    final parts =
    widget.roomId.split('_');

    if (parts.length >= 3) {
      return parts.last;
    }

    return '';
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
  // SEND
  // ============================================================

  Future<void> _send() async {
    final text =
    textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      await ChatService.sendMessage(
        roomId: widget.roomId,
        senderId:
        widget.currentUserId,
        message: text,
      );

      textController.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
    final phone =
    _otherUserPhone.trim();

    if (phone.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Phone number unavailable'),
        ),
      );

      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================
  // COPY PHONE
  // ============================================================

  Future<void> _copyPhone() async {
    final phone =
    _otherUserPhone.trim();

    if (phone.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: phone,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
        Text('Phone number copied'),
      ),
    );
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
  // CLEAR
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
      backgroundColor:
      AppColors.white,

      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor:
        AppColors.primaryColor,
      ),

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(16),

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
              // PHONE / REQUEST
              // ==================================================

              _buildPhoneRow(),

              const SizedBox(height: 8),

              // ==================================================
              // ITEM CARD
              // ==================================================

              _buildTopItemCard(),

              const SizedBox(height: 8),

              // ==================================================
              // SAFETY
              // ==================================================

              _buildSafetyCard(),

              const SizedBox(height: 5),

              // ==================================================
              // MESSAGES
              // ==================================================

              Expanded(
                child:
                _buildMessagesList(),
              ),
            ],
          ),
        ),
      ),

      // ==========================================================
      // INPUT
      // ==========================================================

      bottomNavigationBar:
      _buildBottomArea(),
    );
  }

  // ============================================================
  // PHONE ROW
  // ============================================================

  Widget _buildPhoneRow() {
    return StreamBuilder<
        Map<String, dynamic>>(
      stream:
      ChatService.contactRequestStream(
        roomId: widget.roomId,
      ),

      builder: (
          context,
          snapshot,
          ) {
        final data =
            snapshot.data ??
                <String, dynamic>{};

        final status =
            data['status']
                ?.toString() ??
                'none';

        final senderId =
            data['senderId']
                ?.toString() ??
                '';

        final receiverId =
            data['receiverId']
                ?.toString() ??
                '';

        final isMyRequest =
            status == 'pending' &&
                senderId ==
                    widget.currentUserId;

        final isRequestForMe =
            status == 'pending' &&
                receiverId ==
                    widget.currentUserId &&
                senderId !=
                    widget.currentUserId;

        debugPrint(
          '[CONTACT UI] '
              'status=$status '
              'sender=$senderId '
              'receiver=$receiverId '
              'current=${widget.currentUserId} '
              'phone=$_otherUserPhone',
        );

        // ========================================================
        // INCOMING REQUEST
        // ========================================================

        if (isRequestForMe &&
            !_contactDialogShowing) {
          WidgetsBinding.instance
              .addPostFrameCallback(
                (_) {
              if (!mounted ||
                  _contactDialogShowing) {
                return;
              }

              _showContactRequestDialog();
            },
          );
        }

        // ========================================================
        // ACCEPTED
        // ========================================================

        if (status == 'accepted') {
          return _buildAcceptedPhoneRow();
        }

        // ========================================================
        // REQUEST SENT
        // ========================================================

        if (isMyRequest) {
          return _buildRequestSentRow();
        }

        // ========================================================
        // SEND REQUEST
        // ========================================================

        return _buildSendRequestRow();
      },
    );
  }

  // ============================================================
  // SEND REQUEST UI
  // ============================================================

  Widget _buildSendRequestRow() {
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
            _otherUserPhone.isNotEmpty
                ? _maskPhone(
              _otherUserPhone,
            )
                : '**********',

            fontWeight:
            FontWeight.w400,

            fontSize: 12,
          ),

          const Spacer(),

          InkWell(
            borderRadius:
            BorderRadius.circular(20),

            onTap:
            _onSendPhoneRequest,

            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),

              decoration:
              BoxDecoration(
                color:
                AppColors.white,

                borderRadius:
                BorderRadius.circular(
                  20,
                ),

                border: Border.all(
                  color:
                  AppColors.primaryColor,
                ),
              ),

              child: AppText(
                text:
                'Send Request',

                fontSize: 11,

                fontWeight:
                FontWeight.w600,

                color:
                AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

  // ============================================================
  // REQUEST SENT UI
  // ============================================================

  Widget _buildRequestSentRow() {
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
            _otherUserPhone.isNotEmpty
                ? _maskPhone(
              _otherUserPhone,
            )
                : '**********',

            fontWeight:
            FontWeight.w400,

            fontSize: 12,
          ),

          const Spacer(),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration:
            BoxDecoration(
              color:
              AppColors.white,

              borderRadius:
              BorderRadius.circular(
                20,
              ),

              border: Border.all(
                color:
                AppColors.requestColor,
              ),
            ),

            child: Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                AppText(
                  text:
                  'Request Sent',

                  fontSize: 11,

                  fontWeight:
                  FontWeight.w600,

                  color:
                  AppColors.requestColor,
                ),

                const SizedBox(
                  width: 5,
                ),

                AppIconWidget(
                  assetPath:
                  AssetImages.requestSent,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

  // ============================================================
  // ACCEPTED PHONE UI
  // ============================================================

  Widget _buildAcceptedPhoneRow() {
    if (_otherUserPhone.isEmpty) {
      return AppContainer(
        widget: Row(
          children: [
            AppIconWidget(
              assetPath:
              AssetImages.mobileIcon,
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: AppText(
                text:
                'Phone number unavailable',
                fontSize: 12,
                fontWeight:
                FontWeight.w400,
              ),
            ),

            InkWell(
              onTap:
              _loadOtherUserPhone,

              child: const AppText(
                text: 'Refresh',
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ).pad(8),
      ).padHorizontal(50);
    }

    return AppContainer(
      widget: Row(
        children: [
          AppIconWidget(
            assetPath:
            AssetImages.mobileIcon,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: AppText(
              text:
              _otherUserPhone,

              fontWeight:
              FontWeight.w400,

              fontSize: 12,
            ),
          ),

          InkWell(
            onTap:
            _copyPhone,

            child: const AppText(
              text: 'Copy',
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(width: 12),

          InkWell(
            onTap: _call,

            child: Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                AppIconWidget(
                  assetPath:
                  AssetImages.mobileIcon,
                  size: 14,
                ),

                const SizedBox(
                  width: 3,
                ),

                const AppText(
                  text: 'Call',
                  fontSize: 11,
                ),
              ],
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

  // ============================================================
  // MASK PHONE
  // ============================================================

  String _maskPhone(
      String phone,
      ) {
    final digits =
    phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.isEmpty) {
      return '**********';
    }

    if (digits.length <= 10) {
      return '+91 **********';
    }

    final countryCode =
        '+${digits.substring(
      0,
      digits.length - 10,
    )}';

    return '$countryCode ${'*' * 10}';
  }

  // ============================================================
  // SEND CONTACT REQUEST
  // ============================================================

  Future<void>
  _onSendPhoneRequest() async {
    try {
      await ChatService.sendContactRequest(
        roomId: widget.roomId,

        senderId:
        widget.currentUserId,

        receiverId:
        widget.otherUserId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Request sent'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(e.toString()),
        ),
      );
    }
  }

  // ============================================================
  // CONTACT REQUEST DIALOG
  // ============================================================

  void _showContactRequestDialog() {
    _contactDialogShowing = true;

    AppUiHelper.showBottomSheet(
      showHandle: false,

      context: context,

      child: Column(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          const AppText(
            text:
            'Contact Request',
            fontSize: 18,
            fontWeight:
            FontWeight.w600,
          ),

          const SizedBox(
            height: 10,
          ),

          const AppText(
            text:
            'This user wants to access your phone number.',
            fontSize: 13,
            maxLine: 3,
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(
                      context,
                    );

                    _contactDialogShowing =
                    false;

                    await ChatService
                        .declineContactRequest(
                      roomId:
                      widget.roomId,
                    );
                  },

                  child: Container(
                    padding:
                    const EdgeInsets.all(
                      12,
                    ),

                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),

                      border:
                      Border.all(
                        color:
                        AppColors.fieldGrey,
                      ),
                    ),

                    child:
                    const Center(
                      child: AppText(
                        text:
                        'Decline',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(
                      context,
                    );

                    _contactDialogShowing =
                    false;

                    await ChatService
                        .acceptContactRequest(
                      roomId:
                      widget.roomId,
                    );

                    await _loadOtherUserPhone();
                  },

                  child: Container(
                    padding:
                    const EdgeInsets.all(
                      12,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      AppColors.primaryColor,

                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),

                    child:
                    const Center(
                      child: AppText(
                        text:
                        'Accept',
                        fontSize: 13,
                        color:
                        AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ).pad(),

      showCloseIcon: false,

      color:
      AppColors.primaryColor,

      iconColor:
      AppColors.white,
    ).whenComplete(() {
      _contactDialogShowing = false;
    });
  }

  // ============================================================
  // TOP ITEM CARD
  // ============================================================

  Widget _buildTopItemCard() {
    final navHasAnyData =
        widget.itemName.trim().isNotEmpty ||
            widget.itemImage.trim().isNotEmpty ||
            widget.itemLocation.trim().isNotEmpty ||
            widget.itemPostDate.trim().isNotEmpty;

    if (navHasAnyData) {
      return ItemCard(
        imageWidth: 170,

        isFromEnquiry: true,

        imgUrl:
        widget.itemImage,

        title:
        widget.itemName.trim().isNotEmpty
            ? widget.itemName
            : 'Item',

        location:
        widget.itemLocation,

        date:
        widget.itemPostDate,

        postId: '',

        showPostId:
        false,

        onTap: () {},
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .snapshots(),

      builder: (
          context,
          snapshot,
          ) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final roomData =
        snapshot.data?.data();

        if (roomData == null) {
          return const SizedBox.shrink();
        }

        final itemName =
            roomData['itemName']
                ?.toString()
                .trim() ??
                '';

        final itemImage =
            roomData['itemImage']
                ?.toString() ??
                '';

        final itemLocation =
            roomData['itemLocation']
                ?.toString() ??
                '';

        final itemPostDate =
            roomData['itemPostDate']
                ?.toString() ??
                '';

        final hasAnyData =
            itemName.isNotEmpty ||
                itemImage.trim().isNotEmpty ||
                itemLocation.trim().isNotEmpty ||
                itemPostDate.trim().isNotEmpty;

        if (!hasAnyData) {
          return const SizedBox.shrink();
        }

        return ItemCard(
          imageWidth: 170,

          isFromEnquiry: true,

          imgUrl:
          itemImage,

          title:
          itemName.isNotEmpty
              ? itemName
              : 'Item',

          location:
          itemLocation,

          date:
          itemPostDate,

          postId: '',

          showPostId:
          false,

          onTap: () {},
        );
      },
    );
  }

  // ============================================================
  // SAFETY CARD
  // ============================================================

  Widget _buildSafetyCard() {
    return AppContainer(
      bgColor:
      AppColors.idCardColor,

      widget: Row(
        children: [
          AppIconWidget(
            assetPath:
            AssetImages.shieldBorder,
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: AppText(
              text:
              'Stay safe! Keep Conversations in the app.\n'
                  'Never Share personal info.',
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
              maxLine: 2,
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            onTap: () {},

            child: AppIconWidget(
              assetPath:
              AssetImages.crossIcon,
            ),
          ),
        ],
      ).padRight(),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessagesList() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
      ChatService.messagesStream(
        widget.roomId,
      ),

      builder: (
          context,
          snapshot,
          ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            '[MESSAGES ERROR] '
                '${snapshot.error}',
          );

          return const Center(
            child: AppText(
              text:
              'Unable to load messages',
              fontSize: 12,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs =
        snapshot.data!.docs
            .where((doc) {
          final data =
          doc.data();

          final deletedFor =
          List<String>.from(
            data['deletedFor'] ?? [],
          );

          return !deletedFor.contains(
            widget.currentUserId,
          );
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: AppText(
              text:
              'Say hello 👋',
            ),
          );
        }

        final entries =
        _buildEntries(docs);

        return ListView.builder(
          padding:
          const EdgeInsets.symmetric(
            vertical: 10,
          ),

          itemCount:
          entries.length,

          itemBuilder:
              (context, index) {
            final entry =
            entries[index];

            if (entry.isHeader) {
              return _buildDateHeader(
                entry.headerLabel!,
              );
            }

            final doc =
            entry.doc!;

            final data =
            doc.data();

            final messageType =
                data['messageType']
                    ?.toString() ??
                    'text';

            // Item card is displayed above.
            if (messageType == 'item') {
              return const SizedBox.shrink();
            }

            return _buildTextMessage(
              data: data,
              docId: doc.id,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DATE ENTRIES
  // ============================================================

  List<_ChatListEntry> _buildEntries(
      List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>
      docs,
      ) {
    final entries =
    <_ChatListEntry>[];

    DateTime? lastDate;

    for (final doc in docs) {
      final data =
      doc.data();

      final timestamp =
      data['createdAt'];

      DateTime? messageDate;

      if (timestamp is Timestamp) {
        messageDate =
            timestamp.toDate();
      }

      if (messageDate != null) {
        final dayOnly =
        DateTime(
          messageDate.year,
          messageDate.month,
          messageDate.day,
        );

        if (lastDate == null ||
            dayOnly != lastDate) {
          entries.add(
            _ChatListEntry.header(
              _dateLabel(dayOnly),
            ),
          );

          lastDate = dayOnly;
        }
      }

      entries.add(
        _ChatListEntry.message(
          doc,
        ),
      );
    }

    return entries;
  }

  // ============================================================
  // DATE LABEL
  // ============================================================

  String _dateLabel(
      DateTime date,
      ) {
    final now =
    DateTime.now();

    final today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday =
    today.subtract(
      const Duration(
        days: 1,
      ),
    );

    if (date == today) {
      return 'Today';
    }

    if (date == yesterday) {
      return 'Yesterday';
    }

    return DateFormat(
      'd MMM yyyy',
    ).format(date);
  }

  // ============================================================
  // DATE HEADER
  // ============================================================

  Widget _buildDateHeader(
      String label,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),

          decoration:
          BoxDecoration(
            color:
            AppColors.fieldGrey
                .withAlpha(60),

            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),

          child: AppText(
            text: label,
            fontSize: 12,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ),
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
        data['senderId']
            ?.toString() ==
            widget.currentUserId;

    final isDeleted =
        data['isDeleted'] == true;

    final isSelected =
        selectedMessageId == docId;

    DateTime? date;

    final timestamp =
    data['createdAt'];

    if (timestamp is Timestamp) {
      date =
          timestamp.toDate();
    }

    final time =
    date != null
        ? _formatTime(date)
        : '';

    return GestureDetector(
      onLongPress: () {
        if (isDeleted) {
          return;
        }

        setState(() {
          selectedMessageId =
              docId;
        });
      },

      onTap: () {
        if (selectedMessageId !=
            null) {
          setState(() {
            selectedMessageId =
            null;
          });
        }
      },

      child: Container(
        width:
        double.infinity,

        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,

        child: Align(
          alignment: isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,

          child: Column(
            crossAxisAlignment:
            isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,

            children: [
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
                  MediaQuery.of(
                    context,
                  ).size.width *
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

              Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  if (isMe &&
                      !isDeleted)
                    MessageTick(
                      read:
                      data['read'] ==
                          true,

                      delivered:
                      data['delivered'] ==
                          true,
                    ),

                  const SizedBox(
                    width: 3,
                  ),

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
  // BOTTOM AREA
  // ============================================================

  Widget _buildBottomArea() {
    return StreamBuilder<bool>(
      stream:
      ChatService.chatBlockedStream(
        roomId:
        widget.roomId,
      ),

      builder: (
          context,
          snapshot,
          ) {
        final isBlocked =
            snapshot.data ??
                false;

        if (isBlocked) {
          return SafeArea(
            top: false,

            child: Padding(
              padding:
              const EdgeInsets.all(
                16,
              ),

              child:
              _buildBlockedContainer(),
            ),
          );
        }

        return SafeArea(
          top: false,

          child: Padding(
            padding:
            EdgeInsets.only(
              bottom:
              MediaQuery.of(
                context,
              ).viewInsets.bottom,
            ),

            child: Row(
              children: [
                buildIconContainer(
                  onTap: () {
                    AppUiHelper
                        .showBottomSheet(
                      context:
                      context,

                      child:
                      ChatSharingFiles(),
                    );
                  },

                  height: 50,

                  width: 50,

                  context,

                  icon:
                  AssetImages.add,

                  bgColor:
                  AppColors.white,

                  iconColor:
                  AppColors.black,

                  borderColor:
                  AppColors.fieldGrey,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Container(
                    height: 50,

                    decoration:
                    BoxDecoration(
                      color:
                      AppColors.white,

                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                          Colors.black12,
                          blurRadius:
                          8,
                          offset:
                          Offset(0, 2),
                        ),
                      ],
                    ),

                    child:
                    AppTextField(
                      hintText:
                      'Write your message..',

                      textController:
                      textController,

                      onChange:
                          (v) {},

                      onSubmit:
                          (v) => _send(),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                buildIconContainer(
                  height: 50,

                  width: 50,

                  context,

                  icon:
                  AssetImages.send,

                  bgColor:
                  AppColors.primaryColor,

                  iconColor:
                  AppColors.white,

                  onTap:
                  _send,
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
      onTap:
      _showBlockedPopup,

      child: Container(
        width:
        double.infinity,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration:
        BoxDecoration(
          color:
          AppColors.fieldGrey
              .withAlpha(40),

          borderRadius:
          BorderRadius.circular(
            12,
          ),

          border:
          Border.all(
            color:
            AppColors.fieldGrey,
          ),
        ),

        child: Row(
          children: [
            AppIconWidget(
              assetPath:
              AssetImages.blockChatBorder,
              size: 25,
            ),

            const SizedBox(
              width: 10,
            ),

            const Expanded(
              child: AppText(
                text:
                'This chat has been blocked',
                fontSize: 13,
                fontWeight:
                FontWeight.w500,
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color:
              AppColors.grey,
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

      color:
      AppColors.primaryColor,

      iconColor:
      AppColors.white,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderRow() {
    return Row(
      children: [
        GestureDetector(
          onTap:
              () => AppRoutes.pop(),

          child: AppIconWidget(
            assetPath:
            AssetImages.backArrow,
          ),
        ),

        const SizedBox(
          width: 20,
        ),

        CircleAvatar(
          radius: 18,

          child: ClipOval(
            child:
            widget.otherUserAvatar.isNotEmpty
                ? AppCachedNetworkImage(
              imageUrl:
              widget.otherUserAvatar,

              height: 36,

              width: 36,

              fit:
              BoxFit.cover,
            )
                : Icon(
              Icons.person,

              color:
              AppColors.primaryColor,
            ),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: AppText(
            text:
            widget.otherUserName
                .isNotEmpty
                ? widget.otherUserName
                : 'User ${widget.otherUserId}',

            fontSize: 16,

            fontWeight:
            FontWeight.w500,
          ),
        ),

        Container(
          height: 30,

          width: 30,

          decoration:
          BoxDecoration(
            border:
            Border.all(
              color:
              AppColors.fieldGrey,
            ),

            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),

          child:
          PopupMenuButton<String>(
            padding:
            EdgeInsets.zero,

            icon:
            AppIconWidget(
              assetPath:
              AssetImages.more,
              size: 20,
              color:
              AppColors.black,
            ),

            offset:
            const Offset(
              0,
              40,
            ),

            onSelected:
                (value) async {
              switch (value) {
                case 'clear':
                  await _clearChat();
                  break;

                case 'block':
                  await _blockChat();

                  if (!mounted) {
                    return;
                  }

                  _showBlockedPopup();
                  break;

                case 'report':
                  AppUiHelper
                      .showBottomSheet(
                    context:
                    context,

                    child:
                    ReportChatReasonSheet(
                      userId:
                      int.parse(
                        widget.currentUserId,
                      ),

                      userName:
                      '',

                      userMobile:
                      '',

                      userEmail:
                      '',

                      roomId:
                      widget.roomId,

                      authControllers:
                      AuthControllers(
                        authRepository:
                        AuthRepository(
                          apiClient:
                          ApiClient(),
                        ),
                      ),
                    ),

                    showCloseIcon:
                    true,

                    color:
                    AppColors.primaryColor,

                    iconColor:
                    AppColors.white,
                  );

                  break;
              }
            },

            itemBuilder:
                (context) => [
              const PopupMenuItem(
                value:
                'clear',

                child:
                Text(
                  'Clear Chat',
                ),
              ),

              const PopupMenuItem(
                value:
                'block',

                child:
                Text(
                  'Block',
                ),
              ),

              const PopupMenuItem(
                value:
                'report',

                child:
                Text(
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
  // SELECTION TOP ROW
  // ============================================================

  Widget _buildSelectionTopRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedMessageId =
              null;
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

          icon:
          AppIconWidget(
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
              if (value ==
                  'me') {
                await ChatService
                    .deleteForMe(
                  roomId:
                  widget.roomId,

                  messageId:
                  id,

                  currentUserId:
                  widget.currentUserId,
                );
              } else if (value ==
                  'everyone') {
                await ChatService
                    .deleteForEveryone(
                  roomId:
                  widget.roomId,

                  messageId:
                  id,

                  currentUserId:
                  widget.currentUserId,
                );
              }

              if (!mounted) {
                return;
              }

              setState(() {
                selectedMessageId =
                null;
              });
            } catch (e) {
              if (!mounted) {
                return;
              }

              setState(() {
                selectedMessageId =
                null;
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content:
                  Text(
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
              value:
              'me',

              child:
              AppText(
                text:
                'Delete for me',

                fontSize:
                14,

                fontWeight:
                FontWeight.w500,
              ),
            ),

            const PopupMenuItem(
              value:
              'everyone',

              child:
              AppText(
                text:
                'Delete for everyone',

                fontSize:
                14,

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

  String _formatTime(
      DateTime dt,
      ) {
    final h =
    dt.hour % 12 == 0
        ? 12
        : dt.hour % 12;

    final m =
    dt.minute
        .toString()
        .padLeft(
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

// ============================================================
// CHAT LIST ENTRY
// ============================================================

class _ChatListEntry {
  final bool isHeader;

  final String? headerLabel;

  final QueryDocumentSnapshot<
      Map<String, dynamic>>? doc;

  _ChatListEntry.header(
      this.headerLabel,
      )   : isHeader = true,
        doc = null;

  _ChatListEntry.message(
      this.doc,
      )   : isHeader = false,
        headerLabel = null;
}