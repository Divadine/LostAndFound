import 'package:flutter/material.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class SessionExpiredPopup extends StatelessWidget { // NEW
  const SessionExpiredPopup({super.key}); // NEW

  @override // NEW
  Widget build(BuildContext context) { // NEW
    return PopScope( // NEW
      canPop: false, // NEW
      child: AlertDialog( // NEW
        title: const Text("Session Expired"), // NEW
        content: const Text( // NEW
          "Your account was logged in on another device. Please log in again.", // NEW
        ), // NEW
        actions: [ // NEW
          TextButton( // NEW
            onPressed: () async { // NEW
              await AppPreferences.logout(); // NEW
              if (!context.mounted) return; // NEW
              Navigator.of(context, rootNavigator: true).pop(); // NEW
              AppRoutes.pushAndRemoveUntil(AppRoutes.loginScreen); // NEW
            }, // NEW
            child: const Text("OK"), // NEW
          ), // NEW
        ], // NEW
      ), // NEW
    ); // NEW
  } // NEW
} // NEW
