import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/handover_type.dart';
import 'package:lost_and_found/models/delete_post/delete_post_reasons.dart';
import 'package:lost_and_found/models/handover/handover_type.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';
import 'package:lost_and_found/screens/profile/webView.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_utils.dart';

class AppDialogue {
  static Future<bool> showPopup({
    required BuildContext context,
    required Widget content,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(15),
    EdgeInsets? insetPadding,
    Color backgroundColor = AppColors.white,
    double radius = 12,
    BorderSide borderSides = BorderSide.none,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: contentPadding,
          insetPadding: insetPadding,
          content: content,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: borderSides,
          ),
        );
      },
    );
    return result == true;
  }

  static Future<T?> showValuePopup<T>({
    required BuildContext context,
    required Widget content,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(15),
    EdgeInsets? insetPadding,
    Color backgroundColor = AppColors.white,
    double radius = 12,
    BorderSide borderSides = BorderSide.none,
  }) async {
    return showDialog<T>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: contentPadding,
          insetPadding: insetPadding,
          content: content,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: borderSides,
          ),
        );
      },
    );
  }
}

class AppSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    IconData icon = Icons.info_outline,
    Color backgroundColor = AppColors.idCardColor,
    Color textColor = AppColors.black,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: duration,
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(text: message, color: textColor),
              ),
            ],
          ),
        ),
      );
  }
}

class DeletePopUp extends StatefulWidget {
  final String reason;

  const DeletePopUp({super.key, required this.reason});

  @override
  State<DeletePopUp> createState() => _DeletePopUpState();
}

class _DeletePopUpState extends State<DeletePopUp> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  bool isDeleting = false;

  Future<void> _onConfirmDelete() async {
    final userId = AppPreferences.getUserId();
    if (userId == null) {
      AppRoutes.pop();
      return;
    }

    setState(() => isDeleting = true);

    final response = await authController.deleteAccount(
      userId: userId,
      reason: widget.reason,
    );

    if (!mounted) return;
    setState(() => isDeleting = false);

    if (response.isSuccess) {
      await AppPreferences.clearAll();
      if (!mounted) return;
      AppRoutes.pop();
      AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
    } else {
      AppRoutes.pop();
      AppDialogue.showPopup(
        context: context,
        content: AppText(
          text: response.message.isNotEmpty ? response.message : 'Failed to delete account',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.information),
        const SizedBox(height: 7),
        const AppText(
          text: 'Permanently Delete Account ?',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        const SizedBox(height: 7),
        const AppText(
          text:
          'This will erase your account and all data permanently. you can’t undo this. But you can still reactivate it if you log in within 15 days.',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: TextAlign.center,
        ).padHorizontal(20),
        const SizedBox(height: 15),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'No, Cancel',
                onTap: isDeleting ? () {} : () => AppRoutes.pop(),
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.grey),
                textColor: AppColors.grey,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: isDeleting ? 'Deleting...' : 'Yes, Delete',
                onTap: isDeleting ? () {} : _onConfirmDelete,
                fontSize: 14,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileReportPopUp extends StatelessWidget {
  const ProfileReportPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.hazards),
        SizedBox(height: 7),
        AppText(
          text: 'Profile Report Limit Reached',
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'You’ve reached the maximum number of reports allowed for row. As a precaution has been temporally restricted. If you believe is a mistake. Please submit a request for review.',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
        ).padHorizontal(20),
        SizedBox(height: 15),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: ' Cancel',
                onTap: () {
                  Navigator.pop(context);
                },
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.grey),
                textColor: AppColors.grey,
                radius: BorderRadius.circular(20),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'Justify',
                onTap: () {},
                fontSize: 14,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                radius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SubmissionReceivedPopUp extends StatelessWidget {
  const SubmissionReceivedPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.submit),
        SizedBox(height: 7),
        AppText(
          text: 'Submission Received',
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'We’ve received your request and it is under review by our team.  \n We’ll Contact you via email/phone once a verification process is completed.',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),
        SizedBox(height: 15),
        AppButton(
          title: 'Done',
          onTap: () {},
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
          radius: BorderRadius.circular(20),
        ).padHorizontal(25),
      ],
    );
  }
}

class AlreadySubmittedPopUP extends StatelessWidget {
  const AlreadySubmittedPopUP({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.tickmark),
        SizedBox(height: 7),
        AppText(
          text: 'Already Submitted',
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'You have already submitted a request. Our teams is currently reviewing it. Thanks for you patience.',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),
      ],
    );
  }
}

class DisclaimerPopUP extends StatefulWidget {
  final bool isFromOnBoard;

  const DisclaimerPopUP({super.key, this.isFromOnBoard = false});

