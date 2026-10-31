enum OrderStatus { held, pending, confirmed, completed, cancelled, noShow }

class CatalogOrder {
  final String id;
  final String businessId;
  final String businessName;
  final String businessUsername;
  final String? businessPhoto;
  final String customerId;
  final String customerName;
  final String customerUsername;
  final String? customerPhoto;
  final String guestName;
  final String guestPhone;
  final String businessLinkId;
  final String catalogType;
  final String bookingKind;
  final List<CatalogOrderLineItem> items;
  final double totalAmount;
  /** Subtotal before points discount (falls back to totalAmount). */
  final double subtotalAmount;
  final String couponCode;
  final String couponTitle;
  final double couponDiscountAmount;
  final int pointsRedeemed;
  final double pointsDiscountAmount;
  final String currency;
  final String? bookingDate;
  final String? bookingTime;
  final String checkInDate;
  final String checkOutDate;
  final List<String> resourceNames;
  final OrderStatus status;
  final bool isRead;
  final int tokenNumber;
  final String paymentStatus;
  final String paymentMethod;
  final String paymentProvider;
  final String paymentTransactionId;
  final bool paymentSimulated;
  final bool isGenuinelyPaid;
  /// Server-side loyalty grant summary (stamps/points from this order).
  final OrderLoyaltyReward? loyaltyReward;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CatalogOrder({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessUsername,
    this.businessPhoto,
    required this.customerId,
    required this.customerName,
    required this.customerUsername,
    this.customerPhoto,
    this.guestName = '',
    this.guestPhone = '',
    this.businessLinkId = '',
    this.catalogType = 'catalog',
    this.bookingKind = 'order',
    required this.items,
    this.totalAmount = 0,
    this.subtotalAmount = 0,
    this.couponCode = '',
    this.couponTitle = '',
    this.couponDiscountAmount = 0,
    this.pointsRedeemed = 0,
    this.pointsDiscountAmount = 0,
    this.currency = 'PKR',
    this.bookingDate,
    this.bookingTime,
    this.checkInDate = '',
    this.checkOutDate = '',
    this.resourceNames = const [],
    this.status = OrderStatus.pending,
    this.isRead = false,
    this.tokenNumber = 0,
    this.paymentStatus = 'pending',
    this.paymentMethod = '',
    this.paymentProvider = 'none',
    this.paymentTransactionId = '',
    this.paymentSimulated = false,
    this.isGenuinelyPaid = false,
    this.loyaltyReward,
    this.createdAt,
    this.updatedAt,
  });

