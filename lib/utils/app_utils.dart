
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppUtils {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool isTab = false;

  static int? lastSubmittedPostType;
  static final ValueNotifier<int> postRefreshNotifier = ValueNotifier<int>(0);

  static Future<bool> checkConnectivity() async {
    final value = await Connectivity().checkConnectivity();
    if (value.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  static String formatTimeAgo(DateTime? date) {
    if (date == null) return '';

    // Step 1: Handle date-only fields (midnight)
    // If time is exactly 00:00:00, it's likely a date-only field from the server.
    // Showing "X hours ago" for a date-only field is confusing (e.g. 14 hours ago since midnight).
    if (date.hour == 0 && date.minute == 0 && date.second == 0) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final postDate = DateTime(date.year, date.month, date.day);
      final diffDays = today.difference(postDate).inDays;

      if (diffDays == 0) return 'Today';
      if (diffDays == 1) return 'Yesterday';
      return DateFormat('d MMM yyyy').format(date);
    }

    // Step 2: Handle relative time for fields with actual time data
    final nowUtc = DateTime.now().toUtc();
    final postDateUtc = date.isUtc
        ? date
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
            date.hour,
            date.minute,
            date.second,
            date.millisecond,
            date.microsecond,
          );

    Duration difference = nowUtc.difference(postDateUtc);

    if (difference.isNegative) {
      difference = Duration.zero;
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months != 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years != 1 ? 's' : ''} ago';
    }
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter mobile number";
    }

    if (value.length != 10) {
      return "Mobile number must be 10 digits";
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
      return "Enter valid mobile number";
    }

    return null;
  }


  static String? validateName(String? value) {

    if (value == null || value.trim().isEmpty) {
      return "Please enter your name";
    }


    if (value.trim().length < 3) {
      return "Name must contain at least 3 characters";
    }


    if (value.trim().length > 30) {
      return "Name cannot exceed 30 characters";
    }


    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return "Only letters and spaces are allowed";
    }


    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter PIN code';
    }

    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
      return 'Enter a valid 6-digit PIN code';
    }

    return null;
  }

  static String? required(
      String? value, ) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static Color getMatchColor(int percentage) {
    if (percentage == 100) {
      return AppColors.green;
    } else if (percentage >= 80) {
      return AppColors.lavender;
    } else if (percentage >= 60) {
      return AppColors.percentageBlue;
    } else if (percentage >= 40) {
      return AppColors.percentageOrange;
    } else {
      return AppColors.percentageGrey;
    }
  }
}

