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

  const CategoryRadiosListsScreen({
    super.key,
    required this.postType,
  });

  @override
  State<CategoryRadiosListsScreen> createState() =>
      _CategoryRadiosListsScreenState();
}

class _CategoryRadiosListsScreenState
    extends State<CategoryRadiosListsScreen> {
  // ===========================================================================
  // CONTROLLER
  // ===========================================================================

  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  final TextEditingController searchController =
  TextEditingController();

  Timer? _debounce;

  // ===========================================================================
  // DATA
  // ===========================================================================

  List<CategoryModel> categories = [];

  List<CategoryModel> apiCategories = [];

  // ===========================================================================
  // STATE
  // ===========================================================================

  int? selectedIndex;

  bool isLoading = false;

  // ===========================================================================
  // STREAM
  // ===========================================================================

  final StreamController<List<CategoryModel>>
  mainApiCategoryStream =
  StreamController<List<CategoryModel>>.broadcast();

  // ===========================================================================
  // OTHERS
  // ===========================================================================

  final CategoryModel othersCategory = CategoryModel(
    id: -1,
    name: 'Others',
    imageUrl: '',
  );

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _fetchCategories();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();

    if (!mainApiCategoryStream.isClosed) {
      mainApiCategoryStream.close();
    }

    super.dispose();
  }

  // ===========================================================================
  // FETCH
  // ===========================================================================

  Future<void> _fetchCategories({
    int? limit,
    int? page,
    String? search,
  }) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      selectedIndex = null;
    });

    try {
      final response = await authController.getCategories(
        page: page ?? 0,
        limit: limit ?? 0,
        search: search,
      );

      if (!mounted) return;

      if (response.data != null) {
        apiCategories = List<CategoryModel>.from(
          response.data!.categories,
        );
      } else {
        apiCategories = [];
      }

      if (apiCategories.isNotEmpty) {
        categories = [
          ...apiCategories,
          othersCategory,
        ];
      } else {
        categories = [];
      }

      if (!mainApiCategoryStream.isClosed) {
        mainApiCategoryStream.add(
          List<CategoryModel>.from(categories),
        );
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
        selectedIndex = null;
      });
    } catch (e, stackTrace) {
      debugPrint('CATEGORY API ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      categories = [];
      apiCategories = [];

      if (!mainApiCategoryStream.isClosed) {
        mainApiCategoryStream.add([]);
      }

      setState(() {
        isLoading = false;
        selectedIndex = null;
      });
    }
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void searchCategory(String value) {
    if (!mounted) return;

    setState(() {
      selectedIndex = null;
    });

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
        if (!mounted) return;

        final searchValue = value.trim();

        _fetchCategories(
          search: searchValue.isEmpty ? null : searchValue,
        );
      },
    );
  }

  // ===========================================================================
  // RETRY
  // ===========================================================================

  Future<void> _retryCategories() async {
    final searchValue = searchController.text.trim();

    await _fetchCategories(
      search: searchValue.isEmpty ? null : searchValue,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primaryColor,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Select Category',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.primaryColor,
            ),

            const SizedBox(height: 10),

            AppText(
              text:
              'Choose the Category that best matches your item',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),

            const SizedBox(height: 15),

            AppContainer(
              widget: TextField(
                controller: searchController,
                onChanged: searchCategory,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                    top: 12,
                    right: 12,
                  ),
                  hintText: 'Search categories',
                  border: InputBorder.none,
                  prefixIcon: AppIconWidget(
                    assetPath: AssetImages.searchIcon,
                    size: 10,
                  ).pad(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // IMPORTANT:
            // Expanded is directly inside Column.
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: mainApiCategoryStream.stream,
                initialData: categories,
                builder: (context, snapshot) {
                  final catData = snapshot.data ?? [];

                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (catData.isEmpty) {
                    return CategoryNotFound(
                      key: const ValueKey('category_not_found'),
                      isFromCategory: true,
                      onRetry: _retryCategories,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: catData.length,
                    itemBuilder: (context, index) {
                      final category = catData[index];

                      return _buildTile(
                        categoryName:
                        category.name ?? '',
                        img:
                        category.imageUrl ?? '',
                        isSelected:
                        selectedIndex == index,
                        value: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: selectedIndex != null
            ? AppButton(
          title: 'Next',
          icon: AssetImages.arrow_forward,
          onTap: _onNext,
        ).pad(16)
            : const SizedBox.shrink(),
      ),
    );
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  void _onNext() {
    if (selectedIndex == null) return;

    if (selectedIndex! < 0 ||
        selectedIndex! >= categories.length) {
      return;
    }

    final selectedCategory =
    categories[selectedIndex!];

    final categoryName =
    (selectedCategory.name ?? '')
        .trim()
        .toLowerCase();

    final bool isOthers =
        categoryName == 'others';

    if (!mounted) return;

    if (isOthers) {
      context.pushNamed(
        AppRoutes.firstStepperScreen,
        extra: {
          'category': selectedCategory,
          'subCategory': null,
          'postType': widget.postType,
        },
      );

      return;
    }

    context.pushNamed(
      AppRoutes.subCategoryScreen,
      extra: {
        'category': selectedCategory,
        'postType': widget.postType,
      },
    );
  }

  // ===========================================================================
  // TILE
  // ===========================================================================

  Widget _buildTile({
    required String categoryName,
    required String img,
    required bool isSelected,
    required int value,
  }) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;

        setState(() {
          selectedIndex = value;
        });
      },
      child: AppContainer(
        widget: Row(
          children: [
            img.isEmpty
                ? Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color:
                AppColors.primaryColor
                    .withAlpha(30),
                borderRadius:
                BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.more_horiz,
                color:
                AppColors.primaryColor,
              ),
            )
                : AppCachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              borderRadius:
              BorderRadius.circular(30),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: AppText(
                text: categoryName,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                maxLine: 2,
                textOverflow:
                TextOverflow.ellipsis,
              ),
            ),

            Radio<int>(
              value: value,
              groupValue: selectedIndex,
              activeColor:
              AppColors.primaryColor,
              hoverColor:
              AppColors.primaryColor,
              onChanged: (val) {
                if (!mounted || val == null) {
                  return;
                }

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