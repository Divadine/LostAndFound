class ApiEndPoints {
  ApiEndPoints._();

  static const String baseUrl = "https://lost-and-found.skyraantech.com/backend/";

  //auth
  static const String generateOtp = 'user/generateOtp';
  static const String verifyOtp = 'user/verifyOtp';
  static const String generateMobileOtp = 'user/generateMobileOtp';
  static const String verifyMobileOtp = 'user/verifyMobileOtp';
  static const String getAddressByPincode = 'user/getAddressByPincode';

  //profile
  static const String updateProfile = 'user/update';
  static const String getUserInfo = 'user/getUserInfo';

  //category
  static const String getCategory = 'categories/getCategory';

  //sub-category
  static const String getSubCategory = 'subcategories/getSubCategory';
  static const String getDynamicFields = 'subcategories/getDynamicFields';









}