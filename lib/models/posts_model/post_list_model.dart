class PostListModel {
  final List<PostModel> posts;
  final int page;
  final int limit;
  final int total;

  PostListModel({required this.posts, required this.page, required this.limit, required this.total});

  factory PostListModel.fromJson(Map<String,dynamic> json){
    return PostListModel(
        posts: (json['posts'] as List?  ?? []).map((e) => PostModel.fromJson(e as Map<String,dynamic>)).toList(),
        page: json['page'],
        limit: json['limit'],
        total: json['total']
    );
  }
}

class PostModel{
  final int id;
  final String postUid;
  final String name;
  final String userUid;
  final String location;
  final DateTime? postDate;
  final List<String> images;
  final int status;
  final int enquiriesCount;
  final List<EnquirerAvatarModel> enquirerAvatars;
  PostModel({required this.id, required this.postUid, required this.name, required this.userUid, required this.location, this.postDate, required this.images, required this.status, required this.enquiriesCount, required this.enquirerAvatars});

  factory PostModel.fromJson(Map<String,dynamic> json) {
    return PostModel(
        id: json['id'],
        postUid: json['postUid'],
        name: json['name'],
        userUid: json['userUid'],
        location: json['location'],
        images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
        status: json['status'],
        enquiriesCount: json['enquiriesCount'],
        enquirerAvatars: (json['enquirerAvatars'] as List? ?? []).map((e) => EnquirerAvatarModel.fromJson(e as Map<String,dynamic>)).toList(),
    );
  }
}

class EnquirerAvatarModel {
  final String name;
  final String imageUrl;

  EnquirerAvatarModel({required this.name, required this.imageUrl});

  factory EnquirerAvatarModel.fromJson(Map<String, dynamic> json) {
    return EnquirerAvatarModel(
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}