class PostImageModel {
  final int id;
  final String imgPath;
  PostImageModel({required this.id, required this.imgPath});

  factory PostImageModel.fromJson(Map<String, dynamic> json) {
    return PostImageModel(
      id: json['id'] ,
      imgPath: json['img_path'],
    );
  }
}

class PostAudioModel {
  final int id;
  final String audio;
  PostAudioModel({required this.id, required this.audio});

  factory PostAudioModel.fromJson(Map<String, dynamic> json) {
    return PostAudioModel(
      id: json['id'],
      audio: json['audio'] ?? json['audio_path'],
    );
  }
}

class PostVideoModel {
  final int id;
  final String video;
  PostVideoModel({required this.id, required this.video});

  factory PostVideoModel.fromJson(Map<String, dynamic> json) {
    return PostVideoModel(
      id: json['id'] ,
      video: json['video_path'],
    );
  }
}

