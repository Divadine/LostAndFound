import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/screens/otp_screen.dart';
import 'package:lost_and_found/screens/register_screen.dart';
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
  }

  void deleteProfilePicture() {
    setState(() {
      selectedImage = null;
    });
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
                    onChange: (v) {},
                    onSubmit: (v) {},
                    validator: (e) {
                      return AppUtils.validateName(e);
                    },
                  ),
                ),
                //number
                buildTextFieldWithHeading(
                  title: 'Mobile Number',
                  fieldWidget: AppTextField(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        //color: AppColors.fieldGrey.withAlpha(90),
                        border: Border(
                          right: BorderSide(color: AppColors.fieldGrey),
                        ),
                      ),
                      child: AppText(
                        text: '+91',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppColors.numberGrey,
                      ),
                    ),
                    hintText: 'Enter a mobile number',
                    textController: mobileController,
                    textInputType: TextInputType.phone,
                    maxLength: 10,
                    validator: (e) {
                      if (e == null) return null;

                      return AppUtils.validateMobileNumber(e);
                    },
                    onChange: (v) {},
                    onSubmit: (v) {},
                  ),
                ),

                // alternative number
                buildTextFieldWithHeading(
                  title: ' Alternate Mobile Number (Optional)',
                  fieldWidget:
                  AppTextField(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        //color: AppColors.fieldGrey.withAlpha(90),
                        border: Border(
                          right: BorderSide(color: AppColors.fieldGrey),
                        ),
                      ),
                      child: AppText(
                        text: '+91',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppColors.numberGrey,
                      ),
                    ),

                    suffixIcon: GestureDetector(
                      onTap: () {
                        if (isVerified) return;
                        AppDialogue.showPopup(
                          context: context,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 10,
                            children: [
                              AppIconWidget(
                                assetPath: AssetImages.enterOtpIcon,
                              ),
                              AppText(
                                text: 'Enter OTP',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                              AppText(
                                text:
                                    'We have sent a 4-digit OTP to  +91 9585445777',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: AppColors.black,
                                textAlign: TextAlign.center,
                              ).padHorizontal(16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 10,
                                children: List.generate(_controller.length, (
                                  index,
                                ) {
                                  return Container(
                                    height: 50,
                                    width: 50,

                                    child: TextField(
                                      controller: _controller[index],
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        counterText: '',
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: isFocused[index]
                                                ? AppColors.grey
                                                : otpError[index]
                                                ? AppColors.red
                                                : _controller[index]
                                                      .text
                                                      .isEmpty
                                                ? AppColors.grey
                                                : AppColors.primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            width: 1.5,
                                            color: isFocused[index]
                                                ? AppColors.grey
                                                : otpError[index]
                                                ? AppColors.red
                                                : _controller[index]
                                                      .text
                                                      .isEmpty
                                                ? AppColors.grey
                                                : AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                      focusNode: focusNode[index],
                                      maxLength: 1,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.phone,
                                      onChanged: (v) {
                                        if (v.contains(' ') ||
                                            v.contains('.') ||
                                            v.contains(',') ||
                                            v.contains('-')) {
                                          setState(() {
                                            errorText =
                                                "OTP cannot contain special character";
                                            otpError[index] = true;
                                          });
                                          return;
                                        }

                                        setState(() {
                                          errorText = null;
                                          otpError[index] = false;
                                        });

                                        _onChanged(index, v);

                                        _controller[index]
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _controller[index].text.length,
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ),

                              if (errorText != null)
                                AppText(
                                  text: errorText!,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: AppColors.errorRed,
                                ),

                              Container(
                                height: 20,
                                width: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.fieldGrey,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  spacing: 7,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppIconWidget(assetPath: AssetImages.time),
                                    AppText(
                                      text: _formatTime(seconds),
                                      color: AppColors.navyBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ],
                                ),
                              ),

                              AuthChangeText(
                                text1: 'Didn’t receive ?',
                                fadeColor: seconds != 0
                                    ? AppColors.fadeColor
                                    : null,

                                tappableText: 'Resend',
                                onTap: () {
                                  if (seconds == 0) {
                                    setState(() {
                                      _startTimer();
                                    });
                                  }
                                },
                              ),

                              AppButton(
                                title: 'Verify',
                                onTap: () {
                                  otp = _controller.map((e) => e.text).join();

                                  if (otp.length != 4) {
                                    setState(() {
                                      errorText = "Please enter OTP";

                                      for (
                                        int i = 0;
                                        i < otpError.length;
                                        i++
                                      ) {
                                        otpError[i] = true;
                                      }
                                    });

                                    return;
                                  }

                                  if (otp != "1234") {
                                    setState(() {
                                      errorText = "Please enter valid OTP";

                                      for (
                                        int i = 0;
                                        i < otpError.length;
                                        i++
                                      ) {
                                        otpError[i] = true;
                                      }
                                    });

                                    return;
                                  }

                                  // OTP success
                                  setState(() {
                                    errorText = null;
                                    isVerified = true;

                                    AppRoutes.pop();
                                    for (int i = 0; i < otpError.length; i++) {
                                      otpError[i] = false;
                                    }
                                  });

                                  // Navigate next screen
                                  // AppRoutes.pushNamed(
                                  //   AppRoutes.profileScreen,
                                  // );
                                },
                                radius: BorderRadius.circular(8),
                              ).padHorizontal(30),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.lightGreen
                                : AppColors.idCardColor,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            spacing: 5,
                            crossAxisAlignment: .center,
                            mainAxisAlignment: .center,
                            children: [
                              if (isVerified)
                                Icon(Icons.check, color: AppColors.green),
                              AppText(
                                text: isVerified ? "Verified" : "Verify",
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isVerified
                                    ? AppColors.green
                                    : AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    hintText: 'Enter a mobile number',
                    textController: alternativeController,
                    textInputType: TextInputType.phone,
                    readOnly: isVerified,
                    maxLength: 10,
                    validator: (e) {
                      if (e == null) return null;

                      return AppUtils.validateMobileNumber(e);
                    },
                    onChange: (v) {},
                    onSubmit: (v) {},
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
                          padding: const EdgeInsets.symmetric(
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
                    onChange: _onPinCodeChanged,

                    onSubmit: (v) {},
                  ),
                ),
                //pincode
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
                          onChange: (v) {},
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
                          onChange: (v) {},
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
                          onChange: (v) {},
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

                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
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
                              hintText: '',
                              textController: TextEditingController(
                                text: "Pin Location on Map",
                              ),
                              textBackgroundColor: AppColors.primaryColor,
                              onChange: (e) {},
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
                  ],
                ),

                SizedBox(height: 10),
                //full address
                buildTextFieldWithHeading(
                  title: 'Full Address',
                  fieldWidget: AppTextField(
                    hintText: 'Enter Full Address',
                    textController: addressController,
                    onChange: (v) {},
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
                    onChange: (v) {},
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
