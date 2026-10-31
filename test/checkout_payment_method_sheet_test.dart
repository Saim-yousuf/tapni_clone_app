import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/utils/catalog_checkout.dart';

void main() {
  group('CatalogCheckout.apiPaymentMethod', () {
    test('maps cash and online', () {
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

  group('showCheckoutPaymentMethodSheet', () {
    Future<CheckoutPaymentMethod?> openSheet(WidgetTester tester) async {
      CheckoutPaymentMethod? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showCheckoutPaymentMethodSheet(
                        context,
                        totalAmount: 42,
                        currency: 'Rs',
                      );
                    },
                    child: const Text('Open pay sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open pay sheet'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('defaults to Cash selected', (tester) async {
      await openSheet(tester);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Online payment'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_off_rounded), findsOneWidget);
    });

    testWidgets('selects Online and deselects Cash', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Online payment'));
      await tester.pumpAndSettle();

      final onlineRow = find.ancestor(
        of: find.text('Online payment'),
        matching: find.byType(InkWell),
      );
      final cashRow = find.ancestor(
        of: find.text('Cash'),
        matching: find.byType(InkWell),
      );

      expect(
        find.descendant(
          of: onlineRow,
          matching: find.byIcon(Icons.radio_button_checked_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cashRow,
          matching: find.byIcon(Icons.radio_button_off_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('switching between Cash and Online updates selection', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Online payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      final cashRow = find.ancestor(
        of: find.text('Cash'),
        matching: find.byType(InkWell),
      );
      expect(
        find.descendant(
          of: cashRow,
          matching: find.byIcon(Icons.radio_button_checked_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Continue submits selected Online method', (tester) async {
      CheckoutPaymentMethod? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showCheckoutPaymentMethodSheet(
                        context,
                        totalAmount: 10,
                        currency: 'USD',
                      );
                    },
                    child: const Text('Open pay sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open pay sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Online payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result, CheckoutPaymentMethod.online);
      expect(CatalogCheckout.apiPaymentMethod(result!), 'online');
    });

    testWidgets('Continue submits selected Cash method', (tester) async {
      CheckoutPaymentMethod? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showCheckoutPaymentMethodSheet(
                        context,
                        totalAmount: 10,
                        currency: 'USD',
                      );
                    },
                    child: const Text('Open pay sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open pay sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Online payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result, CheckoutPaymentMethod.cashOnDelivery);
      expect(CatalogCheckout.apiPaymentMethod(result!), 'cash_on_delivery');
    });
  });
}
