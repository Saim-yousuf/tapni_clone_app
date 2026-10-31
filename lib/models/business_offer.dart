class BusinessOffer {
  final String id;
  final String title;
  final String description;
  final String code;
  final bool hasCode;
  final String discountType;
  final double discountValue;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final int totalUsageLimit;
  final int perCustomerLimit;
  final int usedCount;
  final List<String> catalogTypes;
  final List<String> applicableItemIds;
  final List<String> applicableCategories;
  final bool isActive;
  final bool allowWithPoints;
  final bool allowGuests;

  const BusinessOffer({
    required this.id,
    required this.title,
    this.description = '',
    this.code = '',
    this.hasCode = false,
    this.discountType = 'percentage',
    this.discountValue = 0,
    this.startsAt,
    this.expiresAt,
    this.minOrderAmount = 0,
    this.maxDiscountAmount = 0,
    this.totalUsageLimit = 0,
    this.perCustomerLimit = 1,
    this.usedCount = 0,
    this.catalogTypes = const [],
    this.applicableItemIds = const [],
    this.applicableCategories = const [],
    this.isActive = true,
    this.allowWithPoints = true,
    this.allowGuests = true,
  });

  factory BusinessOffer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    final code = json['code']?.toString() ?? '';
    return BusinessOffer(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      code: code,
      hasCode: json['hasCode'] == true || code.isNotEmpty,
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      startsAt: parseDate(json['startsAt']),
      expiresAt: parseDate(json['expiresAt']),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble() ?? 0,
      totalUsageLimit: (json['totalUsageLimit'] as num?)?.toInt() ?? 0,
      perCustomerLimit: (json['perCustomerLimit'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      catalogTypes: strList(json['catalogTypes']),
      applicableItemIds: strList(json['applicableItemIds']),
      applicableCategories: strList(json['applicableCategories']),
      isActive: json['isActive'] != false,
      allowWithPoints: json['allowWithPoints'] != false,
      allowGuests: json['allowGuests'] != false,
    );
  }

  String get discountLabel {
    if (discountType == 'fixed') {
      return discountValue.toStringAsFixed(
        discountValue == discountValue.roundToDouble() ? 0 : 2,
      );
    }
    return '${discountValue.toStringAsFixed(0)}% OFF';
  }
}
