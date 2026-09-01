import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_ui.dart';

/// WhatsApp Business–inspired typography, colors, and surfaces.
///
/// Font sizes come from [AppUi] — change them there for app-wide control.
class WaUi {
  static const Color scaffold = Color(0xFFF0F2F5);
  static const Color toolsScaffold = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color navBarBg = Color(0xFFFFFFFF);
  static const Color navPill = Color(0xFFE9EDEF);
  static const Color navGreen = Color(0xFF10A375);
  static const Color navInactive = Color(0xFFBDBDBD);
  static const Color primaryText = Color(0xFF111B21);
  static const Color secondaryText = Color(0xFF667781);
  static const Color divider = Color(0xFFE9EDEF);
  static const Color accent = Color(0xFF25D366);
  static const Color chipBg = Color(0xFFE7FCE3);
  static const Color chipSelected = Color(0xFFE9EDEF);
  static const Color chipBorder = Color(0xFFD1D7DB);
  static const Color searchBg = Color(0xFFF0F2F5);
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color fieldOutline = Color(0xFFDDDFE2);
  static const Color fieldOutlineFocused = Color(0xFFBEC3C9);
  static const Color promoIconBg = Color(0xFFE7F3FF);
  static const Color promoIconFg = Color(0xFF54656F);
  /// Primary solid button / CTA fill — change here for buttons app-wide.
  static const Color buttonDark = Color(0xFF000000);
  static const Color readCheck = Color(0xFF53BDEB);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusPill = 100;
  static const double primaryButtonHeight = 48;

  static String get fontFamily => AppFonts.fontFamily;

