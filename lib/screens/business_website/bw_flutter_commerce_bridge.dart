import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_cart.dart';

/// Validated payload from website → Flutter `addToCart` bridge.
class BwBridgeAddToCart {
  final ExploreCartLine line;
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String businessUsername;
  final String catalogType;
  final String currency;
  final String websiteSlug;
  final String bookingMode;

  const BwBridgeAddToCart({
    required this.line,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    required this.businessUsername,
    required this.catalogType,
    required this.currency,
    required this.websiteSlug,
    required this.bookingMode,
  });
}

/// Parses and validates BarqodyBridge / postMessage commerce payloads.
/// Rejects malformed or unauthorized-looking messages without trusting prices.
class BwFlutterCommerceBridge {
  static String _str(dynamic v) => (v?.toString() ?? '').trim();

  static int _qty(dynamic v) {
    if (v is num) return v.round().clamp(1, 999);
    return (int.tryParse(_str(v)) ?? 1).clamp(1, 999);
  }

  static String _catalogType(String websiteType, String catalogType) {
    final c = catalogType.toLowerCase();
    if (c == 'services' || c == 'service') return 'services';
    if (c == 'products' || c == 'product') return 'products';
    if (c == 'menu' || c == 'catalog') return 'menu';
    final w = websiteType.toLowerCase();
    if (w == 'service' || w == 'services') return 'services';
    if (w == 'products' || w == 'product') return 'products';
    if (w == 'portfolio') return 'portfolio';
    return 'menu';
  }

  static String _bookingKind(String mode, Map item) {
    final explicit = _str(item['bookingKind']).toLowerCase();
    if (explicit == 'appointment' || explicit == 'stay' || explicit == 'order') {
      return explicit;
    }
    final m = mode.toLowerCase();
    if (m == 'appointment') return 'appointment';
    if (m == 'stay') return 'stay';
    final hasAppt = _str(item['bookingDate']).isNotEmpty &&
        _str(item['bookingTime']).isNotEmpty;
    if (hasAppt) return 'appointment';
    final hasStay = _str(item['checkInDate']).isNotEmpty &&
        _str(item['checkOutDate']).isNotEmpty;
    if (hasStay) return 'stay';
    return 'order';
  }

  /// Returns null when the payload must be rejected.
  static BwBridgeAddToCart? parseAddToCart(Map raw) {
    final action = _str(raw['action']);
    if (action != 'addToCart') return null;

    final itemRaw = raw['item'];
    if (itemRaw is! Map) return null;
    final item = Map<String, dynamic>.from(itemRaw);

    final siteRaw = raw['site'];
    final site = siteRaw is Map
        ? Map<String, dynamic>.from(siteRaw)
        : <String, dynamic>{};

    final businessId = _str(site['businessId']);
    // Require a stable business id — never invent one from the client alone.
    if (businessId.isEmpty || businessId.startsWith('demo:')) return null;

    final catalogItemId = _str(item['catalogItemId'] ?? item['id']);
    final name = _str(item['name']);
    if (name.isEmpty && catalogItemId.isEmpty) return null;

    final websiteType = _str(site['websiteType']);
    final catalogType = _catalogType(
      websiteType,
      _str(site['catalogType']),
    );
    if (catalogType == 'portfolio') return null;

    final bookingMode = _str(site['bookingMode']);
    final bookingKind = _bookingKind(bookingMode, item);

    // Prices from WebView are display-only; server revalidates on placeOrder.
    final priceRaw = item['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(_str(priceRaw)) ?? 0;

    final catalogItem = CatalogItem(
      id: catalogItemId,
      name: name.isNotEmpty ? name : 'Item',
      price: price < 0 ? 0 : price,
      imageUrl: _str(item['image'] ?? item['imageUrl']),
      category: _str(item['category']),
      isActive: true,
    );

    final line = ExploreCartLine(
      item: catalogItem,
      quantity: _qty(item['quantity']),
      notes: _str(item['notes']),
      bookingDate: _str(item['bookingDate']),
      bookingTime: _str(item['bookingTime']),
      resourceId: _str(item['resourceId']),
      resourceName: _str(item['resourceName']),
      checkInDate: _str(item['checkInDate']),
      checkOutDate: _str(item['checkOutDate']),
      bookingKind: bookingKind,
    );

    if (bookingKind == 'appointment' &&
        (line.bookingDate.isEmpty || line.bookingTime.isEmpty)) {
      return null;
    }
    if (bookingKind == 'stay' &&
        (line.checkInDate.isEmpty || line.checkOutDate.isEmpty)) {
      return null;
    }

    return BwBridgeAddToCart(
      line: line,
      businessId: businessId,
      businessLinkId: _str(site['businessLinkId']),
      businessName: _str(site['businessName']).isNotEmpty
          ? _str(site['businessName'])
          : (_str(site['businessUsername']).isNotEmpty
              ? _str(site['businessUsername'])
              : 'Business'),
      businessUsername: _str(site['businessUsername']),
      catalogType: catalogType,
      currency: _str(site['currency']).isNotEmpty
          ? _str(site['currency'])
          : 'PKR',
      websiteSlug: _str(site['websiteSlug']),
      bookingMode: bookingMode,
    );
  }

  static bool isOpenCart(Map raw) => _str(raw['action']) == 'openCart';
}
