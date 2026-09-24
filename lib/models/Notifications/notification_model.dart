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
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    int parsedSenderId = parseId(json['sender_id']);
    if (parsedSenderId == 0) {
      parsedSenderId = parseId(
        json['enquiry_sender_id'] ??
            json['from_user_id'] ??
            json['enquirer_id'] ??
            json['senderId'],
      );
    }

    return NotificationModel(
      id: parseId(json['id']),
      userId: parseId(json['user_id']),
      senderId: parsedSenderId,
      postId: parseId(json['post_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      status: parseId(json['status']),
      postImageUrl: (json['postImageUrl'] as List? ?? [])
          .map((e) => NotificationImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}