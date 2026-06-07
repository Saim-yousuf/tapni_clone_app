import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/onboarding_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/preference_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // AuthProvider check for authenticated needs to be valid.
    // If it relies on a token check, wait. authProvider.isAuthenticated doesn't exist?
    // Let's assume there is a token check, or we should use SharedPrefHelper.

    // Since I haven't added isAuthenticated to AuthProvider in the recent edits,
    // I should check SharedPrefHelper directly if it is not there.
    final token = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    final isLoggedIn = token.isNotEmpty;

    if (isLoggedIn) {
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

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.secondaryWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Logo Symbol (Dynamic Custom Design)
                  // Container(
                  //   width: 90,
                  //   height: 90,
                  //   decoration: BoxDecoration(
                  //     gradient: AppTheme.goldGradient,
                  //     borderRadius: BorderRadius.circular(24),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: AppTheme.accentGold.withOpacity(0.3),
                  //         blurRadius: 20,
                  //         spreadRadius: 2,
                  //         offset: const Offset(0, 8),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Image.asset(
                  //     'assets/images/png/app_icon.png',
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),

                  // const SizedBox(height: 24),
                  // // Logo Text
                  // RichText(
                  //   text: TextSpan(
                  //     children: [
                  //       TextSpan(
                  //         text: 'BarQody',
                  //         style: TextStyle(
                  //           fontSize: 38,
                  //           fontWeight: FontWeight.w900,
                  //           letterSpacing: -1,
                  //           color: isDark ? Colors.white : Colors.black,
                  //         ),
                  //       ),
                  //       const TextSpan(
                  //         text: '.',
                  //         style: TextStyle(
                  //           fontSize: 42,
                  //           fontWeight: FontWeight.w900,
                  //           color: AppTheme.accentGold,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Image.asset(
                    "assets/images/png/en_ar_logo.png",
                    fit: BoxFit.cover,
                    height: 180,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DIGITAL BUSINESS Card',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.grey.shade700,  
                    ),
                  ),
                  Text(
                    ' بطاقة أعمال الرقمية',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
