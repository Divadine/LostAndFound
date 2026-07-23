import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/screens/webView.dart';
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
  const ReportJustification({super.key});

  @override
  State<ReportJustification> createState() => _ReportJustificationState();
}

class _ReportJustificationState extends State<ReportJustification> {
  //String? selectedFile;
  String? selectedImage;
  final ImagePicker picker = ImagePicker();
  bool isChecked = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController mailController = TextEditingController();
  TextEditingController reasonController = TextEditingController();

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage =image.path.split('/').last.substring(1) ;
        

      });
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
              Center(child: AppIconWidget(assetPath: AssetImages.reportJustification)),
              AppText(
                text: 'Your Account has been Suspended',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.start,
              ),
              AppText(
                text:
                    " Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since  Lorem Ipsum is simply ",
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ).padHorizontal(16),
              AppText(
                text:
                    'Please fill out the form below if you would like to try your account again.',
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
                  validator: (e) {
                    return AppUtils.validateName(e);
                  },
                ),
              ),

              //number
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

              //mail
              buildTextFieldWithHeading(
                title: 'Email Address*',
                fieldWidget: AppTextField(
                  hintText: 'Enter your Email Address',
                  textController: mailController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  validator: (e) {
                    return AppUtils.validateEmail(e);
                  },
                ),
              ),

              //reason
              buildTextFieldWithHeading(
                title: 'Reason for Exceeding Report Limit*',
                fieldWidget: AppTextField(
                  maxLines: 4,
                  hintText: 'Describe your situation in detail ',
                  textController: reasonController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  validator: (e) {
                    return AppUtils.validateName(e);
                  },
                ),
              ),

              //document upload
              Column(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: 'Supporting Evidence (Optional)',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                  AppText(
                    text:
                        'Upload any documents or screenshots that support your explanation (PDF, JPG, PNG) maximum size 10 MB .',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),


                  selectedImage == null ? GestureDetector(
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
                  ) :
                  Row(
                    spacing: 7,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconWidget(assetPath: AssetImages.clip),
                      Expanded(child: AppText(text: selectedImage!,fontSize: 14,maxLine: 1,)),
                      Spacer(),
                      GestureDetector(
                        onTap: (){
                          setState(() {
                            selectedImage = null;
                          });
                        },
                          child: AppIconWidget(assetPath: AssetImages.delete)),
                    ],
                  )
                ],
              ),

              //check Box
              Row(
                crossAxisAlignment: .start,
                spacing: 5,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (e) {
                      setState(() {
                        isChecked = e!;
                      });
                    },
                    hoverColor: AppColors.grey,
                    focusColor: AppColors.fieldGrey,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primaryColor;
                      }
                      return AppColors.white;
                    }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(color: AppColors.fieldGrey, width: 2),
                  ),
                  Flexible(
                    child:
                    AuthChangeText(
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

              AppButton(
                title: 'Submit',
                onTap: () {
                  if(mailController.text.trim().isEmpty || reasonController.text.trim().isEmpty){
                    AppSnackBar.show(context: context, message: 'please fill mandatory fields');
                  }
                  final emailError = AppUtils.validateEmail(mailController.text);

                  if (emailError != null) {
                    AppSnackBar.show(
                      context: context,
                      message: 'enter valid mail',
                    );
                    return;
                  }
                  if(isChecked && mailController.text.isNotEmpty && reasonController.text.isNotEmpty){
                    AppDialogue.showPopup(context: context, content: SubmissionReceivedPopUp());

                  }
                  // else{
                  // AppDialogue.showPopup(context: context, content: AlreadySubmittedPopUP());
                  //  }
                },
                fontSize: 16,
                textColor: AppColors.grey,
                bgColor: AppColors.lightViolet,
              ),
            ],
          ).pad(),
        ),
      ),
    );
  }
}
