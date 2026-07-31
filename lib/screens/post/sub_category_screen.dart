import 'package:flutter/material.dart';
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
  const SubCategoryScreen({super.key});

  @override
  State<SubCategoryScreen> createState() =>
      _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {


  List<Map<String, String>> category = [
    {
      'categoryName': 'Dinesh',
      'img':
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRBsa5c2bVIPpKs5m1eXf3Y5mlLeqVhbTr1YfAXWYkvRgEZmbyakF7cGc&s=10',
    },

    {
      'categoryName': 'Kumar',
      'img':
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRBsa5c2bVIPpKs5m1eXf3Y5mlLeqVhbTr1YfAXWYkvRgEZmbyakF7cGc&s=10',
    },
  ];
  TextEditingController searchController = TextEditingController();
  int? selectedIndex;
  List<Map<String, String>> filteredCategory = [];


  @override
  void initState() {
    super.initState();
    filteredCategory = category;
  }

  void searchCategory(String value) {
    setState(() {
      filteredCategory = category
          .where((item) => item['categoryName']!
          .toLowerCase()
          .contains(value.toLowerCase()))
          .toList();
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
              onChanged: searchCategory,

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
          filteredCategory.isEmpty ? CategoryNotFound() : Expanded(
            child: ListView.builder(
              itemCount: category.length,
              itemBuilder: (context, index) {
                final cat = category[index];
                return buildTile(
                  categoryName: cat['categoryName']!,
                  img: cat['img']!,
                  isSelected: selectedIndex == index,
                  onTap: () {},
                  value:index,
                );
              },
            ),
          ),
        ],
      ).pad(16),

      bottomNavigationBar: SafeArea(
        child:

        (selectedIndex != null) ? AppButton(
          title: 'Next',
          onTap: () {
            AppRoutes.pushNamed(AppRoutes.firstStepperScreen);
          },
          icon: AssetImages.arrow_forward,
        ).pad(16) : SizedBox(),
      ),
    );
  }

  Widget buildTile({
    required String categoryName,
    required String img,
    required bool isSelected,
    required int value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: (){
        setState(() {
          selectedIndex = value;
        });
      },
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
              onChanged: (val){
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
