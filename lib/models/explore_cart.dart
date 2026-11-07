import 'package:tapni_app/models/catalog_item.dart';

class ExploreCartLine {
  final CatalogItem item;
  final int quantity;
  final String notes;

  /// Appointment / stay fields from website or native booking sheets.
  final String bookingDate;
  final String bookingTime;
  final String resourceId;
  final String resourceName;
  final String checkInDate;
  final String checkOutDate;

  /// `order` | `appointment` | `stay` (empty = treat as order).
  final String bookingKind;

  const ExploreCartLine({
    required this.item,
    this.quantity = 1,
    this.notes = '',
    this.bookingDate = '',
    this.bookingTime = '',
    this.resourceId = '',
    this.resourceName = '',
    this.checkInDate = '',
    this.checkOutDate = '',
    this.bookingKind = '',
  });

  double get lineTotal => item.displayPrice * quantity;

  bool get hasAppointment =>
      bookingKind == 'appointment' ||
      (bookingDate.isNotEmpty && bookingTime.isNotEmpty);

  bool get hasStay =>
      bookingKind == 'stay' ||
      (checkInDate.isNotEmpty && checkOutDate.isNotEmpty);

  bool sameIdentityAs(ExploreCartLine other) {
    final sameItem = (item.id.isNotEmpty && item.id == other.item.id) ||
        item.name == other.item.name;
    return sameItem &&
        bookingDate == other.bookingDate &&
        bookingTime == other.bookingTime &&
        resourceId == other.resourceId &&
        checkInDate == other.checkInDate &&
        checkOutDate == other.checkOutDate &&
        bookingKind == other.bookingKind;
  }

  ExploreCartLine copyWith({int? quantity, String? notes}) {
    return ExploreCartLine(
      item: item,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      resourceId: resourceId,
      resourceName: resourceName,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      bookingKind: bookingKind,
    );
  }
}

/// One store's basket inside the shared Explore cart.
class ExploreCartVendor {
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String businessUsername;
  final String catalogType;
  final String currency;
  final String websiteSlug;
  /// Menu storefront: owner paused accepting orders.
  final bool ordersPaused;
  /// Menu storefront: outside weekly hours (browse-only).
  final bool isClosedNow;
  final double deliveryFee;
  final double freeDeliveryAbove;
  final double minOrderAmount;
  final bool acceptPickup;
  final bool acceptDelivery;
  final bool tipsEnabled;
  final bool scheduleOrdersEnabled;
  final List<String> deliveryAreas;
  final int prepTimeMinutes;
  final List<CatalogItem> catalogItems;
  final List<ExploreCartLine> lines;

  const ExploreCartVendor({
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    this.businessUsername = '',
    required this.catalogType,
    this.currency = 'PKR',
    this.websiteSlug = '',
    this.ordersPaused = false,
    this.isClosedNow = false,
    this.deliveryFee = 0,
    this.freeDeliveryAbove = 0,
    this.minOrderAmount = 0,
    this.acceptPickup = true,
    this.acceptDelivery = true,
    this.tipsEnabled = false,
    this.scheduleOrdersEnabled = false,
    this.deliveryAreas = const [],
    this.prepTimeMinutes = 0,
    required this.catalogItems,
    required this.lines,
  });

  double get total =>
      lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  int get itemCount =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  /// Delivery fee after free-above threshold (0 when free).
  double deliveryFeeForSubtotal(double subtotal) {
    if (deliveryFee <= 0) return 0;
    if (freeDeliveryAbove > 0 && subtotal >= freeDeliveryAbove) return 0;
    return deliveryFee;
  }

  bool get belowMinOrder =>
      minOrderAmount > 0 && total + 1e-9 < minOrderAmount;

  double get minOrderShortfall =>
      belowMinOrder ? (minOrderAmount - total) : 0;

  /// Closed now but owner allows scheduling for later.
  bool get canScheduleWhileClosed =>
      isClosedNow && scheduleOrdersEnabled && !ordersPaused;

  /// Non-null when Place Order / Continue should be hard-blocked.
  /// Closed + schedule enabled is allowed through so checkout can pick a time.
  String? get orderBlockedLabel {
    if (ordersPaused) return 'Orders paused';
    if (isClosedNow && !scheduleOrdersEnabled) return 'Restaurant closed';
    return null;
  }

  ExploreCartVendor copyWith({
    List<CatalogItem>? catalogItems,
    List<ExploreCartLine>? lines,
    String? businessName,
    String? businessUsername,
    String? catalogType,
    String? currency,
    String? websiteSlug,
    bool? ordersPaused,
    bool? isClosedNow,
    double? deliveryFee,
    double? freeDeliveryAbove,
    double? minOrderAmount,
    bool? acceptPickup,
    bool? acceptDelivery,
    bool? tipsEnabled,
    bool? scheduleOrdersEnabled,
    List<String>? deliveryAreas,
    int? prepTimeMinutes,
  }) {
    return ExploreCartVendor(
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName ?? this.businessName,
      businessUsername: businessUsername ?? this.businessUsername,
      catalogType: catalogType ?? this.catalogType,
      currency: currency ?? this.currency,
      websiteSlug: websiteSlug ?? this.websiteSlug,
      ordersPaused: ordersPaused ?? this.ordersPaused,
      isClosedNow: isClosedNow ?? this.isClosedNow,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      acceptPickup: acceptPickup ?? this.acceptPickup,
      acceptDelivery: acceptDelivery ?? this.acceptDelivery,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      scheduleOrdersEnabled:
          scheduleOrdersEnabled ?? this.scheduleOrdersEnabled,
      deliveryAreas: deliveryAreas ?? this.deliveryAreas,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      catalogItems: catalogItems ?? this.catalogItems,
      lines: lines ?? this.lines,
    );
  }
}

/// Kept for older call sites; prefer [ExploreCartVendor].
@Deprecated('Use ExploreCartVendor')
typedef ExploreCartSession = ExploreCartVendor;
