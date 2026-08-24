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
      postId: json['post_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userUid: json['userUid'] ?? '',
      name: json['name'] ?? '',
      phoneno: json['phoneno'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      matchPercentage: json['matchPercentage'] ?? 0,
    );
  }
}