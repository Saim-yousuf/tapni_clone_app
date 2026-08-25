import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_fonts.dart';

/// Single place to tune app-wide UI: fonts, AppBar, icons.
///
/// Change values here → [WaUi] text styles + [AppTheme] pick them up.
/// Bottom-nav shell screens (Explore / Contacts / Analytics / Settings / My Card)
/// keep their own AppBar overrides (e.g. Profile / Analytics `centerTitle: false`).
class AppUi {
  AppUi._();

  // ── Font sizes (text styles) ──────────────────────────────────────────
  static const double fontDisplay = 40;
  static const double fontDisplayMd = 34;
  static const double fontHeadlineLg = 28;
  static const double fontHeadlineMd = 24;
  static const double fontToolsTitle = 26;
  static const double fontHeadline = 20; // AppBar title / WaUi.headline
  static const double fontSection = 17;
  static const double fontTitle = 17;
  static const double fontListTitle = 16;
  static const double fontChatName = 16.5;
  static const double fontBody = 15;
  static const double fontBodyLg = 16;
  static const double fontCaption = 14;
  static const double fontLabel = 12;
  static const double fontAvatarInitial = 20;

  // ── AppBar ────────────────────────────────────────────────────────────
  /// Light theme AppBar background.
  static const Color appBarBg = Color(0xFFFFFFFF);

  /// Dark theme AppBar background.
  static const Color appBarBgDark = Color(0xFF000000);

  /// AppBar title + icon color (light).
  static const Color appBarFg = Color(0xFF111B21);

  /// AppBar title + icon color (dark).
  static const Color appBarFgDark = Color(0xFFFFFFFF);

  /// When true, titles are centered unless a screen overrides.
  static const bool appBarCenterTitle = true;

  static const double appBarTitleSize = fontHeadline;
  static const FontWeight appBarTitleWeight = FontWeight.w600;
  static const double appBarElevation = 0;

  /// WhatsApp-style AppBar title (Roboto / Cairo / Nastaliq via [AppFonts]).
  static TextStyle appBarTitleStyle({Color? color, bool dark = false}) {
    final scriptAware = AppFonts.usesArabicScript || AppFonts.isHebrew;
    return AppFonts.textStyle(
      color: color ?? (dark ? appBarFgDark : appBarFg),
      fontSize: appBarTitleSize,
      fontWeight: appBarTitleWeight,
      letterSpacing: scriptAware ? 0 : -0.2,
      height: AppFonts.isUrdu ? 1.45 : 1.2,
    );
  }

  // ── Icons ─────────────────────────────────────────────────────────────
  /// Default Material icon size (IconTheme / IconButton).
  static const double iconSize = 24;

  /// AppBar leading / action icons.
  static const double appBarIconSize = 24;

  /// Padding around IconButtons (incl. AppBar actions).
  static const double iconPadding = 8;

  static EdgeInsets get iconButtonPadding =>
      const EdgeInsets.all(iconPadding);

  static EdgeInsets get appBarIconPadding =>
      const EdgeInsets.all(iconPadding);

  /// Builds a standard AppBar that follows these knobs.
  /// Prefer this (or bare [AppBar] with no overrides) so one place controls look.
  static AppBar appBar({
    Widget? title,
    String? titleText,
    List<Widget>? actions,
    Widget? leading,
    bool? centerTitle,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    PreferredSizeWidget? bottom,
  }) {
    assert(title != null || titleText != null, 'Provide title or titleText');
    final fg = foregroundColor ?? appBarFg;
    return AppBar(
      title: title ??
          Text(
            titleText!,
            style: appBarTitleStyle(color: fg),
          ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle ?? appBarCenterTitle,
      backgroundColor: backgroundColor ?? appBarBg,
      foregroundColor: fg,
      elevation: elevation ?? appBarElevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: fg, size: appBarIconSize),
      actionsIconTheme: IconThemeData(color: fg, size: appBarIconSize),
      bottom: bottom,
    );
  }
}