  @override
  State<DisclaimerPopUP> createState() => _DisclaimerPopUPState();
}

class _DisclaimerPopUPState extends State<DisclaimerPopUP> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 15,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(text: 'Disclaimer', fontWeight: FontWeight.w500, fontSize: 18),
        AppText(
          text:
              'The information provided in this Lost & Found application is intended to help users report, search, and recover lost or found items. While we strive to keep the information accurate and up to date, we do not guarantee the authenticity ownership, or availability of any item listed. This pp is a platform that connects users and does not involve in the exchange or return of items. Users are advised to take necessary precautions  while sharing personal information or meeting others. Lost & Found is not responsible for any loss, damage, disputes, or consequences resulting from the use of this application.',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.black,
        ),
        if (!widget.isFromOnBoard)
          AppButton(
            title: 'Ok',
            onTap: () {
              AppRoutes.pop();
            },
            fontSize: 14,
            bgColor: AppColors.primaryColor,
            textColor: AppColors.white,
            radius: BorderRadius.circular(7),
          ).padHorizontal(80),

        if (widget.isFromOnBoard)
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
                child: AuthChangeText(
                  text1: "I have read and agree to the ",
                  tappableText: 'terms & conditions ',
                  text2: "and",
                  tappableText2: 'Privacy Policy.',
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
                  onTap2: () {
                    AppRoutes.pushNamed(
                      AppRoutes.webViewScreen,
                      arguments: WebViewModel(
                        appbar: CustomAppBar(
                          title: "Privacy & Policy",
                          leadingSvg: AssetImages.backArrow,
                        ),
                        link: AppUrls.privacyPolicyLink,
                        isGenerateUrl: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        if (widget.isFromOnBoard)
          AppButton(
            radius: BorderRadius.all(Radius.circular(10)),
            title: 'Confirm',
            onTap: () async{
              await AppPreferences.setIsOnboarded(true);
              if (isChecked) {
                AppRoutes.pop();
                AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please check the disclaimer"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // AppSnackBar.show(
                //   context: context,
                //   message: "please check the disclaimer",
                // );
              }
            },
            bgColor: isChecked ? AppColors.primaryColor : AppColors.disclaimerGrey,
            fontSize: 16,
            textColor: AppColors.white,
          ),
      ],
    );
  }
}



class LogoutPopUp extends StatefulWidget {
  const LogoutPopUp({super.key});

  @override
  State<LogoutPopUp> createState() => _LogoutPopUpState();
}

