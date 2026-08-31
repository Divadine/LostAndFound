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

  const SubCategoryScreen({super.key, required this.category, required this.postType});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<Map<String, dynamic>> filteredCategory = [];

  TextEditingController searchController = TextEditingController();
  int? selectedIndex;
  Timer? _debounce;
  List<SubCategoryModel> subCategories = [];
  bool isLoading = false;
  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );
  StreamController<int?> selectedIndexStream = StreamController.broadcast();
  StreamController<List<SubCategoryModel>> subCategoryStream = StreamController.broadcast();

  // ---------------------------------------------------------------------
  // Manually-added "Others" sub-category.
  // This is NOT returned by the API — we append it locally to the end of
  // the list every time sub-categories are (re)fetched. Selecting it and
  // pressing Next still goes through the normal FirstStepperScreen route,
  // but FirstStepperScreen's `_isGenericMode` getter already treats
  // subCategory.name == 'Others' as generic mode, so item-name/description
  // fields show automatically with no extra wiring needed there.
  //
  // NOTE: adjust `id` to whatever sentinel your backend expects for "no
  // real sub-category" (e.g. -1, 0, etc.), and confirm SubCategoryModel's
  // constructor field names match (id/name/subCategoryImg).
  // ---------------------------------------------------------------------
  // This is a GETTER, not a field, because `widget` (needed for
  // widget.category.id) isn't safely accessible from a field initializer —
  // field initializers run before the State is attached to its widget.
  SubCategoryModel get othersSubCategory => SubCategoryModel(
    id: -1,
    name: 'Others',
    subCategoryImg: '',
    categoryId: widget.category.id,
  );

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
    print(widget.category);
  }

  @override
  void dispose() {
    selectedIndexStream.close();
    searchController.dispose();
    super.dispose();
  }

  void searchCategory(String value) {
    setState(() {
      selectedIndex = null;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        _fetchSubCategories(search: value.trim().isEmpty ? null : value.trim());
      });
      print("fffffffffff ${filteredCategory.length}");
    });
  }

  Future<void> _fetchSubCategories({String? search}) async {
    setState(() {
      isLoading= true;
    });
    final response = await authController.getSubCategories(catId: widget.category.id,search: search);
    if(response.status == 1 && response.data != null){
      subCategories = [...response.data!, othersSubCategory];
      subCategoryStream.add(subCategories);
    }else {
      // Even on failure/empty response, still offer "Others" so the user
      // isn't blocked from posting.
      subCategories = [othersSubCategory];
      subCategoryStream.add(subCategories);
    }
    setState(() {
      isLoading= false;
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
            text: 'Select Sub-Category',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.primaryColor,
          ),
          AppText(
            text: 'Choose the Sub-Category that best matches your item',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: 5),

          AppContainer(
            widget: TextField(
              onChanged: (v) {
                searchCategory(v);
              },
              controller: searchController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 12),
                hintText: "Search categories",
                border: InputBorder.none,
                prefixIcon: AppIconWidget(
                  assetPath: AssetImages.searchIcon,
                  size: 10,
                ).pad(12),
              ),
            ),
          ),
          SizedBox(height: 5),

          StreamBuilder(
              stream: subCategoryStream.stream,
              initialData:subCategories,
              builder: (context, asyncSnapshot) {
                final subCat = asyncSnapshot.data ?? [];
                // API/search is still loading
                if (isLoading) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // API finished but no data
                if (subCat.isEmpty) {
                  return const Expanded(
                    child: CategoryNotFound(
                      isFromCategory: false,
                    ),
                  );
                }
                return

                  Expanded(
                    child: ListView.builder(

                      itemCount: subCat.length,
                      itemBuilder: (context, index) {
                        final cat = subCat[index];
                        return StreamBuilder(
                          stream: selectedIndexStream.stream,
                          builder: (context, asyncSnapshot) {
                            final selectedValue = asyncSnapshot.data;
                            return buildTile(
                              categoryName: cat.name,
                              img: cat.subCategoryImg ?? '',
                              isSelected: selectedValue == index,
                              onTap: () {
                                setState(() {

                                });
                                selectedIndex = index;
                                print("jjjjjjjjjj$selectedIndex");
                                selectedIndexStream.add(selectedIndex);

                              },

                              value: index,
                              onChange: (int? value) {
                                selectedIndex = value;
                                selectedIndexStream.add(selectedIndex);
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
              }
          ),
        ],
      ).pad(16),

      bottomNavigationBar: SafeArea(
        child: (selectedIndex != null)
            ? AppButton(
          title: 'Next',
          onTap: () {
            final selectedSubCategory =
            subCategories[selectedIndex!];
            context.pushNamed(
              AppRoutes.firstStepperScreen,
              extra: {
                'category': widget.category,
                'subCategory': selectedSubCategory,
                'postType': widget.postType,
              },
            );
          },
          icon: AssetImages.arrow_forward,
        ).pad(16)
            : SizedBox(),
      ),
    );
  }

  Widget buildTile({
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
          spacing: 20,
          children: [
            // "Others" has no real image (subCategoryImg is intentionally
            // empty), so fall back to a simple icon instead of hitting the
            // network / showing a broken-image placeholder.
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
            AppText(text: categoryName),
            Spacer(),

            Radio<int>(
              hoverColor: AppColors.primaryColor,
              value: value,
              activeColor: AppColors.primaryColor,
              groupValue: selectedIndex,
              onChanged: onChange,
            ),
          ],
        ).pad(5),
      ).padBottom(12),
    );
  }
}