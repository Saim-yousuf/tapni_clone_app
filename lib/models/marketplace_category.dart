/// Global BarQody Marketplace taxonomy (admin-managed).
/// Independent of business website sections (`CatalogItem.category`).
class MarketplaceCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String imageUrl;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final List<MarketplaceCategory> children;

  const MarketplaceCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.icon = 'category_rounded',
    this.imageUrl = '',
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
  });

  bool get isTopLevel => parentId == null || parentId!.isEmpty;

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) {
    final kids = <MarketplaceCategory>[];
    final rawKids = json['children'];
    if (rawKids is List) {
      for (final c in rawKids) {
        if (c is Map<String, dynamic>) {
          kids.add(MarketplaceCategory.fromJson(c));
        } else if (c is Map) {
          kids.add(MarketplaceCategory.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    final parentRaw = json['parentId'];
    return MarketplaceCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category_rounded',
      imageUrl: json['imageUrl']?.toString() ?? '',
      parentId: parentRaw == null || parentRaw.toString().isEmpty
          ? null
          : parentRaw.toString(),
      sortOrder: (json['sortOrder'] is num)
          ? (json['sortOrder'] as num).toInt()
          : int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      children: kids,
    );
  }
}