class _LogoutPopUpState extends State<LogoutPopUp> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  bool isLoggingOut = false;

  Future<void> _onConfirmLogout() async {
    final userId = AppPreferences.getUserId();
    if (userId == null) {
      AppRoutes.pop();
      return;
    }

    setState(() => isLoggingOut = true);

    final response = await authController.logout(userId: userId);

    if (!mounted) return;
    setState(() => isLoggingOut = false);

    if (response.isSuccess) {
      await AppPreferences.clearAll();
      if (!mounted) return;
      AppRoutes.pop(); // close popup
      AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
    } else {
      AppRoutes.pop();
      AppDialogue.showPopup(
        context: context,
        content: AppText(
          text: response.message.isNotEmpty ? response.message : 'Failed to logout',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.logout),
        const SizedBox(height: 7),
        const AppText(
          text: 'Do you really want to log out?',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        const SizedBox(height: 7),
        const AppText(
          text:
          'Your journey isn’t over yet ! but it’s ok you can login anytime you want',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: TextAlign.center,
          color: AppColors.grey,
        ).padHorizontal(20),
        const SizedBox(height: 10),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: isLoggingOut ? 'Please wait...' : 'Yes',
                fontSize: 14,
                onTap: isLoggingOut ? () {} : _onConfirmLogout,
                bgColor: AppColors.grey.withAlpha(50),
                textColor: AppColors.grey,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'No',
                fontSize: 14,
                onTap: () => AppRoutes.pop(),
                textColor: AppColors.white,
                bgColor: AppColors.primaryColor,
                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TransferCompleted extends StatelessWidget {
  final TransferType type;
  final TransferData data;

  const TransferCompleted({
    super.key,
    required this.type,
    required this.data,
  });

  // ============================================================
  // TYPE CHECKS
  // ============================================================

  bool get isReceive {
    return type == TransferType.receiveToOthers ||
        type == TransferType.receiveToPolice ||
        type == TransferType.receiveToOwner;
  }

  bool get isPolice {
    return type == TransferType.receiveToPolice ||
        type == TransferType.handOverToPolice;
  }

  bool get isOthers {
    return type == TransferType.receiveToOthers ||
        type == TransferType.handOverToOthers;
  }

  bool get isOwner {
    return type == TransferType.receiveToOwner ||
        type == TransferType.handOverToOwner;
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get completedTitle {
    if (isReceive) {
      return 'Item received successfully!';
    }

    return 'Hand Over Completed!';
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  String get completedDescription {
    if (isReceive) {
      return 'You have successfully received the item from';
    }

    return 'You have successfully handed over the item to';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 7,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // SUCCESS ICON
          // ======================================================

          AppIconWidget(
            assetPath: AssetImages.handoverToOwner,
          ),

          const SizedBox(height: 7),

          // ======================================================
          // TITLE
          // ======================================================

          AppText(
            text: completedTitle,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),

          const SizedBox(height: 7),

          // ======================================================
          // DESCRIPTION
          // ======================================================

          AppText(
            text: completedDescription,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.center,
            color: AppColors.grey,
          ).padHorizontal(20),

          // ======================================================
          // USER / POLICE / OTHERS CARD
          // ======================================================

          _buildPersonCard(),

          const SizedBox(height: 10),

          // ======================================================
          // DONE
          // ======================================================

          AppButton(
            title: 'Done',
            fontSize: 14,
            onTap: () {
              AppRoutes.pop();

              AppUiHelper.showBottomSheet(
                showHandle: false,
                showCloseIcon: true,
                context: context,
                child: ReceivedDetails(
                  type: type,
                  data: data,
                ),
              );
            },
            bgColor: AppColors.primaryColor,
            radius: BorderRadius.circular(7),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildPersonCard() {
    if (isPolice) {
      return _buildPoliceCard();
    }

    if (isOthers) {
      return _buildOthersCard();
    }

    return _buildOwnerCard();
  }

  // ============================================================
  // OWNER CARD
  // ============================================================

  Widget _buildOwnerCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          data.avatarUrl.isNotEmpty
              ? AppCachedNetworkImage(
                  imageUrl: data.avatarUrl,
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(26),
                )
              : CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.fieldGrey,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryColor,
                  ),
                ),

          const SizedBox(width: 15),

          Expanded(
            child: AppText(
              text: data.name.isNotEmpty
                  ? data.name
                  : 'Unknown User',
              fontSize: 13,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (data.matchPercentage != null)
            _buildMatchPercentage(
              data.matchPercentage!,
            ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // OTHERS CARD
  // ============================================================

  Widget _buildOthersCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          data.avatarUrl.isNotEmpty
              ? AppCachedNetworkImage(
                  imageUrl: data.avatarUrl,
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(26),
                )
              : CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.fieldGrey,
                  child: AppIconWidget(
                    assetPath: AssetImages.threeDotsHorizontal,
                  ),
                ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: data.name.isNotEmpty
                      ? data.name
                      : 'Others',
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),

                if (data.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  AppText(
                    text: data.phoneNumber,
                    fontSize: 11,
                    color: AppColors.fieldGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ],
            ),
          ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // POLICE CARD
  // ============================================================

  Widget _buildPoliceCard() {
    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconWidget(
            assetPath: AssetImages.policeStation,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: data.policeStationName.isNotEmpty
                      ? data.policeStationName
                      : 'Police Station',
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),

                AppText(
                  text: data.policeStationAddress.isNotEmpty
                      ? data.policeStationAddress
                      : 'Address not available',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fieldGrey,
                  textOverflow: TextOverflow.ellipsis,
                  maxLine: 3,
                ),
              ],
            ),
          ),
        ],
      ).pad(),
    );
  }

  // ============================================================
  // MATCH PERCENTAGE
  // ============================================================

  Widget _buildMatchPercentage(int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppUtils
            .getMatchColor(percentage)
            .withAlpha(70),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        text: '$percentage% match',
        fontWeight: FontWeight.w500,
        fontSize: 10,
        color: AppUtils.getMatchColor(
          percentage,
        ),
      ),
    );
  }
}

