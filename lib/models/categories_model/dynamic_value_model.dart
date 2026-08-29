class DynamicValueModel {
  final int id;
  final String value;
  final String? parentValue;

  DynamicValueModel({required this.id, required this.value, this.parentValue});

  factory DynamicValueModel.fromJson(Map<String,dynamic> json) {
    return DynamicValueModel(
        id: json['id']as int,
        value: json['value']?.toString()  ?? '',
      parentValue:json['parent_value']?.toString(),
    );
  }
}