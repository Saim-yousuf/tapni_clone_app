import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/complete_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
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
  _ProfileType _selected = _ProfileType.personal;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompleteProfileScreen(
          phone: widget.phone,
          verificationToken: widget.verificationToken,
          country: widget.country,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthUi.bg,
      appBar: AppBar(
        backgroundColor: AuthUi.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AuthBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Choose',
          style: AuthUi.screenTitle.copyWith(letterSpacing: 0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthUi.horizontalPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Choose your profile type to get started',
                      style: AuthUi.sectionTitle.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select how you want to use ${context.l10n.appTitle}',
                      style: AuthUi.body,
                    ),
                    const SizedBox(height: 28),
                    _ProfileTypeCard(
                      title: 'Personal Profile',
                      description:
                          'For individuals share your contact details, social links & QR code.',
                      iconAsset: AuthUi.iconPerson,
                      selected: _selected == _ProfileType.personal,
                      onTap: () =>
                          setState(() => _selected = _ProfileType.personal),
                    ),
                    const SizedBox(height: 14),
                    _ProfileTypeCard(
                      title: 'Business Profile',
                      description:
                          'For businesses & brands showcase your business, services & customer rewards.',
                      iconAsset: AuthUi.iconStar,
                      selected: _selected == _ProfileType.business,
                      onTap: () =>
                          setState(() => _selected = _ProfileType.business),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AuthUi.horizontalPad,
                8,
                AuthUi.horizontalPad,
                20,
              ),
              child: AuthPillButton(
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
  });

  final String title;
  final String description;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AuthUi.bg : AuthUi.fieldFill,
      borderRadius: BorderRadius.circular(AuthUi.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuthUi.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuthUi.cardRadius),
            border: Border.all(
              color: selected ? AuthUi.borderFocused : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: AuthUi.cardShadow,
            color: Colors.transparent,
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
                          style: WaUi.headline.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AuthUi.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: AuthUi.body.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    iconAsset,
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 28,
                      color: AuthUi.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
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
