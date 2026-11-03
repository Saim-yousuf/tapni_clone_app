import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class CallerIdService {
  CallerIdService._();

  static const _channel = MethodChannel('barqody/caller_id');

  /// Temporary kill switch. Set true to bring Caller ID back.
  static const bool isFeatureEnabled = true;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isSupported => isFeatureEnabled && _isAndroid;

  static bool get isEnabled {
    if (!isFeatureEnabled) return false;
    final key = SharedPrefHelper.utils.callerIdEnabled;
    if (SharedPrefHelper.haveKey(key) != true) return true;
    return SharedPrefHelper.getBool(key, defValue: true);
  }

  static Future<void> ensureDefaultEnabled({String lang = 'en'}) async {
    if (!isFeatureEnabled) {
      await _disableNative();
      return;
    }
    final key = SharedPrefHelper.utils.callerIdEnabled;
    if (SharedPrefHelper.haveKey(key) != true) {
      await SharedPrefHelper.putBool(key, true);
    }
    await syncNative(lang: lang);
  }

  static bool get wasPermissionPrompted => SharedPrefHelper.getBool(
        SharedPrefHelper.utils.callerIdPermissionPrompted,
      );

  static Future<void> markPermissionPrompted() async {
    await SharedPrefHelper.putBool(
      SharedPrefHelper.utils.callerIdPermissionPrompted,
      true,
    );
  }

  static Future<bool> hasAllPermissions() async {
    if (!isSupported) return false;
    final phone = await hasPhonePermissions();
    final overlay = await hasOverlayPermission();
    final role = await hasCallScreeningRole();
    return phone && overlay && role;
  }

  /// Soft requirement (Truecaller-style): keep app alive for incoming calls.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return true;
    final value =
        await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return value ?? true;
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!isSupported) return;
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// True when Barqody is the system default phone app (owns full call UI).
  static Future<bool> isDefaultDialer() async {
    if (!isSupported) return false;
    final value = await _channel.invokeMethod<bool>('isDefaultDialer');
    return value ?? false;
  }

  /// Opens the system picker to set Barqody as default phone / dialer app.
  static Future<bool> requestDefaultDialerRole() async {
    if (!isSupported) return false;
    final raw = await _channel.invokeMethod<dynamic>('requestDefaultDialerRole');
    if (raw is Map) {
      return raw['opened'] == true || raw['held'] == true;
    }
    return true;
  }

  static Future<void> setEnabled(bool enabled, {String lang = 'en'}) async {
    await SharedPrefHelper.putBool(
      SharedPrefHelper.utils.callerIdEnabled,
      isFeatureEnabled && enabled,
    );
    await syncNative(lang: lang);
  }

  static Future<void> syncNative({String lang = 'en'}) async {
    if (!_isAndroid) return;
    if (!isFeatureEnabled) {
      await _disableNative();
      return;
    }
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    await _channel.invokeMethod('syncConfig', {
      'enabled': isEnabled && token.isNotEmpty,
      'token': token,
      'baseUrl': Api.baseUrl,
      'lang': lang,
    });
  }

  static Future<void> onLogout() async {
    await _disableNative();
  }

  static Future<void> _disableNative() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod('syncConfig', {
      'enabled': false,
      'token': '',
      'baseUrl': Api.baseUrl,
      'lang': 'en',
    });
  }

  static Future<bool> hasPhonePermissions() async {
    if (!isSupported) return false;
    final value = await _channel.invokeMethod<bool>('hasPhonePermissions');
    return value ?? false;
  }

  static Future<void> requestPhonePermissions() async {
    if (!isSupported) return;
    await _channel.invokeMethod('requestPhonePermissions');
  }

  static Future<bool> hasOverlayPermission() async {
    if (!isSupported) return false;
    final value = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return value ?? false;
  }

  static Future<void> requestOverlayPermission() async {
    if (!isSupported) return;
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<bool> hasCallScreeningRole() async {
    if (!isSupported) return false;
    final value = await _channel.invokeMethod<bool>('hasCallScreeningRole');
    return value ?? false;
  }

  /// Opens the system Caller ID / spam-app role picker.
  /// Returns true if a system UI was opened or the role is already held.
  static Future<bool> requestCallScreeningRole() async {
    if (!isSupported) return false;
    final raw = await _channel.invokeMethod<dynamic>('requestCallScreeningRole');
    if (raw is Map) {
      final opened = raw['opened'] == true;
      final held = raw['held'] == true;
      return opened || held;
    }
    return true;
  }
}
