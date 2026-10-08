import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Canonical UI tokens from the finalized Login screen (Figma + polish).
///
/// Use [AuthScale], [AuthAppBarTitle], [AuthPrimaryPillButton],
/// [AuthOutlinedPillButton] on every screen we polish so buttons, app bars,
/// fields, spacing, and type stay consistent.
class AuthUi {
  AuthUi._();

  // Figma PNG icons for auth / onboarding flow
  static const String iconLanguage = 'assets/images/png/language-icon.png';
  static const String iconCardsArena = 'assets/images/png/cards-arena.png';
  static const String iconCamera = 'assets/images/png/camera-icon.png';
  static const String iconPlus = 'assets/images/png/plus-icon.png';
  static const String iconPerson = 'assets/images/png/person-icon.png';
  static const String iconStar = 'assets/images/png/star-icon.png';

  // ── Colors (login final) ──────────────────────────────────────────
  static const Color bg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  /// Figma grey for body / secondary copy.
  static const Color textSecondary = Color(0xFF6B7280);
  /// Labels, hints, timers — same Figma grey token.
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E5EA);
  static const Color borderFocused = Color(0xFF000000);
  static const Color fieldFill = Color(0xFFF5F5F5);
  static const Color backBtnBg = Color(0xFFF2F2F7);
  /// iOS-style keypad tray (Figma OTP).
  static const Color keypadBg = Color(0xFFE5E5EA);
  static const Color keyBg = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);

  // ── Layout (design pts @ 390 width) ───────────────────────────────
  static const double designWidth = 390;
  static const double designHeight = 844;
  static const double maxContentWidth = 430;

  /// Side inset ≈ 7.7% of width (30/390).
  static const double horizontalPad = 30;
  static const double fieldRadius = 12;
  static const double cardRadius = 18;
  static const double buttonHeight = 54;
  static const double fieldHeight = 54;
  static const double appBarHeight = 52;
  static const double appBarTitleSize = 20;
  static const double heroTitleSize = 32;
  static const double bodySize = 15;
  static const double labelSize = 11;
  static const double legalSize = 12;
  static const double buttonLabelSize = 16;
  static const double outlineBorderWidth = 1.5;
  static const double focusBorderWidth = 2.0;

  /// Primary pill shadow — Figma: x0 y8 blur16 spread0 #000 @ 10.2%.
  static List<BoxShadow> primaryButtonShadow(AuthScale m) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.102),
          offset: Offset(0, m.s(8)),
          blurRadius: m.s(16),
          spreadRadius: 0,
        ),
      ];

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

  // Legacy style getters (prefer AuthScale + explicit sizes on new screens)
  static TextStyle get screenTitle => WaUi.headline.copyWith(
        fontSize: appBarTitleSize,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: 1.4,
      );

  static TextStyle get heroTitle => WaUi.headline.copyWith(
        fontSize: heroTitleSize,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionTitle => WaUi.headline.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get body => WaUi.body.copyWith(
        fontSize: bodySize,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.45,
      );

  static TextStyle get fieldLabel => WaUi.label.copyWith(
        fontSize: labelSize,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.85,
      );
}

/// Proportional scaler — use on every polished screen.
class AuthScale {
  AuthScale._({
    required this.scale,
    required this.vScale,
    required this.contentWidth,
    required this.padH,
  });

  final double scale;
  final double vScale;
  final double contentWidth;
  final double padH;

  static AuthScale of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthForScale = size.width.clamp(320.0, 430.0);
    final scale =
        (widthForScale / AuthUi.designWidth).clamp(0.88, 1.12);
    final heightForScale = size.height.clamp(560.0, 926.0);
    final vScale =
        (heightForScale / AuthUi.designHeight).clamp(0.88, 1.06);
    final contentWidth =
        size.width.clamp(0.0, AuthUi.maxContentWidth * scale);
    final padH = (size.width * (AuthUi.horizontalPad / AuthUi.designWidth))
        .clamp(24.0, 40.0);

    return AuthScale._(
      scale: scale,
      vScale: vScale,
      contentWidth: contentWidth,
      padH: padH,
    );
  }

  double s(double pt) => pt * scale;

  double v(double pt) => pt * vScale;

  double get fieldH => s(AuthUi.fieldHeight);

  double get buttonH => s(AuthUi.buttonHeight);

  double get radius => s(AuthUi.fieldRadius);

  double get appBarH => v(AuthUi.appBarHeight);
}

