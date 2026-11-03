import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tapni_app/models/subscription.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/repository/subscription_repo.dart';
import 'package:tapni_app/services/stripe_payment_service.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/release_features.dart';
import 'package:tapni_app/widgets/alert.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepo _subscriptionRepo = SubscriptionRepo();

  bool _isLoading = false;
  bool _isChecking = true;
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;

  bool get isLoading => _isLoading;
  bool get isChecking => _isChecking;
  List<SubscriptionPlan> get plans => _plans;
  UserSubscription? get currentSubscription => _currentSubscription;

  bool get isSubscribed => _currentSubscription?.isActive ?? false;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setChecking(bool value) {
    _isChecking = value;
    notifyListeners();
  }

  void clearData() {
    _plans.clear();
    _currentSubscription = null;
    notifyListeners();
  }

  Future<void> fetchPlans() async {
    if (!ReleaseFeatures.canUseBusinessPro) {
      _plans = [];
      notifyListeners();
      return;
    }
    final response = await _subscriptionRepo.getPlans();
    if (response.success && response.data != null) {
      final data = response.data;
      final plansJson = data is Map<String, dynamic> && data['plans'] != null
          ? data['plans']
          : data;

      if (plansJson is List) {
        _plans = plansJson
            .whereType<Map<String, dynamic>>()
            .map((e) => SubscriptionPlan.fromJson(e))
            .toList();
        notifyListeners();
      }
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    if (!ReleaseFeatures.canUseBusinessPro) {
      _currentSubscription = null;
      setChecking(false);
      notifyListeners();
      return false;
    }
    setChecking(true);
    final response = await _subscriptionRepo.getMySubscription();
    setChecking(false);

    if (response.success && response.data != null) {
      final data = response.data;
      final subscriptionJson = data is Map<String, dynamic>
          ? data['subscription'] ?? data
          : data;

      if (subscriptionJson is Map<String, dynamic>) {
        _currentSubscription = UserSubscription.fromJson(subscriptionJson);
        notifyListeners();
        return _currentSubscription!.isActive;
      }
    }

    _currentSubscription = null;
    notifyListeners();
    return false;
  }

  /// Real Stripe PaymentSheet checkout for a plan (registration + upgrade).
  Future<bool> pay({
    required String planId,
    required BuildContext context,
  }) async {
    if (!ReleaseFeatures.canUseBusinessPro) {
      return false;
    }
    setLoading(true);

    try {
      if (kIsWeb) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(
            message:
                'Plan payment on web is not available in the app shell. Use the mobile app.',
            context: context,
          );
        }
        return false;
      }

      final ready = await StripePaymentService.instance.ensureInitialized();
      if (!ready) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(
            message: StripePaymentService.instance.nativeError ??
                'Stripe is not ready. Online plan payments are unavailable.',
            context: context,
          );
        }
        return false;
      }

      final checkoutResponse =
          await _subscriptionRepo.checkout(planId: planId);
      if (!checkoutResponse.success) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(
            message: PaymentDisplay.sanitizeError(
              checkoutResponse.message,
              fallback: 'Checkout failed',
            ),
            context: context,
          );
        }
        return false;
      }

      final raw = checkoutResponse.data;
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : null);
      if (map == null) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(
            message: 'Invalid checkout response',
            context: context,
          );
        }
        return false;
      }

      final session = CheckoutSession.fromJson(map);
      if (session.checkoutId.isEmpty) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(message: 'Missing checkout id', context: context);
        }
        return false;
      }

      if (session.alreadyPaid) {
        await checkSubscriptionStatus();
        setLoading(false);
        return true;
      }

      if ((session.clientSecret ?? '').isEmpty ||
          session.paymentIntentId.isEmpty) {
        setLoading(false);
        if (context.mounted) {
          ShowAlert.error(
            message: 'Missing Stripe payment session',
            context: context,
          );
        }
        return false;
      }

      final intentSession = PaymentIntentSession(
        paymentId: session.paymentId,
        orderId: '',
        clientSecret: session.clientSecret!,
        paymentIntentId: session.paymentIntentId,
        publishableKey: session.publishableKey,
        customerId: session.customerId,
        ephemeralKey: session.ephemeralKey,
        amount: session.amount,
        currency: session.currency,
      );

      await StripePaymentService.instance.presentPaymentSheet(
        session: intentSession,
        merchantDisplayName: 'BarQody',
      );

      final confirmResponse = await _subscriptionRepo.confirmCheckout(
        checkoutId: session.checkoutId,
        paymentIntentId: session.paymentIntentId,
      );
      setLoading(false);

      if (confirmResponse.success) {
        await checkSubscriptionStatus();
        return true;
      }

      if (context.mounted) {
        ShowAlert.error(
          message: PaymentDisplay.sanitizeError(
            confirmResponse.message,
            fallback: 'Payment failed',
          ),
          context: context,
        );
      }
      return false;
    } on StripeException catch (e) {
      setLoading(false);
      if (e.error.code == FailureCode.Canceled) {
        return false;
      }
      if (context.mounted) {
        ShowAlert.error(
          message: PaymentDisplay.sanitizeError(
            e.error.localizedMessage ?? e.error.message,
            fallback: 'Payment failed',
          ),
          context: context,
        );
      }
      return false;
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        ShowAlert.error(
          message: PaymentDisplay.sanitizeError(
            e.toString(),
            fallback: 'Payment failed',
          ),
          context: context,
        );
      }
      return false;
    }
  }
}
