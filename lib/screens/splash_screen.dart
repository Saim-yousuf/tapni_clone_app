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

/// Bootstrap only — native splash stays on screen until navigation is ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    try {
      await Future<void>.delayed(Duration.zero);
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
        // Background FCM may already have cleared the account.
        if (AccountStorage.getActiveAccount() != null) {
          await AccountStorage.removeActive();
        }
      }

      if (!mounted) return;

      if (isLoggedIn) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.refreshAccounts();
        await authProvider.ensureDeviceSessionRegistered();

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

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } finally {
      // Drop native splash only after the next screen is pushed (or on error).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Match native splash (black + RQ) if splash is already removed.
    return const Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SizedBox.expand(),
    );
  }
}
