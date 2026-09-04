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
  final String posterName;
  final String posterAvatar;
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
    // 1. Handle API response wrapping (check for 'data' key)
    final Map<String, dynamic> data = (json.containsKey('data') && json['data'] is Map)
        ? json['data'] as Map<String, dynamic>
        : json;

    // 2. Collect ALL potential media fields from the 'data' object
    final candidates = <String>[];

    void addCandidate(dynamic val) {
      if (val == null) return;
      if (val is List) {
        for (var item in val) {
          addCandidate(item);
        }
      } else if (val is String) {
        String s = val.trim();
        if (s.isEmpty || s == '[]') return;
        if (s.startsWith('[') && s.endsWith(']')) {
          final inner = s.substring(1, s.length - 1);
          if (inner.isNotEmpty) {
            for (var p in inner.split(',')) {
              addCandidate(p.trim().replaceAll('"', '').replaceAll("'", ""));
            }
          }
        } else {
          candidates.add(s);
        }
      }
    }

    addCandidate(data['images']);
    addCandidate(data['postimages']);
    addCandidate(data['post_images']);
    addCandidate(data['imageUrl']);
    addCandidate(data['image_url']);
    addCandidate(data['post_img']);
    addCandidate(data['post_image']);

    String? foundImage;
    String? foundVideo;

    // 3. Separate images from videos found in candidates
    for (var c in candidates) {
      if (_isVideo(c)) {
        foundVideo ??= c;
      } else {
        foundImage ??= c;
      }
    }

    // 4. Check explicit video fields as fallback
    foundVideo ??= data['videoUrl']?.toString() ??
        data['video_url']?.toString() ??
        data['post_video']?.toString();

    // 5. Finalize the model with unwrapped data
    return SingleMatchModel(
      id: data['id'] as int? ?? 0,
      postUid: data['post_uid']?.toString() ?? '',
      userId: data['user_id'] as int? ?? 0,
      postType: data['post_type'] as int? ?? 0,
      categoryId: data['category_id'] as int? ?? 0,
      subcategoryId: data['subcategory_id'] as int? ?? 0,
      itemName: data['item_name']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      postDate: data['post_date'] != null ? DateTime.tryParse(data['post_date'].toString()) : null,
      status: data['status'] as int? ?? 0,
      imageUrl: foundImage ?? '',
      audioUrl: data['audioUrl']?.toString() ?? data['audio_url']?.toString(),
      videoUrl: foundVideo,
      posterName: data['poster_name']?.toString() ?? data['user_name']?.toString() ?? '',
      posterAvatar: data['poster_avatar']?.toString() ?? data['user_avatar']?.toString() ?? '',
      values: (data['values'] as List? ?? [])
          .map((e) => SingleMatchValue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.contains('.mp4') || lower.contains('.mov') || lower.contains('.avi');
  }
}

class SingleMatchValue {
  final String? fieldName;
  final String? fieldValue;
  final int step;

  SingleMatchValue({
    this.fieldName,
    this.fieldValue,
    this.step = 2,
  });

  factory SingleMatchValue.fromJson(Map<String, dynamic> json) {
    return SingleMatchValue(
      fieldName: json['field_name']?.toString(),
      fieldValue: json['field_value']?.toString(),
      step: json['step'] as int? ?? 2,
    );
  }
}
