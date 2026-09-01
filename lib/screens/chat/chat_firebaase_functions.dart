import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

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
    final cleanCurrentUserId = currentUserId.trim();
    final cleanOtherUserId = otherUserId.trim();

    if (cleanCurrentUserId.isEmpty ||
        cleanOtherUserId.isEmpty) {
      throw Exception('User IDs cannot be empty');
    }

    final users = [
      cleanCurrentUserId,
      cleanOtherUserId,
    ]..sort();

    final trimmedPostId = postId.trim();

    final roomId = trimmedPostId.isNotEmpty
        ? '${users[0]}_${users[1]}_$trimmedPostId'
        : '${users[0]}_${users[1]}';

    final roomRef = _rooms.doc(roomId);

    final snapshot = await roomRef.get();

    final newParticipants = <String, dynamic>{
      cleanCurrentUserId: {
        'name': currentUserName.trim(),
        'avatar': currentUserAvatar.trim(),
        'phone': currentUserPhone.trim(),
      },
      cleanOtherUserId: {
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
          cleanCurrentUserId: 0,
          cleanOtherUserId: 0,
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

      final existingParticipants =
      Map<String, dynamic>.from(
        roomData['participants'] ?? {},
      );

      // ==========================================================
      // CURRENT USER
      // ==========================================================

      final currentParticipant =
      Map<String, dynamic>.from(
        existingParticipants[cleanCurrentUserId] ?? {},
      );

      if (currentUserName.trim().isNotEmpty) {
        currentParticipant['name'] =
            currentUserName.trim();
      }

      if (currentUserAvatar.trim().isNotEmpty) {
        currentParticipant['avatar'] =
            currentUserAvatar.trim();
      }

      if (currentUserPhone.trim().isNotEmpty) {
        currentParticipant['phone'] =
            currentUserPhone.trim();
      }

      currentParticipant['name'] ??= '';
      currentParticipant['avatar'] ??= '';
      currentParticipant['phone'] ??= '';

      existingParticipants[cleanCurrentUserId] =
          currentParticipant;

      // ==========================================================
      // OTHER USER
      // ==========================================================

      final otherParticipant =
      Map<String, dynamic>.from(
        existingParticipants[cleanOtherUserId] ?? {},
      );

      if (otherUserName.trim().isNotEmpty) {
        otherParticipant['name'] =
            otherUserName.trim();
      }

      if (otherUserAvatar.trim().isNotEmpty) {
        otherParticipant['avatar'] =
            otherUserAvatar.trim();
      }

      if (otherUserPhone.trim().isNotEmpty) {
        otherParticipant['phone'] =
            otherUserPhone.trim();
      }

      otherParticipant['name'] ??= '';
      otherParticipant['avatar'] ??= '';
      otherParticipant['phone'] ??= '';

      existingParticipants[cleanOtherUserId] =
          otherParticipant;

      final updateData =
      <String, dynamic>{
        'users': users,
        'participants': existingParticipants,
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
      // ITEM
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
            : cleanCurrentUserId,
        itemName: itemName,
        itemImage: itemImage,
        itemLocation: itemLocation,
        itemPostDate: itemPostDate,
      );
    }

    return roomId;
  }

  // ============================================================
  // UPDATE PARTICIPANT PROFILE
  // ============================================================

  static Future<void> updateParticipantProfile({
    required String roomId,
    required String userId,
    String name = '',
    String avatar = '',
    String phone = '',
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanUserId = userId.trim();

    if (cleanRoomId.isEmpty ||
        cleanUserId.isEmpty) {
      return;
    }

    final roomRef = _rooms.doc(cleanRoomId);

    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      return;
    }

    final roomData =
        snapshot.data() ?? <String, dynamic>{};

    final participants =
    Map<String, dynamic>.from(
      roomData['participants'] ?? {},
    );

    final participant =
    Map<String, dynamic>.from(
      participants[cleanUserId] ?? {},
    );

    if (name.trim().isNotEmpty) {
      participant['name'] = name.trim();
    }

    if (avatar.trim().isNotEmpty) {
      participant['avatar'] = avatar.trim();
    }

    if (phone.trim().isNotEmpty) {
      participant['phone'] = phone.trim();
    }

    participant['name'] ??= '';
    participant['avatar'] ??= '';
    participant['phone'] ??= '';

    participants[cleanUserId] = participant;

    await roomRef.set(
      {
        'participants': participants,
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] PARTICIPANT UPDATED '
          'room=$cleanRoomId '
          'user=$cleanUserId '
          'name=${participant['name']}',
    );
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
        snapshot.data() ?? <String, dynamic>{};

    final participants =
    Map<String, dynamic>.from(
      data['participants'] ?? {},
    );

    final participant =
    participants[userId.trim()];

    if (participant == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      participant,
    );
  }

  // ============================================================
  // GET PARTICIPANT NAME
  // ============================================================

  static Future<String> getParticipantName({
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

    return participant['name']
        ?.toString()
        .trim() ??
        '';
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

  static Future<void> updateParticipantPhone({
    required String roomId,
    required String userId,
    required String phone,
  }) async {
    await updateParticipantProfile(
      roomId: roomId,
      userId: userId,
      phone: phone,
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
        'itemName': itemName.trim(),
        'itemImage': itemImage.trim(),
        'itemLocation': itemLocation.trim(),
        'itemPostDate': itemPostDate.trim(),
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
  }

  // ============================================================
  // ENSURE ITEM CARD FROM ROOM
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
        snapshot.data() ?? <String, dynamic>{};

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
        enquirySenderId.trim(),
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
        snapshot.data() ?? <String, dynamic>{};

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
          userId.trim(),
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
          userId.trim(),
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
          snapshot.data() ?? <String, dynamic>{};

      final blockedBy =
      List<String>.from(
        data['blockedBy'] ?? [],
      );

      return blockedBy.isNotEmpty;
    });
  }

  // ============================================================
  // GET RECEIVER ID
  // ============================================================

  static String _getReceiverId({
    required List<String> users,
    required String senderId,
  }) {
    final cleanSenderId = senderId.trim();

    return users.firstWhere(
          (id) => id.trim() != cleanSenderId,
      orElse: () => '',
    );
  }

  // ============================================================
  // GET UNREAD COUNTS
  // ============================================================

  static Map<String, dynamic> _getUnreadCounts(
      Map<String, dynamic> roomData,
      ) {
    return Map<String, dynamic>.from(
      roomData['unreadCounts'] ?? {},
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String message,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      return;
    }

    final roomRef =
    _rooms.doc(cleanRoomId);

    final roomSnapshot =
    await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception(
        'Chat room does not exist',
      );
    }

    final roomData =
        roomSnapshot.data() ?? <String, dynamic>{};

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

    final receiverId = _getReceiverId(
      users: users,
      senderId: cleanSenderId,
    );

    if (receiverId.isEmpty) {
      throw Exception(
        'Receiver user not found',
      );
    }

    final messageRef =
    roomRef
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageType': 'text',
      'senderId': cleanSenderId,
      'message': cleanMessage,
      'createdAt':
      FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final currentUnread =
    _getUnreadCounts(roomData);

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
        'lastMessage': cleanMessage,

        'lastMessageTime':
        FieldValue.serverTimestamp(),

        'lastMessageSenderId':
        cleanSenderId,

        'lastMessageRead': false,

        'lastMessageDelivered': true,

        'lastMessageDeleted': false,

        'lastMessageId':
        messageRef.id,

        'unreadCounts':
        currentUnread,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // SEND LOCATION MESSAGE
  // ============================================================

  static Future<void> sendLocationMessage({
    required String roomId,
    required String senderId,
    required double latitude,
    required double longitude,
    String address = '',
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();

    final roomRef =
    _rooms.doc(cleanRoomId);

    final roomSnapshot =
    await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception(
        'Chat room does not exist',
      );
    }

    final roomData =
        roomSnapshot.data() ?? <String, dynamic>{};

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

    final receiverId = _getReceiverId(
      users: users,
      senderId: cleanSenderId,
    );

    if (receiverId.isEmpty) {
      throw Exception(
        'Receiver user not found',
      );
    }

    final messageRef =
    roomRef
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageType': 'location',
      'senderId': cleanSenderId,
      'message': address.isNotEmpty
          ? address
          : 'Shared location',
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt':
      FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final currentUnread =
    _getUnreadCounts(roomData);

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
        'lastMessage': ' Location',
        'lastMessageTime':
        FieldValue.serverTimestamp(),
        'lastMessageSenderId':
        cleanSenderId,
        'lastMessageRead': false,
        'lastMessageDelivered': true,
        'lastMessageDeleted': false,
        'lastMessageId':
        messageRef.id,
        'unreadCounts':
        currentUnread,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // SEND IMAGE MESSAGE
  //
  // IMPORTANT:
  //
  // 1. Image is uploaded to Firebase Storage
  // 2. Download URL is generated
  // 3. ONLY the URL is stored in Firestore
  //
  // Firestore:
  //
  // imageUrl: "https://firebasestorage.googleapis.com/..."
  //
  // ============================================================

  static Future<void> sendImageMessage({
    required String roomId,
    required String senderId,
    required File imageFile,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();

    if (cleanRoomId.isEmpty) {
      throw Exception(
        'Room ID cannot be empty',
      );
    }

    if (cleanSenderId.isEmpty) {
      throw Exception(
        'Sender ID cannot be empty',
      );
    }

    if (!await imageFile.exists()) {
      throw Exception(
        'Image file does not exist',
      );
    }

    final roomRef =
    _rooms.doc(cleanRoomId);

    // ==========================================================
    // GET ROOM
    // ==========================================================

    final roomSnapshot =
    await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception(
        'Chat room does not exist',
      );
    }

    final roomData =
        roomSnapshot.data() ?? <String, dynamic>{};

    // ==========================================================
    // CHECK BLOCK
    // ==========================================================

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

    // ==========================================================
    // GET USERS
    // ==========================================================

    final users =
    List<String>.from(
      roomData['users'] ?? [],
    );

    final receiverId = _getReceiverId(
      users: users,
      senderId: cleanSenderId,
    );

    if (receiverId.isEmpty) {
      throw Exception(
        'Receiver user not found',
      );
    }

    // ==========================================================
    // READ IMAGE BYTES
    // ==========================================================

    final Uint8List bytes =
    await imageFile.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception(
        'Image file is empty',
      );
    }

    // ==========================================================
    // CREATE UNIQUE FILE NAME
    // ==========================================================

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_'
        '${cleanSenderId}.jpg';

    // ==========================================================
    // FIREBASE STORAGE REFERENCE
    // ==========================================================

    final Reference storageRef =
    _storage
        .ref()
        .child('chatImages')
        .child(cleanRoomId)
        .child(fileName);

    print(
      '[ChatService] IMAGE UPLOAD START',
    );

    print(
      '[ChatService] Storage path: '
          '${storageRef.fullPath}',
    );

    // ==========================================================
    // UPLOAD IMAGE TO FIREBASE STORAGE
    // ==========================================================

    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      print(
        '[ChatService] IMAGE UPLOAD SUCCESS',
      );
    } on FirebaseException catch (e) {
      print(
        '[ChatService] FIREBASE STORAGE ERROR',
      );

      print(
        'Code: ${e.code}',
      );

      print(
        'Message: ${e.message}',
      );

      throw Exception(
        'Image upload failed: ${e.message ?? e.code}',
      );
    } catch (e) {
      print(
        '[ChatService] IMAGE UPLOAD ERROR: $e',
      );

      rethrow;
    }

    // ==========================================================
    // GET DOWNLOAD URL
    //
    // THIS IS THE URL THAT WILL BE STORED IN FIRESTORE
    // ==========================================================

    String imageUrl;

    try {
      imageUrl =
      await storageRef.getDownloadURL();

      print(
        '[ChatService] IMAGE DOWNLOAD URL:',
      );

      print(imageUrl);
    } on FirebaseException catch (e) {
      print(
        '[ChatService] GET DOWNLOAD URL ERROR',
      );

      print(
        'Code: ${e.code}',
      );

      print(
        'Message: ${e.message}',
      );

      throw Exception(
        'Could not get image URL: '
            '${e.message ?? e.code}',
      );
    }

    if (imageUrl.trim().isEmpty) {
      throw Exception(
        'Firebase returned an empty image URL',
      );
    }

    // ==========================================================
    // CREATE FIRESTORE MESSAGE
    // ==========================================================

    final messageRef =
    roomRef
        .collection('messages')
        .doc();

    // ==========================================================
    // SAVE URL TO FIRESTORE
    // ==========================================================

    await messageRef.set({
      'messageType': 'image',

      'senderId': cleanSenderId,

      'message': '',

      // ONLY URL IS STORED IN FIRESTORE
      'imageUrl': imageUrl,

      'createdAt':
      FieldValue.serverTimestamp(),

      'isDeleted': false,

      'deletedFor': <String>[],

      'delivered': true,

      'read': false,

      'readBy': <String>[],
    });

    print(
      '[ChatService] IMAGE MESSAGE SAVED',
    );

    print(
      '[ChatService] Firestore imageUrl: '
          '$imageUrl',
    );

    // ==========================================================
    // UPDATE UNREAD COUNT
    // ==========================================================

    final currentUnread =
    _getUnreadCounts(roomData);

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

    // ==========================================================
    // UPDATE LAST MESSAGE
    // ==========================================================

    await roomRef.set(
      {
        'lastMessage': '📷 Photo',

        'lastMessageTime':
        FieldValue.serverTimestamp(),

        'lastMessageSenderId':
        cleanSenderId,

        'lastMessageRead': false,

        'lastMessageDelivered': true,

        'lastMessageDeleted': false,

        'lastMessageId':
        messageRef.id,

        'unreadCounts':
        currentUnread,
      },
      SetOptions(merge: true),
    );

    print(
      '[ChatService] IMAGE SEND COMPLETED',
    );
  }

  // ============================================================
