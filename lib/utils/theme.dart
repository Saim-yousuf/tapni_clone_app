import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (UNCHANGED NAMES)
  static const Color primaryBlack = Color(0xFF000000);
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

  // LIGHT THEME (BLACK & WHITE ONLY)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: secondaryWhite,
      cardColor: secondaryWhite,

      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        secondary: primaryBlack,
        background: secondaryWhite,
        surface: secondaryWhite,
        onPrimary: secondaryWhite,
        onSecondary: secondaryWhite,
      ),

      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryBlack,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryBlack,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: primaryBlack),
          bodyMedium: TextStyle(fontSize: 14, color: primaryBlack),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlack),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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

  // DARK THEME (PURE BLACK ONLY)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryWhite,
      scaffoldBackgroundColor: primaryBlack,
      cardColor: primaryBlack,

      colorScheme: const ColorScheme.dark(
        primary: secondaryWhite,
        secondary: secondaryWhite,
        background: primaryBlack,
        surface: primaryBlack,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
      ),

      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: secondaryWhite,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: secondaryWhite,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: secondaryWhite,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: secondaryWhite),
          bodyMedium: TextStyle(fontSize: 14, color: secondaryWhite),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryWhite),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: secondaryWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
