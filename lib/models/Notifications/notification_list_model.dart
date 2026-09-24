import 'notification_model.dart';

class NotificationListModel {
  final List<NotificationModel> notifications;
  final int total;
  final int totalPages;
  final int page;
  final int pageSize;

  NotificationListModel({
    required this.notifications,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.pageSize,
  });

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    return NotificationListModel(
      notifications: (json['data'] as List? ?? [])
          .map(
            (e) => NotificationModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),

      total: json['pagination']['total'] ?? 0,
      totalPages: json['pagination']['totalPages'] ?? 0,
      page: json['pagination']['page'] ?? 1,
      pageSize: json['pagination']['pageSize'] ?? 10,
    );
  }
}