import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/models/authmodels/profile_form_models.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/categories_model/category_model.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/screens/bottomsheets/filter_screen.dart';
import 'package:lost_and_found/screens/chat/individual_chat_screen.dart';
import 'package:lost_and_found/screens/home/available_matching_screen.dart';
import 'package:lost_and_found/screens/bottom_screen.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/screens/post/category_radios_lists_screen.dart';
import 'package:lost_and_found/screens/chat/chat_screen.dart';
import 'package:lost_and_found/screens/post/first_stepper_screen.dart';
import 'package:lost_and_found/screens/post/preview_screen.dart';
import 'package:lost_and_found/screens/post/sub_category_screen.dart';
import 'package:lost_and_found/screens/profile/delete_account_screeen.dart';
import 'package:lost_and_found/screens/home/enquiry_list_screen.dart';
import 'package:lost_and_found/screens/authentication/role_chosen_screen.dart';
import 'package:lost_and_found/screens/home/home_screen.dart';
import 'package:lost_and_found/screens/authentication/login_screen.dart';
import 'package:lost_and_found/screens/home/details_screen.dart';
import 'package:lost_and_found/screens/nearby/map_screen.dart';
import 'package:lost_and_found/screens/authentication/onboarding_screen.dart';
import 'package:lost_and_found/screens/authentication/otp_screen.dart';
import 'package:lost_and_found/screens/authentication/profile_screen.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/report_justification.dart';
import 'package:lost_and_found/screens/post/second_stepper_screen.dart';
import 'package:lost_and_found/screens/profile/settings_screen.dart';
import 'package:lost_and_found/screens/profile/webView.dart';
import 'package:lost_and_found/shared_widgets/app_recorder.dart';
import 'package:lost_and_found/utils/app_preferences.dart';

import 'app_utils.dart';

class AppRoutes {
  static const onBoardingScreen = "/onBoardingScreen";
  static const homeScreen = '/homeScreen';
  static const loginScreen = '/loginScreen';
  static const registerScreen = '/registerScreen';
  static const otpScreen = '/otpScreen';
  static const bottomScreen = '/bottomScreen';
  static const profileScreen = '/profileScreen';
  static const firstHomeScreen = '/firstHomeScreen';
  static const categoryRadioScreen = '/categoryRadioScreen';
  static const settingsScreen = '/settingsScreen';
  static const webViewScreen = '/webViewScreen';
  static const deleteAccountScreen = '/deleteAccountScreen';
  static const reportJustification = '/reportJustification';
  static const availableMatchingScreen = '/availableMatchingScreen';
  static const lostItemsDetailsScreen = '/lostItemsDetailsScreen';
  static const enquiryListScreen = '/enquiryListScreen';
  static const chatScreen = '/chatScreen';
  static const secondStepperScreen = '/secondStepperScreen';
  static const previewScreen = '/previewScreen';
  static const mapScreen = '/mapScreen';
  static const subCategoryScreen = '/subCategoryScreen';
  static const individualChatScreen = '/individualChatScreen';
  static const firstStepperScreen = '/firstStepperScreen';








