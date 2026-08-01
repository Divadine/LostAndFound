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

class CategoryRadiosListsScreen extends StatefulWidget {
  const CategoryRadiosListsScreen({super.key});

  @override
  State<CategoryRadiosListsScreen> createState() =>
      _CategoryRadiosListsScreenState();
}

class _CategoryRadiosListsScreenState extends State<CategoryRadiosListsScreen> {
  final List<Map<String, dynamic>> products = [
    {
      "id": 1,
      "category": "Electronics",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvM3NbtpQg4MM517dpJ8SzhyEhQ0ZNTlS-bO79XfrZhA&s",
      "subCategories": [
        {
          "name": "Mobile",
          "fields": [
            {
              "key": "brand",
              "title": "Brand",
              "type": "dropdown",
              "options": [
                "Samsung",
                "Apple",
                "Redmi",
                "Realme"
              ]
            },
            {
              "key": "model",
              "title": "Model",
              "type": "text"
            },
            {
              "key": "color",
              "title": "Color",
              "type": "dropdown",
              "options": [
                "Black",
                "White",
                "Blue"
              ]
            },
            {
              "key": "image",
              "title": "Upload Image",
              "type": "image"
            }
          ]
        },
        {
          "name": "Laptop",
          "fields": [
            {
              "key": "brand",
              "title": "Brand",
              "type": "dropdown",
              "options": [
                "HP",
                "Dell",
                "Lenovo"
              ]
            },
            {
              "key": "ram",
              "title": "RAM",
              "type": "dropdown",
              "options": [
                "8 GB",
                "16 GB",
                "32 GB"
              ]
            }
          ]
        }
      ]
    },
    {
      "id": 2,
      "category": "Documents",
      "image": "https://digitalinspiration.com/static/d15fbd06120f76d62fd4eb1a55a8d52c/file-upload-forms.png",
      "subCategories": [
        {
          "name": "Aadhar Card",
          "fields": [
            {
              "key": "holderName",
              "title": "Holder Name",
              "type": "text"
            },
            {
              "key": "lastFour",
              "title": "Last 4 Digits",
              "type": "number"
            }
          ]
        }
      ]
    }
  ];
  TextEditingController searchController = TextEditingController();
  int? selectedIndex;
  List<Map<String, dynamic>> filteredCategory = [];

  @override
  void initState() {
    super.initState();
    filteredCategory = products;
  }
  void searchCategory(String value) {
    setState(() {
      filteredCategory = products
          .where(
            (item) => item['categoryName']!.toLowerCase().contains(
              value.toLowerCase(),
            ),
          )
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
          filteredCategory.isEmpty
              ? CategoryNotFound()
              : Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final cat = products[index];
                      return buildTile(
                        categoryName: cat['category'] ?? '',
                        img: cat['image'] ?? '',
                        isSelected: selectedIndex == index,
                        onTap: () {},
                        value: index,
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
              final selectedCategory =filteredCategory[selectedIndex!];
              context.pushNamed(AppRoutes.subCategoryScreen,extra:selectedCategory );

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
            AppText(text: categoryName,fontWeight: FontWeight.w500,fontSize: 14,maxLine: 2,textOverflow: TextOverflow.ellipsis,),
            Spacer(),

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
