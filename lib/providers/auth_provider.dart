import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/l10n_lookup.dart';
import 'package:tapni_app/models/stored_account.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/services/push_notification_service.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/widgets/alert.dart';

class OtpSendResult {
  final bool success;
  final String? otp;
  final String? phone;
  final String? message;

  const OtpSendResult({
    required this.success,
    this.otp,
    this.phone,
    this.message,
  });
}

class OtpVerifyResult {
  final bool success;
  final bool isNewUser;
  final bool loggedIn;
  final String? verificationToken;
  final String? phone;
  final String? message;

  const OtpVerifyResult({
    required this.success,
    this.isNewUser = false,
    this.loggedIn = false,
    this.verificationToken,
    this.phone,
    this.message,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<StoredAccount> get accounts => AccountStorage.getAccounts();
  StoredAccount? get activeAccount => AccountStorage.getActiveAccount();
  bool get hasMultipleAccounts => accounts.length > 1;

  void refreshAccounts() {
    notifyListeners();
  }

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

  Future<void> _persistSessionFromResponse(
    Map data, {
    String? deviceSessionId,
  }) async {
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return;

    final user = data['user'];
    String userId = '';
    String name = '';
    String email = '';
    String? phone;
    String? username;
    String? profilePhoto;

    if (user is Map) {
      userId = (user['id'] ?? user['_id'] ?? '').toString();
      name = (user['name'] ?? '').toString();
      email = (user['email'] ?? '').toString();
      phone = user['phone']?.toString();
      username = user['username']?.toString();
      profilePhoto = user['profilePhoto']?.toString();
    }

    if (userId.isEmpty) {
      userId = phone?.isNotEmpty == true
          ? phone!
          : (email.isNotEmpty ? email : 'user_${token.hashCode}');
    }

    await AccountStorage.upsertAndActivate(
      userId: userId,
      name: name.isNotEmpty ? name : 'Account',
      email: email,
      phone: phone,
      username: username,
      profilePhoto: profilePhoto,
      token: token,
      deviceSessionId: deviceSessionId ?? data['deviceSessionId']?.toString(),
    );
    refreshAccounts();
    await CallerIdService.ensureDefaultEnabled();
  }

  Future<void> ensureDeviceSessionRegistered() async {
    try {
      final res = await _authRepo.registerDeviceSession(
        deviceName: await AccountStorage.defaultDeviceName(),
        platform: AccountStorage.devicePlatformLabel(),
        deviceKey: await AccountStorage.deviceKey(),
      );
      if (!res.success || res.data is! Map) return;
      final data = res.data as Map;
      final newToken = data['token']?.toString();
      final sessionId = data['deviceSessionId']?.toString();
      final active = AccountStorage.getActiveAccount();
      if (active == null) return;

      if (newToken != null && newToken.isNotEmpty) {
        await AccountStorage.upsertAndActivate(
          userId: active.userId,
          name: active.name,
          email: active.email,
          phone: active.phone,
          username: active.username,
          profilePhoto: active.profilePhoto,
          token: newToken,
          deviceSessionId: sessionId,
        );
      } else if (sessionId != null) {
        await AccountStorage.upsertAndActivate(
          userId: active.userId,
          name: active.name,
          email: active.email,
          phone: active.phone,
          username: active.username,
          profilePhoto: active.profilePhoto,
          token: active.token,
          deviceSessionId: sessionId,
        );
      }
      refreshAccounts();
      await CallerIdService.ensureDefaultEnabled();
    } catch (_) {}
  }

  bool isAlreadyOnThisDevice({String? email, String? phone, String? userId}) {
    return AccountStorage.findAccountByEmailOrId(
          email: email,
          phone: phone,
          userId: userId,
        ) !=
        null;
  }

  Future<OtpSendResult> sendOtp(
    String phone,
    BuildContext context, {
    bool showErrors = true,
  }) async {
    if (isAlreadyOnThisDevice(phone: phone)) {
      if (showErrors && context.mounted) {
        ShowAlert.error(
          message: l10nOr(
            (l) => l.accountAlreadyLoggedInOnDevice,
            'This account is already logged in on this device',
          ),
          context: context,
        );
      }
      return OtpSendResult(
        success: false,
        message: l10nOr(
          (l) => l.accountAlreadyLoggedInOnDevice,
          'This account is already logged in on this device',
        ),
      );
    }

    final response = await _authRepo.sendPhoneOtp(phone: phone);

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is Map) {
        return OtpSendResult(
          success: true,
          otp: data['otp']?.toString(),
          phone: data['phone']?.toString() ?? phone,
          message: response.message,
        );
      }
    }

    if (showErrors && context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Failed to send OTP',
        context: context,
      );
    }
    return OtpSendResult(
      success: false,
      message: response.message ?? 'Failed to send OTP',
    );
  }

  Future<OtpVerifyResult> verifyOtp(
    String phone,
    String otp,
    BuildContext context, {
    bool addAccount = false,
  }) async {
    if (isAlreadyOnThisDevice(phone: phone)) {
      if (context.mounted) {
        ShowAlert.error(
          message: l10nOr((l) => l.accountAlreadyLoggedInOnDevice, 'This account is already logged in on this device'),
          context: context,
        );
      }
      return const OtpVerifyResult(success: false);
    }

    final response = await _authRepo.verifyPhoneOtp(phone: phone, otp: otp);

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is! Map) {
        return OtpVerifyResult(
          success: false,
          message: response.message,
        );
      }

      final isNewUser = data['isNewUser'] == true;
      if (isNewUser) {
        return OtpVerifyResult(
          success: true,
          isNewUser: true,
          verificationToken: data['verificationToken']?.toString(),
          phone: data['phone']?.toString() ?? phone,
          message: response.message,
        );
      }

      if (data['token'] != null) {
        final user = data['user'];
        final userId = user is Map
            ? (user['id'] ?? user['_id'])?.toString()
            : null;
        final userPhone =
            user is Map ? user['phone']?.toString() : phone;
        final userEmail =
            user is Map ? user['email']?.toString() : null;

        if (isAlreadyOnThisDevice(
          email: userEmail,
          phone: userPhone,
          userId: userId,
        )) {
          if (context.mounted) {
            ShowAlert.error(
              message: l10nOr((l) => l.accountAlreadyLoggedInOnDevice, 'This account is already logged in on this device'),
              context: context,
            );
          }
          return const OtpVerifyResult(success: false);
        }

        await _persistSessionFromResponse(Map<String, dynamic>.from(data));
        await _clearAllUserData(context);
        await ensureDeviceSessionRegistered();
        await PushNotificationService.syncTokenWithBackend();
        return const OtpVerifyResult(success: true, loggedIn: true);
      }
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'OTP verification failed',
        context: context,
      );
    }
    return OtpVerifyResult(
      success: false,
      message: response.message ?? 'OTP verification failed',
    );
  }

  Future<bool> completePhoneSignup(
    String phone,
    String verificationToken,
    String name,
    BuildContext context, {
    String? country,
    String? profilePhoto,
  }) async {
    final response = await _authRepo.completePhoneSignup(
      phone: phone,
      verificationToken: verificationToken,
      name: name,
      country: country,
      profilePhoto: profilePhoto,
    );

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is Map && data['token'] != null) {
        await _persistSessionFromResponse(Map<String, dynamic>.from(data));
        await _clearAllUserData(context);
        await ensureDeviceSessionRegistered();
        await PushNotificationService.syncTokenWithBackend();
        return true;
      }
    }

    if (context.mounted) {
      ShowAlert.error(
        message: response.message ?? 'Signup failed',
        context: context,
      );
    }
    return false;
  }

  Future<bool> login(
    String email,
    String password,
    BuildContext context, {
    bool addAccount = false,
  }) async {
    if (isAlreadyOnThisDevice(email: email)) {
      if (context.mounted) {
        ShowAlert.error(
          message: l10nOr((l) => l.accountAlreadyLoggedInOnDevice, 'This account is already logged in on this device'),
          context: context,
        );
      }
      return false;
    }

    final response = await _authRepo.login(email: email, password: password);

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is Map && data['token'] != null) {
        final user = data['user'];
        final userId = user is Map
            ? (user['id'] ?? user['_id'])?.toString()
            : null;
        final userEmail =
            user is Map ? user['email']?.toString() : email;

        if (isAlreadyOnThisDevice(email: userEmail, userId: userId)) {
          if (context.mounted) {
            ShowAlert.error(
              message: l10nOr((l) => l.accountAlreadyLoggedInOnDevice, 'This account is already logged in on this device'),
              context: context,
            );
          }
          return false;
        }

        await _persistSessionFromResponse(Map<String, dynamic>.from(data));
        await _clearAllUserData(context);
        await ensureDeviceSessionRegistered();
        await PushNotificationService.syncTokenWithBackend();
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
    final response = await _authRepo.register(
      name: name,
      email: email,
      password: password,
    );

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is Map && data['token'] != null) {
        await _persistSessionFromResponse(Map<String, dynamic>.from(data));
        await _clearAllUserData(context);
        await ensureDeviceSessionRegistered();
        await PushNotificationService.syncTokenWithBackend();
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
      final data = response.data;
      if (data is Map && data['token'] != null) {
        await _persistSessionFromResponse(Map<String, dynamic>.from(data));
        await _clearAllUserData(context);
        await ensureDeviceSessionRegistered();
        await PushNotificationService.syncTokenWithBackend();
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

  Future<bool> loginWithLinkedDevice({
    required String token,
    required Map user,
    String? deviceSessionId,
    required BuildContext context,
  }) async {
    final userId = (user['id'] ?? user['_id'])?.toString();
    final email = user['email']?.toString();
    final phone = user['phone']?.toString();
    if (isAlreadyOnThisDevice(email: email, phone: phone, userId: userId)) {
      if (context.mounted) {
        ShowAlert.error(
          message: l10nOr((l) => l.accountAlreadyLoggedInOnDevice, 'This account is already logged in on this device'),
          context: context,
        );
      }
      return false;
    }

    await _persistSessionFromResponse({
      'token': token,
      'user': user,
      'deviceSessionId': deviceSessionId,
    }, deviceSessionId: deviceSessionId);
    await _clearAllUserData(context);
    await PushNotificationService.syncTokenWithBackend();
    return true;
  }

  Future<bool> switchAccount(String userId, BuildContext context) async {
    final active = AccountStorage.getActiveAccount();
    if (active?.userId == userId) return true;

    final ok = await AccountStorage.switchTo(userId);
    if (!ok) return false;

    await PushNotificationService.removeTokenFromBackend();
    await _clearAllUserData(context);
    refreshAccounts();

    if (context.mounted) {
      final subProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subProvider.checkSubscriptionStatus();
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.fetchProfile();
      await PushNotificationService.syncTokenWithBackend();
    }
    return true;
  }

  /// Revoke this device's server session so it disappears from Linked Devices.
  Future<void> _revokeDeviceSessionForAccount(StoredAccount account) async {
    final previousToken = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    try {
      await SharedPrefHelper.putString(
        SharedPrefHelper.utils.authorizedToken,
        account.token,
      );

      final sessionId = account.deviceSessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        await _authRepo.revokeDeviceSession(sessionId);
      } else {
        await _authRepo.revokeCurrentDeviceSession();
      }
    } catch (_) {
      // Best-effort: still clear local session even if revoke fails.
    } finally {
      await SharedPrefHelper.putString(
        SharedPrefHelper.utils.authorizedToken,
        previousToken,
      );
    }
  }

  /// Called when this device session was revoked from another phone.
  Future<void> handleRemoteDeviceLogout({
    required BuildContext context,
    String? deviceSessionId,
  }) async {
    final active = AccountStorage.getActiveAccount();
    if (active == null) {
      await SharedPrefHelper.remove(
        SharedPrefHelper.utils.pendingRemoteLogout,
      );
      await SharedPrefHelper.remove(
        SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
      );
      return;
    }

    final activeSession = active.deviceSessionId ??
        SharedPrefHelper.getString(
          SharedPrefHelper.utils.activeDeviceSessionId,
        );
    if (deviceSessionId != null &&
        deviceSessionId.isNotEmpty &&
        activeSession.isNotEmpty &&
        activeSession != deviceSessionId) {
      return;
    }

    try {
      await PushNotificationService.removeTokenFromBackend();
    } catch (_) {}

    await _clearAllUserData(context);
    final next = await AccountStorage.removeActive();
    refreshAccounts();

    await SharedPrefHelper.remove(SharedPrefHelper.utils.pendingRemoteLogout);
    await SharedPrefHelper.remove(
      SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
    );

    if (!context.mounted) return;

    final nav = PushNotificationService.navigatorKey.currentState;
    if (nav == null) return;

    if (next != null) {
      final subProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subProvider.checkSubscriptionStatus();
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.fetchProfile();
      await PushNotificationService.syncTokenWithBackend();
      if (!context.mounted) return;
      ShowAlert.error(
        message: l10nOr((l) => l.deviceLoggedOutFromLinkedDevices, 'This device was logged out from Linked devices'),
        context: context,
      );
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ShowAlert.error(
        message: l10nOr((l) => l.deviceLoggedOutFromLinkedDevices, 'This device was logged out from Linked devices'),
        context: context,
      );
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
        (_) => false,
      );
    }
  }

  /// Returns true if another account was activated (stay in app).
  Future<bool> logout({bool logoutAll = false}) async {
    final accounts = logoutAll
        ? List<StoredAccount>.from(AccountStorage.getAccounts())
        : [
            if (AccountStorage.getActiveAccount() != null)
              AccountStorage.getActiveAccount()!,
          ];

    // Remove push token while this device session is still valid.
    await PushNotificationService.removeTokenFromBackend();

    for (final account in accounts) {
      await _revokeDeviceSessionForAccount(account);
    }

    if (logoutAll) {
      await AccountStorage.clearAll();
      refreshAccounts();
      await CallerIdService.onLogout();
      return false;
    }

    final next = await AccountStorage.removeActive();
    refreshAccounts();
    if (next != null) {
      await CallerIdService.ensureDefaultEnabled();
    } else {
      await CallerIdService.onLogout();
    }
    return next != null;
  }
}
