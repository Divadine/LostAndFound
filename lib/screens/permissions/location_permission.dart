import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_preferences.dart';

class AppLocationPermission {
  Future<bool> requestLocationPermission(BuildContext context) async {
    // Permission first: native OS dialog → our AppLocationAccess popup
    final permissionGranted = await _ensureLocationPermission(context);
    if (!permissionGranted) return false;

    // Only once permission is granted, check if GPS/location service is on
    return _ensureLocationServiceEnabled(context);
  }

  Future<bool> _ensureLocationServiceEnabled(BuildContext context) async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    if (enabled) return true;

    if (!context.mounted) return false;

    await AppDialogue.showPopup(
      context: context,
      content: const DeviceLocationAccess(),
    );

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

    final askedBefore = AppPreferences.getAskedAppLocationPermission();

    if (!askedBefore) {
      // First time ever — let the OS show its native default popup.
      await AppPreferences.setAskedAppLocationPermission(true);
      permission = await geo.Geolocator.requestPermission();

      if (permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always) {
        return true;
      }

      // First-time deny via the SYSTEM dialog — don't show our popup yet.
      return false;
    } else {
      // Second+ time — show our own popup directly
      await AppDialogue.showPopup(
        context: context,
        content: const AppLocationAccess(),
      );
    }

    permission = await geo.Geolocator.checkPermission();
    return permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always;
  }
}





















// import 'package:flutter/cupertino.dart';
// import 'package:geolocator/geolocator.dart' as geo;
// import 'package:lost_and_found/utils/app_dialog.dart';
// import 'package:lost_and_found/utils/app_preferences.dart';
//
// class AppLocationPermission {
//   Future<bool> requestLocationPermission(BuildContext context) async {
//     final serviceEnabled = await _ensureLocationServiceEnabled(context);
//     if (!serviceEnabled) return false;
//
//     return _ensureLocationPermission(context);
//   }
//
//   Future<bool> _ensureLocationServiceEnabled(BuildContext context) async {
//     final enabled = await geo.Geolocator.isLocationServiceEnabled();
//     if (enabled) return true;
//
//     if (!context.mounted) return false;
//
//     // Always show our popup first. Its own "Enable" button is what
//     // takes the user to system settings — this method never should.
//     await AppDialogue.showPopup(
//       context: context,
//       content: const DeviceLocationAccess(),
//     );
//
//     await Future.delayed(const Duration(milliseconds: 300));
//     return geo.Geolocator.isLocationServiceEnabled();
//   }
//
//   Future<bool> _ensureLocationPermission(BuildContext context) async {
//     var permission = await geo.Geolocator.checkPermission();
//
//     if (permission == geo.LocationPermission.whileInUse ||
//         permission == geo.LocationPermission.always) {
//       return true;
//     }
//
//     if (!context.mounted) return false;
//
//     final askedBefore = AppPreferences.getAskedAppLocationPermission();
//
//     if (!askedBefore) {
//       // First time ever — let the OS show its native default popup.
//       await AppPreferences.setAskedAppLocationPermission(true);
//       permission = await geo.Geolocator.requestPermission();
//
//       if (permission == geo.LocationPermission.whileInUse ||
//           permission == geo.LocationPermission.always) {
//         return true;
//       }
//
//       // First-time deny via the SYSTEM dialog — don't show our popup yet.
//       return false;
//     } else {
//       // Second+ time — show our own popup directly
//       await AppDialogue.showPopup(
//         context: context,
//         content: const AppLocationAccess(),
//       );
//     }
//
//     permission = await geo.Geolocator.checkPermission();
//     return permission == geo.LocationPermission.whileInUse ||
//         permission == geo.LocationPermission.always;
//   }
// }