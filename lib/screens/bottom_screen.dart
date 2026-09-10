import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/home/home_screen.dart';
import 'package:lost_and_found/screens/authentication/login_screen.dart';
import 'package:lost_and_found/screens/nearby/map_screen.dart';
import 'package:lost_and_found/screens/report_justification.dart';
import 'package:lost_and_found/screens/profile/settings_screen.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'chat/chat_screen.dart';
import 'authentication/role_chosen_screen.dart';
import 'maps/police_station_mapscreen.dart';

class BottomScreen extends StatefulWidget {
  final int? initialTabIndex;
  final Object? navigationExtra;
  const BottomScreen({super.key, this.initialTabIndex, this.navigationExtra});

  @override
  State<BottomScreen> createState() => _BottomScreenState();
}

class _BottomScreenState extends State<BottomScreen> {
  late int selectedIndex;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  late List<Widget> pages;

  List<String> image = [
    AssetImages.home,
    AssetImages.location,
    AssetImages.addBottom,
    AssetImages.chat,
    AssetImages.profile,
  ];
  List<String> labels = ["Home", "Nearby", "Post", "Enquiry", "Profile"];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex ?? 0;
    pages = [
      HomeScreen(initialTabIndex: widget.initialTabIndex),
      PoliceStationMapScreen(),
      SizedBox(),
      ChatScreen(),
      SettingsScreen(),
    ];
    _initConnectivityListener();
  }

  @override
  void didUpdateWidget(covariant BottomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationExtra != oldWidget.navigationExtra) {
      setState(() {
        selectedIndex = widget.initialTabIndex ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _initConnectivityListener() async {
    // Check initial state
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);

    // Listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _updateOfflineStatus(results);
    });
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;

    if (_isOffline == offline) return;

    setState(() {
      _isOffline = offline;
    });
  }

  void _showPostBottomSheet() {
    AppUiHelper.showCustomBottomDialog(
      barrier: true,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);

                AppRoutes.pushNamed(
                  AppRoutes.categoryRadioScreen,
                  arguments: 0,
                );
              },
              child: buildHomeBottomSheet(
                image: AssetImages.searchLostItem,
                title: "I Lost Something",
                description: "Post details about the item you lost.",
              ),
            ),
          ),

          SizedBox(
            height: 150,
            child: VerticalDivider(
              color: AppColors.fieldGrey,
              thickness: 1,
              width: 1,
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);

                AppRoutes.pushNamed(
                  AppRoutes.categoryRadioScreen,
                  arguments: 1,
                );
              },
              child: buildHomeBottomSheet(
                image: AssetImages.homeFoundItem,
                title: "I Found Something",
                description: "Share details about the item you found.",
              ),
            ),
          ),
        ],
      ),

      // showHandle: false,
      // context: context,
      // maxHeightFactor: .45,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedIndex != 0) {
          setState(() {
            selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0,backgroundColor: AppColors.primaryColor,),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: pages[selectedIndex],
              ),
              if (_isOffline)
                Container(
                  color: Colors.white,
                  child: const NoInternetWidget(),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: AppUtils.isTab ? 80 : 60,
            decoration: BoxDecoration(color: AppColors.primaryColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(image.length, (index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    if (index == 2) {
                      _showPostBottomSheet();
                      return;
                    }

                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: AppUtils.isTab ? 80 : 55,
                    child: Column(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconWidget(assetPath: image[index]),
                        if (isSelected)
                          AppText(
                            text: labels[index],
                            fontSize: 12,
                            color: AppColors.white,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildHomeBottomSheet({
  required String image,
  required String title,
  required String description,
}) {
  return Column(
    spacing: 10,
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: .center,
    children: [
      SizedBox(
        height: 100,
        width: 100,
        child: AppIconWidget(assetPath: image, fit: BoxFit.contain),
      ),
      AppText(text: title, fontSize: 14, fontWeight: FontWeight.w600),
      AppText(
        text: description,
        fontWeight: FontWeight.w400,
        fontSize: 10,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 15),
    ],
  );
}
