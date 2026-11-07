enum OrderStatus { held, pending, confirmed, completed, cancelled, noShow }

double? _readCoord(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return null;
}

/// Matches " (24.12345, 67.12345)" pins appended at checkout.
final RegExp _addressPinRe = RegExp(
  r'\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)\s*$',
);

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
  /// Best contact number for UI (order phone, else profile phone from API).
  final String customerPhone;
  final String guestEmail;
  final String businessLinkId;
  final String catalogType;
  final String bookingKind;
  /// takeaway | delivery | dine_in | service | stay
  final String orderType;
  final String fulfillmentAddress;
  final String fulfillmentNotes;
  final String tableToken;
  final String deliveryArea;
  final String scheduledFor;
  final double tipAmount;
  final double deliveryFee;
  /// Optional pin from delivery map picker.
  final double? fulfillmentLat;
  final double? fulfillmentLng;
  /// Prep estimate snapshot (minutes), when storefront/order includes it.
  final int prepTimeMinutes;
  /// True when no BarQody customer is linked yet (guest claim).
  final bool claimEligible;
  /// Customer-facing tracking code when present on the payload.
  final String guestTrackingCode;
  final List<CatalogOrderLineItem> items;
  final double totalAmount;
  /// Subtotal before points discount (falls back to totalAmount).
  final double subtotalAmount;
  final String couponCode;
  final String couponTitle;
  final double couponDiscountAmount;
  final int pointsRedeemed;
  final double pointsDiscountAmount;
  final String currency;
  final String? bookingDate;
  final String? bookingTime;
  final String bookingEnd;
  final String checkInDate;
  final String checkOutDate;
  final List<String> resourceNames;
  final OrderStatus status;
  final List<OrderStatusEvent> statusHistory;
  final bool isRead;
  final int tokenNumber;
  final String paymentStatus;
  final String paymentMethod;
  final String paymentProvider;
  final String paymentTransactionId;
  /// Friendly payment reference for UI (BQ-TXN-…).
  final String publicPaymentRef;
  final String refundStatus;
  final double refundedAmount;
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
    this.customerPhone = '',
    this.guestEmail = '',
    this.businessLinkId = '',
    this.catalogType = 'catalog',
    this.bookingKind = 'order',
    this.orderType = 'takeaway',
    this.fulfillmentAddress = '',
    this.fulfillmentNotes = '',
    this.tableToken = '',
    this.deliveryArea = '',
    this.scheduledFor = '',
    this.tipAmount = 0,
    this.deliveryFee = 0,
    this.fulfillmentLat,
    this.fulfillmentLng,
    this.prepTimeMinutes = 0,
    this.claimEligible = false,
    this.guestTrackingCode = '',
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
    this.bookingEnd = '',
    this.checkInDate = '',
    this.checkOutDate = '',
    this.resourceNames = const [],
    this.status = OrderStatus.pending,
    this.statusHistory = const [],
    this.isRead = false,
    this.tokenNumber = 0,
    this.paymentStatus = 'pending',
    this.paymentMethod = '',
    this.paymentProvider = 'none',
    this.paymentTransactionId = '',
    this.publicPaymentRef = '',
    this.refundStatus = 'none',
    this.refundedAmount = 0,
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
    final fulfillment = json['fulfillment'] is Map
        ? Map<String, dynamic>.from(json['fulfillment'] as Map)
        : <String, dynamic>{};
    final historyRaw = json['statusHistory'];
    final history = <OrderStatusEvent>[];
    if (historyRaw is List) {
      for (final h in historyRaw) {
        if (h is Map) {
          history.add(
            OrderStatusEvent.fromJson(Map<String, dynamic>.from(h)),
          );
        }
      }
    }

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
      customerPhone: () {
        final direct = json['customerPhone']?.toString().trim() ?? '';
        if (direct.isNotEmpty) return direct;
        return json['guestPhone']?.toString().trim() ?? '';
      }(),
      guestEmail: json['guestEmail']?.toString() ?? '',
      businessLinkId: json['businessLinkId']?.toString() ?? '',
      catalogType: json['catalogType']?.toString() ?? 'catalog',
      bookingKind: json['bookingKind']?.toString() ?? 'order',
      orderType: json['orderType']?.toString() ?? 'takeaway',
      fulfillmentAddress: fulfillment['address']?.toString() ?? '',
      fulfillmentNotes: fulfillment['notes']?.toString() ?? '',
      tableToken: fulfillment['tableToken']?.toString() ?? '',
      deliveryArea: fulfillment['deliveryArea']?.toString() ?? '',
      scheduledFor: fulfillment['scheduledFor']?.toString() ?? '',
      tipAmount: (fulfillment['tipAmount'] is num)
          ? (fulfillment['tipAmount'] as num).toDouble()
          : 0,
      deliveryFee: (fulfillment['deliveryFee'] is num)
          ? (fulfillment['deliveryFee'] as num).toDouble()
          : 0,
      fulfillmentLat: _readCoord(
        fulfillment['lat'] ?? fulfillment['latitude'],
      ),
      fulfillmentLng: _readCoord(
        fulfillment['lng'] ?? fulfillment['longitude'],
      ),
      prepTimeMinutes: () {
        final raw =
            fulfillment['prepTimeMinutes'] ?? json['prepTimeMinutes'];
        if (raw is num) return raw.toInt();
        return int.tryParse('$raw') ?? 0;
      }(),
      claimEligible: json['claimEligible'] == true,
      guestTrackingCode: json['guestTrackingCode']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CatalogOrderLineItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
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
      bookingEnd: json['bookingEnd']?.toString() ?? '',
      checkInDate: json['checkInDate']?.toString() ?? '',
      checkOutDate: json['checkOutDate']?.toString() ?? '',
      resourceNames: names,
      status: _parseStatus(json['status']?.toString()),
      statusHistory: history,
      isRead: json['isRead'] as bool? ?? false,
      tokenNumber: _parseToken(json['tokenNumber']),
      paymentStatus: paymentStatus,
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentProvider: json['paymentProvider']?.toString() ?? 'none',
      paymentTransactionId: json['paymentTransactionId']?.toString() ?? '',
      publicPaymentRef: json['publicPaymentRef']?.toString() ?? '',
      refundStatus: json['refundStatus']?.toString() ?? 'none',
      refundedAmount: (json['refundedAmount'] is num)
          ? (json['refundedAmount'] as num).toDouble()
          : 0,
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
      customerPhone: customerPhone,
      guestEmail: guestEmail,
      businessLinkId: businessLinkId,
      catalogType: catalogType,
      bookingKind: bookingKind,
      orderType: orderType,
      fulfillmentAddress: fulfillmentAddress,
      fulfillmentNotes: fulfillmentNotes,
      tableToken: tableToken,
      deliveryArea: deliveryArea,
      scheduledFor: scheduledFor,
      tipAmount: tipAmount,
      deliveryFee: deliveryFee,
      fulfillmentLat: fulfillmentLat,
      fulfillmentLng: fulfillmentLng,
      prepTimeMinutes: prepTimeMinutes,
      claimEligible: claimEligible,
      guestTrackingCode: guestTrackingCode,
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
      bookingEnd: bookingEnd,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      resourceNames: resourceNames,
      status: this.status,
      statusHistory: statusHistory,
      isRead: isRead,
      tokenNumber: tokenNumber,
      paymentStatus: status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProvider: paymentProvider,
      paymentTransactionId:
          paymentTransactionId ?? this.paymentTransactionId,
      publicPaymentRef: publicPaymentRef,
      refundStatus: refundStatus,
      refundedAmount: refundedAmount,
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
    if (pStatus == 'not_required') {
      return 'No payment required';
    }
    if (method == 'online') {
      switch (pStatus) {
        case 'simulated_paid':
          return 'Online · demo payment (not a real charge)';
        case 'paid':
          return 'Online · paid';
        case 'refunded':
          return 'Online · refunded';
        case 'partially_refunded':
          return 'Online · partially refunded';
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

  /// True when this order was meant to be paid online (card / Stripe).
  bool get isOnlinePaymentMethod {
    final method = paymentMethod.trim().toLowerCase();
    final provider = paymentProvider.trim().toLowerCase();
    if (method == 'cash' || method == 'cash_on_delivery' || method == 'cod') {
      return false;
    }
    if (method == 'online' || method == 'card' || method == 'stripe') {
      return true;
    }
    if (provider == 'stripe' || provider == 'mock') return true;
    return false;
  }

  bool get isCashPaymentMethod {
    final method = paymentMethod.trim().toLowerCase();
    return method == 'cash' ||
        method == 'cash_on_delivery' ||
        method == 'cod';
  }

  bool get _paymentStillOpen {
    if (status == OrderStatus.cancelled || status == OrderStatus.noShow) {
      return false;
    }
    final p = paymentStatus.trim().toLowerCase();
    if (isGenuinelyPaid || paymentSimulated) return false;
    if (p == 'paid' ||
        p == 'simulated_paid' ||
        p == 'refunded' ||
        p == 'partially_refunded' ||
        p == 'not_required') {
      return false;
    }
    return true;
  }

  /// COD / cash order not paid yet — customer can pay online from detail.
  bool get canCustomerPayNow => isCashPaymentMethod && _paymentStillOpen;

  /// Legacy alias: resume incomplete online checkout (rare; online is paid at place).
  bool get needsOnlinePayment =>
      isOnlinePaymentMethod && _paymentStillOpen;

  bool get canCustomerCancel =>
      status == OrderStatus.held ||
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed;

  bool get canBusinessRefund =>
      (isGenuinelyPaid ||
          paymentStatus == 'paid' ||
          paymentStatus == 'partially_refunded') &&
      refundStatus != 'refunded' &&
      (status == OrderStatus.confirmed ||
          status == OrderStatus.completed ||
          status == OrderStatus.cancelled);

  /// Compact payment/refund hint for list cards (empty when nothing notable).
  String get listPaymentHint {
    if (canCustomerPayNow) return 'Pay now';
    final pStatus = paymentStatus.trim().toLowerCase();
    if (pStatus == 'refunded' || hasRefund) {
      if (pStatus == 'partially_refunded' ||
          refundStatus == 'partially_refunded') {
        return 'Partially refunded';
      }
      if (pStatus == 'refunded' || refundStatus == 'refunded') {
        return 'Refunded';
      }
      if (refundStatus == 'processing') return 'Refund processing';
    }
    if (pStatus == 'failed') return 'Payment failed';
    if (pStatus == 'not_required') return 'No payment';
    if (pStatus == 'simulated_paid') return 'Demo payment';
    if (isCashPaymentMethod &&
        (pStatus == 'pending' || pStatus == 'unpaid' || pStatus.isEmpty)) {
      return 'Cash';
    }
    if (pStatus == 'pending' || pStatus == 'unpaid' || pStatus.isEmpty) {
      return 'Unpaid';
    }
    return '';
  }

  /// Friendly list reference — never Mongo/Stripe IDs.
  String get listReference {
    if (hasToken) return '#$tokenNumber';
    return kindLabel;
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
  bool get isDelivery => orderType.trim().toLowerCase() == 'delivery';

  /// Address without trailing map-pin coords (for clean UI).
  String get displayFulfillmentAddress {
    final raw = fulfillmentAddress.trim();
    if (raw.isEmpty) return '';
    return raw.replaceFirst(_addressPinRe, '').trim();
  }

  /// Best available map pin: stored lat/lng, else parsed from address.
  ({double lat, double lng})? get mapCoordinates {
    final storedLat = fulfillmentLat;
    final storedLng = fulfillmentLng;
    if (storedLat != null && storedLng != null) {
      return (lat: storedLat, lng: storedLng);
    }
    final match = _addressPinRe.firstMatch(fulfillmentAddress.trim());
    if (match == null) return null;
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  bool get canOpenDeliveryMap =>
      isDelivery &&
      (mapCoordinates != null || displayFulfillmentAddress.isNotEmpty);

  /// Web / walk-in guest with no linked Barqody account.
  bool get isGuest =>
      customerId.trim().isEmpty &&
      (guestName.trim().isNotEmpty || guestPhone.trim().isNotEmpty);

  String get displayCustomerName {
    final name = customerName.trim();
    if (name.isNotEmpty) return name;
    return guestName.trim();
  }

  /// Phone for business contact UI.
  String get displayContactPhone {
    final a = customerPhone.trim();
    if (a.isNotEmpty) return a;
    return guestPhone.trim();
  }

  bool get isPickup {
    final t = orderType.trim().toLowerCase();
    return t == 'takeaway' || t == 'pickup';
  }

  /// One clear payment chip: "Cash · Unpaid", "Online · Paid", etc.
  String get paymentStatusChipLabel {
    final p = paymentStatus.trim().toLowerCase();
    if (p == 'not_required') return 'No payment';
    if (p == 'refunded' || refundStatus == 'refunded') return 'Refunded';
    if (p == 'partially_refunded') return 'Partial refund';
    if (p == 'failed') return 'Failed';
    if (p == 'cancelled' || p == 'canceled') return 'Cancelled';

    final paid = p == 'paid' || isGenuinelyPaid;
    if (p == 'simulated_paid' || paymentSimulated) {
      return isOnlinePaymentMethod ? 'Online · Demo paid' : 'Demo paid';
    }
    if (paid) {
      if (isOnlinePaymentMethod) return 'Online · Paid';
      if (isCashPaymentMethod) return 'Cash · Paid';
      return 'Paid';
    }

    // Unpaid / pending — COD is the normal unpaid path.
    if (isCashPaymentMethod || canCustomerPayNow) return 'Cash · Unpaid';
    if (isOnlinePaymentMethod) return 'Online · Unpaid';
    return 'Unpaid';
  }

  /// Separate method chip unused when status already includes method.
  String get paymentMethodChipLabel => '';

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

  /// "Order" vs "Booking" for titles and banners.
  String get nounLabel =>
      (isAppointment || isStay || isTable) ? 'Booking' : 'Order';

  String get catalogTypeLabel {
    switch (catalogType.trim().toLowerCase()) {
      case 'menu':
        return 'Menu';
      case 'products':
        return 'Products';
      case 'services':
        return 'Services';
      case 'portfolio':
        return 'Portfolio';
      default:
        return 'Catalog';
    }
  }

  String get orderTypeLabel {
    switch (orderType.trim().toLowerCase()) {
      case 'delivery':
        return 'Delivery';
      case 'dine_in':
        return 'Dine-in';
      case 'service':
        return 'Service';
      case 'stay':
        return 'Stay';
      case 'takeaway':
        return 'Pickup';
      default:
        return orderType.trim().isEmpty ? '' : orderType;
    }
  }

  bool get hasRefund =>
      refundedAmount > 0 ||
      refundStatus == 'refunded' ||
      refundStatus == 'partially_refunded' ||
      refundStatus == 'processing';

  bool get isTerminalStatus =>
      status == OrderStatus.completed ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.noShow;

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
    final scheduled = scheduledFor.trim();
    if (scheduled.isNotEmpty) {
      try {
        final dt = DateTime.parse(scheduled).toLocal();
        final d =
            '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        final ap = dt.hour >= 12 ? 'PM' : 'AM';
        return 'Scheduled · $d · $h:$m $ap';
      } catch (_) {
        return 'Scheduled · ${scheduled.replaceFirst('T', ' · ')}';
      }
    }
    return '';
  }

  String get prepTimeLabel {
    if (prepTimeMinutes <= 0) return '';
    return 'Ready in ~$prepTimeMinutes min';
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

class OrderStatusEvent {
  final String from;
  final String to;
  final String actorType;
  final String note;
  final DateTime? createdAt;

  const OrderStatusEvent({
    this.from = '',
    this.to = '',
    this.actorType = '',
    this.note = '',
    this.createdAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      actorType: json['actorType']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt: CatalogOrder._parseDate(json['createdAt']),
    );
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
      notes: (json['notes'] ?? json['note'] ?? json['itemNotes'])
              ?.toString()
              .trim() ??
          '',
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
