enum Environment { local, live }

class Api {
  static final Api instance = Api._();
  Api._();

  // Same host for all targets; avoid dart:io Platform (unsupported on web).
  // Use localhost when Flutter runs on Chrome/desktop on this PC.
  // LAN IP (e.g. 192.168.x.x) is only needed for a physical phone on Wi‑Fi.
  static const String _localBaseUrl = "http://192.168.100.203:3000";

  static const String _liveBaseUrl = "https://barqody-backend.vercel.app";

  static late String baseUrl;

  static void init(
    // Environment env
  ) {
    // baseUrl = _localBaseUrl;
    baseUrl = _liveBaseUrl;

    // env == Environment.local ? _localBaseUrl : _liveBaseUrl;
  }

  static final auth = _AuthApi();
  static final subscription = _SubscriptionApi();
  static final contact = _ContactApi();
  static final loyalty = _LoyaltyApi();
  static final enrollment = _EnrollmentApi();
  static final loyaltyPoints = _LoyaltyPointsApi();
  static final offers = _OffersApi();
  static final businessEnrollment = _BusinessEnrollmentApi();
  static final catalog = _CatalogApi();
  static final booking = _BookingApi();
  static final pos = _PosApi();
  static final attendance = _AttendanceApi();
  static final wallet = _WalletApi();
  static final invitation = _InvitationApi();
  static final directory = _DirectoryApi();
  static final follow = _FollowApi();
  static final explore = _ExploreApi();
  static final marketplace = _MarketplaceApi();
  static final reviews = _ReviewsApi();
  static final businessWebsite = _BusinessWebsiteApi();
  static final businessFeatures = _BusinessFeaturesApi();
  static final payments = _PaymentsApi();
}

class _BusinessFeaturesApi {
  String get mine => "${Api.baseUrl}/api/business/features";
  String get setup => "${Api.baseUrl}/api/business/features/setup";
  String get businessType =>
      "${Api.baseUrl}/api/business/features/business-type";
  String get activate => "${Api.baseUrl}/api/business/features/activate";
  String get deactivate => "${Api.baseUrl}/api/business/features/deactivate";
}

class _AuthApi {
  String get register => "${Api.baseUrl}/api/user/auth/register";
  String get login => "${Api.baseUrl}/api/user/auth/login";
  String get googleSignIn => "${Api.baseUrl}/api/user/auth/google";
  String get otpSend => "${Api.baseUrl}/api/user/auth/otp/send";
  String get otpVerify => "${Api.baseUrl}/api/user/auth/otp/verify";
  String get otpComplete => "${Api.baseUrl}/api/user/auth/otp/complete";
  String get profile => "${Api.baseUrl}/api/user/auth/profile";
  String searchUsers(String query) =>
      "${Api.baseUrl}/api/user/auth/search?q=${Uri.encodeQueryComponent(query)}";
  String profileByUsername(
    String username, {
    bool isScan = false,
    String? cardId,
  }) {
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
  String get gallery => "${Api.baseUrl}/api/user/auth/gallery";
  String galleryItem(String id) =>
      "${Api.baseUrl}/api/user/auth/gallery/${Uri.encodeComponent(id)}";
  String get linkCatalog => "${Api.baseUrl}/api/user/auth/link-catalog";
  String get analytics => "${Api.baseUrl}/api/user/auth/analytics";
  String get saveFcmToken => "${Api.baseUrl}/api/user/auth/fcm-token";
  String get removeFcmToken => "${Api.baseUrl}/api/user/auth/fcm-token";

  String get createDevicePairing =>
      "${Api.baseUrl}/api/user/auth/device/pairing";
  String devicePairingStatus(String code) =>
      "${Api.baseUrl}/api/user/auth/device/pairing/${Uri.encodeComponent(code)}/status";
  String get approveDevicePairing =>
      "${Api.baseUrl}/api/user/auth/device/pairing/approve";
  String get deviceSessions => "${Api.baseUrl}/api/user/auth/device/sessions";
  String get revokeCurrentDeviceSession =>
      "${Api.baseUrl}/api/user/auth/device/sessions/current";
  String revokeDeviceSession(String sessionId) =>
      "${Api.baseUrl}/api/user/auth/device/sessions/$sessionId";
  String get registerDeviceSession =>
      "${Api.baseUrl}/api/user/auth/device/sessions/register";

  String checkUsername(String username) =>
      "${Api.baseUrl}/api/user/auth/username/check?username=${Uri.encodeQueryComponent(username)}";
  String get submitUsernameClaim =>
      "${Api.baseUrl}/api/user/auth/username/claim";
  String get myUsernameClaims =>
      "${Api.baseUrl}/api/user/auth/username/claims";
}

class _SubscriptionApi {
  String get plans => "${Api.baseUrl}/api/user/subscription/plans";
  String get my => "${Api.baseUrl}/api/user/subscription/my";
  String get checkout => "${Api.baseUrl}/api/user/subscription/checkout";
  String get confirm => "${Api.baseUrl}/api/user/subscription/confirm";
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
  String get matchPhones => "${Api.baseUrl}/api/user/contacts/match-phones";
  String updateContact(String id) => "${Api.baseUrl}/api/user/contacts/$id";
  String deleteContact(String id) => "${Api.baseUrl}/api/user/contacts/$id";
}

class _LoyaltyApi {
  String get programs => "${Api.baseUrl}/api/loyalty/programs";
  String program(String id) => "${Api.baseUrl}/api/loyalty/programs/$id";
  String toggleActive(String id) =>
      "${Api.baseUrl}/api/loyalty/programs/$id/toggle";

