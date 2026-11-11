import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';

import 'app_preferences.dart';
import 'app_utils.dart';
import 'device_info_helper.dart';

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
    // Request permission first to ensure token can be fetched on Android 13+ / iOS
    await requestPermission();

    // Initialize local notifications
    await initializePlatformNotifications();

    // Listen for foreground notifications
    listenForegroundMessages();

    // Check launch notification from terminated state
    await checkInitialMessage();

    // Setup and register FCM token
    await setupFcmToken();
  }

  /// Setup FCM token logging and refresh listener
  Future<void> setupFcmToken() async {
    try {
      final String? fcmToken = await messaging.getToken();
      final int? userId = AppPreferences.getUserId();

      print('======================================');
      print('[FCM] Current user ID: ${userId ?? "Not logged in"}');
      print('[FCM] Current token: ${DeviceInfoHelper.maskToken(fcmToken)}');
      print('[FCM] Token registered for user: ${userId ?? "None"}');
      print('======================================');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _updateBackendDeviceToken(fcmToken);
      }

      if (Platform.isIOS) {
        final String? apnsToken = await messaging.getAPNSToken();
        print('[FCM] APNS TOKEN: ${DeviceInfoHelper.maskToken(apnsToken)}');
      }

      // Listen for FCM token refresh
      messaging.onTokenRefresh.listen((String newToken) async {
        final int? currentUserId = AppPreferences.getUserId();
        print('======================================');
        print('[FCM] Token refreshed: ${DeviceInfoHelper.maskToken(newToken)}');
        print('[FCM] Current user ID: ${currentUserId ?? "Not logged in"}');
        print('[FCM] Token registered for user: ${currentUserId ?? "None"}');
        print('======================================');

        if (newToken.isNotEmpty) {
          await _updateBackendDeviceToken(newToken);
        }
      });
    } catch (e) {
      print('[FCM] Error setting up FCM token: $e');
    }
  }

  /// Sends device_id, device_type, and device_token to backend user/update API
  Future<void> _updateBackendDeviceToken(String fcmToken) async {
    try {
      if (fcmToken.isEmpty) {
        print('[FCM] Backend update skipped: FCM token is empty.');
        return;
      }

      final String? authToken = await AppPreferences.getToken();
      if (authToken == null || authToken.isEmpty) {
        print('[FCM] Backend update skipped: Auth token is missing (User not logged in).');
        return;
      }

      final String deviceId = await DeviceInfoHelper.getDeviceId();
      final String deviceType = DeviceInfoHelper.getDeviceType();

      print('[FCM] Sending device info to backend (${ApiEndPoints.updateProfile}):');
      print('[FCM]   device_id: $deviceId');
      print('[FCM]   device_type: $deviceType');
      print('[FCM]   device_token: ${DeviceInfoHelper.maskToken(fcmToken)}');

      final formData = dio.FormData.fromMap({
        'device_id': deviceId,
        'device_type': deviceType,
        'device_token': fcmToken,
      });

      final ApiClient apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndPoints.updateProfile,
        data: formData,
        addToken: true,
      );

      print('[FCM] user/update Response: status=${response.status}, message=${response.message}, data=${response.data}');
    } catch (e) {
      print('[FCM] Exception while updating backend device token: $e');
    }
  }

  /// Check if app was launched from a terminated state via a notification tap
  Future<void> checkInitialMessage() async {
    try {
      final RemoteMessage? initialMessage =
          await messaging.getInitialMessage();

      if (initialMessage != null) {
        print('======================================');
        print('[FCM] APP LAUNCHED FROM TERMINATED STATE VIA NOTIFICATION');
        print('Message ID: ${initialMessage.messageId}');
        print('Title: ${initialMessage.notification?.title}');
        print('Body: ${initialMessage.notification?.body}');
        print('Data: ${initialMessage.data}');
        print('======================================');
      }
    } catch (e) {
      print('[FCM] Error checking initial message: $e');
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
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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
  }

  /// Show local notification
  Future<void> showNotification({
    required RemoteMessage message,
  }) async {
    if (!AppPreferences.getUserNotificationSetting()) {
      return;
    }

    final String title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            AppUtils.appName;

    final String body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            message.data['description']?.toString() ??
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