// class HandOverToOwner extends StatelessWidget {
//   final String name;
//   final String avatarUrl;
//   final int matchPercentage;
//
//   const HandOverToOwner({
//     super.key,
//     required this.name,
//     required this.avatarUrl,
//     required this.matchPercentage,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 5,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Hand Over Completed!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully handed over the item to',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(20),
//
//         AppContainer(
//           widget: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 26,
//                 child: avatarUrl.isNotEmpty
//                     ? AppCachedNetworkImage(
//                   imageUrl: avatarUrl,
//                   fit: BoxFit.cover,
//                   borderRadius: BorderRadius.circular(30),
//                 )
//                     : Icon(Icons.person, color: AppColors.primaryColor),
//               ),
//               const SizedBox(width: 15),
//               AppText(
//                 text: name,
//                 fontSize: 13,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//               Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: AppUtils.getMatchColor(matchPercentage).withAlpha(70),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: AppText(
//                   text: '$matchPercentage% match',
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10,
//                   color: AppUtils.getMatchColor(matchPercentage),
//                 ),
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//             AppUiHelper.showBottomSheet(
//               showHandle: false,
//               showCloseIcon: true,
//               context: context,
//               child: ReceivedDetails(
//                 isReceivedFromPolice: false,
//                 isReceivedFromFounder: true,
//                 isReceivedFromOthers: false,
//               ),
//             );
//           },
//           bgColor: AppColors.primaryColor,
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }
//
// class HandOverToPolice extends StatelessWidget {
//   const HandOverToPolice({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 7,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Hand Over Completed!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully handed over the item to',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(),
//
//         AppContainer(
//           widget: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               AppIconWidget(assetPath: AssetImages.policeStation),
//
//               SizedBox(width: 10),
//
//               Expanded(
//                 child: Column(
//                   spacing: 5,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(
//                       text: "Peelamedu Police Station",
//                       fontSize: 14,
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     AppText(
//                       text:
//                           'Fci road second street, Gandhimanagar, Coimbatore, Tamil Nadu - 641001',
//                       fontSize: 12,
//                       fontWeight: FontWeight.w400,
//                       color: AppColors.fieldGrey,
//                       textOverflow: TextOverflow.ellipsis,
//                       maxLine: 3,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//             AppUiHelper.showBottomSheet(
//               showHandle: false,
//               showCloseIcon: true,
//               context: context,
//               child: ReceivedDetails(
//                 isReceivedFromPolice: true,
//                 isReceivedFromFounder: false,
//                 isReceivedFromOthers: false,
//               ),
//             );
//           },
//           bgColor: AppColors.primaryColor,
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }
//
// class HandOverToOthers extends StatelessWidget {
//   const HandOverToOthers({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 5,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Hand Over Completed!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully handed over the item to',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(20),
//
//         AppContainer(
//           widget: Row(
//             spacing: 7,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 26,
//                 child: AppIconWidget(
//                   assetPath: AssetImages.threeDotsHorizontal,
//                 ),
//               ),
//
//               const SizedBox(width: 15),
//
//               AppText(
//                 text: "Hand over to others",
//                 fontSize: 14,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//           },
//           bgColor: AppColors.primaryColor,
//
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }
//
// class ReceiveToOwner extends StatelessWidget {
//   const ReceiveToOwner({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 5,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Item received successfully!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully received the item from',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(20),
//
//         AppContainer(
//           widget: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 26,
//                 child: AppCachedNetworkImage(
//                   imageUrl: "https://i.pravatar.cc/150?img=1",
//                   fit: BoxFit.cover,
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//
//               const SizedBox(width: 15),
//
//               AppText(
//                 text: "Rahul Sharma",
//                 fontSize: 13,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//               Spacer(),
//
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppUtils.getMatchColor(98).withAlpha(70),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: AppText(
//                   text: '${98}% match',
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10,
//                   color: AppUtils.getMatchColor(98),
//                 ),
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//             AppUiHelper.showBottomSheet(
//               showHandle: false,
//               showCloseIcon: true,
//               context: context,
//               child: ReceivedDetails(
//                 isReceivedFromPolice: false,
//                 isReceivedFromFounder: true,
//                 isReceivedFromOthers: false,
//               ),
//             );
//           },
//           bgColor: AppColors.primaryColor,
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }
//
// class ReceiveToPolice extends StatelessWidget {
//   const ReceiveToPolice({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 7,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Item received successfully!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully handed over the item to',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(),
//
//         AppContainer(
//           widget: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               AppIconWidget(assetPath: AssetImages.policeStation),
//
//               SizedBox(width: 10),
//
//               Expanded(
//                 child: Column(
//                   spacing: 5,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(
//                       text: "Peelamedu Police Station",
//                       fontSize: 14,
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     AppText(
//                       text:
//                       'Fci road second street, Gandhimanagar, Coimbatore, Tamil Nadu - 641001',
//                       fontSize: 12,
//                       fontWeight: FontWeight.w400,
//                       color: AppColors.fieldGrey,
//                       textOverflow: TextOverflow.ellipsis,
//                       maxLine: 3,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//             AppUiHelper.showBottomSheet(
//               showHandle: false,
//               showCloseIcon: true,
//               context: context,
//               child: ReceivedDetails(
//                 isReceivedFromPolice: true,
//                 isReceivedFromFounder: false,
//                 isReceivedFromOthers: false,
//               ),
//             );
//           },
//           bgColor: AppColors.primaryColor,
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }
//
// class ReceiveToOthers extends StatelessWidget {
//   const ReceiveToOthers({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 5,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppIconWidget(assetPath: AssetImages.handoverToOwner),
//         SizedBox(height: 7),
//         AppText(
//           text: 'Received Completed!',
//           fontWeight: FontWeight.w600,
//           fontSize: 14,
//         ),
//         SizedBox(height: 7),
//         AppText(
//           text: 'You have successfully handed over the item to',
//           fontSize: 12,
//           fontWeight: FontWeight.w400,
//           textAlign: .center,
//           color: AppColors.grey,
//         ).padHorizontal(20),
//
//         AppContainer(
//           widget: Row(
//             spacing: 7,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 26,
//                 child: AppIconWidget(
//                   assetPath: AssetImages.threeDotsHorizontal,
//                 ),
//               ),
//
//               const SizedBox(width: 15),
//
//               AppText(
//                 text: "Received to others",
//                 fontSize: 14,
//                 color: AppColors.primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ],
//           ).pad(),
//         ),
//
//         SizedBox(height: 10),
//         AppButton(
//           title: 'Done',
//           fontSize: 14,
//           onTap: () {
//             AppRoutes.pop();
//             AppUiHelper.showBottomSheet(
//               showHandle: false,
//               showCloseIcon: true,
//               context: context,
//               child: ReceivedDetails(
//                 isReceivedFromPolice: false,
//                 isReceivedFromFounder: false,
//                 isReceivedFromOthers: true,
//               ),
//             );
//           },
//           bgColor: AppColors.primaryColor,
//
//           radius: BorderRadius.circular(7),
//         ),
//       ],
//     );
//   }
// }

