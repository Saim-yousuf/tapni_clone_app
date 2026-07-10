import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';

class CatalogHelper {
  static String labelForCategory(String? category) {
    if (category == 'Food & Beverage') return 'Menu';
    if (category == 'Other') return 'Catalog';
    return 'Services';
  }

  static String typeForCategory(String? category) {
    if (category == 'Food & Beverage') return 'menu';
    if (category == 'Other') return 'catalog';
    return 'services';
  }

  static String orderTitleForType(String? catalogType) {
    switch (catalogType) {
      case 'menu':
        return 'New Menu Order';
      case 'services':
        return 'New Service Order';
      default:
        return 'New Catalog Order';
    }
  }

  static String statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.noShow:
        return 'Customer No Show';
    }
  }

  static String statusApiValue(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.noShow:
        return 'no_show';
    }
  }

  static OrderStatus statusFromApi(String? value) {
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

  static const String uncategorizedLabel = 'Other';

  static String categoryOf(CatalogItem item) {
    return item.category.trim().isEmpty
        ? uncategorizedLabel
        : item.category.trim();
  }

  /// User-defined category order first, then any extra categories from items.
  static List<String> orderedCategories({
    required List<String> catalogCategories,
    required List<CatalogItem> items,
  }) {
    final ordered = <String>[];
    final seen = <String>{};

    for (final raw in catalogCategories) {
      final cat = raw.trim();
      if (cat.isEmpty) continue;
      final key = cat.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      ordered.add(cat);
    }

    for (final item in items) {
      final cat = categoryOf(item);
      final key = cat.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      ordered.add(cat);
    }

    return ordered;
  }

  static List<String> categoriesFromItems(List<CatalogItem> items) {
    return orderedCategories(catalogCategories: const [], items: items);
  }

  static Map<String, List<CatalogItem>> groupByCategory(List<CatalogItem> items) {
    final map = <String, List<CatalogItem>>{};
    for (final item in items) {
      final cat = categoryOf(item);
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  /// Groups active items in the business owner's category display order.
  static Map<String, List<CatalogItem>> groupByCategoryOrdered({
    required List<CatalogItem> items,
    required List<String> catalogCategories,
    bool activeOnly = true,
  }) {
    final source = activeOnly ? items.where((i) => i.isActive).toList() : items;
    final grouped = groupByCategory(source);
    final order = orderedCategories(
      catalogCategories: catalogCategories,
      items: source,
    );
    final result = <String, List<CatalogItem>>{};
    for (final cat in order) {
      final list = grouped[cat];
      if (list != null && list.isNotEmpty) {
        result[cat] = list;
      }
    }
    return result;
  }
}
