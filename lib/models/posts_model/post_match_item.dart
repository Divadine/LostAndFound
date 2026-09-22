import 'dart:convert';

// models/match_model/post_matches_model.dart
class PostMatchesModel {
  final MatchedPostSummary post;
  final int matchingCount;
  final List<MatchItemModel> matches;

  PostMatchesModel({required this.post, required this.matchingCount, required this.matches});

  factory PostMatchesModel.fromJson(Map<String, dynamic> json) {
    final postData = json['post'] != null ? Map<String, dynamic>.from(json['post'] as Map) : null;
    if (postData != null && json['handover_info'] != null) {
      postData['handover_info'] = json['handover_info'];
    }

    return PostMatchesModel(
      post: postData != null 
          ? MatchedPostSummary.fromJson(postData)
          : MatchedPostSummary.fromJson({}),
      matchingCount: json['matching_count'] as int? ?? 0,
      matches: (json['matches'] as List? ?? [])
          .map((e) => MatchItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MatchedPostSummary {
  final int id;
  final String postUid;
  final String name;
  final int userId;
  final String location;
  final DateTime? postDate;
  final DateTime? createdAt;
  final List<String> images;

  // Handover Info Fields
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
  final String handoverAvatar;

  MatchedPostSummary({
    required this.id,
    required this.postUid,
    required this.name,
    required this.userId,
    required this.location,
    this.postDate,
    this.createdAt,
    required this.images,
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
    this.handoverAvatar = '',
  });

  factory MatchedPostSummary.fromJson(Map<String, dynamic> json) {
    final handoverImages = <String>[];
    var handoverObj = json['handover'] is Map ? json['handover'] as Map<String, dynamic> : null;

    if (handoverObj == null && json['handover_info'] is List && (json['handover_info'] as List).isNotEmpty) {
      if (json['handover_info'][0] is Map) {
        handoverObj = json['handover_info'][0] as Map<String, dynamic>;
      }
    }

    final hi = json['handover_img'] ??
        json['handover_images'] ??
        handoverObj?['handover_images'] ??
        handoverObj?['handover_img'] ??
        handoverObj?['images'] ??
        handoverObj?['imgPath'] ??
        handoverObj?['img_path'] ??
        json['proof_img'] ??
        handoverObj?['proof_img'];

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

    final stationName = (json['station_name'] ??
            handoverObj?['station_name'] ??
            json['handover_name'] ??
            handoverObj?['handover_name'] ??
            handoverObj?['name'] ??
            handoverObj?['stationName'] ??
            '')
        .toString();

    final stationAddress = (json['station_address'] ??
            handoverObj?['station_address'] ??
            handoverObj?['address'] ??
            handoverObj?['stationAddress'] ??
            '')
        .toString();

    final handoverName = (json['handover_name'] ??
            handoverObj?['handover_name'] ??
            handoverObj?['name'] ??
            handoverObj?['receiver_name'] ??
            handoverObj?['received_by'] ??
            handoverObj?['user_name'] ??
            '')
        .toString();

    return MatchedPostSummary(
      id: json['id'] as int? ?? 0,
      postUid: json['post_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null
          ? DateTime.tryParse(json['post_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      images: _parseImages(json['images']),
      handoverType: int.tryParse((json['handover_type'] ?? handoverObj?['handover_type'] ?? handoverObj?['type'] ?? '').toString()) ?? 0,
      handoverName: handoverName,
      stationName: stationName,
      stationAddress: stationAddress,
      handoverDescription: (handoverObj?['handover_desc'] ??
              handoverObj?['description'] ??
              handoverObj?['handover_description'] ??
              json['handover_desc'] ??
              json['handover_description'] ??
              '')
          .toString(),
      handoverPhoneno: (handoverObj?['phoneno'] ??
              handoverObj?['handover_phoneno'] ??
              handoverObj?['handover_phone'] ??
              json['handover_phoneno'] ??
              json['phoneno'] ??
              '')
          .toString(),
      handoverImg: handoverImages,
      handoverMatchPercentage: int.tryParse((handoverObj?['match_percentage'] ??
              handoverObj?['matchPercentage'] ??
              json['handover_match_percentage'] ??
              json['matchPercentage'] ??
              '')
          .toString()),
      handoverUserUid: (handoverObj?['user_uid'] ??
              handoverObj?['userUid'] ??
              handoverObj?['user_id']?.toString() ??
              json['handover_user_uid'] ??
              '')
          .toString(),
      handoverDate: (handoverObj?['created_at'] ??
              handoverObj?['date'] ??
              handoverObj?['handover_date'] ??
              json['handover_date'] ??
              '')
          .toString(),
      handoverAvatar: (handoverObj?['profile_image'] ??
              handoverObj?['avatar'] ??
              handoverObj?['image'] ??
              '')
          .toString(),
    );
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    final str = value.toString().trim();
    if (str.isEmpty || str == '[]') return [];
    return [str];
  }
}

class MatchItemModel {
  final int postId;
  final String postUid;
  final String posterName;
  final String posterAvatar;
  final String userUid;
  final String postImages;
  final String name;
  final int userId;
  final String location;
  final DateTime? postDate;
  final DateTime? createdAt;
  final String description;
  final int matchPercentage;
  final int matchTier;
  final bool hasImageMatch;
  final int status; // ADDED

  MatchItemModel({
    required this.postId,
    required this.postUid,
    required this.posterName,
    required this.posterAvatar,
    required this.userUid,
    required this.postImages,
    required this.name,
    required this.userId,
    required this.location,
    this.postDate,
    this.createdAt,
    required this.description,
    required this.matchPercentage,
    required this.matchTier,
    required this.hasImageMatch,
    required this.status, // ADDED
  });

  factory MatchItemModel.fromJson(Map<String, dynamic> json) {
    String? foundName = json['poster_name']?.toString() ??
        json['user_name']?.toString() ??
        json['full_name']?.toString() ??
        json['display_name']?.toString();

    if (foundName == null && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      foundName = user['name']?.toString() ??
          user['user_name']?.toString() ??
          user['full_name']?.toString() ??
          user['display_name']?.toString();
    }

    String? foundAvatar = json['poster_avatar']?.toString() ??
        json['user_avatar']?.toString() ??
        json['image_url']?.toString();

    if (foundAvatar == null && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      foundAvatar = user['profile_image']?.toString() ??
          user['image_url']?.toString() ??
          user['avatar']?.toString();
    }

    return MatchItemModel(
      postId: json['post_id'] as int? ?? 0,
      postUid: json['post_uid']?.toString() ?? '',
      posterName: foundName ?? '',
      posterAvatar: foundAvatar ?? '',
      userUid: json['user_uid']?.toString() ?? '',
      postImages: _parseImages(json['postimages']),
      name: json['name']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null
          ? DateTime.tryParse(json['post_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      description: json['description']?.toString() ?? '',
      matchPercentage: json['matchPercentage'] as int? ?? 0,
      matchTier: json['matchTier'] as int? ?? 0,
      hasImageMatch: json['hasImageMatch'] as bool? ?? false,
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0, // ADDED
    );
  }

  static String _parseImages(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.isNotEmpty ? value.first.toString() : '';
    }
    final str = value.toString().trim();
    if (str.isEmpty || str == '[]') return '';

    var clean = str;
    if (clean.startsWith('[') && clean.endsWith(']')) {
      clean = clean.substring(1, clean.length - 1).trim();
    }
    if (clean.isEmpty) return '';

    if (clean.contains(',')) {
      return clean.split(',').first.trim().replaceAll('"', '').replaceAll("'", "");
    }
    return clean.replaceAll('"', '').replaceAll("'", "");
  }
}
