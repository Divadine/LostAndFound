import 'dart:async';

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

  int? selectedIndex;

  bool isLoading = false;

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

    _fetchSubCategories();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
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

    setState(() {
      selectedIndex = null;
    });

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

    setState(() {
      isLoading = true;
      selectedIndex = null;
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
        subCategories = [];
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
        selectedIndex = null;
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
        selectedIndex = null;
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
        // Do not call pop here.
        //
        // GoRouter/Flutter already handles the system
        // back button because canPop = true.
      },
      child: Scaffold(
        backgroundColor: AppColors.white,

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

              // IMPORTANT:
              // Expanded directly inside Column.
              Expanded(
                child: StreamBuilder<
                    List<SubCategoryModel>>(
                  stream:
                  subCategoryStream.stream,
                  initialData:
                  subCategories,
                  builder:
                      (context, snapshot) {
                    final subCat =
                        snapshot.data ??
                            [];

                    if (isLoading) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    if (subCat.isEmpty) {
                      return CategoryNotFound(
                        key: const ValueKey(
                          'subcategory_not_found',
                        ),
                        isFromCategory:
                        false,
                        onRetry:
                        _retrySubCategories,
                      );
                    }

                    return ListView.builder(
                      padding:
                      EdgeInsets.zero,
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
                          isSelected:
                          selectedIndex ==
                              index,
                          value: index,
                          onTap: () {
                            _selectSubCategory(
                              index,
                            );
                          },
                          onChange:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            _selectSubCategory(
                              value,
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
          child: selectedIndex != null
              ? AppButton(
            title: 'Next',
            icon: AssetImages
                .arrow_forward,
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
      int index,
      ) {
    if (!mounted) return;

    if (index < 0 ||
        index >= subCategories.length) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });

    debugPrint(
      'Selected sub-category index: $index',
    );

    debugPrint(
      'Selected sub-category: '
          '${subCategories[index].name}',
    );
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  void _onNext() {
    if (selectedIndex == null) {
      return;
    }

    if (selectedIndex! < 0 ||
        selectedIndex! >=
            subCategories.length) {
      return;
    }

    final selectedSubCategory =
    subCategories[selectedIndex!];

    debugPrint(
      'SELECTED SUB CATEGORY',
    );

    debugPrint(
      'Category: ${widget.category.name}',
    );

    debugPrint(
      'Category ID: ${widget.category.id}',
    );

    debugPrint(
      'Sub Category: '
          '${selectedSubCategory.name}',
    );

    debugPrint(
      'Sub Category ID: '
          '${selectedSubCategory.id}',
    );

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
    required int value,
    required VoidCallback onTap,
    required ValueChanged<int?> onChange,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        widget: Row(
          children: [
            img.isEmpty
                ? Container(
              height: 50,
              width: 50,
              decoration:
              BoxDecoration(
                color:
                AppColors
                    .primaryColor
                    .withAlpha(
                    30),
                borderRadius:
                BorderRadius
                    .circular(
                    30),
              ),
              child:
              const Icon(
                Icons.more_horiz,
                color: AppColors
                    .primaryColor,
              ),
            )
                : AppCachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              borderRadius:
              BorderRadius
                  .circular(30),
            ),

            const SizedBox(width: 20),

            Expanded(
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

            Radio<int>(
              value: value,
              groupValue:
              selectedIndex,
              activeColor:
              AppColors.primaryColor,
              hoverColor:
              AppColors.primaryColor,
              onChanged: onChange,
            ),
          ],
        ).pad(5),
      ).padBottom(12),
    );
  }
}