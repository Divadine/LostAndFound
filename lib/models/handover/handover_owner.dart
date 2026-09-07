class HandoverOwnerListResponse {
  final List<HandoverOwnerModel> data;

  HandoverOwnerListResponse({required this.data});

  factory HandoverOwnerListResponse.fromJson(Map<String, dynamic> json) {
    return HandoverOwnerListResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => HandoverOwnerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HandoverOwnerModel {
  final int postId;
  final int userId;
  final String userUid;
  final String name;
  final String phoneno;
  final String? profileImageUrl;
  final int matchPercentage;

  HandoverOwnerModel({
    required this.postId,
    required this.userId,
    required this.userUid,
    required this.name,
    required this.phoneno,
    this.profileImageUrl,
    required this.matchPercentage,
  });

  factory HandoverOwnerModel.fromJson(Map<String, dynamic> json) {
    return HandoverOwnerModel(
      postId: int.tryParse(json['post_id']?.toString() ?? '') ??
          int.tryParse(json['postId']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ??
          int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      userUid: json['userUid']?.toString() ?? json['user_uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneno: json['phoneno']?.toString() ?? json['phone']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString() ?? json['profile_img']?.toString(),
      matchPercentage: int.tryParse(json['matchPercentage']?.toString() ?? '') ?? 0,
    );
  }
}