  static final GoRouter router = GoRouter(
    navigatorKey: AppUtils.navigatorKey,
    initialLocation: AppPreferences.getIsOnboarded()
        ? loginScreen
        : onBoardingScreen,
    routes: [
      GoRoute(
        path: '/onBoardingScreen',
        name: onBoardingScreen,
        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(
        path: '/homeScreen',
        name: homeScreen,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/loginScreen',
        name: loginScreen,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/registerScreen',
        name: registerScreen,
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/otpScreen',
        name: otpScreen,
        builder: (context, state) {
          if (state.extra is Map) {
            final data = state.extra as Map<String, dynamic>;
            return OtpScreen(
              mobileNo: data['mobileNo'] as String,
              autoSend: data['autoSend'] as bool? ?? true,
            );
          }
          final mobileNo = state.extra is String ? state.extra as String : '';
          return OtpScreen(mobileNo: mobileNo);
        },
      ),
      GoRoute(
        path: '/bottomScreen',
        name: bottomScreen,
        builder: (context, state) => const BottomScreen(),
      ),

      GoRoute(
        path: '/profileScreen',
        name: profileScreen,
        builder: (context, state) {
          final model = state.extra as ProfileScreenModel;

          return ProfileScreen(profileModel:model, );
        },
      ),

      GoRoute(
        path: '/firstHomeScreen',
        name: firstHomeScreen,
        builder: (context, state) => const FirstHomeScreen(),
      ),


      GoRoute(
        path: '/settingsScreen',
        name: settingsScreen,
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/webViewScreen',
        name: webViewScreen,
        builder: (context, state) {
          final model = state.extra as WebViewModel;
          return WebViewScreen(model: model);
        },
      ),
      GoRoute(
        path: '/deleteAccountScreen',
        name: deleteAccountScreen,
        builder: (context, state) {
          return DeleteAccountScreen();
        },
      ),
      GoRoute(
        path: '/reportJustification',
        name: reportJustification,
        builder: (context, state) {
          return ReportJustification();
        },
      ),

      GoRoute(
        path: '/availableMatchingScreen',
        name: availableMatchingScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return AvailableMatchingScreen(
            postId: data['postId'] as int,
            imgUrl: data['imgUrl'] as String? ?? '',
            title: data['title'] as String? ?? '',
            location: data['location'] as String? ?? '',
            date: data['date'] as String? ?? '',
            postUid: data['postUid'] as String? ?? '',
            foundCount: data['foundCount'] as int?,
            isReceived: data['isReceived'] as bool? ?? false,
            status: data['status'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/lostItemsDetailsScreen',
        name: lostItemsDetailsScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final postId = data?['postId'] as int?;
          final userId = data?['userId'] as int?;
          if (postId == null || userId == null) {
            return const Scaffold(
              body: Center(child: Text('Missing item reference')),
            );
          }
          return LostItemsDetailsScreen(
            postId: postId,
            userId: userId,
            percentageMatch: data?['percentageMatch'] as int?,
            posterName: data?['posterName'] as String? ?? '',
            posterAvatar: data?['posterAvatar'] as String? ?? '',
            originalPostId: data?['originalPostId'] as int? ?? 0,
          );
        },
      ),

      GoRoute(
        path: '/enquiryListScreen',
        name: enquiryListScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final postId = data?['postId'] as int?;
          if (postId == null) {
            return const Scaffold(
              body: Center(child: Text('Missing post reference')),
            );
          }
          return EnquiryListScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/chatScreen',
        name: chatScreen,
        builder: (context, state) {
          return ChatScreen();
        },
      ),
      GoRoute(
        path: '/secondStepperScreen',
        name: secondStepperScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return SecondStepperScreen(
            postId: data['postId'] as int,
            prefillDescription: data['prefillDescription'] as String?,
            itemTypeLabel: data['itemTypeLabel'] as String? ?? 'Item Type',
            itemTypeValue: data['itemTypeValue'] as String? ?? '',
            color: data['color'] as String? ?? '',
            fieldValues: (data['fieldValues'] as List<dynamic>? ?? [])
                .map((e) => Map<String, String>.from(e as Map))
                .toList(),
            mainImage: data['mainImage'] as File?,
          );
        },
      ),
      GoRoute(
        path: '/previewScreen',
        name: previewScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return PreviewScreen(
            postId: data['postId'] as int,
            mainImage: data['mainImage'] as File?,
            itemTypeLabel: data['itemTypeLabel'] as String? ?? 'Item Type',
            itemTypeValue: data['itemTypeValue'] as String? ?? '',
            color: data['color'] as String? ?? '',
            fieldValues: (data['fieldValues'] as List<dynamic>? ?? [])
                .map((e) => Map<String, String>.from(e as Map))
                .toList(),
            locations: data['locations'] as List<SelectedLocationModel>,
            locationText: data['locationText'] as String? ?? '',
            postDate: data['postDate'] as DateTime,
            description: data['description'] as String,
            audioPath: data['audioPath'] as String?,
            videoFile: data['videoFile'] as File?,
          );
        },
      ),
      GoRoute(
        path: '/mapScreen',
        name: mapScreen,
        builder: (context, state) {
          final mapScreenModel = state.extra as MapScreenModel;
          return LocationSelectionScreen(mapScreenModel: mapScreenModel);
        },
      ),

      GoRoute(
        path: '/categoryRadioScreen',
        name: categoryRadioScreen,
        builder: (context, state) {
          final postType = state.extra as int?;
          if (postType == null) {
            return const Scaffold(
              body: Center(child: Text('Missing post type')),
            );
          }
          return CategoryRadiosListsScreen(postType: postType);
        },
      ),

      GoRoute(
        path: '/subCategoryScreen',
        name: subCategoryScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return SubCategoryScreen(
            category: data['category'] as CategoryModel,
            postType: data['postType'] as int,
          );
        },
      ),

      GoRoute(
        path: '/individualChatScreen',
        name: individualChatScreen,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null || data['roomId'] == null) {
            return const Scaffold(body: Center(child: Text('Missing chat reference')));
          }
          return IndividualChatScreen.fromArgs(data);
        },
      ),

      GoRoute(
        path: '/firstStepperScreen',
        name: firstStepperScreen,
        builder: (context, state) {
          final data = state.extra as Map<String,dynamic>;

          return FirstStepperScreen(
            category : data['category'],
            subCategory : data['subCategory'],
            postType: data['postType'] as int, );
        },
      ),




    ],
  );

  static void pop([dynamic result]) {
    router.pop(result);
  }

  static void pushNamed(String name, {dynamic arguments}) {
    router.pushNamed(name, extra: arguments);
  }

  static void pushAndRemoveUntil(String name, {dynamic arguments}) {
    router.go(name, extra: arguments);
  }
}