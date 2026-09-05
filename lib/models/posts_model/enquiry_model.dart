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
  });

  factory EnquiryPostModel.fromJson(Map<String, dynamic> json) {
    return EnquiryPostModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ??
          int.tryParse(json['user_uid']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
      userUid: json['user_uid']?.toString() ?? '',
      postUid: json['post_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      location: json['location']?.toString() ?? '',
      postDate: json['post_date'] != null
          ? DateTime.tryParse(json['post_date'].toString())
          : null,
      status: json['post_status'] as int? ?? json['status'] as int? ?? 0,
      postType: json['post_type'] as int? ?? 0,
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
      enquiryId: json['enquiry_id'] as int? ?? 0,
      matchedPostId: json['matched_postid'] as int? ??
          json['matched_id'] as int? ??
          json['post_id'] as int? ?? 0,
      enquirerUserId: json['user_id'] as int? ??
          int.tryParse(json['user_uid']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
      userUid: json['user_uid']?.toString() ?? '',
      postUid: json['post_uid']?.toString() ?? '',
      enquirerName: json['enquirer_name']?.toString() ?? '',
      enquirerProfileImg: json['enquirer_profile_img']?.toString() ??
          json['profile_img']?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      matchPercentage: json['matchPercentage'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      status: json['enquiry_status'] as int? ??
          json['enquirystatus'] as int? ??
          json['status'] as int? ?? 0,
      phoneno: json['phoneno']?.toString() ?? json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
    );
  }
}
