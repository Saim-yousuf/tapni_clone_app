import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/screens/app_language_screen.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

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
          'description': context.l10n.onboardingShareDescription,
          'icon': Icons.contactless_rounded,
        },
        {
          'title': context.l10n.alwaysUpToDate,
          'description': context.l10n.onboardingUpToDateDescription,
          'icon': Icons.sync_lock_rounded,
        },
        {
          'title': context.l10n.smartContactCapture,
          'description': context.l10n.onboardingSmartCaptureDescription,
          'icon': Icons.people_outline_rounded,
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
  }

  String _languageChipLabel(LocaleProvider localeProvider) {
    if (localeProvider.isSystemLanguage) return 'English Us';
    final lang = localeProvider.selectedLanguage;
    if (lang == null) return 'English Us';
    final name = lang.englishName;
    final region = lang.code.contains('_') ? lang.code.split('_').last : 'Us';
    if (name.toLowerCase().startsWith('english')) {
      return 'English ${region[0].toUpperCase()}${region.substring(1).toLowerCase()}';
    }
    return lang.nativeName;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/png/app_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.appTitle.toUpperCase(),
                    style: WaUi.headline.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AuthUi.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AuthUi.backBtnBg,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppLanguageScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AuthUi.iconLanguage,
                              width: 16,
                              height: 16,
                              color: AuthUi.textPrimary,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.language_rounded,
                                size: 16,
                                color: AuthUi.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _languageChipLabel(localeProvider),
                              style: WaUi.caption.copyWith(
                                color: AuthUi.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final item = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Expanded(
                          child: index == 0
                              ? const _OnboardingCardsHero()
                              : _OnboardingIconHero(icon: item['icon'] as IconData),
                        ),
                        Text(
                          index == 0
                              ? 'Your Identity.\nOne Tap Away'
                              : item['title'] as String,
                          textAlign: TextAlign.center,
                          style: AuthUi.heroTitle.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['description'] as String,
                          textAlign: TextAlign.center,
                          style: AuthUi.body,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 8,
                        width: active ? 22 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AuthUi.textPrimary
                              : const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  AuthPillButton(
                    label: _currentPage == pages.length - 1
                        ? context.l10n.getStarted
                        : context.l10n.next,
                    onPressed: _onNextPage,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _goToLogin,
                    behavior: HitTestBehavior.opaque,
                    child: Text.rich(
                      TextSpan(
                        style: AuthUi.body.copyWith(fontSize: 14),
                        children: [
                          TextSpan(text: context.l10n.alreadyHaveAnAccount2),
                          TextSpan(
                            text: 'Sign In',
                            style: WaUi.bodyMedium.copyWith(
                              color: AuthUi.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCardsHero extends StatelessWidget {
  const _OnboardingCardsHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AuthUi.iconCardsArena,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _OnboardingIconHero extends StatelessWidget {
  const _OnboardingIconHero({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: AuthUi.fieldFill,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AuthUi.border),
        ),
        child: Icon(icon, size: 64, color: AuthUi.textPrimary),
      ),
    );
  }
}