  String get templates => "${Api.baseUrl}/api/loyalty-templates";
  String get myTemplates => "${Api.baseUrl}/api/loyalty-templates/mine";
  String templateById(String id) => "${Api.baseUrl}/api/loyalty-templates/$id";
  String useTemplate(String id) =>
      "${Api.baseUrl}/api/loyalty-templates/$id/use";
}

class _EnrollmentApi {
  String get enroll => "${Api.baseUrl}/api/loyalty/enrollments";
  String get selfEnroll => "${Api.baseUrl}/api/loyalty/enrollments/self";
  String get myEnrollments => "${Api.baseUrl}/api/loyalty/enrollments/me";
  String programEnrollments(String programId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/program/$programId";
  String customerEnrollments(String customerId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/customer/$customerId";
  String addStamp(String enrollmentId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/$enrollmentId/stamp";
  String claimReward(String enrollmentId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/$enrollmentId/claim";
  String markClaimed(String enrollmentId) =>
      "${Api.baseUrl}/api/loyalty/enrollments/$enrollmentId/mark-claimed";
}

class _LoyaltyPointsApi {
  String get business => "${Api.baseUrl}/api/loyalty/points/business";
  String get businessPurchase =>
      "${Api.baseUrl}/api/loyalty/points/business/purchase";
  String get businessActivity =>
      "${Api.baseUrl}/api/loyalty/points/business/activity";
  String get businessRedemptionSettings =>
      "${Api.baseUrl}/api/loyalty/points/business/redemption-settings";
  String get customer => "${Api.baseUrl}/api/loyalty/points/customer";
  String get customerActivity =>
      "${Api.baseUrl}/api/loyalty/points/customer/activity";
  String customerCheckout(String businessId) =>
      "${Api.baseUrl}/api/loyalty/points/customer/checkout/$businessId";
  String get redemptionQuote =>
      "${Api.baseUrl}/api/loyalty/points/redemption/quote";
  String publicCheckout(String businessId) =>
      "${Api.baseUrl}/api/loyalty/points/public/checkout/$businessId";
  String stampHistory(String enrollmentId) =>
      "${Api.baseUrl}/api/loyalty/points/stamp-history/$enrollmentId";
}

class _OffersApi {
  String get business => "${Api.baseUrl}/api/offers/business";
  String businessOffer(String id) =>
      "${Api.baseUrl}/api/offers/business/$id";
  String get publicList => "${Api.baseUrl}/api/offers/public";
  String publicOffer(String id) => "${Api.baseUrl}/api/offers/public/$id";
  String get publicQuote => "${Api.baseUrl}/api/offers/public/quote";
}

class _BusinessEnrollmentApi {
  String get enroll => "${Api.baseUrl}/api/loyalty/business-enrollments";
  String customerStatus(String customerId) =>
      "${Api.baseUrl}/api/loyalty/business-enrollments/customer/$customerId";
}

class _CatalogApi {
  String get availability => "${Api.baseUrl}/api/catalog/availability";
  String get publicAvailability =>
      "${Api.baseUrl}/api/catalog/public/availability";
  String get stayAvailability =>
      "${Api.baseUrl}/api/catalog/stay-availability";
  String get orders => "${Api.baseUrl}/api/catalog/orders";
  /// Guest / optional-auth website + Flutter guest checkout.
  String get publicOrders => "${Api.baseUrl}/api/catalog/public/orders";
  String get incomingOrders => "${Api.baseUrl}/api/catalog/orders/incoming";
  String get myOrders => "${Api.baseUrl}/api/catalog/orders/my";
  /// Link a guest web order after phone OTP login (tracking code + phone match).
  String get claimGuestOrder =>
      "${Api.baseUrl}/api/catalog/orders/claim-guest";
  String order(String id) => "${Api.baseUrl}/api/catalog/orders/$id";
  String updateStatus(String id) =>
      "${Api.baseUrl}/api/catalog/orders/$id/status";
  String markOrderRead(String id) =>
      "${Api.baseUrl}/api/catalog/orders/$id/read";
  String get markAllRead => "${Api.baseUrl}/api/catalog/orders/read-all";
  String mockPayment(String id) =>
      "${Api.baseUrl}/api/catalog/orders/$id/payments/mock";
  String publicMockPayment(String id) =>
      "${Api.baseUrl}/api/catalog/public/orders/$id/payments/mock";
}

class _PaymentsApi {
  String get config => "${Api.baseUrl}/api/payments/config";
  String orderIntent(String id) =>
      "${Api.baseUrl}/api/payments/orders/$id/intent";
  String publicOrderIntent(String id) =>
      "${Api.baseUrl}/api/payments/public/orders/$id/intent";
  String orderConfirm(String id) =>
      "${Api.baseUrl}/api/payments/orders/$id/confirm";
  String publicOrderConfirm(String id) =>
      "${Api.baseUrl}/api/payments/public/orders/$id/confirm";
  String orderStatus(String id) =>
      "${Api.baseUrl}/api/payments/orders/$id/status";
  String get methods => "${Api.baseUrl}/api/payments/methods";
  String get setupIntent => "${Api.baseUrl}/api/payments/setup-intent";
  String methodDefault(String id) =>
      "${Api.baseUrl}/api/payments/methods/$id/default";
  String method(String id) => "${Api.baseUrl}/api/payments/methods/$id";
  String get myPayments => "${Api.baseUrl}/api/payments/my";
  String myPayment(String id) => "${Api.baseUrl}/api/payments/my/$id";
  String byOrder(String orderId) =>
      "${Api.baseUrl}/api/payments/by-order/$orderId";
  String orderRefund(String id) =>
      "${Api.baseUrl}/api/payments/orders/$id/refund";
  String get wallet => "${Api.baseUrl}/api/payments/wallet";
  String get walletLedger => "${Api.baseUrl}/api/payments/wallet/ledger";
  String get walletAnalytics =>
      "${Api.baseUrl}/api/payments/wallet/analytics";
}

class _BookingApi {
  String get resources => "${Api.baseUrl}/api/booking/resources";
  String resource(String id) => "${Api.baseUrl}/api/booking/resources/$id";
  String get syncTeam => "${Api.baseUrl}/api/booking/resources/sync-team";
  String get calendarBusy => "${Api.baseUrl}/api/booking/calendar/busy";
}

class _PosApi {
  String get connection => "${Api.baseUrl}/api/pos/connection";
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
  String employeeCardTemplate(String employeeRefId) =>
      "${Api.baseUrl}/api/attendance/employees/me/$employeeRefId/card-template";
}

class _WalletApi {
  String get companyCards => "${Api.baseUrl}/api/wallet/company-cards";
  String get myGoogleCard => "${Api.baseUrl}/api/wallet/google/my-card";
  String googleBusinessCard(String businessUserId) =>
      "${Api.baseUrl}/api/wallet/google/business-card/$businessUserId";
}

class _InvitationApi {
  String get create => "${Api.baseUrl}/api/invitations";
  String get sent => "${Api.baseUrl}/api/invitations/sent";
  String get received => "${Api.baseUrl}/api/invitations/received";
  String byId(String id) => "${Api.baseUrl}/api/invitations/$id";
  String update(String id) => "${Api.baseUrl}/api/invitations/$id";
  String addRecipients(String id) =>
      "${Api.baseUrl}/api/invitations/$id/recipients";

  String get templates => "${Api.baseUrl}/api/invitation-templates";
  String get myTemplates => "${Api.baseUrl}/api/invitation-templates/mine";
  String templateById(String id) =>
      "${Api.baseUrl}/api/invitation-templates/$id";
  String useTemplate(String id) =>
      "${Api.baseUrl}/api/invitation-templates/$id/use";
}

class _DirectoryApi {
  String get sync => "${Api.baseUrl}/api/user/directory/sync";
  String get syncStatus => "${Api.baseUrl}/api/user/directory/sync-status";
  String lookup(String phone) =>
      "${Api.baseUrl}/api/user/directory/lookup?phone=${Uri.encodeQueryComponent(phone)}";
}

class _FollowApi {
  String request(String userId) => "${Api.baseUrl}/api/user/follow/$userId";
  String unfollow(String userId) => "${Api.baseUrl}/api/user/follow/$userId";
  String accept(String followId) =>
      "${Api.baseUrl}/api/user/follow/$followId/accept";
  String decline(String followId) =>
      "${Api.baseUrl}/api/user/follow/$followId/decline";
  String get notifications => "${Api.baseUrl}/api/user/follow/notifications";
  String get markAllRead =>
      "${Api.baseUrl}/api/user/follow/notifications/read";
  String markRead(String followId) =>
      "${Api.baseUrl}/api/user/follow/notifications/$followId/read";
}

class _ExploreApi {
  String get nearby => "${Api.baseUrl}/api/explore/nearby";
  String get banners => "${Api.baseUrl}/api/explore/banners";
  String get categories => "${Api.baseUrl}/api/explore/categories";
  String get bannerPlans => "${Api.baseUrl}/api/explore/banner-plans";
  String get myBanners => "${Api.baseUrl}/api/explore/my-banners";
  String myBanner(String id) => "${Api.baseUrl}/api/explore/my-banners/$id";
}

class _MarketplaceApi {
  String get categories => "${Api.baseUrl}/api/marketplace/categories";
  String get products => "${Api.baseUrl}/api/marketplace/products";
}

class _ReviewsApi {
  String get create => "${Api.baseUrl}/api/reviews";
  String forBusiness(String businessId) =>
      "${Api.baseUrl}/api/reviews/business/$businessId";
  String report(String reviewId) =>
      "${Api.baseUrl}/api/reviews/$reviewId/report";
}

class _BusinessWebsiteApi {
  String get catalog => "${Api.baseUrl}/api/business-websites/catalog";
  String get mine => "${Api.baseUrl}/api/business-websites/mine";
  String get preview => "${Api.baseUrl}/api/business-websites/mine/preview";
  String templatePreview(String templateId) =>
      "${Api.baseUrl}/api/business-websites/templates/${Uri.encodeComponent(templateId)}/preview";
  String get contentCategories =>
      "${Api.baseUrl}/api/business-websites/mine/content-categories";
  String contentCategory(String id) =>
      "${Api.baseUrl}/api/business-websites/mine/content-categories/${Uri.encodeComponent(id)}";
  String get content => "${Api.baseUrl}/api/business-websites/mine/content";
  String contentItem(String id) =>
      "${Api.baseUrl}/api/business-websites/mine/content/${Uri.encodeComponent(id)}";
  String publicSite(String slug) =>
      "${Api.baseUrl}/w/${Uri.encodeComponent(slug)}";

  /// Vanity URL: /{username}/menu | /{username}/service | …
  String vanitySite(String username, String websiteType) {
    final user = Uri.encodeComponent(username.replaceFirst(RegExp(r'^@'), ''));
    final segment = switch (websiteType) {
      'service' || 'services' => 'service',
      'products' || 'product' => 'products',
      'portfolio' => 'portfolio',
      _ => 'menu',
    };
    return "${Api.baseUrl}/$user/$segment";
  }
}