class PostLive extends StatelessWidget {
  const PostLive({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.livePost),
        SizedBox(height: 7),
        AppText(
          text: 'Your Post is live!',
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        SizedBox(height: 7),
        AppText(
          text: 'We will notify you when we find a matching item.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),

        SizedBox(height: 10),
        AppButton(
          title: 'Go to Home',
          fontSize: 14,
          onTap: () async {
            await AppPreferences.setIsItemPosted(true);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
          },
          bgColor: AppColors.primaryColor,

          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

class DeletePostReasonsDialog extends StatefulWidget {
  final int postId;
  final void Function(int)? onDeleted;
  const DeletePostReasonsDialog({super.key, required this.postId, this.onDeleted});

  @override
  State<DeletePostReasonsDialog> createState() =>
      _DeletePostReasonsDialogState();
}

class _DeletePostReasonsDialogState extends State<DeletePostReasonsDialog> {

  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  int presentIndex = 0;

  TextEditingController reasonController = TextEditingController();
  List<DeletePostReasons> reasons = [];
  DeletePostReasons? selectedReason;

  bool isLoading = true;
  String? errorMessage;

  static const _othersId = -1;
  static final DeletePostReasons _othersOption = DeletePostReasons(id: _othersId, text: 'Others');

  @override
  void initState() {
    super.initState();
    fetchReasons();
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> fetchReasons() async {

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await authController.getDeleteReasons();
    if (!mounted) return;

    if(response.isSuccess && response.data != null){
      final fetched = response.data!;
      final hasOthers = fetched.any((r) => r.text.toLowerCase() == 'others');
      setState(() {
        reasons = hasOthers ? fetched : [...fetched, _othersOption];
        isLoading = false;
      });
    }else{
      setState(() {
        errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load reasons';
        isLoading = false;
      });
    }


  }
  bool get _isOthersSelected => selectedReason?.id == _othersId || selectedReason?.text.toLowerCase() == 'others';
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: .start,
        children: [
          AppText(
            text: 'Delete Post',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 10),
          AppText(
            text: 'Why are you deleting this post ?',
            fontWeight: FontWeight.w500,
            fontSize: 14,
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
                  AppButton(title: 'Retry', onTap: fetchReasons),
                ],
              ),
            )
          else

          ...reasons.map((item) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedReason = item;
                  });
                },
                child: Row(
                  spacing: 5,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Radio<DeletePostReasons>(
                        hoverColor: AppColors.primaryColor,
                        groupValue: selectedReason,
                        activeColor: AppColors.primaryColor,
                        onChanged:(value) => setState(() => selectedReason = value),
                        value: item,
                      ),
                    ),
                    Expanded(
                      child: AppText(
                        text: item.text,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_isOthersSelected) ...[
            AppText(
              text: 'Please tell us the reason',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              textAlign: TextAlign.start,
            ),

            SizedBox(height: 10),
            AppTextField(
              hintText: 'Write a reason',
              textController: reasonController,
              onChange: (v) {},
              onSubmit: (v) {},
              maxLines: 4,
            ),
          ],

          SizedBox(height: 8),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: AppButton(
                  title: 'cancel',
                  onTap: () {
                    AppRoutes.pop();
                  },
                  bgColor: Colors.transparent,
                  border: Border.all(color: AppColors.primaryColor),
                  textColor: AppColors.primaryColor,
                  radius: BorderRadius.circular(7),
                ),
              ),
              Expanded(
                child: AppButton(
                  title: 'Next',
                  onTap: () {
                    if (selectedReason == null) {
                      AppSnackBar.show(context: context, message: 'Please select a reason');
                      return;
                    }
                    final finalReason = _isOthersSelected
                        ? reasonController.text.trim()
                        : selectedReason!.text;
                    if (finalReason.isEmpty) {
                      AppSnackBar.show(context: context, message: 'Please enter a reason');
                      return;
                    }
                    AppRoutes.pop();

                    AppDialogue.showPopup(
                      context: context,
                      content: DeletePostDialog(
                        postId: widget.postId,
                        reason: finalReason,
                        onDeleted: widget.onDeleted,
                      ),
                    );
                  },
                  textColor: AppColors.white,
                  bgColor: AppColors.primaryColor,
                  radius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeletePostDialog extends StatefulWidget {
  final int postId;
  final String reason;
  final void Function(int)? onDeleted;
  const DeletePostDialog({super.key, required this.postId, required this.reason, this.onDeleted});

  @override
  State<DeletePostDialog> createState() => _DeletePostDialogState();
}

class _DeletePostDialogState extends State<DeletePostDialog> {

  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  bool isDeleting = false;

  Future<void> confirmDelete() async {
    print('CONFIRM DELETE CALLED — postId: ${widget.postId}, reason: ${widget.reason}');
    setState(() => isDeleting = true);
    final response = await authController.deletePost(postId: widget.postId, reason: widget.reason);

    if (!mounted) return;
    setState(() => isDeleting = false);

    if(response.isSuccess) {
      AppSnackBar.show(
        context: context,
        message: response.message.isNotEmpty ? response.message : 'Post deleted successfully',
        backgroundColor: AppColors.primaryColor,
        textColor: AppColors.white,
      );
      AppRoutes.pop();
      widget.onDeleted?.call(widget.postId);
    }else {
      AppDialogue.showPopup(context: context, content: AppText(text: response.message.isNotEmpty ? response.message : 'Failed to delete post',),);
    }

  }


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.red.withAlpha(50),
          radius: 20,
          child: AppIconWidget(assetPath: AssetImages.delete),
        ),
        SizedBox(height: 7),
        AppText(text: 'Delete Post', fontWeight: FontWeight.w600, fontSize: 16),
        SizedBox(height: 7),
        AppText(
          text: 'Are you sure you want to delete this lost item post ?',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: .center,
        ).padHorizontal(20),
        SizedBox(height: 15),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'Cancel',
                onTap: isDeleting ? () {} : () => AppRoutes.pop(),
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.black),
                textColor: AppColors.black,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: isDeleting ? 'Deleting...' : 'Delete Post',
                onTap: isDeleting ? () {} : confirmDelete,
                fontSize: 14,
                bgColor: AppColors.red,
                textColor: AppColors.white,
                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppLocationAccess extends StatefulWidget {
  const AppLocationAccess({super.key});

  @override
  State<AppLocationAccess> createState() => _AppLocationAccessState();
}

class _AppLocationAccessState extends State<AppLocationAccess> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.mapAccess),

        SizedBox(height: 7),
        AppText(
          text: 'Set your location',
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.fieldGrey,
        ).padHorizontal(10),
        SizedBox(height: 15),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'Deny',
                onTap: () {
                  Navigator.pop(context);
                },
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.black),
                textColor: AppColors.black,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'Allow location',
                onTap: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
                fontSize: 16,

                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DeviceLocationAccess extends StatefulWidget {
  const DeviceLocationAccess({super.key});

  @override
  State<DeviceLocationAccess> createState() => _DeviceLocationAccessState();
}

class _DeviceLocationAccessState extends State<DeviceLocationAccess> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.mapAccess),

        SizedBox(height: 7),
        AppText(
          text: 'Set your location',
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.fieldGrey,
        ).padHorizontal(10),
        SizedBox(height: 15),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'Cancel',
                onTap: () {
                  Navigator.pop(context);
                },
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.black),
                textColor: AppColors.black,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'Enable location',
                onTap: () async {
                  Navigator.pop(context);

                  await Geolocator.openLocationSettings();
                },
                fontSize: 16,

                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BlockChat extends StatefulWidget {
  final Future<void> Function()? onUnblock;
  final Future<void> Function()? onDeleteChat;

  const BlockChat({
    super.key,
    this.onUnblock,
    this.onDeleteChat,
  });

  @override
  State<BlockChat> createState() => _BlockChatState();
}

class _BlockChatState extends State<BlockChat> {
  bool _isUnblocking = false;
  bool _isDeleting = false;

