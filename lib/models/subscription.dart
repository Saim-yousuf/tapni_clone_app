class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String duration;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'SAR',
    required this.duration,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? json['planId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['planName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'SAR',
      duration: json['durationDays']?.toString() ??
          json['duration']?.toString() ??
          '',
    );
  }
}

class UserSubscription {
  final String id;
  final String planId;
  final String planName;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String checkoutId;
  final String providerPaymentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? paidAt;
  final String source;
  final DateTime? requestedAt;
  final DateTime? approvedAt;

  UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.amount = 0,
    this.currency = 'SAR',
    this.checkoutId = '',
    this.providerPaymentId = '',
    this.startDate,
    this.endDate,
    this.paidAt,
    this.source = '',
    this.requestedAt,
    this.approvedAt,
  });

  bool get isActive => status == 'active';
  bool get isPendingPayment => status == 'pending_payment';
  bool get isFailed => status == 'failed';
  bool get isExpired =>
      status == 'expired' ||
      (endDate != null && endDate!.isBefore(DateTime.now()));

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'SAR',
      checkoutId: json['checkoutId']?.toString() ?? '',
      providerPaymentId: json['providerPaymentId']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      source: json['source']?.toString() ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
    );
  }
}

class CheckoutSession {
  final String checkoutId;
  final double amount;
  final String currency;
  final String planId;
  final String planName;
  final String? clientSecret;
  final UserSubscription? subscription;

  CheckoutSession({
    required this.checkoutId,
    required this.amount,
    required this.currency,
    required this.planId,
    required this.planName,
    this.clientSecret,
    this.subscription,
  });

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    final subJson = json['subscription'];
    return CheckoutSession(
      checkoutId: json['checkoutId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'SAR',
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      clientSecret: json['clientSecret']?.toString(),
      subscription: subJson is Map<String, dynamic>
          ? UserSubscription.fromJson(subJson)
          : null,
    );
  }
}
