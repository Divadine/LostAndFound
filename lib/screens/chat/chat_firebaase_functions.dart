import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

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
  // MESSAGING
  // ============================================================

  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String message,
  }) async {
    final cleanRoomId = roomId.trim();
    final cleanSenderId = senderId.trim();
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;

    final roomRef = _rooms.doc(cleanRoomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Chat room does not exist');

    final roomData = roomSnapshot.data()!;
    final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) throw Exception('This chat is blocked.');

    final users = List<String>.from(roomData['users'] ?? []);
    final receiverId = users.firstWhere((id) => id != cleanSenderId, orElse: () => '');
    if (receiverId.isEmpty) throw Exception('Receiver user not found');

    final messageRef = roomRef.collection('messages').doc();
    await messageRef.set({
      'messageType': 'text',
      'senderId': cleanSenderId,
      'message': cleanMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final unreadCounts = Map<String, dynamic>.from(roomData['unreadCounts'] ?? {});
    unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;

    await roomRef.set({
      'lastMessage': cleanMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': cleanSenderId,
      'lastMessageRead': false,
      'lastMessageDelivered': true,
      'lastMessageDeleted': false,
      'lastMessageId': messageRef.id,
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));
  }

  static Future<void> sendLocationMessage({
    required String roomId,
    required String senderId,
    required double latitude,
    required double longitude,
    String address = '',
  }) async {
    final roomRef = _rooms.doc(roomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Chat room does not exist');

    final roomData = roomSnapshot.data()!;
    final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) throw Exception('This chat is blocked.');

    final users = List<String>.from(roomData['users'] ?? []);
    final receiverId = users.firstWhere((id) => id != senderId, orElse: () => '');

    final messageRef = roomRef.collection('messages').doc();
    await messageRef.set({
      'messageType': 'location',
      'senderId': senderId,
      'message': address.isNotEmpty ? address : 'Shared location',
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final unreadCounts = Map<String, dynamic>.from(roomData['unreadCounts'] ?? {});
    unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;

    await roomRef.set({
      'lastMessage': '📍 Location',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'lastMessageRead': false,
      'lastMessageDelivered': true,
      'lastMessageDeleted': false,
      'lastMessageId': messageRef.id,
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));
  }

  static Future<void> sendImageMessageWithUrl({
    required String roomId,
    required String senderId,
    required String imageUrl,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Chat room does not exist');

    final roomData = roomSnapshot.data()!;
    final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) throw Exception('This chat is blocked.');

    final users = List<String>.from(roomData['users'] ?? []);
    final receiverId = users.firstWhere((id) => id != senderId, orElse: () => '');

    final messageRef = roomRef.collection('messages').doc();
    await messageRef.set({
      'messageType': 'image',
      'senderId': senderId,
      'message': '',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final unreadCounts = Map<String, dynamic>.from(roomData['unreadCounts'] ?? {});
    unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;

    await roomRef.set({
      'lastMessage': '📷 Photo',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'lastMessageRead': false,
      'lastMessageDelivered': true,
      'lastMessageDeleted': false,
      'lastMessageId': messageRef.id,
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));
  }

  static Future<void> sendVoiceMessage({
    required String roomId,
    required String senderId,
    required String audioUrl,
    required String duration,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Chat room does not exist');

    final roomData = roomSnapshot.data()!;
    final blockedBy = List<String>.from(roomData['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) throw Exception('This chat is blocked.');

    final users = List<String>.from(roomData['users'] ?? []);
    final receiverId = users.firstWhere((id) => id != senderId, orElse: () => '');

    final messageRef = roomRef.collection('messages').doc();
    await messageRef.set({
      'messageType': 'audio',
      'senderId': senderId,
      'message': '',
      'audioUrl': audioUrl,
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedFor': <String>[],
      'delivered': true,
      'read': false,
      'readBy': <String>[],
    });

    final unreadCounts = Map<String, dynamic>.from(roomData['unreadCounts'] ?? {});
    unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;

    await roomRef.set({
      'lastMessage': '🎤 Voice message',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'lastMessageRead': false,
      'lastMessageDelivered': true,
      'lastMessageDeleted': false,
      'lastMessageId': messageRef.id,
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));
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
        .snapshots();
  }

  static Future<void> markRoomAsRead({
    required String roomId,
    required String userId,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) return;

    final roomData = roomSnapshot.data()!;
    final unreadCounts = Map<String, dynamic>.from(roomData['unreadCounts'] ?? {});
    unreadCounts[userId] = 0;

    await roomRef.set({
      'unreadCounts': unreadCounts,
      'seenBy': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));

    final msgs = await roomRef
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .get();

    if (msgs.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in msgs.docs) {
        final rb = List<String>.from(doc.data()['readBy'] ?? []);
        if (!rb.contains(userId)) {
          rb.add(userId);
          batch.update(doc.reference, {'read': true, 'readBy': rb});
        }
      }
      await batch.commit();
    }

    final lastSender = roomData['lastMessageSenderId']?.toString() ?? '';
    if (lastSender.isNotEmpty && lastSender != userId) {
      await roomRef.set({'lastMessageRead': true}, SetOptions(merge: true));
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
      if (d['messageType'] == 'item') msg = 'Item shared';
      if (d['messageType'] == 'location') msg = '📍 Location';
      if (d['messageType'] == 'image') msg = '📷 Photo';

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
