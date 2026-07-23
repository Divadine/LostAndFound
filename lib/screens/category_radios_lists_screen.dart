import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class CategoryRadiosListsScreen extends StatefulWidget {
  const CategoryRadiosListsScreen({super.key});

  @override
  State<CategoryRadiosListsScreen> createState() =>
      _CategoryRadiosListsScreenState();
}

class _CategoryRadiosListsScreenState extends State<CategoryRadiosListsScreen> {
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
          SizedBox(height: 5),
          AppContainer(
            widget: TextField(
              onChanged: (value) {},

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
          Expanded(
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
    );
  }

  Widget buildTile({
    required String categoryName,
    required String img,
    required bool isSelected,
    required int value,
    required VoidCallback onTap,
  }) {
    return AppContainer(
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
    ).padBottom(12);
  }
}
