import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Locale-aware typography for scripts that Roboto does not render well.
class AppFonts {
  AppFonts._();

  static Locale? _locale;

  /// Call whenever the effective app locale changes (including system locale).
  static void bind(Locale? locale) {
    _locale = locale;
  }

  static Locale? get locale => _locale;

  static String get languageCode => _locale?.languageCode ?? 'en';

  /// Arabic-script languages that need a dedicated UI font.
  static bool get usesArabicScript {
    const codes = {'ar', 'fa', 'ur', 'ps', 'sd', 'ku'};
    return codes.contains(languageCode);
  }

  static bool get isUrdu => languageCode == 'ur';

  static bool get isHebrew => languageCode == 'he';

  /// Default line height — Nastaliq needs more vertical space.
  static double get defaultHeight => isUrdu ? 1.55 : 1.35;

  static String get fontFamily => textStyle().fontFamily!;

  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    final h = height ?? defaultHeight;

    if (isUrdu) {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: h,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    }

    if (usesArabicScript) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: h,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    }

    if (isHebrew) {
      return GoogleFonts.rubik(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: h,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    }

    return GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: h,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Screen titles (Tools / Contacts / Analytics, etc.).
  ///
  /// Uses fonts that actually ship Light/Regular/Bold. Nastaliq only has
  /// Regular, so weight changes on titles would otherwise look identical.
  static TextStyle titleStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    final h = height ?? defaultHeight;

    if (usesArabicScript) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: h,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    }

    if (isHebrew) {
      return GoogleFonts.rubik(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: h,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    }

    return GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: h,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextTheme textTheme(TextTheme base) {
    if (isUrdu) {
      return GoogleFonts.notoNastaliqUrduTextTheme(base);
    }
    if (usesArabicScript) {
      return GoogleFonts.cairoTextTheme(base);
    }
    if (isHebrew) {
      return GoogleFonts.rubikTextTheme(base);
    }
    return GoogleFonts.robotoTextTheme(base);
  }
}
