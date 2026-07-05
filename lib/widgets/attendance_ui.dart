import 'package:flutter/material.dart';

/// Bold, chunky attendance UI — large text and thick buttons.
class AttendanceUi {
  static const String fontFamily = 'Urbanist';

  static const double buttonHeight = 62;
  static const double borderWidth = 3;
  static const double radius = 18;

  static TextStyle get pageTitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        height: 1.1,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      );

  static TextStyle get cardTitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.35,
      );

  static TextStyle get bodyMuted => TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
        height: 1.35,
      );

  static TextStyle get statNumber => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1,
      );

  static TextStyle get statLabel => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      );

  static TextStyle get buttonLabel => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      );

  static BoxDecoration get thickCard => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration thickCardFilled({Color fill = Colors.black}) =>
      BoxDecoration(
        color: fill,
        border: Border.all(color: Colors.black, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
      );

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black, size: 28),
      title: Text(title, style: pageTitle.copyWith(fontSize: 24)),
      actions: actions,
    );
  }

  static Widget sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: sectionTitle),
    );
  }

  static Widget primaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    double? height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height ?? buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: const BorderSide(color: Colors.black, width: borderWidth),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 26),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: buttonLabel),
                ],
              ),
      ),
    );
  }

  static Widget secondaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    double? height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height ?? buttonHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 26),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: buttonLabel),
                ],
              ),
      ),
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Colors.black, width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Colors.black, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Colors.black, width: borderWidth),
      ),
    );
  }

  static Widget timeChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: thickCard,
          child: Column(
            children: [
              Text(label, style: statLabel.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