  // ============================================================
  // UNBLOCK
  // ============================================================

  Future<void> _handleUnblock() async {
    if (_isUnblocking || _isDeleting) return;

    setState(() {
      _isUnblocking = true;
    });

    try {
      if (widget.onUnblock != null) {
        await widget.onUnblock!();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUnblocking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE CHAT
  // ============================================================

  Future<void> _handleDeleteChat() async {
    if (_isUnblocking || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      if (widget.onDeleteChat != null) {
        await widget.onDeleteChat!();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========================================================
        // ICON
        // ========================================================

        AppIconWidget(
          assetPath: AssetImages.blockChatBorder,
        ),

        const SizedBox(height: 12),

        // ========================================================
        // TITLE
        // ========================================================

        const AppText(
          text: 'This chat has been blocked',
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),

        const SizedBox(height: 10),

        // ========================================================
        // DESCRIPTION
        // ========================================================

        AppText(
          text:
          'You cannot send or receive messages in this chat while it is blocked.',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: TextAlign.center,
          color: AppColors.fieldGrey,
        ).padHorizontal(10),

        const SizedBox(height: 20),

        // ========================================================
        // BUTTONS
        // ========================================================

        Row(
          children: [
            // ====================================================
            // DELETE CHAT
            // ====================================================

            Expanded(
              child: AppButton(
                title: _isDeleting
                    ? 'Deleting...'
                    : 'Delete chat',
                onTap: _isUnblocking || _isDeleting
                    ? () {}
                    : _handleDeleteChat,
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(
                  color: AppColors.black,
                ),
                textColor: AppColors.black,
                radius: BorderRadius.circular(7),
              ),
            ),

            const SizedBox(width: 10),

            // ====================================================
            // UNBLOCK CHAT
            // ====================================================

            Expanded(
              child: AppButton(
                title: _isUnblocking
                    ? 'Unblocking...'
                    : 'Unblock chat',
                onTap: _isUnblocking || _isDeleting
                    ? () {}
                    : _handleUnblock,
                fontSize: 16,
                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReportChatReasonSheet extends StatefulWidget {
  final int userId;
  final String userName;
  final String userMobile;
  final String userEmail;
  final String roomId;
  final AuthControllers authControllers;

  const ReportChatReasonSheet({
    super.key,
    required this.userId,
    required this.userName,
    required this.userMobile,
    required this.userEmail,
    required this.roomId,
    required this.authControllers,
  });

  @override
  State<ReportChatReasonSheet> createState() => _ReportChatReasonSheetState();
}

class _ReportChatReasonSheetState extends State<ReportChatReasonSheet> {
  // TODO: swap for a real reasons API if you have one (like getReasonsDeletePost)
  final List<String> reasons = const [
    'Spam or scam',
    'Inappropriate content',
    'Harassment or abuse',
    'Fake item / listing',
  ];

  String? selectedReason;
  bool isOthers = false;
  final TextEditingController othersController = TextEditingController();

  bool get isSubmitEnabled {
    if (selectedReason == null) return false;
    if (isOthers) return othersController.text.trim().isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    othersController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final reason = isOthers ? othersController.text.trim() : selectedReason!;

    AppRoutes.pop(); // close this sheet

    AppDialogue.showPopup(
      context: context,
      content: ReportChatDialog(
        reason: reason,
        userId: widget.userId,
        userName: widget.userName,
        userMobile: widget.userMobile,
        userEmail: widget.userEmail,
        roomId: widget.roomId,
        authControllers: widget.authControllers,
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(text: 'Report this chat', fontWeight: FontWeight.w600, fontSize: 18),
        const SizedBox(height: 12),
        AppText(text: 'Why are you reporting this review?', fontSize: 14),
        const SizedBox(height: 8),

        for (final r in reasons)
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: r,
            groupValue: selectedReason,
            title: AppText(text: r, fontSize: 14),
            onChanged: (v) => setState(() {
              selectedReason = v;
              isOthers = false;
            }),
          ),

        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'Others',
          groupValue: selectedReason,
          title: AppText(text: 'Others', fontSize: 14),
          onChanged: (v) => setState(() {
            selectedReason = v;
            isOthers = true;
          }),
        ),

        if (isOthers) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.fieldGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: othersController,
              inputFormatters: [NoLeadingSpaceFormatter()],
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Type here',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            title: 'Submit',
            onTap: isSubmitEnabled ? _onSubmit : () {}, // was: null
            bgColor: isSubmitEnabled ? AppColors.primaryColor : AppColors.fieldGrey,
            radius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class ReportChatDialog extends StatefulWidget {
  final String reason;
  final int userId;
  final String userName;
  final String userMobile;
  final String userEmail;
  final String roomId;
  final AuthControllers authControllers;

  const ReportChatDialog({
    super.key,
    required this.reason,
    required this.userId,
    required this.userName,
    required this.userMobile,
    required this.userEmail,
    required this.roomId,
    required this.authControllers,
  });

  @override
  State<ReportChatDialog> createState() => _ReportChatDialogState();
}

class _ReportChatDialogState extends State<ReportChatDialog> {
  bool isChecked = false;
  bool isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() => isSubmitting = true);

    final response = await widget.authControllers.createReport(
      userId: widget.userId,
      name: widget.userName,
      mobileno: widget.userMobile,
      email: widget.userEmail,
      description: widget.reason, // <-- the reason picked in step 1
    );

    if (isChecked) {
      await ChatService.blockChat(
        roomId: widget.roomId,
        userId: widget.userId.toString(),
      );
    }

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (response.isSuccess) {
      AppSnackBar.show(context: context, message: response.message ?? 'Chat reported');
      AppRoutes.pop();
    } else {
      AppSnackBar.show(context: context, message: response.message ?? 'Failed to report chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(text: 'Report This Chat?', fontWeight: FontWeight.w500, fontSize: 20),
        const SizedBox(height: 7),
        AppText(
          text: widget.reason,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          textAlign: TextAlign.center,
          color: AppColors.fieldGrey,
        ).padHorizontal(10),
        const SizedBox(height: 15),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (e) => setState(() => isChecked = e!),
              hoverColor: AppColors.grey,
              focusColor: AppColors.fieldGrey,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryColor;
                }
                return AppColors.white;
              }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: BorderSide(color: AppColors.fieldGrey, width: 2),
            ),
            const Flexible(
              child: AppText(
                text: "Report and Block this chat",
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),

        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'Cancel',
                onTap: isSubmitting ? () {} : () => AppRoutes.pop(),
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.black),
                textColor: AppColors.black,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: isSubmitting ? 'Reporting...' : 'Report',
                onTap: isSubmitting ? () {} : _submitReport,
                fontSize: 16,
                radius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}



/// Dialog content used when another user asks to share their phone number.
///
/// The actual Firestore update is intentionally handled by the parent chat
/// screen through [onAccept] and [onDecline]. This widget only displays the
/// dialog UI.


class ChatSendRequest extends StatelessWidget {
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final String senderName;
  final DateTime requestTime;

  const ChatSendRequest({
    super.key,
    required this.onDecline,
    required this.onAccept,
    this.senderName = '',
    required this.requestTime,
  });

  // ============================================================
  // REQUEST DATE
  // ============================================================

  String _formatRequestDate(
      DateTime date) {
    final now =
    DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final requestDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final yesterday =
    today.subtract(
      const Duration(days: 1),
    );

    // ==========================================================
    // TODAY
    // ==========================================================

    if (requestDate == today) {
      return 'Today';
    }

    // ==========================================================
    // YESTERDAY
    // ==========================================================

    if (requestDate == yesterday) {
      return 'Yesterday';
    }

    // ==========================================================
    // OLDER
    // ==========================================================

    return DateFormat(
      'd MMM yyyy',
    ).format(requestDate);
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
    senderName.trim().isNotEmpty
        ? senderName.trim()
        : 'This user';

    return Column(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        // ======================================================
        // HEADER
        // ======================================================

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
              AppColors.idCardColor,
              radius: 20,
              child:
              AppIconWidget(
                assetPath:
                AssetImages.phone,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text:
                    'Contact Received',
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  AppText(
                    text:
                    '$displayName wants to share contact information with you.',
                    fontWeight:
                    FontWeight.w400,
                    fontSize: 12,
                    maxLine: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // TODAY / YESTERDAY / DATE
            // ==================================================

            AppText(
              text:
              _formatRequestDate(
                requestTime,
              ),
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
              color:
              AppColors.primaryColor,
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // BUTTONS
        // ======================================================

        Row(
          children: [
            // ==================================================
            // DECLINE
            // ==================================================

            Expanded(
              child: AppButton(
                title: 'Decline',
                onTap: onDecline,
                bgColor:
                AppColors.white,
                border:
                Border.all(
                  color:
                  AppColors.red,
                ),
                textColor:
                AppColors.red,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            // ==================================================
            // ACCEPT
            // ==================================================

            Expanded(
              child: AppButton(
                title: 'Accept',
                onTap: onAccept,
                bgColor:
                AppColors.primaryColor,
                textColor:
                AppColors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// class NotificationRequest extends StatelessWidget {
//
//   const NotificationRequest({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return
//   }
// }

