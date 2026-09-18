import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
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

class SubCategoryScreen extends StatefulWidget {
  final CategoryModel category;
  final int postType;

  const SubCategoryScreen({
    super.key,
    required this.category,
    required this.postType,
  });

  @override
  State<SubCategoryScreen> createState() =>
      _SubCategoryScreenState();
}

class _SubCategoryScreenState
    extends State<SubCategoryScreen> {
  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController searchController =
  TextEditingController();

  final AuthControllers authController =
  AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  Timer? _debounce;

  // ===========================================================================
  // DATA
  // ===========================================================================

  List<SubCategoryModel> apiSubCategories = [];

  List<SubCategoryModel> subCategories = [];

  // ===========================================================================
  // STATE
  // ===========================================================================

  // ✅ Track the selected sub-category by its stable id instead of its
  // position in the list. Searching re-fetches and rebuilds `subCategories`,
  // so an index-based selection would point at a different item (or nothing)
  // once the list changes shape after a search.
  int? selectedSubCategoryId;

  bool isLoading = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  // ===========================================================================
  // STREAM
  // ===========================================================================

  final StreamController<List<SubCategoryModel>>
  subCategoryStream =
  StreamController<List<SubCategoryModel>>.broadcast();

  // ===========================================================================
  // OTHERS
  // ===========================================================================

  SubCategoryModel get othersSubCategory {
    return SubCategoryModel(
      id: -1,
      name: 'Others',
      subCategoryImg: '',
      categoryId: widget.category.id,
    );
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    debugPrint(
      'Selected Category: ${widget.category.name}',
    );

    debugPrint(
      'Selected Category ID: ${widget.category.id}',
    );

    _initConnectivityListener();
    _fetchSubCategories();
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

    if (!subCategoryStream.isClosed) {
      subCategoryStream.close();
    }

    super.dispose();
  }

  // ===========================================================================
  // BACK
  // ===========================================================================

  void _goBackToCategory() {
    if (!mounted) return;

    // This pops ONLY SubCategoryScreen.
    // The previous CategoryRadiosListsScreen remains in the stack.
    context.pop();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void searchCategory(String value) {
    if (!mounted) return;

    // ✅ No longer clearing selectedSubCategoryId here.
    // The previously selected sub-category should remain selected while
    // the user is typing a search query; it only changes if they tap a
    // different tile.
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
        if (!mounted) return;

        final searchValue = value.trim();

        _fetchSubCategories(
          search:
          searchValue.isEmpty
              ? null
              : searchValue,
        );
      },
    );
  }

  // ===========================================================================
  // RETRY
  // ===========================================================================

  Future<void> _retrySubCategories() async {
    final searchValue =
    searchController.text.trim();

    await _fetchSubCategories(
      search:
      searchValue.isEmpty
          ? null
          : searchValue,
    );
  }

  // ===========================================================================
  // FETCH
  // ===========================================================================

  Future<void> _fetchSubCategories({
    String? search,
  }) async {
    if (!mounted) return;

    if (_isOffline) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      // ✅ Removed `selectedSubCategoryId = null;` here — keep the prior
      // pick across a fetch triggered by search. If the selected item is
      // no longer present in the new results, the radio/dot for it simply
      // won't render as selected on any visible tile, and the bottom "Next"
      // button check further down still works off the id.
    });

    try {
      debugPrint(
        'FETCH SUB CATEGORIES',
      );

      debugPrint(
        'Category ID: ${widget.category.id}',
      );

      debugPrint(
        'Search: $search',
      );

      final response =
      await authController.getSubCategories(
        catId: widget.category.id,
        search: search,
      );

      if (!mounted) return;

      if (response.status == 1 &&
          response.data != null) {
        apiSubCategories =
        List<SubCategoryModel>.from(
          response.data!,
        );
      } else {
        apiSubCategories = [];
      }

      if (apiSubCategories.isNotEmpty) {
        subCategories = [
          ...apiSubCategories,
          othersSubCategory,
        ];
      } else {
        subCategories = [othersSubCategory];
      }

      if (!subCategoryStream.isClosed) {
        subCategoryStream.add(
          List<SubCategoryModel>.from(
            subCategories,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
        // ✅ selectedSubCategoryId intentionally left untouched here too.
      });
    } catch (e, stackTrace) {
      debugPrint(
        'SUB CATEGORY API ERROR',
      );

      debugPrint('$e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      apiSubCategories = [];
      subCategories = [];

      if (!subCategoryStream.isClosed) {
        subCategoryStream.add([]);
      }

      setState(() {
        isLoading = false;
        // ✅ selectedSubCategoryId intentionally left untouched here too.
      });
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) {

      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor:
          AppColors.primaryColor,
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Select Sub-Category',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color:
                AppColors.primaryColor,
              ),

              const SizedBox(height: 10),

              AppText(
                text:
                'Choose the Sub-Category that best matches your item',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 15),

              AppContainer(
                widget: TextField(
                  controller:
                  searchController,
                  inputFormatters: [NoLeadingSpaceFormatter()],
                  onChanged:
                  searchCategory,
                  textInputAction:
                  TextInputAction.search,
                  decoration:
                  InputDecoration(
                    contentPadding:
                    const EdgeInsets.only(
                      top: 12,
                      right: 12,
                    ),
                    hintText:
                    'Search sub-categories',
                    hintStyle: TextStyle(color: AppColors.searchColor),
                    border:
                    InputBorder.none,
                    prefixIcon:
                    AppIconWidget(
                      assetPath:
                      AssetImages
                          .searchIcon,
                      size: 10,
                    ).pad(12),
                  ),
                ),
              ),

              const SizedBox(height: 15),


              Expanded(
                child: _isOffline
                    ? const NoInternetWidget()
                    : StreamBuilder<List<SubCategoryModel>>(
                  stream: subCategoryStream.stream,
                  initialData: subCategories,
                  builder: (context, snapshot) {
                    final subCat = snapshot.data ?? [];

                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // if (subCat.isEmpty) {
                    //   return CategoryNotFound(
                    //     key: const ValueKey(
                    //       'subcategory_not_found',
                    //     ),
                    //     isFromCategory:
                    //     false,
                    //     onRetry:
                    //     _retrySubCategories,
                    //   );
                    // }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount:
                      subCat.length,
                      itemBuilder:
                          (context, index) {
                        final subCategory =
                        subCat[index];

                        return _buildTile(
                          categoryName:
                          subCategory
                              .name ??
                              '',
                          img:
                          subCategory
                              .subCategoryImg ??
                              '',
                          // ✅ Selection is determined by matching ids,
                          // not by matching the tile's index in the list.
                          isSelected:
                          selectedSubCategoryId != null &&
                              selectedSubCategoryId == subCategory.id,
                          subCategoryId: subCategory.id,
                          onTap: () {
                            _selectSubCategory(
                              subCategory.id,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar:
        SafeArea(
          child: (selectedSubCategoryId != null && !_isOffline)
              ? AppButton(
            title: 'Next',
            icon: AssetImages.arrow_forward,
            onTap: _onNext,
          ).pad(16)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECT
  // ===========================================================================

  void _selectSubCategory(
      int? subCategoryId,
      ) {
    if (!mounted) return;

    setState(() {
      selectedSubCategoryId = subCategoryId;
    });
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  void _onNext() {
    if (selectedSubCategoryId == null) {
      return;
    }

    // ✅ Look the sub-category up by id rather than indexing into
    // `subCategories`, since selectedSubCategoryId no longer corresponds
    // to a fixed position after a search re-fetch.
    SubCategoryModel? selectedSubCategory;
    for (final s in subCategories) {
      if (s.id == selectedSubCategoryId) {
        selectedSubCategory = s;
        break;
      }
    }
    selectedSubCategory ??= othersSubCategory;

    if (!mounted) return;

    context.pushNamed(
      AppRoutes.firstStepperScreen,
      extra: {
        'category': widget.category,
        'subCategory':
        selectedSubCategory,
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
    required int? subCategoryId,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        widget: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppText(

                  text: categoryName,
                  fontWeight:
                  FontWeight.w500,
                  fontSize: 14,
                  maxLine: 2,
                  textOverflow:
                  TextOverflow.ellipsis,
                ),
              ),
            ),

            // ===================================================================
            // SELECTION INDICATOR
            // -------------------------------------------------------------------
            // Same fix as the category screen: a plain Radio<int> relies on
            // its own `value == groupValue` check internally, and if that
            // silently fails (nullable id, type mismatch, timing), Radio
            // still draws the outer ring but never the inner filled dot.
            //
            // This custom indicator is driven directly off the `isSelected`
            // boolean computed above from
            // `selectedSubCategoryId == subCategory.id`, so the dot always
            // matches what's actually selected.
            // ===================================================================
            GestureDetector(
              onTap: onTap,
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