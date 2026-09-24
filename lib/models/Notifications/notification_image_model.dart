class NotificationImageModel {
  final int id;
  final String imagePath;

  NotificationImageModel({
    required this.id,
    required this.imagePath,
  });

  factory NotificationImageModel.fromJson(Map<String, dynamic> json) {
    return NotificationImageModel(
      id: json['id'] as int,
      imagePath: json['img_path']?.toString() ?? '',
    );
  }
}