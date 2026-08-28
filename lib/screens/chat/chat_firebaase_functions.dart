import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  // ============================================================
  // CREATE / GET CHAT ROOM
  // ============================================================
  //
  // Room:
  //
  // user 56 + user 57 + post 144
  //
  // => 56_57_144
  //
  // Phone numbers are stored inside:
  //
  // participants
  //   56
  //     phone
  //   57
  //     phone
  //
  // IMPORTANT:
  // Existing participant phone numbers are NEVER overwritten
  // with an empty string.
  // ============================================================

  static Future<String> createChatRoom({
    required String currentUserId,
    required String otherUserId,

    String currentUserName = '',
    String currentUserAvatar = '',
    String currentUserPhone = '',

    String otherUserName = '',
    String otherUserAvatar = '',
    String otherUserPhone = '',

    String? enquirySenderId,

    String itemName = '',
    String itemImage = '',
    String itemLocation = '',
    String itemPostDate = '',

    String postId = '',
  }) async {
    final users = [
      currentUserId.trim(),
      otherUserId.trim(),
    ]..sort();

    final trimmedPostId = postId.trim();

    final roomId = trimmedPostId.isNotEmpty
        ? '${users[0]}_${users[1]}_$trimmedPostId'
        : '${users[0]}_${users[1]}';

    final roomRef = _rooms.doc(roomId);

    final snapshot = await roomRef.get();

    // ============================================================
    // CREATE PARTICIPANT DATA
    // ============================================================

    final newParticipants = <String, dynamic>{
      currentUserId: {
        'name': currentUserName.trim(),
        'avatar': currentUserAvatar.trim(),
        'phone': currentUserPhone.trim(),
      },
      otherUserId: {
        'name': otherUserName.trim(),
        'avatar': otherUserAvatar.trim(),
        'phone': otherUserPhone.trim(),
      },
    };

    // ============================================================
    // CREATE NEW ROOM
    // ============================================================

    if (!snapshot.exists) {
      await roomRef.set({
        'roomId': roomId,

        'users': users,

        'participants': newParticipants,

        'enquirySenderId':
        enquirySenderId?.trim() ?? '',

        'createdAt':
        FieldValue.serverTimestamp(),

        'lastMessage': '',

        'lastMessageTime':
        FieldValue.serverTimestamp(),

        'lastMessageSenderId': '',

        'lastMessageRead': false,

        'lastMessageDelivered': false,

        'lastMessageDeleted': false,

        'lastMessageId': '',

        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },

        'blockedBy': <String>[],

        // ========================================================
        // CONTACT REQUEST
        // ========================================================

        'contactRequestStatus': 'none',
        'contactRequestSenderId': '',
        'contactRequestReceiverId': '',
        'contactRequestCreatedAt': null,
        'contactRequestUpdatedAt': null,

        // ========================================================
        // ITEM
        // ========================================================

        'itemName': itemName.trim(),
        'itemImage': itemImage.trim(),
        'itemLocation': itemLocation.trim(),
        'itemPostDate': itemPostDate.trim(),

        'postId': trimmedPostId,
      });

      print(
        '[ChatService] CHAT ROOM CREATED: $roomId',
      );
    }

    // ============================================================
    // EXISTING ROOM
    // ============================================================

    else {
      final roomData =
          snapshot.data() ?? <String, dynamic>{};

      // ----------------------------------------------------------
      // IMPORTANT:
      // Read existing participants first.
      // Do NOT replace them blindly.
      // ----------------------------------------------------------

      final existingParticipants =
      Map<String, dynamic>.from(
        roomData['participants'] ?? {},
      );

      // ==========================================================
      // CURRENT USER PARTICIPANT
      // ==========================================================

      final currentParticipant =
      Map<String, dynamic>.from(
        existingParticipants[currentUserId] ?? {},
      );

      if (currentUserName.trim().isNotEmpty) {
        currentParticipant['name'] =
            currentUserName.trim();
      }

      if (currentUserAvatar.trim().isNotEmpty) {
        currentParticipant['avatar'] =
            currentUserAvatar.trim();
      }

      // NEVER overwrite existing phone with empty value.
      if (currentUserPhone.trim().isNotEmpty) {
        currentParticipant['phone'] =
            currentUserPhone.trim();
      }

      currentParticipant['phone'] ??= '';

      existingParticipants[currentUserId] =
          currentParticipant;

      // ==========================================================
      // OTHER USER PARTICIPANT
      // ==========================================================

      final otherParticipant =
      Map<String, dynamic>.from(
        existingParticipants[otherUserId] ?? {},
      );

      if (otherUserName.trim().isNotEmpty) {
        otherParticipant['name'] =
            otherUserName.trim();
      }

      if (otherUserAvatar.trim().isNotEmpty) {
        otherParticipant['avatar'] =
            otherUserAvatar.trim();
      }

      // NEVER overwrite existing phone with empty value.
      if (otherUserPhone.trim().isNotEmpty) {
        otherParticipant['phone'] =
            otherUserPhone.trim();
      }

      otherParticipant['phone'] ??= '';

      existingParticipants[otherUserId] =
          otherParticipant;

      final updateData =
      <String, dynamic>{
        'users': users,

        'participants':
        existingParticipants,
      };

      // ==========================================================
      // ENQUIRY SENDER
      // ==========================================================

      if (enquirySenderId != null &&
          enquirySenderId.trim().isNotEmpty) {
        updateData['enquirySenderId'] =
            enquirySenderId.trim();
      }

      // ==========================================================
      // ITEM DATA
      // ==========================================================

      if (itemName.trim().isNotEmpty) {
        updateData['itemName'] =
            itemName.trim();
      }

      if (itemImage.trim().isNotEmpty) {
        updateData['itemImage'] =
            itemImage.trim();
      }

      if (itemLocation.trim().isNotEmpty) {
        updateData['itemLocation'] =
            itemLocation.trim();
      }

      if (itemPostDate.trim().isNotEmpty) {
        updateData['itemPostDate'] =
            itemPostDate.trim();
      }

      if (trimmedPostId.isNotEmpty) {
        updateData['postId'] =
            trimmedPostId;
      }

      await roomRef.set(
        updateData,
        SetOptions(merge: true),
      );

      print(
        '[ChatService] CHAT ROOM UPDATED: $roomId',
      );
    }

    // ============================================================
    // ITEM CARD
    // ============================================================

    final hasAnyItemData =
        itemName.trim().isNotEmpty ||
            itemImage.trim().isNotEmpty ||
            itemLocation.trim().isNotEmpty ||
            itemPostDate.trim().isNotEmpty;

    if (hasAnyItemData) {
      await ensureItemCardMessage(
        roomId: roomId,

        senderId:
        enquirySenderId?.trim().isNotEmpty == true
            ? enquirySenderId!.trim()
            : currentUserId,

        itemName: itemName,
        itemImage: itemImage,
        itemLocation: itemLocation,
        itemPostDate: itemPostDate,
      );
    }

    return roomId;
  }

  // ============================================================
  // GET ROOM
  // ============================================================

  static Future<Map<String, dynamic>?> getRoom(
      String roomId,
      ) async {
    if (roomId.trim().isEmpty) {
      return null;
    }

    final snapshot =
    await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // ============================================================
  // GET PARTICIPANT
  // ============================================================

  static Future<Map<String, dynamic>?>
  getParticipant({
    required String roomId,
    required String userId,
  }) async {
    if (roomId.trim().isEmpty ||
        userId.trim().isEmpty) {
      return null;
    }

    final snapshot =
    await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data() ??
            <String, dynamic>{};

    final participants =
    Map<String, dynamic>.from(
      data['participants'] ?? {},
    );

    final participant =
    participants[userId];

    if (participant == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      participant,
    );
  }

  // ============================================================
  // GET PARTICIPANT PHONE
  // ============================================================

  static Future<String> getParticipantPhone({
    required String roomId,
    required String userId,
  }) async {
    final participant =
    await getParticipant(
      roomId: roomId,
      userId: userId,
    );

    if (participant == null) {
      return '';
    }

    return participant['phone']
        ?.toString()
        .trim() ??
        '';
  }

  // ============================================================
  // UPDATE PARTICIPANT PHONE
  // ============================================================
  //
  // This updates only:
  //
  // participants/{userId}/phone
  //
  // It does NOT destroy name/avatar.
  // ============================================================

  static Future<void> updateParticipantPhone({
    required String roomId,
    required String userId,
    required String phone,
  }) async {
    final cleanPhone = phone.trim();

    if (roomId.trim().isEmpty ||
        userId.trim().isEmpty ||
        cleanPhone.isEmpty) {
      return;
    }

    await _rooms.doc(roomId).set(
      {
        'participants': {
          userId: {
            'phone': cleanPhone,
          },
        },
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] PHONE UPDATED '
          'room=$roomId user=$userId',
    );
  }

  // ============================================================
  // ENSURE ITEM CARD MESSAGE
  // ============================================================

  static Future<void> ensureItemCardMessage({
    required String roomId,
    required String senderId,
    required String itemName,
    required String itemImage,
    required String itemLocation,
    required String itemPostDate,
  }) async {
    if (roomId.trim().isEmpty) {
      return;
    }

    final hasAnyItemData =
        itemName.trim().isNotEmpty ||
            itemImage.trim().isNotEmpty ||
            itemLocation.trim().isNotEmpty ||
            itemPostDate.trim().isNotEmpty;

    if (!hasAnyItemData) {
      return;
    }

    final itemCardRef = _rooms
        .doc(roomId)
        .collection('messages')
        .doc('itemCard');

    await itemCardRef.set(
      {
        'messageType': 'item',

        'senderId': senderId,

        'message': '',

        'itemName':
        itemName.trim(),

        'itemImage':
        itemImage.trim(),

        'itemLocation':
        itemLocation.trim(),

        'itemPostDate':
        itemPostDate.trim(),

        'createdAt':
        FieldValue.serverTimestamp(),

        'isDeleted': false,

        'deletedFor': <String>[],

        'delivered': true,

        'read': true,

        'readBy': <String>[],
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] ITEM CARD CREATED/UPDATED: $roomId',
    );
  }

  // ============================================================
  // ENSURE ITEM CARD FROM EXISTING ROOM
  // ============================================================

  static Future<void> ensureItemCardFromRoom({
    required String roomId,
    required String currentUserId,
  }) async {
    if (roomId.trim().isEmpty) {
      return;
    }

    final snapshot =
    await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return;
    }

    final roomData =
        snapshot.data() ??
            <String, dynamic>{};

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

    final hasAnyItemData =
        itemName.isNotEmpty ||
            itemImage.trim().isNotEmpty ||
            itemLocation.trim().isNotEmpty ||
            itemPostDate.trim().isNotEmpty;

    if (!hasAnyItemData) {
      return;
    }

    final enquirySenderId =
        roomData['enquirySenderId']
            ?.toString() ??
            '';

    await ensureItemCardMessage(
      roomId: roomId,

      senderId:
      enquirySenderId.isNotEmpty
          ? enquirySenderId
          : currentUserId,

      itemName: itemName,

      itemImage: itemImage,

      itemLocation: itemLocation,

      itemPostDate: itemPostDate,
    );
  }

  // ============================================================
  // MARK AS ENQUIRY
  // ============================================================

  static Future<void> markAsEnquiry({
    required String roomId,
    required String enquirySenderId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'enquirySenderId':
        enquirySenderId,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // BLOCKED
  // ============================================================

  static Future<bool> isChatBlocked({
    required String roomId,
    required String userId,
  }) async {
    final snapshot =
    await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return false;
    }

    final data =
        snapshot.data() ??
            <String, dynamic>{};

    final blockedBy =
    List<String>.from(
      data['blockedBy'] ?? [],
    );

    return blockedBy.isNotEmpty;
  }

  static Future<void> blockChat({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'blockedBy':
        FieldValue.arrayUnion([
          userId,
        ]),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> unblockChat({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'blockedBy':
        FieldValue.arrayRemove([
          userId,
        ]),
      },
      SetOptions(merge: true),
    );
  }

  static Stream<bool> chatBlockedStream({
    required String roomId,
  }) {
    return _rooms
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return false;
      }

      final data =
          snapshot.data() ??
              <String, dynamic>{};

      final blockedBy =
      List<String>.from(
        data['blockedBy'] ?? [],
      );

      return blockedBy.isNotEmpty;
    });
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      return;
    }

    final roomRef =
    _rooms.doc(roomId);

    final roomSnapshot =
    await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception(
        'Chat room does not exist',
      );
    }

    final roomData =
        roomSnapshot.data() ??
            <String, dynamic>{};

    final blockedBy =
    List<String>.from(
      roomData['blockedBy'] ?? [],
    );

    if (blockedBy.isNotEmpty) {
      throw Exception(
        'This chat is blocked. '
            'Unblock the chat to continue.',
      );
    }

    final users =
    List<String>.from(
      roomData['users'] ?? [],
    );

    final receiverId =
    users.firstWhere(
          (id) => id != senderId,
      orElse: () => '',
    );

    if (receiverId.isEmpty) {
      throw Exception(
        'Receiver user not found',
      );
    }

    final messageRef = roomRef
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageType': 'text',
      'senderId': senderId,
      'message': message.trim(),
      'createdAt':
      FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': false,
      'read': false,
      'readBy': <String>[],
    });

    final currentUnread =
    Map<String, dynamic>.from(
      roomData['unreadCounts'] ?? {},
    );

    int receiverUnread =
        int.tryParse(
          currentUnread[receiverId]
              ?.toString() ??
              '0',
        ) ??
            0;

    receiverUnread++;

    currentUnread[receiverId] =
        receiverUnread;

    await roomRef.set(
      {
        'lastMessage':
        message.trim(),

        'lastMessageTime':
        FieldValue.serverTimestamp(),

        'lastMessageSenderId':
        senderId,

        'lastMessageRead': false,

        'lastMessageDelivered':
        true,

        'lastMessageDeleted':
        false,

        'lastMessageId':
        messageRef.id,

        'unreadCounts':
        currentUnread,
      },
      SetOptions(merge: true),
    );

    await messageRef.update({
      'delivered': true,
    });
  }

  // ============================================================
  // CHAT ROOMS STREAM
  // ============================================================

  static Stream<
      QuerySnapshot<
          Map<String, dynamic>>>
  chatRoomsStream(
      String userId,
      ) {
    return _rooms
        .where(
      'users',
      arrayContains: userId,
    )
        .snapshots();
  }

  // ============================================================
  // MESSAGES STREAM
  // ============================================================

  static Stream<
      QuerySnapshot<
          Map<String, dynamic>>>
  messagesStream(
      String roomId,
      ) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy(
      'createdAt',
      descending: false,
    )
        .snapshots();
  }

  // ============================================================
  // MARK ROOM AS READ
  // ============================================================

  static Future<void> markRoomAsRead({
    required String roomId,
    required String userId,
  }) async {
    final roomRef =
    _rooms.doc(roomId);

    final roomSnapshot =
    await roomRef.get();

    if (!roomSnapshot.exists) {
      return;
    }

    final roomData =
        roomSnapshot.data() ??
            <String, dynamic>{};

    final unreadCounts =
    Map<String, dynamic>.from(
      roomData['unreadCounts'] ?? {},
    );

    unreadCounts[userId] = 0;

    await roomRef.set(
      {
        'unreadCounts':
        unreadCounts,
      },
      SetOptions(merge: true),
    );

    final messagesSnapshot =
    await roomRef
        .collection('messages')
        .where(
      'senderId',
      isNotEqualTo: userId,
    )
        .get();

    if (messagesSnapshot.docs.isEmpty) {
      return;
    }

    final batch =
    _firestore.batch();

    for (final doc
    in messagesSnapshot.docs) {
      final data = doc.data();

      if (data['isDeleted'] == true) {
        continue;
      }

      final readBy =
      List<String>.from(
        data['readBy'] ?? [],
      );

      if (!readBy.contains(userId)) {
        readBy.add(userId);

        batch.update(
          doc.reference,
          {
            'read': true,
            'readBy': readBy,
          },
        );
      }
    }

    await batch.commit();

    final latestRoomSnapshot =
    await roomRef.get();

    final latestData =
        latestRoomSnapshot.data() ??
            <String, dynamic>{};

    final lastSender =
        latestData[
        'lastMessageSenderId']
            ?.toString() ??
            '';

    if (lastSender.isNotEmpty &&
        lastSender != userId) {
      await roomRef.set(
        {
          'lastMessageRead': true,
        },
        SetOptions(merge: true),
      );
    }
  }

  // ============================================================
  // DELETE FOR EVERYONE
  // ============================================================

  static Future<void> deleteForEveryone({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    final roomRef =
    _rooms.doc(roomId);

    final messageRef = roomRef
        .collection('messages')
        .doc(messageId);

    final snapshot =
    await messageRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ??
            <String, dynamic>{};

    final senderId =
        data['senderId']
            ?.toString() ??
            '';

    if (senderId != currentUserId) {
      throw Exception(
        'You can delete only your own messages.',
      );
    }

    await messageRef.update({
      'isDeleted': true,
      'message':
      'This message was deleted',
    });

    final latestMessages =
    await roomRef
        .collection('messages')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(1)
        .get();

    if (latestMessages.docs.isEmpty) {
      await roomRef.set(
        {
          'lastMessage': '',
          'lastMessageTime':
          FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'lastMessageRead': false,
          'lastMessageDelivered': false,
          'lastMessageDeleted': false,
          'lastMessageId': '',
          'unreadCounts': {},
        },
        SetOptions(merge: true),
      );

      return;
    }

    final latestDoc =
        latestMessages.docs.first;

    final latestData =
    latestDoc.data();

    final latestDeleted =
        latestData['isDeleted'] ==
            true;

    final latestType =
        latestData['messageType']
            ?.toString() ??
            'text';

    String latestMessage;

    if (latestDeleted) {
      latestMessage =
      'This message was deleted';
    } else if (latestType == 'item') {
      latestMessage =
      'Item shared';
    } else {
      latestMessage =
          latestData['message']
              ?.toString() ??
              '';
    }

    await roomRef.set(
      {
        'lastMessage':
        latestMessage,

        'lastMessageTime':
        latestData['createdAt'],

        'lastMessageSenderId':
        latestData['senderId']
            ?.toString() ??
            '',

        'lastMessageDeleted':
        latestDeleted,

        'lastMessageId':
        latestDoc.id,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // DELETE FOR ME
  // ============================================================

  static Future<void> deleteForMe({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    final messageRef = _rooms
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    final snapshot =
    await messageRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ??
            <String, dynamic>{};

    final deletedFor =
    List<String>.from(
      data['deletedFor'] ?? [],
    );

    if (!deletedFor.contains(
      currentUserId,
    )) {
      deletedFor.add(currentUserId);
    }

    await messageRef.update({
      'deletedFor':
      deletedFor,
    });
  }

  // ============================================================
  // CLEAR CHAT
  // ============================================================

  static Future<void> clearChat({
    required String roomId,
  }) async {
    final roomRef =
    _rooms.doc(roomId);

    final messagesSnapshot =
    await roomRef
        .collection('messages')
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      WriteBatch batch =
      _firestore.batch();

      int operationCount = 0;

      for (final doc
      in messagesSnapshot.docs) {
        batch.delete(
          doc.reference,
        );

        operationCount++;

        if (operationCount == 450) {
          await batch.commit();

          batch =
              _firestore.batch();

          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }
    }

    await roomRef.set(
      {
        'lastMessage': '',
        'lastMessageTime':
        FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'lastMessageRead': false,
        'lastMessageDelivered': false,
        'lastMessageDeleted': false,
        'lastMessageId': '',
        'unreadCounts': {},
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // CONTACT REQUEST STREAM
  // ============================================================

  static Stream<
      Map<String, dynamic>>
  contactRequestStream({
    required String roomId,
  }) {
    return _rooms
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {
          'status': 'none',
          'senderId': '',
          'receiverId': '',
          'enquirySenderId': '',
        };
      }

      final data =
          snapshot.data() ??
              <String, dynamic>{};

      return {
        'status':
        data['contactRequestStatus']
            ?.toString() ??
            'none',

        'senderId':
        data['contactRequestSenderId']
            ?.toString() ??
            '',

        'receiverId':
        data['contactRequestReceiverId']
            ?.toString() ??
            '',

        'enquirySenderId':
        data['enquirySenderId']
            ?.toString() ??
            '',
      };
    });
  }

  // ============================================================
  // SEND CONTACT REQUEST
  // ============================================================

  static Future<void> sendContactRequest({
    required String roomId,
    required String senderId,
    required String receiverId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'contactRequestStatus':
        'pending',

        'contactRequestSenderId':
        senderId,

        'contactRequestReceiverId':
        receiverId,

        'contactRequestCreatedAt':
        FieldValue.serverTimestamp(),

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] Contact request SENT '
          'sender=$senderId receiver=$receiverId',
    );
  }

  // ============================================================
  // ACCEPT CONTACT REQUEST
  // ============================================================

  static Future<void> acceptContactRequest({
    required String roomId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'contactRequestStatus':
        'accepted',

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] Contact request = ACCEPTED',
    );
  }

  // ============================================================
  // DECLINE CONTACT REQUEST
  // ============================================================

  static Future<void> declineContactRequest({
    required String roomId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'contactRequestStatus':
        'declined',

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}