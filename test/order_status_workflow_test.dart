import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/utils/catalog_checkout.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

void main() {
  group('OrderStatus held support', () {
    test('parses held from API', () {
      final order = CatalogOrder.fromJson({
        'id': '1',
        'businessId': 'b',
        'businessName': 'Biz',
        'businessUsername': 'biz',
        'customerId': '',
        'customerName': 'Guest',
        'customerUsername': '',
        'items': [],
        'status': 'held',
      });
      expect(order.status, OrderStatus.held);
      expect(order.statusApiValue, 'held');
      expect(CatalogHelper.statusFromApi('held'), OrderStatus.held);
      expect(CatalogHelper.statusApiValue(OrderStatus.held), 'held');
    });

    test('does not collapse held to pending', () {
      expect(CatalogHelper.statusFromApi('held'), isNot(OrderStatus.pending));
    });
  });

  group('Payment method mapping still intact', () {
    test('cash and online API values', () {
      expect(
        CatalogCheckout.apiPaymentMethod(CheckoutPaymentMethod.cashOnDelivery),
        'cash_on_delivery',
      );
      expect(
        CatalogCheckout.apiPaymentMethod(CheckoutPaymentMethod.online),
        'online',
      );
    });
  });
}
