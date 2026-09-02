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
import 'package:lost_and_found/screens/bottomsheets/handover_selection.dart';

import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
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
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  final List<TextEditingController> _controller = List.generate(6, (_) => TextEditingController());
  List<Map<String, dynamic>> details = [
    {
      'imageUrl': '',
    },
  ];

  final Map<int, int> matchingCounts = {};

  HomeFilterState filterState = const HomeFilterState();

  final StreamController<HomeFilterState> filterStateStream =
  StreamController<HomeFilterState>.broadcast();

  late TabController _tabController;

  int _selectedIndex = 0;

  // ============================================================
  // LOST POSTS
  // ============================================================

  List<PostModel> lostPosts = [];
  bool isLoadingLost = true;
  bool isMoreLoadingLost = false;
  int currentPageLost = 1;
  int totalLost = 0;
  final int limitLost = 10;
  String? lostErrorMessage;
  final ScrollController _lostScrollController = ScrollController();

  // ============================================================
  // FOUND POSTS
  // ============================================================

  List<PostModel> foundPosts = [];
  bool isLoadingFound = true;
  bool isMoreLoadingFound = false;
  int currentPageFound = 1;
  int totalFound = 0;
  final int limitFound = 10;
  String? foundErrorMessage;
  final ScrollController _foundScrollController = ScrollController();

  // ============================================================
  // FILTER
  // ============================================================

  void _emitFilter(HomeFilterState state) {
    filterState = state;
    filterStateStream.add(state);
  }

  void _clearFilter() {
    _emitFilter(
      HomeFilterState.cleared(),
    );
  }

  // ============================================================
  // MATCH COUNT
  // ============================================================

  Future<void> _fetchMatchCounts(
      List<PostModel> posts,
      ) async {
    for (final post in posts) {
      try {
        final response = await authController.getPostMatches(
          postId: post.id,
        );

        if (!mounted) {
          return;
        }

        if (response.isSuccess &&
            response.data != null &&
            response.data!.matchingCount > 0) {
          setState(() {
            matchingCounts[post.id] =
                response.data!.matchingCount;
          });
        }
      } catch (e) {
        debugPrint(
          'Error fetching match count for post ${post.id}: $e',
        );
      }
    }
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  String? _mapRangeToApiFilter(
      String? label,
      ) {
    switch (label) {
      case 'Today':
        return 'today';

      case 'Last 7 Days':
        return 'last_7_days';

      case 'Last 30 Days':
        return 'last_30_days';

      case 'Last 3 Months':
        return 'last_3_months';

      case 'Last Year':
        return 'last_year';

      case 'Custom Range':
        return 'custom';

      default:
        return null;
    }
  }

  // ============================================================
  // FORMAT POST DATE
  // ============================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    return DateFormat(
      'd MMM yyyy',
    ).format(date);
  }

  // ============================================================
  // AVAILABLE MATCHING
  // ============================================================

  void _openAvailableMatching(
      PostModel post,
      ) {
    AppRoutes.pushNamed(
      AppRoutes.availableMatchingScreen,
      arguments: {
        'postId': post.id,
        'imgUrl': post.images.isNotEmpty
            ? post.images.first
            : '',
        'title': post.name,
        'location': post.location,
        'date': _formatDate(post.postDate),
        'postUid': post.postUid,
        'foundCount': matchingCounts[post.id] ?? 0,
        'isReceived': false,
        'status': post.status,
      },
    );
  }

  // ============================================================
  // FETCH LOST POSTS
  // ============================================================

  Future<void> _fetchLostPosts({bool isLoadMore = false}) async {
    if (mounted) {
      setState(() {
        if (isLoadMore) {
          isMoreLoadingLost = true;
        } else {
          isLoadingLost = true;
          currentPageLost = 1;
          lostPosts.clear();
        }
        lostErrorMessage = null;
      });
    }

    try {
      final userId = await AppPreferences.getUserId();

      final response = filterState.filterApplied
          ? await authController.filterPosts(
              userId: userId ?? 0,
              postType: 0,
              dateFilter: filterState.dateFilter,
              startDate: filterState.customRange != null
                  ? DateFormat('yyyy-MM-dd').format(
                      filterState.customRange!.start,
                    )
                  : null,
              endDate: filterState.customRange != null
                  ? DateFormat('yyyy-MM-dd').format(
                      filterState.customRange!.end,
                    )
                  : null,
              page: currentPageLost,
              limit: limitLost,
            )
          : await authController.getPost(
              userId: userId ?? 0,
              postType: 0,
              page: currentPageLost,
              limit: limitLost,
            );

      if (!mounted) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        var posts = response.data!.posts;
        totalLost = response.data!.total;

        setState(() {
          if (isLoadMore) {
            lostPosts.addAll(posts);
          } else {
            lostPosts = posts;
          }
          isLoadingLost = false;
          isMoreLoadingLost = false;
        });

        _fetchMatchCounts(posts);
      } else {
        setState(() {
          isLoadingLost = false;
          isMoreLoadingLost = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLost = false;
        isMoreLoadingLost = false;
      });
      debugPrint('Lost posts error: $e');
    }
  }

  // ============================================================
  // FETCH FOUND POSTS
  // ============================================================

  Future<void> _fetchFoundPosts({bool isLoadMore = false}) async {
    if (mounted) {
      setState(() {
        if (isLoadMore) {
          isMoreLoadingFound = true;
        } else {
          isLoadingFound = true;
          currentPageFound = 1;
          foundPosts.clear();
        }
        foundErrorMessage = null;
      });
    }

    try {
      final userId = await AppPreferences.getUserId();

      final response = filterState.filterApplied
          ? await authController.filterPosts(
              userId: userId ?? 0,
              postType: 1,
              dateFilter: filterState.dateFilter,
              startDate: filterState.customRange != null
                  ? DateFormat('yyyy-MM-dd').format(
                      filterState.customRange!.start,
                    )
                  : null,
              endDate: filterState.customRange != null
                  ? DateFormat('yyyy-MM-dd').format(
                      filterState.customRange!.end,
                    )
                  : null,
              page: currentPageFound,
              limit: limitFound,
            )
          : await authController.getPost(
              userId: userId ?? 0,
              postType: 1,
              page: currentPageFound,
              limit: limitFound,
            );

      if (!mounted) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        var posts = response.data!.posts;
        totalFound = response.data!.total;

        setState(() {
          if (isLoadMore) {
            foundPosts.addAll(posts);
          } else {
            foundPosts = posts;
          }
          isLoadingFound = false;
          isMoreLoadingFound = false;
        });
      } else {
        setState(() {
          isLoadingFound = false;
          isMoreLoadingFound = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingFound = false;
        isMoreLoadingFound = false;
      });
      debugPrint('Found posts error: $e');
    }
  }

  // ============================================================
  // SHOW CONTACT REQUEST DIALOG
  // ============================================================

  void _showContactRequestDialog() {
    AppDialogue.showPopup(
      context: context,
      content: ChatSendRequest(
        senderName: 'This user',

        // TEMPORARY:
        // Replace this with the actual Firestore request createdAt
        // when you load the notification/request.
        requestTime: DateTime.now(),

        onDecline: () {
          Navigator.pop(context);
        },

        onAccept: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _selectedIndex) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    _lostScrollController.addListener(() {
      if (_lostScrollController.position.pixels >= _lostScrollController.position.maxScrollExtent - 200 &&
          !isMoreLoadingLost &&
          lostPosts.length < totalLost) {
        currentPageLost++;
        _fetchLostPosts(isLoadMore: true);
      }
    });

    _foundScrollController.addListener(() {
      if (_foundScrollController.position.pixels >= _foundScrollController.position.maxScrollExtent - 200 &&
          !isMoreLoadingFound &&
          foundPosts.length < totalFound) {
        currentPageFound++;
        _fetchFoundPosts(isLoadMore: true);
      }
    });

    _fetchLostPosts();
    _fetchFoundPosts();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();
    filterStateStream.close();
    _lostScrollController.dispose();
    _foundScrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primaryColor,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // ====================================================
            // BLUE BACKGROUND
            // ====================================================

            Container(
              height: double.infinity,
              width: double.infinity,
              color: AppColors.primaryColor,
            ),

            // ====================================================
            // HOME BOX IMAGE
            // ====================================================

            Positioned(
              top: 30,
              right: 0,
              child: AppIconWidget(
                assetPath: AssetImages.homeBox,
              ),
            ),

            // ====================================================
            // WHITE CONTENT CONTAINER
            // ====================================================

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(12),

                height:
                MediaQuery.of(context).size.height * 0.65,

                width: double.infinity,

                decoration: const BoxDecoration(
                  color: AppColors.white,

                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.start,

                  children: [
                    // ==========================================
                    // TAB + FILTER
                    // ==========================================

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,

                              decoration: BoxDecoration(
                                color: AppColors.white,

                                borderRadius:
                                BorderRadius.circular(30),

                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),

                              child: TabBar(
                                controller:
                                _tabController,

                                indicatorSize:
                                TabBarIndicatorSize.label,

                                indicator:
                                const UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color:
                                    AppColors.primaryColor,
                                    width: 3,
                                  ),

                                  insets:
                                  EdgeInsets.symmetric(
                                    vertical: -10,
                                  ),
                                ),

                                padding: EdgeInsets.zero,

                                indicatorPadding:
                                const EdgeInsets.only(
                                  left: 1,
                                  right: 1,
                                ),

                                dividerColor:
                                Colors.transparent,

                                labelColor:
                                AppColors.primaryColor,

                                unselectedLabelColor:
                                AppColors.grey,

                                tabs: [
                                  Tab(
                                    child:
                                    buildTabBarView(
                                      image: AssetImages
                                          .lostItemHome,

                                      title: 'Lost Items',

                                      isSelected:
                                      _selectedIndex ==
                                          0,
                                    ),
                                  ),

                                  Tab(
                                    child:
                                    buildTabBarView(
                                      image:
                                      AssetImages.foundItem,

                                      title: 'Found Items',

                                      isSelected:
                                      _selectedIndex ==
                                          1,
                                    ),
                                  ),
                                ],
                              ).pad(),
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          // ====================================
                          // FILTER BUTTON
                          // ====================================

                          GestureDetector(
                            onTap: () async {
                              final filterData =
                              await AppUiHelper
                                  .showBottomSheet(
                                context: context,
                                child: FilterScreen(),
                              );

                              if (!mounted) {
                                return;
                              }

                              if (filterData == 'clear') {
                                _emitFilter(
                                  HomeFilterState
                                      .cleared(),
                                );

                                _fetchLostPosts();
                                _fetchFoundPosts();
                              } else if (filterData
                              is Map) {
                                _emitFilter(
                                  HomeFilterState(
                                    customRange:
                                    filterData[
                                    'customRange'],

                                    filterApplied:
                                    true,

                                    selectedRange:
                                    filterData[
                                    'range'],

                                    dateFilter:
                                    filterData[
                                    'dateFilter'],
                                  ),
                                );

                                _fetchLostPosts();
                                _fetchFoundPosts();
                              }
                            },

                            child: Container(
                              height: 40,
                              width: 40,

                              decoration:
                              const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,

                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.black12,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),

                              child: Center(
                                child: AppIconWidget(
                                  assetPath:
                                  AssetImages.filter,

                                  fit: BoxFit.cover,

                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // TAB CONTENT
                    // ==========================================

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,

                        children: [
                          _buildLostTab(),
                          _buildFoundTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // HEADER
            // ====================================================

            Positioned(
              top: 40,
              left: 20,
              right: 20,

              child: Column(
                spacing: 10,

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [
                      const AppText(
                        text: 'Lost & Found',
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),

                      // AppContainer(widget:
                      //     Row(children: [
                      //       AppIconWidget(assetPath: AssetImages.trophy),
                      //       AppText(text: 'Community Success',color: AppColors.white,fontSize: 12,fontWeight: FontWeight.w500,),
                      //     ],)
                      // ),

                      // ========================================
                      // NOTIFICATION
                      // ========================================

                      GestureDetector(
                        onTap:
                        _showContactRequestDialog,

                        child: AppIconWidget(
                          assetPath:
                          AssetImages.notification,
                        ),
                      ),
                    ],
                  ),

                  const AppText(
                    text:
                    'Helping you reunite with what\nmatters.',
                    color: AppColors.white,
                    fontSize: 14,
                  ),


                  // Row(
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   spacing: 10,
                  //   children: List.generate(_controller.length,(index) {
                  //     return Container(
                  //       height: 50,
                  //       width: 50,
                  //       child: TextField(
                  //         readOnly: true,
                  //         controller: _controller[index],
                  //
                  //
                  //
                  //
                  //
                  //
                  //       ),
                  //     );
                  //   }
                  //   )),


                  //AppText(text: "Users benefited",fontWeight: FontWeight.w400,fontSize: 12,color: AppColors.white,)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOST TAB
  // ============================================================

  Widget _buildLostTab() {
    if (isLoadingLost) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (lostPosts.isEmpty) {
      return const Center(
        child: AppText(
          text: 'No lost items posted yet',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLostPosts,

      child: Column(
        children: [
          // ================================================
          // FILTER DISPLAY
          // ================================================

          StreamBuilder<HomeFilterState>(
            stream: filterStateStream.stream,
            initialData: filterState,

            builder: (
                context,
                asyncSnapshot,
                ) {
              final filterData =
                  asyncSnapshot.data ??
                      const HomeFilterState();

              if (!filterData.filterApplied) {
                return const SizedBox.shrink();
              }

              return Container(
                height: 35,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: AppColors.lightBlue,

                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,

                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [
                    AppIconWidget(
                      assetPath:
                      AssetImages.filterTick,
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    AppText(
                      text:
                      'Showing results: ${filterData.displayText}',

                      fontSize: 12,

                      fontWeight:
                      FontWeight.w500,
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () {
                        _clearFilter();
                        _fetchLostPosts();
                        _fetchFoundPosts();
                      },

                      child: AppIconWidget(
                        assetPath:
                        AssetImages.crossIcon,

                        color: AppColors.black,
                      ),
                    ),
                  ],
                ).padHorizontal(16),
              ).padHorizontal().padBottom(10);
            },
          ),

          // ================================================
          // LOST ITEMS
          // ================================================

          Expanded(
            child: lostPosts.isEmpty
                ? const Center(
                    child: AppText(
                      text: 'No lost items posted yet',
                    ),
                  )
                : ListView.builder(
                    controller: _lostScrollController,
                    itemCount: lostPosts.length + (isMoreLoadingLost ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == lostPosts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = lostPosts[index];
                      return ItemCard(
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
                            ? post.enquirerAvatars
                                .map((e) => e.imageUrl)
                                .where((url) => url.isNotEmpty)
                                .toList()
                            : null,
                        onViewAll: () => _openAvailableMatching(post),
                        status: post.status,
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
                              'status': post.status,
                            },
                          );
                        },
                        showPostId: true,
                      ).pad();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOUND TAB
  // ============================================================

  Widget _buildFoundTab() {
    if (isLoadingFound) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (foundPosts.isEmpty) {
      return const Center(
        child: AppText(
          text: 'No found items posted yet',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFoundPosts,

      child: Column(
        children: [
          // ================================================
          // FILTER DISPLAY
          // ================================================

          StreamBuilder<HomeFilterState>(
            stream: filterStateStream.stream,
            initialData: filterState,

            builder: (
                context,
                asyncSnapshot,
                ) {
              final filterData =
                  asyncSnapshot.data ??
                      const HomeFilterState();

              if (!filterData.filterApplied) {
                return const SizedBox.shrink();
              }

              return Container(
                height: 35,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: AppColors.lightBlue,

                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,

                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [
                    AppIconWidget(
                      assetPath:
                      AssetImages.filterTick,
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    AppText(
                      text:
                      'Showing results: ${filterData.displayText}',

                      fontSize: 12,

                      fontWeight:
                      FontWeight.w500,
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () {
                        _clearFilter();
                        _fetchLostPosts();
                        _fetchFoundPosts();
                      },

                      child: AppIconWidget(
                        assetPath:
                        AssetImages.crossIcon,

                        color: AppColors.black,
                      ),
                    ),
                  ],
                ).padHorizontal(16),
              ).padHorizontal().padBottom(10);
            },
          ),

          // ================================================
          // FOUND ITEMS
          // ================================================

          Expanded(
            child: foundPosts.isEmpty
                ? const Center(
                    child: AppText(
                      text: 'No found items posted yet',
                    ),
                  )
                : ListView.builder(
                    controller: _foundScrollController,
                    itemCount: foundPosts.length + (isMoreLoadingFound ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == foundPosts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = foundPosts[index];
                      return ItemCard(
                        imgUrl: post.images.isNotEmpty ? post.images.first : '',
                        title: post.name,
                        location: post.location,
                        date: _formatDate(post.postDate),
                        isFound: true,
                        postId: post.postUid,
                        postIntId: post.id,
                        onDeleted: _fetchFoundPosts,
                        newMessageCount: post.enquiriesCount > 0 ? post.enquiriesCount.toString() : null,
                        enquiredProfile: post.enquirerAvatars.isNotEmpty
                            ? post.enquirerAvatars
                                .map((e) => e.imageUrl)
                                .where((url) => url.isNotEmpty)
                                .toList()
                            : null,
                        status: post.status,
                        onTap: () {
                          AppRoutes.pushNamed(
                            AppRoutes.enquiryListScreen,
                            arguments: {
                              'postId': post.id,
                            },
                          );
                        },
                        showPostId: true,
                      ).pad();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BAR
  // ============================================================

  Widget buildTabBarView({
    required String image,
    required String title,
    required bool isSelected,
  }) {
    final color = isSelected
        ? AppColors.primaryColor
        : AppColors.grey;

    return Row(
      spacing: 10,

      mainAxisAlignment:
      MainAxisAlignment.center,

      children: [
        AppIconWidget(
          assetPath: image,
          color: color,
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

// ================================================================
// HOME FILTER STATE
// ================================================================

class HomeFilterState {
  final bool filterApplied;

  final String? selectedRange;

  final String? dateFilter;

  final DateTimeRange? customRange;

  const HomeFilterState({
    this.filterApplied = false,
    this.selectedRange,
    this.dateFilter,
    this.customRange,
  });

  factory HomeFilterState.cleared() {
    return const HomeFilterState();
  }

  DateTimeRange? get effectiveRange {
    if (customRange != null) return customRange;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (selectedRange) {
      case 'Today':
        return DateTimeRange(start: today, end: today);
      case 'Last 7 Days':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case 'Last 30 Days':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case 'Last 3 Months':
        return DateTimeRange(
          start: DateTime(today.year, today.month - 3, today.day),
          end: today,
        );
      case 'Last Year':
        return DateTimeRange(
          start: DateTime(today.year - 1, today.month, today.day),
          end: today,
        );
      default:
        return null;
    }
  }

  String get displayText {
    final range = effectiveRange;
    if (range != null) {
      final start = DateFormat('MMMM d').format(range.start);
      final end = DateFormat('MMMM d').format(range.end);
      if (start == end) return start;
      return '$start - $end';
    }
    return selectedRange ?? '';
  }
}

// ================================================================
// CONTACT REQUEST DIALOG
// ================================================================

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
      DateTime date,
      ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final requestDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(requestDay).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return DateFormat(
      'd MMM yyyy',
    ).format(date);
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final displayName =
    senderName.trim().isNotEmpty
        ? senderName.trim()
        : 'This user';

    return Column(
      mainAxisSize: MainAxisSize.min,

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

              child: AppIconWidget(
                assetPath:
                AssetImages.phone,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

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

            const SizedBox(
              width: 8,
            ),

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
            Expanded(
              child: AppButton(
                title: 'Decline',

                onTap: onDecline,

                bgColor:
                AppColors.white,

                border: Border.all(
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