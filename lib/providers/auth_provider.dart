import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _clearAllUserData(BuildContext context) {
    return Future.wait([
      _clearProfileData(context),
      _clearLeadsData(context),
      _clearSubscriptionData(context),
    ]);
  }

  Future<void> _clearProfileData(BuildContext context) async {
    if (context.mounted) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      profileProvider.clearData();
    }
  }

  Future<void> _clearLeadsData(BuildContext context) async {
    if (context.mounted) {
      final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
      leadsProvider.clearData();
    }
  }

  Future<void> _clearSubscriptionData(BuildContext context) async {
    if (context.mounted) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      subscriptionProvider.clearData();
    }
  }

  Future<bool> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    setLoading(true);
    final response = await _authRepo.login(email: email, password: password);
    setLoading(false);

    if (response.success && response.data != null) {
      final token = response.data['token'];
      if (token != null) {
        await SharedPrefHelper.putString(
          SharedPrefHelper.utils.authorizedToken,
          token.toString(),
        );
        await _clearAllUserData(context);
        return true;
      }
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Login failed',
        context: context,
      );
    }
    return false;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    BuildContext context,
  ) async {
    setLoading(true);
    final response = await _authRepo.register(
      name: name,
      email: email,
      password: password,
    );
    setLoading(false);

    if (response.success && response.data != null) {
      final token = response.data['token'];
      if (token != null) {
        await SharedPrefHelper.putString(
          SharedPrefHelper.utils.authorizedToken,
          token.toString(),
        );
        await _clearAllUserData(context);
        return true;
      }
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Registration failed',
        context: context,
      );
    }
    return false;
  }

  Future<bool> googleSignIn(String token, BuildContext context) async {
    setLoading(true);
    final response = await _authRepo.googleSignIn(token: token);
    setLoading(false);

    if (response.success && response.data != null) {
      final jwt = response.data['token'];
      if (jwt != null) {
        await SharedPrefHelper.putString(
          SharedPrefHelper.utils.authorizedToken,
          jwt.toString(),
        );
        await _clearAllUserData(context);
        return true;
      }
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Google Sign-In failed',
        context: context,
      );
    }
    return false;
  }

  Future<void> logout() async {
    await SharedPrefHelper.remove(SharedPrefHelper.utils.authorizedToken);
    notifyListeners();
  }
}
