import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/post/first_stepper_screen.dart';
import 'package:lost_and_found/screens/profile/webView.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class ReportJustification extends StatefulWidget {
  final int userId;
  final String phone;

  const ReportJustification({
    super.key,
    required this.userId,
    this.phone = '',
  });

  @override
  State<ReportJustification> createState() => _ReportJustificationState();
}

class _ReportJustificationState extends State<ReportJustification> {
  File? selectedFile;
  String? selectedFileName;
  bool isSubmitting = false;

  final ImagePicker picker = ImagePicker();
  bool isChecked = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController mailController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  final AuthControllers _authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  @override
  void initState() {
    super.initState();
    mobileController.text = widget.phone;
    mailController.addListener(_refresh);
    reasonController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    mailController.removeListener(_refresh);
    reasonController.removeListener(_refresh);
    nameController.dispose();
    mobileController.dispose();
    mailController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      AppUtils.validateEmail(mailController.text) == null &&
          reasonController.text.trim().isNotEmpty &&
          isChecked;

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final sizeInMb = await file.length() / (1024 * 1024);

    if (sizeInMb > 10) {
      if (!mounted) return;
      AppSnackBar.show(
          context: context, message: 'File size must be less than 10 MB');
      return;
    }

    setState(() {
      selectedFile = file;
      selectedFileName = image.path.split('/').last;
    });
  }

