import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthControllers _authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!AppPreferences.getIsLoggedIn()) {
      if (!AppPreferences.getIsOnboarded()) {
        AppRoutes.pushAndRemoveUntil(AppRoutes.onBoardingScreen);
        return;
      }

      AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
      return;
    }

    // =========================================================================
    // LOGGED IN.
    //
    // Being "logged in" only means auth succeeded — it does NOT mean the user
    // finished the profile-setup form. If they killed the app mid-form,
    // `profileStatus` is still 0/incomplete (both locally and on the server),
    // so we must resume the form instead of jumping straight to BottomScreen.
    // =========================================================================

    final isProfileComplete = AppPreferences.getProfileStatus() == 1;

    if (isProfileComplete) {
      if (AppPreferences.getIsItemPosted()) {
        AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
      } else {
        AppRoutes.pushAndRemoveUntil(AppRoutes.firstHomeScreen);
      }
      return;
    }

    // Profile incomplete — fetch the latest saved data and resume the form
    // exactly where the user left off, instead of showing a blank one.
    final userId = AppPreferences.getUserId();

    if (userId == null) {
      // Shouldn't normally happen if isLoggedIn is true, but guard anyway.
      AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
      return;
    }

    final profileResponse = await _authController.getProfile(userId: userId);

    if (!mounted) return;

    if (profileResponse.isSuccess && profileResponse.data != null) {
      AppRoutes.pushAndRemoveUntil(
        AppRoutes.profileScreen,
        arguments: profileResponse.data!.copyWith(isFromEdit: false),
      );
    } else {
      // Couldn't fetch the saved profile (e.g. no internet at splash time).
      // Fall back to whatever was cached locally at register/login time so
      // the user isn't stranded with a completely blank form.
      AppRoutes.pushAndRemoveUntil(
        AppRoutes.profileScreen,
        arguments: ProfileScreenModel(
          isFromEdit: false,
          userId: userId,
          name: AppPreferences.getUserName(),
          mobile: AppPreferences.getPhone(),
          altMobileVerified: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}