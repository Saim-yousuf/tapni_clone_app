import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/utils/stripe_checkout_outcome.dart';

void main() {
  group('StripeCheckoutGuards.canSubmitPayment', () {
    test('blocks when Stripe not ready', () {
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: false,
          busy: false,
          useNewCard: true,
          selectedSavedCardId: null,
        ),
        isFalse,
      );
    });

    test('blocks when busy', () {
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: true,
          busy: true,
          useNewCard: true,
          selectedSavedCardId: null,
        ),
        isFalse,
      );
    });

    test('empty payment method — saved path without card id blocked', () {
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: true,
          busy: false,
          useNewCard: false,
          selectedSavedCardId: null,
        ),
        isFalse,
      );
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: true,
          busy: false,
          useNewCard: false,
          selectedSavedCardId: '   ',
        ),
        isFalse,
      );
    });

    test('allows new-card path when ready', () {
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: true,
          busy: false,
          useNewCard: true,
          selectedSavedCardId: null,
        ),
        isTrue,
      );
    });

    test('allows selected saved card', () {
      expect(
        StripeCheckoutGuards.canSubmitPayment(
          stripeReady: true,
          busy: false,
          useNewCard: false,
          selectedSavedCardId: 'pm_123',
        ),
        isTrue,
      );
    });
  });

  group('PaymentSheet / backend outcome mapping', () {
    test('cancellation must not show order success', () {
      const cancelled = StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.cancelled,
        paymentStatus: 'cancelled',
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(cancelled),
        isFalse,
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(null),
        isFalse,
      );
    });

    test('PaymentSheet failure must not show order success', () {
      const failed = StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.failure,
        paymentStatus: 'failed',
        message: 'Card declined',
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(failed),
        isFalse,
      );
    });

    test('pending after sheet must not show order success', () {
      const pending = StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.success,
        paymentStatus: 'pending',
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(pending),
        isFalse,
      );
      expect(StripeCheckoutGuards.isVerifiedPaidSuccess(pending), isFalse);
    });

    test('simulated paid must not show order success', () {
      const simulated = StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.success,
        paymentStatus: 'paid',
        simulated: true,
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(simulated),
        isFalse,
      );
    });

    test('successful PaymentSheet + backend verified paid → success UI', () {
      const paid = StripeCheckoutResult(
        outcome: StripeCheckoutOutcome.success,
        paymentStatus: 'paid',
        paymentTransactionId: 'pi_abc',
        simulated: false,
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(paid),
        isTrue,
      );
    });

    test('resultFromBackendConfirm — paid', () {
      final r = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'paid',
          'isGenuinelyPaid': true,
          'stripeStatus': 'succeeded',
          'paymentTransactionId': 'pi_1',
        },
        fallbackPaymentIntentId: 'pi_fallback',
      );
      expect(r.outcome, StripeCheckoutOutcome.success);
      expect(r.paymentStatus, 'paid');
      expect(r.simulated, isFalse);
    });

    test('resultFromBackendConfirm — pending is failure outcome', () {
      final r = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'pending',
          'isGenuinelyPaid': false,
          'stripeStatus': 'requires_payment_method',
        },
        fallbackPaymentIntentId: 'pi_2',
      );
      expect(r.outcome, StripeCheckoutOutcome.failure);
      expect(r.paymentStatus, 'pending');
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(r),
        isFalse,
      );
    });

    test('resultFromBackendConfirm — canceled', () {
      final r = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'cancelled',
          'isGenuinelyPaid': false,
          'stripeStatus': 'canceled',
        },
        fallbackPaymentIntentId: 'pi_3',
      );
      expect(r.outcome, StripeCheckoutOutcome.cancelled);
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(r),
        isFalse,
      );
    });

    test('resultFromBackendConfirm — failed', () {
      final r = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'failed',
          'isGenuinelyPaid': false,
          'stripeStatus': 'failed',
        },
        fallbackPaymentIntentId: 'pi_4',
      );
      expect(r.outcome, StripeCheckoutOutcome.failure);
    });

    test('duplicate success callbacks still require paid status', () {
      final first = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'paid',
          'isGenuinelyPaid': true,
          'stripeStatus': 'succeeded',
        },
        fallbackPaymentIntentId: 'pi_dup',
      );
      final second = StripeCheckoutGuards.resultFromBackendConfirm(
        data: {
          'paymentStatus': 'paid',
          'isGenuinelyPaid': true,
          'stripeStatus': 'succeeded',
        },
        fallbackPaymentIntentId: 'pi_dup',
      );
      expect(first.outcome, StripeCheckoutOutcome.success);
      expect(second.outcome, StripeCheckoutOutcome.success);
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(first),
        isTrue,
      );
      expect(
        StripeCheckoutGuards.shouldShowOrderSuccessAfterOnline(second),
        isTrue,
      );
    });
  });
}
