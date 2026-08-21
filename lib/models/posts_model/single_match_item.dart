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
      imageUrl: json['imageUrl']?.toString() ?? '',
      audioUrl: (json['audioUrl'] as String?)?.isNotEmpty == true ? json['audioUrl'] as String : null,
      videoUrl: (json['videoUrl'] as String?)?.isNotEmpty == true ? json['videoUrl'] as String : null,
      values: (json['values'] as List? ?? [])
          .map((e) => SingleMatchValue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SingleMatchValue {
  final String fieldName;
  final String fieldValue;

  SingleMatchValue({required this.fieldName, required this.fieldValue});

  factory SingleMatchValue.fromJson(Map<String, dynamic> json) {
    return SingleMatchValue(
      fieldName: json['field_name']?.toString() ?? '',
      fieldValue: json['field_value']?.toString() ?? '',
    );
  }
}