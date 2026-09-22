import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_permission.dart';
import 'package:lost_and_found/utils/app_preferences.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:lost_and_found/utils/notification.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  /// Firebase must be initialized inside
  /// the background isolate.
  await Firebase.initializeApp();

  print('======================================');
  print('BACKGROUND FCM MESSAGE RECEIVED');
  print('Message ID: ${message.messageId}');
  print(
    'Title: ${message.notification?.title}',
  );
  print(
    'Body: ${message.notification?.body}',
  );
  print('Data: ${message.data}');
  print('======================================');
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );  // try {
  //   if (Firebase.apps.isEmpty) {
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //   }
  // } on FirebaseException catch (e) {
  //   if (e.code != 'duplicate-app') {
  //     rethrow;
  //   }
  // } catch (e) {
  //   rethrow;
  // }
  await AppPreferences.init();
  await AppPermissions.init();
  await AppNotificationService().init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTab = MediaQuery.of(context).size.shortestSide >= 600;
    AppUtils.isTab = isTab;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(1.0), boldText: false),
      child: MaterialApp.router(
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
      ),
    );
  }
}
