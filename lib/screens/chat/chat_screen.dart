import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';

import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';

import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'message_tick.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();

    currentUserId =
        AppPreferences.getUserId()
            ?.toString()
            .trim();

    debugPrint(
      '[ChatScreen] Current user ID: $currentUserId',
    );

    if (currentUserId == null || currentUserId!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackBar.show(
          context: context,
          message: 'User not found',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,

      child: Scaffold(
        backgroundColor:
        AppColors.white,

        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor:
          AppColors.primaryColor,
        ),

        body: SafeArea(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 15),

              AppText(
                text:
                'Enquires & Messages',

                fontWeight:
                FontWeight.w500,

                fontSize: 18,
              ).pad(),

              const SizedBox(height: 15),

              _buildTabBar(),

              const SizedBox(height: 10),

              Expanded(
                child: (currentUserId == null || currentUserId!.isEmpty)
                    ? Center(
                        child: AppText(
                          text: 'Please login to see chats',
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      )
                    : StreamBuilder<
                        QuerySnapshot<
                            Map<String, dynamic>>>(
                  stream:
                  ChatService.chatRoomsStream(
                    currentUserId!,
                  ),

                  builder:
                      (context, snapshot) {
                    if (snapshot
                        .connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        '[ChatScreen] Firestore ERROR:',
                      );

                      debugPrint(
                        snapshot.error.toString(),
                      );

                      return Center(
                        child: Padding(
                          padding:
                          const EdgeInsets.all(
                            20,
                          ),

                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,

                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 40,
                                color:
                                AppColors.grey,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              const AppText(
                                text:
                                'Unable to load chats',
                                fontSize: 14,
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              AppText(
                                text:
                                snapshot.error
                                    .toString(),

                                fontSize: 11,

                                color:
                                AppColors.grey,

                                maxLine: 5,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final documents =
                        snapshot.data?.docs ??
                            [];

                    final receivedLeads =
                    <ChatRoomData>[];

                    final sentEnquiries =
                    <ChatRoomData>[];

                    for (final doc
                    in documents) {
                      try {
                        final room =
                        ChatRoomData
                            .fromFirestore(
                          doc,
                          currentUserId!,
                        );

                        if (room
                            .isReceivedEnquiry) {
                          receivedLeads
                              .add(room);
                        }

                        if (room
                            .isSentEnquiry) {
                          sentEnquiries
                              .add(room);
                        }
                      } catch (e) {
                        debugPrint(
                          '[ChatScreen] Error parsing room '
                              '${doc.id}: $e',
                        );
                      }
                    }

                    receivedLeads.sort(
                      _sortByLatest,
                    );

                    sentEnquiries.sort(
                      _sortByLatest,
                    );

                    return TabBarView(
                      children: [
                        _buildChatList(
                          receivedLeads,
                          emptyMessage:
                          'No leads yet',
                        ),

                        _buildChatList(
                          sentEnquiries,
                          emptyMessage:
                          'No enquiries sent',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  int _sortByLatest(
      ChatRoomData a,
      ChatRoomData b,
      ) {
    final aTime =
        a.lastMessageTime ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    final bTime =
        b.lastMessageTime ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    return bTime.compareTo(aTime);
  }

  // ============================================================
  // TAB BAR
  // ============================================================

  Widget _buildTabBar() {
    return Container(
      height: 55,

      margin:
      const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      padding:
      const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color:
        AppColors.fieldGrey
            .withAlpha(1),

        borderRadius:
        BorderRadius.circular(8),

        border: Border.all(
          color:
          AppColors.fieldGrey,
        ),
      ),

      child: TabBar(
        indicatorSize:
        TabBarIndicatorSize.tab,

        indicator: BoxDecoration(
          color:
          AppColors.primaryColor,

          borderRadius:
          BorderRadius.circular(5),
        ),

        dividerColor:
        Colors.transparent,

        labelColor:
        AppColors.white,

        unselectedLabelColor:
        AppColors.grey,

        labelStyle:
        const TextStyle(
          fontSize: 14,
          fontWeight:
          FontWeight.w500,
        ),

        tabs: const [
          Tab(
            text: 'My Leads',
          ),

          Tab(
            text: 'Enquiry',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHAT LIST
  // ============================================================

  Widget _buildChatList(
      List<ChatRoomData> chats, {
        required String emptyMessage,
      }) {
    if (chats.isEmpty) {
      return Center(
        child: AppText(
          text: emptyMessage,
          color: AppColors.grey,
          fontSize: 14,
        ),
      );
    }

    return ListView(
      padding:
      const EdgeInsets.only(
        bottom: 20,
      ),

      children: [
        for (final chat in chats)
          _buildChatRoomTile(chat),
      ],
    );
  }

  // ============================================================
  // CHAT ROOM TILE
  // ============================================================

  Widget _buildChatRoomTile(
      ChatRoomData chat,
      ) {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
      ChatService.messagesStream(
        chat.roomId,
      ),

      builder:
          (context, snapshot) {
        DateTime? visibleLatestTime;

        String visibleLastMessage =
            chat.lastMessage;

        String visibleLastSenderId =
            chat.lastMessageSenderId;

        bool visibleLastMessageRead =
            chat.lastMessageRead;

        bool visibleLastMessageDelivered =
            chat.lastMessageDelivered;

        bool visibleLastMessageDeleted =
            chat.lastMessageDeleted;

        if (snapshot.hasData) {
          final docs =
              snapshot.data!.docs;

          // ======================================================
          // FILTER DELETE FOR ME
          // ======================================================

          final visibleMessages =
          docs.where((doc) {
            final data =
            doc.data();

            final deletedFor =
            List<String>.from(
              data['deletedFor'] ?? [],
            );

            return !deletedFor.contains(
              currentUserId!,
            );
          }).toList();

          if (visibleMessages
              .isNotEmpty) {
            final lastDoc =
                visibleMessages.last;

            final data =
            lastDoc.data();

            final isDeleted =
                data['isDeleted'] ==
                    true;

            final timestamp =
            data['createdAt'];

            if (timestamp
            is Timestamp) {
              visibleLatestTime =
                  timestamp.toDate();
            }

            visibleLastSenderId =
                data['senderId']
                    ?.toString() ??
                    '';

            visibleLastMessageRead =
                data['read'] == true;

            visibleLastMessageDelivered =
                data['delivered'] == true;

            visibleLastMessageDeleted =
                isDeleted;

            if (isDeleted) {
              visibleLastMessage =
              'This message was deleted';
            } else {
              final messageType =
                  data['messageType']
                      ?.toString() ??
                      'text';

              if (messageType ==
                  'image') {
                visibleLastMessage =
                '📷 Photo';
              } else if (messageType ==
                  'location') {
                visibleLastMessage =
                '📍 Location';
              } else if (messageType ==
                  'item') {
                visibleLastMessage =
                'Item shared';
              } else {
                visibleLastMessage =
                    data['message']
                        ?.toString() ??
                        '';
              }
            }
          } else {
            visibleLastMessage = '';

            visibleLatestTime = null;

            visibleLastSenderId = '';

            visibleLastMessageRead =
            false;

            visibleLastMessageDelivered =
            false;

            visibleLastMessageDeleted =
            false;
          }
        }

        final section =
        _getDateSection(
          visibleLatestTime ??
              chat.lastMessageTime,
        );

        return Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            _buildDateHeader(
              section,
            ),

            ChatTile(
              imageUrl:
              chat.otherUserAvatar,

              name:
              chat.otherUserName,

              lastMessage:
              visibleLastMessage.isEmpty
                  ? 'No messages yet'
                  : visibleLastMessage,

              time:
              _formatChatTime(
                visibleLatestTime ??
                    chat.lastMessageTime,
              ),

              unreadCount:
              chat.unreadCount,

              lastMessageIsMine:
              visibleLastSenderId ==
                  currentUserId,

              lastMessageRead:
              visibleLastMessageRead,

              lastMessageDelivered:
              visibleLastMessageDelivered,

              lastMessageDeleted:
              visibleLastMessageDeleted,

              onTap: () {
                _openExistingChat(
                  chat,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE HEADER
  // ============================================================

  Widget _buildDateHeader(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),

      child: AppText(
        text: title,
        fontSize: 13,
        fontWeight:
        FontWeight.w600,
        color: AppColors.grey,
      ),
    );
  }

  // ============================================================
  // DATE SECTION
  // ============================================================

  String _getDateSection(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Older';
    }

    final now =
    DateTime.now();

    final today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final messageDate =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today
            .difference(
          messageDate,
        )
            .inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatChatTime(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    final hour =
    date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    final period =
    date.hour >= 12
        ? 'PM'
        : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openExistingChat(
      ChatRoomData chat,
      ) {
    ChatService.markRoomAsRead(
      roomId: chat.roomId,
      userId: currentUserId!,
    );

    AppRoutes.pushNamed(
      AppRoutes.individualChatScreen,

      arguments: {
        'roomId':
        chat.roomId,

        'currentUserId':
        currentUserId,

        'otherUserId':
        chat.otherUserId,

        'otherUserName':
        chat.otherUserName,

        'otherUserAvatar':
        chat.otherUserAvatar,

        'otherUserPhone':
        chat.otherUserPhone,

        'itemName':
        chat.itemName,

        'itemImage':
        chat.itemImage,

        'itemLocation':
        chat.itemLocation,

        'itemPostDate':
        chat.itemPostDate,

        'enquirySenderId':
        chat.enquirySenderId ?? '',
      },
    );
  }
}

// ===================================================================
// CHAT ROOM MODEL
// ===================================================================

class ChatRoomData {
  final String roomId;

  final String currentUserId;
  final String otherUserId;

  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserPhone;

  final String lastMessage;
  final DateTime? lastMessageTime;

  final String? enquirySenderId;

  final int unreadCount;

  final String lastMessageSenderId;

  final bool lastMessageRead;
  final bool lastMessageDelivered;

  final bool lastMessageDeleted;

  final String itemName;
  final String itemImage;
  final String itemLocation;
  final String itemPostDate;

  final List<String> users;

  ChatRoomData({
    required this.roomId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.otherUserPhone,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.enquirySenderId,
    required this.unreadCount,
    required this.lastMessageSenderId,
    required this.lastMessageRead,
    required this.lastMessageDelivered,
    required this.lastMessageDeleted,
    required this.itemName,
    required this.itemImage,
    required this.itemLocation,
    required this.itemPostDate,
    required this.users,
  });

  factory ChatRoomData.fromFirestore(
      DocumentSnapshot<
          Map<String, dynamic>> doc,
      String currentUserId,
      ) {
    final data =
        doc.data() ??
            <String, dynamic>{};

    // ============================================================
    // USERS
    // ============================================================

    final users =
    List<String>.from(
      data['users'] ?? [],
    );

    String otherUserId = '';

    for (final userId in users) {
      if (userId != currentUserId) {
        otherUserId =
            userId.toString();
        break;
      }
    }

    // ============================================================
    // PARTICIPANTS
    // ============================================================

    final participants =
    Map<String, dynamic>.from(
      data['participants'] ?? {},
    );

    final rawOtherParticipant =
    participants[otherUserId];

    final otherParticipant =
    rawOtherParticipant is Map
        ? Map<String, dynamic>.from(
      rawOtherParticipant,
    )
        : <String, dynamic>{};

    // ============================================================
    // ⭐ ACTUAL USER NAME
    // ============================================================

    final firestoreName =
        otherParticipant['name']
            ?.toString()
            .trim() ??
            '';

    final otherUserName =
    firestoreName.isNotEmpty
        ? firestoreName
        : otherUserId.isNotEmpty
        ? 'User $otherUserId'
        : 'Unknown User';

    // ============================================================
    // AVATAR
    // ============================================================

    final otherUserAvatar =
        otherParticipant['avatar']
            ?.toString()
            .trim() ??
            '';

    // ============================================================
    // PHONE
    // ============================================================

    final otherUserPhone =
        otherParticipant['phone']
            ?.toString()
            .trim() ??
            '';

    // ============================================================
    // LAST MESSAGE TIME
    // ============================================================

    DateTime? lastMessageTime;

    final timestamp =
    data['lastMessageTime'];

    if (timestamp is Timestamp) {
      lastMessageTime =
          timestamp.toDate();
    }

    // ============================================================
    // ENQUIRY
    // ============================================================

    final enquirySenderId =
    data['enquirySenderId']
        ?.toString()
        .trim();

    // ============================================================
    // UNREAD
    // ============================================================

    final unreadCounts =
    Map<String, dynamic>.from(
      data['unreadCounts'] ?? {},
    );

    final unreadCount =
        int.tryParse(
          unreadCounts[currentUserId]
              ?.toString() ??
              '0',
        ) ??
            0;

    // ============================================================
    // LAST MESSAGE
    // ============================================================

    final lastMessageSenderId =
        data['lastMessageSenderId']
            ?.toString() ??
            '';

    final lastMessageRead =
        data['lastMessageRead'] ==
            true;

    final lastMessageDelivered =
        data['lastMessageDelivered'] ==
            true;

    final lastMessageDeleted =
        data['lastMessageDeleted'] ==
            true;

    // ============================================================
    // ITEM
    // ============================================================

    final itemName =
        data['itemName']
            ?.toString() ??
            '';

    final itemImage =
        data['itemImage']
            ?.toString() ??
            '';

    final itemLocation =
        data['itemLocation']
            ?.toString() ??
            '';

    final itemPostDate =
        data['itemPostDate']
            ?.toString() ??
            '';

    // ============================================================
    // DEBUG
    // ============================================================

    debugPrint(
      '[ChatRoomData] '
          'room=${doc.id} '
          'otherUserId=$otherUserId '
          'otherUserName=$otherUserName '
          'phone=$otherUserPhone',
    );

    // ============================================================
    // RETURN
    // ============================================================

    return ChatRoomData(
      roomId:
      data['roomId']
          ?.toString() ??
          doc.id,

      currentUserId:
      currentUserId,

      otherUserId:
      otherUserId,

      otherUserName:
      otherUserName,

      otherUserAvatar:
      otherUserAvatar,

      otherUserPhone:
      otherUserPhone,

      lastMessage:
      data['lastMessage']
          ?.toString() ??
          '',

      lastMessageTime:
      lastMessageTime,

      enquirySenderId:
      enquirySenderId,

      unreadCount:
      unreadCount,

      lastMessageSenderId:
      lastMessageSenderId,

      lastMessageRead:
      lastMessageRead,

      lastMessageDelivered:
      lastMessageDelivered,

      lastMessageDeleted:
      lastMessageDeleted,

      itemName:
      itemName,

      itemImage:
      itemImage,

      itemLocation:
      itemLocation,

      itemPostDate:
      itemPostDate,

      users:
      users,
    );
  }

  // ============================================================
  // RECEIVED ENQUIRY
  // ============================================================

  bool get isReceivedEnquiry {
    if (enquirySenderId == null ||
        enquirySenderId!.isEmpty) {
      return false;
    }

    return enquirySenderId !=
        currentUserId;
  }

  // ============================================================
  // SENT ENQUIRY
  // ============================================================

  bool get isSentEnquiry {
    if (enquirySenderId == null ||
        enquirySenderId!.isEmpty) {
      return false;
    }

    return enquirySenderId ==
        currentUserId;
  }
}

// ===================================================================
// CHAT TILE
// ===================================================================

Widget ChatTile({
  required String imageUrl,
  required String name,
  required String lastMessage,
  required String time,

  int unreadCount = 0,

  bool lastMessageIsMine = false,

  bool lastMessageRead = false,

  bool lastMessageDelivered = false,

  bool lastMessageDeleted = false,

  VoidCallback? onTap,
}) {
  final displayMessage =
  lastMessageDeleted
      ? 'This message was deleted'
      : lastMessage.isEmpty
      ? 'No messages yet'
      : lastMessage;

  return InkWell(
    onTap: onTap,

    child: Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,

      children: [
        // ==========================================================
        // PROFILE
        // ==========================================================

        Stack(
          clipBehavior:
          Clip.none,

          children: [
            CircleAvatar(
              radius: 28,

              backgroundColor:
              AppColors.fieldGrey,

              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? AppCachedNetworkImage(
                  imageUrl:
                  imageUrl,

                  height: 56,

                  width: 56,

                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.person,

                  size: 30,

                  color:
                  AppColors.grey,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              right: -4,

              child: Container(
                padding:
                const EdgeInsets.all(4),

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  color: AppColors
                      .fieldGrey
                      .withAlpha(70),
                ),

                child: AppIconWidget(
                  assetPath:
                  AssetImages.statusIcon,

                  size: 20,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          width: 12,
        ),

        // ==========================================================
        // NAME + MESSAGE
        // ==========================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              AppText(
                text: name.isEmpty
                    ? 'Unknown User'
                    : name,

                fontSize: 16,

                fontWeight:
                FontWeight.w500,
              ),

              const SizedBox(
                height: 4,
              ),

              Row(
                children: [
                  if (lastMessageIsMine &&
                      !lastMessageDeleted)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        right: 4,
                      ),

                      child: MessageTick(
                        read:
                        lastMessageRead,

                        delivered:
                        lastMessageDelivered,
                      ),
                    ),

                  Expanded(
                    child: AppText(
                      text:
                      displayMessage,

                      fontSize: 12,

                      color:
                      AppColors.grey,

                      fontWeight:
                      FontWeight.w400,

                      maxLine: 1,

                      textOverflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        // ==========================================================
        // TIME + UNREAD
        // ==========================================================

        Column(
          mainAxisSize:
          MainAxisSize.min,

          crossAxisAlignment:
          CrossAxisAlignment.end,

          children: [
            AppText(
              text: time,

              fontSize: 10,

              color:
              AppColors.grey,

              fontWeight:
              FontWeight.w400,
            ),

            const SizedBox(
              height: 8,
            ),

            if (unreadCount > 0)
              Container(
                height: 20,

                width: 20,

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  color:
                  AppColors.lightBlue_2,
                ),

                alignment:
                Alignment.center,

                child: AppText(
                  text:
                  unreadCount > 99
                      ? '99+'
                      : unreadCount
                      .toString(),

                  fontWeight:
                  FontWeight.w600,

                  fontSize: 10,

                  color:
                  AppColors.primaryColor,
                ),
              )
            else
              const SizedBox(
                height: 20,
              ),
          ],
        ),
      ],
    ).pad(),
  );
}