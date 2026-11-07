import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/screens/catalog/checkout_payment_method_sheet.dart';
import 'package:tapni_app/screens/catalog/order_placed_screen.dart';
import 'package:tapni_app/screens/catalog/stripe_checkout_screen.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/utils/stripe_checkout_outcome.dart';
import 'package:tapni_app/widgets/app_toast.dart';

/// Shared place-order + payment selection + Stripe online checkout.
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
  ///
  /// Zero-payable bookings skip the payment sheet and Stripe when the
  /// **server** total is ≤ 0 (`paymentStatus: not_required`). Client-submitted
  /// zero cannot bypass payment for paid services.
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
    /// Use public payment endpoints (guest Flutter checkout).
    bool publicGuestPayment = false,
  }) async {
    CheckoutPaymentMethod? method = presetMethod;
    if (method == null && totalAmount > 0) {
      method = await showCheckoutPaymentMethodSheet(
        context,
        totalAmount: totalAmount,
        currency: currency,
      );
      if (method == null) return null;
    }
    // Provisional method for client-side free carts; server total decides next.
    method ??= CheckoutPaymentMethod.cashOnDelivery;
    if (!context.mounted) return null;

    final idempotencyKey = newIdempotencyKey('app');
    final res = await placeOrder(
      paymentMethod: apiPaymentMethod(method),
      idempotencyKey: idempotencyKey,
    );

    if (!context.mounted) return null;

    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not place order',
            kind: AppToastKind.error,
          );
      return null;
    }

    final parsed = CatalogOrder.tryFromApi(res.data);
    if (parsed == null) {
      showAppToast(
            context,
            'Order created but response was invalid',
            kind: AppToastKind.error,
          );
      return null;
    }

    var placed = parsed;
    final serverTotal = placed.totalAmount;

    // Server priced > 0 but client thought free → require real payment choice.
    if (serverTotal > 0 && totalAmount <= 0 && presetMethod == null) {
      final paidMethod = await showCheckoutPaymentMethodSheet(
        context,
        totalAmount: serverTotal,
        currency: placed.currency.isNotEmpty ? placed.currency : currency,
      );
      if (!context.mounted) return placed;
      if (paidMethod == null) {
        showAppToast(
              context,
              'Payment is required for this booking',
              kind: AppToastKind.warning,
            );
        return placed;
      }
      method = paidMethod;
    }

    var onlinePaymentOk = method != CheckoutPaymentMethod.online;

    if (serverTotal <= 0) {
      // Free booking — payment not required (server sets not_required).
      onlinePaymentOk = true;
    } else if (method == CheckoutPaymentMethod.online &&
        placed.id.isNotEmpty) {
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
      final signedIn = SharedPrefHelper.getString(
            SharedPrefHelper.utils.authorizedToken,
          ).isNotEmpty;
      final payResult = await Navigator.of(context).push<StripeCheckoutResult>(
        AppPageRoute(
          builder: (_) => StripeCheckoutScreen(
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
            allowSaveCard: signedIn && !publicGuestPayment,
          ),
        ),
      );
      if (!context.mounted) return placed;

      if (!StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(payResult)) {
        if (payResult != null) {
          placed = placed.copyWithPayment(
            paymentStatus: payResult.paymentStatus,
            paymentMethod: payResult.paymentMethod,
            paymentTransactionId: payResult.paymentTransactionId,
            paymentSimulated: payResult.simulated,
          );
        }
        final msg = switch (payResult?.outcome) {
          StripeCheckoutOutcome.cancelled =>
            payResult?.message ?? 'Payment cancelled',
          StripeCheckoutOutcome.failure =>
            payResult?.message ?? 'Payment was not completed',
          _ => 'Payment was not completed',
        };
        showAppToast(
              context,
              msg,
              kind: AppToastKind.info,
            );
        return placed;
      }

      placed = placed.copyWithPayment(
        paymentStatus: payResult!.paymentStatus,
        paymentMethod: payResult.paymentMethod,
        paymentTransactionId: payResult.paymentTransactionId,
        paymentSimulated: payResult.simulated,
      );
      onlinePaymentOk = true;
    }

    if (pushSuccessScreen && onlinePaymentOk && context.mounted) {
      await Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => OrderPlacedScreen(
            token: placed.tokenNumber,
            customerUsername: customerUsername,
            customerName: customerName,
            guestPhone: guestPhone,
            businessUsername: businessUsername,
            businessName: businessName,
            totalItems: totalItems,
            totalAmount: serverTotal >= 0 ? serverTotal : totalAmount,
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
