import 'dart:io';

class AppUrls {
  static final String rateUs = Platform.isAndroid
      ? 'https://play.google.com/store/apps/details?id=com.findora.lostandfound'
      : 'https://apps.apple.com/app/id$appStoreId';

  static const String aboutUsURL =
      'https://miraxtechnologies.com/aboutus/webview/main.html';
  static const String feedBackURL =
      'https://skyraanapps.com/m_feedback/API/feedback_form/index.php';
  static const String privacyPolicyLink =
      'https://findora.skyraantechnologies.com/privacy_policy.html';
  static const String termsAndConditions =
      'https://findora.skyraantechnologies.com/terms_and_conditions.html';
  static const String disclaimer =
      'https://findora.skyraantechnologies.com/disclaimer.html';
  static const String copyRights =
      'https://www.newsraan.com/backend/copyright.html';

  static String bannerAdUnitId = '';

  //'ca-app-pub-3940256099942544/9214589741';
  static String interstitialAdUnitId = '';

  //'ca-app-pub-3940256099942544/1033173712';
  static String openAdUnitId = '';

  //'ca-app-pub-3940256099942544/9257395921';

  static bool isInterstitialShowing = false;

  static String appStoreId = '6779589172';
  static const String googleMap =
      "https://www.google.com/maps/search/?api=1&query=";
}
