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
  final String finderName;
  final String ownerName;
  final String finderAvatar;
  final String ownerAvatar;
  final String categoryName;
  final List<SingleMatchValue> values;
  final int handoverType;
  final String handoverName;
  final String stationName;
  final String stationAddress;
  final String handoverDescription;
  final String handoverPhoneno;
  final List<String> handoverImg;
  final int? handoverMatchPercentage;
  final String handoverUserUid;
  final String handoverDate;

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
    this.finderName = '',
    this.ownerName = '',
    this.finderAvatar = '',
    this.ownerAvatar = '',
    this.categoryName = '',
    required this.values,
    this.handoverType = 0,
    this.handoverName = '',
    this.stationName = '',
    this.stationAddress = '',
    this.handoverDescription = '',
    this.handoverPhoneno = '',
    this.handoverImg = const [],
    this.handoverMatchPercentage,
    this.handoverUserUid = '',
    this.handoverDate = '',
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

    String? foundName = data['poster_name']?.toString() ??
        data['user_name']?.toString() ??
        data['enquirer_name']?.toString() ??
        data['full_name']?.toString() ??
        data['display_name']?.toString();

    if (foundName == null && data['user'] is Map) {
      final user = data['user'] as Map<String, dynamic>;
      foundName = user['name']?.toString() ??
          user['user_name']?.toString() ??
          user['full_name']?.toString() ??
          user['display_name']?.toString();
    }

    String? foundAvatar = data['poster_avatar']?.toString() ??
        data['user_avatar']?.toString() ??
        data['enquirer_profile_img']?.toString() ??
        data['image_url']?.toString();

    if (foundAvatar == null && data['user'] is Map) {
      final user = data['user'] as Map<String, dynamic>;
      foundAvatar = user['profile_image']?.toString() ??
          user['image_url']?.toString() ??
          user['avatar']?.toString();
    }

    // --- Handover Data Parsing ---
    final handoverImages = <String>[];
    var handoverObj = data['handover'] is Map ? data['handover'] as Map<String, dynamic> : null;

    if (handoverObj == null && (data['handover'] is String) && (data['handover'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(data['handover']);
        if (decoded is Map) {
          handoverObj = decoded as Map<String, dynamic>;
        } else if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
          handoverObj = decoded[0] as Map<String, dynamic>;
        }
      } catch (_) {}
    } else if (handoverObj == null && data['handover'] is List && (data['handover'] as List).isNotEmpty) {
      if (data['handover'][0] is Map) {
        handoverObj = data['handover'][0] as Map<String, dynamic>;
      }
    }

    final hi = data['handover_img'] ??
        data['handover_images'] ??
        handoverObj?['handover_img'] ??
        handoverObj?['images'] ??
        handoverObj?['imgPath'] ??
        handoverObj?['img_path'] ??
        data['proof_img'];

    if (hi != null && hi.toString().isNotEmpty) {
      if (hi is String) {
        if (hi.contains(',')) {
          handoverImages.addAll(hi.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        } else {
          handoverImages.add(hi.trim());
        }
      } else if (hi is List) {
        for (var e in hi) {
          if (e is Map) {
            final path = (e['img_path'] ?? e['image_path'] ?? e['path'] ?? e['url'] ?? '').toString();
            if (path.isNotEmpty) handoverImages.add(path);
          } else if (e != null) {
            handoverImages.add(e.toString());
          }
        }
      }
    }

    final stationName = (data['station_name'] ??
            handoverObj?['station_name'] ??
            data['handover_name'] ??
            handoverObj?['handover_name'] ??
            handoverObj?['name'] ??
            '')
        .toString();

    final stationAddress = (data['station_address'] ??
            handoverObj?['station_address'] ??
            handoverObj?['address'] ??
            '')
        .toString();

    return SingleMatchModel(
      id: data['id'] as int? ?? 0,
      postUid: data['post_uid']?.toString() ?? '',
      userId: data['user_id'] as int? ?? 0,
      postType: data['post_type'] as int? ?? 0,
      categoryId: int.tryParse((data['category_id'] ?? handoverObj?['category_id'] ?? '').toString()) ?? 0,
      subcategoryId: data['subcategory_id'] as int? ?? 0,
      itemName: data['item_name']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      postDate: data['post_date'] != null ? DateTime.tryParse(data['post_date'].toString()) : null,
      status: int.tryParse(data['status']?.toString() ?? '') ?? 0,
      imageUrl: foundImage ?? '',
      audioUrl: data['audioUrl']?.toString() ?? data['audio_url']?.toString(),
      videoUrl: foundVideo,
      posterName: foundName ?? '',
      posterAvatar: foundAvatar ?? '',
      finderName: data['finder_name']?.toString() ?? '',
      ownerName: data['owner_name']?.toString() ?? '',
      finderAvatar: data['finder_avatar']?.toString() ?? '',
      ownerAvatar: data['owner_avatar']?.toString() ?? '',
      categoryName: data['category_name']?.toString() ??
          (data['post'] is Map ? (data['post'] as Map)['category_name']?.toString() : null) ??
          data['category']?.toString() ??
          '',
      values: valuesList
          .map((e) => SingleMatchValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      handoverType: int.tryParse((data['handover_type'] ?? handoverObj?['handover_type'] ?? handoverObj?['type'] ?? '').toString()) ?? 0,
      handoverName: (data['handover_name'] ?? handoverObj?['handover_name'] ?? handoverObj?['name'] ?? '').toString(),
      stationName: stationName,
      stationAddress: stationAddress,
      handoverDescription: (handoverObj?['description'] ??
              handoverObj?['handover_description'] ??
              data['handover_description'] ??
              data['handover_desc'] ??
              '')
          .toString(),
      handoverPhoneno: (handoverObj?['phoneno'] ??
              handoverObj?['handover_phoneno'] ??
              data['handover_phoneno'] ??
              data['phoneno'] ??
              '')
          .toString(),
      handoverImg: handoverImages,
      handoverMatchPercentage: int.tryParse((handoverObj?['match_percentage'] ??
              handoverObj?['matchPercentage'] ??
              data['handover_match_percentage'] ??
              '')
          .toString()),
      handoverUserUid: (handoverObj?['user_uid'] ??
              handoverObj?['userUid'] ??
              data['handover_user_uid'] ??
              '')
          .toString(),
      handoverDate: (handoverObj?['created_at'] ??
              handoverObj?['date'] ??
              data['handover_date'] ??
              '')
          .toString(),
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
