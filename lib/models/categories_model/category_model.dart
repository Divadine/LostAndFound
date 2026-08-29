class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;

  CategoryModel({required this.id, required this.name,  this.imageUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
        id: json['id']as int,
        name: json['name']?.toString() ?? '',
        imageUrl: json['category_image']?.toString(),
    );
  }
}

class CategoryListModel{
  final List<CategoryModel> categories;
  final int total;
  final int totalPages;
  final int nextPage;
  final int prevPage;

  CategoryListModel({required this.categories, required this.total, required this.totalPages, required this.nextPage, required this.prevPage});

  factory CategoryListModel.fromJson(Map<String,dynamic> json) {
    return CategoryListModel(
        categories: (json['categories'] as List).map((e) => CategoryModel.fromJson(e as Map<String,dynamic>)).toList(),
        total: json['pagination']['total'],
        totalPages: json['pagination']['totalPages'],
        nextPage: json['pagination']['nextPage'],
        prevPage: json['pagination']['prevPage']
    );
  }
}
