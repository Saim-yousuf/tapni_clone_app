import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/services/push_notification_service.dart';
import 'package:tapni_app/utils/preference_helper.dart';

/// Polls + reacts to FCM so a remotely revoked device logs out immediately.
class DeviceSessionGuard with WidgetsBindingObserver {
  DeviceSessionGuard._();

  static final DeviceSessionGuard instance = DeviceSessionGuard._();
  static final AuthRepo _repo = AuthRepo();

  Timer? _timer;
  bool _checking = false;
  bool _loggingOut = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(checkNow());
    });
    unawaited(checkNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow());
    }
  }

  Future<void> checkNow() async {
    if (_checking || _loggingOut) return;
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    if (token.isEmpty) return;

    _checking = true;
    try {
      final pending = SharedPrefHelper.getBool(
        SharedPrefHelper.utils.pendingRemoteLogout,
      );
      if (pending) {
        final sessionId = SharedPrefHelper.getString(
          SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
        );
        await _forceLogout(deviceSessionId: sessionId);
        return;
      }

      final res = await _repo.listDeviceSessions();
      if (res.statusCode == 401) {
        await _forceLogout();
        return;
      }

      if (!res.success || res.data is! Map) return;
      final devices = (res.data as Map)['devices'];
      if (devices is! List) return;

      final active = AccountStorage.getActiveAccount();
      final activeSessionId = active?.deviceSessionId ??
          SharedPrefHelper.getString(
            SharedPrefHelper.utils.activeDeviceSessionId,
          );
      if (activeSessionId.isEmpty) return;

      final stillActive = devices.any((d) {
        if (d is! Map) return false;
        return d['id']?.toString() == activeSessionId;
      });

      if (!stillActive) {
        await _forceLogout(deviceSessionId: activeSessionId);
      }
    } catch (_) {
      // Network blips are ignored; next tick retries.
    } finally {
      _checking = false;
    }
  }

  Future<void> handlePushLogout({String? deviceSessionId}) async {
    await _forceLogout(deviceSessionId: deviceSessionId);
  }

  Future<void> handleApiUnauthorized() async {
    await _forceLogout();
  }

  Future<void> _forceLogout({String? deviceSessionId}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      final ctx = PushNotificationService.navigatorKey.currentContext;
      if (ctx == null) {
        await SharedPrefHelper.putBool(
          SharedPrefHelper.utils.pendingRemoteLogout,
          true,
        );
        if (deviceSessionId != null && deviceSessionId.isNotEmpty) {
          await SharedPrefHelper.putString(
            SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
            deviceSessionId,
          );
        }
        return;
      }

      final auth = Provider.of<AuthProvider>(ctx, listen: false);
      await auth.handleRemoteDeviceLogout(
        context: ctx,
        deviceSessionId: deviceSessionId,
      );
    } finally {
      _loggingOut = false;
    }
  }
}
