import 'package:flutter/material.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_button.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _pages(BuildContext context) => [
    {
      'title': context.l10n.oneTapToShare,
      'description':
          'Share your digital card instantly via NFC or QR Code. No app required for others to view your details.',
      'icon': Icons.contactless_rounded,
      'gradient': [Color(0xFF1E1E24), Color(0xFF0D0D0E)],
    },
    {
      'title': context.l10n.alwaysUpToDate,
      'description':
          'Keep your info updated in real time. Modify your social handles, title, or phone number and watch it update immediately.',
      'icon': Icons.sync_lock_rounded,
      'gradient': [Color(0xFF251F14), Color(0xFF0D0D0E)],
    },
    {
      'title': context.l10n.smartContactCapture,
      'description':
          'Collect contacts during meetings. Let prospects fill out their details directly on your profile page to save them instantly.',
      'icon': Icons.people_outline_rounded,
      'gradient': [Color(0xFF15221F), Color(0xFF0D0D0E)],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Transition
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? _pages(context)[_currentPage]['gradient']
                    : [Colors.white, const Color(0xFFF3F3F7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header with Skip Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // child: Icon(Icons.contactless, color: Colors.black, size: 18),
                            child: Image.asset(
                              "assets/images/png/app_icon.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            context.l10n.appTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          context.l10n.skip,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textGreyDark
                                : AppTheme.textGreyLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slider Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages(context).length,
                    itemBuilder: (context, index) {
                      final item = _pages(context)[index];
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Beautiful interactive vector container instead of missing local image
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withOpacity(0.03),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isDark
                                      ? Colors.white24
                                      : Colors.black12),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.goldGradient,
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentGold.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: index == 0
                                      ? Image.asset(
                                          'assets/images/png/app_icon.png',
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          item['icon'],
                                          size: 72,
                                          color: AppTheme.secondaryWhite,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              item['title'],
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item['description'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark
                                    ? AppTheme.textGreyDark
                                    : AppTheme.textGreyLight,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Navigation Indicator & Controls
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages(context).length,
                          (index) => AnimatedContainer(
                            duration: Duration(milliseconds: 350),
                            margin: EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: _currentPage == index ? 24.0 : 8.0,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.accentGold
                                  : (isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Action Button
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: _currentPage == _pages(context).length - 1
                                  ? context.l10n.getStarted
                                  : context.l10n.next,
                              onTap: _onNextPage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
