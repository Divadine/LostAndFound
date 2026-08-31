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
  // ---------------------------------------------------------------------------
  // Controller
  // ---------------------------------------------------------------------------

  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------

  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  List<CategoryModel> categories = [];

  /// Stores only categories received from API.
  ///
  /// This is important because "Others" is manually added and should not
  /// affect the "No Categories Found" condition.
  List<CategoryModel> apiCategories = [];

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  int? selectedIndex;

  bool isLoading = false;

  // ---------------------------------------------------------------------------
  // Stream
  // ---------------------------------------------------------------------------

  final StreamController<List<CategoryModel>> mainApiCategoryStream =
  StreamController<List<CategoryModel>>.broadcast();

  // ---------------------------------------------------------------------------
  // Others category
  // ---------------------------------------------------------------------------

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
    mainApiCategoryStream.close();

    super.dispose();
  }

  // ===========================================================================
  // FETCH CATEGORIES
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
      debugPrint('========================================');
      debugPrint('FETCH CATEGORIES');
      debugPrint('Search: $search');
      debugPrint('Page: ${page ?? 0}');
      debugPrint('Limit: ${limit ?? 0}');
      debugPrint('========================================');

      final response = await authController.getCategories(
        page: page ?? 0,
        limit: limit ?? 0,
        search: search,
      );

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // API SUCCESS
      // -----------------------------------------------------------------------

      if (response.data != null) {
        apiCategories = List<CategoryModel>.from(
          response.data!.categories,
        );

        debugPrint(
          'API categories count: ${apiCategories.length}',
        );
      } else {
        apiCategories = [];

        debugPrint('API returned null data');
      }

      // -----------------------------------------------------------------------
      // IMPORTANT
      //
      // If API has categories:
      //     categories = API categories + Others
      //
      // If API has no categories:
      //     categories = []
      //
      // This allows CategoryNotFound to actually appear.
      // -----------------------------------------------------------------------

      if (apiCategories.isNotEmpty) {
        categories = [
          ...apiCategories,
          othersCategory,
        ];
      } else {
        categories = [];
      }

      // -----------------------------------------------------------------------
      // Update stream
      // -----------------------------------------------------------------------

      mainApiCategoryStream.add(
        List<CategoryModel>.from(categories),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('CATEGORY API ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      // On API error, don't show Others as if the API succeeded.
      categories = [];
      apiCategories = [];

      mainApiCategoryStream.add([]);

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
    // Reset selected category when searching.
    setState(() {
      selectedIndex = null;
    });

    // Cancel previous debounce.
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
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

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          // -------------------------------------------------------------------
          // TITLE
          // -------------------------------------------------------------------

          AppText(
            text: 'Select Category',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.primaryColor,
          ),

          // -------------------------------------------------------------------
          // SUBTITLE
          // -------------------------------------------------------------------

          AppText(
            text: 'Choose the Category that best matches your item',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),

          const SizedBox(height: 5),

          // -------------------------------------------------------------------
          // SEARCH
          // -------------------------------------------------------------------

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

          const SizedBox(height: 5),

          // -------------------------------------------------------------------
          // CATEGORY LIST
          // -------------------------------------------------------------------

          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: mainApiCategoryStream.stream,

              initialData: categories,

              builder: (context, snapshot) {
                final catData = snapshot.data ?? [];

                // -------------------------------------------------------------
                // LOADING
                // -------------------------------------------------------------

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // -------------------------------------------------------------
                // EMPTY
                // -------------------------------------------------------------

                if (catData.isEmpty) {
                  return CategoryNotFound(
                    isFromCategory: true,
                    onRetry: _retryCategories,
                  );
                }

                // -------------------------------------------------------------
                // DATA AVAILABLE
                // -------------------------------------------------------------

                return ListView.builder(
                  itemCount: catData.length,

                  itemBuilder: (context, index) {
                    final category = catData[index];

                    return _buildTile(
                      categoryName: category.name ?? '',
                      img: category.imageUrl ?? '',
                      isSelected: selectedIndex == index,
                      value: index,
                    );
                  },
                ).pad();
              },
            ),
          ),
        ],
      ).pad(16),

      // =========================================================================
      // NEXT BUTTON
      // =========================================================================

      bottomNavigationBar: SafeArea(
        child: selectedIndex != null
            ? AppButton(
          title: 'Next',

          icon: AssetImages.arrow_forward,

          onTap: _onNext,

        ).pad(16)
            : const SizedBox(),
      ),
    );
  }

  // ===========================================================================
  // NEXT BUTTON ACTION
  // ===========================================================================

  void _onNext() {
    if (selectedIndex == null) return;

    if (selectedIndex! < 0 ||
        selectedIndex! >= categories.length) {
      return;
    }

    final selectedCategory = categories[selectedIndex!];

    final categoryName =
    (selectedCategory.name ?? '').trim().toLowerCase();

    final bool isOthers = categoryName == 'others';

    debugPrint('========================================');
    debugPrint('SELECTED CATEGORY');
    debugPrint('Name: ${selectedCategory.name}');
    debugPrint('ID: ${selectedCategory.id}');
    debugPrint('Is Others: $isOthers');
    debugPrint('========================================');

    // =========================================================================
    // OTHERS
    //
    // Skip sub-category screen.
    // Go directly to FirstStepperScreen.
    // =========================================================================

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

    // =========================================================================
    // NORMAL CATEGORY
    //
    // Go to sub-category screen.
    // =========================================================================

    context.pushNamed(
      AppRoutes.subCategoryScreen,
      extra: {
        'category': selectedCategory,
        'postType': widget.postType,
      },
    );
  }

  // ===========================================================================
  // CATEGORY TILE
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
          spacing: 10,
          children: [
            // -----------------------------------------------------------------
            // IMAGE
            // -----------------------------------------------------------------

            img.isEmpty
                ? Container(
              height: 50,
              width: 50,

              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(30),
              ),

              child: const Icon(
                Icons.more_horiz,
                color: AppColors.primaryColor,
              ),
            )
                : AppCachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              borderRadius: BorderRadius.circular(30),
            ),

            // -----------------------------------------------------------------
            // NAME
            // -----------------------------------------------------------------

            Expanded(
              child: AppText(
                text: categoryName,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                maxLine: 2,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),

            // -----------------------------------------------------------------
            // RADIO
            // -----------------------------------------------------------------

            Radio<int>(
              value: value,
              groupValue: selectedIndex,
              activeColor: AppColors.primaryColor,
              hoverColor: AppColors.primaryColor,

              onChanged: (val) {
                if (!mounted) return;

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