// SEND IMAGE MESSAGE (image already uploaded via createImage API)
//
// Flow:
// 1. File is uploaded via AuthRepository.createImage()
// 2. Backend returns img_path URL
// 3. ONLY the URL is stored in Firestore — no Firebase Storage
// ============================================================

  static Future<void> sendImageMessageWithUrl({
    required String roomId,
    required String senderId,
    required String imageUrl,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();
    final cleanImageUrl = imageUrl.trim();

    if (cleanImageUrl.isEmpty) {
      throw Exception('Image URL cannot be empty');
    }

    final roomRef = _rooms.doc(cleanRoomId);

    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Chat room does not exist');
    }

    final roomData = roomSnapshot.data() ?? <String, dynamic>{};

    final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);

    if (blockedBy.isNotEmpty) {
      throw Exception(
        'This chat is blocked. Unblock the chat to continue.',
      );
    }

    final users = List<String>.from(roomData['users'] ?? []);

    final receiverId = _getReceiverId(
      users: users,
      senderId: cleanSenderId,
    );

    if (receiverId.isEmpty) {
      throw Exception('Receiver user not found');
    }

    final messageRef = roomRef.collection('messages').doc();

    // ==========================================================
    // SAVE URL TO FIRESTORE — no file, no Firebase Storage upload
    // ==========================================================

    await messageRef.set({
      'messageType': 'image',
      'senderId': cleanSenderId,
      'message': '',
      'imageUrl': cleanImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final currentUnread = _getUnreadCounts(roomData);

    int receiverUnread = int.tryParse(
      currentUnread[receiverId]?.toString() ?? '0',
    ) ??
        0;

    receiverUnread++;
    currentUnread[receiverId] = receiverUnread;

    await roomRef.set(
      {
        'lastMessage': 'Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': cleanSenderId,
        'lastMessageRead': false,
        'lastMessageDelivered': true,
        'lastMessageDeleted': false,
        'lastMessageId': messageRef.id,
        'unreadCounts': currentUnread,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // CHAT ROOMS STREAM
  // ============================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>>
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

  static Stream<QuerySnapshot<Map<String, dynamic>>>
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
        roomSnapshot.data() ?? <String, dynamic>{};

    final unreadCounts =
    Map<String, dynamic>.from(
      roomData['unreadCounts'] ?? {},
    );

    unreadCounts[userId] = 0;

    await roomRef.set(
      {
        'unreadCounts': unreadCounts,
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
        latestData['lastMessageSenderId']
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

    final messageRef =
    roomRef
        .collection('messages')
        .doc(messageId);

    final snapshot =
    await messageRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? <String, dynamic>{};

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
      'message': 'This message was deleted',
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
        latestData['isDeleted'] == true;

    final latestType =
        latestData['messageType']
            ?.toString() ??
            'text';

    String latestMessage;

    if (latestDeleted) {
      latestMessage =
      'This message was deleted';
    } else if (latestType == 'item') {
      latestMessage = 'Item shared';
    } else if (latestType == 'location') {
      latestMessage = ' Location';
    } else if (latestType == 'image') {
      latestMessage = 'Photo';
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
        snapshot.data() ?? <String, dynamic>{};

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
      'deletedFor': deletedFor,
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
        batch.delete(doc.reference);

        operationCount++;

        if (operationCount == 450) {
          await batch.commit();

          batch = _firestore.batch();

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

  static Stream<Map<String, dynamic>>
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
        'contactRequestStatus': 'pending',

        'contactRequestSenderId':
        senderId.trim(),

        'contactRequestReceiverId':
        receiverId.trim(),

        'contactRequestCreatedAt':
        FieldValue.serverTimestamp(),

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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
        'contactRequestStatus': 'accepted',

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // DECLINE CONTACT REQUEST
  // ===========================================================

  static Future<void> declineContactRequest({
    required String roomId,
  }) async {
    await _rooms.doc(roomId).set(
      {
        'contactRequestStatus': 'declined',

        'contactRequestUpdatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }



}



