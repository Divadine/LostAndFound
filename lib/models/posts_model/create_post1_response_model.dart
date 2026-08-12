class CreatePostStep1Response {
  final int id;
  final String postUid;
  CreatePostStep1Response({required this.id, required this.postUid});

  factory CreatePostStep1Response.fromJson(Map<String, dynamic> json) {
    return CreatePostStep1Response(
      id: json['id'] ,
      postUid: json['post_uid'],
    );
  }
}