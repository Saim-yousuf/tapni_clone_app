import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Tracks real internet reachability — not just Wi‑Fi / mobile data toggles.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    unawaited(_init());
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _recheckTimer;

  bool _isOnline = true;
  bool _initialized = false;
  bool _checking = false;
  bool _bannerDismissed = false;
  int _checkGeneration = 0;
  int _reconnectTick = 0;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get initialized => _initialized;
  /// Increments each time the device goes from offline → online.
  int get reconnectTick => _reconnectTick;
  /// Top offline banner — hidden after swipe dismiss until next screen / tab.
  bool get shouldShowBanner =>
      _initialized && !_isOnline && !_bannerDismissed;

  /// User swiped the banner away on the current screen.
  void dismissBanner() {
    if (_bannerDismissed) return;
    _bannerDismissed = true;
    notifyListeners();
  }

  /// Call when navigating to another screen or tab while still offline.
  void resetBannerForRoute() {
    if (!_bannerDismissed || _isOnline) return;
    _bannerDismissed = false;
    notifyListeners();
  }

  static const _onlineTypes = <ConnectivityResult>{
    ConnectivityResult.wifi,
    ConnectivityResult.mobile,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
  };

  /// Lightweight endpoints used by Android / Chrome for captive-portal checks.
  static const _probeUrls = <String>[
    'https://clients3.google.com/generate_204',
    'https://www.gstatic.com/generate_204',
  ];

  static const _probeTimeout = Duration(seconds: 4);
  static const _recheckInterval = Duration(seconds: 30);

  Future<void> _init() async {
    _recheckTimer = Timer.periodic(_recheckInterval, (_) {
      unawaited(_refresh());
    });

    try {
      final results = await _connectivity.checkConnectivity();
      await _applyResults(results);
    } catch (_) {
      await _verifyInternet();
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _applyResults,
      onError: (_) {},
    );
  }

  Future<void> _refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _applyResults(results);
    } catch (_) {
      await _verifyInternet();
    }
  }

  Future<void> _applyResults(List<ConnectivityResult> results) async {
    final hasInterface = results.any(_onlineTypes.contains);
    if (!hasInterface) {
      _setOnline(false);
      return;
    }
    await _verifyInternet();
  }

  Future<void> _verifyInternet() async {
    if (_checking) return;
    _checking = true;
    final generation = ++_checkGeneration;

    try {
      final reachable = await _hasRealInternet();
      if (generation != _checkGeneration) return;
      _setOnline(reachable);
    } finally {
      if (generation == _checkGeneration) {
        _checking = false;
      }
    }
  }

  Future<bool> _hasRealInternet() async {
    for (final url in _probeUrls) {
      try {
        final response = await http
            .head(Uri.parse(url))
            .timeout(_probeTimeout);
        if (response.statusCode == 204 ||
            (response.statusCode >= 200 && response.statusCode < 400)) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  void _setOnline(bool online) {
    final wasOnline = _isOnline;
    final hadInitialized = _initialized;
    final changed = _isOnline != online || !_initialized;
    if (!changed) return;
    _isOnline = online;
    _initialized = true;
    if (online) {
      _bannerDismissed = false;
      if (hadInitialized && !wasOnline) {
        _reconnectTick++;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _checkGeneration++;
    _recheckTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
