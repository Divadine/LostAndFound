import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_utils.dart';

/// Handles local notification tap when the app is in background.
@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse,
    ) {
  print('======================================');
  print('BACKGROUND NOTIFICATION TAPPED');
  print('Payload: ${notificationResponse.payload}');
  print('======================================');
}

class AppNotificationService {
  static final FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Main notification initialization
  Future<void> init() async {
    // Request notification permission
    await requestPermission();

    // Initialize local notifications
    await initializePlatformNotifications();

    // Listen for foreground notifications
    listenForegroundMessages();

    // Get FCM token
    final String? fcmToken = await messaging.getToken();

    print('======================================');
    print('FCM TOKEN:');
    print(fcmToken);
    print('======================================');

    // iOS APNS token
    if (Platform.isIOS) {
      final String? apnsToken =
      await messaging.getAPNSToken();

      print('======================================');
      print('APNS TOKEN:');
      print(apnsToken);
      print('======================================');
    }
  }

  /// Request Firebase notification permission
  Future<void> requestPermission() async {
    final NotificationSettings settings =
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('======================================');
    print('NOTIFICATION PERMISSION');
    print(settings.authorizationStatus);
    print('======================================');
  }

  /// Listen for notifications while app is open
  void listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        print('======================================');
        print('FOREGROUND FCM MESSAGE RECEIVED');
        print('Message ID: ${message.messageId}');
        print(
          'Title: ${message.notification?.title}',
        );
        print(
          'Body: ${message.notification?.body}',
        );
        print('Data: ${message.data}');
        print('======================================');

        await showNotification(
          message: message,
        );
      },
    );

    /// Called when user taps an FCM notification
    /// while the app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        print('======================================');
        print('FCM NOTIFICATION TAPPED');
        print('Message ID: ${message.messageId}');
        print('Data: ${message.data}');
        print('======================================');

        // Navigate if required.
        //
        // AppRoutes.pushNamed(
        //   AppRoutes.notificationScreen,
        // );
      },
    );
  }

  /// Initialize flutter_local_notifications
  Future<void> initializePlatformNotifications() async {
    const AndroidInitializationSettings
    initializationSettingsAndroid =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
    initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,

      /// Foreground/local notification tap
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        print('======================================');
        print('LOCAL NOTIFICATION TAPPED');
        print('Payload: ${response.payload}');
        print('======================================');

        // Navigate if required.
        //
        // AppRoutes.pushNamed(
        //   AppRoutes.notificationScreen,
        // );
      },

      /// Background notification tap
      onDidReceiveBackgroundNotificationResponse:
      notificationTapBackground,
    );

    /// Android notification channel
    const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
      'lost_and_found_channel',
      'Lost And Found Notifications',
      description:
      'Notifications for Lost And Found application',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show local notification
  Future<void> showNotification({
    required RemoteMessage message,
  }) async {
    final String title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            AppUtils.appName;

    final String body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            '';

    const AndroidNotificationDetails
    androidNotificationDetails =
    AndroidNotificationDetails(
      'lost_and_found_channel',
      'Lost And Found Notifications',
      channelDescription:
      'Notifications for Lost And Found application',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const DarwinNotificationDetails
    iosNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Get FCM token
  Future<String?> token() async {
    if (Platform.isIOS) {
      return await messaging.getAPNSToken();
    }

    return await messaging.getToken();
  }

  /// Get current platform
  String platform() {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return '';
  }
}