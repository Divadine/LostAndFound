
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class AppUtils {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  static Future<bool> checkConnectivity() async {
    final value = await Connectivity().checkConnectivity();
    if (value.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
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
      return AppColors.percentageOrange; // Orange
    } else {
      return AppColors.percentageGrey; // Grey
    }
  }
}

