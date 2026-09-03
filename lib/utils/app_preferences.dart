
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

  static const String _profileStatus = 'profile_status';

  static Future<bool> setProfileStatus(int status) async {
    return _prefs.setInt(_profileStatus, status);
  }

  static int getProfileStatus() {
    return _prefs.getInt(_profileStatus) ?? 0;
  }

  static const String _askedDeviceLocationService = 'asked_device_location_service_before';

  static Future<bool> setAskedDeviceLocationService(bool asked) async {
    return _prefs.setBool(_askedDeviceLocationService, asked);
  }

  static bool getAskedDevicePermissionService() {
    return _prefs.getBool(_askedDeviceLocationService) ?? false;
  }

  static const String _askedAppLocationPermission = 'asked_app_location_permission_before';

  static Future<bool> setAskedAppLocationPermission(bool asked) {
    return _prefs.setBool(_askedAppLocationPermission, asked);
  }

  static bool getAskedAppLocationPermission(){
    return _prefs.getBool(_askedAppLocationPermission) ?? false ;
  }


  static Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_phoneKey);
    await _prefs.remove(_isItemPosted);
    await _prefs.setInt(_profileStatus, 0);

    await _prefs.setBool(
      _isLoggedIn,
      false,
    );
  }



  static const String _tokenKey = "access_token";

  static Future<void> saveToken(String token) async {
    //final prefs = await SharedPreferences.getInstance();
    await _prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    //final prefs = await SharedPreferences.getInstance();
    return _prefs.getString(_tokenKey);
  }


  static Future<void> clearToken() async {
    //final prefs = await SharedPreferences.getInstance();
    await _prefs.remove(_tokenKey);
  }

  static const String _userIdKey = "user_id";

  static Future<void> saveUserId(int userId) async {
    await _prefs.setInt(_userIdKey, userId);
  }

  static int? getUserId() {
    return _prefs.getInt(_userIdKey);
  }

  static const String _phoneKey = "phone_no";

  static Future<void> savePhone(String phone) async {
    await _prefs.setString(_phoneKey, phone);
  }

  static String? getPhone() {
    return _prefs.getString(_phoneKey);
  }

  // NEW: user name storage
  static const String _userNameKey = "user_name";

  static Future<void> saveUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  static String? getUserName() {
    return _prefs.getString(_userNameKey);
  }

  static Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_phoneKey);
    await _prefs.setBool(_isLoggedIn, false);
    // await _prefs.clear();
  }

  static const String _lastAuthScreen = 'last_auth_screen';

  static Future<bool> setLastAuthScreen(String screen) async {
    return _prefs.setString(_lastAuthScreen, screen);
  }

  static String? getLastAuthScreen() {
    return _prefs.getString(_lastAuthScreen);
  }

  static const String _isItemPosted = 'is_item_posted';

  static Future<bool> setIsItemPosted(bool isPosted) async {
    return _prefs.setBool(_isItemPosted, isPosted);
  }

  static bool getIsItemPosted() {
    return _prefs.getBool(_isItemPosted) ?? false;
  }
}