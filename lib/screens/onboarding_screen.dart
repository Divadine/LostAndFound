import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/bottomsheet_handover.dart';
import 'package:lost_and_found/shared_widgets/homeSlider.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import '../utils/app_images.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  int presentIndex = 0;
  String? selectedReason;
  PageController pageController = PageController();

  TextEditingController reasonController = TextEditingController();
  List<String> items = [
    'Item found',
    'Post Created by Mistake',
    'Duplicate Post',
    'Privacy Concern',
    'Item no longer available',
    'Others',
  ];

  List<onBoardModel> screenContents = [
    onBoardModel(
      image: AssetImages.onboard_1,
      title: 'Lost Something ?',
      subTitle: 'Find it Fast ',
      description:
          'Search lost items posted by  People nearby using map, categories and photos',
    ),
    onBoardModel(
      image: AssetImages.onboard_2,
      title: 'Found Something ?',
      subTitle: 'Post it Now.',
      description:
          'Take a photo, add location and post the item. Help the rightful  owner get it back',
    ),
    onBoardModel(
      image: AssetImages.onboard_3,
      title: 'Hand Over Safely',
      subTitle: 'Police Station',
      description:
          'Can’t identify the rightful owner?  Hand over the found item to a nearby Police station ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: SafeArea(
        child: Column(
          spacing: 20,
          children: [
            Container(
              height:MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(),
              child: PageView.builder(
                controller: pageController,
                itemCount: screenContents.length,
                onPageChanged: (value) {
                  setState(() {
                    presentIndex = value;
                  });
                },
                itemBuilder: (context, index) {
                  final model = screenContents[index];
                  return Stack(
                    children: [
                      Column(
                        spacing: 10,
                        crossAxisAlignment: .center,
                        mainAxisAlignment: .center,
                        children: [
                          Flexible(
                            child: SizedBox(
                              height: 350,
                              child: AppIconWidget(
                                assetPath: model.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          SizedBox(height: 40),
                          AppText(
                            text: model.title,
                            fontSize: 24,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          AppText(
                            text: model.subTitle,
                            fontSize: 28,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            text: model.description,
                            fontSize: 16,
                            color: AppColors.grey,
                            textAlign: .center,
                            fontWeight: FontWeight.w400,
                          ).padHorizontal(30),
                        ],
                      ),

                      if (presentIndex < 2)
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pageController.animateToPage(
                                  presentIndex + 2,
                                  duration: Duration(milliseconds: 2),
                                  curve: Curves.easeOut,
                                );
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.grey.withAlpha(150),
                              ),
                              child: AppText(
                                text: 'skip',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.white,
                              ),
                            ).pad(16),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (dots) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: presentIndex == dots ? 10 : 10,
                  decoration: BoxDecoration(
                    color: presentIndex == dots
                        ? AppColors.primaryColor
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            SizedBox(height: 15),

            // card
            // GestureDetector(
            //   onTap: () {
            //     AppDialogue.showPopup(
            //       context: context,
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           AppIconWidget(assetPath: AssetImages.hazards),
            //           SizedBox(height: 7),
            //           AppText(
            //             text: 'Profile Report Limit Reached',
            //             fontWeight: FontWeight.w500,
            //             fontSize: 18,
            //           ),
            //           SizedBox(height: 7),
            //           AppText(
            //             text:
            //                 'You’ve reached the maximum number of reports allowed for row. As a precaution has been temporally restricted. If you believe is a mistake. Please submit a request for review.',
            //             fontSize: 12,
            //             fontWeight: FontWeight.w400,
            //             textAlign: .center,
            //           ).padHorizontal(20),
            //           SizedBox(height: 15),
            //           Row(
            //             spacing: 10,
            //             children: [
            //               Expanded(
            //                 child: AppButton(
            //                   title: ' Cancel',
            //                   onTap: () {
            //                     //Navigator.pop(context);
            //                   },
            //                   fontSize: 14,
            //                   bgColor: Colors.transparent,
            //                   border: Border.all(color: AppColors.grey),
            //                   textColor: AppColors.grey,
            //                   radius: BorderRadius.circular(20),
            //                 ),
            //               ),
            //               Expanded(
            //                 child: AppButton(
            //                   title: 'Justify',
            //                   onTap: () {},
            //                   fontSize: 14,
            //                   bgColor: AppColors.primaryColor,
            //                   textColor: AppColors.white,
            //                   radius: BorderRadius.circular(20),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            //   child: ItemCard(
            //     imgUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
            //     title: 'Fossil Watch',
            //     location: 'Coimbatore, TamilNadu',
            //     date: '20 May 2026',
            //   ),
            // ),
            // GestureDetector(
            //   onTap: () {
            //     AppDialogue.showPopup(
            //       context: context,
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           AppIconWidget(assetPath: AssetImages.submit),
            //           SizedBox(height: 7),
            //           AppText(
            //             text: 'Submission Received',
            //             fontWeight: FontWeight.w500,
            //             fontSize: 18,
            //           ),
            //           SizedBox(height: 7),
            //           AppText(
            //             text:
            //                 'We’ve received your request and it is under review by our team.  \n We’ll Contact you via email/phone once a verification process is completed.',
            //             fontSize: 12,
            //             fontWeight: FontWeight.w400,
            //             textAlign: .center,
            //             color: AppColors.grey,
            //           ).padHorizontal(20),
            //           SizedBox(height: 15),
            //           AppButton(
            //             title: 'Done',
            //             onTap: () {},
            //             fontSize: 14,
            //             bgColor: AppColors.primaryColor,
            //             textColor: AppColors.white,
            //             radius: BorderRadius.circular(20),
            //           ).padHorizontal(25),
            //         ],
            //       ),
            //     );
            //   },
            //   child: ItemCard(
            //     imgUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQTJKOKkJLZ5uIcX3bGfeQQrWws2upsGf-BCVJFaGr7PQ&s=10',
            //     title: 'Apple Watch',
            //     location: 'Ganapathy, TamilNadu',
            //     date: '21 June 2026',
            //     foundCount: 7,
            //   ),
            // ),
            // GestureDetector(
            //   onTap: () {
            //     AppDialogue.showPopup(
            //       context: context,
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           AppIconWidget(assetPath: AssetImages.tickmark),
            //           SizedBox(height: 7),
            //           AppText(
            //             text: 'Already Submitted',
            //             fontWeight: FontWeight.w500,
            //             fontSize: 18,
            //           ),
            //           SizedBox(height: 7),
            //           AppText(
            //             text:
            //                 'You have already submitted a request. Our teams is currently reviewing it. Thanks for you patience.',
            //             fontSize: 12,
            //             fontWeight: FontWeight.w400,
            //             textAlign: .center,
            //             color: AppColors.grey,
            //           ).padHorizontal(20),
            //         ],
            //       ),
            //     );
            //   },
            //   child: ItemCard(
            //     imgUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSUmp0urh_oV5g1rZZI_TYNwt55bs4mJpN_OOt9SnMUgQ&s=10',
            //     title: 'Fast track',
            //     location: 'ooty , TamilNadu',
            //     date: '07 July 2026',
            //     percentageMatch: 75,
            //     profileName: 'Dinesh',
            //     profileUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //   ),
            // ),

            // GestureDetector(
            //   onTap: (){
            //     AppDialogue.showPopup(
            //       context: context,
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //
            //           AppText(
            //             text: 'Disclaimer',
            //             fontWeight: FontWeight.w500,
            //             fontSize: 18,
            //           ),
            //           SizedBox(height: 7),
            //           AppText(
            //             text:
            //             'The information provided in this Lost & Found application is intended to help users report, search, and recover lost or found items. While we strive to keep the information accurate and up to date, we do not guarantee the authenticity ownership, or availability of any item listed. This pp is a platform that connects users and does not involve in the exchange or return of items. Users are advised to take necessary precautions  while sharing personal information or meeting others. Lost & Found is not responsible for any loss, damage, disputes, or consequences resulting from the use of this application.',
            //             fontSize: 14,
            //             fontWeight: FontWeight.w400,
            //             textAlign: .center,
            //             color: AppColors.black,
            //           ),
            //           SizedBox(height: 15,),
            //           AppButton(
            //             title: 'Ok',
            //             onTap: () {},
            //             fontSize: 14,
            //             bgColor: AppColors.primaryColor,
            //             textColor: AppColors.white,
            //             radius: BorderRadius.circular(7),
            //           ).padHorizontal(80),
            //         ],
            //       ),
            //     );
            //
            //   },
            //   child: ItemCard(
            //     imgUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSUmp0urh_oV5g1rZZI_TYNwt55bs4mJpN_OOt9SnMUgQ&s=10',
            //     title: 'Fast track',
            //     location: 'ooty , TamilNadu',
            //     date: '07 July 2026',
            //     //percentageMatch: 75,
            //     //profileName: 'Dinesh',
            //     //profileUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //     enquiredProfile: [
            //       'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //       'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //       'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //       'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //     ],
            //     newMessageCount: '7',
            //   ),
            // ),

            // GestureDetector(
            //   onTap: (){
            //     AppDialogue.showPopup(
            //       context: context,
            //       content: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           AppIconWidget(assetPath: AssetImages.logout),
            //           SizedBox(height: 7),
            //           AppText(
            //             text: 'Do you really want to log out?',
            //             fontWeight: FontWeight.w500,
            //             fontSize: 18,
            //           ),
            //           SizedBox(height: 7),
            //           AppText(
            //             text:'Your journey isn’t over yet ! but it’s ok you can login anytime you want',
            //             fontSize: 12,
            //             fontWeight: FontWeight.w400,
            //             textAlign: .center,
            //             color: AppColors.grey,
            //           ).padHorizontal(20),
            //
            //           SizedBox(height: 10,),
            //           Row(
            //             spacing: 10,
            //             children: [
            //               Expanded(
            //                 child: AppButton(
            //                   title: 'Yes',
            //                   onTap: () {
            //                     AppRoutes.pop();
            //                   },
            //                   bgColor:AppColors.grey.withAlpha(50),
            //
            //                   textColor:
            //                   AppColors.grey,
            //                   radius: BorderRadius.circular(
            //                     7,
            //                   ),
            //                 ),
            //               ),
            //               Expanded(
            //                 child: AppButton(
            //                   title: 'No',
            //                   onTap: () {
            //                     AppRoutes.pop();
            //                     AppDialogue.showPopup(
            //                       context: context,
            //                       content: Column(
            //                         mainAxisSize:
            //                         MainAxisSize.min,
            //                         children: [
            //                           CircleAvatar(
            //                             backgroundColor:
            //                             AppColors.red
            //                                 .withAlpha(
            //                               50,
            //                             ),
            //                             radius: 20,
            //                             child: AppIconWidget(
            //                               assetPath:
            //                               AssetImages
            //                                   .delete,
            //                             ),
            //                           ),
            //                           SizedBox(height: 7),
            //                           AppText(
            //                             text: 'Delete Post',
            //                             fontWeight:
            //                             FontWeight.w600,
            //                             fontSize: 16,
            //                           ),
            //                           SizedBox(height: 7),
            //                           AppText(
            //                             text:
            //                             'Are you sure you want to delete this lost item post ?',
            //                             fontSize: 14,
            //                             fontWeight:
            //                             FontWeight.w400,
            //                             textAlign: .center,
            //                           ).padHorizontal(20),
            //                           SizedBox(height: 15),
            //                           Row(
            //                             spacing: 10,
            //                             children: [
            //                               Expanded(
            //                                 child: AppButton(
            //                                   title:
            //                                   'Cancel',
            //                                   onTap: () {
            //                                     //Navigator.pop(context);
            //                                   },
            //                                   fontSize: 14,
            //                                   bgColor: Colors
            //                                       .transparent,
            //                                   border: Border.all(
            //                                     color: AppColors
            //                                         .black,
            //                                   ),
            //                                   textColor:
            //                                   AppColors
            //                                       .black,
            //                                   radius:
            //                                   BorderRadius.circular(
            //                                     7,
            //                                   ),
            //                                 ),
            //                               ),
            //                               Expanded(
            //                                 child: AppButton(
            //                                   title:
            //                                   'Delete Post',
            //                                   onTap: () {},
            //                                   fontSize: 14,
            //                                   bgColor:
            //                                   AppColors
            //                                       .red,
            //                                   textColor:
            //                                   AppColors
            //                                       .white,
            //                                   radius:
            //                                   BorderRadius.circular(
            //                                     7,
            //                                   ),
            //                                 ),
            //                               ),
            //                             ],
            //                           ),
            //                         ],
            //                       ),
            //                     );
            //                   },
            //                   textColor: AppColors.white,
            //                   bgColor:
            //                   AppColors.primaryColor,
            //                   radius: BorderRadius.circular(
            //                     7,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //
            //
            //         ],
            //       ),
            //     );
            //
            //   },
            //   child: ItemCard(
            //     imgUrl:
            //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSUmp0urh_oV5g1rZZI_TYNwt55bs4mJpN_OOt9SnMUgQ&s=10',
            //     title: 'Fast track',
            //     location: 'ooty , TamilNadu',
            //     date: '07 July 2026',
            //     isFromEnquiry: true,
            //     // percentageMatch: 75,
            //     // profileName: 'Dinesh',
            //     // profileUrl:
            //     // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //   ),
            // ),

            // AppContainer(
            //   widget: Column(
            //     spacing: 10,
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         spacing: 10,
            //         mainAxisAlignment: MainAxisAlignment.start,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           CircleAvatar(
            //             radius: 20,
            //             child: AppCachedNetworkImage(
            //               borderRadius: BorderRadius.circular(20),
            //               imageUrl:
            //                   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-dXyMpH81pBa6x9qvetSA8LqNx4mnigmw0eRp8KFWqBP9nrfmDOdkX2y3&s=10',
            //             ),
            //           ),
            //
            //           Flexible(
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 AppText(
            //                   text: 'Dineshkumar',
            //                   fontWeight: FontWeight.w600,
            //                   fontSize: 12,
            //                   color: AppColors.primaryColor,
            //                 ),
            //                 SizedBox(height: 2),
            //
            //                 AppText(
            //                   text: 'Enuired 2 hous ago',
            //                   fontWeight: FontWeight.w600,
            //                   fontSize: 10,
            //                   color: AppColors.grey,
            //                 ),
            //
            //                 SizedBox(height: 5),
            //                 AppText(
            //                   text:
            //                       'I lost my watch near the park on 20 May evening',
            //                   fontWeight: FontWeight.w400,
            //                   fontSize: 12,
            //                   color: AppColors.black,
            //                 ),
            //               ],
            //             ),
            //           ),
            //
            //           Container(
            //             padding: EdgeInsets.all(5),
            //             decoration: BoxDecoration(
            //               color: AppColors.purple.withAlpha(30),
            //               borderRadius: BorderRadius.circular(15),
            //             ),
            //             child: AppText(
            //               text: '95% match',
            //               fontWeight: FontWeight.w500,
            //               fontSize: 10,
            //               color: AppColors.purple,
            //             ),
            //           ),
            //         ],
            //       ),
            //
            //       Row(
            //         spacing: 10,
            //         children: [
            //           Expanded(
            //             child: AppButton(
            //               title: 'Message',
            //               fontSize: 14,
            //               height: 30,
            //               onTap: () {
            //                 AppDialogue.showPopup(
            //                   context: context,
            //                   content: StatefulBuilder(
            //                     builder: (context, setState) {
            //                       return SingleChildScrollView(
            //                         child: Column(
            //                           mainAxisSize: MainAxisSize.min,
            //                           crossAxisAlignment:
            //                               CrossAxisAlignment.start,
            //                           mainAxisAlignment: .start,
            //                           children: [
            //                             AppText(
            //                               text: 'Delete Post',
            //                               fontSize: 16,
            //                               fontWeight: FontWeight.w600,
            //                             ),
            //                             SizedBox(height: 10),
            //                             AppText(
            //                               text:
            //                                   'Why are you deleting this post ?',
            //                               fontWeight: FontWeight.w500,
            //                               fontSize: 14,
            //                             ),
            //
            //                             ...items.map((item) {
            //                               return Padding(
            //                                 padding: const EdgeInsets.all(
            //                                   8.0,
            //                                 ),
            //                                 child: GestureDetector(
            //                                   onTap: () {
            //                                     setState(() {
            //                                       selectedReason = item;
            //                                     });
            //                                   },
            //                                   child: Row(
            //                                     spacing: 5,
            //                                     children: [
            //                                       SizedBox(
            //                                         height: 20,
            //                                         width: 20,
            //                                         child: Radio<String>(
            //                                           hoverColor: AppColors
            //                                               .primaryColor,
            //                                           groupValue:
            //                                               selectedReason,
            //                                           activeColor: AppColors
            //                                               .primaryColor,
            //                                           onChanged: (value) {
            //                                             setState(() {
            //                                               selectedReason =
            //                                                   value;
            //                                             });
            //                                           },
            //                                           value: item,
            //                                         ),
            //                                       ),
            //                                       Expanded(
            //                                         child: AppText(
            //                                           text: item,
            //                                           fontSize: 14,
            //                                           color: AppColors.black,
            //                                         ),
            //                                       ),
            //                                     ],
            //                                   ),
            //                                 ),
            //                               );
            //                             }),
            //
            //                             if (selectedReason == 'Others') ...[
            //                               AppText(
            //                                 text: 'Please tell us the reason',
            //                                 fontWeight: FontWeight.w400,
            //                                 fontSize: 14,
            //                                 textAlign: TextAlign.start,
            //                               ),
            //
            //                               SizedBox(height: 10),
            //                               AppTextField(
            //                                 hintText: 'Write a reason',
            //                                 textController: reasonController,
            //                                 onChange: (v) {},
            //                                 onSubmit: (v) {},
            //                                 maxLines: 4,
            //                               ),
            //                             ],
            //
            //                             SizedBox(height: 8),
            //                             Row(
            //                               spacing: 10,
            //                               children: [
            //                                 Expanded(
            //                                   child: AppButton(
            //                                     title: 'cancel',
            //                                     onTap: () {
            //                                       AppRoutes.pop();
            //                                     },
            //                                     bgColor: Colors.transparent,
            //                                     border: Border.all(
            //                                       color:
            //                                           AppColors.primaryColor,
            //                                     ),
            //                                     textColor:
            //                                         AppColors.primaryColor,
            //                                     radius: BorderRadius.circular(
            //                                       7,
            //                                     ),
            //                                   ),
            //                                 ),
            //                                 Expanded(
            //                                   child: AppButton(
            //                                     title: 'Next',
            //                                     onTap: () {
            //                                       AppRoutes.pop();
            //                                       AppDialogue.showPopup(
            //                                         context: context,
            //                                         content: Column(
            //                                           mainAxisSize:
            //                                               MainAxisSize.min,
            //                                           children: [
            //                                             CircleAvatar(
            //                                               backgroundColor:
            //                                                   AppColors.red
            //                                                       .withAlpha(
            //                                                         50,
            //                                                       ),
            //                                               radius: 20,
            //                                               child: AppIconWidget(
            //                                                 assetPath:
            //                                                     AssetImages
            //                                                         .delete,
            //                                               ),
            //                                             ),
            //                                             SizedBox(height: 7),
            //                                             AppText(
            //                                               text: 'Delete Post',
            //                                               fontWeight:
            //                                                   FontWeight.w600,
            //                                               fontSize: 16,
            //                                             ),
            //                                             SizedBox(height: 7),
            //                                             AppText(
            //                                               text:
            //                                                   'Are you sure you want to delete this lost item post ?',
            //                                               fontSize: 14,
            //                                               fontWeight:
            //                                                   FontWeight.w400,
            //                                               textAlign: .center,
            //                                             ).padHorizontal(20),
            //                                             SizedBox(height: 15),
            //                                             Row(
            //                                               spacing: 10,
            //                                               children: [
            //                                                 Expanded(
            //                                                   child: AppButton(
            //                                                     title:
            //                                                         'Cancel',
            //                                                     onTap: () {
            //                                                       //Navigator.pop(context);
            //                                                     },
            //                                                     fontSize: 14,
            //                                                     bgColor: Colors
            //                                                         .transparent,
            //                                                     border: Border.all(
            //                                                       color: AppColors
            //                                                           .black,
            //                                                     ),
            //                                                     textColor:
            //                                                         AppColors
            //                                                             .black,
            //                                                     radius:
            //                                                         BorderRadius.circular(
            //                                                           7,
            //                                                         ),
            //                                                   ),
            //                                                 ),
            //                                                 Expanded(
            //                                                   child: AppButton(
            //                                                     title:
            //                                                         'Delete Post',
            //                                                     onTap: () {},
            //                                                     fontSize: 14,
            //                                                     bgColor:
            //                                                         AppColors
            //                                                             .red,
            //                                                     textColor:
            //                                                         AppColors
            //                                                             .white,
            //                                                     radius:
            //                                                         BorderRadius.circular(
            //                                                           7,
            //                                                         ),
            //                                                   ),
            //                                                 ),
            //                                               ],
            //                                             ),
            //                                           ],
            //                                         ),
            //                                       );
            //                                     },
            //                                     textColor: AppColors.white,
            //                                     bgColor:
            //                                         AppColors.primaryColor,
            //                                     radius: BorderRadius.circular(
            //                                       7,
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ],
            //                             ),
            //                           ],
            //                         ),
            //                       );
            //                     },
            //                   ),
            //                 );
            //               },
            //               border: Border.all(color: AppColors.primaryColor),
            //               radius: BorderRadius.circular(15),
            //               prefixIcon: AssetImages.message_icon,
            //               bgColor: Colors.transparent,
            //               textColor: AppColors.primaryColor,
            //             ),
            //           ),
            //
            //           Expanded(
            //             child: AppButton(
            //               title: 'View Details',
            //               height: 30,
            //               fontSize: 14,
            //               onTap: () {
            //                 AppUiHelper.showBottomSheet(
            //                   maxHeightFactor: 0.58,
            //                   context: context,
            //                   child: Column(
            //                     spacing: 10,
            //                     children: [
            //                       AppText(
            //                         text:
            //                             'How would you like to hand Over?',
            //                         fontWeight: FontWeight.w600,
            //                         fontSize: 14,
            //                       ),
            //                       SizedBox(height: 10),
            //                       AppText(
            //                         text: 'Choose one option to continue',
            //                         fontSize: 12,
            //                         fontWeight: FontWeight.w400,
            //                       ),
            //                       BottomSheetHandOver(
            //                         title: 'name',
            //                         subtitle: 'address',
            //                         icon: Icons.person,
            //                         onTap: () {},
            //                       ),
            //                       BottomSheetHandOver(
            //                         title: '',
            //                         subtitle: '',
            //                         icon: Icons.policy,
            //                         onTap: () {},
            //                       ),
            //                       BottomSheetHandOver(
            //                         title: '',
            //                         subtitle: '',
            //                         icon: Icons.man,
            //                         onTap: () {},
            //                       ),
            //                       SizedBox(height: 7,),
            //                       AppButton(
            //                         title: 'Continue',
            //                         onTap: () {},
            //                         fontSize: 14,
            //                         bgColor: AppColors.primaryColor,
            //                         textColor: AppColors.white,
            //                         radius: BorderRadius.circular(7),
            //                       ),
            //                     ],
            //                   ),
            //                 );
            //               },
            //               border: Border.all(color: AppColors.primaryColor),
            //               radius: BorderRadius.circular(15),
            //               bgColor: AppColors.primaryColor,
            //               textColor: AppColors.white,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ).pad(),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          child: AppButton(
            height: 45,
            title: presentIndex == screenContents.length - 1
                ? 'Get Start'
                : 'Next',
            onTap: () {
              if (presentIndex < screenContents.length - 1) {
                pageController.animateToPage(
                  presentIndex + 1,
                  duration: Duration(milliseconds: 2),
                  curve: Curves.easeOut,
                );
              } else {
                AppPreferences.setIsOnboarded(true);
                AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
              }
            },
          ),
        ),
      ),
    );
  }
}

class onBoardModel {
  final String image;
  final String title;
  final String subTitle;
  final String description;

  onBoardModel({
    required this.image,
    required this.title,
    required this.subTitle,
    required this.description,
  });
}
