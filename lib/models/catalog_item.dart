import 'package:tapni_app/models/catalog_item_options.dart';

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

  /// Size / SKU choices (menu). Empty = no size step.
  final List<CatalogVariant> variants;

  /// Item-local / resolved option groups (legacy or after [withResolvedOptionGroups]).
  final List<CatalogOptionGroup> optionGroups;

  /// Shared library group ids (`SocialLink.catalogModifierGroups`).
  final List<String> optionGroupIds;

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
    this.variants = const [],
    this.optionGroups = const [],
    this.optionGroupIds = const [],
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

  List<CatalogVariant> get activeVariants {
    final list = variants.where((v) => v.isActive && v.name.trim().isNotEmpty).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<CatalogOptionGroup> get activeOptionGroups {
    final list = optionGroups
        .where((g) => g.name.trim().isNotEmpty && g.activeOptions.isNotEmpty)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  bool get hasConfiguration =>
      activeVariants.isNotEmpty ||
      activeOptionGroups.isNotEmpty ||
      optionGroupIds.isNotEmpty;

  /// Expand shared library refs into [optionGroups] for configurator / pricing.
  CatalogItem withResolvedOptionGroups(List<CatalogOptionGroup> library) {
    if (optionGroupIds.isEmpty) return this;
    final byId = <String, CatalogOptionGroup>{};
    for (final g in library) {
      if (g.id.isNotEmpty) byId[g.id] = g;
    }
    final resolved = <CatalogOptionGroup>[];
    final seen = <String>{};
    for (final id in optionGroupIds) {
      final g = byId[id];
      if (g != null && seen.add(g.id)) resolved.add(g);
    }
    for (final g in optionGroups) {
      final key = g.id.isNotEmpty ? g.id : 'local:${g.name}';
      if (g.id.isNotEmpty && optionGroupIds.contains(g.id)) continue;
      if (seen.add(key)) resolved.add(g);
    }
    return copyWith(optionGroups: resolved);
  }

  /// Lowest sellable unit before options (for “From” UI).
  double get startingPrice {
    final vs = activeVariants;
    if (vs.isEmpty) return displayPrice;
    var min = vs.first.price;
    for (final v in vs) {
      if (v.price < min) min = v.price;
    }
    return min;
  }

  /// Configured unit: variant (or base display) + selected option upcharges.
  double configuredUnitPrice({
    String? variantId,
    List<String> optionIds = const [],
  }) {
    double base = displayPrice;
    final vs = activeVariants;
    if (vs.isNotEmpty) {
      final id = (variantId ?? '').trim();
      CatalogVariant? match;
      for (final v in vs) {
        if (v.id == id) {
          match = v;
          break;
        }
      }
      if (match == null && vs.length == 1) match = vs.first;
      if (match != null) base = match.price;
    }
    var extras = 0.0;
    final want =
        optionIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (want.isNotEmpty) {
      for (final g in activeOptionGroups) {
        for (final o in g.activeOptions) {
          if (want.contains(o.id)) extras += o.price;
        }
      }
    }
    return base + extras;
  }

  String configurationLabel({
    String? variantId,
    List<String> optionIds = const [],
  }) {
    final parts = <String>[];
    final vs = activeVariants;
    if (vs.isNotEmpty) {
      final id = (variantId ?? '').trim();
      CatalogVariant? v;
      for (final cand in vs) {
        if (cand.id == id) {
          v = cand;
          break;
        }
      }
      if (v == null && vs.length == 1) v = vs.first;
      if (v != null && v.name.trim().isNotEmpty) parts.add(v.name.trim());
    }
    final want = optionIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (want.isNotEmpty) {
      for (final g in activeOptionGroups) {
        for (final o in g.activeOptions) {
          if (want.contains(o.id) && o.name.trim().isNotEmpty) {
            parts.add(o.name.trim());
          }
        }
      }
    }
    return parts.join(' · ');
  }

  String? validateConfiguration({
    String? variantId,
    List<String> optionIds = const [],
  }) {
    final vs = activeVariants;
    if (vs.isNotEmpty) {
      final id = (variantId ?? '').trim();
      final ok = vs.any((v) => v.id == id) || (id.isEmpty && vs.length == 1);
      if (!ok) return 'Choose a size';
    }
    final want = optionIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final known = <String>{};
    for (final g in activeOptionGroups) {
      for (final o in g.activeOptions) {
        known.add(o.id);
      }
    }
    for (final id in want) {
      if (!known.contains(id)) return 'Invalid option selected';
    }
    for (final g in activeOptionGroups) {
      final selected = g.activeOptions.where((o) => want.contains(o.id)).length;
      if (selected < g.minSelections) {
        return g.isRequired
            ? 'Choose ${g.name}'
            : 'Select at least ${g.minSelections} for ${g.name}';
      }
      if (selected > g.maxSelections) {
        return 'Select at most ${g.maxSelections} for ${g.name}';
      }
    }
    return null;
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
      price: catalogMoneyOf(json['price']),
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
      discountedPrice: catalogMoneyOf(json['discountedPrice']),
      rewardPoints: (json['rewardPoints'] is num)
          ? (json['rewardPoints'] as num).toInt()
          : int.tryParse(json['rewardPoints']?.toString() ?? '') ?? 0,
      bookingType: _normalizeBookingType(json['bookingType']?.toString()),
      featured: json['featured'] == true,
      tags: tags,
      variants: _parseVariants(json['variants']),
      optionGroups: _parseOptionGroups(json['optionGroups']),
      optionGroupIds: _parseIdList(json['optionGroupIds']),
    );
  }

  static List<String> _parseIdList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<CatalogVariant> _parseVariants(dynamic raw) {
    if (raw is! List) return const [];
    final out = <CatalogVariant>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(CatalogVariant.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  static List<CatalogOptionGroup> _parseOptionGroups(dynamic raw) {
    if (raw is! List) return const [];
    final out = <CatalogOptionGroup>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(CatalogOptionGroup.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
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
        'variants': variants.map((v) => v.toJson()).toList(),
        'optionGroups': optionGroups.map((g) => g.toJson()).toList(),
        'optionGroupIds': optionGroupIds,
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
    List<CatalogVariant>? variants,
    List<CatalogOptionGroup>? optionGroups,
    List<String>? optionGroupIds,
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
      variants: variants ?? this.variants,
      optionGroups: optionGroups ?? this.optionGroups,
      optionGroupIds: optionGroupIds ?? this.optionGroupIds,
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
