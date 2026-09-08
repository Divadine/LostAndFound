import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_images.dart';


class AppPermissions {
  static late SharedPreferences _prefs;
  static late DeviceInfoPlugin deviceInfo;
  static late PackageInfo packageInfo;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    deviceInfo = DeviceInfoPlugin();
    packageInfo = await PackageInfo.fromPlatform();
  }

  // -------- Open Settings content --------
  static String storagePermissionContent      = 'Please enable photo library access in settings to manage documents.';
  static String cameraPermissionContent       = 'Enable camera to capture photos for your review.';
  static String notificationPermissionContent = 'Enable notification permission for alerts.';
  static String micPermissionContent          = 'Microphone permission is needed to record audio.';
  static String locationPermissionContent     = 'Enable Location permission.';

  // Permission keys
  static String get _cameraKey => 'cameraPermission_${packageInfo.appName}_pref_key';
  static String get _storageKey => 'storagePermission_${packageInfo.appName}_pref_key';
  static String get _notificationKey => 'notificationPermission_${packageInfo.appName}_pref_key';
  static String get _microphoneKey => 'microphonePermission_${packageInfo.appName}_pref_key';
  static String get _locationKey => 'locationPermission_${packageInfo.appName}_pref_key';

  // -------- Camera --------
  static bool? getCameraPref() => _prefs.getBool(_cameraKey);
  static Future<void> setCameraPref(bool val) => _prefs.setBool(_cameraKey, val);

  Future<bool> requestCameraPermission(BuildContext context) async {
    return _handlePermission(
      context: context,
      permission: Permission.camera,
      prefKey: _cameraKey,
      content: cameraPermissionContent,
    );
  }

  // -------- Storage / Photos --------
  static bool? getStoragePref() => _prefs.getBool(_storageKey);
  static Future<void> setStoragePref(bool val) => _prefs.setBool(_storageKey, val);

  Future<bool> requestStoragePermission(BuildContext context) async {
    final version = await getVersion();
    late Permission permission;

    if (Platform.isAndroid) {
      permission = version >= 13 ? Permission.photos : Permission.storage;
    } else if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      return false;
    }

    return _handlePermission(
      context: context,
      permission: permission,
      prefKey: _storageKey,
      content: storagePermissionContent,
    );
  }

  // -------- Microphone --------
  static bool? getMicPref() => _prefs.getBool(_microphoneKey);
  static Future<void> setMicPref(bool val) => _prefs.setBool(_microphoneKey, val);

  Future<bool> requestMicrophonePermission(BuildContext context) async {
    return _handlePermission(
      context: context,
      permission: Permission.microphone,
      prefKey: _microphoneKey,
      content: micPermissionContent,
    );
  }

  // -------- Notifications --------
  static bool? getNotificationPref() => _prefs.getBool(_notificationKey);
  static Future<void> setNotificationPref(bool val) => _prefs.setBool(_notificationKey, val);

  Future<bool> requestNotificationPermission(BuildContext context) async {
    return _handlePermission(
      context: context,
      permission: Permission.notification,
      prefKey: _notificationKey,
      content: notificationPermissionContent,
    );
  }

  // -------- Location --------
  static bool? getLocationPref() => _prefs.getBool(_locationKey);
  static Future<void> setLocationPref(bool val) => _prefs.setBool(_locationKey, val);

  Future<bool> requestLocationPermission(BuildContext context) async {
    return _handlePermission(
      context: context,
      permission: Permission.location,
      prefKey: _locationKey,
      content: locationPermissionContent,
      customPopup: const LocationPermissionPopup(),
    );
  }

  Future<bool> _handlePermission({
    required BuildContext context,
    required Permission permission,
    required String prefKey,
    required String content,
    Widget? customPopup,
  }) async {
    final status = await permission.status;
    if (status.isGranted) return true;

    final askedBefore = _prefs.getBool(prefKey) ?? false;

    if (!askedBefore) {
      // First time — show native dialog
      final newStatus = await permission.request();
      await _prefs.setBool(prefKey, true);

      if (newStatus.isGranted) return true;

      // If user denied the native dialog, show custom popup
      if (newStatus.isDenied || newStatus.isPermanentlyDenied) {
        if (!context.mounted) return false;
        if (customPopup != null) {
          await AppDialogue.showPopup(context: context, content: customPopup);
        } else {
          await goToDeviceSettings(context, content, permission);
        }
      }
    } else {
      // Already asked once — show custom popup directly
      if (!context.mounted) return false;
      if (customPopup != null) {
        await AppDialogue.showPopup(context: context, content: customPopup);
      } else {
        await goToDeviceSettings(context, content, permission);
      }
    }

    return await permission.isGranted;
  }

  locationPermission(BuildContext context) async {
    await AppDialogue.showPopup(
      content: const LocationPermissionPopup(),
      context: context,
    );
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      // print("⚠️ Error checking location service: $e");
      return false;
    }
  }

  // -------- Device Info --------
  Future<int> getVersion() async {
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return int.parse(info.version.release.split('.').first);
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return int.parse(info.systemVersion.split('.').first);
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<int> getAndroidSdkInt() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  // -------- Open App Settings Dialog --------
  Future<void> goToDeviceSettings(BuildContext context, String message, Permission permission) async {
    await AppDialogue.showPopup(
      context: context,
      content: CommonPermissionPopup(
        message: message,
        permission: permission,
      ),
    );
  }
}

class CommonPermissionPopup extends StatefulWidget {
  final String message;
  final Permission permission;

  const CommonPermissionPopup({
    super.key,
    required this.message,
    required this.permission,
  });

  @override
  State<CommonPermissionPopup> createState() => _CommonPermissionPopupState();
}

class _CommonPermissionPopupState extends State<CommonPermissionPopup> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    if (await widget.permission.isGranted) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppText(
          text: 'Permission Required',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AppText(
          text: widget.message,
          fontSize: 16,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),
        AppButton(
          title: 'Enable',
          onTap: () async {
            await openAppSettings();
          },
        ),
      ],
    );
  }
}



class LocationPermissionPopup extends StatefulWidget {
  const LocationPermissionPopup({super.key});

  @override
  State<LocationPermissionPopup> createState() => _LocationPermissionPopupState();
}

class _LocationPermissionPopupState extends State<LocationPermissionPopup> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    if (await Permission.location.isGranted) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AssetImages.mapAccess),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            spacing: 10,
            children: [
              const AppText(
                text: "Enable your Location",
                fontSize: 20,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
              ),
              const AppText(
                text: "Location access is required to show nearby Police Stations. Please enable it in your device settings.",
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: AppColors.grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(),
              AppButton(
                onTap: () async {
                  if (await Permission.location.isGranted) {
                    if (mounted) Navigator.pop(context);
                    return;
                  }
                  await openAppSettings();
                },
                title: 'Enable location',
              ),
              const SizedBox(),
            ],
          ),
        ),
      ],
    );
  }
}
