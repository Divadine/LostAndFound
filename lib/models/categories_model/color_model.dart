class ColorModel {
  final int id;
  final String colorName;
  final int status;

  ColorModel({required this.id, required this.colorName, required this.status});

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      id: json['id'] as int? ?? 0,
      colorName: json['colorname']?.toString() ?? '',
      status: json['status'] as int? ?? 0,
    );
  }
}