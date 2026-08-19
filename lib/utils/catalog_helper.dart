import 'package:tapni_app/l10n/app_localizations.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_order.dart';

class CatalogHelper {
  static String labelForCategory(String? category, AppLocalizations l10n) {
    if (category == 'Food & Beverage') return l10n.menu;
    if (category == 'Other') return l10n.catalog;
    return l10n.services;
  }

  static String typeForCategory(String? category) {
    if (category == 'Food & Beverage') return 'menu';
    if (category == 'Other') return 'catalog';
    return 'services';
  }

  static String orderTitleForType(String? catalogType, AppLocalizations l10n) {
    switch (catalogType) {
      case 'menu':
        return l10n.newMenuOrder;
      case 'services':
        return l10n.newServiceOrder;
      default:
        return l10n.newCatalogOrder;
    }
  }

  static String typeLabel(String? catalogType, AppLocalizations l10n) {
    switch (catalogType) {
      case 'menu':
        return l10n.menu;
      case 'services':
        return l10n.services;
      case 'documents':
        return l10n.documents;
      default:
        return l10n.catalog;
    }
  }

  static String statusLabel(OrderStatus status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.pending:
        return l10n.pending;
      case OrderStatus.completed:
        return l10n.completed;
      case OrderStatus.cancelled:
        return l10n.cancelled;
      case OrderStatus.noShow:
        return l10n.customerNoShow;
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
