import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Masks sensitive tokens for debug logging
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    if (token.length <= 10) return '****';
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }

  /// Returns "Android" or "iOS"
  static String getDeviceType() {
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    return "Unknown";
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_id';
    String? deviceId = prefs.getString(key);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(key, deviceId);
      debugPrint("New device ID generated: $deviceId");
    } else {
      debugPrint("Existing device ID: $deviceId");
    }

    return deviceId;
  }

  /// Returns FCM push notification token (masked in logs)
  static Future<String> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint("[FCM TOKEN] Token generated: ${maskToken(token)}");
        return token;
      }
      debugPrint("[FCM TOKEN] Token is null or empty");
      return "";
    } catch (e) {
      debugPrint("[FCM TOKEN] Error fetching FCM token: $e");
      return "";
    }
  }

  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
