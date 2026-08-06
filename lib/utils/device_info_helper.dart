import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns "Android" or "iOS"
  static String getDeviceType() {
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    return "Unknown";
  }

  static Future<String> getDeviceId() async {

    String? deviceId;
    deviceId = const Uuid().v4();
    print("+++++++++++++++++++++++");
    print(deviceId);
    return deviceId;
  }


  /// Returns FCM push notification token
  static Future<String> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? "no_token_available";
    } catch (e) {
      return "no_token_available";
    }
  }

  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // e.g. "1.0.0"
  }
}