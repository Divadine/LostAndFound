import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
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
import 'package:lost_and_found/shared_widgets/app_audio_player.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';

import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/services/app_recorder_service.dart';

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
  final String itemPostId;
  final String matchedPostId;
  final String enquirySenderId;

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
    this.itemPostId = '',
    this.matchedPostId = '',
    this.enquirySenderId = '',
  });

  factory IndividualChatScreen.fromArgs(
      Map<String, dynamic> args,
      ) {
    return IndividualChatScreen(
      roomId: args['roomId']?.toString() ?? '',
      currentUserId:
      args['currentUserId']?.toString() ?? '',
      otherUserId:
      args['otherUserId']?.toString() ?? '',
      otherUserName:
      args['otherUserName']?.toString() ??
          'User ${args['otherUserId']}',
      otherUserAvatar:
      args['otherUserAvatar']?.toString() ?? '',
      otherUserPhone:
      args['otherUserPhone']?.toString() ?? '',
      itemName:
      args['itemName']?.toString() ?? '',
      itemImage:
      args['itemImage']?.toString() ?? '',
      itemLocation:
      args['itemLocation']?.toString() ?? '',
      itemPostDate:
      args['itemPostDate']?.toString() ?? '',
      itemPostId:
      args['itemPostId']?.toString() ?? '',
      matchedPostId:
      args['matchedPostId']?.toString() ?? '',
      enquirySenderId:
      args['enquirySenderId']?.toString() ?? '',
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? selectedMessageId;
  Map<String, dynamic>? _selectedMessageData;
  String? _editingMessageId;

  String _createdRoomId = '';
  String get _effectiveRoomId =>
      widget.roomId.trim().isNotEmpty ? widget.roomId.trim() : _createdRoomId;

  Map<String, dynamic>? _pendingAttachment;

  bool _showSafetyCard = true;

  String _otherUserPhone = '';
  bool _phoneLoading = false;

  bool _contactDialogShowing = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  Stream<List<String>>? _blockedByStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  Stream<Map<String, dynamic>>? _contactRequestStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;

  String _otherUserAvatar = '';
  DateTime? _clearedAt;

  RecorderState _lastRecorderState = RecorderState.idle;

  final AuthControllers _authController =
  AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  @override
  void initState() {
    super.initState();

    _otherUserAvatar = widget.otherUserAvatar.trim();

    _otherUserPhone =
        widget.otherUserPhone.trim();

    _loadSafetyCardStatus();
    _initConnectivityListener();
    _loadPhoneAndInitialize();

    ChatService.markRoomAsRead(
      roomId: _effectiveRoomId,
      userId: widget.currentUserId,
    );

    _initStreams();

    _lastRecorderState = AppRecorderService.instance.state;
    AppRecorderService.instance.addListener(_onRecorderChanged);
    AppRecorderService.instance.deleteRecording();
  }

  Future<void> _loadSafetyCardStatus() async {
    final dismissed = AppPreferences.getSafetyCardDismissed();

    if (!mounted) return;

    setState(() {
      _showSafetyCard = !dismissed;
    });
  }

  void _initStreams() {
    _blockedByStream = ChatService.chatBlockedByStream(roomId: _effectiveRoomId);
    _messagesStream = ChatService.messagesStream(_effectiveRoomId);
    _contactRequestStream = ChatService.contactRequestStream(roomId: _effectiveRoomId);

    _roomSub?.cancel();
    if (_effectiveRoomId.isNotEmpty) {
      _roomSub = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(_effectiveRoomId)
          .snapshots()
          .listen((snap) {
        if (!snap.exists || !mounted) return;
        final data = snap.data();
        if (data == null) return;

        final clearedAtMap = data['clearedAt'];
        if (clearedAtMap is Map) {
          final userClearedAt = clearedAtMap[widget.currentUserId];
          if (userClearedAt is Timestamp) {
            final newClearedAt = userClearedAt.toDate();
            if (_clearedAt != newClearedAt) {
              setState(() {
                _clearedAt = newClearedAt;
              });
            }
          }
        }

        final participants = Map<String, dynamic>.from(data['participants'] ?? {});
        final otherP = participants[widget.otherUserId];
        if (otherP is Map) {
          final avatar = otherP['avatar']?.toString().trim() ?? '';
          if (avatar != _otherUserAvatar) {
            setState(() {
              _otherUserAvatar = avatar;
            });
          }
        }
      });
    }

    _messagesSub?.cancel();
    if (_effectiveRoomId.isNotEmpty) {
      _messagesSub = _messagesStream?.listen((snapshot) {
        if (!mounted) return;
        final hasUnreadFromOther = snapshot.docs.any((doc) {
          final d = doc.data();
          return d['senderId']?.toString() != widget.currentUserId &&
              d['read'] != true;
        });
        if (hasUnreadFromOther) {
          ChatService.markRoomAsRead(
            roomId: _effectiveRoomId,
            userId: widget.currentUserId,
          );
        }
      });
    }

    if (widget.currentUserId.trim().isNotEmpty) {
      ChatService.startDeliveryTracking(widget.currentUserId);
    }
  }

  void _onRecorderChanged() {
    if (!mounted) return;
    final newState = AppRecorderService.instance.state;
    if (newState != _lastRecorderState) {
      setState(() {
        _lastRecorderState = newState;
      });
    }
  }

  @override
  void didUpdateWidget(covariant IndividualChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _initStreams();
      _loadPhoneAndInitialize();
      ChatService.markRoomAsRead(
        roomId: _effectiveRoomId,
        userId: widget.currentUserId,
      );
    }
  }

  void _initConnectivityListener() async {
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOfflineStatus);
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;
    setState(() {
      _isOffline = offline;
    });
  }

  Future<void> _loadPhoneAndInitialize() async {
    await _loadOtherUserPhone();

    if (!mounted) return;

    await _initializeChat();
  }

  Future<void> _loadOtherUserPhone() async {
    if (_phoneLoading) return;

    _phoneLoading = true;

    try {
      final navigationPhone =
      widget.otherUserPhone.trim();

      if (navigationPhone.isNotEmpty) {
        _setPhone(navigationPhone);

        await _savePhoneToRoom(
          navigationPhone,
        );

        return;
      }

      if (_effectiveRoomId.isNotEmpty &&
          widget.otherUserId.trim().isNotEmpty) {
        final firestorePhone =
        await ChatService.getParticipantPhone(
          roomId: _effectiveRoomId,
          userId: widget.otherUserId,
        );

        if (firestorePhone.trim().isNotEmpty) {
          _setPhone(firestorePhone.trim());
          return;
        }
      }

      final otherUserId =
      int.tryParse(
        widget.otherUserId.trim(),
      );

      if (otherUserId == null) return;

      final response =
      await _authController.getProfile(
        userId: otherUserId,
      );

      if (response.status == 1 &&
          response.data != null) {
        final profilePhone =
            response.data!.mobile
                ?.toString()
                .trim() ??
                '';

        if (profilePhone.isNotEmpty) {
          _setPhone(profilePhone);

          await _savePhoneToRoom(
            profilePhone,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[PHONE] ERROR: $e',
      );
    } finally {
      _phoneLoading = false;
    }
  }

  void _setPhone(String phone) {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) return;

    _otherUserPhone = cleanPhone;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _savePhoneToRoom(
      String phone,
      ) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty ||
        _effectiveRoomId.isEmpty ||
        widget.otherUserId.trim().isEmpty) {
      return;
    }

    try {
      await ChatService.updateParticipantPhone(
        roomId: _effectiveRoomId,
        userId: widget.otherUserId,
        phone: cleanPhone,
      );
    } catch (e) {
      debugPrint(
        '[PHONE] SAVE ERROR: $e',
      );
    }
  }

  Future<void> _initializeChat() async {
    try {
      String roomId = widget.roomId.trim();

      if (roomId.isEmpty) {
        // If roomId is missing, we must generate it and ensure it exists
        roomId = await ChatService.getOrCreateChatRoom(
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
          postId: widget.itemPostId.isNotEmpty
              ? widget.itemPostId
              : _extractPostId(),
          matchedPostId: widget.matchedPostId,
          enquirySenderId: widget.enquirySenderId.isNotEmpty
              ? widget.enquirySenderId
              : widget.currentUserId,
          itemName: widget.itemName,
          itemImage: widget.itemImage,
          itemLocation: widget.itemLocation,
          itemPostDate: widget.itemPostDate,
          otherUserName: widget.otherUserName,
          otherUserAvatar: widget.otherUserAvatar,
          otherUserPhone: _otherUserPhone,
        );

        if (mounted && roomId.isNotEmpty && roomId != _createdRoomId) {
          _createdRoomId = roomId;
          _initStreams();
          setState(() {});
          ChatService.markRoomAsRead(
            roomId: _effectiveRoomId,
            userId: widget.currentUserId,
          );
        }
      } else {
        // Room ID provided, just ensure metadata is merged/updated if necessary
        // without recreating the whole room structure.
        await ChatService.getOrCreateChatRoom(
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
          postId: widget.itemPostId.isNotEmpty
              ? widget.itemPostId
              : _extractPostId(),
          matchedPostId: widget.matchedPostId,
          enquirySenderId: widget.enquirySenderId,
          itemName: widget.itemName,
          itemImage: widget.itemImage,
          itemLocation: widget.itemLocation,
          itemPostDate: widget.itemPostDate,
          otherUserName: widget.otherUserName,
          otherUserAvatar: widget.otherUserAvatar,
          otherUserPhone: _otherUserPhone,
        );
      }

      await ChatService.ensureItemCardFromRoom(
        roomId: roomId,
        currentUserId: widget.currentUserId,
      );

      if (_effectiveRoomId.isNotEmpty) {
        await ChatService.setParticipantAvatar(
          _effectiveRoomId,
          widget.currentUserId,
          AppPreferences.getUserAvatar() ?? '',
        );
      }

      if (_otherUserPhone.isNotEmpty) {
        await _savePhoneToRoom(_otherUserPhone);
      }
    } catch (e) {
      debugPrint('[CHAT] INITIALIZE ERROR: $e');
    }
  }

  String _extractPostId() {
    final parts =
    widget.roomId.split('_');

    if (parts.length >= 3) {
      return parts.last;
    }

    return '';
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _roomSub?.cancel();
    AppRecorderService.instance.removeListener(_onRecorderChanged);
    _connectivitySub?.cancel();
    textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showNoInternetSnackbar() {
    AppSnackBar.show(
      context: context,
      message: 'No internet connection',
      icon: Icons.wifi_off,
    );
  }

  // ============================================================
  // NOTIFY OTHER USER
  // ============================================================
  //
  // Centralized helper so every message type (text, image, location,
  // address, voice) reliably triggers a push notification to the
  // receiver. Previously this was only called for the 'address'
  // attachment type, which is why plain text / image / location /
  // voice messages were never notifying the other user.
  // ============================================================

  Future<void> _notifyOtherUser({String? preview}) async {
    final receiverId = int.tryParse(widget.otherUserId);

    if (receiverId == null) {
      debugPrint(
        '[FCM] Notification receiver: Invalid receiver ID: ${widget.otherUserId}',
      );
      return;
    }

    debugPrint(
      '[FCM] Notification receiver: $receiverId | sender: ${widget.currentUserId} | preview: ${preview ?? ''}',
    );

    try {
      final notificationResponse = await _authController.sendNotification(
        userId: receiverId,
      );

      debugPrint(
        '[Chat Notification] receiver=${widget.otherUserId}, '
            'sender=${widget.currentUserId}, '
            'preview=${preview ?? ''}, '
            'response=${notificationResponse.message}',
      );
    } catch (e) {
      debugPrint('[Chat Notification] ERROR: $e');
    }
  }

  Future<void> _send() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }

    final text = textController.text.trim();

    if (_editingMessageId != null) {
      if (text.isEmpty) return;
      final editId = _editingMessageId!;
      textController.clear();
      setState(() {
        _editingMessageId = null;
      });

      try {
        await ChatService.editMessage(
          roomId: _effectiveRoomId,
          messageId: editId,
          newText: text,
          currentUserId: widget.currentUserId,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
      return;
    }

    if (text.isEmpty && _pendingAttachment == null) return;

    try {
      if (_pendingAttachment != null) {
        final type = _pendingAttachment!['type'];
        if (type == 'image') {
          final caption = text;
          textController.clear();
          await ChatService.sendImageMessageWithUrl(
            roomId: _effectiveRoomId,
            senderId: widget.currentUserId,
            imageUrl: _pendingAttachment!['url'],
            caption: caption,
          );

          await _notifyOtherUser(
            preview: caption.isNotEmpty ? '📷 $caption' : 'Photo',
          );
        } else if (type == 'location') {
          await ChatService.sendLocationMessage(
            roomId: _effectiveRoomId,
            senderId: widget.currentUserId,
            latitude: _pendingAttachment!['latitude'],
            longitude: _pendingAttachment!['longitude'],
            address: _pendingAttachment!['address'],
          );

          await _notifyOtherUser(preview: 'Location');
        } else if (type == 'address') {
          await ChatService.sendMessage(
            roomId: _effectiveRoomId,
            senderId: widget.currentUserId,
            message: _pendingAttachment!['address'],
          );

          await _notifyOtherUser(
            preview: _pendingAttachment!['address']?.toString(),
          );
        }
        setState(() {
          _pendingAttachment = null;
        });
      } else if (text.isNotEmpty) {
        textController.clear();

        await ChatService.sendMessage(
          roomId: _effectiveRoomId,
          senderId: widget.currentUserId,
          message: text,
        );

        await _notifyOtherUser(preview: text);
      }
    } catch (e) {
      if (!mounted) return;

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

  // Future<void> _handleMicPress() async {
  //   final granted = await AppPermissions().requestMicrophonePermission(context);
  //   if (granted) {
  //     await AppRecorderService.instance.startRecording();
  //   }
  // }
  //
  // void _startVoiceRecording() async {
  //   try {
  //     await AppRecorderService.instance.startRecording();
  //   } catch (e) {
  //     debugPrint("Error starting voice recording: $e");
  //   }
  // }

  Future<void> _stopAndSendVoiceRecording() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }

    try {
      final path = await AppRecorderService.instance.saveRecording();
      if (path == null) return;

      final audioFile = File(path);
      final duration = AppRecorderService.instance.formatDuration(
        AppRecorderService.instance.recordedDuration,
      );

      // Upload to server
      final response = await _authController.createAudio(audio: audioFile);

      if (response.isSuccess && response.data != null) {
        final audioUrl = response.data!.audio;
        await ChatService.sendVoiceMessage(
          roomId: _effectiveRoomId,
          senderId: widget.currentUserId,
          audioUrl: audioUrl,
          duration: duration,
        );

        await _notifyOtherUser(preview: 'Voice message');
      } else {
        throw Exception(response.message.isNotEmpty ? response.message : 'Failed to upload audio');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending voice message: $e')),
      );
    } finally {
      await AppRecorderService.instance.deleteRecording();
    }
  }

  Future<void> _cancelVoiceRecording() async {
    await AppRecorderService.instance.cancelRecording();
  }

  Future<void> _call() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    final phone = _otherUserPhone.trim().replaceAll(RegExp(r'[^\d+]'), '');

    if (phone.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number unavailable'),
        ),
      );

      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    } catch (e) {
      debugPrint('[CALL] ERROR: $e');
    }
  }

  Future<void> _copyPhone() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    final phone =
    _otherUserPhone.trim();

    if (phone.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: phone),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
        Text('Phone number copied'),
      ),
    );
  }

  Future<void> _blockChat() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    await ChatService.blockChat(
      roomId: _effectiveRoomId,
      userId:
      widget.currentUserId,
    );
  }

  Future<void> _unblockChat() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    await ChatService.unblockChat(
      roomId: _effectiveRoomId,
      userId:
      widget.currentUserId,
    );
  }

  Future<void> _clearChat() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    await ChatService.clearChat(
      roomId: _effectiveRoomId,
      currentUserId: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedMessageId == null && _editingMessageId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
            _selectedMessageData = null;
          });
        } else if (_editingMessageId != null) {
          textController.clear();
          setState(() {
            _editingMessageId = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: AppColors.primaryColor,
        ),
        body: SafeArea(
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    selectedMessageId != null
                        ? _buildSelectionTopRow()
                        : _buildHeaderRow(),
                    const SizedBox(height: 10),
                    const Divider(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildPhoneRow(),
                            const SizedBox(height: 8),
                            _buildTopItemCard(),
                            const SizedBox(height: 8),
                            _buildSafetyCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildMessagesList(),
                    ],
                  ),
                ),
              ),
              Divider(),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHONE ROW
  // ============================================================

  Widget _buildPhoneRow() {
    return StreamBuilder<
        Map<String, dynamic>>(
      stream: _contactRequestStream,

      builder: (context, snapshot) {
        final data =
            snapshot.data ??
                <String, dynamic>{};

        final status =
            data['status']?.toString() ??
                'none';

        final senderId =
            data['senderId']?.toString() ??
                '';

        final receiverId =
            data['receiverId']?.toString() ??
                '';

        DateTime requestTime =
        DateTime.now();

        final createdAt =
        data['createdAt'];

        if (createdAt is Timestamp) {
          requestTime =
              createdAt.toDate();
        }

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

        if (isRequestForMe &&
            !_contactDialogShowing) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (!mounted ||
                _contactDialogShowing) {
              return;
            }

            _showContactRequestDialog(
              senderName:
              widget.otherUserName,
              requestTime:
              requestTime,
            );
          });
        }

        if (status == 'accepted') {
          return _buildAcceptedPhoneRow();
        }

        if (isMyRequest) {
          return _buildRequestSentRow();
        }

        return _buildSendRequestRow();
      },
    );
  }

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
            onTap: _isOffline
                ? _showNoInternetSnackbar
                : _onSendPhoneRequest,
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
                  AppColors
                      .primaryColor,
                ),
              ),
              child: AppText(
                text:
                'Send Request',
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
                color:
                AppColors
                    .primaryColor,
              ),
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

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
              AppColors.requestColor,
              borderRadius:
              BorderRadius.circular(
                20,
              ),
              // border: Border.all(
              //   color:
              //   AppColors.requestColor,
              // ),
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
                    color:Color(0xff96550E)
                  // AppColors
                  //     .requestColor,
                ),
                const SizedBox(width: 5),
                AppIconWidget(
                    assetPath:
                    AssetImages
                        .requestSent,
                    size: 13,
                    color:Color(0xff96550E)
                ),
              ],
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(50);
  }

  Widget _buildAcceptedPhoneRow() {
    if (_phoneLoading &&
        _otherUserPhone.isEmpty) {
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
                'Loading phone number...',
                fontSize: 12,
              ),
            ),
            SizedBox(
              width: 16,
              height: 16,
              child: _isOffline
                  ? const NoInternetWidget(size: 16, showText: false)
                  : const CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ).pad(8),
      ).padHorizontal(50);
    }

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
              ),
            ),
            InkWell(
              onTap: () async {
                await _loadOtherUserPhone();
              },
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
              fontSize: 12,
            ),
          ),

          InkWell(
            onTap: _copyPhone,
            child: Row(
              spacing: 5,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconWidget(
                  assetPath: AssetImages.copy,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const AppText(
                  text: 'Copy',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          InkWell(
            onTap: _call,
            child: Row(
              spacing: 5,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconWidget(
                  assetPath: AssetImages.call,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const AppText(
                  text: 'Call',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ).pad(8),
    ).padHorizontal(20);
  }

  String _maskPhone(String phone) {
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

  Future<void>
  _onSendPhoneRequest() async {
    if (_isOffline) {
      _showNoInternetSnackbar();
      return;
    }
    try {
      await ChatService.sendContactRequest(
        roomId: _effectiveRoomId,
        senderId:
        widget.currentUserId,
        receiverId:
        widget.otherUserId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Request sent'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
  // CONTACT REQUEST
  // ============================================================

  void _showContactRequestDialog({
    required String senderName,
    required DateTime requestTime,
  }) {
    if (!mounted ||
        _contactDialogShowing) {
      return;
    }

    _contactDialogShowing = true;

    AppDialogue.showPopup(
      context: context,
      content: ChatSendRequest(
        senderName: senderName,
        requestTime: requestTime,

        onDecline: () async {
          if (_isOffline) {
            _showNoInternetSnackbar();
            return;
          }
          try {
            await ChatService
                .declineContactRequest(
              roomId: _effectiveRoomId,
            );

            if (!mounted) return;

            Navigator.of(context).pop();
          } finally {
            _contactDialogShowing =
            false;
          }
        },

        onAccept: () async {
          if (_isOffline) {
            _showNoInternetSnackbar();
            return;
          }
          try {
            await ChatService
                .acceptContactRequest(
              roomId: _effectiveRoomId,
            );

            await _loadOtherUserPhone();

            if (!mounted) return;

            Navigator.of(context).pop();
          } finally {
            _contactDialogShowing =
            false;
          }
        },
      ),
    ).whenComplete(() {
      _contactDialogShowing =
      false;
    });
  }

  // ============================================================
  // ITEM CARD
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
        imgUrl: widget.itemImage,
        title:
        widget.itemName.trim().isNotEmpty
            ? widget.itemName
            : 'Item',
        location:
        widget.itemLocation,
        date:
        widget.itemPostDate,
        postId: '',
        showPostId: false,
        onTap: () {},
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(_effectiveRoomId)
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
          imgUrl: itemImage,
          title:
          itemName.isNotEmpty
              ? itemName
              : 'Item',
          location: itemLocation,
          date: itemPostDate,
          postId: '',
          showPostId: false,
          onTap: () {},
        );
      },
    );
  }

  // ============================================================
  // SAFETY
  // ============================================================

  Widget _buildSafetyCard() {
    if (!_showSafetyCard) return const SizedBox.shrink();

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
            onTap: () async {
              setState(() {
                _showSafetyCard = false;
              });

              await AppPreferences.setSafetyCardDismissed(true);
            },
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (
          context,
          snapshot,
          ) {
        // ============================================================
        // LOADING
        // ============================================================

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _isOffline
              ? const NoInternetWidget()
              : const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ============================================================
        // ERROR
        // ============================================================

        if (snapshot.hasError) {
          return const Center(
            child: AppText(
              text: 'Unable to load messages',
              fontSize: 12,
            ),
          );
        }

        // ============================================================
        // NO DATA
        // ============================================================

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // ============================================================
        // MESSAGES
        // ============================================================
        //
        // IMPORTANT:
        //
        // Do NOT remove messages from the list using deletedFor.
        //
        // Delete for Me:
        //   deletedFor contains currentUserId
        //   -> show "This message was deleted"
        //
        // Delete for Everyone:
        //   isDeleted == true
        //   -> show "This message was deleted"
        //
        // Therefore, we keep ALL documents here.
        // ============================================================

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          if (_clearedAt != null && createdAt is Timestamp) {
            if (createdAt.toDate().isBefore(_clearedAt!)) {
              return false;
            }
          }
          return true;
        }).toList();

        // ============================================================
        // MARK MESSAGES AS READ
        // ============================================================

        final hasUnreadFromOther = snapshot.data!.docs.any((doc) {
          final d = doc.data();

          return d['senderId']?.toString() != widget.currentUserId &&
              d['read'] != true;
        });

        if (hasUnreadFromOther) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ChatService.markRoomAsRead(
                roomId: _effectiveRoomId,
                userId: widget.currentUserId,
              );
            }
          });
        }

        // ============================================================
        // EMPTY CHAT
        // ============================================================

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 100,
              ),
              child: Column(
                children: [
                  AppIconWidget(
                    assetPath: AssetImages.chatEmpty,
                  ),

                  AppText(
                    text: 'Chat looks fresh!',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),

                  AppText(
                    text: 'start a new conversation anytime!',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.fieldGrey,
                  ),
                ],
              ),
            ),
          );
        }

        // ============================================================
        // BUILD DATE ENTRIES
        // ============================================================

        final entries = _buildEntries(docs);

        // ============================================================
        // SCROLL TO BOTTOM
        // ============================================================

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });

        // ============================================================
        // MESSAGE LIST
        // ============================================================

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),

          itemCount: entries.length,

          itemBuilder: (context, index) {
            final entry = entries[index];

            // ========================================================
            // DATE HEADER
            // ========================================================

            if (entry.isHeader) {
              return _buildDateHeader(
                entry.headerLabel!,
              );
            }

            final doc = entry.doc!;
            final data = doc.data();

            // ========================================================
            // DELETE STATUS
            // ========================================================

            final deletedFor = List<String>.from(
              data['deletedFor'] ?? [],
            );

            final isDeletedForMe = deletedFor.contains(
              widget.currentUserId,
            );

            final isDeletedForEveryone =
                data['isDeleted'] == true;

            // ========================================================
            // DELETE FOR ME / DELETE FOR EVERYONE
            // ========================================================

            if (isDeletedForMe || isDeletedForEveryone) {
              return _buildTextMessage(
                data: {
                  ...data,

                  // Force deleted UI
                  'isDeleted': true,

                  // Force deleted message text
                  'message': 'This message was deleted',
                },
                docId: doc.id,
              );
            }

            // ========================================================
            // MESSAGE TYPE
            // ========================================================

            final messageType =
                data['messageType']?.toString() ?? 'text';

            // ========================================================
            // ITEM MESSAGE
            // ========================================================

            if (messageType == 'item') {
              return const SizedBox.shrink();
            }

            // ========================================================
            // LOCATION MESSAGE
            // ========================================================

            if (messageType == 'location') {
              return _buildLocationMessage(
                data: data,
                docId: doc.id,
              );
            }

            // ========================================================
            // IMAGE MESSAGE
            // ========================================================

            if (messageType == 'image') {
              return _buildImageMessage(
                data: data,
                docId: doc.id,
              );
            }

            // ========================================================
            // AUDIO MESSAGE
            // ========================================================

            if (messageType == 'audio') {
              return _buildAudioMessage(
                data: data,
                docId: doc.id,
              );
            }

            // ========================================================
            // TEXT MESSAGE
            // ========================================================

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
        final dayOnly = DateTime(
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
        _ChatListEntry.message(doc),
      );
    }

    return entries;
  }

  String _dateLabel(DateTime date) {
    final now =
    DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday =
    today.subtract(
      const Duration(days: 1),
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
  // AVATAR & FULLSCREEN HELPERS
  // ============================================================

  Widget _chatAvatar(String? url, {double size = 28}) {
    final cleanUrl = url?.trim() ?? '';
    final isEmpty = cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.fieldGrey,
      child: ClipOval(
        child: !isEmpty
            ? AppCachedNetworkImage(
                imageUrl: cleanUrl,
                height: size,
                width: size,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.person,
                size: size * 0.7,
                color: AppColors.grey,
              ),
      ),
    );
  }

  Widget _withAvatar({
    required bool isMe,
    required Widget child,
  }) {
    final senderAvatar = isMe
        ? (AppPreferences.getUserAvatar() ?? '')
        : _otherUserAvatar;

    return Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          _chatAvatar(senderAvatar, size: 28),
          const SizedBox(width: 6),
        ],
        Flexible(child: child),
        if (isMe) ...[
          const SizedBox(width: 6),
          _chatAvatar(senderAvatar, size: 28),
        ],
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
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
      date =
          timestamp.toDate();
    }

    final time =
    date != null
        ? _formatTime(date)
        : '';

    return GestureDetector(
      onLongPress: () {
        if (isDeleted) return;

        setState(() {
          selectedMessageId = docId;
          _selectedMessageData = data;
        });
      },

      onTap: () {
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
            _selectedMessageData = null;
          });
        }
      },

      child: Container(
        width: double.infinity,
        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: _withAvatar(
            isMe: isMe,
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
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? AppColors.fieldGrey
                          : isMe
                          ? AppColors.chatByMe
                          : AppColors.chatByOther,
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: AppText(
                      text: isDeleted
                          ? 'This message was deleted'
                          : (data['message']?.toString() ?? ''),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDeleted ? AppColors.white : null,
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: time,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (data['read'] == true) ...[
                          const AppText(
                            text: 'Seen',
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 2),
                        ],
                        MessageTick(
                          read: data['read'] == true,
                          delivered: data['delivered'] == true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}

  // ============================================================
  // IMAGE MESSAGE
  // ============================================================

  Widget _buildImageMessage({
    required Map<String, dynamic> data,
    required String docId,
  }) {
    final isMe =
        data['senderId']?.toString() ==
            widget.currentUserId;

    final isSelected =
        selectedMessageId == docId;

    final isDeleted =
        data['isDeleted'] == true;

    if (isDeleted) {
      return _buildTextMessage(
        data: data,
        docId: docId,
      );
    }

    final imageUrl =
        data['imageUrl']?.toString() ??
            data['message']?.toString() ??
            '';

    final messageText = data['message']?.toString().trim() ?? '';
    final caption = (messageText.isNotEmpty && messageText != imageUrl) ? messageText : '';

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
        setState(() {
          selectedMessageId = docId;
          _selectedMessageData = data;
        });
      },

      onTap: () {
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
            _selectedMessageData = null;
          });
        }
      },

      child: Container(
        width: double.infinity,
        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: _withAvatar(
            isMe: isMe,
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
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.chatByMe : AppColors.chatByOther,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () {
                                if (selectedMessageId != null) {
                                  setState(() {
                                    selectedMessageId = null;
                                    _selectedMessageData = null;
                                  });
                                  return;
                                }
                                if (imageUrl.isNotEmpty) {
                                  _showFullScreenImage(context, imageUrl);
                                }
                              },
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.55,
                                  maxHeight: 300,
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      width: 180,
                                      color: AppColors.fieldGrey,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        if (caption.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: AppText(
                              text: caption,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: time,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (data['read'] == true) ...[
                          const AppText(
                            text: 'Seen',
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 2),
                        ],
                        MessageTick(
                          read: data['read'] == true,
                          delivered: data['delivered'] == true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION MESSAGE
  // ============================================================

  Widget _buildLocationMessage({
    required Map<String, dynamic> data,
    required String docId,
  }) {
    final isMe =
        data['senderId']?.toString() ==
            widget.currentUserId;

    final isSelected =
        selectedMessageId == docId;

    final isDeleted =
        data['isDeleted'] == true;

    final latitude =
    _toDouble(data['latitude']);

    final longitude =
    _toDouble(data['longitude']);

    final address =
        data['address']?.toString().trim() ??
            '';

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

    if (isDeleted) {
      return _buildTextMessage(
        data: {
          ...data,
          'message':
          'This location was deleted',
          'isDeleted': true,
        },
        docId: docId,
      );
    }

    return GestureDetector(
      onLongPress: () {
        setState(() {
          selectedMessageId = docId;
          _selectedMessageData = data;
        });
      },

      onTap: () {
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
            _selectedMessageData = null;
          });
          return;
        }

        if (latitude != null &&
            longitude != null) {
          _openLocationInMaps(
            latitude,
            longitude,
          );
        }
      },

      child: Container(
        width: double.infinity,

        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: _withAvatar(
            isMe: isMe,
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
                  // ==================================================
                  // LOCATION CARD
                  // ==================================================

                  Container(
                    width: 250,

                    margin:
                    const EdgeInsets.symmetric(
                      vertical: 2,
                    ),

                    clipBehavior:
                    Clip.antiAlias,

                    decoration:
                    BoxDecoration(
                      color: AppColors.white,

                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),

                      border: Border.all(
                        color:
                        AppColors.fieldGrey,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // ==================================================
                        // MAP
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 145,

                          child: Stack(
                            children: [
                              Container(
                                width:
                                double.infinity,
                                height:
                                double.infinity,

                                decoration:
                                const BoxDecoration(
                                  gradient:
                                  LinearGradient(
                                    begin:
                                    Alignment.topLeft,
                                    end:
                                    Alignment.bottomRight,
                                    colors: [
                                      Color(
                                        0xFFE5EDF0,
                                      ),
                                      Color(
                                        0xFFD8E4E8,
                                      ),
                                    ],
                                  ),
                                ),

                                child:
                                CustomPaint(
                                  painter:
                                  _LocationMapPainter(),
                                ),
                              ),

                              // ==================================================
                              // CENTER LOCATION PIN
                              // ==================================================

                              const Center(
                                child: Icon(
                                  Icons
                                      .location_on,
                                  size: 44,
                                  color: AppColors
                                      .primaryColor,
                                ),
                              ),

                              // ==================================================
                              // MAP LABEL
                              // ==================================================

                              Positioned(
                                left: 10,
                                top: 10,

                                child: Container(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    Colors.white,
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      20,
                                    ),
                                  ),

                                  child:
                                  const Text(
                                    'Location',
                                    style:
                                    TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // ==================================================
                              // OPEN MAP ICON
                              // ==================================================

                              Positioned(
                                right: 10,
                                top: 10,

                                child: Container(
                                  width: 34,
                                  height: 34,

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    Colors.white,
                                    shape:
                                    BoxShape.circle,
                                  ),

                                  child: const Icon(
                                    Icons
                                        .open_in_new,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // LOCATION DETAILS
                        // ==================================================

                        Padding(
                          padding:
                          const EdgeInsets
                              .all(12),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .location_on,
                                    size: 18,
                                    color: AppColors
                                        .primaryColor,
                                  ),

                                  const SizedBox(
                                    width: 6,
                                  ),

                                  const Expanded(
                                    child: Text(
                                      'Shared Location',
                                      style:
                                      TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (address
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  address,
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,

                                  style:
                                  const TextStyle(
                                    fontSize: 11,
                                    color: Colors
                                        .black54,
                                    height: 1.35,
                                  ),
                                ),
                              ],

                              if (latitude != null &&
                                  longitude !=
                                      null) ...[
                                const SizedBox(
                                  height: 7,
                                ),

                                Text(
                                  '${latitude.toStringAsFixed(5)}, '
                                      '${longitude.toStringAsFixed(5)}',

                                  style:
                                  const TextStyle(
                                    fontSize: 10,
                                    color: Colors
                                        .black45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // TIME
                  // ==================================================

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: time,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (data['read'] == true) ...[
                          const AppText(
                            text: 'Seen',
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 2),
                        ],
                        MessageTick(
                          read: data['read'] == true,
                          delivered: data['delivered'] == true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage({
    required Map<String, dynamic> data,
    required String docId,
  }) {
    final isMe =
        data['senderId']?.toString() ==
            widget.currentUserId;

    final isSelected =
        selectedMessageId == docId;

    final isDeleted =
        data['isDeleted'] == true;

    if (isDeleted) {
      return _buildTextMessage(
        data: data,
        docId: docId,
      );
    }

    final audioUrl =
        data['audioUrl']?.toString() ?? '';

    final duration =
        data['duration']?.toString() ?? '0:00';

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
        setState(() {
          selectedMessageId = docId;
          _selectedMessageData = data;
        });
      },

      onTap: () {
        if (selectedMessageId != null) {
          setState(() {
            selectedMessageId = null;
            _selectedMessageData = null;
          });
        }
      },

      child: Container(
        width: double.infinity,
        color: isSelected
            ? AppColors.chatDelete
            : Colors.transparent,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: _withAvatar(
            isMe: isMe,
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
                  if (audioUrl.isNotEmpty)
                    Container(
                      width: 250,
                      margin:
                      const EdgeInsets.symmetric(
                        vertical: 2,
                      ),

                      padding: const EdgeInsets.all(8),

                      decoration:
                      BoxDecoration(
                        color: isMe
                            ? AppColors.chatByMe
                            : AppColors.chatByOther,
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppAudioPlayer(url: audioUrl),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: AppText(
                              text: duration,
                              fontSize: 10,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: time,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (data['read'] == true) ...[
                          const AppText(
                            text: 'Seen',
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 2),
                        ],
                        MessageTick(
                          read: data['read'] == true,
                          delivered: data['delivered'] == true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  Future<void> _openLocationInMaps(
      double latitude,
      double longitude,
      ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
          LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint(
        '[LOCATION] MAP ERROR: $e',
      );
    }
  }

  // ============================================================
  // BOTTOM AREA
  // ============================================================

  Widget _buildBottomArea() {
    final recorderService = AppRecorderService.instance;
    final isRecording = recorderService.isRecording || recorderService.isPaused;

    return StreamBuilder<List<String>>(
      stream: _blockedByStream,
      builder: (
          context,
          snapshot,
          ) {
        final blockedBy = snapshot.data ?? <String>[];
        final isBlocked = blockedBy.isNotEmpty;
        final isBlockedByMe = blockedBy.contains(widget.currentUserId);

        if (isBlocked) {
          return _buildBlockedInlineCard(isBlockedByMe: isBlockedByMe);
        }

        if (isRecording) {
          return _buildChatRecordingUi();
        }

        return Container(
          padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_editingMessageId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: AppText(
                          text: 'Editing message',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          textController.clear();
                          setState(() {
                            _editingMessageId = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 18, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
              if (_pendingAttachment != null) _buildPendingAttachmentPreview(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppContainer(
                    width: 50,
                    height: 50,
                    color: AppColors.fieldGrey.withAlpha(50),
                    widget: InkWell(
                      onTap: () {
                        if (_isOffline) {
                          _showNoInternetSnackbar();
                          return;
                        }
                        AppUiHelper.showBottomSheet(
                          radius: BorderRadius.circular(10),
                          context: context,
                          showHandle: false,
                          showCloseIcon: false,
                          color: AppColors.primaryColor,
                          bgColor: Colors.transparent,
                          iconColor: AppColors.white,
                          child: ChatSharingFiles(
                            roomId: widget.roomId,
                            currentUserId: widget.currentUserId,
                            onAttachmentSelected: (attachment) {
                              if (attachment['type'] == 'address') {
                                final address = attachment['address']?.toString() ?? '';
                                textController.text = address;
                                textController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: address.length),
                                );
                                _focusNode.requestFocus();
                              } else {
                                setState(() {
                                  _pendingAttachment = attachment;
                                });
                              }
                            },
                          ),
                        );
                      },
                      child: Center(
                        child: AppIconWidget(
                          assetPath: AssetImages.add,
                          color: AppColors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppContainer(
                      color: AppColors.fieldGrey.withAlpha(50),
                      widget: AppTextField(
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        borderRadius: BorderRadius.circular(14),
                        borderColor: Colors.transparent,
                        hintStyle: TextStyle(
                            color: AppColors.black
                        ),
                        hintText: 'Write your message..',
                        textController: textController,
                        onChange: (v) {},
                        onSubmit: (v) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: textController,
                    builder: (context, value, child) {
                      return AppContainer(
                        width: 50,
                        height: 50,
                        bgColor: AppColors.primaryColor,
                        widget: InkWell(
                          onTap: _send,
                          child: Center(
                            child: AppIconWidget(
                              assetPath: AssetImages.send,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatRecordingUi() {
    final service = AppRecorderService.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancelVoiceRecording,
            child: AppIconWidget(
              assetPath: AssetImages.recordCancel,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldGrey.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: service,
                    builder: (context, _) {
                      return AppText(
                        text: service.formatDuration(service.elapsed),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AppText(
                      text: "Recording...",
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (service.isPaused) {
                service.resumeRecording();
              } else {
                service.pauseRecording();
              }
            },
            child: AppIconWidget(
              assetPath: service.isPaused
                  ? AssetImages.recordingPlay
                  : AssetImages.recordingPause,
              size: 24,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _stopAndSendVoiceRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachmentPreview() {
    if (_pendingAttachment == null) return const SizedBox.shrink();

    final type = _pendingAttachment!['type'];

    if (type == 'image') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 180,
                  maxHeight: 180,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _pendingAttachment!['url'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: AppColors.fieldGrey,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _pendingAttachment = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget content;
    if (type == 'location') {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.fieldGrey.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on,
                color: AppColors.primaryColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: AppText(
                text: _pendingAttachment!['address'] ?? 'Location',
                fontSize: 12,
                maxLine: 1,
              ),
            ),
          ],
        ),
      );
    } else if (type == 'address') {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.fieldGrey.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home, color: AppColors.primaryColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: AppText(
                text: _pendingAttachment!['address'] ?? 'Address',
                fontSize: 12,
                maxLine: 1,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: content),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _pendingAttachment = null;
              });
            },
          ),
        ],
      ),
    );
  }



  Widget _buildBlockedInlineCard({required bool isBlockedByMe}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: AppIconWidget(
                assetPath: AssetImages.blockChat,
                size: 34,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            text: isBlockedByMe ? 'This chat has been blocked' : 'You have been blocked',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            text: isBlockedByMe
                ? 'You cannot send or receive messages in this chat while it is blocked.'
                : 'You can no longer send or receive messages in this chat.',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
            textAlign: TextAlign.center,
            maxLine: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.fieldGrey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_isOffline) {
                      _showNoInternetSnackbar();
                      return;
                    }
                    await ChatService.clearChat(
                      roomId: _effectiveRoomId,
                      currentUserId: widget.currentUserId,
                      hide: true,
                    );
                    if (mounted) {
                      AppRoutes.pop();
                    }
                  },
                  child: const AppText(
                    text: 'Delete chat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (isBlockedByMe) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_isOffline) {
                        _showNoInternetSnackbar();
                        return;
                      }
                      await _unblockChat();
                    },
                    child: const AppText(
                      text: 'Unblock chat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }



  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => AppRoutes.pop(),

          child: AppIconWidget(
            assetPath: AssetImages.backArrow,
            size: 20,
          ),
        ),

        const SizedBox(width: 20),

        _chatAvatar(_otherUserAvatar, size: 36),

        const SizedBox(width: 15),

        Expanded(
          child: AppText(
            text: widget.otherUserName.isNotEmpty
                ? widget.otherUserName
                : 'User ${widget.otherUserId}',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        StreamBuilder<List<String>>(
          stream: _blockedByStream,
          builder: (context, snapshot) {
            final blockedBy = snapshot.data ?? <String>[];
            final isBlockedByMe = blockedBy.contains(widget.currentUserId);
            final isBlockedByOther = blockedBy.isNotEmpty && !isBlockedByMe;

            return Container(
              height: 30,
              width: 30,

              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.fieldGrey,
                ),
                borderRadius: BorderRadius.circular(10),
              ),

              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,

                icon: AppIconWidget(
                  assetPath: AssetImages.more,
                  size: 20,
                  color: AppColors.black,
                ),

                offset: const Offset(0, 40),

                onSelected: (value) async {
                  if (_isOffline) {
                    _showNoInternetSnackbar();
                    return;
                  }
                  switch (value) {
                    case 'clear':
                      await _clearChat();
                      break;

                    case 'unblock':
                      await _unblockChat();
                      break;

                    case 'block':
                      await _blockChat();
                      break;

                    case 'report':
                      final currentUserId = int.tryParse(widget.currentUserId);

                      if (currentUserId == null) return;

                      AppUiHelper.showBottomSheet(
                        context: context,

                        child: ReportChatReasonSheet(
                          userId: currentUserId,
                          userName: '',
                          userMobile: '',
                          userEmail: '',
                          roomId: widget.roomId,

                          authControllers: AuthControllers(
                            authRepository: AuthRepository(
                              apiClient: ApiClient(),
                            ),
                          ),
                        ),

                        showCloseIcon: true,

                        color: AppColors.white,

                        iconColor: AppColors.black,
                      );

                      break;
                  }
                },

                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear Chat'),
                  ),

                  if (isBlockedByMe)
                    const PopupMenuItem(
                      value: 'unblock',
                      child: Text('Unblock'),
                    )
                  else if (isBlockedByOther)
                    const PopupMenuItem(
                      enabled: false,
                      value: 'blocked',
                      child: Text('Blocked'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Block'),
                    ),

                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionTopRow() {
    final isMyMessage = _selectedMessageData?['senderId']?.toString() == widget.currentUserId;
    final messageType = _selectedMessageData?['messageType']?.toString() ?? 'text';
    final isTextMessage = messageType == 'text';
    final isDeleted = _selectedMessageData?['isDeleted'] == true;
    final canEdit = isMyMessage && isTextMessage && !isDeleted;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedMessageId = null;
              _selectedMessageData = null;
            });
          },

          child: AppIconWidget(
            assetPath: AssetImages.backArrow,
          ),
        ),

        const Spacer(),

        if (canEdit) ...[
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.fieldGrey,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (_selectedMessageData != null) {
                  final msgText = _selectedMessageData!['message']?.toString() ?? '';
                  textController.text = msgText;
                  textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: msgText.length),
                  );
                  setState(() {
                    _editingMessageId = selectedMessageId;
                    selectedMessageId = null;
                    _selectedMessageData = null;
                  });
                  _focusNode.requestFocus();
                }
              },
              child: Center(
                child: AppIconWidget(
                  assetPath: AssetImages.editChat,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],

        if (isMyMessage)
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.fieldGrey,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              offset: const Offset(0, 40),

              icon: AppIconWidget(
                assetPath: AssetImages.delete,
                size: 18,
                color: AppColors.black,
              ),

              onSelected: (value) async {
                if (_isOffline) {
                  _showNoInternetSnackbar();
                  return;
                }
                final id = selectedMessageId;

                if (id == null) return;

                try {
                  if (value == 'me') {
                    await ChatService.deleteForMe(
                      roomId: _effectiveRoomId,
                      messageId: id,
                      currentUserId: widget.currentUserId,
                    );
                  }

                  if (value == 'everyone') {
                    await ChatService.deleteForEveryone(
                      roomId: _effectiveRoomId,
                      messageId: id,
                      currentUserId: widget.currentUserId,
                    );
                  }

                  if (!mounted) return;

                  setState(() {
                    selectedMessageId = null;
                    _selectedMessageData = null;
                  });
                } catch (e) {
                  if (!mounted) return;

                  setState(() {
                    selectedMessageId = null;
                    _selectedMessageData = null;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },

              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'me',
                  child: AppText(
                    text: 'Delete for me',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (isMyMessage)
                  const PopupMenuItem(
                    value: 'everyone',
                    child: AppText(
                      text: 'Delete for everyone',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

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
        .padLeft(2, '0');

    final ampm =
    dt.hour >= 12
        ? 'PM'
        : 'AM';

    return '$h:$m $ampm';
  }
}

// ============================================================
// MAP PAINTER
// ============================================================

class _LocationMapPainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final roadPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..color =
      const Color(0xFFCCD7DB);

    final mainRoadPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 6
      ..color =
      const Color(0xFFF8FAFA);

    // Horizontal roads
    for (double y = 15;
    y < size.height;
    y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        roadPaint,
      );
    }

    // Vertical roads
    for (double x = 15;
    x < size.width;
    x += 40) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        roadPaint,
      );
    }

    // Main diagonal road
    canvas.drawLine(
      Offset(
        -20,
        size.height * .85,
      ),
      Offset(
        size.width + 20,
        size.height * .15,
      ),
      mainRoadPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
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