
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static late SharedPreferences _prefs;

  static Future<void> init() async {

    _prefs = await SharedPreferences.getInstance();

  }

  static const String _isOnboarded = 'onboard';

  static Future<bool> setIsOnboarded(bool isOnBoard) async {

    return _prefs.setBool(_isOnboarded, isOnBoard);

  }

  static bool getIsOnboarded() {

    return _prefs.getBool(_isOnboarded) ?? false;

  }


  static const String _isLoggedIn= 'login';

  static Future<bool> setIsLoggedIn(bool isLogin) async {

    return _prefs.setBool(_isLoggedIn, isLogin);

  }

  static bool getIsLoggedIn() {

    return _prefs.getBool(_isLoggedIn) ?? false;

  }



}