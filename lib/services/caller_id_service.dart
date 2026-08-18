import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class CallerIdService {
  CallerIdService._();

  static const _channel = MethodChannel('barqody/caller_id');

  static bool get isSupported => Platform.isAndroid;

  static bool get isEnabled {
    final key = SharedPrefHelper.utils.callerIdEnabled;
    if (SharedPrefHelper.haveKey(key) != true) return true;
    return SharedPrefHelper.getBool(key, defValue: true);
  }

  static Future<void> ensureDefaultEnabled({String lang = 'en'}) async {
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

  static Future<void> setEnabled(bool enabled, {String lang = 'en'}) async {
    await SharedPrefHelper.putBool(
      SharedPrefHelper.utils.callerIdEnabled,
      enabled,
    );
    await syncNative(lang: lang);
  }

  static Future<void> syncNative({String lang = 'en'}) async {
    if (!isSupported) return;
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
    if (!isSupported) return;
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

  static Future<void> requestCallScreeningRole() async {
    if (!isSupported) return;
    await _channel.invokeMethod('requestCallScreeningRole');
  }
}
