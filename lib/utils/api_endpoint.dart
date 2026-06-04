import 'dart:io' show Platform;

enum Environment { local, live }

class Api {
  static final Api instance = Api._();
  Api._();

  static String get _localBaseUrl {
    if (Platform.isAndroid) {
      return "https://remake-drained-underarm.ngrok-free.dev";
    }
    return "https://remake-drained-underarm.ngrok-free.dev";
  }
  static const String _liveBaseUrl = "https://your-production-url.com";

  static late String baseUrl;

  static void init(
    // Environment env
  ) {
    baseUrl = _localBaseUrl;

    // env == Environment.local ? _localBaseUrl : _liveBaseUrl;
  }

  static final auth = _AuthApi();
  static final subscription = _SubscriptionApi();
}

class _AuthApi {
  String get register => "${Api.baseUrl}/api/user/auth/register";
  String get login => "${Api.baseUrl}/api/user/auth/login";
  String get googleSignIn => "${Api.baseUrl}/api/user/auth/google";
  String get profile => "${Api.baseUrl}/api/user/auth/profile";
}

class _SubscriptionApi {
  String get plans => "${Api.baseUrl}/api/user/subscription/plans";
  String get my => "${Api.baseUrl}/api/user/subscription/my";
  String get subscribe => "${Api.baseUrl}/api/user/subscription/subscribe";
  String get cancel => "${Api.baseUrl}/api/user/subscription/cancel";
}
