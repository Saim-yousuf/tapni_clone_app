import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class SavedCard {
  final String id;
  final String brand;
  final String last4;
  final int? expMonth;
  final int? expYear;
  final bool isDefault;

  const SavedCard({
    required this.id,
    this.brand = '',
    this.last4 = '',
    this.expMonth,
    this.expYear,
    this.isDefault = false,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      expMonth: json['expMonth'] is int
          ? json['expMonth'] as int
          : int.tryParse('${json['expMonth'] ?? ''}'),
      expYear: json['expYear'] is int
          ? json['expYear'] as int
          : int.tryParse('${json['expYear'] ?? ''}'),
      isDefault: json['isDefault'] == true,
    );
  }

  String get label {
    final b = brand.isEmpty ? 'Card' : brand.toUpperCase();
    return '$b •••• $last4';
  }

  String get expiryLabel {
    if (expMonth == null || expYear == null) return '';
    final m = expMonth!.toString().padLeft(2, '0');
    final y = expYear!.toString().length > 2
        ? expYear!.toString().substring(expYear!.toString().length - 2)
        : expYear!.toString();
    return '$m/$y';
  }
}

class PaymentIntentSession {
  final String paymentId;
  final String orderId;
  final String clientSecret;
  final String paymentIntentId;
  final String publishableKey;
  final String? customerId;
  final String? ephemeralKey;
  final double amount;
  final String currency;
  final bool saveCard;
  final bool alreadyPaid;
  final List<SavedCard> savedCards;

  const PaymentIntentSession({
    required this.paymentId,
    required this.orderId,
    required this.clientSecret,
    required this.paymentIntentId,
    required this.publishableKey,
    this.customerId,
    this.ephemeralKey,
    this.amount = 0,
    this.currency = 'SAR',
    this.saveCard = false,
    this.alreadyPaid = false,
    this.savedCards = const [],
  });

  factory PaymentIntentSession.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['savedCards'];
    final cards = <SavedCard>[];
    if (cardsRaw is List) {
      for (final c in cardsRaw) {
        if (c is Map) {
          cards.add(SavedCard.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return PaymentIntentSession(
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      clientSecret: json['clientSecret']?.toString() ?? '',
      paymentIntentId: json['paymentIntentId']?.toString() ?? '',
      publishableKey: json['publishableKey']?.toString() ?? '',
      customerId: json['customerId']?.toString(),
      ephemeralKey: json['ephemeralKey']?.toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount'] ?? 0}') ?? 0,
      currency: json['currency']?.toString() ?? 'SAR',
      saveCard: json['saveCard'] == true,
      alreadyPaid: json['alreadyPaid'] == true,
      savedCards: cards,
    );
  }
}

class PaymentRepo {
  Map<String, dynamic>? _unwrap(dynamic data) {
    if (data is Map) {
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchConfig() async {
    final res = await ApiHandler.request(
      api: Api.payments.config,
      method: ApiMethod.get,
      authorization: false,
    );
    if (!res.success) return null;
    return _unwrap(res.data);
  }

  Future<ApiResponse> createOrderIntent({
    required String orderId,
    bool publicGuest = false,
    bool saveCard = false,
    String? paymentMethodId,
    String? idempotencyKey,
    String? paymentAttemptKey,
    String? guestPhone,
    String? paymentSessionToken,
    String? email,
  }) {
    return ApiHandler.request(
      api: publicGuest
          ? Api.payments.publicOrderIntent(orderId)
          : Api.payments.orderIntent(orderId),
      method: ApiMethod.post,
      authorization: !publicGuest,
      jsonBody: {
        'saveCard': saveCard,
        if (paymentMethodId != null && paymentMethodId.isNotEmpty)
          'paymentMethodId': paymentMethodId,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
        if (paymentAttemptKey != null && paymentAttemptKey.isNotEmpty)
          'paymentAttemptKey': paymentAttemptKey,
        if (guestPhone != null && guestPhone.isNotEmpty)
          'guestPhone': guestPhone,
        if (paymentSessionToken != null && paymentSessionToken.isNotEmpty)
          'paymentSessionToken': paymentSessionToken,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  Future<ApiResponse> confirmOrderPayment({
    required String orderId,
    required String paymentIntentId,
    bool publicGuest = false,
    String? guestPhone,
    String? paymentSessionToken,
  }) {
    return ApiHandler.request(
      api: publicGuest
          ? Api.payments.publicOrderConfirm(orderId)
          : Api.payments.orderConfirm(orderId),
      method: ApiMethod.post,
      authorization: !publicGuest,
      jsonBody: {
        'paymentIntentId': paymentIntentId,
        if (guestPhone != null && guestPhone.isNotEmpty)
          'guestPhone': guestPhone,
        if (paymentSessionToken != null && paymentSessionToken.isNotEmpty)
          'paymentSessionToken': paymentSessionToken,
      },
    );
  }

  Future<List<SavedCard>> listSavedCards() async {
    final res = await ApiHandler.request(
      api: Api.payments.methods,
      method: ApiMethod.get,
      authorization: true,
    );
    if (!res.success || res.data == null) return [];
    final payload = res.data is Map && res.data['data'] is List
        ? res.data['data'] as List
        : (res.data is List ? res.data as List : const []);
    return payload
        .whereType<Map>()
        .map((e) => SavedCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ApiResponse> createSetupIntent() {
    return ApiHandler.request(
      api: Api.payments.setupIntent,
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> setDefaultCard(String paymentMethodId) {
    return ApiHandler.request(
      api: Api.payments.methodDefault(paymentMethodId),
      method: ApiMethod.put,
      authorization: true,
    );
  }

  Future<ApiResponse> removeCard(String paymentMethodId) {
    return ApiHandler.request(
      api: Api.payments.method(paymentMethodId),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> getBusinessWallet() {
    return ApiHandler.request(
      api: Api.payments.wallet,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getBusinessWalletLedger({
    int limit = 50,
    int skip = 0,
    String? from,
    String? to,
    String? type,
    String? q,
  }) {
    return ApiHandler.request(
      api: Api.payments.walletLedger,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'limit': '$limit',
        'skip': '$skip',
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (type != null && type.isNotEmpty) 'type': type,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
  }

  /// range: day | week | month | year — ledger-backed chart series.
  Future<ApiResponse> getBusinessWalletAnalytics({String range = 'month'}) {
    return ApiHandler.request(
      api: Api.payments.walletAnalytics,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {'range': range},
    );
  }

  Future<ApiResponse> listMyPayments({
    int limit = 50,
    int skip = 0,
    String? status,
  }) {
    return ApiHandler.request(
      api: Api.payments.myPayments,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'limit': '$limit',
        'skip': '$skip',
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<ApiResponse> getMyPaymentDetail(String paymentId) {
    return ApiHandler.request(
      api: Api.payments.myPayment(paymentId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getPaymentByOrder(String orderId) {
    return ApiHandler.request(
      api: Api.payments.byOrder(orderId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> refundOrder({
    required String orderId,
    double? amount,
    String? reason,
    String? idempotencyKey,
  }) {
    return ApiHandler.request(
      api: Api.payments.orderRefund(orderId),
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        if (amount != null) 'amount': amount,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      },
    );
  }
}
