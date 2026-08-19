import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/onboarding_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/preference_helper.dart';
import 'package:tapni_app/services/push_notification_service.dart';

/// Bootstrap only — native splash stays until the next route is ready (local prefs).
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer past the first build — Navigator / notifyListeners are unsafe in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_navigateToNext());
    });
  }

  Future<void> _navigateToNext() async {
    try {
      if (!mounted) return;

      final token = SharedPrefHelper.getString(
        SharedPrefHelper.utils.authorizedToken,
      );
      final pendingRemoteLogout = SharedPrefHelper.getBool(
        SharedPrefHelper.utils.pendingRemoteLogout,
      );
      final isLoggedIn = token.isNotEmpty && !pendingRemoteLogout;

      if (pendingRemoteLogout) {
        await SharedPrefHelper.remove(
          SharedPrefHelper.utils.pendingRemoteLogout,
        );
        await SharedPrefHelper.remove(
          SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
        );
        if (AccountStorage.getActiveAccount() != null) {
          await AccountStorage.removeActive();
        }
      }

      if (!mounted) return;

      if (isLoggedIn) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final subProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        authProvider.refreshAccounts();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );

        // Network bootstrap after UI is shown (WhatsApp / IG style).
        unawaited(
          _bootstrapLoggedIn(
            authProvider: authProvider,
            subProvider: subProvider,
            profileProvider: profileProvider,
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  Future<void> _bootstrapLoggedIn({
    required AuthProvider authProvider,
    required SubscriptionProvider subProvider,
    required ProfileProvider profileProvider,
  }) async {
    try {
      await authProvider.ensureDeviceSessionRegistered();
      await Future.wait([
        subProvider.checkSubscriptionStatus(),
        profileProvider.fetchProfile(),
        profileProvider.fetchLinkCatalog(),
        PushNotificationService.syncTokenWithBackend(),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SizedBox.expand(),
    );
  }
}
