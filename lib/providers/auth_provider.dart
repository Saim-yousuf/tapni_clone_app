import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1200));

    _isAuthenticated = true;
    _userEmail = email;
    _userName = email.split('@')[0].toUpperCase();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1500));

    _isAuthenticated = true;
    _userEmail = email;
    _userName = name;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _isLoading = false;
    notifyListeners();
  }
}
