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
}
