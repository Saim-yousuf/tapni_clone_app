import 'package:tapni_app/models/catalog_item.dart';

class ExploreCartLine {
  final CatalogItem item;
  final int quantity;
  final String notes;

  const ExploreCartLine({
    required this.item,
    this.quantity = 1,
    this.notes = '',
  });

  double get lineTotal => item.price * quantity;

  ExploreCartLine copyWith({int? quantity, String? notes}) {
    return ExploreCartLine(
      item: item,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
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
  final List<CatalogItem> catalogItems;
  final List<ExploreCartLine> lines;

  const ExploreCartVendor({
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    required this.catalogType,
    this.currency = 'PKR',
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
  }) {
    return ExploreCartVendor(
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName ?? this.businessName,
      catalogType: catalogType ?? this.catalogType,
      currency: currency ?? this.currency,
      catalogItems: catalogItems ?? this.catalogItems,
      lines: lines ?? this.lines,
    );
  }
}

/// Kept for older call sites; prefer [ExploreCartVendor].
@Deprecated('Use ExploreCartVendor')
typedef ExploreCartSession = ExploreCartVendor;
