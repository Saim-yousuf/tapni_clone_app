class CatalogItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  /// Business website section name (owner-managed). Not a marketplace category.
  final String category;

  /// Global MarketplaceCategory top-level id (optional discovery).
  final String marketplaceCategoryId;

  /// Global MarketplaceCategory child id (optional; must match parent).
  final String marketplaceSubcategoryId;

  final bool isActive;

  /// Service-only fields (persisted with catalog links).
  final int durationMinutes;
  final bool offerDiscount;
  final double discountedPrice;
  final int rewardPoints;

  /// `appointment` | `request` | `none`
  final String bookingType;

  /// Highlight on menu website home (featured strip).
  final bool featured;

  /// Display tags: veg | spicy | popular.
  final List<String> tags;

  CatalogItem({
    this.id = '',
    required this.name,
    this.price = 0,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.marketplaceCategoryId = '',
    this.marketplaceSubcategoryId = '',
    this.isActive = true,
    this.durationMinutes = 0,
    this.offerDiscount = false,
    this.discountedPrice = 0,
    this.rewardPoints = 0,
    this.bookingType = 'appointment',
    this.featured = false,
    this.tags = const [],
  });

  /// Price shown to customers (discounted when offer is active).
  double get displayPrice {
    if (offerDiscount &&
        discountedPrice > 0 &&
        discountedPrice < price) {
      return discountedPrice;
    }
    return price;
  }

  String get durationLabel {
    if (durationMinutes <= 0) return '';
    return '$durationMinutes min';
  }

  bool get isListedOnMarketplace => marketplaceCategoryId.trim().isNotEmpty;

  bool get isVeg => tags.contains('veg');
  bool get isSpicy => tags.contains('spicy');
  bool get isPopular => tags.contains('popular');

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        final s = t?.toString().trim().toLowerCase() ?? '';
        if (s == 'veg' || s == 'spicy' || s == 'popular') {
          if (!tags.contains(s)) tags.add(s);
        }
      }
    }
    return CatalogItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      marketplaceCategoryId:
          json['marketplaceCategoryId']?.toString() ?? '',
      marketplaceSubcategoryId:
          json['marketplaceSubcategoryId']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      durationMinutes: (json['durationMinutes'] is num)
          ? (json['durationMinutes'] as num).toInt()
          : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
      offerDiscount: json['offerDiscount'] as bool? ?? false,
      discountedPrice: (json['discountedPrice'] is num)
          ? (json['discountedPrice'] as num).toDouble()
          : 0,
      rewardPoints: (json['rewardPoints'] is num)
          ? (json['rewardPoints'] as num).toInt()
          : int.tryParse(json['rewardPoints']?.toString() ?? '') ?? 0,
      bookingType: _normalizeBookingType(json['bookingType']?.toString()),
      featured: json['featured'] == true,
      tags: tags,
    );
  }

  static String _normalizeBookingType(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'request':
        return 'request';
      case 'none':
      case 'no_scheduling':
      case 'noscheduling':
        return 'none';
      default:
        return 'appointment';
    }
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'name': name,
        'price': price,
        'description': description,
        if (category.isNotEmpty) 'category': category,
        'marketplaceCategoryId': marketplaceCategoryId,
        'marketplaceSubcategoryId': marketplaceSubcategoryId,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
        'isActive': isActive,
        if (durationMinutes > 0) 'durationMinutes': durationMinutes,
        'offerDiscount': offerDiscount,
        if (offerDiscount && discountedPrice > 0)
          'discountedPrice': discountedPrice,
        if (rewardPoints > 0) 'rewardPoints': rewardPoints,
        'bookingType': bookingType,
        'featured': featured,
        'tags': tags,
      };

  CatalogItem copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    String? marketplaceCategoryId,
    String? marketplaceSubcategoryId,
    bool? isActive,
    int? durationMinutes,
    bool? offerDiscount,
    double? discountedPrice,
    int? rewardPoints,
    String? bookingType,
    bool? featured,
    List<String>? tags,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      marketplaceCategoryId:
          marketplaceCategoryId ?? this.marketplaceCategoryId,
      marketplaceSubcategoryId:
          marketplaceSubcategoryId ?? this.marketplaceSubcategoryId,
      isActive: isActive ?? this.isActive,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      offerDiscount: offerDiscount ?? this.offerDiscount,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      bookingType: bookingType ?? this.bookingType,
      featured: featured ?? this.featured,
      tags: tags ?? this.tags,
    );
  }
}

class CatalogOrderItem {
  final String name;
  final double price;
  final int quantity;
  final String notes;

  CatalogOrderItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes = '',
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        if (notes.isNotEmpty) 'notes': notes,
      };
}
