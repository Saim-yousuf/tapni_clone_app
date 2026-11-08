import 'dart:math' as math;

/// True for Mongo ObjectId hex strings. Client temp ids (`opt_…`) must not be sent.
bool isPersistedCatalogOptionId(String id) {
  final s = id.trim();
  if (s.length != 24) return false;
  return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(s);
}

/// Accepts num or numeric string from API / cache JSON.
double catalogMoneyOf(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw == null) return 0;
  final s = raw.toString().trim().replaceAll(',', '');
  if (s.isEmpty) return 0;
  return double.tryParse(s) ?? 0;
}

int catalogIntOf(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString().trim() ?? '') ?? 0;
}

/// Size / SKU of a [CatalogItem] (e.g. Small / Medium / Large).
class CatalogVariant {
  final String id;
  final String name;
  final double price;
  final int sortOrder;
  final bool isActive;

  const CatalogVariant({
    this.id = '',
    required this.name,
    this.price = 0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CatalogVariant.fromJson(Map<String, dynamic> json) {
    return CatalogVariant(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: catalogMoneyOf(json['price']),
      sortOrder: catalogIntOf(json['sortOrder']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (isPersistedCatalogOptionId(id)) '_id': id,
        'name': name,
        'price': price,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  CatalogVariant copyWith({
    String? id,
    String? name,
    double? price,
    int? sortOrder,
    bool? isActive,
  }) {
    return CatalogVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// One choice inside an option group (e.g. Extra cheese).
class CatalogOption {
  final String id;
  final String name;
  final double price;
  final int sortOrder;
  final bool isActive;

  const CatalogOption({
    this.id = '',
    required this.name,
    this.price = 0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: catalogMoneyOf(json['price']),
      sortOrder: catalogIntOf(json['sortOrder']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (isPersistedCatalogOptionId(id)) '_id': id,
        'name': name,
        'price': price,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  CatalogOption copyWith({
    String? id,
    String? name,
    double? price,
    int? sortOrder,
    bool? isActive,
  }) {
    return CatalogOption(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Required/optional choice set on a catalog item (e.g. Toppings, Crust).
class CatalogOptionGroup {
  final String id;
  final String name;

  /// `single` | `multiple`
  final String selectionType;
  final int minSelections;
  final int maxSelections;
  final int sortOrder;
  final List<CatalogOption> options;

  const CatalogOptionGroup({
    this.id = '',
    required this.name,
    this.selectionType = 'single',
    this.minSelections = 0,
    this.maxSelections = 1,
    this.sortOrder = 0,
    this.options = const [],
  });

  bool get isSingle => selectionType != 'multiple';
  bool get isRequired => minSelections > 0;

  List<CatalogOption> get activeOptions =>
      options.where((o) => o.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory CatalogOptionGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    final options = <CatalogOption>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          options.add(CatalogOption.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final sel = json['selectionType']?.toString().toLowerCase().trim();
    final maxRaw = (json['maxSelections'] is num)
        ? (json['maxSelections'] as num).toInt()
        : 1;
    final minRaw = (json['minSelections'] is num)
        ? (json['minSelections'] as num).toInt()
        : 0;
    return CatalogOptionGroup(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      selectionType: sel == 'multiple' ? 'multiple' : 'single',
      minSelections: math.max(0, minRaw),
      maxSelections: math.max(1, maxRaw),
      sortOrder: (json['sortOrder'] is num)
          ? (json['sortOrder'] as num).toInt()
          : 0,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        if (isPersistedCatalogOptionId(id)) '_id': id,
        'name': name,
        'selectionType': selectionType,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'sortOrder': sortOrder,
        'options': options.map((o) => o.toJson()).toList(),
      };

  CatalogOptionGroup copyWith({
    String? id,
    String? name,
    String? selectionType,
    int? minSelections,
    int? maxSelections,
    int? sortOrder,
    List<CatalogOption>? options,
  }) {
    return CatalogOptionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      selectionType: selectionType ?? this.selectionType,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      sortOrder: sortOrder ?? this.sortOrder,
      options: options ?? this.options,
    );
  }
}

String newCatalogOptionId() =>
    'opt_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(1 << 20)}';
