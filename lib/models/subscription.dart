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

  UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.startDate,
    this.endDate,
  });

  bool get isActive => status == 'active';

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
    );
  }
}
