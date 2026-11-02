import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/screens/catalog/mock_stripe_checkout_screen.dart';
import 'package:tapni_app/screens/catalog/order_placed_screen.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';

/// Shared place-order + payment selection + mock online checkout.
class CatalogCheckout {
  static String newIdempotencyKey(String prefix) {
    final t = DateTime.now().millisecondsSinceEpoch;
    final r = t.toRadixString(36);
    return '${prefix}_$t$r';
  }

  static String apiPaymentMethod(CheckoutPaymentMethod method) {
    switch (method) {
      case CheckoutPaymentMethod.online:
        return 'online';
      case CheckoutPaymentMethod.cashOnDelivery:
        return 'cash_on_delivery';
    }
  }

  /// Returns placed [CatalogOrder] or null on cancel/failure (snackbar shown).
  static Future<CatalogOrder?> placeWithPayment({
    required BuildContext context,
    required Future<ApiResponse> Function({
      required String paymentMethod,
      required String idempotencyKey,
    }) placeOrder,
    required double totalAmount,
    required String currency,
    required String customerName,
    String? customerEmail,
    String? customerUsername,
    String? guestPhone,
    String? businessName,
    String? businessUsername,
    int totalItems = 1,
    String bookingKind = 'order',
    bool pushSuccessScreen = true,
    CheckoutPaymentMethod? presetMethod,
    /// Use public mock-payment endpoint (guest Flutter checkout).
    bool publicGuestPayment = false,
  }) async {
    final method = presetMethod ??
        await showCheckoutPaymentMethodSheet(
          context,
          totalAmount: totalAmount,
          currency: currency,
        );
    if (method == null) return null;
    if (!context.mounted) return null;

    final idempotencyKey = newIdempotencyKey('app');
    final res = await placeOrder(
      paymentMethod: apiPaymentMethod(method),
      idempotencyKey: idempotencyKey,
    );

    if (!context.mounted) return null;

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Could not place order')),
      );
      return null;
    }

    final parsed = CatalogOrder.tryFromApi(res.data);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created but response was invalid')),
      );
      return null;
    }

    var placed = parsed;

    if (method == CheckoutPaymentMethod.online && placed.id.isNotEmpty) {
      final sessionToken = () {
        final raw = res.data;
        if (raw is Map) {
          final payload = raw['data'] is Map ? raw['data'] : raw;
          if (payload is Map) {
            return payload['paymentSessionToken']?.toString();
          }
        }
        return null;
      }();
      final serverTotal =
          placed.totalAmount > 0 ? placed.totalAmount : totalAmount;
      final payResult = await Navigator.of(context).push<MockPaymentResult>(
        AppPageRoute(
          builder: (_) => MockStripeCheckoutScreen(
            orderId: placed.id,
            amount: serverTotal,
            currency:
                placed.currency.isNotEmpty ? placed.currency : currency,
            customerName: customerName,
            customerEmail: customerEmail,
            businessName: businessName ?? businessUsername,
            paymentAttemptKey: '${idempotencyKey}_pay',
            paymentSessionToken: sessionToken,
            publicGuest: publicGuestPayment,
            guestPhone: guestPhone,
          ),
        ),
      );
      if (!context.mounted) return placed;
      if (payResult != null) {
        placed = placed.copyWithPayment(
          paymentStatus: payResult.paymentStatus,
          paymentMethod: payResult.paymentMethod,
          paymentTransactionId: payResult.paymentTransactionId,
          paymentSimulated: payResult.simulated,
        );
      }
    }

    if (pushSuccessScreen && context.mounted) {
      final confirmTotal =
          placed.totalAmount > 0 ? placed.totalAmount : totalAmount;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(
            token: placed.tokenNumber,
            customerUsername: customerUsername,
            customerName: customerName,
            guestPhone: guestPhone,
            businessUsername: businessUsername ?? businessName,
            totalItems: totalItems,
            totalAmount: confirmTotal,
            currency:
                placed.currency.isNotEmpty ? placed.currency : currency,
            orderId: placed.id,
            bookingKind: bookingKind,
            paymentMethod: placed.paymentMethod,
            paymentStatus: placed.paymentStatus,
            paymentSimulated: placed.paymentSimulated,
          ),
        ),
      );
    }

    return placed;
  }
}
