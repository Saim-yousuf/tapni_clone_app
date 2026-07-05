class CatalogItem {
  final String name;
  final double price;
  final String description;
  final bool isActive;

  CatalogItem({
    required this.name,
    this.price = 0,
    this.description = '',
    this.isActive = true,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'description': description,
        'isActive': isActive,
      };

  CatalogItem copyWith({
    String? name,
    double? price,
    String? description,
    bool? isActive,
  }) {
    return CatalogItem(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}

class CatalogOrderItem {
  final String name;
  final double price;
  final int quantity;

  CatalogOrderItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
