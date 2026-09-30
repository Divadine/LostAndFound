import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  // ============================================================
  // GENERATE DETERMINISTIC ROOM ID
  // ============================================================

  static String generateRoomId({
    required String userId1,
    required String userId2,
    required String postId,
  }) {
    final cleanUser1 = userId1.trim();
    final cleanUser2 = userId2.trim();
    final cleanPostId = postId.trim();

    final users = [cleanUser1, cleanUser2]..sort();

    // Deterministic ID based on sorted users and target post ID
    return '${users[0]}_${users[1]}_$cleanPostId';
  }

  // ============================================================
  // GET OR CREATE CHAT ROOM (Idempotent)
  // ============================================================

  static Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String postId,
    String? matchedPostId,
    String? enquiryId,
    String? enquirySenderId,
    String? itemName,
    String? itemImage,
    String? itemLocation,
    String? itemPostDate,
    String? currentUserName,
    String? currentUserAvatar,
    String? currentUserPhone,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserPhone,
    String? description,
    String? profileUrl,
  }) async {
    final cleanCurrentUserId = currentUserId.trim();
    final cleanOtherUserId = otherUserId.trim();
    final cleanPostId = postId.trim();

    if (cleanCurrentUserId.isEmpty ||
        cleanOtherUserId.isEmpty ||
        cleanPostId.isEmpty) {
      throw Exception('User IDs and Post ID cannot be empty');
    }

    final roomId = generateRoomId(
      userId1: cleanCurrentUserId,
      userId2: cleanOtherUserId,
      postId: cleanPostId,
    );

    debugPrint('[CHAT_ID]\n'
        'currentUserId=$cleanCurrentUserId\n'
        'otherUserId=$cleanOtherUserId\n'
        'postId=$cleanPostId\n'
        'matchedPostId=${matchedPostId ?? ''}\n'
        'enquiryId=${enquiryId ?? ''}\n'
        'generatedRoomId=$roomId');

    final roomRef = _rooms.doc(roomId);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final now = FieldValue.serverTimestamp();

      if (!snapshot.exists) {
        // ========================================================
        // CREATE NEW ROOM
        // ========================================================
        final users = [cleanCurrentUserId, cleanOtherUserId]..sort();

        final data = <String, dynamic>{
          'roomId': roomId,
          'users': users,
          'postId': cleanPostId,
          'matchedPostId': matchedPostId?.trim() ?? '',
          'enquiryId': enquiryId?.trim() ?? '',
          'enquirySenderId': enquirySenderId?.trim() ?? '',
          'itemName': itemName?.trim() ?? '',
          'itemImage': itemImage?.trim() ?? '',
          'itemLocation': itemLocation?.trim() ?? '',
          'itemPostDate': itemPostDate?.trim() ?? '',
          'description': description?.trim() ?? '',
          'profileUrl': profileUrl?.trim() ?? '',
          'createdAt': now,
          'updatedAt': now,
          'lastMessage': '',
          'lastMessageTime': now,
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
          'contactRequestStatus': 'none',
          'participants': {
            cleanCurrentUserId: {
              'name': currentUserName?.trim() ?? '',
              'avatar': currentUserAvatar?.trim() ?? '',
              'phone': currentUserPhone?.trim() ?? '',
            },
            cleanOtherUserId: {
              'name': otherUserName?.trim() ?? '',
              'avatar': otherUserAvatar?.trim() ?? '',
              'phone': otherUserPhone?.trim() ?? '',
            },
          },
        };

        transaction.set(roomRef, data);
        debugPrint('[CHAT_CREATED] Created new room: $roomId');
      } else {
        // ========================================================
        // UPDATE EXISTING ROOM (Merging logic)
        // ========================================================
        final existingData = snapshot.data()!;
        final updateData = <String, dynamic>{
          'updatedAt': now,
        };

        // Helper to update only if incoming is non-empty and existing is empty
        void mergeField(String key, String? newValue) {
          final val = newValue?.trim() ?? '';
          final existingVal = existingData[key]?.toString() ?? '';
          if (val.isNotEmpty && existingVal.isEmpty) {
            updateData[key] = val;
          }
        }

        mergeField('matchedPostId', matchedPostId);
        mergeField('enquiryId', enquiryId);
        mergeField('enquirySenderId', enquirySenderId);
        mergeField('itemName', itemName);
        mergeField('itemImage', itemImage);
        mergeField('itemLocation', itemLocation);
        mergeField('itemPostDate', itemPostDate);
        mergeField('description', description);
        mergeField('profileUrl', profileUrl);

        // Merge participants
        final participants =
        Map<String, dynamic>.from(existingData['participants'] ?? {});

        void updateParticipant(
            String uid, String? name, String? avatar, String? phone) {
          final p = Map<String, dynamic>.from(participants[uid] ?? {});
          final n = name?.trim() ?? '';
          final a = avatar?.trim() ?? '';
          final ph = phone?.trim() ?? '';

          if (n.isNotEmpty && (p['name']?.toString().isEmpty ?? true)) {
            p['name'] = n;
          }
          if (a.isNotEmpty && (p['avatar']?.toString().isEmpty ?? true)) {
            p['avatar'] = a;
          }
          if (ph.isNotEmpty && (p['phone']?.toString().isEmpty ?? true)) {
            p['phone'] = ph;
          }
          participants[uid] = p;
        }

        updateParticipant(cleanCurrentUserId, currentUserName,
            currentUserAvatar, currentUserPhone);
        updateParticipant(
            cleanOtherUserId, otherUserName, otherUserAvatar, otherUserPhone);

        updateData['participants'] = participants;

        transaction.update(roomRef, updateData);
        debugPrint('[CHAT_EXISTING] Using existing room: $roomId');
      }

      return roomId;
    }).then((id) async {
      // After transaction, ensure item card message exists if data provided
      if (itemName?.trim().isNotEmpty == true ||
          itemImage?.trim().isNotEmpty == true) {
        await ensureItemCardMessage(
          roomId: id,
          senderId: enquirySenderId?.trim().isNotEmpty == true
              ? enquirySenderId!.trim()
              : cleanCurrentUserId,
          itemName: itemName ?? '',
          itemImage: itemImage ?? '',
          itemLocation: itemLocation ?? '',
          itemPostDate: itemPostDate ?? '',
        );
      }
      return id;
    });
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

    if (cleanRoomId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    final roomRef = _rooms.doc(cleanRoomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final roomData = snapshot.data()!;
      final participants =
      Map<String, dynamic>.from(roomData['participants'] ?? {});
      final participant =
      Map<String, dynamic>.from(participants[cleanUserId] ?? {});

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
      transaction.update(roomRef, {'participants': participants});
    });
  }

  // ============================================================
  // GET ROOM
  // ============================================================

  static Future<Map<String, dynamic>?> getRoom(String roomId) async {
    if (roomId.trim().isEmpty) return null;
    final snapshot = await _rooms.doc(roomId).get();
    return snapshot.exists ? snapshot.data() : null;
  }

  // ============================================================
  // GET PARTICIPANT
  // ============================================================

  static Future<Map<String, dynamic>?> getParticipant({
    required String roomId,
    required String userId,
  }) async {
    if (roomId.trim().isEmpty || userId.trim().isEmpty) return null;
    final snapshot = await _rooms.doc(roomId).get();
    if (!snapshot.exists) return null;

    final participants =
    Map<String, dynamic>.from(snapshot.data()?['participants'] ?? {});
    final participant = participants[userId.trim()];
    return participant != null ? Map<String, dynamic>.from(participant) : null;
  }

  static Future<String> getParticipantPhone({
    required String roomId,
    required String userId,
  }) async {
    final p = await getParticipant(roomId: roomId, userId: userId);
    return p?['phone']?.toString().trim() ?? '';
  }

  static Future<void> updateParticipantPhone({
    required String roomId,
    required String userId,
    required String phone,
  }) async {
    await updateParticipantProfile(roomId: roomId, userId: userId, phone: phone);
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
    if (roomId.trim().isEmpty) return;

    final hasAnyItemData = itemName.trim().isNotEmpty ||
        itemImage.trim().isNotEmpty ||
        itemLocation.trim().isNotEmpty ||
        itemPostDate.trim().isNotEmpty;

    if (!hasAnyItemData) return;

    final itemCardRef = _rooms.doc(roomId).collection('messages').doc('itemCard');
    final doc = await itemCardRef.get();
    if (doc.exists) return;

    await itemCardRef.set({
      'messageType': 'item',
      'senderId': senderId,
      'message': '',
      'itemName': itemName.trim(),
      'itemImage': itemImage.trim(),
      'itemLocation': itemLocation.trim(),
      'itemPostDate': itemPostDate.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': true,
      'readBy': <String>[],
    }, SetOptions(merge: true));
  }

  static Future<void> ensureItemCardFromRoom({
    required String roomId,
    required String currentUserId,
  }) async {
    if (roomId.trim().isEmpty) return;
    final snapshot = await _rooms.doc(roomId).get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final itemName = data['itemName']?.toString().trim() ?? '';
    final itemImage = data['itemImage']?.toString() ?? '';
    final itemLocation = data['itemLocation']?.toString() ?? '';
    final itemPostDate = data['itemPostDate']?.toString() ?? '';
    final enquirySenderId = data['enquirySenderId']?.toString() ?? '';

    if (itemName.isNotEmpty || itemImage.isNotEmpty) {
      await ensureItemCardMessage(
        roomId: roomId,
        senderId: enquirySenderId.isNotEmpty ? enquirySenderId : currentUserId,
        itemName: itemName,
        itemImage: itemImage,
        itemLocation: itemLocation,
        itemPostDate: itemPostDate,
      );
    }
  }

  // ============================================================
  // BLOCKED & CONTACT REQUESTS
  // ============================================================

  static Future<void> blockChat({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).set({
      'blockedBy': FieldValue.arrayUnion([userId.trim()]),
    }, SetOptions(merge: true));
  }

  static Future<void> unblockChat({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).set({
      'blockedBy': FieldValue.arrayRemove([userId.trim()]),
    }, SetOptions(merge: true));
  }

  /// Returns the list of user IDs who blocked this chat.
  static Stream<List<String>> chatBlockedByStream({required String roomId}) {
    return _rooms.doc(roomId).snapshots().map((s) {
      if (!s.exists) return <String>[];
      return List<String>.from(s.data()?['blockedBy'] ?? []);
    });
  }

  static Stream<bool> chatBlockedStream({required String roomId}) {
    return _rooms.doc(roomId).snapshots().map((s) {
      if (!s.exists) return false;
      final blockedBy = List<String>.from(s.data()?['blockedBy'] ?? []);
      return blockedBy.isNotEmpty;
    });
  }

  static Stream<Map<String, dynamic>> contactRequestStream(
      {required String roomId}) {
    return _rooms.doc(roomId).snapshots().map((s) {
      if (!s.exists) {
        return {
          'status': 'none',
          'senderId': '',
          'receiverId': '',
          'enquirySenderId': '',
        };
      }
      final d = s.data()!;
      return {
        'status': d['contactRequestStatus']?.toString() ?? 'none',
        'senderId': d['contactRequestSenderId']?.toString() ?? '',
        'receiverId': d['contactRequestReceiverId']?.toString() ?? '',
        'enquirySenderId': d['enquirySenderId']?.toString() ?? '',
        'createdAt': d['contactRequestCreatedAt'],
      };
    });
  }

  static Future<void> sendContactRequest({
    required String roomId,
    required String senderId,
    required String receiverId,
  }) async {
    await _rooms.doc(roomId).set({
      'contactRequestStatus': 'pending',
      'contactRequestSenderId': senderId.trim(),
      'contactRequestReceiverId': receiverId.trim(),
      'contactRequestCreatedAt': FieldValue.serverTimestamp(),
      'contactRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> acceptContactRequest({required String roomId}) async {
    await _rooms.doc(roomId).set({
      'contactRequestStatus': 'accepted',
      'contactRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> declineContactRequest({required String roomId}) async {
    await _rooms.doc(roomId).set({
      'contactRequestStatus': 'declined',
      'contactRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================================
  // SINGLE WRITE PATH FOR ALL MESSAGE TYPES
  // ============================================================
  //
  // - blocked check + receiver lookup (uses cache when offline)
  // - message starts as delivered:false. The RECEIVER's app flips it
  //   to true (startDeliveryTracking / markRoomAsRead), which is what
  //   turns the single tick into a double grey tick.
  // - unreadCounts uses a NESTED map so set(merge:true) increments
  //   unreadCounts.<receiverId> correctly (a dotted key inside set()
  //   would create a literal field named "unreadCounts.123").
  // - commit is NOT awaited: offline, commit() only completes when the
  //   server acknowledges. The local write shows instantly with
  //   metadata.hasPendingWrites == true (single tick).
  // ============================================================

  static Future<void> _sendToRoom({
    required String roomId,
    required String senderId,
    required String messageType,
    required String lastMessageText,
    required Map<String, dynamic> extraData,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();
    if (cleanRoomId.isEmpty || cleanSenderId.isEmpty) return;

    final roomRef = _rooms.doc(cleanRoomId);

    String receiverId = '';

    try {
      final roomSnap = await roomRef.get();
      if (!roomSnap.exists) throw Exception('Chat room does not exist');

      final roomData = roomSnap.data()!;
      final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);
      if (blockedBy.isNotEmpty) throw Exception('This chat is blocked.');

      final users = List<String>.from(roomData['users'] ?? []);
      receiverId = users.firstWhere(
            (id) => id != cleanSenderId,
        orElse: () => '',
      );
    } on FirebaseException catch (e) {
      // Offline with nothing cached: fall back to parsing the room id.
      debugPrint('[CHAT] room lookup failed: ${e.code}');
    }

    if (receiverId.isEmpty) {
      final parts = cleanRoomId.split('_');
      if (parts.length >= 2) {
        receiverId = (parts[0] == cleanSenderId) ? parts[1] : parts[0];
      }
    }

    final messageRef = roomRef.collection('messages').doc();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(messageRef, {
      'messageType': messageType,
      'senderId': cleanSenderId,
      'receiverId': receiverId,
      'createdAt': now,
      'isDeleted': false,
      'isEdited': false,
      'deletedFor': <String>[],
      'delivered': false,
      'read': false,
      'readBy': <String>[],
      ...extraData,
    });

    final roomUpdate = <String, dynamic>{
      'lastMessage': lastMessageText,
      'lastMessageTime': now,
      'lastMessageSenderId': cleanSenderId,
      'lastMessageRead': false,
      'lastMessageDelivered': false,
      'lastMessageDeleted': false,
      'lastMessageId': messageRef.id,
      'updatedAt': now,
    };

    if (receiverId.isNotEmpty) {
      roomUpdate['unreadCounts'] = {
        receiverId: FieldValue.increment(1),
      };
    }

    batch.set(roomRef, roomUpdate, SetOptions(merge: true));

    unawaited(batch.commit().catchError((e) {
      debugPrint('[CHAT] send commit error: $e');
    }));
  }

  // ============================================================
  // MESSAGING APIs
  // ============================================================

  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String message,
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;

    await _sendToRoom(
      roomId: roomId,
      senderId: senderId,
      messageType: 'text',
      lastMessageText: cleanMessage,
      extraData: {'message': cleanMessage},
    );
  }

  static Future<void> sendLocationMessage({
    required String roomId,
    required String senderId,
    required double latitude,
    required double longitude,
    String address = '',
  }) async {
    final msg = address.isNotEmpty ? address : 'Shared location';
    await _sendToRoom(
      roomId: roomId,
      senderId: senderId,
      messageType: 'location',
      lastMessageText: '📍 Location',
      extraData: {
        'message': msg,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  /// Image + optional caption = ONE message.
  static Future<void> sendImageMessageWithUrl({
    required String roomId,
    required String senderId,
    required String imageUrl,
    String caption = '',
  }) async {
    final cleanCaption = caption.trim();
    final lastMsg = cleanCaption.isNotEmpty ? '📷 $cleanCaption' : '📷 Photo';

    await _sendToRoom(
      roomId: roomId,
      senderId: senderId,
      messageType: 'image',
      lastMessageText: lastMsg,
      extraData: {
        'message': cleanCaption,
        'imageUrl': imageUrl,
      },
    );
  }

  static Future<void> sendVoiceMessage({
    required String roomId,
    required String senderId,
    required String audioUrl,
    required String duration,
  }) async {
    await _sendToRoom(
      roomId: roomId,
      senderId: senderId,
      messageType: 'audio',
      lastMessageText: '🎤 Voice message',
      extraData: {
        'message': '',
        'audioUrl': audioUrl,
        'duration': duration,
      },
    );
  }

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  static Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    String? currentUserId,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanMsgId = messageId.trim();
    final cleanText = newText.trim();
    if (cleanRoomId.isEmpty || cleanMsgId.isEmpty || cleanText.isEmpty) return;

    final roomRef = _rooms.doc(cleanRoomId);
    final messageRef = roomRef.collection('messages').doc(cleanMsgId);

    final snap = await messageRef.get();
    if (!snap.exists) return;

    final d = snap.data()!;
    if (currentUserId != null &&
        d['senderId']?.toString() != currentUserId.trim()) {
      throw Exception('You can edit only your own messages.');
    }
    if (d['isDeleted'] == true) {
      throw Exception('Deleted message cannot be edited.');
    }
    if ((d['messageType']?.toString() ?? 'text') != 'text') {
      throw Exception('Only text messages can be edited.');
    }
    if ((d['message']?.toString() ?? '') == cleanText) return;

    final batch = _firestore.batch();

    // read / delivered are NOT touched, so an already-seen message stays seen
    batch.update(messageRef, {
      'message': cleanText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });

    final roomSnap = await roomRef.get();
    if (roomSnap.exists &&
        (roomSnap.data()?['lastMessageId']?.toString() ?? '') == cleanMsgId) {
      batch.update(roomRef, {
        'lastMessage': cleanText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    unawaited(batch.commit().catchError((e) {
      debugPrint('[CHAT] edit commit error: $e');
    }));
  }

  // ============================================================
  // STREAMS & UTILS
  // ============================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> chatRoomsStream(String userId) {
    return _rooms.where('users', arrayContains: userId).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots(includeMetadataChanges: true);
  }

  // ============================================================
  // DELIVERY TRACKING (receiver side)
  // ============================================================
  //
  // Call ChatService.startDeliveryTracking(userId) once after login /
  // app start (e.g. in your home screen initState) and
  // stopDeliveryTracking() on logout.
  //
  // When the receiver's app is running and gets a new message, it flips
  // delivered -> true, so the sender sees the DOUBLE GREY tick.
  // ============================================================

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _deliverySub;

  static void startDeliveryTracking(String userId) {
    final me = userId.trim();
    if (me.isEmpty) return;

    _deliverySub?.cancel();

    _deliverySub = _rooms
        .where('users', arrayContains: me)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        if (doc.metadata.hasPendingWrites) continue;

        final lastSender = d['lastMessageSenderId']?.toString() ?? '';
        if (lastSender.isEmpty || lastSender == me) continue;
        if (d['lastMessageDelivered'] == true) continue;

        markDelivered(roomId: doc.id, userId: me);
      }
    }, onError: (e) => debugPrint('[CHAT] delivery listener error: $e'));
  }

  static void stopDeliveryTracking() {
    _deliverySub?.cancel();
    _deliverySub = null;
  }

  static Future<void> markDelivered({
    required String roomId,
    required String userId,
  }) async {
    try {
      final roomRef = _rooms.doc(roomId);

      final snap = await roomRef
          .collection('messages')
          .where('delivered', isEqualTo: false)
          .get();

      final docs = snap.docs
          .where((d) => d.data()['senderId']?.toString() != userId)
          .toList();

      final batch = _firestore.batch();
      for (final d in docs.take(400)) {
        batch.update(d.reference, {'delivered': true});
      }
      batch.set(
        roomRef,
        {'lastMessageDelivered': true},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e) {
      debugPrint('[CHAT] markDelivered error: $e');
    }
  }

  // ============================================================
  // MARK ROOM AS READ (receiver side)
  // ============================================================
  //
  // Uses a single-field query (no composite index needed) and filters
  // senderId on the client. Errors are logged, never swallowed silently.
  // ============================================================

  static Future<void> markRoomAsRead({
    required String roomId,
    required String userId,
  }) async {
    final rid = roomId.trim();
    final uid = userId.trim();
    if (rid.isEmpty || uid.isEmpty) return;

    try {
      final roomRef = _rooms.doc(rid);
      final roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;
      final room = roomSnap.data()!;

      final unreadMap = room['unreadCounts'];
      final currentUnread = unreadMap is Map
          ? (int.tryParse(unreadMap[uid]?.toString() ?? '0') ?? 0)
          : 0;

      final snap = await roomRef
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      final docs = snap.docs
          .where((d) => d.data()['senderId']?.toString() != uid)
          .toList();

      if (docs.isEmpty && currentUnread == 0) return;

      final lastFromOther =
          (room['lastMessageSenderId']?.toString() ?? '') != uid;

      final batch = _firestore.batch();

      for (final d in docs.take(400)) {
        batch.update(d.reference, {
          'read': true,
          'delivered': true,
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }

      batch.set(
        roomRef,
        {
          'unreadCounts': {uid: 0},
          'seenBy': FieldValue.arrayUnion([uid]),
          if (lastFromOther) 'lastMessageRead': true,
          if (lastFromOther) 'lastMessageDelivered': true,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('[CHAT] markRoomAsRead error: $e');
    }
  }

  static Stream<Map<String, Map<String, int>>> enquiryCountsStream(String userId) {
    return _rooms.where('users', arrayContains: userId).snapshots().map((snapshot) {
      final Map<String, int> seen = {};
      final Map<String, int> total = {};
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final seenBy = List<String>.from(d['seenBy'] ?? []);
        final p1 = d['postId']?.toString() ?? '';
        final p2 = d['matchedPostId']?.toString() ?? '';

        if (p1.isNotEmpty) {
          total[p1] = (total[p1] ?? 0) + 1;
          if (seenBy.contains(userId)) seen[p1] = (seen[p1] ?? 0) + 1;
        }
        if (p2.isNotEmpty && p2 != p1) {
          total[p2] = (total[p2] ?? 0) + 1;
          if (seenBy.contains(userId)) seen[p2] = (seen[p2] ?? 0) + 1;
        }
      }
      return {'seen': seen, 'total': total};
    });
  }

  static Future<void> deleteForEveryone({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    final mRef = _rooms.doc(roomId).collection('messages').doc(messageId);
    final s = await mRef.get();
    if (!s.exists) return;
    if (s.data()?['senderId'] != currentUserId) {
      throw Exception('You can delete only your own messages.');
    }

    await mRef.update({'isDeleted': true, 'message': 'This message was deleted'});

    final latest = await _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (latest.docs.isEmpty) {
      await _rooms.doc(roomId).update({'lastMessage': '', 'lastMessageId': ''});
    } else {
      final d = latest.docs.first.data();
      String msg = d['isDeleted'] == true ? 'This message was deleted' : (d['message'] ?? '');
      if (d['isDeleted'] != true) {
        if (d['messageType'] == 'item') msg = 'Item shared';
        if (d['messageType'] == 'location') msg = '📍 Location';
        if (d['messageType'] == 'audio') msg = '🎤 Voice message';
        if (d['messageType'] == 'image') {
          final cap = d['message']?.toString().trim() ?? '';
          msg = cap.isNotEmpty ? '📷 $cap' : '📷 Photo';
        }
      }

      await _rooms.doc(roomId).update({
        'lastMessage': msg,
        'lastMessageTime': d['createdAt'],
        'lastMessageSenderId': d['senderId'],
        'lastMessageDeleted': d['isDeleted'] == true,
        'lastMessageId': latest.docs.first.id,
      });
    }
  }

  static Future<void> deleteForMe({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    final mRef = _rooms.doc(roomId).collection('messages').doc(messageId);
    await mRef.update({
      'deletedFor': FieldValue.arrayUnion([currentUserId])
    });
  }

  static Future<void> clearChat({
    required String roomId,
    required String currentUserId,
  }) async {
    final msgs = await _rooms.doc(roomId).collection('messages').get();
    if (msgs.docs.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final doc in msgs.docs) {
      batch.update(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([currentUserId])
      });
      if (++count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
}