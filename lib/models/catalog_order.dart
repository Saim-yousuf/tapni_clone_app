enum OrderStatus { pending, completed, cancelled, noShow }

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
  final String businessLinkId;
  final String catalogType;
  final List<CatalogOrderLineItem> items;
  final double totalAmount;
  final OrderStatus status;
  final bool isRead;
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
    this.businessLinkId = '',
    this.catalogType = 'catalog',
    required this.items,
    this.totalAmount = 0,
    this.status = OrderStatus.pending,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CatalogOrder.fromJson(Map<String, dynamic> json) {
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
      businessLinkId: json['businessLinkId']?.toString() ?? '',
      catalogType: json['catalogType']?.toString() ?? 'catalog',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CatalogOrderLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : 0,
      status: _parseStatus(json['status']?.toString()),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static OrderStatus _parseStatus(String? value) {
    switch (value) {
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'no_show':
        return OrderStatus.noShow;
      default:
        return OrderStatus.pending;
    }
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
}

class CatalogOrderLineItem {
  final String name;
  final double price;
  final int quantity;

  CatalogOrderLineItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory CatalogOrderLineItem.fromJson(Map<String, dynamic> json) {
    return CatalogOrderLineItem(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
    );
  }

  double get lineTotal => price * quantity;
}
