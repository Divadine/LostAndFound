import 'package:go_router/go_router.dart';
import 'package:lost_and_found/screens/available_matching_screen.dart';
import 'package:lost_and_found/screens/bottom_screen.dart';
import 'package:lost_and_found/screens/category_radios_lists_screen.dart';
import 'package:lost_and_found/screens/chat_screen.dart';
import 'package:lost_and_found/screens/delete_account_screeen.dart';
import 'package:lost_and_found/screens/enquiry_list_screen.dart';
import 'package:lost_and_found/screens/firstHome_screen.dart';
import 'package:lost_and_found/screens/home_screen.dart';
import 'package:lost_and_found/screens/login_screen.dart';
import 'package:lost_and_found/screens/lost_items_details_screen.dart';
import 'package:lost_and_found/screens/onboarding_screen.dart';
import 'package:lost_and_found/screens/otp_screen.dart';
import 'package:lost_and_found/screens/profile_screen.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/screens/report_justification.dart';
import 'package:lost_and_found/screens/second_stepper_screen.dart';
import 'package:lost_and_found/screens/settings_screen.dart';
import 'package:lost_and_found/screens/webView.dart';
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
