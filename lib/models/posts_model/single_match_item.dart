class SingleMatchModel {
  final int id;
  final String postUid;
  final int userId;
  final int postType;
  final int categoryId;
  final int subcategoryId;
  final String itemName;
  final String color;
  final String description;
  final String location;
  final DateTime? postDate;
  final int status;
  final String imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String posterName;      // NEW
  final String posterAvatar;    // NEW
  final List<SingleMatchValue> values;

  SingleMatchModel({
    required this.id,
    required this.postUid,
    required this.userId,
    required this.postType,
    required this.categoryId,
    required this.subcategoryId,
    required this.itemName,
    required this.color,
    required this.description,
    required this.location,
    this.postDate,
    required this.status,
    required this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.posterName = '',
    this.posterAvatar = '',
    required this.values,
  });

  factory SingleMatchModel.fromJson(Map<String, dynamic> json) {
    return SingleMatchModel(
      id: json['id'] as int? ?? 0,
      postUid: json['post_uid']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      postType: json['post_type'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      subcategoryId: json['subcategory_id'] as int? ?? 0,
      itemName: json['item_name']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null ? DateTime.tryParse(json['post_date'].toString()) : null,
      status: json['status'] as int? ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? json['audio_url']?.toString(),
      videoUrl: (json['videoUrl'] as String?)?.isNotEmpty == true
          ? json['videoUrl'] as String
          : (json['video_url'] as String?),

      posterName: json['poster_name']?.toString() ?? json['user_name']?.toString() ?? '',
      posterAvatar: json['poster_avatar']?.toString() ?? json['user_avatar']?.toString() ?? '',
      values: (json['values'] as List? ?? [])
          .map((e) => SingleMatchValue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SingleMatchValue {
  final String fieldName;
  final String fieldValue;
  final int step; // NEW — 1 = item details box, 2 = location/landmark box. Defaults to 2.

  SingleMatchValue({
    required this.fieldName,
    required this.fieldValue,
    this.step = 2,
  });

  factory SingleMatchValue.fromJson(Map<String, dynamic> json) {
    return SingleMatchValue(
      fieldName: json['field_name']?.toString() ?? '',
      fieldValue: json['field_value']?.toString() ?? '',
      step: json['step'] as int? ?? 2,
    );
  }
}