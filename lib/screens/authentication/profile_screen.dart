import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/screens/authentication/otp_screen.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:lost_and_found/screens/otp_screen_shared.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileScreenModel profileModel;

  const ProfileScreen({super.key, required this.profileModel});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController alternativeController = TextEditingController();

  bool isAlternativeNumberValid = false;
  bool isVerified = false;
  bool isPinCodeValid = false;
  File? selectedImage;
  String otp = '';
  Timer? timer;
  int seconds = 30;
  int? enableRestart;
  String? errorText;
  bool isFormValid = false;

  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _controller = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  final List<FocusNode> focusNode = List.generate(4, (_) => FocusNode());
  List<bool> otpError = List.generate(4, (_) => false);
  List<bool> isFocused = List.generate(4, (_) => false);
  final ImagePicker picker = ImagePicker();

  void checkFormValidation() {
    setState(() {
      isFormValid =
          selectedImage != null &&
          AppUtils.validateName(nameController.text) == null &&
          AppUtils.validateMobileNumber(mobileController.text) == null &&
          AppUtils.validatePincode(pinController.text) == null &&
          AppUtils.required(countryController.text) == null &&
          AppUtils.required(stateController.text) == null &&
          AppUtils.required(cityController.text) == null &&
          AppUtils.required(addressController.text) == null &&
          AppUtils.required(landmarkController.text) == null;
    });
  }

  void _onPinCodeChanged(String value) {
    setState(() {
      isPinCodeValid = AppUtils.validatePincode(value) == null;
    });
  }

  Future<void> photoFromGallery() async {
    final XFile? pic = await picker.pickImage(source: ImageSource.gallery);

    if (pic != null) {
      setState(() {
        selectedImage = File(pic.path);
      });
    }

    checkFormValidation();
  }

  void deleteProfilePicture() {
    setState(() {
      selectedImage = null;
    });

    checkFormValidation();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      focusNode[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNode[index - 1].requestFocus();
    }

    otp = _controller.map((e) => e.text).join();
    if (otp.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 30;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    alternativeController.dispose();
    pinController.dispose();
    countryController.dispose();
    stateController.dispose();
    cityController.dispose();
    addressController.dispose();
    landmarkController.dispose();

    for (final c in _controller) {
      c.dispose();
    }

    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                AppText(
                  text: 'Profile',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),

                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : null,
                      radius: 50,
                      child: selectedImage == null ? Icon(Icons.person) : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: -4,

                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          AppUiHelper.showBottomSheet(
                            maxHeightFactor: 0.25,
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: InkWell(
                                    onTap: () {
                                      AppRoutes.pop();
                                    },
                                    child: AppIconWidget(
                                      assetPath: AssetImages.crossIcon,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await photoFromGallery();
                                    AppRoutes.pop();
                                  },

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 10,
                                    children: [
                                      AppIconWidget(
                                        assetPath: AssetImages.galleryImage,
                                      ),
                                      AppText(
                                        text: 'Choose from gallery',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(),
                                GestureDetector(
                                  onTap: () {
                                    if (selectedImage == null) return;
                                    selectedImage = null;
                                    setState(() {});
                                    AppRoutes.pop();
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 10,
                                    children: [
                                      AppIconWidget(
                                        assetPath: AssetImages.delete,
                                      ),
                                      AppText(
                                        text: 'Delete profile picture',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        color: AppColors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            //color: AppColors.white,
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.fieldGrey.withAlpha(70),
                            ),
                            child: AppIconWidget(
                              assetPath: AssetImages.camera,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                //userid
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                //   decoration: BoxDecoration(
                //     color: AppColors.idCardColor,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: AppText(
                //     text: 'ID : LF101',
                //     fontWeight: FontWeight.w400,
                //     fontSize: 10,
                //   ),
                // ),

                //name field
                buildTextFieldWithHeading(
                  title: 'Name',

                  fieldWidget: AppTextField(
                    hintText: 'enter name',
                    textController: nameController,
                    onChange: (v) {
                      checkFormValidation();
                    },
                    onSubmit: (v) {},
                    validator: (e) {
                      return AppUtils.validateName(e);
                    },
                  ),
                ),

                // Mobile Number
                buildTextFieldWithHeading(
                  title: 'Mobile Number',
                  fieldWidget: Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          hintText: '+91',
                          textController: TextEditingController(),
                          onChange: (v) {},
                          onSubmit: (v) {},
                        ),
                      ),

                      Expanded(
                        flex: 8,
                        child: AppTextField(
                          maxLength: 10,
                          readOnly: true,
                          hintText: 'Enter a mobile number',
                          textController: mobileController,
                          onChange: (v) {},
                          onSubmit: (v) {},
                          textInputType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ),

                // Alternate Mobile Number
                buildTextFieldWithHeading(
                  title: ' Alternate Mobile Number',
                  fieldWidget: Column(
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              hintText: '+91',
                              textController: TextEditingController(),
                              onChange: (v) {},
                              onSubmit: (v) {},
                            ),
                          ),

                          Expanded(
                            flex: 8,
                            child: AppTextField(
                              maxLength: 10,
                              hintText: 'Enter a mobile number',
                              textController: alternativeController,
                              onChange: (v) {
                                setState(() {
                                  errorText = AppUtils.validateMobileNumber(v);
                                });
                              },
                              onSubmit: (v) {},
                              textInputType: TextInputType.phone,
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  if (isVerified) return;
                                  if (AppUtils.validateMobileNumber(
                                        alternativeController.text,
                                      ) !=
                                      null) {
                                    AppDialogue.showPopup(
                                      context: context,
                                      content: OtpSharedScreen(
                                        isAlternateNumber: true,
                                        mobileNumber:
                                            alternativeController.text,
                                        onVerified: () {
                                          setState(() {
                                            isVerified = true;
                                          });
                                          AppRoutes.pop();
                                        },
                                      ),
                                    );
                                  }
                                },
                                child: SizedBox(
                                  width: 100,
                                  child: Container(
                                    color: isVerified
                                        ? AppColors.lightGreen
                                        : AppColors.idCardColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isVerified)
                                            Icon(
                                              Icons.check,
                                              color: AppColors.green,
                                              size: 16,
                                            ),
                                          if (isVerified)
                                            const SizedBox(width: 4),
                                          AppText(
                                            text: isVerified
                                                ? "Verified"
                                                : "Verify",
                                            fontSize: 12,
                                            color: isVerified
                                                ? AppColors.green
                                                : AppColors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (errorText != null)
                        buildErrorText(errorText: errorText ?? ''),
                    ],
                  ),
                ),

                buildTextFieldWithHeading(
                  title: ' PinCode',
                  fieldWidget: AppTextField(
                    suffixIcon: GestureDetector(
                      onTap: isPinCodeValid
                          ? () {
                              // Call API here
                            }
                          : null,
                      child: SizedBox(
                        width: 100,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.idCardColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          child: Center(
                            child: AppText(
                              text: 'Get Details',
                              color: isPinCodeValid
                                  ? AppColors.primaryColor
                                  : AppColors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    hintText: 'Enter Pincode',
                    textController: pinController,
                    textInputType: TextInputType.phone,
                    maxLength: 6,
                    validator: (e) {
                      if (e == null) return null;

                      return AppUtils.validatePincode(e);
                    },
                    onChange: (v) {
                      _onPinCodeChanged(v);
                      checkFormValidation();
                    },

                    onSubmit: (v) {},
                  ),
                ),

                Opacity(
                  opacity: 1,
                  child: Column(
                    spacing: 10,
                    children: [
                      buildTextFieldWithHeading(
                        title: 'Country',
                        fieldWidget: AppTextField(
                          hintText: 'Enter country',
                          textController: countryController,
                          onChange: (v) {
                            checkFormValidation();
                          },
                          onSubmit: (v) {},
                          validator: (v) {
                            return AppUtils.required(v);
                          },
                        ),
                      ),

                      //state
                      buildTextFieldWithHeading(
                        title: 'State',
                        fieldWidget: AppTextField(
                          hintText: 'Enter state',
                          textController: stateController,
                          onChange: (v) {
                            checkFormValidation();
                          },
                          onSubmit: (v) {},
                          validator: (v) {
                            return AppUtils.required(v);
                          },
                        ),
                      ),

                      //city
                      buildTextFieldWithHeading(
                        title: 'City',
                        fieldWidget: AppTextField(
                          hintText: 'Enter city',
                          textController: cityController,
                          onChange: (v) {
                            checkFormValidation();
                          },
                          onSubmit: (v) {},
                          validator: (v) {
                            return AppUtils.required(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                //country
                SizedBox(height: 10),

                //map
                //map/address card
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    AppText(
                      text: 'Address details',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ).pad(1),

                    GestureDetector(
                      onTap: (){
                        print('---------------------------------------------------------------');
                        AppRoutes.pushNamed(AppRoutes.mapScreen,arguments: MapScreenModel(needSingleLocation: true));
                      },

                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          border: Border.all(color: AppColors.fieldGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // Image background
                            Positioned.fill(
                              child: AppIconWidget(
                                assetPath: AssetImages.map,
                                // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Bottom button
                            Center(
                              child: AppTextField(
                                onTap: (){
                                  print('---------------------------------------------------------------');
                                  AppRoutes.pushNamed(AppRoutes.mapScreen,arguments: MapScreenModel(needSingleLocation: true));
                                },
                                hintText: '',
                                textController: TextEditingController(
                                  text: "Pin Location on Map",
                                ),
                                textBackgroundColor: AppColors.primaryColor,
                                onChange: (e) {
                                  checkFormValidation();
                                },
                                suffixIcon: AppIconWidget(
                                  assetPath: AssetImages.iosForward,
                                ).pad(12),
                                readOnly: true,
                                onSubmit: (e) {},
                                prefixIcon: AppIconWidget(
                                  assetPath: AssetImages.map_marker,
                                  size: 20,
                                ).pad(12),
                              ).padHorizontal(15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                //full address
                buildTextFieldWithHeading(
                  title: 'Full Address',
                  fieldWidget: AppTextField(
                    hintText: 'Enter Full Address',
                    textController: addressController,
                    onChange: (v) {
                      checkFormValidation();
                    },
                    onSubmit: (v) {},
                    validator: (v) {
                      return AppUtils.required(v);
                    },
                  ),
                ),

                //landmark
                buildTextFieldWithHeading(
                  title: 'Landmark',
                  fieldWidget: AppTextField(
                    hintText: 'Enter landmark',
                    textController: landmarkController,
                    onChange: (v) {
                      checkFormValidation();
                    },
                    onSubmit: (v) {},
                    validator: (v) {
                      return AppUtils.required(v);
                    },
                  ),
                ),
              ],
            ).pad(16),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.fieldGrey.withAlpha(50),
                width: 2,
              ),
            ),
          ),
          child: AppButton(
            title: widget.profileModel.isFromEdit ? 'Save' : 'Save & Next',
            radius: BorderRadius.circular(7),
            onTap: () {
              if (_formKey.currentState!.validate()) {
                widget.profileModel.isFromEdit
                    ? AppRoutes.pop()
                    : AppRoutes.pushNamed(AppRoutes.firstHomeScreen);
              }
              if (selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText(
                      text: 'choose an Image',
                      color: AppColors.white,
                    ),
                  ),
                );
              } else {
                print('**************************************************');
              }
            },

            bgColor: isFormValid
                ? AppColors.primaryColor
                : AppColors.idCardColor,
            textColor: isFormValid ? AppColors.white : AppColors.black,
          ).pad(16),
        ),
      ),
    );
  }
}

class ProfileScreenModel {
  final bool isFromEdit;

  ProfileScreenModel({required this.isFromEdit});
}
