import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_dropdown_field.dart';
import 'package:lost_and_found/shared_widgets/app_image_upload_file.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';

import '../../utils/app_ui_helper.dart';

class FirstStepperScreen extends StatefulWidget {
  final Map<String, dynamic> subCategory;
  const FirstStepperScreen({super.key,  required this.subCategory});

  @override
  State<FirstStepperScreen> createState() => _FirstStepperScreenState();
}

class _FirstStepperScreenState extends State<FirstStepperScreen> {

  List<Map<String,dynamic>> filteredSubCategory =[];
  late String pickedFile;


  @override
  void initState(){
    super.initState();

    filteredSubCategory = widget.subCategory['fields'];
    print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^$filteredSubCategory');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Post Lost Item',
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
        leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () {
          AppRoutes.pop();
        },
      ),

      body: ListView.builder(
        itemCount: filteredSubCategory.length,
        itemBuilder: (context, index) {
          final field= filteredSubCategory[index];

          switch(field['type']) {
            case "text" :
              return buildTextFieldWithHeading(
                title:field['title'],
                fieldWidget: AppTextField(
                  borderColor: AppColors.fieldGrey,
                 borderRadius:BorderRadius.circular(5),
                  hintText: '',
                  textController: TextEditingController(),
                  onChange: (v) {},
                  onSubmit: (v) {},
                ).pad(),
              ).pad();

            case 'number' :
              return buildTextFieldWithHeading(
                title: field['title'] ?? '',
                fieldWidget: AppTextField(
                  // borderRadius: BorderRadius.circular(10),
                  borderColor: AppColors.fieldGrey,
                  hintText: '',
                  textController: TextEditingController(),
                  onChange: (v) {},
                  onSubmit: (v) {},
                ).pad(),
              ).pad();

            case "dropdown":
              return buildTextFieldWithHeading(
                title: field['title'] ?? '',
                fieldWidget: AppDropdownField<String>(
                  borderColor: AppColors.fieldGrey,
                  value: field['selectedValue'] as String?,
                  hintText: 'Select ${field['title'] ?? 'item'}',
                  items: List<String>.from(field['options'] ?? []),
                  itemLabel: (e) => e,
                  selectedItemColor: AppColors.primaryColor.withAlpha(30),
                  selectedItemTextColor: AppColors.primaryColor,
                  onChanged: (v) => setState(() => field['selectedValue'] = v),
                ).pad(),
              ).pad();

            case "image":
              return AppImageUploadField(
                title: 'Upload Image',
                images: field['pickedImages'] ?? [],
                maxImages: field['maxImages'] ?? 4,
                onAdd: () async {


                },
                onRemove: (i) => setState(() => (field['pickedImages'] as List).removeAt(i)),
              );



            default :
              return SizedBox();
          }
        },
      ),
      bottomNavigationBar:  AppButton(
        radius: BorderRadius.circular(5),
        title: 'Next',
        onTap: () {
          AppRoutes.pushNamed(AppRoutes.secondStepperScreen);
        },
      ).pad(16),
    );
  }
}