/// Auth app bar — lock this for Login / OTP / QR Login (and future auth screens).
///
/// - Height: [AuthUi.appBarHeight] via [AuthScale.appBarH]
/// - Title: ALL-CAPS, **w800**, 16pt, letterSpacing 1.4, centered
/// - Optional leading [AuthBackButton] (OTP / QR); Login has no back
class AuthAppBarTitle extends StatelessWidget {
  const AuthAppBarTitle(
    this.title, {
    super.key,
    this.onBack,
    this.showBack = false,
    this.allCaps = true,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBack;

  /// Login / OTP / QR use ALL-CAPS + tracking. Some steps (e.g. Choose) keep title case.
  final bool allCaps;

  static TextStyle titleStyle(AuthScale m, {bool allCaps = true}) =>
      AppFonts.textStyle(
        fontSize: m.s(AuthUi.appBarTitleSize),
        fontWeight: FontWeight.w800,
        color: AuthUi.textPrimary,
        letterSpacing: allCaps ? 1.4 : 0,
        height: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final label = Text(
      allCaps ? title.toUpperCase() : title,
      textAlign: TextAlign.center,
      style: titleStyle(m, allCaps: allCaps),
    );

    if (!showBack) {
      return SizedBox(
        height: m.appBarH,
        child: Center(child: label),
      );
    }

    return SizedBox(
      height: m.appBarH,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.padH),
        child: Stack(
          alignment: Alignment.center,
          children: [
            label,
            Align(
              alignment: Alignment.centerLeft,
              child: AuthBackButton(onPressed: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canonical circular back control (OTP / Verify). Use this everywhere.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed, this.backgroundColor});

  final VoidCallback? onPressed;

  /// Defaults to [AuthUi.backBtnBg]. Pass white (etc.) when over a photo.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AuthUi.backBtnBg,
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
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: AppFonts.textStyle(
          fontSize: m.s(AuthUi.labelSize),
          fontWeight: FontWeight.w600,
          color: AuthUi.textMuted,
          letterSpacing: 0.85,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Black filled pill — primary CTA (Continue). Includes Figma drop shadow.
class AuthPrimaryPillButton extends StatelessWidget {
  const AuthPrimaryPillButton({
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
    final m = AuthScale.of(context);
    final h = m.buttonH;
    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: AuthUi.primaryButtonShadow(m),
      ),
      child: Material(
        color: AuthUi.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(h / 2),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(h / 2),
          child: Center(
            child: loading
                ? SizedBox(
                    width: m.s(22),
                    height: m.s(22),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: AppFonts.textStyle(
                      fontSize: m.s(AuthUi.buttonLabelSize),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// White outlined pill — secondary CTA (Login with QR). No shadow.
class AuthOutlinedPillButton extends StatelessWidget {
  const AuthOutlinedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.buttonH;
    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        color: AuthUi.bg,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(
          color: AuthUi.textPrimary,
          width: AuthUi.outlineBorderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(h / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(h / 2),
          child: Center(
            child: Text(
              label,
              style: AppFonts.textStyle(
                fontSize: m.s(AuthUi.buttonLabelSize),
                fontWeight: FontWeight.w700,
                color: AuthUi.textPrimary,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// @Deprecated — use [AuthPrimaryPillButton].
@Deprecated('Use AuthPrimaryPillButton')
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
    return AuthPrimaryPillButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }
}

/// Figma OTP custom numeric keypad (light gray tray + white keys).
class AuthNumericKeypad extends StatelessWidget {
  const AuthNumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Taller keys so the tray sits higher / fills bottom third like Figma.
    final keyH = m.s(52);
    final gap = m.s(8);
    final radius = m.s(6);

    Widget keyFace({
      required Widget child,
      required VoidCallback? onTap,
    }) {
      return Material(
        color: AuthUi.keyBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: keyH,
            child: Center(child: child),
          ),
        ),
      );
    }

    Widget digit(String d) => keyFace(
          onTap: () => onDigit(d),
          child: Text(
            d,
            style: AppFonts.textStyle(
              fontSize: m.s(24),
              fontWeight: FontWeight.w400,
              color: AuthUi.textPrimary,
              height: 1,
            ),
          ),
        );

    return ColoredBox(
      color: AuthUi.keypadBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.s(6),
          m.s(8),
          m.s(6),
          bottom > 0 ? bottom : m.s(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 3; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    Expanded(child: digit('${row * 3 + col + 1}')),
                  ],
                ],
              ),
            ],
            SizedBox(height: gap),
            Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                SizedBox(width: gap),
                Expanded(child: digit('0')),
                SizedBox(width: gap),
                Expanded(
                  child: keyFace(
                    onTap: onBackspace,
                    child: Icon(
                      Icons.backspace_outlined,
                      size: m.s(24),
                      color: AuthUi.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
