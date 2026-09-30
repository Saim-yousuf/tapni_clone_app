class CatalogItem {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isActive;

  /// Service-only fields (persisted with catalog links).
  final int durationMinutes;
  final bool offerDiscount;
  final double discountedPrice;
  final int rewardPoints;

  /// `appointment` | `request` | `none`
  final String bookingType;

  CatalogItem({
    required this.name,
    this.price = 0,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.isActive = true,
    this.durationMinutes = 0,
    this.offerDiscount = false,
    this.discountedPrice = 0,
    this.rewardPoints = 0,
    this.bookingType = 'appointment',
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

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
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
        'name': name,
        'price': price,
        'description': description,
        if (category.isNotEmpty) 'category': category,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
        'isActive': isActive,
        if (durationMinutes > 0) 'durationMinutes': durationMinutes,
        'offerDiscount': offerDiscount,
        if (offerDiscount && discountedPrice > 0)
          'discountedPrice': discountedPrice,
        if (rewardPoints > 0) 'rewardPoints': rewardPoints,
        'bookingType': bookingType,
      };

  CatalogItem copyWith({
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    bool? isActive,
    int? durationMinutes,
    bool? offerDiscount,
    double? discountedPrice,
    int? rewardPoints,
    String? bookingType,
  }) {
    return CatalogItem(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      offerDiscount: offerDiscount ?? this.offerDiscount,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      bookingType: bookingType ?? this.bookingType,
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
