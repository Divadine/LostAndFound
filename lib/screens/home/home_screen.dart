import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/posts_model/post_list_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
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
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  List<Map<String, dynamic>> details = [
    {'imageUrl': ''},
  ];

  final Map<int, int> matchingCounts = {};

  HomeFilterState  filterState = const HomeFilterState();

  StreamController<HomeFilterState> filterStateStream = StreamController.broadcast();

  late TabController _tabController;
  int _selectedIndex = 0;

  // Lost posts (post_type: 0)
  List<PostModel> lostPosts = [];
  bool isLoadingLost = true;
  String? lostErrorMessage;

  // Found posts (post_type: 1)
  List<PostModel> foundPosts = [];
  bool isLoadingFound = true;
  String? foundErrorMessage;

  void _emitFilter(HomeFilterState state) {
filterState = state;
filterStateStream.add(state);
  }

  void _clearFilter() {
    _emitFilter(HomeFilterState.cleared());
  }


  Future<void> _fetchMatchCounts(List<PostModel> posts) async {
    for (final post in posts) {
      final response = await authController.getPostMatches(postId: post.id);
      if (!mounted) return;
      if (response.isSuccess && response.data != null && response.data!.matchingCount > 0) {
        setState(() => matchingCounts[post.id] = response.data!.matchingCount);
      }
    }
  }

  String? _mapRangeToApiFilter(String? label) {
    switch (label) {
      case 'Today': return 'today';
      case 'Last 7 Days': return 'last_7_days';
      case 'Last 30 Days': return 'last_30_days';
      case 'Last 3 Months': return 'last_3_months';
      case 'Last Year': return 'last_year';
      case 'Custom Range': return 'custom';
      default: return null;
    }
  }

  void _openAvailableMatching(PostModel post) {
    AppRoutes.pushNamed(
      AppRoutes.availableMatchingScreen,
      arguments: {
        'postId': post.id,
        'imgUrl': post.images.isNotEmpty ? post.images.first : '',
        'title': post.name,
        'location': post.location,
        'date': _formatDate(post.postDate),
        'postUid': post.postUid,
        'foundCount': matchingCounts[post.id] ?? 0,
        'isReceived': false,
      },
    );
  }

  Future<void> _fetchLostPosts() async {
    setState(() {
      isLoadingLost = true;
      lostErrorMessage = null;
    });

    final userId = await AppPreferences.getUserId();

    final response = filterState.filterApplied
        ? await authController.filterPosts(
      userId: userId ?? 0,
      postType: 0,
      dateFilter: filterState.dateFilter,
      startDate: filterState.customRange != null
          ? DateFormat('yyyy-MM-dd').format(filterState.customRange!.start)
          : null,
      endDate: filterState.customRange != null
          ? DateFormat('yyyy-MM-dd').format(filterState.customRange!.end)
          : null,
    )
        : await authController.getPost(userId: userId ?? 0, postType: 0);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        lostPosts = response.data!.posts;
        isLoadingLost = false;
      });
      _fetchMatchCounts(lostPosts);
    } else {
      setState(() {
        lostErrorMessage = response.currentState == CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : (response.message.isNotEmpty ? response.message : 'Failed to load posts');
        isLoadingLost = false;
      });
    }
  }

  Future<void> _fetchFoundPosts() async {
    setState(() {
      isLoadingFound = true;
      foundErrorMessage = null;
    });

    final userId = await AppPreferences.getUserId();

    final response = filterState.filterApplied
        ? await authController.filterPosts(
      userId: userId ?? 0,
      postType: 1,
      dateFilter: filterState.dateFilter,
      //_mapRangeToApiFilter(filterState.selectedRange),
      startDate: filterState.customRange != null
          ? DateFormat('yyyy-MM-dd').format(filterState.customRange!.start)
          : null,
      endDate: filterState.customRange != null
          ? DateFormat('yyyy-MM-dd').format(filterState.customRange!.end)
          : null,
    )
        : await authController.getPost(userId: userId ?? 0, postType: 1);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        foundPosts = response.data!.posts;
        isLoadingFound = false;
      });
    } else {
      setState(() {
        foundErrorMessage = response.currentState == CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : (response.message.isNotEmpty ? response.message : 'Failed to load posts');
        isLoadingFound = false;
      });
    }
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

    _fetchLostPosts();
    _fetchFoundPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    filterStateStream.close();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
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
                            onTap: () async {
                              final filterData = await AppUiHelper.showBottomSheet(context: context, child: FilterScreen());

                              if (filterData == 'clear') {
                                _emitFilter(HomeFilterState.cleared());
                                _fetchLostPosts();
                                _fetchFoundPosts();
                              } else if (filterData is Map) {
                                _emitFilter(HomeFilterState(
                                  customRange: filterData['customRange'],
                                  filterApplied: true,
                                  selectedRange: filterData['range'],
                                  dateFilter: filterData['dateFilter'],
                                ));
                                _fetchLostPosts();
                                _fetchFoundPosts();
                              }
                            },
                            // onTap: () async{
                            //
                            //   final filterData = await AppUiHelper.showBottomSheet(context: context, child: FilterScreen());
                            //
                            //   if(filterData == 'clear'){
                            //     _emitFilter(HomeFilterState.cleared());
                            //   }else if(filterData is Map){
                            //     _emitFilter(HomeFilterState(customRange: filterData['customRange'],filterApplied: true,selectedRange: filterData['range']));
                            //   }
                            // },
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
                          _buildLostTab(),

                          _buildFoundTab(),


                          // StreamBuilder(
                          //   stream: filterStateStream.stream,
                          //
                          //   builder: (context, asyncSnapshot) {
                          //     final filterData = asyncSnapshot.data ?? HomeFilterState();
                          //
                          //     if (!filterData.filterApplied) {
                          //       return const SizedBox.shrink();
                          //     }
                          //     return Container(
                          //       height: 35,
                          //       width: double.infinity,
                          //       decoration: BoxDecoration(
                          //         //border: Border.all(color: AppColors.primaryColor),
                          //         color: AppColors.lightBlue,
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       child: Row(
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //         children: [
                          //
                          //           AppIconWidget(assetPath: AssetImages.filterTick),
                          //           SizedBox(width: 15,),
                          //           AppText(
                          //             text: 'Showing results : ${filterData.selectedRange ?? " "}  ',
                          //             fontSize: 12,
                          //             fontWeight: FontWeight.w500,
                          //           ),
                          //           Spacer(),
                          //           GestureDetector(
                          //             onTap: () {
                          //               _clearFilter();
                          //               AppRoutes.pop();
                          //               // },
                          //             },
                          //             child:AppIconWidget(assetPath: AssetImages.crossIcon,color: AppColors.black,),
                          //           ),
                          //         ],
                          //       ).padHorizontal(16),
                          //     ).padHorizontal();
                          //   }
                          // ),
                          // foundItems
                          // ListView.builder(
                          //   itemCount: 2,
                          //   itemBuilder: (context, index) {
                          //     return ItemCard(
                          //       imgUrl:
                          //           'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                          //       title: 'Fossil Watch',
                          //       location: 'Coimbatore, TamilNadu',
                          //       date: '20 May 2026',
                          //       postId: 'LF2378',
                          //       time: "Just now",
                          //       newMessageCount: "5",
                          //       enquiredProfile: [
                          //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                          //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                          //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
                          //       ],
                          //       onTap: () {
                          //         AppRoutes.pushNamed(
                          //           AppRoutes.enquiryListScreen,
                          //         );
                          //       },
                          //       showPostId: true,
                          //     ).pad();
                          //   },
                          // ),
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

  Widget _buildLostTab() {
    if (isLoadingLost) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lostErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(text: lostErrorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(title: 'Retry', onTap: _fetchLostPosts),
            //ElevatedButton(onPressed: _fetchLostPosts, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (lostPosts.isEmpty) {
      return const Center(child: AppText(text: 'No lost items posted yet'));
    }

    return RefreshIndicator(
      onRefresh: _fetchLostPosts,
      child: ListView(
        children: [
          StreamBuilder(
            stream: filterStateStream.stream,
            builder: (context, asyncSnapshot) {
              final filterData = asyncSnapshot.data ?? HomeFilterState();
              if (!filterData.filterApplied) return const SizedBox.shrink();
              return Container(
                height: 35,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppIconWidget(assetPath: AssetImages.filterTick),
                    SizedBox(width: 15),
                    AppText(
                      text: 'Showing results : ${filterData.displayText}',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        _clearFilter();
                        _fetchLostPosts();
                      },
                      child: AppIconWidget(assetPath: AssetImages.crossIcon, color: AppColors.black),
                    ),
                  ],
                ).padHorizontal(16),
              ).padHorizontal();
            },
          ),


          for (final post in lostPosts)
            ItemCard(
              imgUrl: post.images.isNotEmpty ? post.images.first : '',
              title: post.name,
              location: post.location,
              date: _formatDate(post.postDate),
              postId: post.postUid,
              foundCount: matchingCounts[post.id],
              postIntId: post.id,
              onDeleted: _fetchLostPosts,
              newMessageCount: post.enquiriesCount > 0 ? post.enquiriesCount.toString() : null,
              enquiredProfile: post.enquirerAvatars.isNotEmpty
                  ? post.enquirerAvatars.map((e) => e.imageUrl).toList()
                  : null,
              onViewAll: () => _openAvailableMatching(post),
              onTap: () {

                AppRoutes.pushNamed(
                  AppRoutes.availableMatchingScreen,
                  arguments: {
                    'postId': post.id,
                    'imgUrl': post.images.isNotEmpty ? post.images.first : '',
                    'title': post.name,
                    'location': post.location,
                    'date': _formatDate(post.postDate),
                    'postUid': post.postUid,
                    'foundCount': post.enquiriesCount,
                    'isReceived': false,
                  }
                );
              },
              showPostId: true,
            ).pad(),
        ],
      ),
    );
  }

  Widget _buildFoundTab() {
    if (isLoadingFound) {
      return const Center(child: CircularProgressIndicator());
    }
    if (foundErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(text: foundErrorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(title: 'Retry', onTap: _fetchFoundPosts),
          ],
        ),
      );
    }
    if (foundPosts.isEmpty) {
      return const Center(child: AppText(text: 'No found items posted yet'));
    }

    return RefreshIndicator(
      onRefresh: _fetchFoundPosts,
      child: ListView(
        children: [

          StreamBuilder(
            stream: filterStateStream.stream,
            builder: (context, asyncSnapshot) {
              final filterData = asyncSnapshot.data ?? HomeFilterState();
              if (!filterData.filterApplied) return const SizedBox.shrink();
              return Container(
                height: 35,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppIconWidget(assetPath: AssetImages.filterTick),
                    SizedBox(width: 15),
                    AppText(
                      text: 'Showing results : ${filterData.displayText}',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        _clearFilter();
                        _fetchFoundPosts();
                      },
                      child: AppIconWidget(assetPath: AssetImages.crossIcon, color: AppColors.black),
                    ),
                  ],
                ).padHorizontal(16),
              ).padHorizontal();
            },
          ),


          for (final post in foundPosts)
            ItemCard(
              imgUrl: post.images.isNotEmpty ? post.images.first : '',
              title: post.name,
              location: post.location,
              date: _formatDate(post.postDate),
              postId: post.postUid,
              postIntId: post.id,
              onDeleted: _fetchFoundPosts,
              newMessageCount: post.enquiriesCount > 0 ? post.enquiriesCount.toString() : null,
              enquiredProfile: post.enquirerAvatars.isNotEmpty
                  ? post.enquirerAvatars.map((e) => e.imageUrl).toList()
                  : null,
              onTap: () {
                AppRoutes.pushNamed(AppRoutes.enquiryListScreen,arguments: {'postId': post.id},);
              },
              showPostId: true,
            ).pad(),
        ],
      ),
    );
  }
  // Widget _buildFoundTab() {
  //   if (isLoadingFound) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //   if (foundErrorMessage != null) {
  //     return Center(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //
  //           AppText(text: foundErrorMessage!, textAlign: TextAlign.center),
  //           const SizedBox(height: 12),
  //           AppButton(title: 'Retry', onTap: _fetchFoundPosts),
  //           //ElevatedButton(onPressed: _fetchFoundPosts, child: const Text('Retry')),
  //         ],
  //       ),
  //     );
  //   }
  //   if (foundPosts.isEmpty) {
  //     return const Center(child: AppText(text: 'No found items posted yet'));
  //   }
  //
  //   return RefreshIndicator(
  //     onRefresh: _fetchFoundPosts,
  //     child: ListView.builder(
  //       itemCount: foundPosts.length,
  //       itemBuilder: (context, index) {
  //         final post = foundPosts[index];
  //         return ItemCard(
  //           imgUrl: post.images.isNotEmpty ? post.images.first : '',
  //           title: post.name,
  //           location: post.location,
  //           date: _formatDate(post.postDate),
  //           postId: post.postUid,
  //           postIntId: post.id,
  //           onDeleted: _fetchFoundPosts,
  //           newMessageCount: post.enquiriesCount > 0 ? post.enquiriesCount.toString() : null,
  //           enquiredProfile: post.enquirerAvatars.isNotEmpty
  //               ? post.enquirerAvatars.map((e) => e.imageUrl).toList()
  //               : null,
  //           onTap: () {
  //             AppRoutes.pushNamed(AppRoutes.enquiryListScreen);
  //           },
  //           showPostId: true,
  //         ).pad();
  //       },
  //     ),
  //   );
  // }

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
  final String? selectedRange;   // e.g. "Last 7 Days" or "Custom Range"
  final String? dateFilter;      // API value, e.g. "last_7_days" or "custom"
  final DateTimeRange? customRange;

  const HomeFilterState({
    this.filterApplied = false,
    this.selectedRange,
    this.dateFilter,
    this.customRange,
  });

  factory HomeFilterState.cleared() => const HomeFilterState();

  String get displayText {
    if (selectedRange == 'Custom Range' && customRange != null) {
      final start = DateFormat('MMMM d').format(customRange!.start);
      final end = DateFormat('MMMM d').format(customRange!.end);
      return '$start - $end';
    }
    return selectedRange ?? '';
  }
}
