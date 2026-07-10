import 'dart:io' show Platform;

enum Environment { local, live }

class Api {
  static final Api instance = Api._();
  Api._();

  static String get _localBaseUrl {
    if (Platform.isAndroid) {
      return "http://192.168.100.203:3000";
    }
    return "http://192.168.100.203:3000";
  }

  static const String _liveBaseUrl = "https://barqody-backend.vercel.app";

  static late String baseUrl;

  static void init(
    // Environment env
  ) {
    baseUrl = _localBaseUrl;
    // baseUrl = _liveBaseUrl;

    // env == Environment.local ? _localBaseUrl : _liveBaseUrl;
  }

  static final auth = _AuthApi();
  static final subscription = _SubscriptionApi();
  static final contact = _ContactApi();
  static final loyalty = _LoyaltyApi();
  static final enrollment = _EnrollmentApi();
  static final businessEnrollment = _BusinessEnrollmentApi();
  static final catalog = _CatalogApi();
  static final attendance = _AttendanceApi();
  static final wallet = _WalletApi();
}

class _AuthApi {
  String get register => "${Api.baseUrl}/api/user/auth/register";
  String get login => "${Api.baseUrl}/api/user/auth/login";
  String get googleSignIn => "${Api.baseUrl}/api/user/auth/google";
  String get profile => "${Api.baseUrl}/api/user/auth/profile";
  String searchUsers(String query) =>
      "${Api.baseUrl}/api/user/auth/search?q=${Uri.encodeQueryComponent(query)}";
  String profileByUsername(String username, {bool isScan = false, String? cardId}) {
    final params = <String>[];
    if (isScan) params.add('source=scan');
    if (cardId != null && cardId.isNotEmpty) {
      params.add('card=${Uri.encodeQueryComponent(cardId)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return "${Api.baseUrl}/api/user/auth/profile/$username$query";
  }

  String profileById(String id, {bool isScan = false, String? cardId}) {
    final params = <String>[];
    if (isScan) params.add('source=scan');
    if (cardId != null && cardId.isNotEmpty) {
      params.add('card=${Uri.encodeQueryComponent(cardId)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return "${Api.baseUrl}/api/user/auth/getprofile/$id$query";
  }
  String get links => "${Api.baseUrl}/api/user/auth/profile/links";
  String get linkCatalog => "${Api.baseUrl}/api/user/auth/link-catalog";
  String get analytics => "${Api.baseUrl}/api/user/auth/analytics";
  String get saveFcmToken => "${Api.baseUrl}/api/user/auth/fcm-token";
  String get removeFcmToken => "${Api.baseUrl}/api/user/auth/fcm-token";
}

class _SubscriptionApi {
  String get plans => "${Api.baseUrl}/api/user/subscription/plans";
  String get my => "${Api.baseUrl}/api/user/subscription/my";
  String get subscribe => "${Api.baseUrl}/api/user/subscription/subscribe";
  String get cancel => "${Api.baseUrl}/api/user/subscription/cancel";
}

class _ContactApi {
  String get getCategories => "${Api.baseUrl}/api/user/category";
  String get createCategory => "${Api.baseUrl}/api/user/category";
  String deleteCategory(String id) => "${Api.baseUrl}/api/user/category/$id";

  String get getContacts => "${Api.baseUrl}/api/user/contacts";
  String get addManual => "${Api.baseUrl}/api/user/contacts/manual";
  String get addScanned => "${Api.baseUrl}/api/user/contacts/scan";
  String get exchange => "${Api.baseUrl}/api/user/contacts/exchange";
  String updateContact(String id) => "${Api.baseUrl}/api/user/contacts/$id";
  String deleteContact(String id) => "${Api.baseUrl}/api/user/contacts/$id";
}

class _LoyaltyApi {
  String get programs => "${Api.baseUrl}/api/loyalty/programs";
  String program(String id) => "${Api.baseUrl}/api/loyalty/programs/$id";
  String toggleActive(String id) =>
      "${Api.baseUrl}/api/loyalty/programs/$id/toggle";
}

class _EnrollmentApi {
  String get enroll => "${Api.baseUrl}/api/loyalty/enrollments";
  String get myEnrollments => "${Api.baseUrl}/api/loyalty/enrollments/me";
  String customerEnrollments(String customerId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/customer/$customerId";
  String addStamp(String enrollmentId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/$enrollmentId/stamp";
}

class _BusinessEnrollmentApi {
  String get enroll => "${Api.baseUrl}/api/loyalty/business-enrollments";
  String customerStatus(String customerId) =>
      "${Api.baseUrl}/api/loyalty/business-enrollments/customer/$customerId";
}

class _CatalogApi {
  String get availability => "${Api.baseUrl}/api/catalog/availability";
  String get orders => "${Api.baseUrl}/api/catalog/orders";
  String get incomingOrders => "${Api.baseUrl}/api/catalog/orders/incoming";
  String get myOrders => "${Api.baseUrl}/api/catalog/orders/my";
  String order(String id) => "${Api.baseUrl}/api/catalog/orders/$id";
  String updateStatus(String id) =>
      "${Api.baseUrl}/api/catalog/orders/$id/status";
  String markOrderRead(String id) =>
      "${Api.baseUrl}/api/catalog/orders/$id/read";
  String get markAllRead => "${Api.baseUrl}/api/catalog/orders/read-all";
}

class _AttendanceApi {
  String get employees => "${Api.baseUrl}/api/attendance/employees";
  String employee(String id) => "${Api.baseUrl}/api/attendance/employees/$id";
  String get myEmployers => "${Api.baseUrl}/api/attendance/employees/me";
  String employeeStatus(String employeeUserId) =>
      "${Api.baseUrl}/api/attendance/employees/status/$employeeUserId";
  String get mark => "${Api.baseUrl}/api/attendance/mark";
  String get today => "${Api.baseUrl}/api/attendance/today";
  String get businessRecords =>
      "${Api.baseUrl}/api/attendance/records/business";
  String get myRecords => "${Api.baseUrl}/api/attendance/records/me";
  String get summary => "${Api.baseUrl}/api/attendance/summary";
  String get myInvitations => "${Api.baseUrl}/api/attendance/invitations/me";
  String acceptInvitation(String id) =>
      "${Api.baseUrl}/api/attendance/invitations/$id/accept";
  String declineInvitation(String id) =>
      "${Api.baseUrl}/api/attendance/invitations/$id/decline";
}

class _WalletApi {
  String get companyCards => "${Api.baseUrl}/api/wallet/company-cards";
  String get myGoogleCard => "${Api.baseUrl}/api/wallet/google/my-card";
  String googleBusinessCard(String businessUserId) =>
      "${Api.baseUrl}/api/wallet/google/business-card/$businessUserId";
}
