import 'dart:convert';

class EnquiryPostModel {
  final int id;
  final int userId;
  final String userUid;
  final String postUid;
  final String name;
  final List<String> images;
  final String location;
  final DateTime? postDate;
  final int status;
  final int postType;
  final int categoryId;
  final String categoryName;
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

  EnquiryPostModel({
    required this.id,
    required this.userId,
    required this.userUid,
    required this.postUid,
    required this.name,
    required this.images,
    required this.location,
    this.postDate,
    this.status = 0,
    this.postType = 0,
    this.categoryId = 0,
    this.categoryName = '',
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

  factory EnquiryPostModel.fromJson(Map<String, dynamic> json) {
    final handoverImages = <String>[];
    var handoverObj = json['handover'] is Map ? json['handover'] as Map<String, dynamic> : null;

    if (handoverObj == null && (json['handover'] is String) && (json['handover'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['handover']);
        if (decoded is Map) {
          handoverObj = decoded as Map<String, dynamic>;
        } else if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
          handoverObj = decoded[0] as Map<String, dynamic>;
        }
      } catch (_) {}
    } else if (handoverObj == null && json['handover'] is List && (json['handover'] as List).isNotEmpty) {
      if (json['handover'][0] is Map) {
        handoverObj = json['handover'][0] as Map<String, dynamic>;
      }
    }

    final hi = json['handover_img'] ??
        json['handover_images'] ??
        handoverObj?['handover_img'] ??
        handoverObj?['images'] ??
        handoverObj?['imgPath'] ??
        handoverObj?['img_path'] ??
        json['proof_img'] ??
        handoverObj?['proof_img'] ??
        handoverObj?['handover_images'];

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
            '')
        .toString();

    final stationAddress = (json['station_address'] ??
            handoverObj?['station_address'] ??
            handoverObj?['address'] ??
            '')
        .toString();

    return EnquiryPostModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ??
          int.tryParse(json['user_uid']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
      userUid: json['user_uid']?.toString() ?? '',
      postUid: json['post_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null
          ? DateTime.tryParse(json['post_date'].toString())
          : null,
      status: int.tryParse(json['post_status']?.toString() ?? '') ??
          int.tryParse(json['status']?.toString() ?? '') ??
          0,
      postType: int.tryParse(json['post_type']?.toString() ?? '') ?? 0,
      categoryId: int.tryParse((json['category_id'] ?? handoverObj?['category_id'] ?? '').toString()) ?? 0,
      categoryName: (json['category_name'] ?? handoverObj?['category_name'] ?? '').toString(),
      handoverType: int.tryParse((json['handover_type'] ?? handoverObj?['handover_type'] ?? handoverObj?['type'] ?? '').toString()) ?? 0,
      handoverName: (json['handover_name'] ?? handoverObj?['handover_name'] ?? handoverObj?['name'] ?? '').toString(),
      stationName: stationName,
      stationAddress: stationAddress,
      handoverDescription: (handoverObj?['description'] ??
              handoverObj?['handover_description'] ??
              json['handover_description'] ??
              json['handover_desc'] ??
              '')
          .toString(),
      handoverPhoneno: (handoverObj?['phoneno'] ??
              handoverObj?['handover_phoneno'] ??
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
              json['handover_user_uid'] ??
              json['user_uid'] ??
              '')
          .toString(),
      handoverDate: (handoverObj?['created_at'] ??
              handoverObj?['date'] ??
              json['handover_date'] ??
              '')
          .toString(),
    );
  }
}

class PostEnquiriesModel {
  final EnquiryPostModel? post;
  final int enquiriesCount;
  final List<EnquiryItem> enquiries;

  PostEnquiriesModel({
    this.post,
    required this.enquiriesCount,
    required this.enquiries,
  });

  factory PostEnquiriesModel.fromJson(Map<String, dynamic> json) {
    return PostEnquiriesModel(
      post: json['post'] != null
          ? EnquiryPostModel.fromJson(json['post'] as Map<String, dynamic>)
          : null,
      enquiriesCount: json['enquiries_count'] as int? ?? 0,
      enquiries: (json['enquiries'] as List? ?? [])
          .map((e) => EnquiryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EnquiryItem {
  final int enquiryId;
  final int matchedPostId;
  final int postId;
  final int enquirerUserId;
  final String userUid;
  final String postUid;
  final String enquirerName;
  final String enquirerProfileImg;
  final String description;
  final int matchPercentage;
  final DateTime? createdAt;
  final int status;
  final String phoneno;

  EnquiryItem({
    required this.enquiryId,
    required this.matchedPostId,
    required this.postId,
    required this.enquirerUserId,
    required this.userUid,
    required this.postUid,
    required this.enquirerName,
    required this.enquirerProfileImg,
    required this.description,
    required this.matchPercentage,
    this.createdAt,
    this.status = 0,
    this.phoneno = '',
  });

  factory EnquiryItem.fromJson(Map<String, dynamic> json) {
    return EnquiryItem(
      enquiryId: int.tryParse(json['enquiry_id']?.toString() ?? '') ??
          int.tryParse(json['id']?.toString() ?? '') ?? 0,
      matchedPostId: int.tryParse(json['matched_postid']?.toString() ?? '') ??
          int.tryParse(json['matched_id']?.toString() ?? '') ??
          int.tryParse(json['matchedPostId']?.toString() ?? '') ?? 0,
      postId: int.tryParse(json['post_id']?.toString() ?? '') ??
          int.tryParse(json['postId']?.toString() ?? '') ?? 0,
      enquirerUserId: int.tryParse(json['user_id']?.toString() ?? '') ??
          int.tryParse(json['enquirySenderId']?.toString() ?? '') ??
          int.tryParse(json['user_uid']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
      userUid: json['user_uid']?.toString() ?? json['userUid']?.toString() ?? '',
      postUid: json['post_uid']?.toString() ?? json['postUid']?.toString() ?? '',
      enquirerName: json['enquirer_name']?.toString() ?? '',
      enquirerProfileImg: json['enquirer_profile_img']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      matchPercentage: int.tryParse(json['matchPercentage']?.toString() ?? '') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      status: int.tryParse(json['enquiry_status']?.toString() ?? '') ??
          int.tryParse(json['enquirystatus']?.toString() ?? '') ??
          int.tryParse(json['status']?.toString() ?? '') ??
          0,
      phoneno: json['phoneno']?.toString() ?? json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
    );
  }
}
