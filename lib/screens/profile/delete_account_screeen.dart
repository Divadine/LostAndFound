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
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  List<DeletePostReasons> reasons = [];
  bool isLoading = true;
  String? errorMessage;

  DeletePostReasons? selectedReason;
  bool isChecked = false;
  final TextEditingController reasonController = TextEditingController();

  // API list may or may not include an "Others" option — this stays
  // as a local-only sentinel so free-text entry always works.
  static const _othersId = -1;
  static final DeletePostReasons _othersOption = DeletePostReasons(id: _othersId, text: 'Others');

  @override
  void initState() {
    super.initState();
    _fetchReasons();
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchReasons() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getDeleteAccountReasons();

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      final fetched = response.data!;
      final hasOthers = fetched.any((r) => r.text.toLowerCase() == 'others');
      setState(() {
        reasons = hasOthers ? fetched : [...fetched, _othersOption];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load reasons';
        isLoading = false;
      });
    }
  }

  bool get _isOthersSelected => selectedReason?.id == _othersId || selectedReason?.text.toLowerCase() == 'others';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const AppText(
                text:
                "Please be aware that your account will remain active for 15 days before deleted. During this time, you have the ability to retrieve or reinstate your account. Once 15 days have passes, your account will be erased permanently.",
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              const AppText(
                text: "Why are you deleting your account ?",
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      AppText(text: errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      AppButton(title: 'Retry', onTap: _fetchReasons),
                    ],
                  ),
                )
              else
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
                            child: Radio<DeletePostReasons>(
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
                            text: item.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ).padBottom(),
                  );
                }),

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
                  const Flexible(
                    child: AppText(
                      text:
                      "I confirm that I want to delete my account and understand this action is permanent and cannot be undone.",
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
                  if (!isChecked || selectedReason == null) {
                    AppSnackBar.show(
                      context: context,
                      message: "Please choose a reason",
                    );
                    return;
                  }

                  final finalReason = _isOthersSelected
                      ? reasonController.text.trim()
                      : selectedReason!.text;

                  if (finalReason.isEmpty) {
                    AppSnackBar.show(context: context, message: "Please write a reason");
                    return;
                  }

                  AppDialogue.showPopup(
                    context: context,
                    content: DeletePopUp(reason: finalReason),
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