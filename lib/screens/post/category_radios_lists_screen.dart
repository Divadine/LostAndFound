import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/category_not_found.dart';

class CategoryRadiosListsScreen extends StatefulWidget {
  final int postType;
  const CategoryRadiosListsScreen({super.key, required this.postType});

  @override
  State<CategoryRadiosListsScreen> createState() =>
      _CategoryRadiosListsScreenState();
}

class _CategoryRadiosListsScreenState extends State<CategoryRadiosListsScreen> {

  List<CategoryModel> categories = [];
  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  final TextEditingController searchController = TextEditingController();
  int? selectedIndex;

  Timer? _debounce;
  List<Map<String, dynamic>> filteredCategory = [];
  bool isLoading = false;

  //final StreamController<List<Map<String, dynamic>>> mainCategoryStream = StreamController.broadcast();
  StreamController<int?> selectedCategoryStream = StreamController.broadcast();
  StreamController<List<CategoryModel>> mainApiCategoryStream = StreamController.broadcast();



  Future<void> _fetchCategories({ int? limit,  int? page, String? search}) async {
    setState(() {
      isLoading = true;
    });

    final response = await authController.getCategories(page: page ?? 0, limit: limit ?? 0, search: search);

    if( response.data!= null){
       categories = response.data!.categories;
      mainApiCategoryStream.add(categories);
    }else{
      categories = [];
      mainApiCategoryStream.add([]);
    }

    setState(() {
      isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchCategories();

    print('*********************filteredcategory ---> $filteredCategory');
  }

  @override
  void dispose() {
    mainApiCategoryStream.close();
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void searchCategory(String value) {
    selectedIndex = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchCategories(search: value.trim().isEmpty ? null : value.trim());
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          AppText(
            text: 'Select Category',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.primaryColor,
          ),
          AppText(
            text: 'Choose the Category that best matches your item',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 5),
          AppContainer(
            widget: TextField(
              onChanged: searchCategory,
              controller: searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 12),
                hintText: "Search categories",
                border: InputBorder.none,
                prefixIcon: AppIconWidget(
                  assetPath: AssetImages.searchIcon,
                  size: 10,
                ).pad(12),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: mainApiCategoryStream.stream,
              initialData: categories,
              builder: (context, snapshot) {
                final catData = snapshot.data ?? [];
                // API is still loading
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // API finished but no categories found
                if (catData.isEmpty) {
                  return  CategoryNotFound(isFromCategory: true,);
                }
                // Data available
                return ListView.builder(
                  itemCount: catData.length,
                  //shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final cat = catData[index];
                    return buildTile(
                      categoryName: cat.name ?? '',
                      img: cat.imageUrl ?? '',
                      isSelected: selectedIndex == index,
                      value: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ).pad(16),
      bottomNavigationBar: SafeArea(
        child: (selectedIndex != null)
            ? AppButton(

          title: 'Next',
          onTap: () {
            final selectedCategory = categories[selectedIndex!];
            context.pushNamed(
              AppRoutes.subCategoryScreen,
              extra: {'category': selectedCategory,'postType': widget.postType,},

            );
          },
          icon: AssetImages.arrow_forward,
        ).pad(16)
            : const SizedBox(),
      ),
    );
  }

  Widget buildTile({
    required String categoryName,
    required String img,
    required bool isSelected,
    required int value,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = value;
        });
      },
      child: AppContainer(
        widget: Row(
          spacing: 10,
          children: [
            AppCachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              borderRadius: BorderRadius.circular(30),
            ),
            AppText(
              text: categoryName,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              maxLine: 2,
              textOverflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Radio<int>(
              hoverColor: AppColors.primaryColor,
              value: value,
              activeColor: AppColors.primaryColor,
              groupValue: selectedIndex,
              onChanged: (val) {
                setState(() {
                  selectedIndex = val;
                });
              },
            ),
          ],
        ).pad(5),
      ).padBottom(12),
    );
  }
}