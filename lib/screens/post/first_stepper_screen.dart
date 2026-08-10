import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_dropdown_field.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class FirstStepperScreen extends StatefulWidget {

  final SubCategoryModel subCategory;

  const FirstStepperScreen({
    super.key,
    required this.subCategory,

  });

  @override
  State<FirstStepperScreen> createState() =>
      _FirstStepperScreenState();
}

class _FirstStepperScreenState
    extends State<FirstStepperScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  List<DynamicFieldsModel> dynamicFields = [];

  bool isLoading = true;
  String? errorMessage;

  final Map<int, TextEditingController>
  textControllers = {};

  final Map<int, String?>
  selectedDropdownValues = {};

  @override
  void initState() {
    super.initState();

    print(
      'FIRST STEPPER SUBCATEGORY ID: '
          '${widget.subCategory.id}',
    );

    _fetchDynamicFields();
  }

  Future<void> _fetchDynamicFields() async {
    try {
      print('========== DYNAMIC FIELD REQUEST ==========');
      print(
        'subcategory_id: ${widget.subCategory.id}',
      );

      final response =
      await authController.getDynamicFields(
        subCatId: widget.subCategory.id,
      );

      print('========== DYNAMIC FIELD RESPONSE ==========');
      print('status: ${response.status}');
      print('message: ${response.message}');
      print('data: ${response.data}');
      print(
        'data length: ${response.data?.length}',
      );

      if (!mounted) return;

      if (response.status == 1 &&
          response.data != null) {
        final fields =
        response.data as List<DynamicFieldsModel>;

        for (final field in fields) {
          print(
            'FIELD => '
                'id=${field.id}, '
                'name=${field.displayName}, '
                'type=${field.fieldType}, '
                'master=${field.dropdownMaster}, '
                'required=${field.isRequired}',
          );

          if (field.fieldType ==
              DynamicFieldType.text ||
              field.fieldType ==
                  DynamicFieldType.textarea) {
            textControllers[field.id] =
                TextEditingController();
          }
        }

        setState(() {
          dynamicFields = fields;
          isLoading = false;
        });

        print(
          'FINAL FIELD COUNT: '
              '${dynamicFields.length}',
        );
      } else {
        setState(() {
          errorMessage = response.message;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print(
        'DYNAMIC FIELD ERROR: $e',
      );
      print(stackTrace);

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final controller
    in textControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: CustomAppBar(
        title: 'Post Lost Item',
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
        leadingIconColor:
        AppColors.primaryColor,
        onLeadingTap: () {
          AppRoutes.pop();
        },
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child:
        Text(errorMessage!),
      )
          : dynamicFields.isEmpty
          ? const Center(
        child: Text(
          'No dynamic fields available',
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.all(16),
        itemCount:
        dynamicFields.length,
        itemBuilder:
            (context, index) {
          final field =
          dynamicFields[index];

          return _buildField(
            field,
          );
        },
      ),

      bottomNavigationBar:
      AppButton(
        radius:
        BorderRadius.circular(5),
        title: 'Next',
        onTap: () {
          AppRoutes.pushNamed(
            AppRoutes.secondStepperScreen,
          );
        },
      ).pad(16),
    );
  }

  Widget _buildField(
      DynamicFieldsModel field,
      ) {
    switch (field.fieldType) {
      case DynamicFieldType.text:
        return buildTextFieldWithHeading(
          title: field.displayName,
          fieldWidget: AppTextField(
            borderColor:
            AppColors.fieldGrey,
            borderRadius:
            BorderRadius.circular(5),
            hintText: '',
            textController:
            textControllers[field.id]!,
            onChange: (value) {
              print(
                '${field.displayName}: $value',
              );
            },
            onSubmit: (value) {},
          ).pad(),
        ).pad();

      case DynamicFieldType.textarea:
        return buildTextFieldWithHeading(
          title: field.displayName,
          fieldWidget: AppTextField(
            maxLines: 4,
            borderColor:
            AppColors.fieldGrey,
            borderRadius:
            BorderRadius.circular(5),
            hintText: '',
            textController:
            textControllers[field.id]!,
            onChange: (value) {},
            onSubmit: (value) {},
          ).pad(),
        ).pad();

      case DynamicFieldType.dropdown:
        return buildTextFieldWithHeading(
          title: field.displayName,
          fieldWidget:
          AppDropdownField<String>(
            borderColor:
            AppColors.fieldGrey,

            value:
            selectedDropdownValues[
            field.id],

            hintText:
            'Select ${field.displayName}',

            // We will populate this
            // using dropdown_master API.
            items: const [],

            itemLabel: (value) => value,

            selectedItemColor:
            AppColors.primaryColor
                .withAlpha(30),

            selectedItemTextColor:
            AppColors.primaryColor,

            onChanged: (value) {
              setState(() {
                selectedDropdownValues[
                field.id] = value;
              });
            },
          ).pad(),
        ).pad();

      case DynamicFieldType.unknown:
        return const SizedBox();
    }
  }
}