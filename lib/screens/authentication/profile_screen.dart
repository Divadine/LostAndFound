import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/controllers/pincode_profile_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/authmodels/pincode_details_model.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/otp_screen.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/screens/permissions/location_permission.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
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
  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  final addressControllers = AddressControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );
  bool isNotFromSetUp = false;
  bool isAlternativeNumberValid = false;
  bool isPinCodeValid = false;
  String otp = '';
  Timer? timer;
  int seconds = 30;
  int? enableRestart;
  String? errorText;
  bool isFormValid = false;
  late String selectedLocation;
  StreamController<String?> nameStream = StreamController.broadcast();
  StreamController<String?> mobileStream = StreamController.broadcast();
  StreamController<bool?> verifyMobileStream = StreamController.broadcast();
  StreamController<String?> pinStream = StreamController.broadcast();
  StreamController<File?> imageStream = StreamController.broadcast();

  bool _isAltVerified = false;
  String? latitude;
  String? longitude;
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
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController countryCodeController2 = TextEditingController();

  final ImagePicker picker = ImagePicker();
  File? choosenImage;
  List<AreaModel> cityOptions = [];
  String? selectedCityName;
  bool _isFormValid = false;

  final AppLocationPermission _appPermissions = AppLocationPermission();

  @override
  void initState() {
    super.initState();

    nameController.text = widget.profileModel.name ?? '';
    mobileController.text = widget.profileModel.mobile ?? '';
    alternativeController.text = widget.profileModel.altMobile ?? '';
    pinController.text = widget.profileModel.pincode ?? '';
    countryController.text = widget.profileModel.country ?? '';
    stateController.text = widget.profileModel.state ?? '';
    cityController.text = widget.profileModel.city ?? '';
    addressController.text = widget.profileModel.address ?? '';
    landmarkController.text = widget.profileModel.landmark ?? '';
    latitude = widget.profileModel.latitude;
    longitude = widget.profileModel.longitude;

    _isAltVerified = widget.profileModel.altMobileVerified;
    if (widget.profileModel.altMobileVerified) {
      verifyMobileStream.add(true);
    }
    if (widget.profileModel.pincode != null) {
      isPinCodeValid =
          AppUtils.validatePincode(widget.profileModel.pincode!) == null;
    }
    countryCodeController.text = '+91';
    countryCodeController2.text = '+91';

    if (widget.profileModel.city != null &&
        widget.profileModel.city!.isNotEmpty) {
      selectedCityName = widget.profileModel.city;
      cityOptions = [AreaModel(id: 0, name: widget.profileModel.city!)];
    }
  }

  Future<void> _openMapForAddress() async {
    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) return;

    if (!mounted) return;
    final singleLocation = await context.pushNamed(
      AppRoutes.mapScreen,
      extra: MapScreenModel(needSingleLocation: true),
    );

    if (singleLocation != null) {
      final locations = singleLocation as SelectedLocationModel;
      addressController.text = locations.address;
    }
  }

  void _checkFormValidity() {
    final valid =
        (_formKey.currentState?.validate() ?? false) && choosenImage != null;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  String? _validatePinCode(String value) {
    final errorPinCode = AppUtils.validatePincode(value);
    isPinCodeValid = errorPinCode == null;
    return errorPinCode;
  }

  Future<void> photoFromGallery() async {
    final XFile? pic = await picker.pickImage(source: ImageSource.gallery);

    if (pic != null) {
      choosenImage = File(pic.path);
      imageStream.add(File(pic.path));
      _checkFormValidity();
    }
  }

  void deleteProfilePicture() {
    if (choosenImage == null) return;
    choosenImage = null;

    imageStream.add(null);
    AppRoutes.pop();
    _checkFormValidity();
  }

  @override
  void dispose() {
    nameStream.close();
    mobileStream.close();
    pinStream.close();

    nameController.dispose();
    mobileController.dispose();
    alternativeController.dispose();
    pinController.dispose();

    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: isNotFromSetUp
          ? CustomAppBar(
              title: '',
              leadingSvg: AssetImages.backArrow,
              onLeadingTap: () {
                AppRoutes.pop();
              },
            )
          : null,
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

                StreamBuilder(
                  stream: imageStream.stream,
                  builder: (context, asyncSnapshot) {
                    final selectedImage = asyncSnapshot.data;
                    return Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage)
                              : null,
                          radius: 50,
                          child: selectedImage == null
                              ? (widget.profileModel.profileImageUrl != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: widget
                                              .profileModel
                                              .profileImageUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(Icons.person))
                              : null,
                        ),

                        Positioned(
                          bottom: 0,
                          right: -4,

                          child: GestureDetector(
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        deleteProfilePicture();
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                    );
                  },
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
                    readOnly: !widget.profileModel.isFromEdit,
                    onSubmit: (v) {},
                    onChange: (v) => _checkFormValidity(),
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
                          readOnly: true,
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
                          readOnly: !widget.profileModel.isFromEdit,
                          hintText: 'Enter a mobile number',
                          textController: mobileController,
                          onChange: (v) => _checkFormValidity(),

                          onSubmit: (v) {},
                          textInputType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ),

                // Alternate Mobile Number
                StreamBuilder(
                  stream: mobileStream.stream,
                  builder: (context, asyncSnapshot) {
                    final numberData = asyncSnapshot.data;
                    return buildTextFieldWithHeading(
                      title: ' Alternate Mobile Number(optional)',
                      fieldWidget: Column(
                        children: [
                          Row(
                            spacing: 10,
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  readOnly: true,
                                  hintText: '+91',
                                  textController: countryCodeController2,
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
                                    mobileStream.add(
                                      AppUtils.validateMobileNumber(v),
                                    );
                                    if (_isAltVerified) {
                                      setState(() => _isAltVerified = false);
                                      verifyMobileStream.add(false);
                                    }
                                  },
                                  onSubmit: (v) {},
                                  textInputType: TextInputType.phone,
                                  suffixIcon: StreamBuilder(
                                    stream: verifyMobileStream.stream,
                                    builder: (context, asyncSnapshot) {
                                      final isVerified =
                                          asyncSnapshot.data ?? false;
                                      return GestureDetector(
                                        onTap: () {
                                          if (isVerified) return;

                                          if (AppUtils.validateMobileNumber(
                                                alternativeController.text,
                                              ) ==
                                              null) {
                                            AppDialogue.showPopup(
                                              context: context,
                                              content: OtpSharedScreen(
                                                isAlternateNumber: true,
                                                mobileNumber:
                                                    alternativeController.text,
                                                onVerifyOtp: (String otp) async {
                                                  final response =
                                                      await authController
                                                          .verifyMobileOtp(
                                                            phone:
                                                                alternativeController
                                                                    .text,
                                                            otp: otp,
                                                            userId: widget
                                                                .profileModel
                                                                .userId!,
                                                          );
                                                  if (response.status == 1) {
                                                    _isAltVerified = true;
                                                    verifyMobileStream.add(
                                                      true,
                                                    );
                                                    AppRoutes.pop();
                                                    return null;
                                                  }
                                                  return response.message;
                                                },
                                                onSendOtp: () async {
                                                  final response = await authController.generateMobileOtp(alternativeController.text);
                                                  if (response.isSuccess) return null;
                                                  if (response.currentState == CurrentState.noInternet) {
                                                    return 'No internet connection. Please check your network.';
                                                  }
                                                  return response.message.isNotEmpty ? response.message : 'Failed to send OTP';
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
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (numberData != null)
                            buildErrorText(errorText: numberData ?? ''),
                        ],
                      ),
                    );
                  },
                ),

                StreamBuilder(
                  stream: pinStream.stream,
                  builder: (context, asyncSnapshot) {
                    final pinData = asyncSnapshot.data;
                    return buildTextFieldWithHeading(
                      title: ' PinCode',
                      fieldWidget: AppTextField(
                        hintText: 'Enter Pincode',
                        textController: pinController,
                        textInputType: TextInputType.phone,
                        maxLength: 6,
                        validator: (e) {
                          if (e == null) return null;

                          return AppUtils.validatePincode(e);
                        },
                        onChange: (v) {
                          // _validatePinCode(v);
                          pinStream.add(_validatePinCode(v));
                          _checkFormValidity();
                          // checkFormValidation();
                        },

                        onSubmit: (v) {},
                        suffixIcon: GestureDetector(
                          onTap: isPinCodeValid
                              ? () async {
                            final result = await addressControllers
                                .getAddressByPincode(pinController.text);
                            if (result != null) {
                              setState(() {
                                countryController.text = result.country;
                                stateController.text = result.state;
                                cityOptions = result.areas;
                                selectedCityName = cityOptions.isNotEmpty
                                    ? cityOptions.first.name
                                    : null;
                                cityController.text =
                                    selectedCityName ?? '';
                                latitude = result.latitude;
                                longitude = result.longitude;
                              });
                              _checkFormValidity();
                            } else {
                              AppDialogue.showPopup(
                                context: context,
                                content: AppText(
                                  text:
                                  'Could not fetch location details',
                                ),
                              );
                            }
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
                      )

                    );
                  },
                ),

                Opacity(
                  opacity: 1,
                  child: Column(
                    spacing: 10,
                    children: [
                      buildTextFieldWithHeading(
                        title: 'Country',
                        fieldWidget: AppTextField(
                          readOnly: true,
                          hintText: 'Enter country',
                          textController: countryController,
                          onChange: (v) {
                            //
                            //
                            //
                            //
                            // ();
                          },
                          onSubmit: (v) {},
                          // validator: (v) {
                          //   return AppUtils.required(v);
                          // },
                        ),
                      ),

                      //state
                      buildTextFieldWithHeading(
                        title: 'State',
                        fieldWidget: AppTextField(
                          hintText: 'Enter state',
                          readOnly: true,

                          textController: stateController,
                          onChange: (v) {
                            // checkFormValidation();
                          },
                          onSubmit: (v) {},
                          // validator: (v) {
                          //   return AppUtils.required(v);
                          // },
                        ),
                      ),

                      //city
                      //city
                      buildTextFieldWithHeading(
                        title: 'City',
                        fieldWidget: DropdownButtonFormField<String>(
                          value: selectedCityName,
                          items: cityOptions
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.name,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                          onChanged: cityOptions.isEmpty
                              ? null
                              : (v) {
                                  setState(() {
                                    selectedCityName = v;
                                    cityController.text = v ?? '';
                                  });
                                  _checkFormValidity();
                                },
                          decoration: InputDecoration(
                            hintText: cityOptions.isEmpty
                                ? 'Fetch pincode first'
                                : 'Select city',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'City is required'
                              : null,
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
                      onTap: _openMapForAddress,
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
                                onTap: _openMapForAddress,
                                hintText: '',
                                textController: TextEditingController(
                                  text: "Pin Location on Map",
                                ),
                                textBackgroundColor: AppColors.primaryColor,
                                onChange: (e) {
                                  // checkFormValidation();
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
                    readOnly: true,
                    maxLines: 2,
                    hintText: 'Enter Full Address',
                    textController: addressController,
                    onChange: (v) {
                      _checkFormValidity();
                    },
                    onSubmit: (v) {},
                    // validator: (v) {
                    //   return AppUtils.required(v);
                    // },
                  ),
                ),

                //landmark
                buildTextFieldWithHeading(
                  title: 'Landmark',
                  fieldWidget: AppTextField(
                    hintText: 'Enter landmark',
                    textController: landmarkController,
                    onChange: (v) {
                      _checkFormValidity();
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
            onTap: () async {
              if (!_formKey.currentState!.validate()) return;

              final profile = UpdateProfileForm(
                id: widget.profileModel.userId,
                profileImg: choosenImage,
                name: nameController.text,
                phoneNo: mobileController.text,
                altNo: alternativeController.text.isNotEmpty
                    ? alternativeController.text
                    : null,
                pinCode: pinController.text,
                country: countryController.text,
                state: stateController.text,
                city: cityController.text,
                address: addressController.text,
                landMark: landmarkController.text,
                lat: latitude,
                log: longitude,
                altVerified: _isAltVerified,
              );

              final response = await authController.updateProfileForm(profile);
              if (!mounted) return;
              if (response.status == 1) {
                widget.profileModel.isFromEdit
                    ? AppRoutes.pop()
                    : AppRoutes.pushNamed(AppRoutes.firstHomeScreen);
              } else {
                print('**************************************************');
                AppDialogue.showPopup(
                  context: context,
                  content: AppText(
                    text: response.message ,
                  ),
                );
              }
            },

            bgColor: _isFormValid
                ? AppColors.primaryColor
                : AppColors.idCardColor,

            textColor: _isFormValid ? AppColors.white : AppColors.black,
          ).pad(16),
        ),
      ),
    );
  }
}
