import 'notification_image_model.dart';

class NotificationModel {
  final int id;
  final int userId;
  final int senderId;
  final int postId;
  final String title;
  final String description;
  final String? createdAt;
  final List<NotificationImageModel> postImageUrl;
  final int status;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.postId,
    required this.title,
    required this.description,
    this.createdAt,
    required this.postImageUrl,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      senderId: json['sender_id'] as int? ?? 0,
      postId: json['post_id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      status: json['status'] ?? 0,
      postImageUrl: (json['postImageUrl']as List? ?? []).map((e) => NotificationImageModel.fromJson(e as Map<String, dynamic>,)).toList(),
    );
  }
}