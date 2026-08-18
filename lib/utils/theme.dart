import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

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

  /// Status + nav bar colors matching app theme (WhatsApp-style).
  static SystemUiOverlayStyle systemUiFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: isDark ? primaryBlack : secondaryWhite,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? primaryBlack : secondaryWhite,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static void applySystemUi(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(systemUiFor(brightness));
  }

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

  /// Backwards-compatible getters (Latin / Roboto).
  static ThemeData get lightTheme => lightThemeFor(null);
  static ThemeData get darkTheme => darkThemeFor(null);

  // LIGHT THEME — locale-aware typography
  static ThemeData lightThemeFor(Locale? locale) {
    AppFonts.bind(locale);
    final baseText = ThemeData.light().textTheme.apply(bodyColor: primaryBlack);
    final height = AppFonts.defaultHeight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: secondaryWhite,
      cardColor: secondaryWhite,
      fontFamily: AppFonts.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        secondary: primaryBlack,
        background: secondaryWhite,
        surface: secondaryWhite,
        onPrimary: secondaryWhite,
        onSecondary: secondaryWhite,
      ),
      textTheme: AppFonts.textTheme(baseText).copyWith(
        displayLarge: AppFonts.textStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        displayMedium: AppFonts.textStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        headlineLarge: AppFonts.textStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        headlineMedium: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
        titleLarge: AppFonts.textStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
        titleMedium: AppFonts.textStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
          height: height,
        ),
        bodyLarge: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: height,
        ),
        bodyMedium: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: height,
        ),
        bodySmall: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryBlack,
          height: height,
        ),
        labelLarge: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
          height: height,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: systemUiFor(Brightness.light),
        iconTheme: const IconThemeData(color: primaryBlack),
        centerTitle: true,
        titleTextStyle: AppFonts.textStyle(
          color: primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: secondaryWhite,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(64, WaUi.primaryButtonHeight),
          maximumSize: const Size(double.infinity, WaUi.primaryButtonHeight),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WaUi.fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: WaUi.secondaryText,
          height: height,
        ),
        border: WaUi.fieldEnabledBorder,
        enabledBorder: WaUi.fieldEnabledBorder,
        focusedBorder: WaUi.fieldFocusedBorder,
        errorBorder: WaUi.fieldErrorBorder,
        focusedErrorBorder: WaUi.fieldErrorBorder,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondaryWhite,
        selectedItemColor: primaryBlack,
        unselectedItemColor: primaryBlack,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // DARK THEME — locale-aware typography
  static ThemeData darkThemeFor(Locale? locale) {
    AppFonts.bind(locale);
    final baseText =
        ThemeData.dark().textTheme.apply(bodyColor: secondaryWhite);
    final height = AppFonts.defaultHeight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryWhite,
      scaffoldBackgroundColor: primaryBlack,
      cardColor: primaryBlack,
      fontFamily: AppFonts.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: secondaryWhite,
        secondary: secondaryWhite,
        background: primaryBlack,
        surface: primaryBlack,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
      ),
      textTheme: AppFonts.textTheme(baseText).copyWith(
        displayLarge: AppFonts.textStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        displayMedium: AppFonts.textStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        headlineLarge: AppFonts.textStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: secondaryWhite,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.3,
          height: height,
        ),
        headlineMedium: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: secondaryWhite,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
        titleLarge: AppFonts.textStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: secondaryWhite,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
        titleMedium: AppFonts.textStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: secondaryWhite,
          height: height,
        ),
        bodyLarge: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: height,
        ),
        bodyMedium: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: height,
        ),
        bodySmall: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryWhite,
          height: height,
        ),
        labelLarge: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: secondaryWhite,
          height: height,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: systemUiFor(Brightness.dark),
        iconTheme: const IconThemeData(color: secondaryWhite),
        centerTitle: true,
        titleTextStyle: AppFonts.textStyle(
          color: secondaryWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: AppFonts.usesArabicScript ? 0 : -0.2,
          height: height,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryWhite,
          foregroundColor: primaryBlack,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(64, WaUi.primaryButtonHeight),
          maximumSize: const Size(double.infinity, WaUi.primaryButtonHeight),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3B3C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB0B3B8),
          height: height,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(WaUi.radiusMd)),
          borderSide: BorderSide(color: Color(0xFF4E4F50)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(WaUi.radiusMd)),
          borderSide: BorderSide(color: Color(0xFF4E4F50)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(WaUi.radiusMd)),
          borderSide: BorderSide(color: Color(0xFFB0B3B8)),
        ),
        errorBorder: WaUi.fieldErrorBorder,
        focusedErrorBorder: WaUi.fieldErrorBorder,
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
