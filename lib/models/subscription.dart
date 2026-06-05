class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String duration;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? json['planId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['planName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['durationDays']?.toString() ?? json['duration']?.toString() ?? '',
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
  final DateTime? startDate;
  final DateTime? endDate;
  final String transactionRef;
  final String paymentReceipt;
  final String rejectionReason;
  final String source;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.startDate,
    this.endDate,
    this.transactionRef = '',
    this.paymentReceipt = '',
    this.rejectionReason = '',
    this.source = '',
    this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
  });

  bool get isActive => status == 'active';
  bool get isRequested => status == 'requested';
  bool get isRejected => status == 'rejected';

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      transactionRef: json['transactionRef']?.toString() ?? '',
      paymentReceipt: json['paymentReceipt']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.tryParse(json['rejectedAt'].toString())
          : null,
    );
  }
}
