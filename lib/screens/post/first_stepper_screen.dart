import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/categories_model/color_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_fields_model.dart';
import 'package:lost_and_found/models/categories_model/dynamic_value_model.dart';
import 'package:lost_and_found/models/categories_model/sub_category_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_dropdown_field.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class FirstStepperScreen extends StatefulWidget {
  final CategoryModel category;
  final SubCategoryModel? subCategory; // nullable — null when category = "Others"
  final int postType;

  const FirstStepperScreen({
    super.key,
    required this.category,
    this.subCategory,
    required this.postType,
  });

  @override
  State<FirstStepperScreen> createState() => _FirstStepperScreenState();
}

class _FirstStepperScreenState extends State<FirstStepperScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  List<DynamicFieldsModel> dynamicFields = [];

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  bool _isPickingImage = false;

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController(); // generic mode only

  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String?> selectedDropdownValues = {};
  final Map<int, List<DynamicValueModel>> dropdownItems = {};
  final Map<int, bool> dropdownLoading = {};
  final Map<int, String?> dropdownError = {};
  final Map<int, int?> dropdownParent = {};

  // Dedicated color dropdown — always from getColors, never from
  // getDynamicFields/getDynamicNestedValues, in every mode.
  List<ColorModel> colorOptions = [];
  bool isLoadingColors = false;
  String? selectedColor;

  final List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 4;

  // True for: (1) top-level category = "Others" (no subcategory step at all),
  // or (2) a real category was chosen but subcategory = "Not Sure"/"Others".
  bool get _isGenericMode {
    final catName = widget.category.name?.toLowerCase().trim() ?? '';
    if (catName == 'others') return true;
    final subName = widget.subCategory?.name.toLowerCase().trim() ?? '';
    return subName == 'not sure' || subName == 'others';
  }

  bool _isColorField(DynamicFieldsModel field) {
    final name = field.displayName.toLowerCase().trim();
    return name == 'color' || name == 'colour';
  }

  @override
  void initState() {
    super.initState();
    _fetchColors();
    if (_isGenericMode) {
      // No subcategory-driven fields to load in generic mode.
      setState(() => isLoading = false);
    } else {
      _fetchDynamicFields();
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    for (final controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchColors() async {
    setState(() => isLoadingColors = true);

    final response = await authController.getColors();

    if (!mounted) return;

    setState(() {
      isLoadingColors = false;
      if (response.isSuccess && response.data != null) {
        colorOptions = response.data!;
      }
    });
  }

  Future<void> _fetchDynamicFields() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getDynamicFields(subCatId: widget.subCategory!.id);

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

    // Color is always handled by the dedicated getColors dropdown —
    // strip any "Color"/"Colour" field the subcategory's dynamic fields
    // API returns, so it's never shown twice.
    final fields = response.data!.where((f) => !_isColorField(f)).toList();

    for (final field in fields) {
      if (field.fieldType == DynamicFieldType.text || field.fieldType == DynamicFieldType.textarea) {
        textControllers[field.id] = TextEditingController();
      }
    }

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

    for (final field in fields) {
      if (field.fieldType == DynamicFieldType.dropdown && dropdownParent[field.id] == null) {
        _loadDropdownValues(field);
      }
    }
  }

  Future<void> _loadDropdownValues(DynamicFieldsModel field) async {
    setState(() {
      dropdownLoading[field.id] = true;
      dropdownError[field.id] = null;
    });

    final response = await authController.getDynamicValues(brandMasterName: field.dropdownMaster);

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

  Future<void> _loadNestedDropdownValues(DynamicFieldsModel field, String parentValue) async {
    setState(() {
      dropdownLoading[field.id] = true;
      dropdownError[field.id] = null;
    });

    final response = await authController.getDynamicNestedValues(
      parentValue: parentValue,
      brandMasterName: field.displayName,
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

  void _resetDescendantsOf(int changedFieldId) {
    for (final field in dynamicFields) {
      if (field.fieldType == DynamicFieldType.dropdown && dropdownParent[field.id] == changedFieldId) {
        selectedDropdownValues[field.id] = null;
        dropdownItems[field.id] = [];
        dropdownError[field.id] = null;
        _resetDescendantsOf(field.id);
      }
    }
  }

  void _onDropdownChanged(DynamicFieldsModel field, String? value) {
    setState(() {
      selectedDropdownValues[field.id] = value;
      _resetDescendantsOf(field.id);
    });

    if (value == null) return;

    for (final childField in dynamicFields) {
      if (childField.fieldType == DynamicFieldType.dropdown && dropdownParent[childField.id] == field.id) {
        _loadNestedDropdownValues(childField, value);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    if (selectedImages.length >= maxImages) return;
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => selectedImages.add(File(picked.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<void> _onSubmit() async {
    if (selectedImages.isEmpty) {
      AppDialogue.showPopup(context: context, content: AppText(text: 'Please upload at least one image'));
      return;
    }

    setState(() => isSubmitting = true);

    // Step A: upload images
    final imageResponse = await authController.createImage(images: selectedImages);

    if (!mounted) return;

    if (!imageResponse.isSuccess || imageResponse.data == null) {
      setState(() => isSubmitting = false);
      final msg = imageResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (imageResponse.message.isNotEmpty ? imageResponse.message : 'Failed to upload images');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
      return;
    }

    final imageIds = imageResponse.data!.map((e) => e.id).join(',');

    // Step B: gather dynamic field values — only relevant in normal mode.
    // Color is deliberately excluded here; it's sent as its own top-level field.
    final postValues = <Map<String, String>>[];

    if (!_isGenericMode) {
      for (final field in dynamicFields) {
        String? value;

        if (field.fieldType == DynamicFieldType.text || field.fieldType == DynamicFieldType.textarea) {
          value = textControllers[field.id]?.text.trim();
        } else if (field.fieldType == DynamicFieldType.dropdown) {
          value = selectedDropdownValues[field.id];
        }
        if (value != null && value.isNotEmpty) {
          postValues.add({'field': field.displayName, 'value': value});
        }
      }
    }

    final userId = await AppPreferences.getUserId();

    final postResponse = await authController.createPostStep1(
      userId: userId ?? 0,
      postType: widget.postType,
      categoryId: widget.category.id,
      subcategoryId: widget.subCategory?.id ?? 0,
      itemName: _isGenericMode ? itemNameController.text.trim() : '',
      color: selectedColor ?? '',
      postImages: imageIds,
      postValues: postValues,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (postResponse.isSuccess && postResponse.data != null) {
      AppRoutes.pushNamed(
        AppRoutes.secondStepperScreen,
        arguments: {
          'postId': postResponse.data!.id,
          if (_isGenericMode) 'prefillDescription': descriptionController.text.trim(),
        },
      );
    } else {
      final msg = postResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (postResponse.message.isNotEmpty ? postResponse.message : 'Failed to complete post');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchDynamicFields, child: const Text('Retry')),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category — always shown, auto-filled, read-only
          buildTextFieldWithHeading(
            title: 'Category',
            fieldWidget: AppTextField(
              suffixIcon: AppIconWidget(assetPath: AssetImages.blueTick, size: 20).pad(),
              readOnly: true,
              borderColor: AppColors.fieldGrey,
              borderRadius: BorderRadius.circular(5),
              hintText: '',
              textController: TextEditingController(text: widget.category.name ?? ''),
              onChange: (v) {},
              onSubmit: (v) {},
            ).pad(),
          ).pad(),

          // Sub-Category — only shown when one was actually chosen
          // (skipped when Category = "Others" was picked at the top level).
          if (widget.subCategory != null)
            buildTextFieldWithHeading(
              title: 'Sub-Category',
              fieldWidget: AppTextField(
                suffixIcon: AppIconWidget(assetPath: AssetImages.blueTick, size: 20).pad(),
                readOnly: true,
                borderColor: AppColors.fieldGrey,
                borderRadius: BorderRadius.circular(5),
                hintText: '',
                textController: TextEditingController(text: widget.subCategory!.name),
                onChange: (v) {},
                onSubmit: (v) {},
              ).pad(),
            ).pad(),

          // Item Name — ONLY in generic mode ("Others" / "Not Sure").
          // Hidden entirely for a normal category+subcategory selection.
          if (_isGenericMode)
            buildTextFieldWithHeading(
              title: 'Item Name',
              fieldWidget: AppTextField(
                borderColor: AppColors.fieldGrey,
                borderRadius: BorderRadius.circular(5),
                hintText: 'Enter item name',
                textController: itemNameController,
                onChange: (v) {},
                onSubmit: (v) {},
              ).pad(),
            ).pad(),

          // Color — ALWAYS shown, ALWAYS from the dedicated getColors API,
          // in every mode.
          _buildColorDropdown(),

          // Normal mode: subcategory-driven dynamic fields (Brand, Model, etc,
          // with Color already filtered out).
          // Generic mode: no dynamic fields — description instead.
          if (_isGenericMode)
            buildTextFieldWithHeading(
              title: 'Item Description',
              fieldWidget: AppTextField(
                maxLines: 4,
                borderColor: AppColors.fieldGrey,
                borderRadius: BorderRadius.circular(5),
                hintText: 'Write a item description',
                textController: descriptionController,
                onChange: (v) {},
                onSubmit: (v) {},
              ).pad(),
            ).pad()
          else
            ...dynamicFields.map((field) => _buildField(field)),

          // Image upload — ALWAYS shown, at the end, in every mode.
          _buildImageUploadSection(),
        ],
      ),
      bottomNavigationBar: isLoading || errorMessage != null
          ? null
          : AppButton(
        radius: BorderRadius.circular(5),
        title: isSubmitting ? 'Please wait...' : 'Next',
        onTap: isSubmitting ? () {} : _onSubmit,
      ).pad(16),
    );
  }

  Widget _buildColorDropdown() {
    return buildTextFieldWithHeading(
      title: 'Color',
      fieldWidget: AppDropdownField<String>(
        borderColor: AppColors.fieldGrey,
        value: selectedColor,
        hintText: isLoadingColors ? 'Loading...' : 'Select color',
        items: colorOptions.map((c) => c.colorName).toList(),
        itemLabel: (value) => value,
        selectedItemColor: AppColors.primaryColor.withAlpha(30),
        selectedItemTextColor: AppColors.primaryColor,
        onChanged: isLoadingColors ? null : (value) => setState(() => selectedColor = value),
      ).pad(),
    ).pad();
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Upload Image ${selectedImages.length}/$maxImages',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedImages.length < maxImages ? selectedImages.length + 1 : maxImages,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.50,
          ),
          itemBuilder: (context, index) {
            if (index < selectedImages.length) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: AppIconWidget(
                          assetPath: AssetImages.delete,
                          size: 10,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.fieldGrey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: AppColors.primaryColor, size: 28),
                ),
              ),
            );
          },
        ),
      ],
    ).pad();
  }

  Widget _buildField(DynamicFieldsModel field) {
    switch (field.fieldType) {
      case DynamicFieldType.text:
        return buildTextFieldWithHeading(
          title: field.displayName,
          fieldWidget: AppTextField(
            borderColor: AppColors.fieldGrey,
            borderRadius: BorderRadius.circular(5),
            hintText: 'Enter ${field.displayName.toLowerCase()}',
            textController: textControllers[field.id]!,
            onChange: (value) {},
            onSubmit: (value) {},
          ).pad(),
        ).pad();

      case DynamicFieldType.textarea:
        return buildTextFieldWithHeading(
          title: field.displayName,
          fieldWidget: AppTextField(
            maxLines: 4,
            borderColor: AppColors.fieldGrey,
            borderRadius: BorderRadius.circular(5),
            hintText: '',
            textController: textControllers[field.id]!,
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
          fieldWidget: AppDropdownField<String>(
            borderColor: AppColors.fieldGrey,
            value: selectedDropdownValues[field.id],
            hintText: hint,
            items: options.map((e) => e.value).toList(),
            itemLabel: (value) => value,
            selectedItemColor: AppColors.primaryColor.withAlpha(30),
            selectedItemTextColor: AppColors.primaryColor,
            onChanged: (isLockedByParent || isLoadingOptions) ? null : (value) => _onDropdownChanged(field, value),
          ).pad(),
        ).pad();

      case DynamicFieldType.unknown:
        return const SizedBox();
    }
  }
}

Widget buildTextFieldWithHeading({
  required String title,
  required Widget fieldWidget,
}) {
  return Column(
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText(text: title, fontSize: 16, fontWeight: FontWeight.w600),
      fieldWidget,
    ],
  );
}