  static TextStyle _style({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = primaryText,
    double? height,
    double? letterSpacing,
  }) {
    final scriptAware = AppFonts.usesArabicScript || AppFonts.isHebrew;
    return AppFonts.textStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? AppFonts.defaultHeight,
      letterSpacing: scriptAware ? 0 : letterSpacing,
    );
  }

  /// Tools / chats screen title — large left header (WhatsApp-style).
  ///
  /// Prefer [toolsTitleOf] when changing weight/size. Google Fonts embeds
  /// weight into the family, so `copyWith(fontWeight: …)` often looks unchanged.
  static TextStyle get toolsTitle => toolsTitleOf();

  /// Rebuilds the tools title via [AppFonts.titleStyle] so weight actually applies.
  ///
  /// Uses `inherit: false` so AppBar/theme [DefaultTextStyle] (often w600)
  /// cannot merge back to a heavier weight.
  /// Do not `copyWith(fontWeight:)` after Google Fonts — that re-breaks weight.
  static TextStyle toolsTitleOf({
    FontWeight weight = FontWeight.w400,
    double? size,
    double? height,
    Color color = primaryText,
    double? letterSpacing,
  }) {
    final scriptAware = AppFonts.usesArabicScript || AppFonts.isHebrew;
    final style = AppFonts.titleStyle(
      fontSize: size ?? AppUi.fontToolsTitle,
      fontWeight: weight,
      color: color,
      height: height ?? (AppFonts.isUrdu ? 1.45 : 1.15),
      letterSpacing: scriptAware ? 0 : (letterSpacing ?? -0.2),
    );
    return style.copyWith(inherit: false);
  }

  static TextStyle get sectionHeader => _style(
        size: AppUi.fontSection,
        weight: FontWeight.w600,
        height: AppFonts.isUrdu ? 1.45 : 1.2,
      );

  static TextStyle get headline => _style(
        size: AppUi.fontHeadline,
        weight: FontWeight.w600,
        height: AppFonts.isUrdu ? 1.45 : 1.2,
        letterSpacing: -0.2,
      );

  /// AppBar title — WhatsApp-style (same as [headline]).
  /// Prefer omitting [Text.style] so [ThemeData.appBarTheme] applies, or use this.
  static TextStyle get appBarTitle => headline;

  static TextStyle get title => _style(
        size: AppUi.fontTitle,
        weight: FontWeight.w500,
      );

  static TextStyle get listTitle => _style(
        size: AppUi.fontListTitle,
        weight: FontWeight.w500,
      );

  static TextStyle get body => _style(
        size: AppUi.fontBody,
        weight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => _style(
        size: AppUi.fontBody,
        weight: FontWeight.w500,
      );

  static TextStyle get caption => _style(
        size: AppUi.fontCaption,
        weight: FontWeight.w400,
        color: secondaryText,
      );

  static TextStyle get listSubtitle => _style(
        size: AppUi.fontCaption,
        weight: FontWeight.w400,
        color: secondaryText,
      );

  static TextStyle get label => _style(
        size: AppUi.fontLabel,
        weight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0.1,
      );

  static TextStyle get navLabel => _style(
        size: AppUi.fontLabel,
        weight: FontWeight.w500,
        height: AppFonts.isUrdu ? 1.35 : 1.1,
      );

  static TextStyle get navLabelActive => _style(
        size: AppUi.fontLabel,
        weight: FontWeight.w600,
        height: AppFonts.isUrdu ? 1.35 : 1.1,
      );

  static TextStyle get button => _style(
        size: AppUi.fontBodyLg,
        weight: FontWeight.w600,
        height: 1.0,
      );

  static TextStyle get promoTitle => _style(
        size: AppUi.fontBodyLg,
        weight: FontWeight.w600,
      );

  static TextStyle get promoBody => _style(
        size: AppUi.fontCaption,
        weight: FontWeight.w400,
        color: secondaryText,
        height: AppFonts.isUrdu ? 1.55 : 1.4,
      );

  static TextStyle get promoButton => _style(
        size: AppUi.fontBodyLg,
        weight: FontWeight.w600,
        color: Colors.white,
        height: 1.0,
      );

  /// Chats / contacts list row.
  static TextStyle get chatName => _style(
        size: AppUi.fontChatName,
        weight: FontWeight.w600,
        height: AppFonts.isUrdu ? 1.45 : 1.2,
      );

  static TextStyle get chatPreview => _style(
        size: AppUi.fontCaption,
        weight: FontWeight.w400,
        color: secondaryText,
      );

  static TextStyle get chatDate => _style(
        size: AppUi.fontLabel,
        weight: FontWeight.w400,
        color: secondaryText,
        height: AppFonts.isUrdu ? 1.35 : 1.1,
      );

  static TextStyle get chatDateHighlight => _style(
        size: AppUi.fontLabel,
        weight: FontWeight.w500,
        color: accent,
        height: AppFonts.isUrdu ? 1.35 : 1.1,
      );

  static TextStyle get avatarInitial => _style(
        size: AppUi.fontAvatarInitial,
        weight: FontWeight.w500,
        color: primaryText,
      );

  static const List<Color> avatarPalette = [
    Color(0xFFCBE7F5),
    Color(0xFFD8F0CB),
    Color(0xFFFADBD8),
    Color(0xFFE8DAEF),
    Color(0xFFF9E79F),
    Color(0xFFD5DBDB),
  ];

  static BoxDecoration get sheetDecoration => BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusLg)),
      );

  static BoxDecoration tileDecoration({bool selected = false}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(
          color: selected ? accent : divider,
          width: selected ? 1.5 : 1,
        ),
      );

  static BoxDecoration get promoCardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: divider, width: 1),
      );

  /// Facebook-style field: white fill + light grey outline (never black).
  static const OutlineInputBorder fieldEnabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
    borderSide: BorderSide(color: fieldOutline),
  );

  static const OutlineInputBorder fieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
    borderSide: BorderSide(color: fieldOutlineFocused),
  );

  static const OutlineInputBorder fieldErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
    borderSide: BorderSide(color: Color(0xFFE53935)),
  );

  static BoxDecoration get fieldBox => BoxDecoration(
        color: fieldFill,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: fieldOutline),
      );

  static OutlineInputBorder fieldBorder({double radius = radiusMd}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: fieldOutline),
    );
  }

  static OutlineInputBorder fieldFocused({double radius = radiusMd}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: fieldOutlineFocused),
    );
  }

  static InputDecoration fieldDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
    double radius = radiusMd,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldFill,
      hintStyle: _style(size: AppUi.fontBody, color: secondaryText),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: fieldBorder(radius: radius),
      enabledBorder: fieldBorder(radius: radius),
      focusedBorder: fieldFocused(radius: radius),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
      ),
    );
  }
}
