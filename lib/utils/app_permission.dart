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
    if (await Permission.camera.isGranted) return true;

    if (getCameraPref() == null) {
      await Permission.camera.request();
      await setCameraPref(true);
    } else {
      await goToDeviceSettings(context, cameraPermissionContent);
    }

    return await Permission.camera.isGranted;
  }

  // Future<bool> requestCameraPermission(BuildContext context) async {
  //   final status = await Permission.camera.status;
  //
  //   if (status.isGranted) return true;
  //
  //   if (status.isDenied) {
  //     final req = await Permission.camera.request();
  //     return req.isGranted;
  //   }
  //
  //   if (status.isPermanentlyDenied || status.isRestricted) {
  //     await goToDeviceSettings(context, cameraPermissionContent);
  //     return await Permission.camera.isGranted;
  //   }
  //
  //   return false;
  // }


  // -------- Storage / Photos --------
  static bool? getStoragePref() => _prefs.getBool(_storageKey);
  static Future<void> setStoragePref(bool val) => _prefs.setBool(_storageKey, val);

  Future<void> requestStoragePermission(BuildContext context) async {
    final version = await getVersion();
    final storagePref = getStoragePref();
    late Permission permission;

    if (Platform.isAndroid) {
      permission = version >= 13 ? Permission.photos : Permission.storage;
    } else if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      return;
    }

    final status = await permission.status;

    if (status.isGranted) {
      await setStoragePref(true);
      return;
    }

    if (storagePref == null) {
      await permission.request();
      await setStoragePref(true);
    } else {
      await goToDeviceSettings(
        context,
        storagePermissionContent,
      );
    }
  }

  // -------- Microphone --------
  static bool? getMicPref() => _prefs.getBool(_microphoneKey);
  static Future<void> setMicPref(bool val) => _prefs.setBool(_microphoneKey, val);
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    if (await Permission.microphone.isGranted) return true;

    if (getMicPref() == null) {
      await Permission.microphone.request();
      await setMicPref(true);
    } else {
      await goToDeviceSettings(context, micPermissionContent);
    }
    return await Permission.microphone.isGranted;
  }

  // -------- Notifications --------
  static bool? getNotificationPref() => _prefs.getBool(_notificationKey);
  static Future<void> setNotificationPref(bool val) => _prefs.setBool(_notificationKey, val);

  Future<bool> requestNotificationPermission(BuildContext context) async {
    if (await Permission.notification.isGranted) return true;

    if (getNotificationPref() == null) {
      await Permission.notification.request();
      await setNotificationPref(true);
    } else {
      await goToDeviceSettings(context, notificationPermissionContent);
    }
    return await Permission.notification.isGranted;
  }

  // -------- Location --------
  static bool? getLocationPref() => _prefs.getBool(_locationKey);
  static Future<void> setLocationPref(bool val) => _prefs.setBool(_locationKey, val);

  Future<bool> requestLocationPermission(BuildContext context) async {
    if (await Permission.location.isGranted){
      return true;
    };

    if (getLocationPref() == null) {
      final status = await Permission.location.request();
      if (status.isGranted) {
        await setLocationPref(true);
      } else {
        await setLocationPref(false);


      }
    } else {
      await locationPermission(context);
      // await goToDeviceSettings(context, locationPermissionContent);
    }
    return await Permission.location.isGranted;
  }


  locationPermission(BuildContext context) async {
    await AppDialogue.showPopup(content: Column(
        children: [
          Image.asset(AssetImages.location,height: 100,width: 100,),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              spacing: 10,
              children: [
                AppText(text:
                "Enable your Location",
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                ),

                AppText(text:
                  "Location access is required to show nearby toilets. Please enable it in your device settings.",
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: AppColors.grey,
                  textAlign: TextAlign.center,
                ),
                SizedBox(),
                AppButton(onTap: ()async{
                  if (await Permission.location.isGranted){
                    Navigator.pop(context);
                    return;
                  };
                  await openAppSettings();
                }, title: 'Enable location', ),
                SizedBox(),
              ],
            ),
          ),

        ],
      ), context: context,
    );
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      print("⚠️ Error checking location service: $e");
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
  Future<void> goToDeviceSettings(BuildContext context, String message) async {
    await AppDialogue.showPopup(
       context: context,
        content: ListView(
          shrinkWrap: true,
          children: [
            AppText(text: 'Permission Required', fontWeight: FontWeight.bold, fontSize:18, textAlign: TextAlign.center,),
            SizedBox(height: 20,),
            AppText(text: message, fontSize:16, textAlign: TextAlign.center,),
          ],
        ),
        // noText: 'Close',
        // yesText: 'Open settings',
        // onConfirm: ()async{
        //   Navigator.pop(context);
        //   await Future.delayed(Duration(milliseconds: 300));
        //   await openAppSettings();
        // }
        );

  }
}


