enum StripeCheckoutOutcome { success, failure, cancelled }

class StripeCheckoutResult {
  final StripeCheckoutOutcome outcome;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentTransactionId;
  final bool simulated;
  final String? message;

  const StripeCheckoutResult({
    required this.outcome,
    required this.paymentStatus,
    this.paymentMethod = 'online',
    this.paymentTransactionId,
    this.simulated = false,
    this.message,
  });
}

/// Pure helpers for Stripe checkout navigation / Pay-button gating.
/// Kept free of Stripe SDK calls so unit tests can cover cancel/fail/success.
class StripeCheckoutGuards {
  StripeCheckoutGuards._();

  /// Pay requires either a saved card id, or an explicit "new card" choice.
  static bool canSubmitPayment({
    required bool stripeReady,
    required bool busy,
    required bool useNewCard,
    required String? selectedSavedCardId,
  }) {
    if (!stripeReady || busy) return false;
    if (useNewCard) return true;
    final id = (selectedSavedCardId ?? '').trim();
    return id.isNotEmpty;
  }

  /// Only genuine backend-verified paid status is a checkout success.
  /// Pending / cancelled / failed / simulated must not open Order Success.
  static bool isVerifiedPaidSuccess(StripeCheckoutResult? result) {
    if (result == null) return false;
    if (result.outcome != StripeCheckoutOutcome.success) return false;
    if (result.simulated) return false;
    final status = result.paymentStatus.trim().toLowerCase();
    return status == 'paid';
  }

  /// Online checkout may show OrderPlaced only after verified paid success.
  static bool shouldShowOrderSuccessAfterOnline(
    StripeCheckoutResult? payResult,
  ) {
    return isVerifiedPaidSuccess(payResult);
  }

  /// Map backend confirm payload → checkout outcome.
  /// Never treat pending/cancelled/failed as success.
  /// [fallbackPaymentIntentId] is SDK-only and must never be shown in UI.
  static StripeCheckoutResult resultFromBackendConfirm({
    required Map<String, dynamic> data,
    required String fallbackPaymentIntentId,
    String? message,
  }) {
    final status = (data['paymentStatus']?.toString() ?? 'pending')
        .trim()
        .toLowerCase();
    final genuinelyPaid =
        data['isGenuinelyPaid'] == true || status == 'paid';
    final stripeStatus = (data['gatewayStatus']?.toString() ??
            data['stripeStatus']?.toString() ??
            '')
        .trim()
        .toLowerCase();
    // Prefer friendly public ref; never use Stripe PaymentIntent as display ref.
    final tx = (data['publicRef']?.toString() ??
            data['publicPaymentRef']?.toString() ??
            '')
        .trim();

    if (genuinelyPaid && status == 'paid') {
      return StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.success,
        paymentStatus: 'paid',
        paymentTransactionId: tx.isEmpty ? null : tx,
        simulated: false,
        message: message ?? 'Payment confirmed',
      );
    }

    if (status == 'cancelled' ||
        status == 'canceled' ||
        stripeStatus == 'canceled') {
      return StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.cancelled,
        paymentStatus: 'cancelled',
        paymentTransactionId: tx.isEmpty ? null : tx,
        simulated: false,
        message: message ?? 'Payment cancelled',
      );
    }

    if (status == 'failed' || stripeStatus == 'failed') {
      return StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.failure,
        paymentStatus: 'failed',
        paymentTransactionId: tx.isEmpty ? null : tx,
        simulated: false,
        message: message ?? 'Payment failed',
      );
    }

    // Pending / processing / requires_action — not success.
    return StripeCheckoutResult(
      outcome: StripeCheckoutOutcome.failure,
      paymentStatus: status.isEmpty ? 'pending' : status,
      paymentTransactionId: tx.isEmpty ? null : tx,
      simulated: false,
      message: message ?? 'Payment is not complete yet. Please try again.',
    );
  }
}