  factory CatalogOrder.fromJson(Map<String, dynamic> json) {
    final namesRaw = json['resourceNames'];
    final names = <String>[];
    if (namesRaw is List) {
      for (final n in namesRaw) {
        final s = n?.toString().trim() ?? '';
        if (s.isNotEmpty) names.add(s);
      }
    }

    final paymentStatus = json['paymentStatus']?.toString() ?? 'pending';

    return CatalogOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      businessUsername: json['businessUsername']?.toString() ?? '',
      businessPhoto: json['businessPhoto']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerUsername: json['customerUsername']?.toString() ?? '',
      customerPhoto: json['customerPhoto']?.toString(),
      guestName: json['guestName']?.toString() ?? '',
      guestPhone: json['guestPhone']?.toString() ?? '',
      businessLinkId: json['businessLinkId']?.toString() ?? '',
      catalogType: json['catalogType']?.toString() ?? 'catalog',
      bookingKind: json['bookingKind']?.toString() ?? 'order',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CatalogOrderLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : 0,
      subtotalAmount: (json['subtotalAmount'] is num)
          ? (json['subtotalAmount'] as num).toDouble()
          : ((json['totalAmount'] is num)
              ? (json['totalAmount'] as num).toDouble()
              : 0),
      couponCode: json['couponCode']?.toString() ?? '',
      couponTitle: json['couponTitle']?.toString() ?? '',
      couponDiscountAmount: (json['couponDiscountAmount'] is num)
          ? (json['couponDiscountAmount'] as num).toDouble()
          : 0,
      pointsRedeemed: (json['pointsRedeemed'] is num)
          ? (json['pointsRedeemed'] as num).toInt()
          : 0,
      pointsDiscountAmount: (json['pointsDiscountAmount'] is num)
          ? (json['pointsDiscountAmount'] as num).toDouble()
          : 0,
      currency: (json['currency']?.toString().trim().isNotEmpty ?? false)
          ? json['currency'].toString().toUpperCase()
          : 'PKR',
      bookingDate: json['bookingDate']?.toString(),
      bookingTime: json['bookingTime']?.toString(),
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      resourceNames: names,
      status: _parseStatus(json['status']?.toString()),
      isRead: json['isRead'] as bool? ?? false,
      tokenNumber: _parseToken(json['tokenNumber']),
      paymentStatus: paymentStatus,
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentProvider: json['paymentProvider']?.toString() ?? 'none',
      paymentTransactionId: json['paymentTransactionId']?.toString() ?? '',
      paymentSimulated: json['paymentSimulated'] as bool? ??
          paymentStatus == 'simulated_paid',
      isGenuinelyPaid: json['isGenuinelyPaid'] as bool? ??
          paymentStatus == 'paid',
      loyaltyReward: OrderLoyaltyReward.tryParse(json['loyaltyReward']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static CatalogOrder? tryFromApi(dynamic data) {
    if (data is! Map) return null;
    final payload = data['data'] is Map ? data['data'] : data;
    if (payload is! Map) return null;
    try {
      return CatalogOrder.fromJson(Map<String, dynamic>.from(payload));
    } catch (_) {
      return null;
    }
  }

  CatalogOrder copyWithPayment({
    String? paymentStatus,
    String? paymentMethod,
    String? paymentTransactionId,
    bool? paymentSimulated,
  }) {
    final status = paymentStatus ?? this.paymentStatus;
    return CatalogOrder(
      id: id,
      businessId: businessId,
      businessName: businessName,
      businessUsername: businessUsername,
      businessPhoto: businessPhoto,
      customerId: customerId,
      customerName: customerName,
      customerUsername: customerUsername,
      customerPhoto: customerPhoto,
      guestName: guestName,
      guestPhone: guestPhone,
      businessLinkId: businessLinkId,
      catalogType: catalogType,
      bookingKind: bookingKind,
      items: items,
      totalAmount: totalAmount,
      subtotalAmount: subtotalAmount,
      couponCode: couponCode,
      couponTitle: couponTitle,
      couponDiscountAmount: couponDiscountAmount,
      pointsRedeemed: pointsRedeemed,
      pointsDiscountAmount: pointsDiscountAmount,
      currency: currency,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      resourceNames: resourceNames,
      status: this.status,
      isRead: isRead,
      tokenNumber: tokenNumber,
      paymentStatus: status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProvider: paymentProvider,
      paymentTransactionId:
          paymentTransactionId ?? this.paymentTransactionId,
      loyaltyReward: loyaltyReward,
      paymentSimulated: paymentSimulated ?? this.paymentSimulated,
      isGenuinelyPaid: status == 'paid',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get paymentLabel {
    final method = paymentMethod.trim().toLowerCase();
    final pStatus = paymentStatus.trim().toLowerCase();
    if (method == 'online') {
      switch (pStatus) {
        case 'simulated_paid':
          return 'Online · demo payment (not a real charge)';
        case 'paid':
          return 'Online · paid';
        case 'failed':
          return 'Online · payment failed';
        case 'cancelled':
          return 'Online · cancelled';
        default:
          return 'Online · awaiting payment';
      }
    }
    if (method == 'cash_on_delivery' || method == 'cash') {
      return 'Cash on delivery';
    }
    if (pStatus == 'unpaid' || pStatus == 'pending' || pStatus.isEmpty) {
      return 'Payment pending';
    }
    if (pStatus == 'simulated_paid') {
      return 'Demo payment (not a real charge)';
    }
    if (pStatus == 'paid') return 'Paid';
    if (pStatus == 'failed') return 'Payment failed';
    if (pStatus == 'cancelled') return 'Payment cancelled';
    return 'Payment update';
  }

  /// Normalized kind used for filters and badges.
  String get kind {
    final k = bookingKind.trim().toLowerCase();
    if (k == 'appointment' || k == 'stay' || k == 'table' || k == 'order') {
      return k;
    }
    if (checkInDate.trim().isNotEmpty && checkOutDate.trim().isNotEmpty) {
      return 'stay';
    }
    if ((bookingDate ?? '').trim().isNotEmpty) return 'appointment';
    if (catalogType == 'services') return 'appointment';
    if (catalogType == 'menu') return 'order';
    return 'order';
  }

  bool get isStay => kind == 'stay';
  bool get isAppointment => kind == 'appointment';
  bool get isTable => kind == 'table';

  /// Web / walk-in guest with no linked Barqody account.
  bool get isGuest =>
      customerId.trim().isEmpty &&
      (guestName.trim().isNotEmpty || guestPhone.trim().isNotEmpty);

  String get displayCustomerName {
    final name = customerName.trim();
    if (name.isNotEmpty) return name;
    return guestName.trim();
  }

  String get kindLabel {
    switch (kind) {
      case 'appointment':
        return 'Appointment';
      case 'stay':
        return 'Stay';
      case 'table':
        return 'Table';
      default:
        return 'Order';
    }
  }

  /// One-line schedule for list cards (empty for plain orders).
  String get whenLine {
    if (isStay) {
      final cin = checkInDate.trim();
      final cout = checkOutDate.trim();
      final range = (cin.isNotEmpty && cout.isNotEmpty)
          ? '$cin – $cout'
          : (cin.isNotEmpty ? cin : '');
      final room = resourceNames.isNotEmpty ? resourceNames.join(', ') : '';
      if (range.isEmpty && room.isEmpty) return '';
      if (range.isEmpty) return room;
      if (room.isEmpty) return range;
      return '$range · $room';
    }
    if (isAppointment) {
      final date = (bookingDate ?? '').trim();
      final time = (bookingTime ?? '').trim();
      final who = resourceNames.isNotEmpty ? resourceNames.join(', ') : '';
      final slot = [
        if (date.isNotEmpty) date,
        if (time.isNotEmpty) time,
      ].join(' · ');
      if (slot.isEmpty && who.isEmpty) return '';
      if (slot.isEmpty) return who;
      if (who.isEmpty) return slot;
      return '$slot · $who';
    }
    return '';
  }

  static OrderStatus _parseStatus(String? value) {
    switch (value) {
      case 'held':
        return OrderStatus.held;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'no_show':
        return OrderStatus.noShow;
      case 'pending':
        return OrderStatus.pending;
      default:
        return OrderStatus.pending;
    }
  }

  static int _parseToken(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get statusApiValue {
    switch (status) {
      case OrderStatus.held:
        return 'held';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.noShow:
        return 'no_show';
      case OrderStatus.pending:
        return 'pending';
    }
  }

  String get itemsSummary =>
      items.map((e) => '${e.quantity}x ${e.name}').join(', ');

  bool get hasToken => tokenNumber > 0;

  String get tokenLabel => hasToken ? 'Order #$tokenNumber' : '';

  static int tokenFromApi(dynamic data) {
    if (data is! Map) return 0;
    final payload = data['data'] is Map ? data['data'] : data;
    if (payload is! Map) return 0;
    final value = payload['tokenNumber'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? idFromApi(dynamic data) {
    if (data is! Map) return null;
    final payload = data['data'] is Map ? data['data'] : data;
    if (payload is! Map) return null;
    final id = payload['id'] ?? payload['_id'];
    final s = id?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }
}

class CatalogOrderLineItem {
  final String name;
  /// Effective unit price charged (sale when discounted).
  final double price;
  /// Optional list/original unit (new orders only; absent on legacy rows).
  final double? listPrice;
  /// Optional list − sale amount when [offerDiscount] is true.
  final double discountAmount;
  final bool offerDiscount;
  final int quantity;
  final String notes;
  final String imageUrl;

  CatalogOrderLineItem({
    required this.name,
    required this.price,
    this.listPrice,
    this.discountAmount = 0,
    this.offerDiscount = false,
    this.quantity = 1,
    this.notes = '',
    this.imageUrl = '',
  });

  factory CatalogOrderLineItem.fromJson(Map<String, dynamic> json) {
    final listRaw = json['listPrice'];
    return CatalogOrderLineItem(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      listPrice: listRaw is num ? listRaw.toDouble() : null,
      discountAmount: (json['discountAmount'] is num)
          ? (json['discountAmount'] as num).toDouble()
          : 0,
      offerDiscount: json['offerDiscount'] == true,
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : 1,
      notes: json['notes']?.toString() ?? '',
      imageUrl:
          json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
    );
  }

  double get lineTotal => price * quantity;

  bool get hasDiscountSnapshot =>
      offerDiscount && listPrice != null && listPrice! > price;
}

/// Server OrderLoyaltyGrant summary attached to order payloads.
class OrderLoyaltyReward {
  final String status;
  final int stampsAwarded;
  final int pointsAwarded;
  final String orderLabel;

  const OrderLoyaltyReward({
    required this.status,
    this.stampsAwarded = 0,
    this.pointsAwarded = 0,
    this.orderLabel = '',
  });

  static OrderLoyaltyReward? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final status = raw['status']?.toString() ?? '';
    if (status.isEmpty) return null;
    return OrderLoyaltyReward(
      status: status,
      stampsAwarded: (raw['stampsAwarded'] is num)
          ? (raw['stampsAwarded'] as num).toInt()
          : 0,
      pointsAwarded: (raw['pointsAwarded'] is num)
          ? (raw['pointsAwarded'] as num).toInt()
          : 0,
      orderLabel: raw['orderLabel']?.toString() ?? '',
    );
  }

  bool get wasAwarded => status == 'awarded' && (stampsAwarded > 0 || pointsAwarded > 0);

  String get summaryLabel {
    if (status == 'reversed') return 'Rewards reversed';
    final parts = <String>[];
    if (stampsAwarded > 0) {
      parts.add('$stampsAwarded stamp${stampsAwarded == 1 ? '' : 's'}');
    }
    if (pointsAwarded > 0) {
      parts.add('$pointsAwarded pts');
    }
    if (parts.isEmpty) return status == 'awarded' ? 'No enrollments to reward' : status;
    return parts.join(' · ');
  }
}
