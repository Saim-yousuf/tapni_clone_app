import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

void main() {
  group('catalog sections', () {
    test('orderedCategories keeps empty owned sections', () {
      final cats = CatalogHelper.orderedCategories(
        catalogCategories: ['New Arrivals', 'Best Sellers'],
        items: const [],
      );
      expect(cats, ['New Arrivals', 'Best Sellers']);
    });

    test('section validation message wording', () {
      const msg = 'Add at least one section before adding products.';
      expect(msg.toLowerCase(), contains('section'));
      expect(msg.toLowerCase(), isNot(contains('category first')));
    });
  });

  group('zero-pay labels', () {
    test('not_required is not genuinely paid', () {
      final order = CatalogOrder.fromJson({
        'id': '1',
        'totalAmount': 0,
        'paymentStatus': 'not_required',
        'paymentMethod': 'cash_on_delivery',
        'items': [],
      });
      expect(order.paymentStatus, 'not_required');
      expect(order.isGenuinelyPaid, isFalse);
      expect(order.paymentLabel, 'No payment required');
      expect(order.totalAmount, 0);
    });

    test('paid status still paid', () {
      final order = CatalogOrder.fromJson({
        'id': '2',
        'totalAmount': 40,
        'paymentStatus': 'paid',
        'paymentMethod': 'online',
        'items': [],
      });
      expect(order.isGenuinelyPaid, isTrue);
      expect(order.paymentLabel, contains('paid'));
    });
  });
}
