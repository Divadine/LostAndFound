import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns "Android" or "iOS"
  static String getDeviceType() {
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    return "Unknown";
  }
  //
  // static Future<String> getDeviceId() async {
  //
  //   String? deviceId;
  //   deviceId = const Uuid().v4();
  //   print("+++++++++++++++++++++++");
  //   print(deviceId);
  //   return deviceId;
  // }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    const key = 'device_id';

    String? deviceId = prefs.getString(key);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();

      await prefs.setString(key, deviceId);

      print("New device ID generated: $deviceId");
    } else {
      print("Existing device ID: $deviceId");
    }

    return deviceId;
  }


  /// Returns FCM push notification token
  static Future<String> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("====> token $token");
      return token ?? "no_token_available";
    } catch (e) {
      return "no_token_available";
    }
  }

  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}