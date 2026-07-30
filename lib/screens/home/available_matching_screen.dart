import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import '../authentication/role_chosen_screen.dart';

class AvailableMatchingScreen extends StatefulWidget {
  final AvailableScreenModel? availableScreenModel;

  const AvailableMatchingScreen({super.key, this.availableScreenModel});

  @override
  State<AvailableMatchingScreen> createState() =>
      _AvailableMatchingScreenState();
}

class _AvailableMatchingScreenState extends State<AvailableMatchingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title:
            'Available Matching item - ${widget.availableScreenModel?.foundCount} founded',
        leadingSvg: AssetImages.backArrow,
        titleColor: AppColors.primaryColor,
        leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () {
          AppRoutes.pop();
        },
      ),

      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 10,
          children: [
            ItemCard(
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
            AppContainer(
              widget: AppText(
                text:
                    'Matching Items(${widget.availableScreenModel?.foundCount})',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                textAlign: TextAlign.center,
              ).pad(12),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  return ItemCard(
                    imageWidth: 170,
                    isFromEnquiry: true,
                    imgUrl:
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',

                    title: 'Fossil Watch',
                    location: 'Coimbatore, TamilNadu',
                    date: '20 May 2026',
                    postId: '',
                    onTap: () {},
                    percentageMatch: 100,
                    showPostId: false,
                    profileUrl:
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                    profileName: 'diva',
                  ).padBottom(10);
                },
              ),
            ),
          ],
        ).pad(),
      ),

      bottomNavigationBar: widget.availableScreenModel?.isReceived == true
          ? SafeArea(
              child: SucessCard(
                name: 'Dinesh',
                location: '22 May 2026',
                onTap: () {
                  AppUiHelper.showBottomSheet(
                    context: context,
                    child: ReceivedDetails(isReceivedFromPolice: false, isReceivedFromFounder: false, isReceivedFromOthers: false,),
                  );
                },
              ).pad(),
            )
          : SafeArea(
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
                      onTap: () {
            
                        AppUiHelper.showBottomSheet(
                          context: context,
                          child: ReceiveHandoverSheet(title: '',),
                        );
                      },
                      radius: BorderRadius.circular(14),
                    ),
                  ],
                ),
              ).pad(),
          ),
    );
  }
}

class AvailableScreenModel {
  final int? foundCount;
  final bool? isReceived;

  AvailableScreenModel({this.foundCount, this.isReceived});
}
