import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/bottomsheets/filter_screen.dart';
import 'package:lost_and_found/screens/home/available_matching_screen.dart';
import 'package:lost_and_found/screens/bottomsheets/submission_detail.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> details = [
    {'imageUrl': ''},
  ];
  HomeFilterState  filterState = const HomeFilterState();

  StreamController<HomeFilterState> filterStateStream = StreamController.broadcast();

  late TabController _tabController;
  int _selectedIndex = 0;


  void _emitFilter(HomeFilterState state) {
filterState = state;
filterStateStream.add(state);
  }
  void _clearFilter() {
    _emitFilter(HomeFilterState.cleared());
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _selectedIndex) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    filterStateStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              color: AppColors.primaryColor,
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
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.label,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 3,
                                  ),
                                  insets: EdgeInsets.symmetric(vertical: -10),
                                ),
                                padding: EdgeInsets.zero,
                                indicatorPadding: EdgeInsets.only(
                                  left: 1,
                                  right: 1,
                                ),
                                dividerColor: Colors.transparent,
                                labelColor: AppColors.primaryColor,
                                unselectedLabelColor: AppColors.grey,
                                tabs: [
                                  Tab(
                                    child: buildTabBarView(
                                      image: AssetImages.lostItemHome,
                                      title: "Lost Items",
                                      isSelected: _selectedIndex == 0,
                                    ),
                                  ),
                                  Tab(
                                    child: buildTabBarView(
                                      image: AssetImages.foundItem,
                                      title: "Found Items",
                                      isSelected: _selectedIndex == 1,
                                    ),
                                  ),
                                ],
                              ).pad(),
                            ),
                          ),

                          SizedBox(width: 5),
                          GestureDetector(
                            onTap: () async{

                              final filterData = await AppUiHelper.showBottomSheet(context: context, child: FilterScreen());

                              if(filterData == 'clear'){
                                _emitFilter(HomeFilterState.cleared());
                              }else if(filterData is Map){
                                _emitFilter(HomeFilterState(customRange: filterData['customRange'],filterApplied: true,selectedRange: filterData['range']));
                              }
                              // if(filterData != null){
                              //   setState(() {
                              //
                              //     filterApplied = true;
                              //     _selectedRange = filterData['range'];
                              //     _customRange = filterData['customRange'];
                              //   });
                              // }
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
                        controller: _tabController,
                        children: [
                          Column(
                            children: [

                              // if()
                              StreamBuilder(
                                stream: filterStateStream.stream,

                                builder: (context, asyncSnapshot) {
                                  final filterData = asyncSnapshot.data ?? HomeFilterState();

                                  if (!filterData.filterApplied) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    height: 35,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      //border: Border.all(color: AppColors.primaryColor),
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                  
                                        AppIconWidget(assetPath: AssetImages.filterTick),
                                        SizedBox(width: 15,),
                                        AppText(
                                          text: 'Showing results : ${filterData.selectedRange ?? " "}  ',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            _clearFilter();
                                            //AppRoutes.pop();},
                                          },
                                          child:AppIconWidget(assetPath: AssetImages.crossIcon,color: AppColors.black,),
                                        ),
                                      ],
                                    ).padHorizontal(16),
                                  ).padHorizontal();
                                }
                              ),
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
                              ).pad(),
                              ItemCard(
                                imgUrl:
                                    'https://getacregold.com/cdn/shop/articles/gold_bar_4100x.jpg?v=1639068933',
                                title: 'Gold',
                                location: "Coimbatore",
                                date: 'May 25 2026',
                                postId: 'LF2021',
                                onTap: () {
                                  AppUiHelper.showBottomSheet(
                                    context: context,
                                    child: ReceiveHandoverSheet(title: 'gold', isReceiver: false,),
                                  );
                                },
                                showPostId: true,
                              ).pad(),
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
                      GestureDetector(
                        onTap: () {
                          AppDialogue.showPopup(context: context, content: ChatSendRequest());
                          //AppRoutes.pushNamed(AppRoutes.loginScreen);
                        },
                        child: AppIconWidget(
                          assetPath: AssetImages.notification,
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  Widget buildTabBarView({
    required String image,
    required String title,
    required bool isSelected,
  }) {
    final color = isSelected ? AppColors.primaryColor : AppColors.grey;

    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIconWidget(
          assetPath: image,
          color: color, // requires AppIconWidget to support a color/tint param
        ),
        AppText(
          text: title,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ],
    );
  }
}


class HomeFilterState {
  final bool filterApplied;
  final String? selectedRange;
  final DateTimeRange? customRange;

  const HomeFilterState({
    this.filterApplied = false,
    this.selectedRange,
    this.customRange,
  });

  factory HomeFilterState.cleared() => const HomeFilterState();
}
