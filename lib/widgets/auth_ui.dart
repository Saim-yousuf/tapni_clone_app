import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

/// Shared visual tokens + chrome for Figma auth / onboarding screens.
/// Logic-free — layout helpers only.
class AuthUi {
  AuthUi._();

  // Figma PNG icons for auth / onboarding flow
  static const String iconLanguage = 'assets/images/png/language-icon.png';
  static const String iconCardsArena = 'assets/images/png/cards-arena.png';
  static const String iconCamera = 'assets/images/png/camera-icon.png';
  static const String iconPlus = 'assets/images/png/plus-icon.png';
  static const String iconPerson = 'assets/images/png/person-icon.png';
  static const String iconStar = 'assets/images/png/star-icon.png';

  static const Color bg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFF000000);
  static const Color fieldFill = Color(0xFFF5F5F5);
  static const Color backBtnBg = Color(0xFFF2F2F7);
  static const Color keypadBg = Color(0xFFF7F7F8);
  static const Color keyBg = Color(0xFFFFFFFF);

  static const double horizontalPad = 24;
  static const double fieldRadius = 12;
  static const double cardRadius = 18;
  static const double buttonHeight = 52;

  static TextStyle get screenTitle => WaUi.headline.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.6,
      );

  static TextStyle get heroTitle => WaUi.headline.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.4,
      );

  static TextStyle get sectionTitle => WaUi.headline.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get body => WaUi.body.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.45,
      );

  static TextStyle get fieldLabel => WaUi.label.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.8,
      );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: AuthUi.backBtnBg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AuthUi.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: AuthUi.fieldLabel,
      ),
    );
  }
}

class AuthPillButton extends StatelessWidget {
  const AuthPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuthUi.buttonHeight / 2),
        boxShadow: onPressed == null && !loading ? null : AuthUi.softShadow,
      ),
      child: SizedBox(
        height: AuthUi.buttonHeight,
        width: double.infinity,
        child: WaPrimaryButton(
          label: label,
          onPressed: onPressed,
          loading: loading,
        ),
      ),
    );
  }
}

class AuthOutlinedChip extends StatelessWidget {
  const AuthOutlinedChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AuthUi.textPrimary, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 6),
                ] else ...[
                  const Icon(Icons.add, size: 16, color: AuthUi.textPrimary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: WaUi.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AuthUi.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
