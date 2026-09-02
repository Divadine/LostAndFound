import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
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

    if (!AppPreferences.getIsLoggedIn()) {
      if (!AppPreferences.getIsOnboarded()) {
        AppRoutes.pushAndRemoveUntil(AppRoutes.onBoardingScreen);
        return;
      }

      final lastAuth = AppPreferences.getLastAuthScreen();
      if (lastAuth == 'register') {
        AppRoutes.pushAndRemoveUntil(AppRoutes.registerScreen);
      } else {
        AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen);
      }
      return;
    }

    AppRoutes.pushAndRemoveUntil(AppRoutes.bottomScreen);
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
