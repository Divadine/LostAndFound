import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/delete_post/delete_post_reasons.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
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
  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  // Local delete account reasons
  final List<DeletePostReasons> reasons = [
    DeletePostReasons(
      id: 1,
      text: 'I no longer need Findora',
    ),
    DeletePostReasons(
      id: 2,
      text: 'I found another service',
    ),
    DeletePostReasons(
      id: 3,
      text: "I couldn't find my lost item",
    ),
    DeletePostReasons(
      id: 4,
      text: "I couldn't find the right item",
    ),
    DeletePostReasons(
      id: 5,
      text: 'I had difficulty using the app',
    ),
    DeletePostReasons(
      id: 6,
      text: 'Privacy concerns',
    ),
    DeletePostReasons(
      id: 7,
      text: 'Limited features',
    ),
    DeletePostReasons(
      id: 8,
      text: 'Too many notifications',
    ),
    DeletePostReasons(
      id: 9,
      text: 'App crashes or technical issues',
    ),
    DeletePostReasons(
      id: 10,
      text: 'I was dissatisfied with the experience',
    ),
    DeletePostReasons(
      id: -1,
      text: 'Other',
    ),
  ];

  DeletePostReasons? selectedReason;

  bool isChecked = false;

  final TextEditingController reasonController =
  TextEditingController();

  static const _othersId = -1;

  bool get _isOthersSelected =>
      selectedReason?.id == _othersId;

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "Account Deletion Notice",
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const AppText(
                text:
                'Please be aware that your Findora account '
                    'will remain active for 30 days after you '
                    'request deletion. During this period, you can choose'
                    ' to recover or reactivate your account. After 30 days,'
                    ' your account and associated data will be permanently '
                    'deleted and cannot be recovered.',
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),

              const AppText(
                text:
                "Why are you deleting your Findora account?",
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),

              // Delete account reasons
              ...reasons.map(
                    (item) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedReason = item;

                        // Clear custom reason when selecting
                        // any predefined reason.
                        if (item.id != _othersId) {
                          reasonController.clear();
                        }
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
                            child: Radio<DeletePostReasons>(
                              hoverColor: AppColors.black,
                              activeColor: AppColors.black,
                              groupValue: selectedReason,
                              value: item,
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value;

                                  if (value?.id != _othersId) {
                                    reasonController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: AppText(
                            text: item.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ).padBottom(),
                  );
                },
              ),

              // Show text field only when Other is selected
              if (_isOthersSelected) ...[
                AppTextField(
                  hintText: 'Write a reason',
                  textController: reasonController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  maxLines: 4,
                ),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (e) {
                      setState(() {
                        isChecked = e ?? false;

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
                    fillColor:
                    WidgetStateProperty.resolveWith(
                          (states) {
                        if (states.contains(
                          WidgetState.selected,
                        )) {
                          return AppColors.primaryColor;
                        }

                        return AppColors.white;
                      },
                    ),
                    materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(
                      color: AppColors.fieldGrey,
                      width: 2,
                    ),
                  ),
                  const Flexible(
                    child: AppText(
                      text:
                      "I confirm that I want to delete my Findora account."
                          " I understand that my account will be permanently "
                          "deleted after 30 days and cannot be recovered after that period.",
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.start,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              AppButton(
                title: "Delete Account",
                onTap: () {

                  // First check reason
                  if (selectedReason == null) {
                    AppSnackBar.show(
                      context: context,
                      message: "Please choose a reason",
                    );
                    return;
                  }

                  // Then check confirmation checkbox
                  if (!isChecked) {
                    AppSnackBar.show(
                      context: context,
                      message: "Please confirm for deletion",
                    );
                    return;
                  }

                  // Check checkbox and reason
                  // if (!isChecked || selectedReason == null) {
                  //   AppSnackBar.show(
                  //     context: context,
                  //     message: "Please confirm for deletion",
                  //   );
                  //   return;
                  // }

                  // Get selected reason
                  final finalReason = _isOthersSelected
                      ? reasonController.text.trim()
                      : selectedReason!.text;

                  // Other reason cannot be empty
                  if (finalReason.isEmpty) {
                    AppSnackBar.show(
                      context: context,
                      message: "Please write a reason",
                    );
                    return;
                  }

                  // Show confirmation popup
                  AppDialogue.showPopup(
                    context: context,
                    content: DeletePopUp(
                      reason: finalReason,
                    ),
                  );
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