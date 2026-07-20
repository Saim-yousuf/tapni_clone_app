import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WhatsApp Business–inspired typography, colors, and surfaces.
class WaUi {
  static const Color scaffold = Color(0xFFF0F2F5);
  static const Color toolsScaffold = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color navBarBg = Color(0xFFF7F8FA);
  static const Color navPill = Color(0xFFE9EDEF);
  static const Color primaryText = Color(0xFF111B21);
  static const Color secondaryText = Color(0xFF667781);
  static const Color divider = Color(0xFFE9EDEF);
  static const Color accent = Color(0xFF25D366);
  static const Color chipBg = Color(0xFFE7FCE3);
  static const Color chipSelected = Color(0xFFE9EDEF);
  static const Color chipBorder = Color(0xFFD1D7DB);
  static const Color searchBg = Color(0xFFF0F2F5);
  static const Color promoIconBg = Color(0xFFE7F3FF);
  static const Color promoIconFg = Color(0xFF54656F);
  static const Color buttonDark = Color(0xFF111B21);
  static const Color readCheck = Color(0xFF53BDEB);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusPill = 100;

  static String get fontFamily => GoogleFonts.roboto().fontFamily!;

  static TextStyle _style({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = primaryText,
    double height = 1.25,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tools / chats screen title — large bold left header (WhatsApp-style).
  static TextStyle get toolsTitle => _style(
        size: 26,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionHeader => _style(
        size: 17,
        weight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get headline => _style(
        size: 20,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle get title => _style(
        size: 17,
        weight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get listTitle => _style(
        size: 16,
        weight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get body => _style(
        size: 15,
        weight: FontWeight.w400,
        height: 1.35,
      );

  static TextStyle get bodyMedium => _style(
        size: 15,
        weight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle get caption => _style(
        size: 14,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.35,
      );

  static TextStyle get listSubtitle => _style(
        size: 14,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.35,
      );

  static TextStyle get label => _style(
        size: 12,
        weight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0.1,
      );

  static TextStyle get navLabel => _style(
        size: 12,
        weight: FontWeight.w500,
        height: 1.1,
      );

  static TextStyle get navLabelActive => _style(
        size: 12,
        weight: FontWeight.w600,
        height: 1.1,
      );

  static TextStyle get button => _style(
        size: 15,
        weight: FontWeight.w500,
      );

  static TextStyle get promoTitle => _style(
        size: 16,
        weight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get promoBody => _style(
        size: 14,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.4,
      );

  static TextStyle get promoButton => _style(
        size: 15,
        weight: FontWeight.w500,
        color: Colors.white,
      );

  /// Chats / contacts list row.
  static TextStyle get chatName => _style(
        size: 16.5,
        weight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get chatPreview => _style(
        size: 14,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.25,
      );

  static TextStyle get chatDate => _style(
        size: 12,
        weight: FontWeight.w400,
        color: secondaryText,
        height: 1.1,
      );

  static TextStyle get chatDateHighlight => _style(
        size: 12,
        weight: FontWeight.w500,
        color: accent,
        height: 1.1,
      );

  static TextStyle get avatarInitial => _style(
        size: 20,
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
}
