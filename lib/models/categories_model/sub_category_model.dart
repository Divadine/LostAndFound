class SubCategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final String? subCategoryImg;

  SubCategoryModel({required this.id, required this.categoryId, required this.name, this.subCategoryImg});

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
        id: json['id'],
        categoryId: json['category_id'],
        name: json['subcategory_name'],
      subCategoryImg: json['subcategory_img']
    );
  }
}