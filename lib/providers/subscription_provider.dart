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

  Future<bool> subscribe(
    String planId,
    BuildContext context, {
    String transactionRef = '',
    String paymentReceipt = '',
  }) async {
    setLoading(true);
    final response = await _subscriptionRepo.subscribe(
      planId: planId,
      transactionRef: transactionRef,
      paymentReceipt: paymentReceipt,
    );
    setLoading(false);

    if (response.success) {
      await checkSubscriptionStatus(); // Refresh status
      return true;
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Subscription failed',
        context: context,
      );
    }
    return false;
  }
}
