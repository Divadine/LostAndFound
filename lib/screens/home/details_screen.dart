import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/bottomsheets/send_enquiry.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class LostItemsDetailsScreen extends StatefulWidget {
  const LostItemsDetailsScreen({super.key});

  @override
  State<LostItemsDetailsScreen> createState() => _LostItemsDetailsScreenState();
}

class _LostItemsDetailsScreenState extends State<LostItemsDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.primaryColor, toolbarHeight: 0),
      body: SingleChildScrollView(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Lost Items',
              leadingIconColor: AppColors.primaryColor,
              leadingSvg: AssetImages.backArrow,
              onLeadingTap: () {
                AppRoutes.pop();
              },
              titleColor: AppColors.primaryColor,
              centerTitle: true,
            ),

            AppContainer(
              widget: Column(
                spacing: 15,
                children: [
                  AppCachedNetworkImage(
                    imageUrl:
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    height: 150,
                  ),

                  Row(
                    spacing: 10,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: AppCachedNetworkImage(
                          width: 40,
                          // height: 40,
                          imageUrl:
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',

                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),

                      AppText(
                        text: 'DineshKumar',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),

                  AppContainer(
                    widget: Column(
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            AppText(
                              text: 'Item Type',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            AppText(
                              text: 'Watch',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            AppText(
                              text: 'Brand',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            AppText(
                              text: 'Fossil',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            AppText(
                              text: 'Model',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            AppText(
                              text: 'F5-5562',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            AppText(
                              text: 'Color',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            AppText(
                              text: 'Black',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  AppContainer(
                    widget: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: 'matches',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            text: '90% match',
                            //'${percentageMatch! }% match',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppContainer(
                    widget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: 'Land Mark',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text: 'Park',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Material',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text: 'Stainless Steel',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Special Marks',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text: 'Scratch on left side of the dial',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Location',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text: 'Chennai, Tamil Nadu, India',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Date',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text: '20 May 2026',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Description',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        AppText(
                          text:
                              'Black strap, round dial , silcer case. The dial has 3 small dals inside. The is a scratch on the left side.',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        Divider(),

                        AppText(
                          text: 'Voice Description',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        //AppText(text: 'Black strap, round dial , silcer case. The dial has 3 small dals inside. The is a scratch on the left side.',fontWeight: FontWeight.w400,fontSize: 12,),
                        Divider(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppButton(
              title: 'Send Enquiry',
              onTap: () {
                AppUiHelper.showBottomSheet(
                  showHandle: false,
                  showCloseIcon: false,
                  context: context,
                  child: SendEnquiry(

                  ),
                );
              },
              fontSize: 14,
              radius: BorderRadius.circular(10),
            ),
          ],
        ).pad(16),
      ),
    );
  }
}
