import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Attendance screens — WhatsApp Business–style surfaces and typography.
class AttendanceUi {
  static String get fontFamily => WaUi.fontFamily;

  static const double buttonHeight = 52;
  static const double borderWidth = 1;
  static const double radius = WaUi.radiusLg;

  static Color get scaffoldBg => WaUi.toolsScaffold;
  static Color get primaryText => WaUi.primaryText;
  static Color get secondaryText => WaUi.secondaryText;
  static Color get divider => WaUi.divider;
  static Color get surface => WaUi.surface;
  static Color get buttonDark => WaUi.buttonDark;

  static TextStyle get pageTitle => WaUi.headline;

  static TextStyle get sectionTitle => WaUi.sectionHeader;

  static TextStyle get cardTitle => WaUi.chatName;

  static TextStyle get body => WaUi.body;

  static TextStyle get bodyMuted => WaUi.listSubtitle;

  static TextStyle get statNumber => WaUi.toolsTitle.copyWith(
        fontSize: 28,
        color: primaryText,
      );

  static TextStyle get statLabel => WaUi.label.copyWith(color: primaryText);

  static TextStyle get buttonLabel => WaUi.button.copyWith(color: Colors.white);

  static BoxDecoration get thickCard => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: divider, width: borderWidth),
      );

  static BoxDecoration thickCardFilled({Color fill = WaUi.buttonDark}) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: fill, width: borderWidth),
      );

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: scaffoldBg,
      surfaceTintColor: scaffoldBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: WaUi.primaryText, size: 24),
      title: Text(title, style: pageTitle),
      actions: actions,
    );
  }

  static Widget sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          backgroundColor: buttonDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaUi.radiusPill),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
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
          foregroundColor: primaryText,
          side: const BorderSide(color: WaUi.divider, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaUi.radiusPill),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: WaUi.button.copyWith(color: primaryText),
                  ),
                ],
              ),
      ),
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: WaUi.bodyMedium.copyWith(color: secondaryText),
      filled: true,
      fillColor: WaUi.navBarBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
        borderSide: const BorderSide(color: WaUi.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
        borderSide: const BorderSide(color: WaUi.buttonDark, width: 1.2),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: thickCard,
          child: Column(
            children: [
              Text(label, style: WaUi.label),
              const SizedBox(height: 8),
              Text(
                value,
                style: WaUi.headline.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
