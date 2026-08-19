import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:tapni_app/models/stored_account.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class AccountStorage {
  static List<StoredAccount> getAccounts() {
    final raw = SharedPrefHelper.getString(
      SharedPrefHelper.utils.linkedAccounts,
    );
    if (raw.isEmpty) {
      // Migrate legacy single token if present
      final legacyToken = SharedPrefHelper.getString(
        SharedPrefHelper.utils.authorizedToken,
      );
      if (legacyToken.isNotEmpty) {
        return [
          StoredAccount(
            userId: 'legacy',
            name: 'Account',
            email: '',
            token: legacyToken,
          ),
        ];
      }
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => StoredAccount.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.token.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAccounts(List<StoredAccount> accounts) async {
    final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.linkedAccounts,
      encoded,
    );
  }

  static StoredAccount? getActiveAccount() {
    final accounts = getAccounts();
    if (accounts.isEmpty) return null;
    final activeId = SharedPrefHelper.getString(
      SharedPrefHelper.utils.activeAccountId,
    );
    if (activeId.isNotEmpty) {
      for (final a in accounts) {
        if (a.userId == activeId) return a;
      }
    }
    return accounts.first;
  }

  static Future<void> setActiveToken(String token, {String? deviceSessionId}) async {
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.authorizedToken,
      token,
    );
    if (deviceSessionId != null) {
      await SharedPrefHelper.putString(
        SharedPrefHelper.utils.activeDeviceSessionId,
        deviceSessionId,
      );
    }
  }

  /// Add or update account and make it active.
  static Future<StoredAccount> upsertAndActivate({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? username,
    String? profilePhoto,
    required String token,
    String? deviceSessionId,
  }) async {
    final accounts = getAccounts()
        .where((a) => a.userId != 'legacy' || a.userId == userId)
        .toList();

    // Drop legacy placeholder once we know real user id
    accounts.removeWhere((a) => a.userId == 'legacy');

    final index = accounts.indexWhere((a) => a.userId == userId);
    final account = StoredAccount(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      username: username,
      profilePhoto: profilePhoto,
      token: token,
      deviceSessionId: deviceSessionId,
    );

    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }

    await _saveAccounts(accounts);
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.activeAccountId,
      userId,
    );
    await setActiveToken(token, deviceSessionId: deviceSessionId);
    return account;
  }

  static Future<void> updateActiveProfileMeta({
    String? name,
    String? email,
    String? phone,
    String? username,
    String? profilePhoto,
    String? userId,
  }) async {
    final accounts = getAccounts();
    final activeId = SharedPrefHelper.getString(
      SharedPrefHelper.utils.activeAccountId,
    );
    var index = accounts.indexWhere((a) => a.userId == activeId);
    if (index < 0 && accounts.isNotEmpty) {
      index = 0;
    }
    if (index < 0) return;
    final current = accounts[index];
    final nextId = (userId != null && userId.isNotEmpty) ? userId : current.userId;
    accounts[index] = current.copyWith(
      userId: nextId,
      name: name ?? current.name,
      email: email ?? current.email,
      phone: phone ?? current.phone,
      username: username ?? current.username,
      profilePhoto: profilePhoto ?? current.profilePhoto,
    );
    await _saveAccounts(accounts);
    if (nextId != activeId) {
      await SharedPrefHelper.putString(
        SharedPrefHelper.utils.activeAccountId,
        nextId,
      );
    }
  }

  static Future<bool> switchTo(String userId) async {
    final accounts = getAccounts();
    StoredAccount? account;
    for (final a in accounts) {
      if (a.userId == userId) {
        account = a;
        break;
      }
    }
    if (account == null) return false;
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.activeAccountId,
      account.userId,
    );
    await setActiveToken(
      account.token,
      deviceSessionId: account.deviceSessionId,
    );
    return true;
  }

  /// Remove current account. Returns remaining account to activate, or null.
  static Future<StoredAccount?> removeActive() async {
    final accounts = getAccounts();
    final activeId = SharedPrefHelper.getString(
      SharedPrefHelper.utils.activeAccountId,
    );
    accounts.removeWhere(
      (a) =>
          a.userId == activeId ||
          (activeId.isEmpty &&
              a.token ==
                  SharedPrefHelper.getString(
                    SharedPrefHelper.utils.authorizedToken,
                  )),
    );
    await _saveAccounts(accounts);

    if (accounts.isEmpty) {
      await SharedPrefHelper.remove(SharedPrefHelper.utils.authorizedToken);
      await SharedPrefHelper.remove(SharedPrefHelper.utils.activeAccountId);
      await SharedPrefHelper.remove(
        SharedPrefHelper.utils.activeDeviceSessionId,
      );
      return null;
    }

    final next = accounts.first;
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.activeAccountId,
      next.userId,
    );
    await setActiveToken(next.token, deviceSessionId: next.deviceSessionId);
    return next;
  }

  static Future<void> clearAll() async {
    await SharedPrefHelper.remove(SharedPrefHelper.utils.linkedAccounts);
    await SharedPrefHelper.remove(SharedPrefHelper.utils.authorizedToken);
    await SharedPrefHelper.remove(SharedPrefHelper.utils.activeAccountId);
    await SharedPrefHelper.remove(SharedPrefHelper.utils.activeDeviceSessionId);
  }

  static String devicePlatformLabel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Mobile';
  }

  /// Stable id for this install/hardware — one account session per device.
  static Future<String> deviceKey() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final id = info.id.trim();
        if (id.isNotEmpty && id.toLowerCase() != 'unknown') {
          return 'android_$id';
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final id = (info.identifierForVendor ?? '').trim();
        if (id.isNotEmpty) return 'ios_$id';
      }
    } catch (_) {}
    return '${devicePlatformLabel().toLowerCase()}_fallback';
  }

  static StoredAccount? findAccountByEmailOrId({
    String? email,
    String? phone,
    String? userId,
  }) {
    final accounts = getAccounts();
    final emailLower = email?.trim().toLowerCase() ?? '';
    final phoneNorm = phone?.trim() ?? '';
    final id = userId?.trim() ?? '';
    for (final a in accounts) {
      if (id.isNotEmpty && a.userId == id) return a;
      if (emailLower.isNotEmpty &&
          a.email.trim().toLowerCase() == emailLower) {
        return a;
      }
      if (phoneNorm.isNotEmpty && PhoneUtils.sameNumber(a.phone, phoneNorm)) {
        return a;
      }
    }
    return null;
  }

  static bool isGenericDeviceName(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty) return true;
    const generic = {
      'android',
      'android device',
      'ios',
      'ios device',
      'mobile',
      'mobile device',
      'this device',
      'new device',
      'linked device',
      'linked android',
      'linked ios',
      'device',
      'unknown',
      'phone',
    };
    return generic.contains(v);
  }

  /// Human-readable phone name shown on Linked Devices (e.g. "Samsung SM-A325F").
  static Future<String> defaultDeviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        for (final candidate in [
          _joinBrandModel(info.brand, info.model),
          _joinBrandModel(info.manufacturer, info.model),
          info.model,
          info.name,
          info.device,
          info.product,
        ]) {
          final cleaned = _cleanDeviceLabel(candidate);
          if (cleaned != null) return cleaned;
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        for (final candidate in [
          info.modelName,
          info.name,
          info.localizedModel,
          info.model,
        ]) {
          final cleaned = _cleanDeviceLabel(candidate);
          if (cleaned != null) return cleaned;
        }
      }
    } catch (_) {}
    return '${devicePlatformLabel()} device';
  }

  static String? _joinBrandModel(String brand, String model) {
    final b = brand.trim();
    final m = model.trim();
    if (b.isEmpty && m.isEmpty) return null;
    if (b.isEmpty) return m;
    if (m.isEmpty) return _capitalizeWords(b);
    if (m.toLowerCase().startsWith(b.toLowerCase())) return m;
    return '${_capitalizeWords(b)} $m';
  }

  static String? _cleanDeviceLabel(String? raw) {
    final v = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v.isEmpty || isGenericDeviceName(v)) return null;
    return v;
  }

  static String _capitalizeWords(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
