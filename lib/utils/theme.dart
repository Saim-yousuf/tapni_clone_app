import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (UNCHANGED NAMES)
  static const Color primaryBlack = Colors.black;
  static const Color secondaryWhite = Color(0xFFFFFFFF);
  static const Color accentBlack = Color(0xFF111111);
  static const Color accentDarkGrey = Color(0xFF000000); // forced black only

  // Accent GOLD removed visually → forced black only
  static const Color accentGold = Color(0xFF000000);
  static const Color accentGoldDark = Color(0xFF000000);

  // Grey Tones → simplified (no visible color variation)
  static const Color greyLightBg = Color(0xFFFFFFFF);
  static const Color greyDarkBg = Color(0xFF000000);
  static const Color cardDarkBg = Color(0xFF000000);
  static const Color cardLightBg = Color(0xFFFFFFFF);
  static const Color greyBorderLight = Color(0xFF000000);
  static const Color greyBorderDark = Color(0xFFFFFFFF);
  static const Color textGreyLight = Color(0xFF000000);
  static const Color textGreyDark = Color(0xFFFFFFFF);

  // PURE BLACK GRADIENT (NO OTHER COLOR)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Colors.black, Colors.black],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Colors.black, Colors.black],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism (neutral only)
  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 16.0,
    double borderOpacity = 0.1,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.black.withOpacity(0.05)
          : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.black.withOpacity(borderOpacity)
            : Colors.white.withOpacity(borderOpacity),
        width: 1.0,
      ),
    );
  }

  // LIGHT THEME — WhatsApp-style Roboto typography
  static ThemeData get lightTheme {
    final baseText = ThemeData.light().textTheme.apply(bodyColor: primaryBlack);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: secondaryWhite,
      cardColor: secondaryWhite,
      fontFamily: GoogleFonts.roboto().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        secondary: primaryBlack,
        background: secondaryWhite,
        surface: secondaryWhite,
        onPrimary: secondaryWhite,
        onSecondary: secondaryWhite,
      ),
      textTheme: GoogleFonts.robotoTextTheme(baseText).copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: -0.3,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: 1.35,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: 1.35,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: 1.35,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlack),
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          color: primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: secondaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryWhite,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondaryWhite,
        selectedItemColor: primaryBlack,
        unselectedItemColor: primaryBlack,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // DARK THEME — WhatsApp-style Roboto typography
  static ThemeData get darkTheme {
    final baseText = ThemeData.dark().textTheme.apply(bodyColor: secondaryWhite);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryWhite,
      scaffoldBackgroundColor: primaryBlack,
      cardColor: primaryBlack,
      fontFamily: GoogleFonts.roboto().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: secondaryWhite,
        secondary: secondaryWhite,
        background: primaryBlack,
        surface: primaryBlack,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
      ),
      textTheme: GoogleFonts.robotoTextTheme(baseText).copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: -0.3,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: secondaryWhite,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: secondaryWhite,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: secondaryWhite,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: 1.35,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: 1.35,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: 1.35,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: secondaryWhite,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: secondaryWhite),
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          color: secondaryWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryWhite,
          foregroundColor: primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryBlack,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryWhite, width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: secondaryWhite,
        unselectedItemColor: secondaryWhite,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
