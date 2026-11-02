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
  final String catalogType;
  final String currency;
  final String websiteSlug;
  final List<CatalogItem> catalogItems;
  final List<ExploreCartLine> lines;

  const ExploreCartVendor({
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    required this.catalogType,
    this.currency = 'PKR',
    this.websiteSlug = '',
    required this.catalogItems,
    required this.lines,
  });

  double get total =>
      lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  int get itemCount =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  ExploreCartVendor copyWith({
    List<CatalogItem>? catalogItems,
    List<ExploreCartLine>? lines,
    String? businessName,
    String? catalogType,
    String? currency,
    String? websiteSlug,
  }) {
    return ExploreCartVendor(
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName ?? this.businessName,
      catalogType: catalogType ?? this.catalogType,
      currency: currency ?? this.currency,
      websiteSlug: websiteSlug ?? this.websiteSlug,
      catalogItems: catalogItems ?? this.catalogItems,
      lines: lines ?? this.lines,
    );
  }
}

/// Kept for older call sites; prefer [ExploreCartVendor].
@Deprecated('Use ExploreCartVendor')
typedef ExploreCartSession = ExploreCartVendor;