  Future<void> _submitReport() async {
    if (mailController.text.trim().isEmpty ||
        reasonController.text.trim().isEmpty) {
      AppSnackBar.show(
          context: context, message: 'Please fill all mandatory fields');
      return;
    }

    if (AppUtils.validateEmail(mailController.text) != null) {
      AppSnackBar.show(context: context, message: 'Enter a valid email');
      return;
    }

    if (!isChecked) {
      AppSnackBar.show(
          context: context, message: 'Please accept the terms and conditions');
      return;
    }

    final hasNet = await AppUtils.checkConnectivity();
    if (!hasNet) {
      if (!mounted) return;
      AppSnackBar.show(
          context: context,
          message: 'No internet connection',
          icon: Icons.wifi_off);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1) image irundha mudhalla upload
      String? imageId;
      if (selectedFile != null) {
        final upload =
        await _authController.createImage(images: [selectedFile!]);

        if (!upload.isSuccess || upload.data == null || upload.data!.isEmpty) {
          if (!mounted) return;
          setState(() => isSubmitting = false);
          AppSnackBar.show(
            context: context,
            message: upload.message.isNotEmpty
                ? upload.message
                : 'Failed to upload image',
          );
          return;
        }

        // PostImageModel la id field peru check pannunga
        imageId = upload.data!.first.id.toString();
      }

      // 2) createReport
      final response = await _authController.createReport(
        userId: widget.userId,
        name: nameController.text.trim(),
        mobileno: mobileController.text.trim(),
        email: mailController.text.trim(),
        description: reasonController.text.trim(),
        imageId: imageId,
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      if (response.isSuccess) {
        // SubmissionReceivedPopUp -> Done -> login screen ku back
        await AppDialogue.showPopup(
          context: context,
          content: const SubmissionReceivedPopUp(),
        );
        if (mounted) AppRoutes.pop();
      } else {
        AppSnackBar.show(
          context: context,
          message: response.message.isNotEmpty
              ? response.message
              : 'Failed to submit report',
        );
      }
    } catch (e) {
      debugPrint('[REPORT JUSTIFY] ERROR: $e');
      if (!mounted) return;
      setState(() => isSubmitting = false);
      AppSnackBar.show(context: context, message: 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: '', leadingSvg: AssetImages.backArrow),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: AppIconWidget(
                      assetPath: AssetImages.reportJustification)),
              AppText(
                text: 'Your Findora Account Has Been Suspended ',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.start,
              ),
              AppText(
                text:
                " Your Findora account has been temporarily suspended because we identified activity that may violate our Community Guidelines or Terms & Conditions. \n If you believe this suspension was made in error, you can submit an appeal for our team to review your account. ",
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ).padHorizontal(16),
              AppText(
                text:
                'Please complete the form below with accurate information and explain why you believe your account should be reinstated',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ).padHorizontal(16),

              buildTextFieldWithHeading(
                title: 'Full name',
                fieldWidget: AppTextField(
                  hintText: 'enter name',
                  textController: nameController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  validator: (e) => AppUtils.validateName(e),
                ),
              ),

              buildTextFieldWithHeading(
                title: 'Mobile Number',
                fieldWidget: AppTextField(
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

              buildTextFieldWithHeading(
                title: 'Email Address',
                isRequired: true,
                fieldWidget: AppTextField(
                  hintText: 'Enter your Email Address',
                  textController: mailController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  validator: (e) => AppUtils.validateEmail(e),
                ),
              ),

              buildTextFieldWithHeading(
                title: 'Reason for Exceeding Report Limit',
                isRequired: true,
                fieldWidget: AppTextField(
                  maxLines: 4,
                  hintText: 'Describe your situation in detail ',
                  textController: reasonController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                ),
              ),

              Column(
                spacing: 15,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Supporting Evidence',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: ' (Optional)',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                  AppText(
                    text:
                    'Upload any documents or screenshots that support your explanation (PDF, JPG, PNG) maximum size 10 MB .',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  selectedFile == null
                      ? GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.fieldGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          AppText(
                            text: 'Click to upload',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: AppColors.primaryColor,
                          ),
                          AppIconWidget(assetPath: AssetImages.upload),
                        ],
                      ),
                    ),
                  )
                      : Row(
                    spacing: 7,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIconWidget(assetPath: AssetImages.clip),
                      Expanded(
                        child: AppText(
                          text: selectedFileName ?? '',
                          fontSize: 14,
                          maxLine: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFile = null;
                            selectedFileName = null;
                          });
                        },
                        child:
                        AppIconWidget(assetPath: AssetImages.delete),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (e) => setState(() => isChecked = e ?? false),
                    hoverColor: AppColors.grey,
                    focusColor: AppColors.fieldGrey,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primaryColor;
                      }
                      return AppColors.white;
                    }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(color: AppColors.fieldGrey, width: 2),
                  ),
                  Flexible(
                    child: AuthChangeText(
                      text1: "I agree",
                      tappableText: 'terms and conditions',
                      onTap: () {
                        AppRoutes.pushNamed(
                          AppRoutes.webViewScreen,
                          arguments: WebViewModel(
                            appbar: CustomAppBar(
                              title: "Terms and Condition",
                              leadingSvg: AssetImages.backArrow,
                            ),
                            link: AppUrls.termsAndConditions,
                            isGenerateUrl: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppButton(
                title: isSubmitting ? 'Submitting...' : 'Submit',
                fontSize: 16,
                textColor: _isFormValid ? AppColors.white : AppColors.grey,
                bgColor:
                _isFormValid ? AppColors.primaryColor : AppColors.lightViolet,
                onTap: isSubmitting ? () {} : _submitReport,
              ),
            ],
          ).pad(),
        ),
      ),
    );
  }
}
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:lost_and_found/screens/authentication/register_screen.dart';
// import 'package:lost_and_found/screens/post/first_stepper_screen.dart';
// import 'package:lost_and_found/screens/profile/webView.dart';
// import 'package:lost_and_found/shared_widgets/app_bar.dart';
// import 'package:lost_and_found/shared_widgets/app_button.dart';
// import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
// import 'package:lost_and_found/shared_widgets/app_text.dart';
// import 'package:lost_and_found/shared_widgets/app_text_field.dart';
// import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
// import 'package:lost_and_found/utils/app_colors.dart';
// import 'package:lost_and_found/utils/app_dialog.dart';
// import 'package:lost_and_found/utils/app_images.dart';
// import 'package:lost_and_found/utils/app_routes.dart';
// import 'package:lost_and_found/utils/app_ui_helper.dart';
// import 'package:lost_and_found/utils/app_urls.dart';
// import 'package:lost_and_found/utils/app_utils.dart';
//
// class ReportJustification extends StatefulWidget {
//   const ReportJustification({super.key});
//
//   @override
//   State<ReportJustification> createState() => _ReportJustificationState();
// }
//
// class _ReportJustificationState extends State<ReportJustification> {
//   //String? selectedFile;
//   String? selectedImage;
//   final ImagePicker picker = ImagePicker();
//   bool isChecked = false;
//   TextEditingController nameController = TextEditingController();
//   TextEditingController mobileController = TextEditingController();
//   TextEditingController mailController = TextEditingController();
//   TextEditingController reasonController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     mailController.addListener(_refresh);
//     reasonController.addListener(_refresh);
//   }
//
//   void _refresh() => setState(() {});
//
//   @override
//   void dispose() {
//     mailController.removeListener(_refresh);
//     reasonController.removeListener(_refresh);
//     nameController.dispose();
//     mobileController.dispose();
//     mailController.dispose();
//     reasonController.dispose();
//     super.dispose();
//   }
//
//   bool get _isFormValid =>
//       AppUtils.validateEmail(mailController.text) == null &&
//           reasonController.text.trim().isNotEmpty &&
//           isChecked;
//   Future<void> pickImage() async {
//     final XFile? image = await picker.pickImage(
//       source: ImageSource.gallery,
//     );
//
//     if (image != null) {
//       setState(() {
//         selectedImage =image.path.split('/').last.substring(1) ;
//
//
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       appBar: CustomAppBar(title: '', leadingSvg: AssetImages.backArrow),
//
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             spacing: 10,
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Center(child: AppIconWidget(assetPath: AssetImages.reportJustification)),
//               AppText(
//                 text: 'Your Findora Account Has Been Suspended ',
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 textAlign: TextAlign.start,
//               ),
//               AppText(
//                 text:
//                     " Your Findora account has been temporarily suspended because we identified activity that may violate our Community Guidelines or Terms & Conditions. \n If you believe this suspension was made in error, you can submit an appeal for our team to review your account. ",
//
//                 fontWeight: FontWeight.w400,
//                 fontSize: 12,
//               ).padHorizontal(16),
//               AppText(
//                 text:
//                     'Please complete the form below with accurate information and explain why you believe your account should be reinstated',
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 textAlign: TextAlign.center,
//               ).padHorizontal(16),
//
//               buildTextFieldWithHeading(
//                 title: 'Full name',
//                 fieldWidget: AppTextField(
//                   hintText: 'enter name',
//                   textController: nameController,
//                   onChange: (v) {},
//                   onSubmit: (v) {},
//                   validator: (e) {
//                     return AppUtils.validateName(e);
//                   },
//                 ),
//               ),
//
//               //number
//               buildTextFieldWithHeading(
//                 title: 'Mobile Number',
//                 fieldWidget: AppTextField(
//
//                   hintText: 'Enter a mobile number',
//                   textController: mobileController,
//                   textInputType: TextInputType.phone,
//                   maxLength: 10,
//                   validator: (e) {
//                     if (e == null) return null;
//
//                     return AppUtils.validateMobileNumber(e);
//                   },
//                   onChange: (v) {},
//                   onSubmit: (v) {},
//                 ),
//               ),
//
//               //mail
//               buildTextFieldWithHeading(
//                 title: 'Email Address',
//                 isRequired: true,
//                 fieldWidget: AppTextField(
//                   hintText: 'Enter your Email Address',
//                   textController: mailController,
//                   onChange: (v) {},
//                   onSubmit: (v) {},
//                   validator: (e) {
//                     return AppUtils.validateEmail(e);
//                   },
//                 ),
//               ),
//
//               //reason
//               buildTextFieldWithHeading(
//                 title: 'Reason for Exceeding Report Limit',
//                 isRequired: true,
//                 fieldWidget: AppTextField(
//                   maxLines: 4,
//                   hintText: 'Describe your situation in detail ',
//                   textController: reasonController,
//                   onChange: (v) {},
//                   onSubmit: (v) {},
//                   validator: (e) {
//                     return AppUtils.validateName(e);
//                   },
//                 ),
//               ),
//
//               //document upload
//               Column(
//                 spacing: 15,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text.rich(
//                     TextSpan(
//                       text: 'Supporting Evidence',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w400,
//                         color: Colors.black,
//                       ),
//                       children: [
//                         TextSpan(
//                           text: ' (Optional)',
//                           style: TextStyle(color: AppColors.grey),
//                         ),
//                       ],
//                     ),
//                   ),
//                   AppText(
//                     text:
//                         'Upload any documents or screenshots that support your explanation (PDF, JPG, PNG) maximum size 10 MB .',
//                     fontSize: 14,
//                     fontWeight: FontWeight.w400,
//                   ),
//
//
//                   selectedImage == null ? GestureDetector(
//                     onTap: pickImage,
//                     child: Container(
//
//                       height: 50,
//                       width: 150,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: AppColors.fieldGrey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         spacing: 10,
//                         children: [
//                           AppText(
//
//                             text: 'Click to upload',
//                             fontWeight: FontWeight.w400,
//                             fontSize: 12,
//                             color: AppColors.primaryColor,
//                           ),
//                           AppIconWidget(assetPath: AssetImages.upload),
//                         ],
//                       ),
//                     ),
//                   ) :
//                   Row(
//                     spacing: 7,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       AppIconWidget(assetPath: AssetImages.clip),
//                       Expanded(child: AppText(text: selectedImage!,fontSize: 14,maxLine: 1,)),
//                       Spacer(),
//                       GestureDetector(
//                         onTap: (){
//                           setState(() {
//                             selectedImage = null;
//                           });
//                         },
//                           child: AppIconWidget(assetPath: AssetImages.delete)),
//                     ],
//                   )
//                 ],
//               ),
//
//               SizedBox(height: 10,),
//               //check Box
//               Row(
//                 crossAxisAlignment: .start,
//                 spacing: 5,
//                 children: [
//                   Checkbox(
//                     value: isChecked,
//                     onChanged: (e) {
//                       setState(() {
//                         isChecked = e ?? false;
//                       });
//                     },
//                     hoverColor: AppColors.grey,
//                     focusColor: AppColors.fieldGrey,
//                     fillColor: WidgetStateProperty.resolveWith((states) {
//                       if (states.contains(WidgetState.selected)) {
//                         return AppColors.primaryColor;
//                       }
//                       return AppColors.white;
//                     }),
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     visualDensity: const VisualDensity(
//                       horizontal: -4,
//                       vertical: -4,
//                     ),
//
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     side: BorderSide(color: AppColors.fieldGrey, width: 2),
//                   ),
//                   Flexible(
//                     child:
//                     AuthChangeText(
//                       text1: "I agree",
//                       tappableText: 'terms and conditions',
//                       onTap: () {
//                         AppRoutes.pushNamed(
//                           AppRoutes.webViewScreen,
//                           arguments: WebViewModel(
//                             appbar: CustomAppBar(
//                               title: "Terms and Condition",
//                               leadingSvg: AssetImages.backArrow,
//                             ),
//                             link: AppUrls.termsAndConditions,
//                             isGenerateUrl: true,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 10,),
//               AppButton(
//                 title: 'Submit',
//                 fontSize: 16,
//                 textColor: _isFormValid ? AppColors.white : AppColors.grey,
//                 bgColor: _isFormValid ? AppColors.primaryColor : AppColors.lightViolet,
//                 onTap: () {
//                   if (mailController.text.trim().isEmpty ||
//                       reasonController.text.trim().isEmpty) {
//                     AppSnackBar.show(
//                       context: context,
//                       message: 'Please fill all mandatory fields',
//                     );
//                     return;
//                   }
//
//                   if (AppUtils.validateEmail(mailController.text) != null) {
//                     AppSnackBar.show(context: context, message: 'Enter a valid email');
//                     return;
//                   }
//
//                   if (!isChecked) {
//                     AppSnackBar.show(
//                       context: context,
//                       message: 'Please accept the terms and conditions',
//                     );
//                     return;
//                   }
//
//                   AppDialogue.showPopup(
//                     context: context,
//                     content: SubmissionReceivedPopUp(),
//                   );
//                 },
//               ),
//               // AppButton(
//               //   title: 'Submit',
//               //   onTap: () {
//               //     if(mailController.text.trim().isEmpty || reasonController.text.trim().isEmpty){
//               //       AppSnackBar.show(context: context, message: 'please fill mandatory fields');
//               //     }
//               //     final emailError = AppUtils.validateEmail(mailController.text);
//               //
//               //     if (emailError != null) {
//               //       AppSnackBar.show(
//               //         context: context,
//               //         message: 'enter valid mail',
//               //       );
//               //       return;
//               //     }
//               //     if(isChecked && mailController.text.isNotEmpty && reasonController.text.isNotEmpty){
//               //       AppDialogue.showPopup(context: context, content: SubmissionReceivedPopUp());
//               //
//               //     }
//               //     // else{
//               //     // AppDialogue.showPopup(context: context, content: AlreadySubmittedPopUP());
//               //     //  }
//               //   },
//               //   fontSize: 16,
//               //   textColor: AppColors.grey,
//               //   bgColor: AppColors.lightViolet,
//               // ),
//             ],
//           ).pad(),
//         ),
//       ),
//     );
//   }
// }
