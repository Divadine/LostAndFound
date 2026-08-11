class ImageModel {
  final int id;
  final String imgPath;

  ImageModel({required this.id, required this.imgPath});

  Map<String,dynamic> toMap() {
    return {
      'id' : id,
      'img_path' : imgPath,
    };
  }
}