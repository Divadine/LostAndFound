import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

//-------------------------------------------------------------------------------------------------------------------------------------------------------

enum WebViewType { feedback, privacyPolicy, termsAndConditions, aboutUs }

class WebViewModel {
  CustomAppBar appbar;
  String link;
  Color backgroundColor;
  Color primaryColor;
  bool isGenerateUrl;
  String themeColor;
  String themeMode;
  WebViewType? webViewType;

  WebViewModel({
    required this.appbar,
    required this.link,
    required this.isGenerateUrl,
    this.backgroundColor = Colors.white,
    this.primaryColor = Colors.blue,
    this.themeColor = '#1B3C63',
    this.themeMode = '#1B3C63',
    this.webViewType,
  });

  factory WebViewModel.fromJson(Map<String, dynamic> json) {
    return WebViewModel(
      appbar: json['appbar'],
      link: json['link'],
      isGenerateUrl: json['isGenerateUrl'],
      backgroundColor: json['backgroundColor'],
      primaryColor: json['primaryColor'],
      themeColor: json['themeColor'],
      themeMode: json['themeMode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appbar': appbar,
      'link': link,
      'isGenerateUrl': isGenerateUrl,
      'backgroundColor': backgroundColor,
      'primaryColor': primaryColor,
      'themeColor': themeColor,
      'themeMode': themeMode,
    };
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------

class WebViewScreen extends StatefulWidget {
  final WebViewModel model;

  const WebViewScreen({super.key, required this.model});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final WebViewController _ctrl = WebViewController();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  Sink<bool> get connectionSink => _connectionController.sink;

  int _progress = 0;
  bool isConnected = true;
  bool _initNav = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _connectionController.close();
    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
    _ctrl.setNavigationDelegate(NavigationDelegate());
    super.dispose();
  }

  Future<void> _checkConnection() async {
    isConnected = await AppUtils.checkConnectivity();
    connectionSink.add(isConnected);
  }

  Future<void> _init() async {
    await _checkConnection();
    await _bindData();
    _ctrl.enableZoom(false);
    _ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
    _ctrl.setBackgroundColor(AppColors.white);
    _ctrl.setNavigationDelegate(
      Platform.isIOS ? _iosNavigationDelegate() : _navigationDelegate(),
    );
    if (widget.model.link == AppUrls.aboutUsURL) {
      _ctrl.loadRequest(Uri.parse(_generateUrlAboutUs()));
    } else if (widget.model.link == AppUrls.feedBackURL) {
      _ctrl.loadRequest(Uri.parse(_generateUrl()));
    } else {
      final url = widget.model.link;
      _ctrl.loadRequest(Uri.parse(url));
    }
    // final url = widget.model.isGenerateUrl ? _generateUrl() : widget.model.link;
    // _ctrl.loadRequest(Uri.parse(url));
    await _initFilePicker();
  }

  NavigationDelegate _navigationDelegate() {
    if (widget.model.webViewType == WebViewType.feedback) {
      print("Feedback");
      return NavigationDelegate(
        onProgress: (val) {
          _progress = val;
          connectionSink.add(true);
        },
      );
    }
    print("Not Feedback");
    return NavigationDelegate(
      onProgress: (val) {
        _progress = val;
      },

      onNavigationRequest: (request) {
        final url = request.url;
        final uri = Uri.parse(url);
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },

      onPageStarted: (url) {
        if (kDebugMode) {
          print("Page started loading: $url");
        }
        _progress = 0;
        connectionSink.add(true);
      },
      onPageFinished: (url) {
        if (kDebugMode) {
          print("Page finished loading: $url");
        }
        _progress = 100;
        connectionSink.add(true);
      },
      onWebResourceError: (error) {
        if (kDebugMode) {
          print(
            "WebView Error: ${error.description} (Code: ${error.errorCode}, Type: ${error.errorType}) for URL: ${error.url}",
          );
        }
        if (mounted) {
          _progress = 0;
        }
        connectionSink.add(false);
      },
      onUrlChange: (change) {
        if (kDebugMode) {
          print("URL changed to: ${change.url}");
        }
      },
    );
  }

  NavigationDelegate _iosNavigationDelegate() {
    return NavigationDelegate(
      onProgress: (progress) {
        _progress = progress;
        connectionSink.add(true);
      },

      onNavigationRequest: (request) {
        final url = request.url;
        final uri = Uri.parse(url);

        // Allow http/https normally
        if (uri.scheme == "http" || uri.scheme == "https") {
          return NavigationDecision.navigate;
        }

        // Handle external links safely on iOS
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },

      onPageStarted: (url) {
        _progress = 0;
        connectionSink.add(true);
      },

      onPageFinished: (url) {
        _progress = 100;
        connectionSink.add(true);
      },

      onWebResourceError: (_) {
        _progress = 0;
        connectionSink.add(false);
      },
    );
  }

  // NavigationDelegate _navigationDelegate() {
  //   if (widget.model.webViewType == WebViewType.feedback) {
  //     return NavigationDelegate(
  //       onProgress: (val) {
  //         _progress = val;
  //         connectionSink.add(true);
  //       },
  //     );
  //   }
  //
  //
  //   return NavigationDelegate(
  //     onProgress: (val) {
  //       _progress = val;
  //     },
  //     onNavigationRequest: (request) {
  //       if (_initNav) return NavigationDecision.navigate;
  //       if (request.url.startsWith('mailto:')) {
  //         final Uri emailLaunchUri = Uri.parse(request.url);
  //         launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
  //         return NavigationDecision.prevent;
  //       }
  //
  //       if (request.url.startsWith('tel:')) {
  //         final Uri telLaunchUri = Uri.parse(request.url);
  //         launchUrl(telLaunchUri, mode: LaunchMode.externalApplication);
  //         return NavigationDecision.prevent;
  //       }
  //
  //       // if (request.url.startsWith('http://') ||
  //       //     request.url.startsWith('https://')) {
  //       //   launchUrl(
  //       //     Uri.parse(request.url),
  //       //     mode: LaunchMode.externalApplication,
  //       //   );
  //       //   return NavigationDecision.prevent;
  //       // }
  //
  //       if (kDebugMode) {
  //         print("Blocking navigation for unsupported scheme: ${request.url}");
  //       }
  //       return NavigationDecision.navigate;
  //     },
  //
  //     // onNavigationRequest: (request) {
  //     //   final url = request.url;
  //     //   final uri = Uri.parse(url);
  //     //   launchUrl(uri, mode: LaunchMode.externalApplication);
  //     //   return NavigationDecision.prevent;
  //     // },
  //
  //     // onNavigationRequest: (request) {
  //     //   if (request.url.startsWith('mailto:')) {
  //     //     final Uri emailLaunchUri = Uri.parse(request.url);
  //     //     launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
  //     //     return NavigationDecision.prevent;
  //     //   }
  //     //
  //     //   if (request.url.startsWith('tel:')) {
  //     //     final Uri telLaunchUri = Uri.parse(request.url);
  //     //     launchUrl(telLaunchUri, mode: LaunchMode.externalApplication);
  //     //     return NavigationDecision.prevent;
  //     //   }
  //     //
  //     //   if (request.url.startsWith('http://') ||
  //     //       request.url.startsWith('https://')) {
  //     //     return NavigationDecision.navigate;
  //     //   }
  //     //
  //     //   if (kDebugMode) {
  //     //     print("Blocking navigation for unsupported scheme: ${request.url}");
  //     //   }
  //     //   return NavigationDecision.prevent;
  //     // },
  //     onPageStarted: (url) {
  //       if (kDebugMode) {
  //         print("Page started loading: $url");
  //       }
  //       _progress = 0;
  //       connectionSink.add(true);
  //     },
  //     onPageFinished: (url) {
  //       if (kDebugMode) {
  //         print("Page finished loading: $url");
  //       }
  //       _progress = 100;
  //       connectionSink.add(true);
  //     },
  //     onWebResourceError: (error) {
  //       if (kDebugMode) {
  //         print(
  //           "WebView Error: ${error.description} (Code: ${error.errorCode}, Type: ${error.errorType}) for URL: ${error.url}",
  //         );
  //       }
  //       if (mounted) {
  //         _progress = 0;
  //       }
  //       connectionSink.add(false);
  //     },
  //     onUrlChange: (change) {
  //       if (kDebugMode) {
  //         print("URL changed to: ${change.url}");
  //       }
  //     },
  //   );
  // }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> _initFilePicker() async {
    if (Platform.isAndroid) {
      final androidController = _ctrl.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    final picker = ImagePicker();
    final files = await picker.pickMedia();
    return files == null ? [] : [Uri.file(files.path).toString()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.model.backgroundColor,
      appBar: widget.model.appbar,
      body: SafeArea(
        child: StreamBuilder<bool>(
          stream: connectionStream,
          initialData: true,
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isConnected)
                  Expanded(
                    child: AppText(text: "No Internet"),
                    // NoInternet(
                    //   tryAgain: () {
                    //     _init();
                    //   },
                    // ),
                  )
                else
                  Expanded(
                    child: _progress < 100
                        ? Center(
                            child: Platform.isIOS
                                ? CupertinoActivityIndicator(
                                    color: AppColors.primaryColor,
                                  )
                                : CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                            ),
                            child: WebViewWidget(controller: _ctrl),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _deviceId = '';
  String _deviceName = '';
  String _deviceType = '';
  String _groupId = '78';
  String _deviceModel = '';
  String _appVersion = '';
  String _osVersion = '';
  String _appName = '';
  String _apptype = '';
  String _packageName = '';
  String _language = '';
  String _countryCode = '';
  String _isDevOrProd = '';
  String _themeColor = '';
  String _themeMode = '';

  String _getDeviceUUID(String deviceId) {
    const Uuid uuid = Uuid();
    final String namespaceUrlString = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
    final String uuidV5 = uuid.v5(namespaceUrlString, deviceId);
    return uuidV5;
  }

  Future<void> _bindData() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceId = _getDeviceUUID(androidInfo.id);
      _deviceType = 'Android';
      _deviceModel = androidInfo.model;
      _osVersion = androidInfo.version.release;
      _deviceName = androidInfo.brand;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceId = _getDeviceUUID(iosInfo.identifierForVendor ?? "unknown");
      _deviceType = 'iOS';
      _deviceModel = iosInfo.utsname.machine;
      _osVersion = iosInfo.systemVersion;
      _deviceName = iosInfo.name;
    }
    _groupId = '78';
    _appVersion = packageInfo.version;
    _appName = packageInfo.appName;
    _packageName = packageInfo.packageName;
    _apptype = 'Lite';
    _language = 'English';
    _countryCode = 'IN';
    _themeColor = widget.model.themeColor;
    _themeMode = widget.model.themeMode;
    _isDevOrProd = '0';
  }

  String _generateUrl() {
    // final user = AppPreferences.getUser();
    // final userId = user['id'];
    String url = widget.model.link;
    url += '?';
    url += 'device_id=$_deviceId&';
    url += 'device_type=$_deviceType&';
    url += 'group_id=$_groupId&';
    url += 'device_model=$_deviceModel&';
    url += 'app_version=$_appVersion&';
    url += 'os_version=$_osVersion&';
    url += 'device_name=$_deviceName&';
    url += 'app_name=$_appName&';
    url += 'package_name=$_packageName&';
    url += 'app_type=$_apptype&';
    // url += 'user_id=${userId}&';
    url += 'language=$_language&';
    url += 'country_code=$_countryCode&';
    url += 'theme_color=$_themeColor&';
    url += 'theme_mode=$_themeMode&';
    url += 'is_develop_or_prod=$_isDevOrProd&';
    url += 'wid';
    print(url);
    return url;
  }

  String _generateUrlAboutUs() {
    String url = widget.model.link;
    url += '?';
    url += 'device_id=$_deviceId&';
    url += 'device_type=$_deviceType&';
    url += 'group_id=$_groupId&';
    url += 'device_model=$_deviceModel&';
    url += 'app_version=$_appVersion&';
    url += 'os_version=$_osVersion&';
    url += 'device_name=$_deviceName&';
    url += 'app_name=$_appName&';
    url += 'package_name=$_packageName&';
    url += 'language=$_language&';
    url += 'country_code=$_countryCode&';
    url += 'is_develop_or_prod=$_isDevOrProd';
    print(url);
    return url;
  }
}
