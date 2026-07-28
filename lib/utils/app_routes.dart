import 'package:go_router/go_router.dart';
import 'package:lost_and_found/screens/home/available_matching_screen.dart';
import 'package:lost_and_found/screens/bottom_screen.dart';
import 'package:lost_and_found/screens/post/category_radios_lists_screen.dart';
import 'package:lost_and_found/screens/chat/chat_screen.dart';
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
  static const mapScreen = '/mapScreen';
  static const subCategoryScreen = '/subCategoryScreen';




  static final GoRouter router = GoRouter(
    navigatorKey: AppUtils.navigatorKey,
    initialLocation: AppPreferences.getIsOnboarded()
        ? AppPreferences.getIsLoggedIn()
              ? bottomScreen
              : loginScreen
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
        builder: (context, state) => const OtpScreen(),
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
          return ProfileScreen(profileModel: model);
        },
      ),

      GoRoute(
        path: '/firstHomeScreen',
        name: firstHomeScreen,
        builder: (context, state) => const FirstHomeScreen(),
      ),
      GoRoute(
        path: '/categoryRadioScreen',
        name: categoryRadioScreen,
        builder: (context, state) => const CategoryRadiosListsScreen(),
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
          final model = state.extra as AvailableScreenModel;
          return AvailableMatchingScreen(
            availableScreenModel: AvailableScreenModel(
              foundCount: 8,
              isReceived: false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/lostItemsDetailsScreen',
        name: lostItemsDetailsScreen,
        builder: (context, state) {
          return LostItemsDetailsScreen();
        },
      ),

      GoRoute(
        path: '/enquiryListScreen',
        name: enquiryListScreen,
        builder: (context, state) {
          return EnquiryListScreen();
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
          return SecondStepperScreen();
        },
      ),
      GoRoute(
        path: '/mapScreen',
        name: mapScreen,
        builder: (context, state) {
          return MapScreen();
        },
      ),

      GoRoute(
        path: '/subCategoryScreen',
        name: subCategoryScreen,
        builder: (context, state) {
          return SubCategoryScreen();
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
    router.goNamed(name, extra: arguments);
  }
}
