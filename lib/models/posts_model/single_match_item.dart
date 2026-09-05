import 'dart:convert';

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
      } else if (val is Map) {
        // Look for common image/video keys in objects
        addCandidate(val['img_path']);
        addCandidate(val['image_path']);
        addCandidate(val['imgPath']);
        addCandidate(val['imagePath']);
        addCandidate(val['path']);
        addCandidate(val['url']);
        addCandidate(val['imageUrl']);
        addCandidate(val['imageURL']);
        addCandidate(val['file_path']);
        addCandidate(val['filePath']);
      } else if (val is String) {
        String s = val.trim();
        if (s.isEmpty || s == '[]' || s == 'null' || s == '""' || s == "''") return;

        // Try to parse as JSON if it looks like an array or object
        if ((s.startsWith('[') && s.endsWith(']')) || (s.startsWith('{') && s.endsWith('}'))) {
          try {
            final decoded = jsonDecode(s);
            addCandidate(decoded);
            return;
          } catch (_) {
            // Fall through to manual parsing
          }
        }

        // Handle comma-separated values (often used for multiple image paths/IDs)
        if (s.contains(',')) {
          for (var p in s.split(',')) {
            addCandidate(p.trim().replaceAll('"', '').replaceAll("'", ""));
          }
          return;
        }

        // Remove wrapping quotes if any
        s = s.replaceAll('"', '').replaceAll("'", "");
        if (s.isEmpty) return;

        candidates.add(s);
      } else if (val is num) {
        // If it's a number, it might be an image ID, which isn't a path, 
        // but we'll add it just in case the backend uses IDs in paths
        candidates.add(val.toString());
      }
    }

    // Exhaustive check for common field names
    final fieldsToCheck = [
      'images', 'Images', 'postimages', 'postImages', 'PostImages', 'Postimages',
      'post_images', 'Post_Images', 'imageUrl', 'image_url', 'imageURL',
      'post_img', 'post_image', 'image', 'Image', 'postimg', 'Postimg',
      'item_image', 'itemImage', 'file_path', 'filePath', 'path'
    ];

    for (var field in fieldsToCheck) {
      addCandidate(json[field]);
      addCandidate(data[field]);
    }

    // Also check if there's a nested post object
    if (data['post'] is Map) {
      for (var field in fieldsToCheck) {
        addCandidate((data['post'] as Map)[field]);
      }
    }

    // Also check values for image fields
    final valuesData = data['values'] ?? data['post_values'] ?? data['postValues'] ?? data['dynamic_values'];
    final valuesList = (valuesData is List) ? valuesData : [];
    
    for (var v in valuesList) {
      if (v is Map) {
        final fieldName = (v['field_name'] ?? v['fieldName'] ?? '').toString().toLowerCase();
        if (fieldName.contains('image') || 
            fieldName.contains('photo') || 
            fieldName.contains('img') || 
            fieldName.contains('proof') || 
            fieldName.contains('file') || 
            fieldName.contains('attachment')) {
          addCandidate(v['field_value'] ?? v['fieldValue']);
        }
      }
    }

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
    if (foundImage == null || foundImage.isEmpty) {
      print('DEBUG: SingleMatchModel - No image found in keys: ${data.keys.toList()}');
      if (data['post'] is Map) {
        print('DEBUG: SingleMatchModel - Keys in nested post: ${(data['post'] as Map).keys.toList()}');
      }
    }

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
      values: valuesList
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
