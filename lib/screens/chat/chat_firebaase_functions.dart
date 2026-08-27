import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  // ============================================================
  // CREATE / GET CHAT ROOM
  // ============================================================

  static Future<String> createChatRoom({
    required String currentUserId,
    required String otherUserId,

    String currentUserName = '',
    String currentUserAvatar = '',

    String otherUserName = '',
    String otherUserAvatar = '',

    String? enquirySenderId,

    String itemName = '',
    String itemImage = '',
    String itemLocation = '',
    String itemPostDate = '',
  }) async {
    final users = [
      currentUserId,
      otherUserId,
    ]..sort();

    final roomId = '${users[0]}_${users[1]}';

    final roomRef = _rooms.doc(roomId);

    final snapshot = await roomRef.get();

    final participants = {
      currentUserId: {
        'name': currentUserName,
        'avatar': currentUserAvatar,
      },
      otherUserId: {
        'name': otherUserName,
        'avatar': otherUserAvatar,
      },
    };

    // ============================================================
    // CREATE ROOM
    // ============================================================

    if (!snapshot.exists) {
      await roomRef.set({
        'roomId': roomId,

        'users': users,

        'participants': participants,

        'enquirySenderId': enquirySenderId,

        'createdAt': FieldValue.serverTimestamp(),

        'lastMessage': '',

        'lastMessageTime': FieldValue.serverTimestamp(),

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
        // ITEM DATA
        // ========================================================

        'itemName': itemName,

        'itemImage': itemImage,

        'itemLocation': itemLocation,

        'itemPostDate': itemPostDate,
      });
    }

    // ============================================================
    // EXISTING ROOM
    // ============================================================

    else {
      final updateData = <String, dynamic>{
        'users': users,
        'participants': participants,
      };

      if (enquirySenderId != null &&
          enquirySenderId.isNotEmpty) {
        updateData['enquirySenderId'] =
            enquirySenderId;
      }

      if (itemName.trim().isNotEmpty) {
        updateData['itemName'] = itemName;
      }

      if (itemImage.trim().isNotEmpty) {
        updateData['itemImage'] = itemImage;
      }

      if (itemLocation.trim().isNotEmpty) {
        updateData['itemLocation'] =
            itemLocation;
      }

      if (itemPostDate.trim().isNotEmpty) {
        updateData['itemPostDate'] =
            itemPostDate;
      }

      // IMPORTANT:
      // Do not overwrite blockedBy.

      await roomRef.set(
        updateData,
        SetOptions(
          merge: true,
        ),
      );
    }

    // ============================================================
    // CREATE ITEM CARD MESSAGE
    // ============================================================

    if (itemName.trim().isNotEmpty) {
      await ensureItemCardMessage(
        roomId: roomId,
        senderId:
        enquirySenderId ?? currentUserId,
        itemName: itemName,
        itemImage: itemImage,
        itemLocation: itemLocation,
        itemPostDate: itemPostDate,
      );
    }

    return roomId;
  }

  // ============================================================
  // ENSURE ITEM CARD MESSAGE
  // ============================================================
  //
  // The document ID is always:
  //
  // itemCard
  //
  // Therefore it can only exist once inside a room.
  //
  // Both users read the same document.
  //
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

    if (itemName.trim().isEmpty) {
      return;
    }

    final itemCardRef = _rooms
        .doc(roomId)
        .collection('messages')
        .doc('itemCard');

    final existing =
    await itemCardRef.get();

    // Already exists.
    if (existing.exists) {
      return;
    }

    await itemCardRef.set({
      'messageType': 'item',

      'senderId': senderId,

      'message': '',

      'itemName': itemName,

      'itemImage': itemImage,

      'itemLocation': itemLocation,

      'itemPostDate': itemPostDate,

      'createdAt':
      FieldValue.serverTimestamp(),

      'isDeleted': false,

      'deletedFor': <String>[],

      'delivered': true,

      'read': true,

      'readBy': <String>[],
    });
  }

  // ============================================================
  // ENSURE ITEM CARD FROM EXISTING ROOM
  // ============================================================
  //
  // Used when opening an already-created room.
  //
  // Example:
  //
  // chatRooms/48_49
  //
  // ============================================================

  static Future<void> ensureItemCardFromRoom({
    required String roomId,
    required String currentUserId,
  }) async {
    if (roomId.trim().isEmpty) {
      return;
    }

    final roomSnapshot =
    await _rooms.doc(roomId).get();

    if (!roomSnapshot.exists) {
      return;
    }

    final roomData =
        roomSnapshot.data() ?? {};

    final itemName =
        roomData['itemName']
            ?.toString()
            .trim() ??
            '';

    // There is no item information in
    // this room, so there is nothing
    // to create.
    if (itemName.isEmpty) {
      return;
    }

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
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // GET ROOM
  // ============================================================

  static Future<Map<String, dynamic>?>
  getRoom(
      String roomId,
      ) async {
    final snapshot =
    await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // ============================================================
  // CHECK BLOCKED
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
        snapshot.data() ?? {};

    final blockedBy =
    List<String>.from(
      data['blockedBy'] ?? [],
    );

    return blockedBy.isNotEmpty;
  }

  // ============================================================
  // BLOCK
  // ============================================================

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
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // UNBLOCK
  // ============================================================

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
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // BLOCKED STREAM
  // ============================================================

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
          snapshot.data() ?? {};

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
        roomSnapshot.data() ?? {};

    // ============================================================
    // CHECK BLOCK
    // ============================================================

    final blockedBy =
    List<String>.from(
      roomData['blockedBy'] ?? [],
    );

    if (blockedBy.isNotEmpty) {
      throw Exception(
        'This chat is blocked. Unblock the chat to continue.',
      );
    }

    // ============================================================
    // USERS
    // ============================================================

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

    // ============================================================
    // CREATE MESSAGE
    // ============================================================

    final messageRef = roomRef
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageType': 'text',

      'senderId': senderId,

      'message':
      message.trim(),

      'createdAt':
      FieldValue.serverTimestamp(),

      'isDeleted': false,

      'deletedFor':
      <String>[],

      'delivered': false,

      'read': false,

      'readBy':
      <String>[],
    });

    // ============================================================
    // UNREAD
    // ============================================================

    final currentUnread =
    Map<String, dynamic>.from(
      roomData['unreadCounts'] ??
          {},
    );

    int receiverUnread =
        int.tryParse(
          currentUnread[
          receiverId]
              ?.toString() ??
              '0',
        ) ??
            0;

    receiverUnread++;

    currentUnread[
    receiverId] =
        receiverUnread;

    // ============================================================
    // UPDATE ROOM
    // ============================================================

    await roomRef.set(
      {
        'lastMessage':
        message.trim(),

        'lastMessageTime':
        FieldValue.serverTimestamp(),

        'lastMessageSenderId':
        senderId,

        'lastMessageRead':
        false,

        'lastMessageDelivered':
        true,

        'lastMessageDeleted':
        false,

        'lastMessageId':
        messageRef.id,

        'unreadCounts':
        currentUnread,
      },
      SetOptions(
        merge: true,
      ),
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
        roomSnapshot.data() ?? {};

    final unreadCounts =
    Map<String, dynamic>.from(
      roomData['unreadCounts'] ??
          {},
    );

    unreadCounts[userId] = 0;

    await roomRef.set(
      {
        'unreadCounts':
        unreadCounts,
      },
      SetOptions(
        merge: true,
      ),
    );

    final messagesSnapshot =
    await roomRef
        .collection('messages')
        .where(
      'senderId',
      isNotEqualTo: userId,
    )
        .get();

    if (messagesSnapshot
        .docs.isEmpty) {
      return;
    }

    final batch =
    _firestore.batch();

    for (final doc
    in messagesSnapshot.docs) {
      final data =
      doc.data();

      if (data['isDeleted'] ==
          true) {
        continue;
      }

      final readBy =
      List<String>.from(
        data['readBy'] ?? [],
      );

      if (!readBy.contains(
        userId,
      )) {
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
            {};

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
        SetOptions(
          merge: true,
        ),
      );
    }
  }

  // ============================================================
  // DELETE FOR EVERYONE
  // ============================================================

  static Future<void>
  deleteForEveryone({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    final roomRef =
    _rooms.doc(roomId);

    final messageRef =
    roomRef
        .collection('messages')
        .doc(messageId);

    final messageSnapshot =
    await messageRef.get();

    if (!messageSnapshot.exists) {
      return;
    }

    final messageData =
        messageSnapshot.data() ??
            {};

    final senderId =
        messageData['senderId']
            ?.toString() ??
            '';

    if (senderId !=
        currentUserId) {
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

    if (latestMessages
        .docs.isEmpty) {
      await roomRef.set(
        {
          'lastMessage': '',

          'lastMessageTime':
          FieldValue.serverTimestamp(),

          'lastMessageSenderId': '',

          'lastMessageRead': false,

          'lastMessageDelivered':
          false,

          'lastMessageDeleted':
          false,

          'lastMessageId': '',

          'unreadCounts': {},
        },
        SetOptions(
          merge: true,
        ),
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
    } else if (latestType ==
        'item') {
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
      SetOptions(
        merge: true,
      ),
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
    final messageRef =
    _rooms
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    final snapshot =
    await messageRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? {};

    final deletedFor =
    List<String>.from(
      data['deletedFor'] ?? [],
    );

    if (!deletedFor.contains(
      currentUserId,
    )) {
      deletedFor.add(
        currentUserId,
      );
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

    if (messagesSnapshot
        .docs.isNotEmpty) {
      WriteBatch batch =
      _firestore.batch();

      int operationCount = 0;

      for (final doc
      in messagesSnapshot.docs) {
        batch.delete(
          doc.reference,
        );

        operationCount++;

        if (operationCount ==
            450) {
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

        'lastMessageDelivered':
        false,

        'lastMessageDeleted':
        false,

        'lastMessageId': '',

        'unreadCounts': {},
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}