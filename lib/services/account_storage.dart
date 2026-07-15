import 'dart:convert';
import 'dart:io';

import 'package:tapni_app/models/stored_account.dart';
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

  static String defaultDeviceName() {
    return '${devicePlatformLabel()} device';
  }
}
