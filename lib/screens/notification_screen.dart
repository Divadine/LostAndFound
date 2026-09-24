import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/Notifications/notification_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_utils.dart';

import 'chat/chat_firebaase_functions.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  final ScrollController _scrollController = ScrollController();

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  bool _isMoreLoading = false;
  bool _hasMore = true;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  final bool _isOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isMoreLoading &&
        _hasMore &&
        !_isLoading) {
      _currentPage++;
      _fetchNotifications(isLoadMore: true);
    }
  }

  Future<void> _fetchNotifications({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isMoreLoading || !_hasMore) return;
      setState(() => _isMoreLoading = true);
    } else {
      setState(() {
        _isLoading = _notifications.isEmpty;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final userId = AppPreferences.getUserId() ?? 0;

      final response = await authController.getNotificationList(
        userId: userId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final newNotifications = response.data!.notifications;
        _totalPages = response.data!.totalPages;

        debugPrint('=== NOTIFICATIONS FETCHED ===');
        debugPrint('Queried with userId: $userId');
        debugPrint('Count returned: ${newNotifications.length}');
        for (final n in newNotifications) {
          debugPrint(
            '-> id: ${n.id} | receiver userId: ${n.userId} | sender senderId: ${n.senderId} | postId: ${n.postId} | title: ${n.title}',
          );
        }

        setState(() {
          if (isLoadMore) {
            _notifications.addAll(newNotifications);
            _isMoreLoading = false;
          } else {
            _notifications = newNotifications;
            _isLoading = false;
          }
          _hasMore = _currentPage < _totalPages && newNotifications.isNotEmpty;
        });
      } else {
        setState(() {
          if (isLoadMore) {
            _isMoreLoading = false;
          } else {
            _error = response.message;
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isLoadMore) {
          _isMoreLoading = false;
        } else {
          _error = "Something went wrong";
          _isLoading = false;
        }
      });
      debugPrint('Notification fetch error: $e');
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return "";
    final date = DateTime.tryParse(createdAt);
    if (date == null) return "";
    return AppUtils.formatTimeAgo(date);
  }

  // ------------------------------------------------------------
  // Notification tap
  // ------------------------------------------------------------
  Future<void> _openNotificationChat(NotificationModel notification) async {
    final currentUserId = AppPreferences.getUserId();
    if (currentUserId == null) return;

    final currentUserIdStr = currentUserId.toString();
    final otherUserIdStr = notification.senderId.toString();

    debugPrint('Notification tapped');
    debugPrint('notification userId (receiver): ${notification.userId}');
    debugPrint('notification senderId (enquirer): ${notification.senderId}');
    debugPrint('notification postId: ${notification.postId}');

    // ============================================================
    // Fetch the sender's profile so the chat header shows their
    // real name/avatar instead of falling back to "User <id>".
    // IndividualChatScreen only receives what we pass here — it
    // does NOT look this up itself for name/avatar (only phone).
    // ============================================================
    String otherUserName = '';
    String otherUserAvatar = '';
    String otherUserPhone = '';

    try {
      final profileResponse = await authController.getProfile(
        userId: notification.senderId,
      );

      if (profileResponse.isSuccess && profileResponse.data != null) {
        final profile = profileResponse.data!;
        // TODO: confirm these field names match your actual
        // GetProfileModel — adjust if it uses different keys
        // (e.g. fullName, profileImage, mobileNumber, etc.)
        otherUserName = profile.name?.toString().trim() ?? '';
        otherUserAvatar = profile.profileImageUrl?.toString().trim() ?? '';
        otherUserPhone = profile.mobile?.toString().trim() ?? '';
      }
    } catch (e) {
      debugPrint('Failed to fetch sender profile: $e');
    }

    final roomId = ChatService.generateRoomId(
      userId1: currentUserIdStr,
      userId2: otherUserIdStr,
      postId: notification.postId.toString(),
    );

    debugPrint('Generated notification roomId: $roomId');

    if (!mounted) return;

    AppRoutes.pushNamed(
      AppRoutes.individualChatScreen,
      arguments: {
        'roomId': roomId,
        'currentUserId': currentUserIdStr,
        'otherUserId': otherUserIdStr,
        'otherUserName': otherUserName,
        'otherUserAvatar': otherUserAvatar,
        'otherUserPhone': otherUserPhone,
        'itemPostId': notification.postId.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: AppIconWidget(
              assetPath: AssetImages.notificationBackIcon,
              size: 20,
            ),
          ),
        ),
        title: const AppText(
          text: "Notifications",
          color: AppColors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isOffline) {
      return const NoInternetWidget();
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: AppText(text: _error!, color: AppColors.black));
    }

    final items = _notifications;

    if (items.isEmpty) {
      return const Center(
        child: AppText(text: "No notifications yet", color: AppColors.black),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchNotifications(isLoadMore: false),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: items.length + (_isMoreLoading ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = items[index];

          return GestureDetector(
            onTap: () => _openNotificationChat(item),
            child: _NotificationCard(
              imageUrl: item.postImageUrl.isNotEmpty
                  ? item.postImageUrl.first.imagePath
                  : null,
              title: item.title,
              description: item.description,
              time: _timeAgo(item.createdAt),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String description;
  final String time;

  const _NotificationCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (imageUrl != null && imageUrl!.trim().isNotEmpty)
              ? AppCachedNetworkImage(
            imageUrl: imageUrl!,
            height: 76,
            width: 76,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(16),
          )
              : Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: AppColors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: title,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.black,
                ),
                const SizedBox(height: 4),
                AppText(
                  text: description,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: const Color(0xFF1A1A1A),
                  maxLine: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                AppText(
                  text: time,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: const Color(0xFF808080),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}