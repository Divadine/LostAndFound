import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class ReportChat extends StatefulWidget {
  const ReportChat({super.key});

  @override
  State<ReportChat> createState() => _ReportChatState();
}

class _ReportChatState extends State<ReportChat> {
  String? selectedReason;
  TextEditingController reasonController = TextEditingController();
  List<String> reasons = [
    'Spam',
    'Harassment',
    'Inappropriate content',
    'Fake information',
    'Scam',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15,
      children: [
        AppText(
          text: 'Report this chat',
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        AppText(
          text: "Why are you reporting this chat ?",
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        ...reasons.map((item) {
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
                      activeColor: AppColors.primaryColor,
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
                AppText(
                  text: item,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGrey,
                ),
              ],
            ),
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

        AppButton(
          title: 'Submit',
          onTap: () {
            AppRoutes.pop();
            if(selectedReason != null ){
              AppDialogue.showPopup(
                context: context,
                content: ReportChatDialog(),
              );
            }else{
              AppSnackBar.show(
                context: context,
                message: "Please choose a reason",
              );
            }


          },
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
        ),
      ],
    );
  }
}
