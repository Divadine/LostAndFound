import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/authmodels/profile_screen_model.dart';
import 'package:lost_and_found/models/posts_model/post_list_model.dart';
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
      } else {
        AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
      }
      return;
    }

    // =========================================================================
    // LOGGED IN.
    // =========================================================================

    final userId = AppPreferences.getUserId();
    if (userId == null) {
      AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
      return;
    }

    // Resolve the user's latest status from the backend before deciding
    // where to navigate. This ensures that after a fresh install, we
    // correctly identify existing users versus new users.
    final profileResponse = await _authController.getProfile(userId: userId);

    if (!mounted) return;

    int currentStatus = AppPreferences.getProfileStatus();
    ProfileScreenModel? profileData;

    if (profileResponse.isSuccess && profileResponse.data != null) {
      profileData = profileResponse.data!;
      currentStatus = profileData.status ?? currentStatus;
      // Sync local status with backend
      await AppPreferences.setProfileStatus(currentStatus);
    } else {
      // Failed to fetch profile (e.g. no internet).
      // If we already have a status >= 1 locally, we can proceed.
      if (currentStatus >= 2) {
        AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
        return;
      } else if (currentStatus == 1) {
        AppRoutes.pushAndRemoveUntil(AppRoutes.firstHomeScreen);
        return;
      }
    }

    if (currentStatus >= 1) {
      // Profile completed. Now check the backend for any existing posts.
      // This is the source of truth for whether an existing user should
      // bypass the FirstHomeScreen after a reinstall.
      bool hasPosted = false;
      try {
        final postResults = await Future.wait([
          _authController.getPost(userId: userId, postType: 0, limit: 1),
          _authController.getPost(userId: userId, postType: 1, limit: 1),
        ]);

        if (postResults[0].isSuccess &&
            postResults[0].data != null &&
            postResults[0].data!.total > 0) {
          hasPosted = true;
        } else if (postResults[1].isSuccess &&
            postResults[1].data != null &&
            postResults[1].data!.total > 0) {
          hasPosted = true;
        }
      } catch (e) {
        debugPrint('Splash: Failed to check post status: $e');
      }

      if (hasPosted) {
        await AppPreferences.setProfileStatus(2);
        AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
      } else {
        // If no posts found, always go to FirstHomeScreen, even if local status was 2.
        await AppPreferences.setProfileStatus(1);
        AppRoutes.pushAndRemoveUntil(AppRoutes.firstHomeScreen);
      }
      return;
    }

    // Profile incomplete — fetch the latest saved data and resume the form
    // exactly where the user left off, instead of showing a blank one.
    if (profileData != null) {
      AppRoutes.pushAndRemoveUntil(
        AppRoutes.profileScreen,
        arguments: profileData.copyWith(isFromEdit: false),
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