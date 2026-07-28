import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/screens/authentication/profile_screen.dart';
import 'package:lost_and_found/screens/profile/webView.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isEnable = false;

  getEmoji(int ratingsEmoji) {
    switch (ratingsEmoji) {
      case 1:
        return AssetImages.one_star;
      case 2:
        return AssetImages.two_star;
      case 3:
        return AssetImages.three_star;
      case 4:
        return AssetImages.four_star;
      case 5:
        return AssetImages.five_star;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRLEWjC-Hd4WpPkUHnFslUH-qp_VENqS3vYvZJUGoxMU5Zb-Ar3EXKq3c6&s=10',
                ),
              ),
              AppText(text: 'name', fontWeight: FontWeight.w500, fontSize: 16),

              SizedBox(height: 10),

              AppButton(
                title: "Edit Profile",
                onTap: () {
                  AppRoutes.pushNamed(
                    AppRoutes.profileScreen,
                    arguments: ProfileScreenModel(isFromEdit: true),
                  );
                },
                height: 35,
                fontSize: 12,
                prefixIcon: AssetImages.pen,
              ).padHorizontal(105),

              SizedBox(height: 10),

              AppContainer(
                widget: Column(
                  children: [
                    buildSettingTile(
                      image: AssetImages.bell,
                      title: 'notifications',
                      trailingIcon: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          activeColor: AppColors.white,
                          activeTrackColor: AppColors.primaryColor,
                          inactiveThumbColor: AppColors.grey,
                          // inactiveTrackColor: Colors.grey.shade300,
                          value: isEnable,
                          onChanged: (e) {
                            isEnable = !isEnable;
                            setState(() {});
                          },
                        ),
                      ),
                      onTap: () {},
                    ),

                    Divider(),
                    buildSettingTile(
                      image: AssetImages.termsConditions,
                      title: 'Terms & Conditions',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
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

                    Divider(),
                    buildSettingTile(
                      image: AssetImages.feedBack,
                      title: 'Feedback',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        AppRoutes.pushNamed(
                          AppRoutes.webViewScreen,
                          arguments: WebViewModel(
                            appbar: CustomAppBar(
                              title: "Feedback",
                              leadingSvg: AssetImages.backArrow,
                            ),
                            link: AppUrls.feedBackURL,
                            isGenerateUrl: true,
                          ),
                        );
                      },
                    ),
                    Divider(),
                    buildSettingTile(
                      image: AssetImages.aboutUs,
                      title: 'About us',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        AppRoutes.pushNamed(
                          AppRoutes.webViewScreen,
                          arguments: WebViewModel(
                            appbar: CustomAppBar(
                              title: "About Us",
                              leadingSvg: AssetImages.backArrow,
                            ),
                            link: AppUrls.aboutUsURL,
                            isGenerateUrl: true,
                          ),
                        );
                      },
                    ),

                    Divider(),

                    buildSettingTile(
                      image: AssetImages.privacyPolicy,
                      title: 'Privacy & Policy',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
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
                    Divider(),
                    buildSettingTile(
                      image: AssetImages.privacyPolicy,
                      title: 'Disclaimer',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        AppDialogue.showPopup(
                          context: context,
                          content: DisclaimerPopUP(isFromOnBoard: false,),
                        );
                        // AppRoutes.pop();
                      },
                    ),
                    Divider(),
                    buildSettingTile(
                      image: AssetImages.star,
                      title: 'Rate Us',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        int rating = 5;
                        AppDialogue.showPopup(
                          context: context,
                          content: StatefulBuilder(
                            builder: (context, setDialogState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 15,
                                children: [
                                  AppText(
                                    text: 'How are you feeling ? ',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),

                                  CircleAvatar(
                                    radius: 25,
                                    child: AppIconWidget(
                                      assetPath:
                                          getEmoji(rating) ??
                                          AssetImages.one_star,
                                    ),
                                  ),
                                  Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: List.generate(
                                        5,
                                        (stars) => GestureDetector(
                                          onTap: () {
                                            if (rating < 2) return;
                                            setDialogState(() {
                                              int selectedStar = stars + 1;
                                              if (rating == selectedStar) {
                                                rating = rating - 1;
                                              } else {
                                                rating = selectedStar;
                                              }
                                            });
                                          },
                                          child: AppIconWidget(
                                            assetPath: stars < rating
                                                ? AssetImages.filled_star
                                                : AssetImages.empty_star,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  AppButton(
                                    title: rating > 3 ? 'Submit' : 'Feedback',
                                    onTap: () async {
                                      Uri url = Uri.parse(AppUrls.rateUs);
                                      bool hasNet =
                                          await AppUtils.checkConnectivity();
                                      if (rating > 3) {
                                        if (hasNet) {
                                          if (!context.mounted) return;
                                          context.pop();
                                          await launchUrl(url);
                                        } else {
                                          if (!context.mounted) return;
                                          AppSnackBar.show(
                                            context: context,
                                            message:
                                                'PleaseCheck your Internet',
                                          );
                                        }
                                      } else {
                                        if (!context.mounted) return;
                                        context.pop();
                                        if (!context.mounted) return;
                                        AppRoutes.pushNamed(
                                          AppRoutes.webViewScreen,
                                          arguments: WebViewModel(
                                            link: AppUrls.feedBackURL,
                                            isGenerateUrl: true,
                                            webViewType: WebViewType.feedback,
                                            appbar: CustomAppBar(
                                              title: 'Feedback',
                                              leadingSvg: AssetImages.backArrow,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ).padHorizontal(50),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                    Divider(),
                    buildSettingTile(
                      image: AssetImages.deleteAccount,
                      title: 'Delete Account',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        AppRoutes.pushNamed(AppRoutes.deleteAccountScreen);
                      },
                    ),
                    Divider(),
                    buildSettingTile(
                      image: AssetImages.logOut,
                      title: 'Logout',
                      trailingIcon: AppIconWidget(
                        assetPath: AssetImages.iosForward,
                      ),
                      onTap: () {
                        AppDialogue.showPopup(
                          context: context,
                          content: LogoutPopUp(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ).pad(20),
        ),
      ),
    );
  }

  Widget buildSettingTile({
    required String image,
    required String title,
    required Widget trailingIcon,
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Row(
          children: [
            AppIconWidget(assetPath: image, color: AppColors.black),
            SizedBox(width: 20),
            AppText(text: title, fontSize: 15, fontWeight: FontWeight.w500),
            Spacer(),
            trailingIcon,
          ],
        ).pad(),
      ),
    );
  }
}
