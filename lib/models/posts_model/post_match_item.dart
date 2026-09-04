// models/match_model/post_matches_model.dart
class PostMatchesModel {
  final MatchedPostSummary post;
  final int matchingCount;
  final List<MatchItemModel> matches;

  PostMatchesModel({required this.post, required this.matchingCount, required this.matches});

  factory PostMatchesModel.fromJson(Map<String, dynamic> json) {
    return PostMatchesModel(
      post: MatchedPostSummary.fromJson(json['post'] as Map<String, dynamic>),
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
  final List<String> images;

  MatchedPostSummary({
    required this.id,
    required this.postUid,
    required this.name,
    required this.userId,
    required this.location,
    this.postDate,
    required this.images,
  });

  factory MatchedPostSummary.fromJson(Map<String, dynamic> json) {
    return MatchedPostSummary(
      id: json['id'] as int? ?? 0,
      postUid: json['post_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null ? DateTime.tryParse(json['post_date'].toString()) : null,
      images: _parseImages(json['images']),
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
  final String description;
  final int matchPercentage;
  final int matchTier;
  final bool hasImageMatch;

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
    required this.description,
    required this.matchPercentage,
    required this.matchTier,
    required this.hasImageMatch,
  });

  factory MatchItemModel.fromJson(Map<String, dynamic> json) {
    return MatchItemModel(
      postId: json['post_id'] as int? ?? 0,
      postUid: json['post_uid']?.toString() ?? '',
      posterName: json['poster_name']?.toString() ?? '',
      posterAvatar: json['poster_avatar']?.toString() ?? '',
      userUid: json['user_uid']?.toString() ?? '',
      postImages: _parseImages(json['postimages']),
      name: json['name']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null ? DateTime.tryParse(json['post_date'].toString()) : null,
      description: json['description']?.toString() ?? '',
      matchPercentage: json['matchPercentage'] as int? ?? 0,
      matchTier: json['matchTier'] as int? ?? 0,
      hasImageMatch: json['hasImageMatch'] as bool? ?? false,
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