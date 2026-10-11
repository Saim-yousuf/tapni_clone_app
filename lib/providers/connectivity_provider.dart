import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tapni_app/utils/api_endpoint.dart';

/// Tracks reachability for this app — Wi‑Fi/mobile plus our API host.
///
/// Google captive-portal probes alone are unreliable (blocked regions, LAN
/// backends with no public internet). Prefer [Api.baseUrl], then public probes.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    instance = this;
    unawaited(_init());
  }

  /// Latest instance — used by [ApiHandler] when a request succeeds.
  static ConnectivityProvider? instance;

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

  /// App reached the backend — clear false "offline" from probe flakiness.
  void reportApiReachable() {
    _setOnline(true);
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
    // Interface is up — stay optimistic while we verify. Avoid flashing
    // "No internet" when Google probes fail but our API still works.
    if (!_initialized) {
      _setOnline(true);
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
    // 1) Our backend — what the app actually needs (LAN / regional hosts).
    if (_apiHostReachable()) {
      final ok = await _probeUri(_apiProbeUri());
      if (ok) return true;
    }

    // 2) Public captive-portal probes (optional confirmation).
    for (final url in _probeUrls) {
      if (await _probeUri(Uri.parse(url), acceptGenerate204: true)) {
        return true;
      }
    }

    return false;
  }

  bool _apiHostReachable() {
    try {
      final base = Api.baseUrl;
      return base.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Uri? _apiProbeUri() {
    try {
      return Uri.parse(Api.baseUrl);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _probeUri(
    Uri? uri, {
    bool acceptGenerate204 = false,
  }) async {
    if (uri == null) return false;
    try {
      final response = await http.get(uri).timeout(_probeTimeout);
      if (acceptGenerate204 && response.statusCode == 204) return true;
      // Any HTTP response means the host is reachable (even 404/500).
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
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
    if (identical(instance, this)) instance = null;
    _checkGeneration++;
    _recheckTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
