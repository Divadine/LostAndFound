import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final Map<String, dynamic> category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  List<Map<String, dynamic>> filteredCategory = [];

  TextEditingController searchController = TextEditingController();
  int? selectedIndex;

  StreamController<int?> selectedIndexStream = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    filteredCategory = List<Map<String, dynamic>>.from(
      widget.category["subCategories"] ?? [],
    );
    print(widget.category);
    print('filtered Category ------------>>>>>>>>>>>>>>>>>>>>>>>>>>>${filteredCategory}');
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
      selectedIndexStream.add(null);
      filteredCategory =
          List<Map<String, dynamic>>.from(
                widget.category["subCategories"] ?? [],
              )
              .where(
                (item) =>
                    item['name']!.toLowerCase().contains(value.toLowerCase()),
              )
              .toList();
      print("fffffffffff ${filteredCategory.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: SingleChildScrollView(
        child: Column(
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

            filteredCategory.isEmpty
                ? CategoryNotFound()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.category["subCategories"].length,
                    itemBuilder: (context, index) {
                      final cat = widget.category["subCategories"][index];
                      return StreamBuilder(
                        stream: selectedIndexStream.stream,
                        builder: (context, asyncSnapshot) {
                          final selectedValue = asyncSnapshot.data;
                          return buildTile(
                            categoryName: cat['name']!,
                            img: cat['image'] ?? '',
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
          ],
        ).pad(16),
      ),

      bottomNavigationBar: SafeArea(
        child: (selectedIndex != null)
            ? AppButton(
                title: 'Next',
                onTap: () {
                  final selectedSubCategory =
                      widget.category["subCategories"][selectedIndex!];
                  context.pushNamed(
                    AppRoutes.firstStepperScreen,
                    extra: {
                      'category': widget.category,
                      'subCategory': selectedSubCategory,
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
            AppCachedNetworkImage(
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
