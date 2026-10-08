import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/complete_profile_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

/// Figma "Choose" step — personal vs business (UI selection only).
/// Signup API / token handling stays on [CompleteProfileScreen].
class ChooseProfileTypeScreen extends StatefulWidget {
  const ChooseProfileTypeScreen({
    super.key,
    required this.phone,
    required this.verificationToken,
    this.country,
  });

  final String phone;
  final String verificationToken;
  final String? country;

  @override
  State<ChooseProfileTypeScreen> createState() =>
      _ChooseProfileTypeScreenState();
}

enum _ProfileType { personal, business }

class _ChooseProfileTypeScreenState extends State<ChooseProfileTypeScreen> {
  // Figma reference shows Business selected.
  _ProfileType _selected = _ProfileType.business;

  void _continue() {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => CompleteProfileScreen(
          phone: widget.phone,
          verificationToken: widget.verificationToken,
          country: widget.country,
        ),
      ),
    );
  }

  TextStyle _text(
    AuthScale m, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuthUi.textPrimary,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return AppFonts.textStyle(
      fontSize: m.s(size),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthAppBarTitle(
              'Choose',
              showBack: true,
              allCaps: false,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  m.padH,
                  m.v(28),
                  m.padH,
                  m.v(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your profile type to get\nstarted',
                      style: _text(
                        m,
                        size: 24,
                        weight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: m.v(10)),
                    Text(
                      'Select how you want to use ${context.l10n.appTitle}',
                      style: _text(
                        m,
                        size: AuthUi.bodySize,
                        color: AuthUi.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: m.v(32)),
                    _ProfileTypeCard(
                      title: 'Personal Profile',
                      description:
                          'For individuals share your\ncontact details, social links &\nQR code.',
                      iconAsset: AuthUi.iconPerson,
                      selected: _selected == _ProfileType.personal,
                      onTap: () =>
                          setState(() => _selected = _ProfileType.personal),
                      scale: m,
                    ),
                    SizedBox(height: m.v(16)),
                    _ProfileTypeCard(
                      title: 'Business Profile',
                      description:
                          'For businesses & brands\nshowcase your business,\nservices & customer\nrewards.',
                      iconAsset: AuthUi.iconStar,
                      selected: _selected == _ProfileType.business,
                      onTap: () =>
                          setState(() => _selected = _ProfileType.business),
                      scale: m,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                m.padH,
                m.v(12),
                m.padH,
                m.v(20) + (bottom > 0 ? 0 : m.v(8)),
              ),
              child: AuthPrimaryPillButton(
                label: context.l10n.continueLabel,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTypeCard extends StatelessWidget {
  const _ProfileTypeCard({
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final String title;
  final String description;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;
  final AuthScale scale;

  static const _fill = Color(0xFFF5F5F5);
  static const _unselectedStroke = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final m = scale;
    final radius = m.s(20);
    final iconSize = m.s(48);

    return Material(
      color: _fill,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(m.s(20), m.s(20), m.s(16), m.s(16)),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? AuthUi.borderFocused : _unselectedStroke,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000), // #000 @ 25%
                offset: Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.textStyle(
                            fontSize: m.s(17),
                            fontWeight: FontWeight.w700,
                            color: AuthUi.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: m.s(8)),
                        Text(
                          description,
                          style: AppFonts.textStyle(
                            fontSize: m.s(13),
                            fontWeight: FontWeight.w400,
                            color: AuthUi.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: m.s(12)),
                  Image.asset(
                    iconAsset,
                    width: iconSize,
                    height: iconSize,
                    color: AuthUi.textPrimary,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: iconSize,
                      color: AuthUi.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: m.s(12)),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                  size: m.s(24),
                  color: AuthUi.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
