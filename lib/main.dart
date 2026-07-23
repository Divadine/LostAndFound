import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRoutes.router,

      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle:SystemUiOverlayStyle(
            statusBarColor: AppColors.primaryColor
          )
        )
      ),
      title: 'LostAndFound',
      debugShowCheckedModeBanner: false,
    );
  }
}
