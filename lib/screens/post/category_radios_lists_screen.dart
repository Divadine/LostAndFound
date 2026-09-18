import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
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

  // ✅ Track the selected category by its stable id instead of its
  // position in the list. Search re-fetches and rebuilds `categories`,
  // so an index-based selection ("selectedIndex") would point at a
  // completely different item (or nothing) once the list changes shape.
  // Tracking the id means the previously chosen category stays visually
  // selected across a search, as long as it's still present in the results.
  int? selectedCategoryId;

  bool isLoading = false;
  bool isMoreLoading = false;
  int currentPage = 1;
  int totalCategories = 0;
  final int limit = 10;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  final ScrollController _scrollController = ScrollController();

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !isMoreLoading &&
          apiCategories.length < totalCategories) {
        currentPage++;
        _fetchCategories(isLoadMore: true, search: searchController.text.trim());
      }
    });

    _initConnectivityListener();
    _fetchCategories();
  }

  void _initConnectivityListener() async {
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOfflineStatus);
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;
    setState(() {
      _isOffline = offline;
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _debounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();

    if (!mainApiCategoryStream.isClosed) {
      mainApiCategoryStream.close();
    }

    super.dispose();
  }

  // ===========================================================================
  // FETCH
  // ===========================================================================

  Future<void> _fetchCategories({
    String? search,
    bool isLoadMore = false,
  }) async {
    if (!mounted) return;

    if (_isOffline && !isLoadMore) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      if (isLoadMore) {
        isMoreLoading = true;
      } else {
        isLoading = true;
        currentPage = 1;
        apiCategories.clear();
        // ✅ NOT resetting selectedCategoryId here anymore.
        // Previously this cleared selection on every search/refresh.
        // The chosen category should remain selected across a search
        // unless the user explicitly picks a different one.
      }
    });

    try {
      final response = await authController.getCategories(
        page: currentPage,
        limit: limit,
        search: search,
      );

      if (!mounted) return;

      if (response.data != null) {
        totalCategories = response.data!.total;
        if (isLoadMore) {
          apiCategories.addAll(response.data!.categories);
        } else {
          apiCategories = List<CategoryModel>.from(response.data!.categories);
        }
      }

      if (apiCategories.isNotEmpty) {
        categories = [
          ...apiCategories,
          othersCategory,
        ];
      } else {
        categories = [othersCategory];
      }

      if (!mainApiCategoryStream.isClosed) {
        mainApiCategoryStream.add(List<CategoryModel>.from(categories));
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('CATEGORY API ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
    }
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void searchCategory(String value) {
    if (!mounted) return;

    // ✅ No longer clearing selectedCategoryId here.
    // The previously selected category should stay selected while typing
    // a search query; it will only change if the user taps a different tile.
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
      resizeToAvoidBottomInset : false,
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
                inputFormatters: [NoLeadingSpaceFormatter()],
                onChanged: searchCategory,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                    top: 12,
                    right: 12,
                  ),
                  hintText: 'Search categories',
                  hintStyle: TextStyle(color: AppColors.searchColor),
                  border: InputBorder.none,
                  prefixIcon: AppIconWidget(
                    assetPath: AssetImages.searchIcon,
                    size: 10,
                  ).pad(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // IMPORTANT:
            // Expanded is directly inside Column.
            Expanded(
              child: _isOffline
                  ? const NoInternetWidget()
                  : StreamBuilder<List<CategoryModel>>(
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
                    padding: const EdgeInsets.only(top: 4),
                    controller: _scrollController,

                    itemCount: catData.length + (isMoreLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == catData.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isOffline
                              ? const NoInternetWidget(size: 50)
                              : const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final category = catData[index];

                      return _buildTile(
                        categoryName: category.name ?? '',
                        img: category.imageUrl ?? '',
                        categoryId: category.id,
                        // ✅ Selection is now determined by matching ids,
                        // not by matching the tile's index in the list.
                        isSelected: selectedCategoryId != null &&
                            selectedCategoryId == category.id,
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
        child: (selectedCategoryId != null && !_isOffline)
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
    if (selectedCategoryId == null) return;

    // ✅ Look the category up by id rather than indexing into `categories`,
    // since selectedCategoryId no longer corresponds to a fixed position.
    CategoryModel? selectedCategory;
    for (final c in categories) {
      if (c.id == selectedCategoryId) {
        selectedCategory = c;
        break;
      }
    }
    selectedCategory ??= othersCategory;

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
    required int? categoryId,
  }) {
    void selectThis() {
      if (!mounted) return;

      setState(() {
        selectedCategoryId = categoryId;
      });
    }

    return GestureDetector(
      onTap: selectThis,
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

            // ===================================================================
            // SELECTION INDICATOR
            // -------------------------------------------------------------------
            // Using a plain Radio<int> here was matching selectedCategoryId
            // against category id with `value == groupValue`, and when that
            // check silently failed (nullable/type mismatch upstream in the
            // model, or timing with setState), Radio still paints its outer
            // ring but never paints the inner filled dot — which is exactly
            // the "border shows, dot doesn't" symptom.
            //
            // Instead, this custom indicator is driven directly off the
            // `isSelected` boolean already computed above from
            // `selectedCategoryId == category.id`. There's no separate
            // internal state for it to disagree with: if the row is
            // selected, the dot is always in the tree.
            // ===================================================================
            GestureDetector(
              onTap: selectThis,
              child: Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                    : null,
              ),
            ),
          ],
        ).pad(5),
      ).padBottom(12),
    );
  }
}