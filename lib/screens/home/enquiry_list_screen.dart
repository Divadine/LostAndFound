import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "Enquires",
        centerTitle: true,
        leadingSvg: AssetImages.backArrow,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: .start,
          spacing: 10,
          children: [
            ItemCard(
              imageWidth: 170,
              isFromEnquiry: true,
              imgUrl:
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
              title: 'Fossil Watch',
              location: 'Coimbatore, TamilNadu',
              date: '20 May 2026',
              postId: 'LF2378',

              bg: AppColors.lightBlue_2,

              //foundCount: 20,
              //time: "Just now",
              onTap: () {
                AppRoutes.pushNamed(AppRoutes.lostItemsDetailsScreen);
              },
              showPostId: true,
            ),
            Row(
              children: [
                AppText(
                  text: 'Enquires Received',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ).pad(12),
              ],
            ),

            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  return buildEnquiryCard(
                    context: context,
                    profileImage:
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
                    name: 'Dineshkumar',
                    time: '2 hours ago',
                    matchPercentage: '95%',
                    description:
                        'I lost my watch near the park on 20 May evening',
                    messageOnTap: () {},
                    detailOnTap: () {},
                  );
                },
              ),
            ),
          ],
        ).pad(),
      ),

      bottomNavigationBar: SafeArea(
        child: AppContainer(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              AppButton(
                title: 'Receive',
                onTap: () {},
                radius: BorderRadius.circular(14),
              ),
            ],
          ),
        ).pad(),
      ),
    );
  }

  Widget buildEnquiryCard({
    required BuildContext context,
    required String profileImage,
    required String name,
    required String time,
    required String matchPercentage,
    required String description,
    required void Function() messageOnTap,
    required void Function() detailOnTap,
  }) {
    return AppContainer(
      widget: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                child: AppCachedNetworkImage(
                  borderRadius: BorderRadius.circular(20),
                  imageUrl: profileImage,
                ),
              ),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: name,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(height: 2),

                    AppText(
                      text: 'Enquired ${time}',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: AppColors.grey,
                    ),

                    SizedBox(height: 5),
                    AppText(
                      text: description,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withAlpha(30),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AppText(
                  text: '$matchPercentage match',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),

          Row(
            spacing: 10,
            children: [
              Expanded(
                child: AppButton(
                  title: 'Message',
                  fontSize: 14,
                  height: 30,
                  onTap: messageOnTap,
                  border: Border.all(color: AppColors.primaryColor),
                  radius: BorderRadius.circular(10),
                  prefixIcon: AssetImages.message_icon,
                  bgColor: Colors.transparent,
                  textColor: AppColors.primaryColor,
                ),
              ),

              Expanded(
                child: AppButton(
                  title: 'View Details',
                  height: 30,
                  fontSize: 14,
                  onTap: detailOnTap,
                  border: Border.all(color: AppColors.primaryColor),
                  radius: BorderRadius.circular(10),
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ).pad(),
    ).pad();
  }
}
