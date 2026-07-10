class CatalogItem {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isActive;

  CatalogItem({
    required this.name,
    this.price = 0,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.isActive = true,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'description': description,
        if (category.isNotEmpty) 'category': category,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
        'isActive': isActive,
      };

  CatalogItem copyWith({
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    bool? isActive,
  }) {
    return CatalogItem(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
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
