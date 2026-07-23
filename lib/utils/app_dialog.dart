import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/onboarding_screen.dart';
import 'package:lost_and_found/screens/webView.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/auth_change_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'app_images.dart';
import 'app_routes.dart';
import 'app_ui_helper.dart';
import 'app_urls.dart';
import 'app_utils.dart';

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

class DeletePopUp extends StatelessWidget {
  const DeletePopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.information),
        SizedBox(height: 7),
        AppText(
          text: 'Permanently Delete Account ?',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'This will erase your account and all data permanently. you can’t undo this. But you can still reactivate it if you log in within 15 days.',
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
                title: 'No, Cancel',
                onTap: () {
                  AppRoutes.pop();
                },
                fontSize: 14,
                bgColor: Colors.transparent,
                border: Border.all(color: AppColors.grey),
                textColor: AppColors.grey,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'Yes, Delete',
                onTap: () {
                  AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
                },
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
                  //Navigator.pop(context);
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
            title: 'Confirm',
            onTap: () {
              if (isChecked) {
                AppRoutes.pop();
                AppRoutes.pushNamed(AppRoutes.bottomScreen);
              } else {
                AppSnackBar.show(
                  context: context,
                  message: "please check the disclaimer",
                );
              }
            },
            bgColor: AppColors.primaryColor,
            fontSize: 16,
            textColor: AppColors.white,
          ),
      ],
    );
  }
}

class LogoutPopUp extends StatelessWidget {
  const LogoutPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.logout),
        SizedBox(height: 7),
        AppText(
          text: 'Do you really want to log out?',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: 7),
        AppText(
          text:
              'Your journey isn’t over yet ! but it’s ok you can login anytime you want',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),

        SizedBox(height: 10),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: AppButton(
                title: 'Yes',
                fontSize: 14,
                onTap: () {
                  AppRoutes.pop();
                },
                bgColor: AppColors.grey.withAlpha(50),

                textColor: AppColors.grey,
                radius: BorderRadius.circular(7),
              ),
            ),
            Expanded(
              child: AppButton(
                title: 'No',
                fontSize: 14,
                onTap: () {
                  AppRoutes.pop();
                },
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

class HandOverToOwner extends StatelessWidget {
  const HandOverToOwner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.handoverToOwner),
        SizedBox(height: 7),
        AppText(
          text: 'Hand Over Completed!',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: 7),
        AppText(
          text: 'You have successfully handed over the item to',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),

        AppContainer(
          widget: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                child: AppCachedNetworkImage(
                  imageUrl: "https://i.pravatar.cc/150?img=1",
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(width: 15),

              AppText(
                text: "Rahul Sharma",
                fontSize: 13,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppUtils.getMatchColor(98).withAlpha(70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  text: '${98}% match',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: AppUtils.getMatchColor(98),
                ),
              ),
            ],
          ).pad(),
        ),

        SizedBox(height: 10),
        AppButton(
          title: 'Done',
          fontSize: 14,
          onTap: () {
            AppRoutes.pop();
          },
          bgColor: AppColors.primaryColor,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

class HandOverToPolice extends StatelessWidget {
  const HandOverToPolice({super.key});

  @override
  Widget build(BuildContext context) {
    return
      Column(
      spacing: 7,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.handoverToOwner),
        SizedBox(height: 7),
        AppText(
          text: 'Item received successfully!',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: 7),
        AppText(
          text: 'You have successfully handed over the item to',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(),

        AppContainer(
          widget: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AppIconWidget(assetPath: AssetImages.policeStation),

               SizedBox(width: 10),

              Expanded(
                child: Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: "Peelamedu Police Station",
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    AppText(
                      text:
                          'Fci road second street, Gandhimanagar, Coimbatore, Tamil Nadu - 641001',
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
        ),

        SizedBox(height: 10),
        AppButton(
          title: 'Done',
          fontSize: 14,
          onTap: () {
            AppRoutes.pop();
          },
          bgColor: AppColors.primaryColor,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

class HandOverToOthers extends StatelessWidget {
  const HandOverToOthers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.handoverToOwner),
        SizedBox(height: 7),
        AppText(
          text: 'Hand Over Completed!',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: 7),
        AppText(
          text: 'You have successfully handed over the item to',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),

        AppContainer(
          widget: Row(
            spacing: 7,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                child: AppIconWidget(
                  assetPath: AssetImages.threeDotsHorizontal,
                ),
              ),

              const SizedBox(width: 15),

              AppText(
                text: "Hand over to others",
                fontSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ).pad(),
        ),

        SizedBox(height: 10),
        AppButton(
          title: 'Done',
          fontSize: 14,
          onTap: () {
            AppRoutes.pop();
          },
          bgColor:AppColors.primaryColor,


          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

class ReceiveToOthers extends StatelessWidget {
  const ReceiveToOthers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWidget(assetPath: AssetImages.handoverToOwner),
        SizedBox(height: 7),
        AppText(
          text: 'Received Completed!',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        SizedBox(height: 7),
        AppText(
          text: 'You have successfully handed over the item to',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          textAlign: .center,
          color: AppColors.grey,
        ).padHorizontal(20),

        AppContainer(
          widget: Row(
            spacing: 7,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                child: AppIconWidget(
                  assetPath: AssetImages.threeDotsHorizontal,
                ),
              ),

              const SizedBox(width: 15),

              AppText(
                text: "Received to others",
                fontSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ).pad(),
        ),

        SizedBox(height: 10),
        AppButton(
          title: 'Done',
          fontSize: 14,
          onTap: () {
            AppRoutes.pop();
          },
          bgColor:AppColors.primaryColor,


          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

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
          onTap: () {
            AppRoutes.pop();
          },
          bgColor:AppColors.primaryColor,


          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}
