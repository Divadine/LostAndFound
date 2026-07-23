import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  List<String> reasonList = [
    "Found better tool/service",
    "No longer needed",
    'Navigation difficulties',
    'Privacy concerns',
    'Limited features',
    'Dissatisfied with content',
    'Unsuccessful results',
    'App crashes / technical issues',
    'Poor customer',
    "Others",

  ];
  String? selectedReason;
  bool isChecked = false;
  final TextEditingController reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "Delete Account",
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            crossAxisAlignment: .start,
            mainAxisAlignment: .start,
            children: [
              AppText(
                text:
                    "Please be aware that your account will remain active for 15 days before deleted. During this time, you have the ability to retrieve or reinstate your account. Once 15 days have passes, your account will be erased permanently.",
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              AppText(
                text: "Why are you deleting your account ?",
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              ...reasonList.map((item) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedReason = item;
                    });
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      SizedBox(
                        height: 4,
                        width: 8,
                        child: Transform.scale(
                          scale: 0.8,
                          child: Radio<String>(
                            hoverColor: AppColors.black,
                            activeColor: AppColors.black,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              setState(() {
                                selectedReason = value;
                              });
                            },
                            value: item,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AppText(
                          text: item,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ).padBottom(),
                );
              }),
              if (selectedReason == 'Others') ...[
                AppTextField(
                  hintText: 'Write a reason',
                  textController: reasonController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  maxLines: 4,
                ),
              ],
              Row(
                crossAxisAlignment: .start,
                spacing: 5,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (e) {
                      setState(() {
                        isChecked = e!;
                        if (isChecked) {
                          AppSnackBar.show(
                            context: context,
                            message: "Confirm for deletion",
                          );
                        }
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
                    child: AppText(
                      text:
                          "I confirm that I want to delete my account and understand this action is permanent and cannot be undone.",
                      fontWeight: FontWeight.w400,
                      textAlign: .start,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              AppButton(
                title: "Delete Account",
                onTap: () {
                  if (isChecked && selectedReason != null) {
                    AppDialogue.showPopup(
                      context: context,
                      content: DeletePopUp(),
                    );
                  } else {
                    AppSnackBar.show(
                      context: context,
                      message: "Please choose a reason",
                    );
                  }
                },
                fontSize: 15,
                radius: BorderRadius.circular(10),
              ),
            ],
          ).pad(16),
        ),
      ),
    );
  }
}
