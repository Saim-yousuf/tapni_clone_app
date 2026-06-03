import 'package:flutter/material.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/widgets/alert.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password, BuildContext context) async {
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

  Future<bool> register(String name, String email, String password, BuildContext context) async {
    setLoading(true);
    final response = await _authRepo.register(name: name, email: email, password: password);
    setLoading(false);

    if (response.success && response.data != null) {
      final token = response.data['token'];
      if (token != null) {
        await SharedPrefHelper.putString(
          SharedPrefHelper.utils.authorizedToken,
          token.toString(),
        );
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
