import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class FirstStepperScreen extends StatefulWidget {
  const FirstStepperScreen({super.key});

  @override
  State<FirstStepperScreen> createState() => _FirstStepperScreenState();
}

class _FirstStepperScreenState extends State<FirstStepperScreen> {
  List<Map<String, dynamic>> property = [
    {
      "id": 1,
      "category": "Electronics",
      "image": "electronics.png",
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
                "Redmi",
                "Realme",
                "Poco",
                "Vivo",
                "Oppo",
                "Apple",
                "OnePlus"
              ]
            },
            {
              "key": "model",
              "title": "Model",
              "type": "dropdown",
              "dependsOn": "brand",
              "options": {
                "Samsung": [
                  "Galaxy A20",
                  "Galaxy A35",
                  "Galaxy S24"
                ],
                "Redmi": [
                  "Note 12",
                  "Note 13",
                  "Note 14"
                ],
                "Realme": [
                  "Narzo 60",
                  "11 Pro"
                ],
                "Poco": [
                  "X6",
                  "F6"
                ]
              }
            },
            {
              "key": "color",
              "title": "Color",
              "type": "dropdown",
              "options": [
                "Black",
                "White",
                "Blue",
                "Silver",
                "Green"
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
                "Lenovo",
                "Asus",
                "Acer",
                "Apple"
              ]
            },
            {
              "key": "ram",
              "title": "RAM",
              "type": "dropdown",
              "options": [
                "4 GB",
                "8 GB",
                "16 GB",
                "32 GB"
              ]
            },
            {
              "key": "color",
              "title": "Color",
              "type": "dropdown",
              "options": [
                "Black",
                "Silver",
                "Grey"
              ]
            },
            {
              "key": "image",
              "title": "Upload Image",
              "type": "image"
            }
          ]
        }
      ]
    },
    {
      "id": 2,
      "category": "Documents",
      "image": "documents.png",
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
            },
            {
              "key": "image",
              "title": "Upload Image",
              "type": "image"
            }
          ]
        },
        {
          "name": "Driving License",
          "fields": [
            {
              "key": "holderName",
              "title": "Holder Name",
              "type": "text"
            },
            {
              "key": "state",
              "title": "State",
              "type": "dropdown",
              "options": [
                "Tamil Nadu",
                "Kerala",
                "Karnataka"
              ]
            },
            {
              "key": "image",
              "title": "Upload Image",
              "type": "image"
            }
          ]
        }
      ]
    },
    {
      "id": 3,
      "category": "Gold",
      "image": "gold.png",
      "subCategories": [
        {
          "name": "Ring",
          "fields": [
            {
              "key": "metal",
              "title": "Metal",
              "type": "dropdown",
              "options": [
                "Gold",
                "Silver",
                "Platinum"
              ]
            },
            {
              "key": "weight",
              "title": "Weight",
              "type": "text"
            },
            {
              "key": "color",
              "title": "Color",
              "type": "dropdown",
              "options": [
                "Yellow",
                "Rose Gold",
                "White Gold"
              ]
            },
            {
              "key": "image",
              "title": "Upload Image",
              "type": "image"
            }
          ]
        }
      ]
    }
  ];

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

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: property.length,
              itemBuilder: (context, index) {
                final field= property[index];

                switch(field['type']) {
                  case "text" :
                    return buildTextFieldWithHeading(
                      title:field['title'],
                      fieldWidget: AppTextField(
                        hintText: '',
                        textController: TextEditingController(),
                        onChange: (v) {},
                        onSubmit: (v) {},
                      ),
                    );

                  case 'number' :
                    return buildTextFieldWithHeading(
                      title: '',
                      fieldWidget: AppTextField(
                        hintText: '',
                        textController: TextEditingController(),
                        onChange: (v) {},
                        onSubmit: (v) {},
                      ),
                    );

                  case "dropdown" :
                    return DropdownButtonFormField(
                        items: (field['options'] as List).map((e) => DropdownMenuItem(value:e,child: AppText(text: e))).toList(),
                        onChanged: (v){});

                  case "image" :
                    return AppCachedNetworkImage(imageUrl: '');

                  default :
                    return SizedBox();
                }
              },
            ),
          ),

          AppButton(
            title: 'Next',
            onTap: () {
              AppRoutes.pushNamed(AppRoutes.secondStepperScreen);
            },
          ),
        ],
      ),
    );
  }
}
