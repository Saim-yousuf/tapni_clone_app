import 'package:flutter/material.dart';
import 'package:tapni_app/models/subscription.dart';
import 'package:tapni_app/repository/subscription_repo.dart';
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

  /// Mock checkout + confirm (Stripe-shaped). Card data never leaves the device.
  Future<bool> pay({
    required String planId,
    required BuildContext context,
  }) async {
    setLoading(true);

    final checkoutResponse = await _subscriptionRepo.checkout(planId: planId);
    if (!checkoutResponse.success) {
      setLoading(false);
      if (context.mounted) {
        ShowAlert.error(
          message: checkoutResponse.message ?? 'Checkout failed',
          context: context,
        );
      }
      return false;
    }

    final raw = checkoutResponse.data;
    if (raw is! Map<String, dynamic>) {
      setLoading(false);
      if (context.mounted) {
        ShowAlert.error(message: 'Invalid checkout response', context: context);
      }
      return false;
    }

    final session = CheckoutSession.fromJson(raw);
    if (session.checkoutId.isEmpty) {
      setLoading(false);
      if (context.mounted) {
        ShowAlert.error(message: 'Missing checkout id', context: context);
      }
      return false;
    }

    final confirmResponse = await _subscriptionRepo.confirmCheckout(
      checkoutId: session.checkoutId,
    );
    setLoading(false);

    if (confirmResponse.success) {
      await checkSubscriptionStatus();
      return true;
    }

    if (context.mounted) {
      ShowAlert.error(
        message: confirmResponse.message ?? 'Payment failed',
        context: context,
      );
    }
    return false;
  }
}
