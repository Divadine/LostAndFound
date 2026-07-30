import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';

class AppLocationPermission {
  Future<bool> requestLocationPermission(BuildContext context) async {
    final serviceEnabled = await _ensureLocationServiceEnabled(context);
    if (!serviceEnabled) return false;

    return _ensureLocationPermission(context);
  }

  Future<bool> _ensureLocationServiceEnabled(BuildContext context) async {


    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    if (enabled) return true;

    final askedBefore = AppPreferences.getAskedDevicePermissionService();
    if (!context.mounted) return false;

    if(!askedBefore){
      await AppPreferences.setAskedDeviceLocationService(true);
      await geo.Geolocator.openLocationSettings();
    }else {
      await AppDialogue.showPopup(context: context, content: DeviceLocationAccess());

    }

    await Future.delayed(const Duration(milliseconds: 300));
    return geo.Geolocator.isLocationServiceEnabled();
  }



  Future<bool> _ensureLocationPermission(BuildContext context) async {
    var permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always) {
      return true;
    }

    if (!context.mounted) return false;

    if (permission == geo.LocationPermission.deniedForever) {
      await AppDialogue.showPopup(
        context: context,
        content: AppLocationAccess(),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      permission = await geo.Geolocator.checkPermission();
      return permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always;
    }

    // permission == denied (never asked, or asked-and-declined-but-askable)
    final askedBefore = AppPreferences.getAskedAppLocationPermission();

    if (!askedBefore) {
      // First time ever — let the OS show its native default popup.
      await AppPreferences.setAskedAppLocationPermission(true);
      permission = await geo.Geolocator.requestPermission();
    } else {
      // Second+ time — show our own popup first, before touching the OS
      // prompt again.
      await AppDialogue.showPopup(
        context: context,
        content: AppLocationAccess(),
      );
      permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
    }

    return permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always;
  }


}