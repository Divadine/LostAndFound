import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
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



  final Map<int, TextEditingController>textControllers = {};

  final Map<int, String?> selectedDropdownValues = {};
  final Map<int, List<DynamicValueModel>> dropdownItems = {};
  final Map<int, bool> dropdownLoading = {}; // fieldId -> is fetching options
  final Map<int, String?> dropdownError = {}; // fieldId -> load error message

  final Map<int, int?> dropdownParent = {};

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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getDynamicFields(subCatId: widget.subCategory.id);

    if (!mounted) return;

    if (!response.isSuccess || response.data == null) {
      setState(() {
        errorMessage = response.currentState == CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : (response.message.isNotEmpty ? response.message : 'Failed to load fields');
        isLoading = false;
      });
      return;
    }

    final fields = response.data!;

    for (final field in fields) {
      if (field.fieldType == DynamicFieldType.text || field.fieldType == DynamicFieldType.textarea) {
        textControllers[field.id] = TextEditingController();
      }
    }

    // Work out dropdown chain: each dropdown's parent is the nearest
    // preceding dropdown field in the list (or null if it's first).
    int? lastDropdownFieldId;
    for (final field in fields) {
      if (field.fieldType == DynamicFieldType.dropdown) {
        dropdownParent[field.id] = lastDropdownFieldId;
        dropdownItems[field.id] = [];
        dropdownLoading[field.id] = false;
        dropdownError[field.id] = null;
        lastDropdownFieldId = field.id;
      }
    }

    setState(() {
      dynamicFields = fields;
      isLoading = false;
    });

    // Fetch options for every root dropdown (no parent) right away.
    for (final field in fields) {
      if (field.fieldType == DynamicFieldType.dropdown && dropdownParent[field.id] == null) {
        _loadDropdownValues(field);
      }
    }
  }


  /// Root dropdown loader — uses /getDynamicValues.
  Future<void> _loadDropdownValues(DynamicFieldsModel field) async {
    setState(() {
      dropdownLoading[field.id] = true;
      dropdownError[field.id] = null;
    });

    final response = await authController.getDynamicValues( brandMasterName: field.displayName);

    if (!mounted) return;

    setState(() {
      dropdownLoading[field.id] = false;
      if (response.isSuccess && response.data != null) {
        dropdownItems[field.id] = response.data!;
      } else {
        dropdownItems[field.id] = [];
        dropdownError[field.id] = response.currentState == CurrentState.noInternet
            ? 'No internet connection.'
            : (response.message.isNotEmpty ? response.message : 'Failed to load options');
      }
    });
  }



  /// Chained dropdown loader — uses /getDynamicNestedValues.
  Future<void> _loadNestedDropdownValues(DynamicFieldsModel field, String parentValue) async {
    setState(() {
      dropdownLoading[field.id] = true;
      dropdownError[field.id] = null;
    });

    final response = await authController.getDynamicNestedValues(
      parentValue: parentValue, brandMasterName: field.displayName,
    );

    if (!mounted) return;

    setState(() {
      dropdownLoading[field.id] = false;
      if (response.isSuccess && response.data != null) {
        dropdownItems[field.id] = response.data!;
      } else {
        dropdownItems[field.id] = [];
        dropdownError[field.id] = response.currentState == CurrentState.noInternet
            ? 'No internet connection.'
            : (response.message.isNotEmpty ? response.message : 'Failed to load options');
      }
    });
  }


  /// Recursively clears + reloads every dropdown that (transitively)
  /// depends on [changedFieldId], since its parent value just changed.
  void _resetDescendantsOf(int changedFieldId) {
    for (final field in dynamicFields) {
      if (field.fieldType == DynamicFieldType.dropdown && dropdownParent[field.id] == changedFieldId) {
        selectedDropdownValues[field.id] = null;
        dropdownItems[field.id] = [];
        dropdownError[field.id] = null;
        _resetDescendantsOf(field.id); // clear grandchildren too
      }
    }
  }


  void _onDropdownChanged(DynamicFieldsModel field, String? value) {
    setState(() {
      selectedDropdownValues[field.id] = value;
      _resetDescendantsOf(field.id);
    });

    if (value == null) return;

    // Find the immediate child dropdown (if any) and load its nested values.
    for (final childField in dynamicFields) {
      if (childField.fieldType == DynamicFieldType.dropdown && dropdownParent[childField.id] == field.id) {
        _loadNestedDropdownValues(childField, value);
      }
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
          ? const Center(child:CircularProgressIndicator(), )  : errorMessage != null ?
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDynamicFields,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
        final parentFieldId = dropdownParent[field.id];
        final isLockedByParent = parentFieldId != null && selectedDropdownValues[parentFieldId] == null;
        final options = dropdownItems[field.id] ?? [];
        final isLoadingOptions = dropdownLoading[field.id] ?? false;
        final loadError = dropdownError[field.id];

        String hint;
        if (isLockedByParent) {
          final parentField = dynamicFields.firstWhere((f) => f.id == parentFieldId);
          hint = 'Select ${parentField.displayName} first';
        } else if (isLoadingOptions) {
          hint = 'Loading...';
        } else if (loadError != null) {
          hint = loadError;
        } else {
          hint = 'Select ${field.displayName}';
        }

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
            items: options.map((e) => e.value).toList(),

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