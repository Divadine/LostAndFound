import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/available_matching_screen.dart';
import 'package:lost_and_found/screens/received_details.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/bottomsheet_handover.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/shared_widgets/sucess_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> details = [
    {'imageUrl': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: AppColors.primaryColor,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                height: double.infinity,
                width: double.infinity,
                color: AppColors.primaryColor,
              ),

              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "Lost & Found",
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),

                        AppIconWidget(assetPath: AssetImages.notification),
                      ],
                    ),

                    AppText(
                      text: "Helping you reunite with what\nmatters.",
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 30,
                right: 0,
                child: AppIconWidget(assetPath: AssetImages.homeBox),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.all(12),
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),

                                child: TabBar(
                                  padding: EdgeInsets.zero,
                                  indicatorPadding: EdgeInsets.only(
                                    left: 18,
                                    right: 18,
                                  ),

                                  indicator: UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  dividerColor: Colors.transparent,

                                  labelColor: AppColors.primaryColor,
                                  unselectedLabelColor: Colors.grey,

                                  tabs: [
                                    Tab(
                                      child: buildTabBarView(
                                        image: AssetImages.lostItem,
                                        title: "Lost Items",
                                      ),
                                    ),

                                    Tab(
                                      child: buildTabBarView(
                                        image: AssetImages.foundItem,
                                        title: "Found Items",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: 3),
                            GestureDetector(
                              onTap: () {
                                AppDialogue.showPopup(
                                  context: context,
                                  content: SucessCard(
                                    name: 'prakash',
                                    location: 'coimbatore ',
                                    onTap: () {},
                                  ),
                                );
                              },
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AppIconWidget(
                                    assetPath: AssetImages.filter,
                                    fit: BoxFit.cover,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Column(
                              children: [
                                ItemCard(
                                  imgUrl:
                                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                                  title: 'Fossil Watch',
                                  location: 'Coimbatore, TamilNadu',
                                  date: '20 May 2026',
                                  postId: 'LF2378',
                                  foundCount: 20,
                                  time: "Just now",
                                  onTap: () {
                                    AppRoutes.pushNamed(
                                      AppRoutes.availableMatchingScreen,
                                      arguments: AvailableScreenModel(
                                        foundCount: 8,
                                        isReceived: false,
                                      ),
                                    );
                                  },
                                  showPostId: true,
                                ),
                                ItemCard(
                                  imgUrl:
                                      'https://getacregold.com/cdn/shop/articles/gold_bar_4100x.jpg?v=1639068933',
                                  title: 'Gold',
                                  location: "Coimbatore",
                                  date: 'May 25 2026',
                                  postId: 'LF2021',
                                  onTap: (){
                                    AppUiHelper.showBottomSheet(
                                      context: context,
                                      child: ReceiveHandoverSheet(title: 'gold',),
                                    );
                                  },
                                  showPostId: true,
                                ),
                              ],
                            ),

                            //foundItems
                            ListView.builder(
                              itemCount: 2,
                              itemBuilder: (context, index) {
                                return ItemCard(
                                  imgUrl:
                                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                                  title: 'Fossil Watch',
                                  location: 'Coimbatore, TamilNadu',
                                  date: '20 May 2026',
                                  postId: 'LF2378',
                                  time: "Just now",
                                  newMessageCount: "5",
                                  enquiredProfile: [
                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                                  ],
                                  onTap: () {
                                    AppRoutes.pushNamed(
                                      AppRoutes.enquiryListScreen,
                                    );
                                  },
                                  showPostId: true,
                                ).pad();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTabBarView({required String image, required String title}) {
    return Row(
      spacing: 7,
      //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIconWidget(assetPath: image),

        AppText(text: title, fontSize: 14, fontWeight: FontWeight.w600),
      ],
    );
  }
}
